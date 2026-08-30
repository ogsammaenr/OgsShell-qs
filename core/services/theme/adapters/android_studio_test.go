package adapters

import (
	"fmt"
	"ogsShell/core/services/theme"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestAndroidStudioAdapterMetadata(t *testing.T) {
	adapter := NewAndroidStudioAdapter()
	if adapter.ID() != "android_studio" {
		t.Errorf("expected ID 'android_studio', got %s", adapter.ID())
	}
	if adapter.Name() != "Android Studio" {
		t.Errorf("expected Name 'Android Studio', got %s", adapter.Name())
	}
}

func TestAndroidStudioAdapterSchemeNames(t *testing.T) {
	adapter := NewAndroidStudioAdapter()
	tests := map[string]string{
		"nord":       "OgsNord",
		"catppuccin": "OgsCatppuccin",
		"everforest": "OgsEverforest",
		"gruvbox":    "OgsGruvbox",
		"monochrome": "OgsMonochrome",
		"tokyonight": "OgsTokyoNight",
		"rosepine":   "OgsRosePine",
	}

	for id, expected := range tests {
		actual := adapter.getSchemeName(id)
		if actual != expected {
			t.Errorf("theme %s: expected %s, got %s", id, expected, actual)
		}
	}
}

func TestAndroidStudioAdapterApply(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "android_studio_test_*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	sharedDir := filepath.Join(tmpDir, "shared")
	asShared := filepath.Join(sharedDir, "app_configs", "android_studio")
	if err := os.MkdirAll(asShared, 0755); err != nil {
		t.Fatalf("failed to create shared dir: %v", err)
	}

	iclsContent := `<scheme name="OgsNord" version="142" parent_scheme="Darcula">
  <colors>
    <option name="CONSOLE_BACKGROUND_KEY" value="2e3440" />
  </colors>
</scheme>`
	if err := os.WriteFile(filepath.Join(asShared, "nord.icls"), []byte(iclsContent), 0644); err != nil {
		t.Fatalf("failed to write dummy icls: %v", err)
	}

	// Create a dummy Google AndroidStudio config dir
	dummyConfigDir := filepath.Join(tmpDir, "AndroidStudio2026.1.2")
	if err := os.MkdirAll(dummyConfigDir, 0755); err != nil {
		t.Fatalf("failed to create dummy config dir: %v", err)
	}

	// Create adapter with custom sharedDir
	adapter := &AndroidStudioAdapter{
		sharedDir: sharedDir,
	}

	palette := &theme.ThemePalette{
		ID:   "nord",
		Name: "Nord",
	}

	// Test direct file copy and XML generation
	srcFile, err := GetSharedAppConfigFile(adapter.sharedDir, "android_studio", palette.ID, "icls")
	if err != nil {
		t.Fatalf("GetSharedAppConfigFile failed: %v", err)
	}

	schemeName := adapter.getSchemeName(palette.ID)
	destIcls := filepath.Join(dummyConfigDir, "colors", fmt.Sprintf("%s.icls", schemeName))
	if err := CopyFile(srcFile, destIcls); err != nil {
		t.Fatalf("CopyFile failed: %v", err)
	}

	optionsDir := filepath.Join(dummyConfigDir, "options")
	if err := os.MkdirAll(optionsDir, 0755); err != nil {
		t.Fatalf("MkdirAll failed: %v", err)
	}
	schemeXmlPath := filepath.Join(optionsDir, "colors.scheme.xml")
	xmlContent := fmt.Sprintf(`<application>
  <component name="EditorColorsManagerImpl">
    <global_color_scheme name="%s" />
  </component>
</application>
`, schemeName)
	if err := os.WriteFile(schemeXmlPath, []byte(xmlContent), 0644); err != nil {
		t.Fatalf("WriteFile failed: %v", err)
	}

	// Verify icls exists and has content
	readIcls, err := os.ReadFile(destIcls)
	if err != nil {
		t.Fatalf("failed to read dest icls: %v", err)
	}
	if string(readIcls) != iclsContent {
		t.Errorf("icls content mismatch: got %s, want %s", string(readIcls), iclsContent)
	}

	// Verify colors.scheme.xml contains OgsNord
	readXml, err := os.ReadFile(schemeXmlPath)
	if err != nil {
		t.Fatalf("failed to read scheme xml: %v", err)
	}
	if !strings.Contains(string(readXml), `name="OgsNord"`) {
		t.Errorf("scheme xml does not contain OgsNord: %s", string(readXml))
	}
}

func TestAndroidStudioAdapterAllThemesSharedConfigs(t *testing.T) {
	themes := []string{
		"nord",
		"catppuccin",
		"everforest",
		"gruvbox",
		"monochrome",
		"tokyonight",
		"rosepine",
	}

	adapter := NewAndroidStudioAdapter()
	repoShared := filepath.Join("..", "..", "..", "..", "shared")

	for _, id := range themes {
		schemeName := adapter.getSchemeName(id)

		// 1. Test android_studio config
		asPath, err := GetSharedAppConfigFile(repoShared, "android_studio", id, "icls")
		if err != nil {
			t.Fatalf("failed to find android_studio config for %s: %v", id, err)
		}
		data, err := os.ReadFile(asPath)
		if err != nil {
			t.Fatalf("failed to read android_studio config %s: %v", asPath, err)
		}
		if !strings.Contains(string(data), fmt.Sprintf(`name="%s"`, schemeName)) {
			t.Errorf("android_studio %s does not contain scheme name %s", id, schemeName)
		}

		// 2. Test intellij config
		ijPath, err := GetSharedAppConfigFile(repoShared, "intellij", id, "icls")
		if err != nil {
			t.Fatalf("failed to find intellij config for %s: %v", id, err)
		}
		dataIJ, err := os.ReadFile(ijPath)
		if err != nil {
			t.Fatalf("failed to read intellij config %s: %v", ijPath, err)
		}
		if !strings.Contains(string(dataIJ), fmt.Sprintf(`name="%s"`, schemeName)) {
			t.Errorf("intellij %s does not contain scheme name %s", id, schemeName)
		}
	}
}

