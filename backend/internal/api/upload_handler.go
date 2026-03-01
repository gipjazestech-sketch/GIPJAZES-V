package api

import (
	"context"
	"fmt"
	"time"

	"cloud.google.com/go/storage"
	pb "github.com/gipjazes/backend/internal/proto"
)

type UploadHandler struct {
	storageClient *storage.Client
	bucketName    string
}

func NewUploadHandler(client *storage.Client, bucket string) *UploadHandler {
	return &UploadHandler{storageClient: client, bucketName: bucket}
}

func (h *UploadHandler) GetUploadUrl(ctx context.Context, req *pb.SignedUrlRequest) (*pb.SignedUrlResponse, error) {
	// Generate a unique path for the raw video
	objectPath := fmt.Sprintf("raw/%d_%s", time.Now().UnixNano(), req.Filename)

	// Create Signed URL for PUT request
	opts := &storage.SignedURLOptions{
		Scheme:         storage.SigningSchemeV4,
		Method:         "PUT",
		GoogleAccessID: "gipjazes-v-sa@gipjazes-v-2026.iam.gserviceaccount.com",
		Expires:        time.Now().Add(15 * time.Minute),
		ContentType:    req.ContentType,
	}

	url, err := h.storageClient.Bucket(h.bucketName).SignedURL(objectPath, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to generate signed url: %v", err)
	}

	return &pb.SignedUrlResponse{
		UploadUrl: url,
		FilePath:  objectPath,
	}, nil
}
