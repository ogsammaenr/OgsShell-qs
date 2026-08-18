package launcher

import (
	"strings"
	"unicode"

	"ogsShell/core/services/launcher/entry"
)

// MatchResult holds an application entry and its computed search score.
type MatchResult struct {
	App   entry.AppEntry
	Score int
}

// ScoreApp calculates the relevance score (0 - 100+) for a given query against an AppEntry.
// Returns 0 if there is no significant match.
func ScoreApp(query string, app *entry.AppEntry) int {
	query = strings.TrimSpace(query)
	if query == "" {
		// Empty query returns baseline score based on LaunchCount
		return frecencyBonus(app.LaunchCount)
	}

	lowerQuery := strings.ToLower(query)
	lowerName := strings.ToLower(app.Name)
	lowerGeneric := strings.ToLower(app.GenericName)
	lowerExec := strings.ToLower(app.ExecBinary)
	lowerAcronym := strings.ToLower(app.Acronym)
	lowerID := strings.ToLower(strings.TrimSuffix(app.ID, ".desktop"))

	baseScore := 0

	// 1. Exact Name Match (100 Puan)
	if lowerName == lowerQuery {
		baseScore = 100
		return baseScore + frecencyBonus(app.LaunchCount)
	}

	// 2. Name Prefix Match (90 Puan) & Name Word Prefix (88 Puan)
	if strings.HasPrefix(lowerName, lowerQuery) {
		baseScore = 90
	} else if matchesWordPrefix(lowerName, lowerQuery) {
		baseScore = 88
	}

	// 3. Acronym Match (85 Puan) & Exec Binary Match (85 Puan)
	if baseScore < 85 {
		if lowerAcronym != "" && (lowerAcronym == lowerQuery || strings.HasPrefix(lowerAcronym, lowerQuery)) {
			baseScore = 85
		} else if lowerExec != "" && lowerExec == lowerQuery {
			baseScore = 85
		} else if lowerExec != "" && strings.HasPrefix(lowerExec, lowerQuery) {
			baseScore = 82
		} else if lowerID == lowerQuery || strings.HasPrefix(lowerID, lowerQuery) {
			baseScore = 80
		}
	}

	// 4. GenericName / Category Match (70 Puan)
	if baseScore < 70 {
		if lowerGeneric != "" && (lowerGeneric == lowerQuery || strings.HasPrefix(lowerGeneric, lowerQuery) || matchesWordPrefix(lowerGeneric, lowerQuery)) {
			baseScore = 70
		} else if lowerGeneric != "" && strings.Contains(lowerGeneric, lowerQuery) {
			baseScore = 65
		} else {
			for _, cat := range app.Categories {
				lowerCat := strings.ToLower(cat)
				if lowerCat == lowerQuery || strings.HasPrefix(lowerCat, lowerQuery) || matchesWordPrefix(lowerCat, lowerQuery) {
					baseScore = 68
					break
				} else if strings.Contains(lowerCat, lowerQuery) {
					baseScore = 60
					break
				}
			}
		}
	}

	// 5. Keywords Substring Match (50 Puan)
	if baseScore < 50 {
		for _, kw := range app.Keywords {
			lowerKw := strings.ToLower(kw)
			if lowerKw == lowerQuery || strings.HasPrefix(lowerKw, lowerQuery) || matchesWordPrefix(lowerKw, lowerQuery) {
				baseScore = 50
				break
			} else if strings.Contains(lowerKw, lowerQuery) {
				baseScore = 45
				break
			}
		}

		if baseScore < 50 && app.Comment != "" {
			lowerComment := strings.ToLower(app.Comment)
			if strings.Contains(lowerComment, lowerQuery) {
				baseScore = 40
			}
		}
	}

	// 6. Typo / Fuzzy Tolerant Match (10 - 45 Puan)
	if baseScore == 0 {
		fuzzyScore := calculateFuzzyScore(lowerQuery, lowerName, lowerExec, lowerGeneric, lowerAcronym, lowerID, app.Keywords)
		if fuzzyScore > baseScore {
			baseScore = fuzzyScore
		}
	}

	if baseScore > 0 {
		return baseScore + frecencyBonus(app.LaunchCount)
	}

	return 0
}

