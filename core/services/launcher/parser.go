package launcher

import (
	"bufio"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"unicode"

	"ogsShell/core/services/launcher/entry"
)

var (
	// Regex to match XDG field codes like %f, %F, %u, %U, %d, %D, %n, %N, %i, %c, %k, %v, %m
	xdgFieldCodeRegex = regexp.MustCompile(`%[fFuUdDnNickvm]`)
)

// GetApplicationDirectories returns the standardized list of directories to scan for .desktop files.
func GetApplicationDirectories() []string {
	dirs := make([]string, 0, 6)
	homeDir, _ := os.UserHomeDir()

	// 1. User local applications
	if homeDir != "" {
		dirs = append(dirs, filepath.Join(homeDir, ".local", "share", "applications"))
		dirs = append(dirs, filepath.Join(homeDir, ".local", "share", "flatpak", "exports", "share", "applications"))
	}

	// 2. System Flatpak applications
	dirs = append(dirs, "/var/lib/flatpak/exports/share/applications")

	// 3. XDG_DATA_DIRS
	if xdgDataDirs := os.Getenv("XDG_DATA_DIRS"); xdgDataDirs != "" {
		for _, dataDir := range strings.Split(xdgDataDirs, ":") {
			if trimmed := strings.TrimSpace(dataDir); trimmed != "" {
				appDir := filepath.Join(trimmed, "applications")
				if !containsString(dirs, appDir) {
					dirs = append(dirs, appDir)
				}
			}
		}
	}

	// 4. Default system directories
	defaultSystemDirs := []string{
		"/usr/local/share/applications",
		"/usr/share/applications",
	}
	for _, sysDir := range defaultSystemDirs {
		if !containsString(dirs, sysDir) {
			dirs = append(dirs, sysDir)
		}
	}

	return dirs
}

// ParseDesktopFile parses a single .desktop file according to XDG specifications.
func ParseDesktopFile(filePath string) (*entry.AppEntry, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	inDesktopEntryGroup := false
	isApplication := true
	noDisplay := false
	hidden := false

	app := entry.AppEntry{
		ID:   filepath.Base(filePath),
		Path: filePath,
	}

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		// Skip comments and empty lines
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		// Group header detection
		if strings.HasPrefix(line, "[") && strings.HasSuffix(line, "]") {
			groupName := line[1 : len(line)-1]
			if groupName == "Desktop Entry" {
				inDesktopEntryGroup = true
			} else {
				// We've moved past the main [Desktop Entry] group (e.g. [Desktop Action ...])
				if inDesktopEntryGroup {
					break
				}
				inDesktopEntryGroup = false
			}
			continue
		}

		if !inDesktopEntryGroup {
			continue
		}

		// Key-Value parsing
		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			continue
		}

		key := strings.TrimSpace(parts[0])
		val := strings.TrimSpace(parts[1])

		switch key {
		case "Type":
			if !strings.EqualFold(val, "Application") {
				isApplication = false
			}
		case "NoDisplay":
			if strings.EqualFold(val, "true") || val == "1" {
				noDisplay = true
			}
		case "Hidden":
			if strings.EqualFold(val, "true") || val == "1" {
				hidden = true
			}
		case "Name":
			if app.Name == "" {
				app.Name = unquoteXDGString(val)
			}
		case "GenericName":
			if app.GenericName == "" {
				app.GenericName = unquoteXDGString(val)
			}
		case "Comment":
			if app.Comment == "" {
				app.Comment = unquoteXDGString(val)
			}
		case "Exec":
			if app.Exec == "" {
				app.Exec = cleanExecCommand(val)
			}
		case "Icon":
			if app.Icon == "" {
				app.Icon = unquoteXDGString(val)
			}
		case "Terminal":
			app.Terminal = strings.EqualFold(val, "true") || val == "1"
		case "Categories":
			if len(app.Categories) == 0 {
				app.Categories = parseSemicolonList(val)
			}
		case "Keywords":
			if len(app.Keywords) == 0 {
				app.Keywords = parseSemicolonList(val)
			}
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	// Filter out non-launchable or hidden entries
	if !isApplication || noDisplay || hidden || app.Name == "" || app.Exec == "" {
		return nil, nil
	}

	// Extract binary name from cleaned Exec
	app.ExecBinary = extractExecBinary(app.Exec)

	// Resolve / Normalize Application Icon
	app.Icon = resolveAppIcon(app.Icon, app.ExecBinary, app.ID)

	// Generate acronym from Name
	app.Acronym = generateAcronym(app.Name)

	// Pre-index SearchText
	app.SearchText = buildSearchTokenPool(&app)

	return &app, nil
}

