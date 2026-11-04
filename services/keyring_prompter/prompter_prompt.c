#include "prompter_prompt.h"
#include <json-glib/json-glib.h>
#include <stdio.h>
#include <time.h>

static OgsKeyringPrompt *active_prompt_instance = NULL;
static guint64 prompt_counter = 0;

enum {
    PROP_0,
    PROP_TITLE,
    PROP_MESSAGE,
    PROP_DESCRIPTION,
    PROP_WARNING,
    PROP_PASSWORD_NEW,
    PROP_PASSWORD_STRENGTH,
    PROP_CHOICE_LABEL,
    PROP_CHOICE_CHOSEN,
    PROP_CALLER_WINDOW,
    PROP_CONTINUE_LABEL,
    PROP_CANCEL_LABEL,
    N_PROPS
};

static void ogs_keyring_prompt_prompt_iface_init(GcrPromptIface *iface);

G_DEFINE_TYPE_WITH_CODE(OgsKeyringPrompt, ogs_keyring_prompt, G_TYPE_OBJECT,
                        G_IMPLEMENT_INTERFACE(GCR_TYPE_PROMPT, ogs_keyring_prompt_prompt_iface_init))

static void ogs_keyring_prompt_get_property(GObject *object, guint prop_id, GValue *value, GParamSpec *pspec) {
    OgsKeyringPrompt *self = OGS_KEYRING_PROMPT(object);
    switch (prop_id) {
    case PROP_TITLE: g_value_set_string(value, self->title); break;
    case PROP_MESSAGE: g_value_set_string(value, self->message); break;
    case PROP_DESCRIPTION: g_value_set_string(value, self->description); break;
    case PROP_WARNING: g_value_set_string(value, self->warning); break;
    case PROP_PASSWORD_NEW: g_value_set_boolean(value, self->password_new); break;
    case PROP_PASSWORD_STRENGTH: g_value_set_int(value, self->password_strength); break;
    case PROP_CHOICE_LABEL: g_value_set_string(value, self->choice_label); break;
    case PROP_CHOICE_CHOSEN: g_value_set_boolean(value, self->choice_chosen); break;
    case PROP_CALLER_WINDOW: g_value_set_string(value, self->caller_window); break;
    case PROP_CONTINUE_LABEL: g_value_set_string(value, self->continue_label); break;
    case PROP_CANCEL_LABEL: g_value_set_string(value, self->cancel_label); break;
    default: G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec); break;
    }
}

static void ogs_keyring_prompt_set_property(GObject *object, guint prop_id, const GValue *value, GParamSpec *pspec) {
    OgsKeyringPrompt *self = OGS_KEYRING_PROMPT(object);
    switch (prop_id) {
    case PROP_TITLE: g_free(self->title); self->title = g_value_dup_string(value); break;
    case PROP_MESSAGE: g_free(self->message); self->message = g_value_dup_string(value); break;
    case PROP_DESCRIPTION: g_free(self->description); self->description = g_value_dup_string(value); break;
    case PROP_WARNING: g_free(self->warning); self->warning = g_value_dup_string(value); break;
    case PROP_PASSWORD_NEW: self->password_new = g_value_get_boolean(value); break;
    case PROP_PASSWORD_STRENGTH: self->password_strength = g_value_get_int(value); break;
    case PROP_CHOICE_LABEL: g_free(self->choice_label); self->choice_label = g_value_dup_string(value); break;
    case PROP_CHOICE_CHOSEN: self->choice_chosen = g_value_get_boolean(value); break;
    case PROP_CALLER_WINDOW: g_free(self->caller_window); self->caller_window = g_value_dup_string(value); break;
    case PROP_CONTINUE_LABEL: g_free(self->continue_label); self->continue_label = g_value_dup_string(value); break;
    case PROP_CANCEL_LABEL: g_free(self->cancel_label); self->cancel_label = g_value_dup_string(value); break;
    default: G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec); break;
    }
}

static void ogs_keyring_prompt_finalize(GObject *object) {
    OgsKeyringPrompt *self = OGS_KEYRING_PROMPT(object);
    if (active_prompt_instance == self) {
        active_prompt_instance = NULL;
    }
    if (self->pending_task) {
        g_task_return_new_error(self->pending_task, G_IO_ERROR, G_IO_ERROR_CANCELLED, "Prompt finalized");
        g_clear_object(&self->pending_task);
    }
    g_free(self->prompt_id);
    g_free(self->title);
    g_free(self->message);
    g_free(self->description);
    g_free(self->warning);
    g_free(self->choice_label);
    g_free(self->caller_window);
    g_free(self->continue_label);
    g_free(self->cancel_label);
    G_OBJECT_CLASS(ogs_keyring_prompt_parent_class)->finalize(object);
}