// frecencyBonus provides up to +15 bonus points based on user launch frequency.
func frecencyBonus(launchCount int) int {
	if launchCount <= 0 {
		return 0
	}
	bonus := launchCount * 2
	if bonus > 15 {
		bonus = 15
	}
	return bonus
}

// matchesWordPrefix checks if any word in the target starts with the given prefix.
func matchesWordPrefix(target, prefix string) bool {
	words := strings.FieldsFunc(target, func(r rune) bool {
		return unicode.IsSpace(r) || r == '-' || r == '_' || r == '.' || r == '/' || r == '(' || r == ')'
	})
	for _, w := range words {
		if strings.HasPrefix(w, prefix) {
			return true
		}
	}
	return false
}

// calculateFuzzyScore computes Damerau-Levenshtein and subsequence fuzzy scores across all app tokens.
func calculateFuzzyScore(query, name, exec, generic, acronym, appID string, keywords []string) int {
	queryLen := len(query)
	if queryLen < 3 {
		// Do not fuzzy match 1 or 2 letter queries to prevent noise
		return 0
	}

	bestScore := 0

	// Check Name words for Damerau-Levenshtein distance
	nameWords := strings.FieldsFunc(name, func(r rune) bool {
		return unicode.IsSpace(r) || r == '-' || r == '_' || r == '.' || r == '/' || r == '(' || r == ')'
	})

	for _, word := range nameWords {
		score := scoreByDistance(query, word, 45, 25)
		if score > bestScore {
			bestScore = score
		}
	}

	// Check compound acronyms (e.g. "vsc" + "code" -> "vscode" for Visual Studio Code)
	if acronym != "" && len(nameWords) > 1 {
		lastWord := nameWords[len(nameWords)-1]
		compound := acronym[:len(acronym)-1] + lastWord
		score := scoreByDistance(query, compound, 45, 25)
		if score > bestScore {
			bestScore = score
		}
	}

	// Check App ID tokens (e.g. "visual-studio-code" -> "code", "visual", "studio")
	idWords := strings.FieldsFunc(appID, func(r rune) bool {
		return unicode.IsSpace(r) || r == '-' || r == '_' || r == '.'
	})
	for _, word := range idWords {
		score := scoreByDistance(query, word, 42, 22)
		if score > bestScore {
			bestScore = score
		}
	}

	// Check Exec binary name
	if exec != "" {
		score := scoreByDistance(query, exec, 42, 22)
		if score > bestScore {
			bestScore = score
		}
	}

	// Check GenericName words
	if generic != "" && bestScore < 30 {
		genericWords := strings.FieldsFunc(generic, func(r rune) bool {
			return unicode.IsSpace(r) || r == '-' || r == '_' || r == '.'
		})
		for _, word := range genericWords {
			score := scoreByDistance(query, word, 35, 18)
			if score > bestScore {
				bestScore = score
			}
		}
	}

	// Check Keywords
	if bestScore < 25 {
		for _, kw := range keywords {
			lowerKw := strings.ToLower(kw)
			score := scoreByDistance(query, lowerKw, 30, 15)
			if score > bestScore {
				bestScore = score
			}
		}
	}

	// Fallback to fuzzy subsequence match on name if no edit distance match
	if bestScore == 0 {
		subseqScore := scoreSubsequence(query, name)
		if subseqScore > bestScore {
			bestScore = subseqScore
		}
	}

	return bestScore
}

// scoreByDistance calculates score based on Damerau-Levenshtein edit distance.
func scoreByDistance(query, target string, maxDist1Score, maxDist2Score int) int {
	qLen := len(query)
	tLen := len(target)

	// Quick length diff check
	diff := qLen - tLen
	if diff < 0 {
		diff = -diff
	}
	if diff > 2 {
		return 0
	}

	dist := DamerauLevenshteinDistance(query, target)
	if dist == 1 {
		return maxDist1Score
	}
	if dist == 2 && qLen >= 5 {
		return maxDist2Score
	}
	return 0
}

