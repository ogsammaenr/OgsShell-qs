package calendar

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"sync"
	"time"
)

// HolidayEngine provides multi-tiered holiday resolution (Memory -> Disk Cache -> Online API -> Algorithmic Fallback).
type HolidayEngine struct {
	mu        sync.RWMutex
	yearCache map[int][]Holiday
	fetcher   *HolidayFetcher
}

// NewHolidayEngine creates a new HolidayEngine instance.
func NewHolidayEngine() *HolidayEngine {
	return &HolidayEngine{
		yearCache: make(map[int][]Holiday),
		fetcher:   NewHolidayFetcher(),
	}
}

// GetHolidaysForYear resolves holidays through memory cache, disk cache, and algorithmic fallback.
func (e *HolidayEngine) GetHolidaysForYear(year int) []Holiday {
	if year <= 0 {
		year = time.Now().Year()
	}

	// 1. In-Memory Cache Lookup
	e.mu.RLock()
	if cached, exists := e.yearCache[year]; exists && len(cached) > 0 {
		e.mu.RUnlock()
		return cached
	}
	e.mu.RUnlock()

	// 2. Disk Cache Lookup
	diskCached, err := LoadHolidaysCache(year)
	if err == nil && len(diskCached) > 0 {
		e.mu.Lock()
		e.yearCache[year] = diskCached
		e.mu.Unlock()
		return diskCached
	}

	// 3. Fallback to Algorithmic / Diyanet Calculation Engine
	calculated := e.calculateOfflineHolidays(year)

	e.mu.Lock()
	e.yearCache[year] = calculated
	e.mu.Unlock()

	return calculated
}

// SyncHolidaysOnline fetches the latest online holiday announcements, updating caches.
func (e *HolidayEngine) SyncHolidaysOnline(ctx context.Context, year int) ([]Holiday, error) {
	if year <= 0 {
		year = time.Now().Year()
	}

	fetched, err := e.fetcher.FetchTurkeyHolidays(ctx, year)
	if err != nil {
		return nil, fmt.Errorf("online holiday sync failed: %w", err)
	}

	if len(fetched) == 0 {
		return nil, fmt.Errorf("remote API returned empty holiday list")
	}

	// Sort chronologically
	sort.Slice(fetched, func(i, j int) bool {
		return fetched[i].Date < fetched[j].Date
	})

	// Update In-Memory & Disk Cache
	e.mu.Lock()
	e.yearCache[year] = fetched
	e.mu.Unlock()

	_ = SaveHolidaysCache(year, fetched)
	return fetched, nil
}

// GetHolidaysForMonth returns all holidays falling within a specific month.
func (e *HolidayEngine) GetHolidaysForMonth(year int, month int) []Holiday {
	all := e.GetHolidaysForYear(year)
	prefix := fmt.Sprintf("%04d-%02d-", year, month)
	var monthHolidays []Holiday

	for _, h := range all {
		if strings.HasPrefix(h.Date, prefix) {
			monthHolidays = append(monthHolidays, h)
		}
	}
	return monthHolidays
}

// GetHolidayForDate returns the holiday information if the date is a holiday.
func (e *HolidayEngine) GetHolidayForDate(dateStr string) (*Holiday, bool) {
	t, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		return nil, false
	}

	holidays := e.GetHolidaysForYear(t.Year())
	for _, h := range holidays {
		if h.Date == dateStr {
			return &h, true
		}
	}
	return nil, false
}

// calculateOfflineHolidays generates offline national and religious holidays for Turkey.
func (e *HolidayEngine) calculateOfflineHolidays(year int) []Holiday {
	var list []Holiday

	// 1. Static National Holidays (Official)
	nationalHolidays := []struct {
		Month     int
		Day       int
		Name      string
		IsHalfDay bool
	}{
		{1, 1, "Yılbaşı", false},
		{4, 23, "Ulusal Egemenlik ve Çocuk Bayramı", false},
		{5, 1, "Emek ve Dayanışma Günü", false},
		{5, 19, "Atatürk'ü Anma, Gençlik ve Spor Bayramı", false},
		{7, 15, "15 Temmuz Demokrasi ve Milli Birlik Günü", false},
		{8, 30, "Zafer Bayramı", false},
		{10, 28, "Cumhuriyet Bayramı Arefesi", true},
		{10, 29, "Cumhuriyet Bayramı", false},
	}

	for _, nh := range nationalHolidays {
		list = append(list, Holiday{
			Date:      fmt.Sprintf("%04d-%02d-%02d", year, nh.Month, nh.Day),
			Name:      nh.Name,
			IsHalfDay: nh.IsHalfDay,
			Type:      "national",
		})
	}

	// 2. Islamic Religious Holidays (Ramazan & Kurban Bayramları)
	religious := getReligiousHolidays(year)
	list = append(list, religious...)

	// Sort chronologically by date
	sort.Slice(list, func(i, j int) bool {
		return list[i].Date < list[j].Date
	})

	return list
}

