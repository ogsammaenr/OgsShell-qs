#ifndef OGS_KEYRING_PROMPTER_PROMPT_H
#define OGS_KEYRING_PROMPTER_PROMPT_H

#define GCR_API_SUBJECT_TO_CHANGE 1
#include <gcr/gcr.h>
#include <gio/gio.h>

G_BEGIN_DECLS

#define OGS_TYPE_KEYRING_PROMPT (ogs_keyring_prompt_get_type())
G_DECLARE_FINAL_TYPE(OgsKeyringPrompt, ogs_keyring_prompt, OGS, KEYRING_PROMPT, GObject)

struct _OgsKeyringPrompt {
    GObject parent;

    gchar *prompt_id;
    gchar *title;
    gchar *message;
    gchar *description;
    gchar *warning;
    gboolean password_new;
    gint password_strength;
    gchar *choice_label;
    gboolean choice_chosen;
    gchar *caller_window;
    gchar *continue_label;
    gchar *cancel_label;

    GTask *pending_task;
    gboolean is_confirm_mode;
};

OgsKeyringPrompt *ogs_keyring_prompt_get_active(void);
void ogs_keyring_prompt_complete_password(const gchar *id, const gchar *password, gboolean remember);
void ogs_keyring_prompt_complete_confirm(const gchar *id, gboolean confirmed, gboolean remember);
void ogs_keyring_prompt_cancel(const gchar *id);

G_END_DECLS

#endif /* OGS_KEYRING_PROMPTER_PROMPT_H */
