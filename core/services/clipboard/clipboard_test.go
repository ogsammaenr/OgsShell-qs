package clipboard

import (
	"os"
	"path/filepath"
	"testing"
)

func TestParseCliphistListOutput(t *testing.T) {
	rawOutput := `1001	https://github.com/ogsammaenr/OgsShell-qs
1002	[[ binary data 1920x1080 png 2.4MB ]]
1003	const token = "catppuccin-mocha";
1004	echo '{"name":"toggle_dnd"}' | nc -U /tmp/ogs_shell.sock
`

	pinnedMap := map[string]PinnedItem{
		"1003": {ID: "1003", Content: "const token = \"catppuccin-mocha\";", Label: "Token Snippet"},
	}

	// 1. Full Parse Test
	items := ParseCliphistListOutput(rawOutput, pinnedMap, 10, "")
	if len(items) != 4 {
		t.Fatalf("expected 4 items, got %d", len(items))
	}

	// Verify Item 0 (URL Text)
	if items[0].ID != "1001" || items[0].Type != "text" || items[0].IsPinned {
		t.Errorf("unexpected item 0: %+v", items[0])
	}

	// Verify Item 1 (Image)
	if items[1].ID != "1002" || items[1].Type != "image" {
		t.Errorf("unexpected item 1 (image): %+v", items[1])
	}

	// Verify Item 2 (Pinned)
	if items[2].ID != "1003" || !items[2].IsPinned {
		t.Errorf("expected item 2 to be pinned: %+v", items[2])
	}

	// 2. Query Search Test
	searchItems := ParseCliphistListOutput(rawOutput, pinnedMap, 10, "toggle_dnd")
	if len(searchItems) != 1 {
		t.Fatalf("expected 1 search result, got %d", len(searchItems))
	}
	if searchItems[0].ID != "1004" {
		t.Errorf("expected search item 1004, got %s", searchItems[0].ID)
	}

	// 3. Limit Test
	limitedItems := ParseCliphistListOutput(rawOutput, pinnedMap, 2, "")
	if len(limitedItems) != 2 {
		t.Errorf("expected limit of 2 items, got %d", len(limitedItems))
	}
}

func TestPinnedStorageCRUD(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "clip_test_*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	pinnedPath := filepath.Join(tmpDir, "clipboard_pinned.json")

	mgr, err := NewDefaultClipboardManager(pinnedPath)
	if err != nil {
		t.Fatalf("failed to create manager: %v", err)
	}
	defer mgr.Close()

	// Initial count
	if len(mgr.GetPinned()) != 0 {
		t.Fatalf("expected 0 pinned items initially, got %d", len(mgr.GetPinned()))
	}

	// Pin item
	item1, err := mgr.PinItem("custom_1", "git commit -m 'feat: dynamic island'", "Git Feat")
	if err != nil {
		t.Fatalf("failed to pin item: %v", err)
	}
	if item1.ID != "custom_1" || item1.Label != "Git Feat" {
		t.Errorf("unexpected pinned item: %+v", item1)
	}

	// Pin second item
	_, _ = mgr.PinItem("custom_2", "sudo systemctl restart NetworkManager", "Restart Net")

	if len(mgr.GetPinned()) != 2 {
		t.Fatalf("expected 2 pinned items, got %d", len(mgr.GetPinned()))
	}

	// Unpin item 1
	_ = mgr.UnpinItem("custom_1")
	if len(mgr.GetPinned()) != 1 {
		t.Fatalf("expected 1 pinned item after unpin, got %d", len(mgr.GetPinned()))
	}
	if mgr.GetPinned()[0].ID != "custom_2" {
		t.Errorf("expected remaining item custom_2, got %s", mgr.GetPinned()[0].ID)
	}

	// Reload from disk to verify persistence
	reloadedMgr, err := NewDefaultClipboardManager(pinnedPath)
	if err != nil {
		t.Fatalf("failed to reload manager: %v", err)
	}
	defer reloadedMgr.Close()

	if len(reloadedMgr.GetPinned()) != 1 {
		t.Errorf("expected 1 item in reloaded manager, got %d", len(reloadedMgr.GetPinned()))
	}
}
