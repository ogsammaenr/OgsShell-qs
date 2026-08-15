package clipboard

// ClipboardItem represents an entry in the system clipboard history.
type ClipboardItem struct {
	ID        string `json:"id"`        // cliphist ID or unique hash
	Preview   string `json:"preview"`   // Truncated preview text
	Type      string `json:"type"`      // "text" | "image"
	IsPinned  bool   `json:"is_pinned"` // Whether this item is saved in pinned favorites
	Label     string `json:"label,omitempty"`
	Timestamp int64  `json:"timestamp"`
}

// PinnedItem represents a user-bookmarked or favorited snippet that survives history wipes.
type PinnedItem struct {
	ID        string `json:"id"`
	Content   string `json:"content"`
	Label     string `json:"label"`
	Timestamp int64  `json:"timestamp"`
}

// GetHistoryPayload defines request parameters when querying clipboard history.
type GetHistoryPayload struct {
	Limit int    `json:"limit,omitempty"` // Maximum items (default: 50)
	Query string `json:"query,omitempty"` // Search filter
}

// CopyItemPayload defines the RPC request for restoring/copying content to the active clipboard.
type CopyItemPayload struct {
	ID   string `json:"id,omitempty"`   // cliphist ID to decode and copy
	Text string `json:"text,omitempty"` // Direct custom text to copy
}

// GetItemContentPayload defines the request for decoding the full raw text of an item.
type GetItemContentPayload struct {
	ID string `json:"id"`
}

// ItemContentResponse defines the response containing full decoded text.
type ItemContentResponse struct {
	ID      string `json:"id"`
	Content string `json:"content"`
	Type    string `json:"type"`
}

// DeleteItemPayload defines the RPC request for deleting an entry from history.
type DeleteItemPayload struct {
	ID string `json:"id"`
}

// PinItemPayload defines the RPC request for bookmarking an item into favorites.
type PinItemPayload struct {
	ID    string `json:"id,omitempty"`    // Existing history ID to pin
	Text  string `json:"text,omitempty"`  // Direct custom text to pin
	Label string `json:"label,omitempty"` // Optional human-readable title
}

// UnpinItemPayload defines the RPC request for removing an item from favorites.
type UnpinItemPayload struct {
	ID string `json:"id"`
}

// ClipboardItemCopiedPayload defines the event broadcast when a new item is copied.
type ClipboardItemCopiedPayload struct {
	ID      string `json:"id"`
	Preview string `json:"preview"`
	Type    string `json:"type"`
}
