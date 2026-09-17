package capture

import (
	"os"
	"path/filepath"
	"testing"
)

func TestNewDefaultCaptureManager(t *testing.T) {
	mgr, err := NewDefaultCaptureManager()
	if err != nil {
		t.Fatalf("NewDefaultCaptureManager failed: %v", err)
	}
	defer mgr.Close()

	if mgr.freezePath != "/tmp/ogs_freeze.png" {
		t.Errorf("expected freezePath /tmp/ogs_freeze.png, got %s", mgr.freezePath)
	}

	if mgr.ocrTempPath != "/tmp/ogs_ocr.png" {
		t.Errorf("expected ocrTempPath /tmp/ogs_ocr.png, got %s", mgr.ocrTempPath)
	}

	state := mgr.GetRecordState()
	if state.IsRecording {
		t.Errorf("expected initial IsRecording to be false")
	}
}

func TestStopRecordingWithoutStart(t *testing.T) {
	mgr, err := NewDefaultCaptureManager()
	if err != nil {
		t.Fatalf("NewDefaultCaptureManager failed: %v", err)
	}
	defer mgr.Close()

	_, err = mgr.StopRecording()
	if err == nil {
		t.Errorf("expected error when stopping non-existent recording")
	}
}

func TestOpenAnnotatorMissingFile(t *testing.T) {
	mgr, err := NewDefaultCaptureManager()
	if err != nil {
		t.Fatalf("NewDefaultCaptureManager failed: %v", err)
	}
	defer mgr.Close()

	err = mgr.OpenAnnotator("")
	if err == nil {
		t.Errorf("expected error when opening annotator with no file and no prior screenshot")
	}

	err = mgr.OpenAnnotator("/non/existent/path/screenshot_dummy.png")
	if err == nil {
		t.Errorf("expected error for non-existent file path")
	}
}

func TestRecordStateCallback(t *testing.T) {
	mgr, err := NewDefaultCaptureManager()
	if err != nil {
		t.Fatalf("NewDefaultCaptureManager failed: %v", err)
	}
	defer mgr.Close()

	updateCalled := false
	mgr.SetRecordUpdateCallback(func(state RecordState) {
		updateCalled = true
	})

	finishCalled := false
	mgr.SetRecordFinishedCallback(func(result RecordFinishedPayload) {
		finishCalled = true
	})

	if mgr.recordUpdateCallback == nil || mgr.recordFinishedCallback == nil {
		t.Errorf("callbacks were not set properly")
	}

	_ = updateCalled
	_ = finishCalled
}

func TestCustomDirectories(t *testing.T) {
	tmpDir := t.TempDir()
	mgr := &Manager{
		screenshotsDir: filepath.Join(tmpDir, "Screenshots"),
		recordingsDir:  filepath.Join(tmpDir, "Recordings"),
		freezePath:     filepath.Join(tmpDir, "freeze.png"),
		ocrTempPath:    filepath.Join(tmpDir, "ocr.png"),
	}

	if err := os.MkdirAll(mgr.screenshotsDir, 0755); err != nil {
		t.Fatalf("failed to create custom screenshot dir: %v", err)
	}

	if _, err := os.Stat(mgr.screenshotsDir); err != nil {
		t.Errorf("screenshot directory was not created: %v", err)
	}
}
