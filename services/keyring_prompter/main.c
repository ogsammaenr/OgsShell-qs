#define GCR_API_SUBJECT_TO_CHANGE 1
#include "prompter_prompt.h"
#include <gio/gio.h>
#include <glib-unix.h>
#include <json-glib/json-glib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static GMainLoop *main_loop = NULL;
static GcrSystemPrompter *prompter = NULL;
static gboolean is_registered = FALSE;
static guint owner_id_system = 0;
static guint owner_id_private = 0;

static gboolean on_sigterm(gpointer user_data) {
    (void)user_data;
    if (main_loop && g_main_loop_is_running(main_loop)) {
        g_main_loop_quit(main_loop);
    }
    return G_SOURCE_REMOVE;
}

static void handle_json_line(const gchar *line) {
    if (!line || !*line) return;

    JsonParser *parser = json_parser_new();
    GError *error = NULL;

    if (!json_parser_load_from_data(parser, line, -1, &error)) {
        g_clear_error(&error);
        g_object_unref(parser);
        return;
    }

    JsonNode *root = json_parser_get_root(parser);
    if (!root || !JSON_NODE_HOLDS_OBJECT(root)) {
        g_object_unref(parser);
        return;
    }

    JsonObject *obj = json_node_get_object(root);
    const gchar *name = json_object_get_string_member_with_default(obj, "name", "");
    JsonObject *args = NULL;
    if (json_object_has_member(obj, "args")) {
        args = json_object_get_object_member(obj, "args");
    }

    if (g_strcmp0(name, "keyring_submit_response") == 0 && args) {
        const gchar *id = json_object_get_string_member_with_default(args, "id", NULL);
        const gchar *password = json_object_get_string_member_with_default(args, "password", "");
        gboolean remember = json_object_get_boolean_member_with_default(args, "remember", TRUE);
        ogs_keyring_prompt_complete_password(id, password, remember);
    } else if (g_strcmp0(name, "keyring_confirm_response") == 0 && args) {
        const gchar *id = json_object_get_string_member_with_default(args, "id", NULL);
        gboolean confirmed = json_object_get_boolean_member_with_default(args, "confirmed", TRUE);
        gboolean remember = json_object_get_boolean_member_with_default(args, "remember", TRUE);
        ogs_keyring_prompt_complete_confirm(id, confirmed, remember);
    } else if (g_strcmp0(name, "keyring_cancel_response") == 0 && args) {
        const gchar *id = json_object_get_string_member_with_default(args, "id", NULL);
        ogs_keyring_prompt_cancel(id);
    } else if (g_strcmp0(name, "ping") == 0) {
        fprintf(stdout, "{\"type\":\"pong\"}\n");
        fflush(stdout);
    }

    g_object_unref(parser);
}

static gboolean on_stdin_readable(GIOChannel *channel, GIOCondition cond, gpointer user_data) {
    (void)user_data;
    if (cond & (G_IO_ERR | G_IO_HUP)) {
        // Parent closed pipe or terminated
        if (main_loop && g_main_loop_is_running(main_loop)) {
            g_main_loop_quit(main_loop);
        }
        return G_SOURCE_REMOVE;
    }

    if (cond & G_IO_IN) {
        gchar *line = NULL;
        gsize len = 0;
        GError *error = NULL;
        GIOStatus status;

        while ((status = g_io_channel_read_line(channel, &line, &len, NULL, &error)) == G_IO_STATUS_NORMAL) {
            if (line) {
                g_strstrip(line);
                handle_json_line(line);
                g_free(line);
                line = NULL;
            }
        }
        if (error) {
            g_clear_error(&error);
        }
        if (status == G_IO_STATUS_EOF) {
            if (main_loop && g_main_loop_is_running(main_loop)) {
                g_main_loop_quit(main_loop);
            }
            return G_SOURCE_REMOVE;
        }
    }

    return G_SOURCE_CONTINUE;
}

static void on_bus_acquired(GDBusConnection *connection, const gchar *name, gpointer user_data) {
    (void)user_data;
    if (prompter && !is_registered) {
        gcr_system_prompter_register(prompter, connection);
        is_registered = TRUE;
    }
    fprintf(stdout, "{\"type\":\"keyring_bus_acquired\",\"name\":\"%s\"}\n", name);
    fflush(stdout);
}

static void on_name_acquired(GDBusConnection *connection, const gchar *name, gpointer user_data) {
    (void)connection;
    (void)user_data;
    fprintf(stdout, "{\"type\":\"keyring_name_acquired\",\"name\":\"%s\"}\n", name);
    fflush(stdout);
}

static void on_name_lost(GDBusConnection *connection, const gchar *name, gpointer user_data) {
    (void)connection;
    (void)user_data;
    fprintf(stderr, "[ogsshell-keyring-prompter] Name lost or not acquired: %s\n", name);
}

int main(int argc, char *argv[]) {
    (void)argc;
    (void)argv;
    // Unbuffered stdout for zero latency NDJSON IPC
    setvbuf(stdout, NULL, _IOLBF, 0);

    main_loop = g_main_loop_new(NULL, FALSE);

    // Setup UNIX signal handlers for graceful shutdown
    g_unix_signal_add(SIGTERM, on_sigterm, NULL);
    g_unix_signal_add(SIGINT, on_sigterm, NULL);

    // Setup STDIN channel to listen for JSON RPC from Go parent supervisor
    GIOChannel *stdin_chan = g_io_channel_unix_new(fileno(stdin));
    g_io_channel_set_encoding(stdin_chan, NULL, NULL);
    g_io_channel_set_buffered(stdin_chan, TRUE);
    g_io_channel_set_flags(stdin_chan, G_IO_FLAG_NONBLOCK, NULL);
    g_io_add_watch(stdin_chan, G_IO_IN | G_IO_HUP | G_IO_ERR, on_stdin_readable, NULL);
    g_io_channel_unref(stdin_chan);

    // Instantiate GcrSystemPrompter with our custom prompt class
    prompter = gcr_system_prompter_new(GCR_SYSTEM_PROMPTER_SINGLE, OGS_TYPE_KEYRING_PROMPT);

    // Claim D-Bus session well-known names to intercept prompt requests
    owner_id_system = g_bus_own_name(G_BUS_TYPE_SESSION,
                                     "org.gnome.keyring.SystemPrompter",
                                     G_BUS_NAME_OWNER_FLAGS_REPLACE,
                                     on_bus_acquired,
                                     on_name_acquired,
                                     on_name_lost,
                                     NULL, NULL);

    owner_id_private = g_bus_own_name(G_BUS_TYPE_SESSION,
                                      "org.gnome.keyring.PrivatePrompter",
                                      G_BUS_NAME_OWNER_FLAGS_REPLACE,
                                      on_bus_acquired,
                                      on_name_acquired,
                                      on_name_lost,
                                      NULL, NULL);

    fprintf(stdout, "{\"type\":\"keyring_prompter_started\"}\n");
    fflush(stdout);

    // Run GLib event loop
    g_main_loop_run(main_loop);

    // Cleanup upon exit
    if (owner_id_system) g_bus_unown_name(owner_id_system);
    if (owner_id_private) g_bus_unown_name(owner_id_private);

    if (prompter) {
        if (is_registered) {
            gcr_system_prompter_unregister(prompter, FALSE);
        }
        g_object_unref(prompter);
        prompter = NULL;
    }

    g_main_loop_unref(main_loop);
    main_loop = NULL;

    return 0;
}
