package launcher

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"syscall"
	"unicode"

	"ogsShell/core/logger"
)

// AppRunner handles detached and isolated process execution for desktop applications.
type AppRunner struct{}

// NewAppRunner creates a new AppRunner instance.
func NewAppRunner() *AppRunner {
	return &AppRunner{}
}

// Launch executes the application specified by the execCommand string.
// It first attempts to use systemd-run --user --scope for cgroup isolation.
// If systemd-run fails or is unavailable, it falls back to a detached process with Setsid.
func (r *AppRunner) Launch(execCommand string) error {
	log := logger.Module("LAUNCHER-RUNNER")

	args := splitExecArgs(execCommand)
	if len(args) == 0 {
		return fmt.Errorf("çalıştırılacak komut boş")
	}

	log.Info("Uygulama başlatılıyor", "command", execCommand, "binary", args[0])

	// 1. Try systemd-run --user --scope
	if systemdPath, err := exec.LookPath("systemd-run"); err == nil && systemdPath != "" {
		systemdArgs := append([]string{"--user", "--scope"}, args...)
		cmd := exec.Command(systemdPath, systemdArgs...)
		cmd.Env = os.Environ()
		cmd.Stdin = nil
		cmd.Stdout = nil
		cmd.Stderr = nil

		if err := cmd.Start(); err == nil {
			log.Info("Uygulama systemd-run ile izole başlatıldı", "binary", args[0])
			return nil
		} else {
			log.Warn("systemd-run ile başlatma başarısız, standart detached fallback deneniyor", "err", err)
		}
	}

	// 2. Fallback: Detached process with Setsid
	cmd := exec.Command(args[0], args[1:]...)
	cmd.SysProcAttr = &syscall.SysProcAttr{
		Setsid: true, // Creates a new session/process group detached from parent
	}
	cmd.Env = os.Environ()
	cmd.Stdin = nil
	cmd.Stdout = nil
	cmd.Stderr = nil

	if err := cmd.Start(); err != nil {
		log.Error("Uygulama başlatılamadı", "binary", args[0], "err", err)
		return fmt.Errorf("uygulama başlatılamadı (%s): %w", args[0], err)
	}

	log.Info("Uygulama detached süreç olarak başlatıldı", "binary", args[0], "pid", cmd.Process.Pid)
	return nil
}

// splitExecArgs safely parses an Exec command line string into separate arguments,
// respecting single and double quotes.
func splitExecArgs(command string) []string {
	var args []string
	var current strings.Builder
	inSingleQuote := false
	inDoubleQuote := false
	isEscaped := false

	for _, r := range command {
		if isEscaped {
			current.WriteRune(r)
			isEscaped = false
			continue
		}

		if r == '\\' {
			isEscaped = true
			continue
		}

		if r == '\'' && !inDoubleQuote {
			inSingleQuote = !inSingleQuote
			continue
		}

		if r == '"' && !inSingleQuote {
			inDoubleQuote = !inDoubleQuote
			continue
		}

		if unicode.IsSpace(r) && !inSingleQuote && !inDoubleQuote {
			if current.Len() > 0 {
				args = append(args, current.String())
				current.Reset()
			}
			continue
		}

		current.WriteRune(r)
	}

	if current.Len() > 0 {
		args = append(args, current.String())
	}

	return args
}
