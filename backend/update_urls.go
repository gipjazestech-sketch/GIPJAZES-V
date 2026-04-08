package main

import (
	"context"
	"fmt"
	"log"

	"github.com/jackc/pgx/v5"
)

func main() {
	connStr := "postgresql://neondb_owner:npg_mWH4iehn3wku@ep-misty-frog-amra4cwk-pooler.c-5.us-east-1.aws.neon.tech/neondb?sslmode=require"
	conn, err := pgx.Connect(context.Background(), connStr)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v", err)
	}
	defer conn.Close(context.Background())

	query := "UPDATE videos SET video_url = REPLACE(video_url, 'http://localhost:8080', 'https://gipjazes-backend.onrender.com') WHERE video_url LIKE 'http://localhost:8080%';"
	tag, err := conn.Exec(context.Background(), query)
	if err != nil {
		log.Fatalf("Failed to execute update: %v", err)
	}

	fmt.Printf("Updated URLs. Rows affected: %d\n", tag.RowsAffected())
}
