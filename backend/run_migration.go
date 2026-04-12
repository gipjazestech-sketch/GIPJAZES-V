package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v5"
)

func main() {
	connStr := "postgresql://neondb_owner:npg_DPwZ7VNnCIL9@ep-aged-sky-amxwb0of-pooler.c-5.us-east-1.aws.neon.tech/neondb?channel_binding=require&sslmode=require"
	conn, err := pgx.Connect(context.Background(), connStr)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v", err)
	}
	defer conn.Close(context.Background())

	sqlFile, err := os.ReadFile("migrations/20260408_extended_fixes.sql")
	if err != nil {
		log.Fatalf("Failed to read sql file: %v", err)
	}

	_, err = conn.Exec(context.Background(), string(sqlFile))
	if err != nil {
		log.Fatalf("Failed to execute migration: %v", err)
	}

	fmt.Println("Migration applied successfully.")
}
