package usecase

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/redis/go-redis/v9"
	pb "github.com/gipjazes/backend/internal/proto"
)

type FeedService struct {
	redisClient *redis.Client
}

func NewFeedService(rc *redis.Client) *FeedService {
	return &FeedService{redisClient: rc}
}

// GetUserFeed retrieves the pre-computed feed from Redis
func (s *FeedService) GetUserFeed(ctx context.Context, userID string, limit int64) ([]*pb.Video, error) {
	key := fmt.Sprintf("feed:%s", userID)

	// Fetch video IDs from Redis List (LGRANGE)
	// In a real app, a worker would have pushed IDs here based on the algorithm
	videoJSONs, err := s.redisClient.LRange(ctx, key, 0, limit-1).Result()
	if err != nil {
		return nil, fmt.Errorf("failed to fetch feed from redis: %v", err)
	}

	var videos []*pb.Video
	for _, vJson := range videoJSONs {
		var video pb.Video
		if err := json.Unmarshal([]byte(vJson), &video); err == nil {
			videos = append(videos, &video)
		}
	}

	// Falls back to a global trending feed if personal feed is empty
	if len(videos) == 0 {
		return s.getGlobalTrending(ctx, limit)
	}

	return videos, nil
}

// GetWeightedFeed calculates a ranked feed based on user performance metrics
func (s *FeedService) GetWeightedFeed(ctx context.Context, metrics []VideoStats) ([]string, error) {
	// 1. Apply the weighted ranking algorithm
	rankedIDs := RankVideos(metrics)

	// 2. Optionally cache the result in Redis for the next fetch
	// s.redisClient.LPush(ctx, "temp_ranked_feed", rankedIDs)

	return rankedIDs, nil
}

func (s *FeedService) getGlobalTrending(ctx context.Context, limit int64) ([]*pb.Video, error) {
	// Mocking high-performance trending feed retrieval
	return []*pb.Video{
		{
			Id:       "trend-1",
			VideoUrl: "https://storage.googleapis.com/gipjazes-hls/processed/v1/master.m3u8",
			Description: "#GIPJAZES V is LIVE 🚀",
			Creator: &pb.User{Username: "jazes_official", DisplayName: "GIPJAZES Team"},
		},
	}, nil
}
