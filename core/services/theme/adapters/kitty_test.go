package adapters

import (
	"net"
	"ogsShell/core/services/theme"
	"os"
	"path/filepath"
	"testing"
)

func TestFindKittySockets(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "kitty_sock_test_*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create a dummy unix socket
	sockPath := filepath.Join(tmpDir, "kitty-12345")
	l, err := net.Listen("unix", sockPath)
	if err != nil {
		t.Fatalf("failed to create unix socket: %v", err)
	}
	defer l.Close()

	// Temporarily override XDG_RUNTIME_DIR to point to tmpDir
	oldXdg := os.Getenv("XDG_RUNTIME_DIR")
	os.Setenv("XDG_RUNTIME_DIR", tmpDir)
	defer os.Setenv("XDG_RUNTIME_DIR", oldXdg)

	sockets := FindKittySockets()
	found := false
	for _, s := range sockets {
		if s == sockPath {
			found = true
			break
		}
	}

	if !found {
		t.Errorf("expected to find socket %s, found: %+v", sockPath, sockets)
	}
}

func TestKittyAdapterMetadata(t *testing.T) {
	adapter := NewKittyAdapter()
	if adapter.ID() != "kitty" {
		t.Errorf("expected ID 'kitty', got %s", adapter.ID())
	}
	if adapter.Name() != "Kitty Terminal" {
		t.Errorf("expected Name 'Kitty Terminal', got %s", adapter.Name())
	}
}

func TestKittyAdapterApplyCustomPath(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "kitty_apply_test_*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	sharedDir := filepath.Join(tmpDir, "shared")
	kittyShared := filepath.Join(sharedDir, "app_configs", "kitty")
	if err := os.MkdirAll(kittyShared, 0755); err != nil {
		t.Fatalf("failed to create shared dir: %v", err)
	}

	themeContent := "foreground #c0caf5\nbackground #1a1b26\n"
	if err := os.WriteFile(filepath.Join(kittyShared, "tokyonight.conf"), []byte(themeContent), 0644); err != nil {
		t.Fatalf("failed to write dummy theme: %v", err)
	}

	destPath := filepath.Join(tmpDir, "current-theme.conf")
	adapter := &KittyAdapter{
		customThemePath: destPath,
		sharedDir:       sharedDir,
	}

	palette := &theme.ThemePalette{
		ID:   "tokyonight",
		Name: "Tokyo Night",
	}

	if err := adapter.Apply(palette); err != nil {
		t.Fatalf("Apply failed: %v", err)
	}

	appliedData, err := os.ReadFile(destPath)
	if err != nil {
		t.Fatalf("failed to read destination theme: %v", err)
	}

	if string(appliedData) != themeContent {
		t.Errorf("expected %q, got %q", themeContent, string(appliedData))
	}
}
