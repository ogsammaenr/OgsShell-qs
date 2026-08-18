package launcher

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"testing"
	"time"

	"ogsShell/core/services/launcher/entry"
)

func TestCleanExecCommand(t *testing.T) {
	tests := []struct {
		input    string
		expected string
	}{
		{"gimp-2.10 %U", "gimp-2.10"},
		{"firefox %u", "firefox"},
		{"/usr/bin/code --unity-launch %F", "/usr/bin/code --unity-launch"},
		{"vlc --started-from-file %f", "vlc --started-from-file"},
		{"flatpak run org.mozilla.firefox", "flatpak run org.mozilla.firefox"},
	}

	for _, tt := range tests {
		got := cleanExecCommand(tt.input)
		if got != tt.expected {
			t.Errorf("cleanExecCommand(%q) = %q; want %q", tt.input, got, tt.expected)
		}
	}
}

func TestGenerateAcronym(t *testing.T) {
	tests := []struct {
		input    string
		expected string
	}{
		{"GNU Image Manipulation Program", "gimp"},
		{"Visual Studio Code", "vsc"},
		{"Google Chrome", "gc"},
		{"Obsidian", ""},
		{"OBS Studio", "os"},
	}

	for _, tt := range tests {
		got := generateAcronym(tt.input)
		if got != tt.expected {
			t.Errorf("generateAcronym(%q) = %q; want %q", tt.input, got, tt.expected)
		}
	}
}

func TestDamerauLevenshteinDistance(t *testing.T) {
	tests := []struct {
		s1       string
		s2       string
		expected int
	}{
		{"firefox", "firefox", 0},
		{"firfox", "firefox", 1},      // deletion
		{"fireefox", "firefox", 1},    // insertion
		{"farefox", "firefox", 1},     // substitution
		{"vscdoe", "vscode", 1},       // transposition
		{"chrmoe", "chrome", 1},       // transposition
		{"spotfiy", "spotify", 1},     // transposition
		{"stduio", "studio", 1},       // transposition
		{"kitten", "sitting", 3},
	}

	for _, tt := range tests {
		got := DamerauLevenshteinDistance(tt.s1, tt.s2)
		if got != tt.expected {
			t.Errorf("DamerauLevenshteinDistance(%q, %q) = %d; want %d", tt.s1, tt.s2, got, tt.expected)
		}
	}
}

func TestMatcherScoringHierarchy(t *testing.T) {
	gimp := entry.AppEntry{
		ID:          "org.gimp.GIMP.desktop",
		Name:        "GNU Image Manipulation Program",
		GenericName: "Image Editor",
		Exec:        "gimp-2.10",
		ExecBinary:  "gimp-2.10",
		Acronym:     "gimp",
		Categories:  []string{"Graphics", "RasterEditor"},
		Keywords:    []string{"photo", "paint", "drawing"},
	}

	vscode := entry.AppEntry{
		ID:          "code.desktop",
		Name:        "Visual Studio Code",
		GenericName: "Code Editor",
		Exec:        "code",
		ExecBinary:  "code",
		Acronym:     "vsc",
		Categories:  []string{"Development", "IDE"},
		Keywords:    []string{"editor", "programming"},
	}

	firefox := entry.AppEntry{
		ID:          "firefox.desktop",
		Name:        "Firefox",
		GenericName: "Web Browser",
		Exec:        "firefox",
		ExecBinary:  "firefox",
		Acronym:     "f",
		Categories:  []string{"Network", "WebBrowser"},
		Keywords:    []string{"internet", "surf"},
	}

	// 1. Exact Name Match (100)
	scoreExact := ScoreApp("Firefox", &firefox)
	if scoreExact != 100 {
		t.Errorf("Expected exact match score 100, got %d", scoreExact)
	}

	// 2. Name Prefix Match (90)
	scorePrefix := ScoreApp("Fire", &firefox)
	if scorePrefix != 90 {
		t.Errorf("Expected prefix match score 90, got %d", scorePrefix)
	}

	// 3. Acronym Match (85)
	scoreAcronym := ScoreApp("gimp", &gimp)
	if scoreAcronym < 85 {
		t.Errorf("Expected acronym match score >= 85, got %d", scoreAcronym)
	}

	// 4. GenericName / Category Match (70)
	scoreGeneric := ScoreApp("editor", &vscode)
	if scoreGeneric < 65 {
		t.Errorf("Expected generic match score >= 65, got %d", scoreGeneric)
	}

	// 5. Keyword Match (50)
	scoreKeyword := ScoreApp("photo", &gimp)
	if scoreKeyword < 50 {
		t.Errorf("Expected keyword match score >= 50, got %d", scoreKeyword)
	}

	// 6. Typo / Fuzzy Matches
	scoreTypoFirefox := ScoreApp("firfox", &firefox)
	if scoreTypoFirefox < 20 || scoreTypoFirefox > 50 {
		t.Errorf("Expected typo match for firfox -> Firefox (20-50), got %d", scoreTypoFirefox)
	}

	scoreTypoVscode := ScoreApp("vscdoe", &vscode)
	if scoreTypoVscode < 20 || scoreTypoVscode > 50 {
		t.Errorf("Expected typo match for vscdoe -> Visual Studio Code (20-50), got %d", scoreTypoVscode)
	}
}

