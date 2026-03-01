package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/redis/go-redis/v9"
)

func main() {
	log.Println("🎬 Starting GIPJAZES V Video Transcoding Worker...")

	// Connect to Redis for job queue
	rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
	defer rdb.Close()
	
	// Create context to handle graceful shutdown
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Wait for termination signal
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-c
		log.Println("Shutting down worker gracefully...")
		cancel()
	}()

	log.Println("Worker is listening for new video uploads to process...")
	
	// Simulated worker loop
	for {
		select {
		case <-ctx.Done():
			log.Println("Worker stopped entirely.")
			return
		default:
			// Pretend to look for tasks in Redis queue
			time.Sleep(5 * time.Second)
		}
	}
}