static void emit_prompt_requested(OgsKeyringPrompt *self, gboolean is_password) {
    JsonBuilder *builder = json_builder_new();
    json_builder_begin_object(builder);

    json_builder_set_member_name(builder, "type");
    json_builder_add_string_value(builder, "keyring_prompt_requested");

    json_builder_set_member_name(builder, "payload");
    json_builder_begin_object(builder);

    json_builder_set_member_name(builder, "id");
    json_builder_add_string_value(builder, self->prompt_id ? self->prompt_id : "");

    json_builder_set_member_name(builder, "is_password");
    json_builder_add_boolean_value(builder, is_password);

    json_builder_set_member_name(builder, "title");
    json_builder_add_string_value(builder, self->title ? self->title : "Anahtarlık Kilit Açma");

    json_builder_set_member_name(builder, "description");
    json_builder_add_string_value(builder, self->description ? self->description : "");

    json_builder_set_member_name(builder, "message");
    json_builder_add_string_value(builder, self->message ? self->message : "");

    json_builder_set_member_name(builder, "warning");
    json_builder_add_string_value(builder, self->warning ? self->warning : "");

    json_builder_set_member_name(builder, "choice_label");
    json_builder_add_string_value(builder, self->choice_label ? self->choice_label : "");

    json_builder_set_member_name(builder, "choice_chosen");
    json_builder_add_boolean_value(builder, self->choice_chosen);

    json_builder_set_member_name(builder, "password_new");
    json_builder_add_boolean_value(builder, self->password_new);

    json_builder_set_member_name(builder, "caller_window");
    json_builder_add_string_value(builder, self->caller_window ? self->caller_window : "");

    json_builder_set_member_name(builder, "continue_label");
    json_builder_add_string_value(builder, self->continue_label ? self->continue_label : "Kilidi Aç");

    json_builder_set_member_name(builder, "cancel_label");
    json_builder_add_string_value(builder, self->cancel_label ? self->cancel_label : "Vazgeç");

    json_builder_end_object(builder);
    json_builder_end_object(builder);

    JsonGenerator *gen = json_generator_new();
    JsonNode *root = json_builder_get_root(builder);
    json_generator_set_root(gen, root);
    json_generator_set_pretty(gen, FALSE);

    gsize len = 0;
    gchar *json_str = json_generator_to_data(gen, &len);

    fprintf(stdout, "%s\n", json_str);
    fflush(stdout);

    g_free(json_str);
    json_node_free(root);
    g_object_unref(gen);
    g_object_unref(builder);
}

static void emit_prompt_dismissed(const gchar *id) {
    fprintf(stdout, "{\"type\":\"keyring_prompt_dismissed\",\"payload\":{\"id\":\"%s\"}}\n", id ? id : "");
    fflush(stdout);
}

static void ogs_prompt_password_async(GcrPrompt *prompt,
                                      GCancellable *cancellable,
                                      GAsyncReadyCallback callback,
                                      gpointer user_data) {
    OgsKeyringPrompt *self = OGS_KEYRING_PROMPT(prompt);
    active_prompt_instance = self;
    self->is_confirm_mode = FALSE;

    g_free(self->prompt_id);
    self->prompt_id = g_strdup_printf("prompt_%lu_%lu", (unsigned long)time(NULL), (unsigned long)(++prompt_counter));

    if (self->pending_task) {
        g_task_return_new_error(self->pending_task, G_IO_ERROR, G_IO_ERROR_CANCELLED, "Previous task superseded");
        g_clear_object(&self->pending_task);
    }
    self->pending_task = g_task_new(self, cancellable, callback, user_data);

    emit_prompt_requested(self, TRUE);
}

static const gchar *ogs_prompt_password_finish(GcrPrompt *prompt,
                                               GAsyncResult *result,
                                               GError **error) {
    (void)prompt;
    return g_task_propagate_pointer(G_TASK(result), error);
}

static void ogs_prompt_confirm_async(GcrPrompt *prompt,
                                     GCancellable *cancellable,
                                     GAsyncReadyCallback callback,
                                     gpointer user_data) {
    OgsKeyringPrompt *self = OGS_KEYRING_PROMPT(prompt);
    active_prompt_instance = self;
    self->is_confirm_mode = TRUE;

    g_free(self->prompt_id);
    self->prompt_id = g_strdup_printf("prompt_%lu_%lu", (unsigned long)time(NULL), (unsigned long)(++prompt_counter));

    if (self->pending_task) {
        g_task_return_new_error(self->pending_task, G_IO_ERROR, G_IO_ERROR_CANCELLED, "Previous task superseded");
        g_clear_object(&self->pending_task);
    }
    self->pending_task = g_task_new(self, cancellable, callback, user_data);

    emit_prompt_requested(self, FALSE);
}

