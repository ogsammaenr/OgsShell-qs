package keyring

import (
	"encoding/json"
	"testing"
)

func TestPayloads(t *testing.T) {
	req := PromptRequestedPayload{
		ID:            "prompt_123_1",
		IsPassword:    true,
		Title:         "Giriş Anahtarlığını Aç",
		Description:   "Google Chrome anahtarlığa erişmek istiyor",
		ChoiceLabel:   "Oturum açıldığında hatırla",
		ChoiceChosen:  true,
		ContinueLabel: "Kilidi Aç",
		CancelLabel:   "Vazgeç",
	}

	bytes, err := json.Marshal(req)
	if err != nil {
		t.Fatalf("Marshal error: %v", err)
	}

	var parsed PromptRequestedPayload
	if err := json.Unmarshal(bytes, &parsed); err != nil {
		t.Fatalf("Unmarshal error: %v", err)
	}

	if parsed.ID != "prompt_123_1" || !parsed.IsPassword || parsed.Title != "Giriş Anahtarlığını Aç" {
		t.Errorf("Unexpected parsed payload: %+v", parsed)
	}
}

func TestManagerInstantiation(t *testing.T) {
	mgr := NewManager()
	if mgr == nil {
		t.Fatal("NewManager returned nil")
	}

	bin := mgr.resolveBinaryPath()
	t.Logf("Resolved binary path: %s", bin)
}
