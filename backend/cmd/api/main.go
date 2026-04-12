package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/cloudinary/cloudinary-go/v2"
	"github.com/cloudinary/cloudinary-go/v2/api/uploader"

	"cloud.google.com/go/storage"
	_ "github.com/lib/pq"
	"github.com/joho/godotenv"
	"github.com/redis/go-redis/v9"

	"github.com/gipjazes/backend/internal/api"
	pb "github.com/gipjazes/backend/internal/proto"
	"github.com/gipjazes/backend/internal/repository"
	"github.com/gipjazes/backend/internal/usecase"
	"github.com/gipjazes/backend/pkg/auth"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

type masterServer struct {
	pb.UnimplementedGIPJAZESServiceServer
	authHandler   *api.AuthHandler
	feedService   *usecase.FeedService
	uploadHandler *api.UploadHandler
	adminHandler  *api.AdminHandler
	videoRepo     *repository.PostgresVideoRepository
	userRepo      *repository.PostgresUserRepository
	messageRepo   *repository.PostgresMessageRepository
	adminRepo     *repository.AdminRepository
}

// Delegate methods to specific handlers
func (s *masterServer) Register(ctx context.Context, req *pb.RegisterRequest) (*pb.AuthResponse, error) {
	return s.authHandler.Register(ctx, req)
}

func (s *masterServer) Login(ctx context.Context, req *pb.LoginRequest) (*pb.AuthResponse, error) {
	return s.authHandler.Login(ctx, req)
}

func (s *masterServer) GetFeed(ctx context.Context, req *pb.GetFeedRequest) (*pb.FeedResponse, error) {
	// Use cursor for relative offset pagination
	var offset int64 = 0
	if req.Cursor != "" {
		fmt.Sscanf(req.Cursor, "%d", &offset)
	}

	videos, err := s.videoRepo.GetRecentVideos(ctx, int64(req.Limit), offset, "")
	if err != nil {
		return nil, err
	}
	if videos == nil {
		videos = []*pb.Video{}
	}

	nextCursor := ""
	if len(videos) == int(req.Limit) {
		nextCursor = fmt.Sprintf("%d", offset+int64(req.Limit))
	}

	return &pb.FeedResponse{Videos: videos, NextCursor: nextCursor}, nil
}

func (s *masterServer) GetUploadUrl(ctx context.Context, req *pb.SignedUrlRequest) (*pb.SignedUrlResponse, error) {
	return s.uploadHandler.GetUploadUrl(ctx, req)
}

func (s *masterServer) AdminTakedown(ctx context.Context, req *pb.TakedownRequest) (*pb.TakedownResponse, error) {
	return s.adminHandler.AdminTakedown(ctx, req)
}