static GcrPromptReply ogs_prompt_confirm_finish(GcrPrompt *prompt,
                                                GAsyncResult *result,
                                                GError **error) {
    (void)prompt;
    gssize res = g_task_propagate_int(G_TASK(result), error);
    if (res < 0) return GCR_PROMPT_REPLY_CANCEL;
    return (GcrPromptReply)res;
}

static void ogs_prompt_close(GcrPrompt *prompt) {
    OgsKeyringPrompt *self = OGS_KEYRING_PROMPT(prompt);
    if (self->pending_task) {
        g_task_return_new_error(self->pending_task, G_IO_ERROR, G_IO_ERROR_CANCELLED, "Prompt closed");
        g_clear_object(&self->pending_task);
    }
    emit_prompt_dismissed(self->prompt_id);
    if (active_prompt_instance == self) {
        active_prompt_instance = NULL;
    }
}

static void ogs_keyring_prompt_prompt_iface_init(GcrPromptIface *iface) {
    iface->prompt_password_async = ogs_prompt_password_async;
    iface->prompt_password_finish = ogs_prompt_password_finish;
    iface->prompt_confirm_async = ogs_prompt_confirm_async;
    iface->prompt_confirm_finish = ogs_prompt_confirm_finish;
    iface->prompt_close = ogs_prompt_close;
}

static void ogs_keyring_prompt_init(OgsKeyringPrompt *self) {
    self->password_new = FALSE;
    self->password_strength = 0;
    self->choice_chosen = TRUE;
}

static void ogs_keyring_prompt_class_init(OgsKeyringPromptClass *klass) {
    GObjectClass *gobject_class = G_OBJECT_CLASS(klass);
    gobject_class->get_property = ogs_keyring_prompt_get_property;
    gobject_class->set_property = ogs_keyring_prompt_set_property;
    gobject_class->finalize = ogs_keyring_prompt_finalize;

    g_object_class_override_property(gobject_class, PROP_TITLE, "title");
    g_object_class_override_property(gobject_class, PROP_MESSAGE, "message");
    g_object_class_override_property(gobject_class, PROP_DESCRIPTION, "description");
    g_object_class_override_property(gobject_class, PROP_WARNING, "warning");
    g_object_class_override_property(gobject_class, PROP_PASSWORD_NEW, "password-new");
    g_object_class_override_property(gobject_class, PROP_PASSWORD_STRENGTH, "password-strength");
    g_object_class_override_property(gobject_class, PROP_CHOICE_LABEL, "choice-label");
    g_object_class_override_property(gobject_class, PROP_CHOICE_CHOSEN, "choice-chosen");
    g_object_class_override_property(gobject_class, PROP_CALLER_WINDOW, "caller-window");
    g_object_class_override_property(gobject_class, PROP_CONTINUE_LABEL, "continue-label");
    g_object_class_override_property(gobject_class, PROP_CANCEL_LABEL, "cancel-label");
}

OgsKeyringPrompt *ogs_keyring_prompt_get_active(void) {
    return active_prompt_instance;
}

void ogs_keyring_prompt_complete_password(const gchar *id, const gchar *password, gboolean remember) {
    OgsKeyringPrompt *self = active_prompt_instance;
    if (!self || !self->pending_task) return;
    if (id && self->prompt_id && g_strcmp0(id, self->prompt_id) != 0) return;

    self->choice_chosen = remember;
    GTask *task = self->pending_task;
    self->pending_task = NULL;

    g_task_return_pointer(task, g_strdup(password ? password : ""), g_free);
    g_object_unref(task);

    emit_prompt_dismissed(self->prompt_id);
}

void ogs_keyring_prompt_complete_confirm(const gchar *id, gboolean confirmed, gboolean remember) {
    OgsKeyringPrompt *self = active_prompt_instance;
    if (!self || !self->pending_task) return;
    if (id && self->prompt_id && g_strcmp0(id, self->prompt_id) != 0) return;

    self->choice_chosen = remember;
    GTask *task = self->pending_task;
    self->pending_task = NULL;

    g_task_return_int(task, confirmed ? GCR_PROMPT_REPLY_CONTINUE : GCR_PROMPT_REPLY_CANCEL);
    g_object_unref(task);

    emit_prompt_dismissed(self->prompt_id);
}

void ogs_keyring_prompt_cancel(const gchar *id) {
    OgsKeyringPrompt *self = active_prompt_instance;
    if (!self || !self->pending_task) return;
    if (id && self->prompt_id && g_strcmp0(id, self->prompt_id) != 0) return;

    GTask *task = self->pending_task;
    self->pending_task = NULL;

    if (self->is_confirm_mode) {
        g_task_return_int(task, GCR_PROMPT_REPLY_CANCEL);
    } else {
        g_task_return_new_error(task, G_IO_ERROR, G_IO_ERROR_CANCELLED, "User cancelled");
    }
    g_object_unref(task);

    emit_prompt_dismissed(self->prompt_id);
}
