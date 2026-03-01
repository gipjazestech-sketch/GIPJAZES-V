package main

import (
	"context"
	"log"
	"time"

	pb "github.com/gipjazes/backend/internal/proto"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func main() {
	// Connect to the gRPC server
	conn, err := grpc.Dial("localhost:9090", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()
	c := pb.NewGIPJAZESServiceClient(conn)

	// Contact the server and print out its response.
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()

	log.Println("🚀 RUNNING SMOKE TEST...")

	// 1. Test GetFeed
	r, err := c.GetFeed(ctx, &pb.GetFeedRequest{UserId: "test-user-123", Limit: 5})
	if err != nil {
		log.Fatalf("could not get feed: %v", err)
	}
	log.Printf("✅ Feed Response Success! Received %d videos.", len(r.GetVideos()))

	// 2. Test GetUploadUrl
	u, err := c.GetUploadUrl(ctx, &pb.SignedUrlRequest{Filename: "awesome_video.mp4", ContentType: "video/mp4"})
	if err != nil {
		log.Fatalf("could not get upload url: %v", err)
	}
	log.Printf("✅ Signed URL Success! URL: %s", u.GetUploadUrl())

	log.Println("✨ SMOKE TEST PASSED: Connection Handshake Verified.")
}
