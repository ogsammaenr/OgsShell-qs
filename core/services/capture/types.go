package capture

// FreezeResult holds the result of a screen freeze capture.
type FreezeResult struct {
	FilePath  string             `json:"file_path"`
	Timestamp int64              `json:"timestamp"`
	Success   bool               `json:"success"`
	Error     string             `json:"error,omitempty"`
	Mode      string             `json:"mode,omitempty"`
	Monitors  []HyprlandMonitor  `json:"monitors,omitempty"`
}

// CaptureRequest defines parameters for a screenshot or OCR capture.
type CaptureRequest struct {
	Geometry string `json:"geometry,omitempty"` // "x,y wxh" or empty for fullscreen
	Target   string `json:"target,omitempty"`   // Optional custom output file path
}

// CaptureResult holds metadata and status of a captured screenshot.
type CaptureResult struct {
	FilePath  string `json:"file_path"`
	Geometry  string `json:"geometry,omitempty"`
	Timestamp int64  `json:"timestamp"`
	Copied    bool   `json:"copied"`
	Success   bool   `json:"success"`
	Error     string `json:"error,omitempty"`
}

// OCRResult represents the extracted text from an optical character recognition run.
type OCRResult struct {
	Text      string `json:"text"`
	Preview   string `json:"preview"`
	CharCount int    `json:"char_count"`
	Copied    bool   `json:"copied"`
	Success   bool   `json:"success"`
	Error     string `json:"error,omitempty"`
}

// RecordState tracks the live state of a screen recording session.
type RecordState struct {
	IsRecording     bool   `json:"is_recording"`
	DurationSeconds int    `json:"duration_seconds"`
	FilePath        string `json:"file_path,omitempty"`
	Geometry        string `json:"geometry,omitempty"`
}

// RecordFinishedPayload contains summary information when a recording finishes.
type RecordFinishedPayload struct {
	FilePath        string `json:"file_path"`
	DurationSeconds int    `json:"duration_seconds"`
	Success         bool   `json:"success"`
	Error           string `json:"error,omitempty"`
}

// Action Request Payloads:

// FreezeScreenPayload defines arguments for the freeze_screen RPC action.
type FreezeScreenPayload struct {
	Mode string `json:"mode,omitempty"`
}

// CaptureScreenshotPayload defines arguments for the capture_screenshot RPC action.
type CaptureScreenshotPayload struct {
	Geometry string `json:"geometry,omitempty"`
	Monitor  string `json:"monitor,omitempty"`
	LocalX   int    `json:"local_x,omitempty"`
	LocalY   int    `json:"local_y,omitempty"`
	Width    int    `json:"width,omitempty"`
	Height   int    `json:"height,omitempty"`
}

// CaptureOCRPayload defines arguments for the capture_ocr RPC action.
type CaptureOCRPayload struct {
	Geometry string `json:"geometry,omitempty"`
	Monitor  string `json:"monitor,omitempty"`
	LocalX   int    `json:"local_x,omitempty"`
	LocalY   int    `json:"local_y,omitempty"`
	Width    int    `json:"width,omitempty"`
	Height   int    `json:"height,omitempty"`
}

// StartRecordingPayload defines arguments for the start_recording RPC action.
type StartRecordingPayload struct {
	Geometry string `json:"geometry,omitempty"`
}

// StopRecordingPayload defines arguments for the stop_recording RPC action.
type StopRecordingPayload struct{}

// OpenAnnotatorPayload defines arguments for the open_annotator RPC action.
type OpenAnnotatorPayload struct {
	FilePath string `json:"file_path,omitempty"`
}