// resolveAppIcon normalizes the icon name or resolves to an absolute path if found on disk.
func resolveAppIcon(rawIcon, execBinary, desktopID string) string {
	return ResolveIcon(rawIcon, execBinary, desktopID)
}

// cleanExecCommand cleans XDG parameter field codes (%f, %F, %u, %U, etc.) and unquotes if needed.
func cleanExecCommand(rawExec string) string {
	cleaned := xdgFieldCodeRegex.ReplaceAllString(rawExec, "")
	cleaned = strings.TrimSpace(cleaned)
	return cleaned
}

// extractExecBinary extracts the base executable binary name (e.g. "/usr/bin/gimp-2.10" -> "gimp-2.10").
func extractExecBinary(execCmd string) string {
	fields := strings.Fields(execCmd)
	if len(fields) == 0 {
		return ""
	}
	binaryPath := fields[0]
	// If path or binary is quoted, unquote
	binaryPath = strings.Trim(binaryPath, "\"'")
	return filepath.Base(binaryPath)
}

// generateAcronym builds an acronym string from the application name (e.g. "GNU Image Manipulation Program" -> "gimp", "Visual Studio Code" -> "vsc").
func generateAcronym(name string) string {
	if name == "" {
		return ""
	}

	words := strings.FieldsFunc(name, func(r rune) bool {
		return unicode.IsSpace(r) || r == '-' || r == '_' || r == '(' || r == ')' || r == '[' || r == ']' || r == '/' || r == ':'
	})

	if len(words) == 0 {
		return ""
	}

	if len(words) == 1 {
		// For a single word, check if it contains CamelCase (e.g. "VirtualBox" -> "vb")
		var camelAcronym strings.Builder
		for i, r := range name {
			if unicode.IsUpper(r) || (i == 0 && unicode.IsLetter(r)) {
				camelAcronym.WriteRune(unicode.ToLower(r))
			}
		}
		if camelAcronym.Len() > 1 && camelAcronym.Len() < len(name) {
			return camelAcronym.String()
		}
		return ""
	}

	var sb strings.Builder
	for _, word := range words {
		for _, r := range word {
			if unicode.IsLetter(r) || unicode.IsDigit(r) {
				sb.WriteRune(unicode.ToLower(r))
				break
			}
		}
	}

	return sb.String()
}

// buildSearchTokenPool creates a unified, lowercase token pool for fast substring and prefix checks.
func buildSearchTokenPool(app *entry.AppEntry) string {
	parts := make([]string, 0, 8+len(app.Categories)+len(app.Keywords))

	if app.Name != "" {
		parts = append(parts, strings.ToLower(app.Name))
	}
	if app.GenericName != "" {
		parts = append(parts, strings.ToLower(app.GenericName))
	}
	if app.ExecBinary != "" {
		parts = append(parts, strings.ToLower(app.ExecBinary))
	}
	if app.Acronym != "" {
		parts = append(parts, strings.ToLower(app.Acronym))
	}
	if app.ID != "" {
		parts = append(parts, strings.ToLower(strings.TrimSuffix(app.ID, ".desktop")))
	}
	for _, cat := range app.Categories {
		if cat != "" {
			parts = append(parts, strings.ToLower(cat))
		}
	}
	for _, kw := range app.Keywords {
		if kw != "" {
			parts = append(parts, strings.ToLower(kw))
		}
	}
	if app.Comment != "" {
		parts = append(parts, strings.ToLower(app.Comment))
	}

	return strings.Join(parts, " ")
}

// parseSemicolonList splits strings like "Graphics;2DGraphics;RasterEditor;" into a clean string slice.
func parseSemicolonList(val string) []string {
	raw := strings.Split(val, ";")
	result := make([]string, 0, len(raw))
	for _, item := range raw {
		trimmed := strings.TrimSpace(item)
		if trimmed != "" {
			result = append(result, unquoteXDGString(trimmed))
		}
	}
	return result
}

// unquoteXDGString unquotes surrounding quotes and standard escaped characters.
func unquoteXDGString(s string) string {
	s = strings.TrimSpace(s)
	if len(s) >= 2 && ((s[0] == '"' && s[len(s)-1] == '"') || (s[0] == '\'' && s[len(s)-1] == '\'')) {
		s = s[1 : len(s)-1]
	}
	s = strings.ReplaceAll(s, "\\s", " ")
	s = strings.ReplaceAll(s, "\\n", "\n")
	s = strings.ReplaceAll(s, "\\t", "\t")
	s = strings.ReplaceAll(s, "\\r", "\r")
	s = strings.ReplaceAll(s, "\\\\", "\\")
	return s
}

func containsString(slice []string, val string) bool {
	for _, item := range slice {
		if item == val {
			return true
		}
	}
	return false
}