func TestIndexer_SearchAndFrecency(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "launcher_test_*")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create sample desktop files
	appsDir := filepath.Join(tempDir, "applications")
	_ = os.MkdirAll(appsDir, 0755)

	gimpFile := filepath.Join(appsDir, "gimp.desktop")
	_ = os.WriteFile(gimpFile, []byte(`[Desktop Entry]
Type=Application
Name=GNU Image Manipulation Program
GenericName=Image Editor
Exec=gimp-2.10 %U
Icon=gimp
Categories=Graphics;2DGraphics;
Keywords=photo;paint;
`), 0644)

	firefoxFile := filepath.Join(appsDir, "firefox.desktop")
	_ = os.WriteFile(firefoxFile, []byte(`[Desktop Entry]
Type=Application
Name=Firefox
GenericName=Web Browser
Exec=firefox %u
Icon=firefox
Categories=Network;WebBrowser;
Keywords=internet;browser;
`), 0644)

	statsFile := filepath.Join(tempDir, "launcher_stats.json")
	indexer := NewIndexer(statsFile, []string{appsDir})
	indexer.Reindex()

	if indexer.Count() != 2 {
		t.Fatalf("Expected 2 indexed apps, got %d", indexer.Count())
	}

	// Test Search
	results := indexer.Search("gimp", 10)
	if len(results) == 0 || results[0].ID != "gimp.desktop" {
		t.Fatalf("Expected gimp.desktop as top result, got: %+v", results)
	}

	// Test Frecency Recording
	indexer.RecordLaunch("firefox.desktop")
	indexer.RecordLaunch("firefox.desktop")
	indexer.RecordLaunch("firefox.desktop")

	app, exists := indexer.GetByID("firefox.desktop")
	if !exists || app.LaunchCount != 3 {
		t.Fatalf("Expected launch count 3 for firefox, got %d", app.LaunchCount)
	}
}

func TestIndexer_ConcurrencySafety(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "launcher_concurrency_*")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	indexer := NewIndexer(filepath.Join(tempDir, "stats.json"), []string{})
	indexer.mu.Lock()
	for i := 0; i < 100; i++ {
		app := entry.AppEntry{
			ID:   fmt.Sprintf("app_%d.desktop", i),
			Name: fmt.Sprintf("Application Number %d", i),
			Exec: fmt.Sprintf("app_%d", i),
		}
		indexer.entries[app.ID] = app
		indexer.entryList = append(indexer.entryList, app)
	}
	indexer.mu.Unlock()

	var wg sync.WaitGroup
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	// Concurrent Readers
	for r := 0; r < 8; r++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			for {
				select {
				case <-ctx.Done():
					return
				default:
					_ = indexer.Search(fmt.Sprintf("app %d", id%10), 10)
				}
			}
		}(r)
	}

	// Concurrent Writers (RecordLaunch)
	for w := 0; w < 4; w++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			for {
				select {
				case <-ctx.Done():
					return
				default:
					indexer.RecordLaunch(fmt.Sprintf("app_%d.desktop", id%50))
				}
			}
		}(w)
	}

	wg.Wait()
}

func TestSplitExecArgs(t *testing.T) {
	cmd := `gimp-2.10 -s --verbose "my file with spaces.png" 'another argument'`
	args := splitExecArgs(cmd)

	expected := []string{"gimp-2.10", "-s", "--verbose", "my file with spaces.png", "another argument"}
	if len(args) != len(expected) {
		t.Fatalf("Expected %d args, got %d: %+v", len(expected), len(args), args)
	}
	for i := range expected {
		if args[i] != expected[i] {
			t.Errorf("arg[%d] = %q; want %q", i, args[i], expected[i])
		}
	}
}

// BenchmarkSearch_500Apps measures search latency across 500 in-memory applications.
func BenchmarkSearch_500Apps(b *testing.B) {
	indexer := NewIndexer("", []string{})
	indexer.mu.Lock()
	for i := 0; i < 500; i++ {
		app := entry.AppEntry{
			ID:          fmt.Sprintf("app_%d.desktop", i),
			Name:        fmt.Sprintf("Desktop Application %d", i),
			GenericName: "Productivity Tool",
			Exec:        fmt.Sprintf("tool-%d", i),
			ExecBinary:  fmt.Sprintf("tool-%d", i),
			Acronym:     fmt.Sprintf("da%d", i),
			Categories:  []string{"Utility", "Development"},
			Keywords:    []string{"tool", "editor", "utility"},
		}
		app.SearchText = buildSearchTokenPool(&app)
		indexer.entries[app.ID] = app
		indexer.entryList = append(indexer.entryList, app)
	}
	indexer.mu.Unlock()

	queries := []string{"Desktop", "da42", "editor", "firfox", "tool-100", "Productivity"}

	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		q := queries[i%len(queries)]
		_ = indexer.Search(q, 15)
	}
}

// BenchmarkSearch_250Apps measures search latency across a typical 250-app Linux system.
func BenchmarkSearch_250Apps(b *testing.B) {
	indexer := NewIndexer("", []string{})
	indexer.mu.Lock()
	for i := 0; i < 250; i++ {
		app := entry.AppEntry{
			ID:          fmt.Sprintf("app_%d.desktop", i),
			Name:        fmt.Sprintf("Application %d", i),
			GenericName: "Text Editor",
			Exec:        fmt.Sprintf("app-%d", i),
			ExecBinary:  fmt.Sprintf("app-%d", i),
			Acronym:     fmt.Sprintf("a%d", i),
			Categories:  []string{"Utility"},
			Keywords:    []string{"editor"},
		}
		app.SearchText = buildSearchTokenPool(&app)
		indexer.entries[app.ID] = app
		indexer.entryList = append(indexer.entryList, app)
	}
	indexer.mu.Unlock()

	queries := []string{"App", "editor", "a12", "firfox"}

	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		q := queries[i%len(queries)]
		_ = indexer.Search(q, 15)
	}
}
