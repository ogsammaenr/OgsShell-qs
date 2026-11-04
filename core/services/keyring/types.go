package keyring

// PromptRequestedPayload represents an incoming prompt request emitted by the C helper prompter.
type PromptRequestedPayload struct {
	ID            string `json:"id"`
	IsPassword    bool   `json:"is_password"`
	Title         string `json:"title"`
	Description   string `json:"description"`
	Message       string `json:"message"`
	Warning       string `json:"warning"`
	ChoiceLabel   string `json:"choice_label"`
	ChoiceChosen  bool   `json:"choice_chosen"`
	PasswordNew   bool   `json:"password_new"`
	CallerWindow  string `json:"caller_window"`
	ContinueLabel string `json:"continue_label"`
	CancelLabel   string `json:"cancel_label"`
}

// PromptDismissedPayload represents a dismissed or closed prompt.
type PromptDismissedPayload struct {
	ID string `json:"id"`
}

// SubmitResponsePayload is sent by client to submit password.
type SubmitResponsePayload struct {
	ID       string `json:"id"`
	Password string `json:"password"`
	Remember bool   `json:"remember"`
}

// ConfirmResponsePayload is sent by client to confirm an action.
type ConfirmResponsePayload struct {
	ID        string `json:"id"`
	Confirmed bool   `json:"confirmed"`
	Remember  bool   `json:"remember"`
}

// CancelResponsePayload is sent by client to cancel prompting.
type CancelResponsePayload struct {
	ID string `json:"id"`
}
