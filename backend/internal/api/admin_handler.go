package api

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	pb "github.com/gipjazes/backend/internal/proto"
	"github.com/gipjazes/backend/internal/repository"
	"github.com/redis/go-redis/v9"
)

type AdminHandler struct {
	adminRepo   *repository.AdminRepository
	videoRepo   *repository.PostgresVideoRepository
	redisClient *redis.Client
	pb.UnimplementedGIPJAZESServiceServer
}

func NewAdminHandler(adminRepo *repository.AdminRepository, videoRepo *repository.PostgresVideoRepository, redis *redis.Client) *AdminHandler {
	return &AdminHandler{adminRepo: adminRepo, videoRepo: videoRepo, redisClient: redis}
}

func (h *AdminHandler) AdminTakedown(ctx context.Context, req *pb.TakedownRequest) (*pb.TakedownResponse, error) {
	// 1. Soft delete in Postgres
	err := h.videoRepo.SoftDelete(ctx, req.VideoId)
	if err != nil {
		return nil, fmt.Errorf("failed to delete from db: %v", err)
	}

	// 2. Instant Purge from Redis Caches
	err = h.redisClient.Del(ctx, "global:trending").Err()
	if err != nil {
		return nil, fmt.Errorf("failed to purge redis: %v", err)
	}

	// Also remove from a specific set of active videos
	h.redisClient.SRem(ctx, "active:videos", req.VideoId)

	return &pb.TakedownResponse{Success: true}, nil
}

func (h *AdminHandler) HandleGetStats(w http.ResponseWriter, r *http.Request) {
	stats, err := h.adminRepo.GetStats(r.Context())
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(stats)
}

func (h *AdminHandler) HandleGetReports(w http.ResponseWriter, r *http.Request) {
	limitStr := r.URL.Query().Get("limit")
	limit, _ := strconv.Atoi(limitStr)
	if limit == 0 {
		limit = 50
	}
	reports, err := h.adminRepo.GetRecentReports(r.Context(), limit)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(reports)
}

func (h *AdminHandler) HandleGetTransactions(w http.ResponseWriter, r *http.Request) {
	limitStr := r.URL.Query().Get("limit")
	limit, _ := strconv.Atoi(limitStr)
	if limit == 0 {
		limit = 100
	}
	txs, err := h.adminRepo.GetTransactions(r.Context(), limit)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(txs)
}

func (h *AdminHandler) HandleBanUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var req struct {
		UserID string `json:"user_id"`
		Reason string `json:"reason"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}
	if err := h.adminRepo.BanUser(r.Context(), req.UserID, req.Reason); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]bool{"success": true})
}

func (h *AdminHandler) HandleFeatureVideo(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var req struct {
		VideoID  string `json:"video_id"`
		Featured bool   `json:"featured"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}
	if err := h.adminRepo.FeatureVideo(r.Context(), req.VideoID, req.Featured); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]bool{"success": true})
}
