package transcoder

import (
	"context"
	"fmt"
	"log"
	"strings"

	transcoder "cloud.google.com/go/video/transcoder/apiv1"
	"cloud.google.com/go/video/transcoder/apiv1/transcoderpb"
)

// GCSObject represents the event data from GCS
type GCSObject struct {
	Bucket string `json:"bucket"`
	Name   string `json:"name"`
}

// TriggerTranscoder is a Cloud Function triggered by a GCS upload
func TriggerTranscoder(ctx context.Context, e GCSObject) error {
	// Only process files in the 'raw/' folder
	if !strings.HasPrefix(e.Name, "raw/") {
		return nil
	}

	projectID := "gipjazes-v-2026"
	location := "us-central1" // Adjusted to your region
	outputBucket := "gipjazes-hls-output"
	
	outputName := strings.Replace(e.Name, "raw/", "processed/", 1)
	outputName = strings.TrimSuffix(outputName, ".mp4")

	client, err := transcoder.NewClient(ctx)
	if err != nil {
		return fmt.Errorf("transcoder.NewClient: %v", err)
	}
	defer client.Close()

	req := &transcoderpb.CreateJobRequest{
		Parent: fmt.Sprintf("projects/%s/locations/%s", projectID, location),
		Job: &transcoderpb.Job{
			InputUri:  fmt.Sprintf("gs://%s/%s", e.Bucket, e.Name),
			OutputUri: fmt.Sprintf("gs://%s/%s/", outputBucket, outputName),
			// Use a preset for HLS (Adaptive Bitrate)
			JobConfig: &transcoderpb.Job_TemplateId{
				TemplateId: "preset/web-hd", 
			},
		},
	}

	resp, err := client.CreateJob(ctx, req)
	if err != nil {
		return fmt.Errorf("CreateJob: %v", err)
	}

	log.Printf("Transcoding Job Created: %s", resp.GetName())
	return nil
}
