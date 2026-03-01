package api

import (
	"context"
	"fmt"

	pb "github.com/gipjazes/backend/internal/proto"
	"github.com/gipjazes/backend/internal/repository"
	"github.com/gipjazes/backend/pkg/auth"
	"golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
	userRepo     *repository.PostgresUserRepository
	tokenManager *auth.TokenManager
	pb.UnimplementedGIPJAZESServiceServer
}

func NewAuthHandler(repo *repository.PostgresUserRepository, tm *auth.TokenManager) *AuthHandler {
	return &AuthHandler{userRepo: repo, tokenManager: tm}
}

func (h *AuthHandler) Register(ctx context.Context, req *pb.RegisterRequest) (*pb.AuthResponse, error) {
	// 1. Hash Password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %v", err)
	}

	// 2. Create User in DB
	user := &pb.User{
		Username:    req.Username,
		DisplayName: req.Username, // Default display name to username
	}
	
	err = h.userRepo.CreateUser(ctx, user, req.Email, string(hashedPassword))
	if err != nil {
		return nil, fmt.Errorf("failed to create user: %v", err)
	}

	// 3. Generate Token
	token, err := h.tokenManager.Generate(user.Id)
	if err != nil {
		return nil, fmt.Errorf("failed to generate token: %v", err)
	}

	return &pb.AuthResponse{
		Token: token,
		User:  user,
	}, nil
}

func (h *AuthHandler) Login(ctx context.Context, req *pb.LoginRequest) (*pb.AuthResponse, error) {
	// 1. Get User from DB
	user, hashedPassword, err := h.userRepo.GetByEmail(ctx, req.Email)
	if err != nil {
		return nil, fmt.Errorf("invalid credentials")
	}

	// 2. Verify Password
	err = bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(req.Password))
	if err != nil {
		return nil, fmt.Errorf("invalid credentials")
	}

	// 3. Generate Token
	token, err := h.tokenManager.Generate(user.Id)
	if err != nil {
		return nil, fmt.Errorf("failed to generate token: %v", err)
	}

	return &pb.AuthResponse{
		Token: token,
		User:  user,
	}, nil
}