// getReligiousHolidays computes or looks up religious holidays for Turkey.
func getReligiousHolidays(year int) []Holiday {
	type religiousEntry struct {
		ramadanEve string // "YYYY-MM-DD"
		eidEve     string // "YYYY-MM-DD"
	}

	// Accurate astronomical calculation table (Diyanet official dates 2024-2035)
	knownYears := map[int]religiousEntry{
		2024: {ramadanEve: "2024-04-09", eidEve: "2024-06-15"},
		2025: {ramadanEve: "2025-03-29", eidEve: "2025-06-05"},
		2026: {ramadanEve: "2026-03-19", eidEve: "2026-05-26"},
		2027: {ramadanEve: "2027-03-09", eidEve: "2027-05-16"},
		2028: {ramadanEve: "2028-02-26", eidEve: "2028-05-04"},
		2029: {ramadanEve: "2029-02-14", eidEve: "2029-04-23"},
		2030: {ramadanEve: "2030-02-04", eidEve: "2030-04-13"},
		2031: {ramadanEve: "2031-01-24", eidEve: "2031-04-02"},
		2032: {ramadanEve: "2032-01-13", eidEve: "2032-03-21"},
		2033: {ramadanEve: "2033-01-02", eidEve: "2033-03-10"},
		2034: {ramadanEve: "2034-12-12", eidEve: "2034-02-28"},
		2035: {ramadanEve: "2035-12-01", eidEve: "2035-02-17"},
	}

	entry, ok := knownYears[year]
	if !ok {
		// Fallback algorithmic shift (~10.875 days per lunar year)
		baseYear := 2026
		diffYears := year - baseYear
		shiftDays := int(float64(diffYears) * 354.367) - (diffYears * 365)

		baseRamadan, _ := time.Parse("2006-01-02", "2026-03-19")
		baseEid, _ := time.Parse("2006-01-02", "2026-05-26")

		entry = religiousEntry{
			ramadanEve: baseRamadan.AddDate(0, 0, shiftDays).Format("2006-01-02"),
			eidEve:     baseEid.AddDate(0, 0, shiftDays).Format("2006-01-02"),
		}
	}

	var results []Holiday

	// Ramazan Bayramı (Arefe + 3 Days)
	if rEve, err := time.Parse("2006-01-02", entry.ramadanEve); err == nil {
		results = append(results, Holiday{
			Date:      rEve.Format("2006-01-02"),
			Name:      "Ramazan Bayramı Arefesi",
			IsHalfDay: true,
			Type:      "religious",
		})
		for day := 1; day <= 3; day++ {
			d := rEve.AddDate(0, 0, day)
			results = append(results, Holiday{
				Date:      d.Format("2006-01-02"),
				Name:      fmt.Sprintf("Ramazan Bayramı %d. Gün", day),
				IsHalfDay: false,
				Type:      "religious",
			})
		}
	}

	// Kurban Bayramı (Arefe + 4 Days)
	if kEve, err := time.Parse("2006-01-02", entry.eidEve); err == nil {
		results = append(results, Holiday{
			Date:      kEve.Format("2006-01-02"),
			Name:      "Kurban Bayramı Arefesi",
			IsHalfDay: true,
			Type:      "religious",
		})
		for day := 1; day <= 4; day++ {
			d := kEve.AddDate(0, 0, day)
			results = append(results, Holiday{
				Date:      d.Format("2006-01-02"),
				Name:      fmt.Sprintf("Kurban Bayramı %d. Gün", day),
				IsHalfDay: false,
				Type:      "religious",
			})
		}
	}

	return results
}
