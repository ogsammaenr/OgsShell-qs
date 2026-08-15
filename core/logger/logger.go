package logger

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"os"
	"sync"
	"time"
)

// Terminal ANSI Renk Kodları
const (
	colorReset  = "\033[0m"
	colorRed    = "\033[31m"
	colorYellow = "\033[33m"
	colorGreen  = "\033[32m"
	colorCyan   = "\033[36m"
)

type CustomHandler struct {
	opts		slog.HandlerOptions
	out			io.Writer
	mu			sync.Mutex
}

func NewCustomHandler(out io.Writer, opts *slog.HandlerOptions) *CustomHandler {
	h := &CustomHandler{out: out}
	if opts != nil {
		h.opts = *opts
	}
	return h
}

func (h *CustomHandler) Enabled(_ context.Context, level slog.Level) bool {
	minLevel := slog.LevelInfo
	if h.opts.Level != nil {
		minLevel = h.opts.Level.Level()
	}
	return level >= minLevel
}

func (h *CustomHandler) Handle(_ context.Context, r slog.Record) error {
	h.mu.Lock()
	defer h.mu.Unlock()

	timeStr := r.Time.Format(time.TimeOnly)

	var levelStr string
	switch r.Level {
	case slog.LevelDebug:
			levelStr = colorCyan + "DEBUG" + colorReset
	case slog.LevelInfo:
			levelStr = colorGreen +"INFO" + colorReset
	case slog.LevelWarn:
			levelStr = colorYellow + "WARN" + colorReset
	case slog.LevelError:
			levelStr = colorRed + "ERROR" + colorReset
	default:
			levelStr = r.Level.String()
	}

	module := "CORE"
	var extraAttrs string
	
	r.Attrs(func(a slog.Attr) bool {
		if a.Key == "module" {
			module = a.Value.String()
		} else {
			extraAttrs += fmt.Sprintf(" %s=%v", a.Key, a.Value.Any())
		}
		return true
	})

	line := fmt.Sprintf("%s [%s] [%s] %s%s\n",timeStr, levelStr, module, r.Message, extraAttrs)

	_, err := h.out.Write([]byte(line))
	return err
}

func (h *CustomHandler) WithAttrs(_ []slog.Attr) slog.Handler		{ return h }
func (h *CustomHandler) WithGroup(_ string) slog.Handler				{ return h }

func Init() {
	handler := NewCustomHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelDebug,
	})
	slog.SetDefault(slog.New(handler))
}

func Module(name string) *slog.Logger {
	return slog.Default().With("module", name)
}
