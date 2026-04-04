package usecase

import (
	"sort"
)

// VideoStats holds metrics for ranking
type VideoStats struct {
	VideoID        string
	CompletionRate float64 // 0.0 to 1.0
	LoopCount      int
	ShareCount     int
}

// RankingWeights as per GIPJAZES V 2026 specs
const (
	WeightCompletion = 10.0
	WeightLoops      = 8.0
	WeightShares     = 5.0
)

// CalculateScore computes the weighted ranking for a single video
func CalculateScore(stats VideoStats) float64 {
	score := (stats.CompletionRate * WeightCompletion) +
		(float64(stats.LoopCount) * WeightLoops) +
		(float64(stats.ShareCount) * WeightShares)
	return score
}

// RankVideos sorts a list of videos based on their calculated scores
func RankVideos(videos []VideoStats) []string {
	type scoredVideo struct {
		id    string
		score float64
	}

	scores := make([]scoredVideo, len(videos))
	for i, v := range videos {
		scores[i] = scoredVideo{id: v.VideoID, score: CalculateScore(v)}
	}

	// Sort descending
	sort.Slice(scores, func(i, j int) bool {
		return scores[i].score > scores[j].score
	})

	result := make([]string, len(scores))
	for i, s := range scores {
		result[i] = s.id
	}
	return result
}