func main() {
	// Load environment variables from .env (checks current and parent dir)
	godotenv.Load()
	godotenv.Load("../.env")

	// 1. Load Config (Using Environment Variables for Cloud)
	dbDSN := os.Getenv("DATABASE_URL")
	if dbDSN == "" {
		dbDSN = "host=localhost port=5432 user=gipjazes password=jazes_pass_2026 dbname=gipjazes_main sslmode=disable"
	}

	redisAddr := os.Getenv("REDIS_URL")
	if redisAddr == "" {
		redisAddr = "localhost:6379"
	}

	appPort := os.Getenv("PORT")
	if appPort == "" {
		appPort = "8080"
	}

	publicDomain := os.Getenv("RAILWAY_PUBLIC_DOMAIN")
	if publicDomain == "" {
		publicDomain = os.Getenv("RENDER_EXTERNAL_URL")
	}
	if publicDomain != "" {
		if !strings.HasPrefix(publicDomain, "http") {
			publicDomain = "https://" + publicDomain
		}
	} else {
		publicDomain = "http://localhost:" + appPort
	}

	// 2. Initialize Postgres
	db, err := sql.Open("postgres", dbDSN)
	if err != nil {
		log.Fatalf("failed to connect to postgres: %v", err)
	}
	defer db.Close()

	// Initializing Database Schema (Auto-Migrations for Render/Railway)
	err = initDB(db)
	if err != nil {
		log.Printf("DB Initialization Warning: %v", err)
	}

	// 3. Initialize Redis
	rdb := redis.NewClient(&redis.Options{Addr: redisAddr})
	defer rdb.Close()

	// 4. Initialize GCP Storage and Cloudinary
	ctx := context.Background()
	storageClient, err := storage.NewClient(ctx)
	if err != nil {
		log.Printf("Warning: GCS Client failed to init (expected if no key provided): %v", err)
	}

	cloudinaryURL := os.Getenv("CLOUDINARY_URL")
	var cld *cloudinary.Cloudinary
	if cloudinaryURL != "" {
		cld, err = cloudinary.NewFromURL(cloudinaryURL)
		if err != nil {
			log.Printf("Warning: Cloudinary Client failed to init: %v", err)
		} else {
			log.Printf("Cloudinary initialized successfully")
		}
	}

	// 5. Initialize Repositories & Services
	tokenManager := auth.NewTokenManager("jazes_v_secret_key_change_me_in_prod", 24*time.Hour)
	videoRepo := repository.NewPostgresVideoRepository(db)
	userRepo := repository.NewPostgresUserRepository(db)
	messageRepo := repository.NewPostgresMessageRepository(db)

	feedService := usecase.NewFeedService(rdb)
	adminRepo := repository.NewAdminRepository(db)
	uploadHandler := api.NewUploadHandler(storageClient, "gipjazes-raw-videos")
	adminHandler := api.NewAdminHandler(adminRepo, videoRepo, rdb)
	authHandler := api.NewAuthHandler(userRepo, tokenManager)

	// 6. Setup gRPC Server
	lis, err := net.Listen("tcp", ":9090")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	s := grpc.NewServer()
	srv := &masterServer{
		feedService:   feedService,
		uploadHandler: uploadHandler,
		adminHandler:  adminHandler,
		authHandler:   authHandler,
		videoRepo:     videoRepo,
		userRepo:      userRepo,
		messageRepo:   messageRepo,
		adminRepo:     adminRepo,
	}
	pb.RegisterGIPJAZESServiceServer(s, srv)

	// Enable reflection for debugging (e.g. via Postman/grpcurl)
	reflection.Register(s)

	// --- 7. Start HTTP REST Gateway for Web App ---
	go func() {
		mux := http.NewServeMux()

		mux.HandleFunc("/api/auth/register", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
			if r.Method == "OPTIONS" {
				return
			}

			var req pb.RegisterRequest
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				log.Printf("Register decode err: %v", err)
				http.Error(w, err.Error(), http.StatusBadRequest)
				return
			}
			log.Printf("Incoming Register Request: %v", req.Email)

			resp, err := srv.Register(context.Background(), &req)
			if err != nil {
				log.Printf("Register processing err: %v", err)
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}

			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(resp)
		})

		mux.HandleFunc("/api/auth/login", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
			if r.Method == "OPTIONS" {
				return
			}

			var req pb.LoginRequest
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				log.Printf("Login decode err: %v", err)
				http.Error(w, err.Error(), http.StatusBadRequest)
				return
			}
			log.Printf("Incoming Login Request: %v", req.Email)

			resp, err := srv.Login(context.Background(), &req)
			if err != nil {
				log.Printf("Login processing err: %v", err)
				http.Error(w, err.Error(), http.StatusUnauthorized)
				return
			}

			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(resp)
		})

		mux.HandleFunc("/api/feed", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
			if r.Method == "OPTIONS" {
				return
			}

			// Parse query parameters
			cursorStr := r.URL.Query().Get("cursor")
			categoryStr := r.URL.Query().Get("category")

			var offset int64 = 0
			if cursorStr != "" {
				fmt.Sscanf(cursorStr, "%d", &offset)
			}
			limit := 10

			videos, err := srv.videoRepo.GetRecentVideos(context.Background(), int64(limit), offset, categoryStr)
			if err != nil {
				log.Printf("Feed fetch err: %v", err)
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}

			nextCursor := ""
			if len(videos) == limit {
				nextCursor = fmt.Sprintf("%d", offset+int64(limit))
			}

			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]interface{}{
				"videos":      videos,
				"next_cursor": nextCursor,
			})
		})

		mux.HandleFunc("/api/categories", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
			if r.Method == "OPTIONS" {
				return
			}
			w.Header().Set("Content-Type", "application/json")
			categories := []string{"For You", "Comedy", "Music", "Tech", "Travel", "Food"}
			json.NewEncoder(w).Encode(categories)
		})

		mux.HandleFunc("/api/upload", func(w http.ResponseWriter, r *http.Request) {
			// Basic CORS
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" {
				return
			}

			// Authenticate Header
			authHeader := r.Header.Get("Authorization")
			if len(authHeader) < 8 || authHeader[:7] != "Bearer " {
				http.Error(w, "Unauthorized: Missing or invalid token", http.StatusUnauthorized)
				return
			}
			tokenStr := authHeader[7:]
			claims, err := tokenManager.Verify(tokenStr)
			if err != nil {
				http.Error(w, "Unauthorized: Invalid session", http.StatusUnauthorized)
				return
			}

			// Parse Multipart Form
			err = r.ParseMultipartForm(100 << 20) // Allow up to 100MB
			if err != nil {
				http.Error(w, "File size too large", http.StatusBadRequest)
				return
			}

			// Read file payload
			file, handler, err := r.FormFile("video")
			if err != nil {
				http.Error(w, "Invalid video payload", http.StatusBadRequest)
				return
			}
			defer file.Close()

			// Prepare file storage
			var videoUrl string
			if cld != nil {
				resp, err := cld.Upload.Upload(context.Background(), file, uploader.UploadParams{
					ResourceType: "video",
					Folder:       "gipjazes",
				})
				if err != nil {
					http.Error(w, fmt.Sprintf("Failed to upload to Cloudinary: %v", err), http.StatusInternalServerError)
					return
				}
				videoUrl = resp.SecureURL
			} else {
				os.MkdirAll("uploads", os.ModePerm)
				safeFilename := fmt.Sprintf("%d_%s", time.Now().UnixNano(), handler.Filename)
				localPath := filepath.Join("uploads", safeFilename)
				out, err := os.Create(localPath)
				if err != nil {
					http.Error(w, "Failed to save the file stream", http.StatusInternalServerError)
					return
				}
				defer out.Close()
				_, err = io.Copy(out, file)
				if err != nil {
					http.Error(w, "Failed writing file payload", http.StatusInternalServerError)
					return
				}
				videoUrl = publicDomain + "/uploads/" + safeFilename
			}

			// Create a proper Video record in the DB using the native Postgres repo pointer
			vid := &pb.Video{
				CreatorId:   claims.UserID,
				VideoUrl:    videoUrl,
				Description: r.FormValue("description"), // Can be retrieved from formData text input
			}

			err = videoRepo.CreateVideo(context.Background(), vid)
			if err != nil {
				http.Error(w, fmt.Sprintf("Failed to link video with DB: %v", err), http.StatusInternalServerError)
				return
			}

			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]interface{}{"success": true, "video": vid})
		})

		mux.HandleFunc("/api/profile/avatar", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" { return }

			authHeader := r.Header.Get("Authorization")
			if len(authHeader) < 8 { http.Error(w, "Unauthorized", http.StatusUnauthorized); return }
			_, err := tokenManager.Verify(authHeader[7:])
			if err != nil { http.Error(w, "Unauthorized", http.StatusUnauthorized); return }

			err = r.ParseMultipartForm(10 << 20) // 10MB
			if err != nil { http.Error(w, "File too large", http.StatusBadRequest); return }

			file, _, err := r.FormFile("avatar")
			if err != nil { http.Error(w, "Missing file", http.StatusBadRequest); return }
			defer file.Close()

			var avatarUrl string
			if cloudinaryURL != "" {
				cld, _ := cloudinary.NewFromURL(cloudinaryURL)
				uploadResult, err := cld.Upload.Upload(context.Background(), file, uploader.UploadParams{
					Folder: "gipjazes_avatars",
				})
				if err != nil { http.Error(w, "Cloudinary upload failed", http.StatusInternalServerError); return }
				avatarUrl = uploadResult.SecureURL
			} else {
				// Local fallback if no cloudinary
				tempFile, err := os.CreateTemp("uploads", "avatar-*.jpg")
				if err != nil { http.Error(w, "Local save failed", http.StatusInternalServerError); return }
				defer tempFile.Close()
				io.Copy(tempFile, file)
				avatarUrl = publicDomain + "/uploads/" + filepath.Base(tempFile.Name())
			}

			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]interface{}{"success": true, "avatar_url": avatarUrl})
		})

		mux.HandleFunc("/api/profile", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" {
				return
			}

			authHeader := r.Header.Get("Authorization")
			if len(authHeader) < 8 || authHeader[:7] != "Bearer " {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}
			tokenStr := authHeader[7:]
			claims, err := tokenManager.Verify(tokenStr)
			if err != nil {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			// Check if we are requesting an external profile
			targetUserID := r.URL.Query().Get("user_id")
			if targetUserID == "" {
				targetUserID = claims.UserID
			}

			// Get User Data
			user, bio, err := srv.userRepo.GetUserByID(context.Background(), targetUserID)
			if err != nil {
				http.Error(w, "User not found", http.StatusNotFound)
				return
			}

			// Get Follow Stats
			followers, following, _ := srv.userRepo.GetFollowCounts(context.Background(), targetUserID)

			// Get User Videos
			videos, err := srv.videoRepo.GetVideosByUserID(context.Background(), targetUserID)
			if err != nil {
				videos = []*pb.Video{} // Fallback
			}

			// Get Total Likes
			totalLikes, _ := srv.videoRepo.GetTotalLikesByUserID(context.Background(), targetUserID)

			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]interface{}{
				"user":        user,
				"bio":         bio,
				"followers":   followers,
				"following":   following,
				"videos":      videos,
				"total_likes": totalLikes,
			})
		})

		mux.HandleFunc("/api/follow", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" {
				return
			}

			authHeader := r.Header.Get("Authorization")
			if len(authHeader) < 8 || authHeader[:7] != "Bearer " {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}
			tokenStr := authHeader[7:]
			claims, err := tokenManager.Verify(tokenStr)
			if err != nil {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			var req map[string]string
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				http.Error(w, "Bad request", http.StatusBadRequest)
				return
			}
			followeeID := req["followee_id"]
			if followeeID == "" {
				http.Error(w, "Missing followee_id", http.StatusBadRequest)
				return
			}

			err = srv.userRepo.FollowUser(context.Background(), claims.UserID, followeeID)
			if err != nil {
				http.Error(w, "Failed to follow user", http.StatusInternalServerError)
				return
			}

			// Fire Notification
			_ = srv.adminRepo.CreateNotification(context.Background(), followeeID, claims.UserID, "follow", "New Follower", "Someone started following you!", nil)

			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]interface{}{"success": true})
		})

		mux.HandleFunc("/api/unfollow", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" {
				return
			}

			authHeader := r.Header.Get("Authorization")
			if len(authHeader) < 8 || authHeader[:7] != "Bearer " {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}
			tokenStr := authHeader[7:]
			claims, err := tokenManager.Verify(tokenStr)
			if err != nil {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			var req map[string]string
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				http.Error(w, "Bad request", http.StatusBadRequest)
				return
			}
			followeeID := req["followee_id"]
			if followeeID == "" {
				http.Error(w, "Missing followee_id", http.StatusBadRequest)
				return
			}

			err = srv.userRepo.UnfollowUser(context.Background(), claims.UserID, followeeID)
			if err != nil {
				http.Error(w, "Failed to unfollow user", http.StatusInternalServerError)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]interface{}{"success": true})
		})

		mux.HandleFunc("/api/followers", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" {
				return
			}

			userID := r.URL.Query().Get("user_id")
			if userID == "" {
				http.Error(w, "Missing user_id", http.StatusBadRequest)
				return
			}

			users, err := srv.userRepo.GetFollowers(context.Background(), userID)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(users)
		})

		mux.HandleFunc("/api/following", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" {
				return
			}

			userID := r.URL.Query().Get("user_id")
			if userID == "" {
				http.Error(w, "Missing user_id", http.StatusBadRequest)
				return
			}

			users, err := srv.userRepo.GetFollowing(context.Background(), userID)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(users)
		})

		mux.HandleFunc("/api/comments", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" {
				return
			}

			if r.Method == "GET" {
				videoID := r.URL.Query().Get("video_id")
				if videoID == "" {
					http.Error(w, "Missing video_id", http.StatusBadRequest)
					return
				}
				comments, err := srv.videoRepo.GetCommentsByVideoID(context.Background(), videoID)
				if err != nil {
					http.Error(w, err.Error(), http.StatusInternalServerError)
					return
				}
				w.Header().Set("Content-Type", "application/json")
				json.NewEncoder(w).Encode(comments)
				return
			}

			if r.Method == "POST" {
				// Authenticate
				authHeader := r.Header.Get("Authorization")
				if len(authHeader) < 8 || authHeader[:7] != "Bearer " {
					http.Error(w, "Unauthorized", http.StatusUnauthorized)
					return
				}
				tokenStr := authHeader[7:]
				claims, err := tokenManager.Verify(tokenStr)
				if err != nil {
					http.Error(w, "Unauthorized", http.StatusUnauthorized)
					return
				}

				var req map[string]string
				if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
					http.Error(w, "Bad request", http.StatusBadRequest)
					return
				}

				videoID := req["video_id"]
				content := req["content"]

				if videoID == "" || content == "" {
					http.Error(w, "Missing video_id or content", http.StatusBadRequest)
					return
				}

				newCount, err := srv.videoRepo.CreateComment(context.Background(), videoID, claims.UserID, content)
				if err != nil {
					log.Printf("Comment create err: %v", err)
					http.Error(w, err.Error(), http.StatusInternalServerError)
					return
				}

				// Fire Notification
				_ = srv.adminRepo.CreateNotification(context.Background(), videoID, claims.UserID, "comment", "New Comment", content, nil)

				w.Header().Set("Content-Type", "application/json")
				json.NewEncoder(w).Encode(map[string]interface{}{"success": true, "new_count": newCount})
				return
			}
		})

		mux.HandleFunc("/api/live/list", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			list, err := srv.videoRepo.GetLiveBroadcasts(context.Background())
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(list)
		})

		mux.HandleFunc("/api/live/start", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" { return }
			
			authHeader := r.Header.Get("Authorization")
			if len(authHeader) < 8 { http.Error(w, "Unauthorized", http.StatusUnauthorized); return }
			claims, err := tokenManager.Verify(authHeader[7:])
			if err != nil { http.Error(w, "Unauthorized", http.StatusUnauthorized); return }

			var req struct { Title string `json:"title"` }
			json.NewDecoder(r.Body).Decode(&req)
			
			id, err := srv.videoRepo.StartLive(context.Background(), claims.UserID, req.Title)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			json.NewEncoder(w).Encode(map[string]interface{}{"success": true, "live_id": id})
		})

		mux.HandleFunc("/api/search", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
			if r.Method == "OPTIONS" {
				return
			}

			q := r.URL.Query().Get("q")
			if q == "" {
				w.Header().Set("Content-Type", "application/json")
				json.NewEncoder(w).Encode([]interface{}{})
				return
			}

			var videos []*pb.Video
			var err error
			if len(q) > 0 && q[0] == '#' {
				videos, err = srv.videoRepo.SearchByHashtag(context.Background(), q[1:])
			} else {
				videos, err = srv.videoRepo.SearchVideos(context.Background(), q)
			}
			
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}

			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(videos)
		})

		mux.HandleFunc("/api/video/view", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
			if r.Method == "OPTIONS" {
				return
			}
			var req struct {
				VideoID string `json:"video_id"`
			}
			json.NewDecoder(r.Body).Decode(&req)
			_ = srv.videoRepo.IncrementViewCount(context.Background(), req.VideoID)
			w.WriteHeader(http.StatusOK)
		})

		mux.HandleFunc("/api/messages", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" {
				return
			}
			authHeader := r.Header.Get("Authorization")
			if len(authHeader) < 8 || authHeader[:7] != "Bearer " {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}
			tokenStr := authHeader[7:]
			claims, err := tokenManager.Verify(tokenStr)
			if err != nil {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			if r.Method == "GET" {
				convID := r.URL.Query().Get("conversation_id")
				if convID != "" {
					msgs, err := srv.messageRepo.GetConversationMessages(context.Background(), convID, 50)
					if err != nil {
						http.Error(w, err.Error(), http.StatusInternalServerError)
						return
					}
					w.Header().Set("Content-Type", "application/json")
					json.NewEncoder(w).Encode(msgs)
				} else {
					chats, err := srv.messageRepo.GetUserConversations(context.Background(), claims.UserID)
					if err != nil {
						http.Error(w, err.Error(), http.StatusInternalServerError)
						return
					}
					w.Header().Set("Content-Type", "application/json")
					json.NewEncoder(w).Encode(chats)
				}
				return
			}

			if r.Method == "POST" {
				var req struct {
					ConversationID string `json:"conversation_id"`
					Content        string `json:"content"`
				}
				if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
					http.Error(w, "Bad request", http.StatusBadRequest)
					return
				}
				msg, err := srv.messageRepo.SendMessage(context.Background(), req.ConversationID, claims.UserID, req.Content)
				if err != nil {
					http.Error(w, err.Error(), http.StatusInternalServerError)
					return
				}
				w.Header().Set("Content-Type", "application/json")
				json.NewEncoder(w).Encode(msg)
				return
			}
		})

		mux.HandleFunc("/api/messages/send_to_user", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" {
				return
			}
			authHeader := r.Header.Get("Authorization")
			if len(authHeader) < 8 || authHeader[:7] != "Bearer " {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}
			tokenStr := authHeader[7:]
			claims, err := tokenManager.Verify(tokenStr)
			if err != nil {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			var req struct {
				ReceiverID string `json:"receiver_id"`
				Content    string `json:"content"`
			}
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				http.Error(w, "Bad request", http.StatusBadRequest)
				return
			}

			convID, err := srv.messageRepo.FindOrCreateDirectConversation(context.Background(), claims.UserID, req.ReceiverID)
			if err != nil {
				http.Error(w, "Failed to create conversation", http.StatusInternalServerError)
				return
			}

			msg, err := srv.messageRepo.SendMessage(context.Background(), convID, claims.UserID, req.Content)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(msg)
		})



		mux.HandleFunc("/api/notifications", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" {
				return
			}

			authHeader := r.Header.Get("Authorization")
			if len(authHeader) < 8 || authHeader[:7] != "Bearer " {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}
			claims, err := tokenManager.Verify(authHeader[7:])
			if err != nil {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			alerts, err := srv.adminRepo.GetUserNotifications(context.Background(), claims.UserID)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(alerts)
		})

		mux.HandleFunc("/api/report", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" {
				return
			}
			authHeader := r.Header.Get("Authorization")
			if len(authHeader) < 8 || authHeader[:7] != "Bearer " {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}
			tokenStr := authHeader[7:]
			claims, err := tokenManager.Verify(tokenStr)
			if err != nil {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			if r.Method == "POST" {
				var req struct {
					VideoID string `json:"video_id"`
					Reason  string `json:"reason"`
				}
				if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
					http.Error(w, "Bad request", http.StatusBadRequest)
					return
				}
				if err := srv.videoRepo.CreateReport(context.Background(), claims.UserID, req.VideoID, req.Reason); err != nil {
					http.Error(w, err.Error(), http.StatusInternalServerError)
					return
				}
				w.Header().Set("Content-Type", "application/json")
				json.NewEncoder(w).Encode(map[string]bool{"success": true})
			}
		})

		mux.HandleFunc("/api/discover", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
			if r.Method == "OPTIONS" {
				return
			}

			videos, err := srv.videoRepo.GetTrendingVideos(context.Background(), 20)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(videos)
		})

		mux.HandleFunc("/api/like", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" {
				return
			}

			authHeader := r.Header.Get("Authorization")
			if len(authHeader) < 8 || authHeader[:7] != "Bearer " {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}
			tokenStr := authHeader[7:]
			claims, err := tokenManager.Verify(tokenStr)
			if err != nil {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			var req map[string]string
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				http.Error(w, "Bad request", http.StatusBadRequest)
				return
			}
			videoID := req["video_id"]
			if videoID == "" {
				http.Error(w, "Missing video_id", http.StatusBadRequest)
				return
			}

			isLiked, newCount, err := srv.videoRepo.ToggleLike(context.Background(), claims.UserID, videoID)
			if err != nil {
				log.Printf("Like toggle err: %v", err)
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}

			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]interface{}{"success": true, "is_liked": isLiked, "new_count": newCount})
		})

		mux.HandleFunc("/api/repost", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" {
				return
			}
			authHeader := r.Header.Get("Authorization")
			if len(authHeader) < 8 || authHeader[:7] != "Bearer " {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}
			claims, err := tokenManager.Verify(authHeader[7:])
			if err != nil {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			var req struct {
				VideoID string `json:"video_id"`
			}
			json.NewDecoder(r.Body).Decode(&req)
			if req.VideoID == "" {
				http.Error(w, "Missing video_id", http.StatusBadRequest)
				return
			}

			err = srv.videoRepo.RepostVideo(context.Background(), claims.UserID, req.VideoID)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]bool{"success": true})
		})

		mux.HandleFunc("/api/profile/update", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" {
				return
			}
			authHeader := r.Header.Get("Authorization")
			if len(authHeader) < 8 || authHeader[:7] != "Bearer " {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}
			claims, err := tokenManager.Verify(authHeader[7:])
			if err != nil {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			var req struct {
				Username    string `json:"username"`
				DisplayName string `json:"display_name"`
				Bio         string `json:"bio"`
				AvatarURL   string `json:"avatar_url"`
			}
			json.NewDecoder(r.Body).Decode(&req)

			err = srv.userRepo.UpdateProfile(context.Background(), claims.UserID, req.Username, req.DisplayName, req.Bio, req.AvatarURL)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]bool{"success": true})
		})

		mux.HandleFunc("/api/user/delete", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" {
				return
			}
			authHeader := r.Header.Get("Authorization")
			if len(authHeader) < 8 || authHeader[:7] != "Bearer " {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}
			claims, err := tokenManager.Verify(authHeader[7:])
			if err != nil {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			err = srv.userRepo.DeleteUser(context.Background(), claims.UserID)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]bool{"success": true})
		})

		mux.HandleFunc("/api/auth/forgot-password", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
			if r.Method == "OPTIONS" {
				return
			}
			var req struct {
				Email string `json:"email"`
			}
			json.NewDecoder(r.Body).Decode(&req)
			// Generate a simple token for simulation (in real life use secure random)
			token := fmt.Sprintf("RECOVER_%d", time.Now().Unix())
			err := srv.userRepo.SetRecoveryToken(context.Background(), req.Email, token)
			if err != nil {
				http.Error(w, "Email not found", http.StatusNotFound)
				return
			}
			// In a real app, send email. Here, just return it for ease of use in UI.
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]interface{}{"success": true, "recovery_token": token})
		})

		mux.HandleFunc("/api/auth/reset-password", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Content-Type", "application/json")
			var req struct {
				Token       string `json:"token"`
				NewPassword string `json:"new_password"`
			}
			json.NewDecoder(r.Body).Decode(&req)
			// Hash new password (using simple hash for demo or actual bcrypt if available)
			// Assuming there's a pkg/auth utility or just using string for now.
			err := srv.userRepo.ResetPassword(context.Background(), req.Token, req.NewPassword)
			if err != nil {
				http.Error(w, err.Error(), http.StatusBadRequest)
				return
			}
			json.NewEncoder(w).Encode(map[string]bool{"success": true})
		})

		mux.HandleFunc("/api/wallet/balance", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" {
				return
			}
			authHeader := r.Header.Get("Authorization")
			if len(authHeader) < 8 || authHeader[:7] != "Bearer " {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}
			tokenStr := authHeader[7:]
			claims, err := tokenManager.Verify(tokenStr)
			if err != nil {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			balance, err := srv.userRepo.GetBalance(context.Background(), claims.UserID)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]interface{}{"balance": balance})
		})

		mux.HandleFunc("/api/wallet/gift", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" {
				return
			}
			authHeader := r.Header.Get("Authorization")
			if len(authHeader) < 8 || authHeader[:7] != "Bearer " {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}
			tokenStr := authHeader[7:]
			claims, err := tokenManager.Verify(tokenStr)
			if err != nil {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			var req struct {
				ReceiverID string `json:"receiver_id"`
				Amount     int64  `json:"amount"`
			}
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				http.Error(w, "Bad request", http.StatusBadRequest)
				return
			}

			err = srv.userRepo.SendGift(context.Background(), claims.UserID, req.ReceiverID, req.Amount)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}

			// Fire Notification
			_ = srv.adminRepo.CreateNotification(context.Background(), req.ReceiverID, claims.UserID, "gift", "Virtual Gift Received! 🎁", fmt.Sprintf("You received %d tokens.", req.Amount), nil)

			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]interface{}{"success": true})
		})

		// --- Admin Dashboard Endpoints ---
		mux.HandleFunc("/api/admin/stats", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" { return }
			stats, err := srv.adminRepo.GetStats(context.Background())
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(stats)
		})

		mux.HandleFunc("/api/admin/reports", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" { return }
			reports, err := srv.adminRepo.GetRecentReports(context.Background(), 10)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(reports)
		})

		mux.HandleFunc("/api/admin/transactions", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" { return }
			txs, err := srv.adminRepo.GetTransactions(context.Background(), 15)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(txs)
		})

		mux.HandleFunc("/api/admin/ban", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			if r.Method == "OPTIONS" { return }
			if r.Method != "POST" { http.Error(w, "Method not allowed", http.StatusMethodNotAllowed); return }

			var req struct {
				UserID string `json:"user_id"`
				Reason string `json:"reason"`
			}
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				http.Error(w, "Bad request", http.StatusBadRequest)
				return
			}
			err := srv.adminRepo.BanUser(context.Background(), req.UserID, req.Reason)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]bool{"success": true})
		})

		// Expose Uploads directory natively so App.tsx can stream the local files directly!
		// Expose Uploads directory with CORS so the frontend (Vercel) can stream videos from the backend (Render)
		mux.Handle("/uploads/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Range, Content-Type")
			w.Header().Set("Access-Control-Expose-Headers", "Content-Length, Content-Range")
			if r.Method == "OPTIONS" {
				w.WriteHeader(http.StatusOK)
				return
			}
			http.StripPrefix("/uploads/", http.FileServer(http.Dir("./uploads"))).ServeHTTP(w, r)
		}))

		log.Printf("🌐 GIPJAZES V HTTP REST Backend running at :%s", appPort)
		if err := http.ListenAndServe(":"+appPort, mux); err != nil {
			log.Fatalf("HTTP server failed: %v", err)
		}
	}()

	// --- 8. Start gRPC Server ---
	log.Printf("🚀 GIPJAZES V gRPC Backend running at %v", lis.Addr())
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
func initDB(db *sql.DB) error {
	log.Println("Checking and initializing database schema...")
	schema := `
	CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

	CREATE TABLE IF NOT EXISTS users (
		id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
		username VARCHAR(50) UNIQUE NOT NULL,
		display_name VARCHAR(100) NOT NULL,
		email VARCHAR(255) UNIQUE NOT NULL,
		password_hash TEXT NOT NULL DEFAULT '',
		avatar_url TEXT,
		is_verified BOOLEAN DEFAULT FALSE,
		is_banned BOOLEAN DEFAULT FALSE,
		ban_reason TEXT,
		balance BIGINT DEFAULT 0,
		bio TEXT,
		created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
		updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
		deleted_at TIMESTAMP WITH TIME ZONE
	);

	DO $$ 
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
					   WHERE table_name='users' AND column_name='password_hash') THEN
			ALTER TABLE users ADD COLUMN password_hash TEXT NOT NULL DEFAULT '';
		END IF;
	END $$;

	CREATE TABLE IF NOT EXISTS videos (
		id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
		creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		video_url TEXT NOT NULL,
		thumbnail_url TEXT,
		description TEXT,
		category VARCHAR(50),
		like_count INTEGER DEFAULT 0,
		share_count INTEGER DEFAULT 0,
		comment_count INTEGER DEFAULT 0,
		view_count INTEGER DEFAULT 0,
		is_featured BOOLEAN DEFAULT FALSE,
		hashtags TEXT[] DEFAULT '{}',
		created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
		deleted_at TIMESTAMP WITH TIME ZONE
	);

	CREATE TABLE IF NOT EXISTS follows (
		follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
		PRIMARY KEY (follower_id, following_id)
	);

	CREATE TABLE IF NOT EXISTS likes (
		user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
		created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
		PRIMARY KEY (user_id, video_id)
	);

	CREATE TABLE IF NOT EXISTS messages (
		id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
		conversation_id UUID NOT NULL,
		sender_id UUID NOT NULL REFERENCES users(id),
		content TEXT NOT NULL,
		created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
	);

	CREATE TABLE IF NOT EXISTS comments (
		id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
		video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
		user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		content TEXT NOT NULL,
		created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
	);

	CREATE TABLE IF NOT EXISTS reports (
		id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
		reporter_id UUID NOT NULL REFERENCES users(id),
		video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
		reason TEXT NOT NULL,
		created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
	);

	CREATE TABLE IF NOT EXISTS transactions (
		id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
		sender_id UUID REFERENCES users(id),
		receiver_id UUID REFERENCES users(id),
		amount BIGINT NOT NULL,
		type VARCHAR(50),
		created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
	);

	CREATE TABLE IF NOT EXISTS live_broadcasts (
		id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
		host_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		title TEXT,
		is_active BOOLEAN DEFAULT TRUE,
		view_count INTEGER DEFAULT 0,
		created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
	);

	CREATE INDEX IF NOT EXISTS idx_videos_creator_id ON videos(creator_id);
	CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
	CREATE INDEX IF NOT EXISTS idx_comments_video_id ON comments(video_id);

	-- New Tables for Extended Features
	CREATE TABLE IF NOT EXISTS reposts (
		id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
		user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
		created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
		UNIQUE(user_id, video_id)
	);

	CREATE TABLE IF NOT EXISTS notifications (
		id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
		user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		actor_id UUID REFERENCES users(id) ON DELETE SET NULL,
		type VARCHAR(50),
		title TEXT,
		body TEXT,
		reference_id UUID,
		is_read BOOLEAN DEFAULT FALSE,
		created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
	);
	CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);

	DO $$ 
	BEGIN
		-- Add recovery columns to users
		IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='recovery_token') THEN
			ALTER TABLE users ADD COLUMN recovery_token TEXT;
			ALTER TABLE users ADD COLUMN recovery_expires TIMESTAMP WITH TIME ZONE;
		END IF;
		-- Add hashtags to videos
		IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='videos' AND column_name='hashtags') THEN
			ALTER TABLE videos ADD COLUMN hashtags TEXT[] DEFAULT '{}';
		END IF;
	END $$;
	`

	_, err := db.Exec(schema)
	if err != nil {
		return fmt.Errorf("database schema init failed: %v", err)
	}

	log.Println("Database schema checked and healthy!")
	return nil
}

func main_dummy() {
	// this is just to keep the file structure if needed, but not used
}
