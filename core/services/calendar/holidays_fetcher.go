package calendar

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

// NagerHoliday represents an item in the Nager.Date PublicHolidays JSON payload.
type NagerHoliday struct {
	Date        string   `json:"date"`
	LocalName   string   `json:"localName"`
	Name        string   `json:"name"`
	CountryCode string   `json:"countryCode"`
	Fixed       bool     `json:"fixed"`
	Global      bool     `json:"global"`
	Types       []string `json:"types"`
}

// HolidayFetcher fetches live holiday records from remote APIs.
type HolidayFetcher struct {
	httpClient *http.Client
	baseURL    string
}

// NewHolidayFetcher creates a new HolidayFetcher with a 5-second timeout.
func NewHolidayFetcher(baseURL ...string) *HolidayFetcher {
	url := "https://date.nager.at/api/v3/PublicHolidays"
	if len(baseURL) > 0 && baseURL[0] != "" {
		url = baseURL[0]
	}

	return &HolidayFetcher{
		httpClient: &http.Client{
			Timeout: 5 * time.Second,
		},
		baseURL: url,
	}
}

// FetchTurkeyHolidays queries the Nager.Date API for Turkey (TR) holidays of a given year.
func (f *HolidayFetcher) FetchTurkeyHolidays(ctx context.Context, year int) ([]Holiday, error) {
	if year <= 0 {
		year = time.Now().Year()
	}

	reqURL := fmt.Sprintf("%s/%d/TR", f.baseURL, year)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, reqURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create holiday request: %w", err)
	}

	req.Header.Set("User-Agent", "ogsShell-qs/1.0 (ArchLinux/Hyprland; Desktop Shell)")
	req.Header.Set("Accept", "application/json")

	resp, err := f.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("holiday http request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("holiday api returned status %d", resp.StatusCode)
	}

	var rawItems []NagerHoliday
	if err := json.NewDecoder(resp.Body).Decode(&rawItems); err != nil {
		return nil, fmt.Errorf("failed to decode holiday json: %w", err)
	}

	var holidays []Holiday
	for _, item := range rawItems {
		hType := "national"
		isHalfDay := false

		// Identify religious or half-day holidays
		nameLower := item.LocalName
		if containsAny(nameLower, "Ramazan", "Kurban", "Bayramı") {
			hType = "religious"
		}
		if containsAny(nameLower, "Arefe", "Arefesi", "Yarım") {
			isHalfDay = true
		}

		holidays = append(holidays, Holiday{
			Date:      item.Date,
			Name:      item.LocalName,
			IsHalfDay: isHalfDay,
			Type:      hType,
		})
	}

	return holidays, nil
}

func containsAny(s string, keywords ...string) bool {
	for _, kw := range keywords {
		if len(s) >= len(kw) && containsSubstring(s, kw) {
			return true
		}
	}
	return false
}

func containsSubstring(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(s) > 0 && len(substr) > 0 && indexOf(s, substr) >= 0)
}

func indexOf(s, substr string) int {
	n := len(substr)
	if n == 0 {
		return 0
	}
	for i := 0; i+n <= len(s); i++ {
		if s[i:i+n] == substr {
			return i
		}
	}
	return -1
}
