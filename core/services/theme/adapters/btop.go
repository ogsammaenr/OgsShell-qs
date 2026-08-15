package adapters

import (
	"ogsShell/core/services/theme"
	"os"
	"path/filepath"
)

type BtopAdapter struct {
	sharedDir string
}

func NewBtopAdapter() *BtopAdapter {
	return &BtopAdapter{}
}

func (a *BtopAdapter) ID() string   { return "btop" }
func (a *BtopAdapter) Name() string { return "Btop System Monitor" }

func (a *BtopAdapter) IsInstalled() bool {
	homeDir, _ := os.UserHomeDir()
	btopConf := filepath.Join(homeDir, ".config", "btop")
	_, err := os.Stat(btopConf)
	return err == nil
}

func (a *BtopAdapter) Apply(palette *theme.ThemePalette) error {
	homeDir, _ := os.UserHomeDir()
	destPath := filepath.Join(homeDir, ".config", "btop", "themes", "ogsshell.theme")
	srcFile, err := GetSharedAppConfigFile(a.sharedDir, "btop", palette.ID, "theme")
	if err != nil {
		return err
	}

	return CopyFile(srcFile, destPath)
}