// scoreSubsequence evaluates whether query runes appear in order in target, with contiguous bonuses.
func scoreSubsequence(query, target string) int {
	if len(query) < 3 || len(target) == 0 {
		return 0
	}

	qRunes := []rune(query)
	tRunes := []rune(target)

	qIdx := 0
	consecutive := 0
	maxConsecutive := 0

	for _, tr := range tRunes {
		if qIdx < len(qRunes) && tr == qRunes[qIdx] {
			qIdx++
			consecutive++
			if consecutive > maxConsecutive {
				maxConsecutive = consecutive
			}
		} else {
			consecutive = 0
		}
	}

	if qIdx == len(qRunes) {
		// All characters matched in sequence
		score := 15 + (maxConsecutive * 5)
		if score > 35 {
			score = 35
		}
		return score
	}

	return 0
}

// DamerauLevenshteinDistance computes the Damerau-Levenshtein distance between two strings
// using a zero-heap-allocation stack buffer for extreme sub-millisecond throughput.
func DamerauLevenshteinDistance(source, target string) int {
	sLen := len(source)
	tLen := len(target)

	if sLen == 0 {
		return tLen
	}
	if tLen == 0 {
		return sLen
	}

	// For standard queries and tokens (len <= 60), use zero-alloc stack buffer
	if sLen <= 60 && tLen <= 60 {
		stride := tLen + 2
		var d [64 * 64]int
		var lastSeen [256]int

		maxDist := sLen + tLen
		d[0] = maxDist

		for i := 0; i <= sLen; i++ {
			d[(i+1)*stride] = maxDist
			d[(i+1)*stride+1] = i
		}
		for j := 0; j <= tLen; j++ {
			d[j+1] = maxDist
			d[stride+j+1] = j
		}

		for i := 1; i <= sLen; i++ {
			var db int
			sChar := source[i-1]

			for j := 1; j <= tLen; j++ {
				tChar := target[j-1]
				k := lastSeen[tChar]
				l := db

				cost := 0
				if sChar != tChar {
					cost = 1
				} else {
					db = j
				}

				// Deletion, insertion, substitution
				subCost := d[i*stride+j] + cost
				insCost := d[(i+1)*stride+j] + 1
				delCost := d[i*stride+j+1] + 1

				minVal := subCost
				if insCost < minVal {
					minVal = insCost
				}
				if delCost < minVal {
					minVal = delCost
				}

				// Transposition
				if k > 0 && l > 0 {
					transCost := d[k*stride+l] + (i - k - 1) + 1 + (j - l - 1)
					if transCost < minVal {
						minVal = transCost
					}
				}

				d[(i+1)*stride+j+1] = minVal
			}

			lastSeen[sChar] = i
		}

		return d[(sLen+1)*stride+tLen+1]
	}

	// Fallback for strings > 60 chars
	stride := tLen + 2
	d := make([]int, (sLen+2)*stride)
	var lastSeen [256]int

	maxDist := sLen + tLen
	d[0] = maxDist

	for i := 0; i <= sLen; i++ {
		d[(i+1)*stride] = maxDist
		d[(i+1)*stride+1] = i
	}
	for j := 0; j <= tLen; j++ {
		d[j+1] = maxDist
		d[stride+j+1] = j
	}

	for i := 1; i <= sLen; i++ {
		var db int
		sChar := source[i-1]

		for j := 1; j <= tLen; j++ {
			tChar := target[j-1]
			k := lastSeen[tChar]
			l := db

			cost := 0
			if sChar != tChar {
				cost = 1
			} else {
				db = j
			}

			subCost := d[i*stride+j] + cost
			insCost := d[(i+1)*stride+j] + 1
			delCost := d[i*stride+j+1] + 1

			minVal := subCost
			if insCost < minVal {
				minVal = insCost
			}
			if delCost < minVal {
				minVal = delCost
			}

			if k > 0 && l > 0 {
				transCost := d[k*stride+l] + (i - k - 1) + 1 + (j - l - 1)
				if transCost < minVal {
					minVal = transCost
				}
			}

			d[(i+1)*stride+j+1] = minVal
		}

		lastSeen[sChar] = i
	}

	return d[(sLen+1)*stride+tLen+1]
}
