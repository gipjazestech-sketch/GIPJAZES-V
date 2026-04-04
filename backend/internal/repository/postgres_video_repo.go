package repository

import (
	"context"
	"database/sql"
	"fmt"

	pb "github.com/gipjazes/backend/internal/proto"
	"google.golang.org/protobuf/types/known/timestamppb"
)

type PostgresVideoRepository struct {
	db *sql.DB
}

func NewPostgresVideoRepository(db *sql.DB) *PostgresVideoRepository {
	return &PostgresVideoRepository{db: db}
}

func (r *PostgresVideoRepository) GetVideoByID(ctx context.Context, id string) (*pb.Video, error) {
	query := `
		SELECT v.id, v.creator_id, v.video_url, v.thumbnail_url, v.description, 
		       v.like_count, v.share_count, v.comment_count, v.created_at,
		       u.username, u.display_name, u.avatar_url, u.is_verified
		FROM videos v
		JOIN users u ON v.creator_id = u.id
		WHERE v.id = $1 AND v.deleted_at IS NULL
	`

	video := &pb.Video{Creator: &pb.User{}}
	var createdAt sql.NullTime

	err := r.db.QueryRowContext(ctx, query, id).Scan(
		&video.Id, &video.CreatorId, &video.VideoUrl, &video.ThumbnailUrl, &video.Description,
		&video.LikeCount, &video.ShareCount, &video.CommentCount, &createdAt,
		&video.Creator.Username, &video.Creator.DisplayName, &video.Creator.AvatarUrl, &video.Creator.IsVerified,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("video not found")
		}
		return nil, err
	}

	if createdAt.Valid {
		video.CreatedAt = timestamppb.New(createdAt.Time)
	}

	return video, nil
}

func (r *PostgresVideoRepository) CreateVideo(ctx context.Context, video *pb.Video) error {
	query := `
		INSERT INTO videos (creator_id, video_url, thumbnail_url, description)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at
	`
	var createdAt sql.NullTime
	err := r.db.QueryRowContext(ctx, query,
		video.CreatorId, video.VideoUrl, video.ThumbnailUrl, video.Description,
	).Scan(&video.Id, &createdAt)

	if err != nil {
		return err
	}

	if createdAt.Valid {
		video.CreatedAt = timestamppb.New(createdAt.Time)
	}
	return nil
}

func (r *PostgresVideoRepository) SoftDelete(ctx context.Context, id string) error {
	query := `UPDATE videos SET deleted_at = CURRENT_TIMESTAMP WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	return err
}

func (r *PostgresVideoRepository) GetRecentVideos(ctx context.Context, limit, offset int64, category string) ([]*pb.Video, error) {
	query := `
		SELECT v.id, v.creator_id, v.video_url, v.thumbnail_url, v.description, 
		       v.like_count, v.share_count, v.comment_count, v.created_at,
		       u.username, u.display_name, u.avatar_url, u.is_verified
		FROM videos v
		JOIN users u ON v.creator_id = u.id
		WHERE v.deleted_at IS NULL
	`

	args := []interface{}{limit, offset}
	if category != "" {
		query += ` AND v.category = $3`
		args = append(args, category)
	}

	query += ` ORDER BY v.created_at DESC LIMIT $1 OFFSET $2`

	rows, err := r.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var videos []*pb.Video
	for rows.Next() {
		video := &pb.Video{Creator: &pb.User{}}
		var createdAt sql.NullTime

		err := rows.Scan(
			&video.Id, &video.CreatorId, &video.VideoUrl, &video.ThumbnailUrl, &video.Description,
			&video.LikeCount, &video.ShareCount, &video.CommentCount, &createdAt,
			&video.Creator.Username, &video.Creator.DisplayName, &video.Creator.AvatarUrl, &video.Creator.IsVerified,
		)
		if err != nil {
			return nil, err
		}

		if createdAt.Valid {
			video.CreatedAt = timestamppb.New(createdAt.Time)
		}

		videos = append(videos, video)
	}

	return videos, nil
}

func (r *PostgresVideoRepository) GetVideosByUserID(ctx context.Context, userID string) ([]*pb.Video, error) {
	query := `
		SELECT v.id, v.creator_id, v.video_url, v.thumbnail_url, v.description, 
		       v.like_count, v.share_count, v.comment_count, v.created_at,
		       u.username, u.display_name, u.avatar_url, u.is_verified
		FROM videos v
		JOIN users u ON v.creator_id = u.id
		WHERE v.creator_id = $1 AND v.deleted_at IS NULL
		ORDER BY v.created_at DESC
	`

	rows, err := r.db.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var videos []*pb.Video
	for rows.Next() {
		video := &pb.Video{Creator: &pb.User{}}
		var createdAt sql.NullTime

		err := rows.Scan(
			&video.Id, &video.CreatorId, &video.VideoUrl, &video.ThumbnailUrl, &video.Description,
			&video.LikeCount, &video.ShareCount, &video.CommentCount, &createdAt,
			&video.Creator.Username, &video.Creator.DisplayName, &video.Creator.AvatarUrl, &video.Creator.IsVerified,
		)
		if err != nil {
			return nil, err
		}

		if createdAt.Valid {
			video.CreatedAt = timestamppb.New(createdAt.Time)
		}

		videos = append(videos, video)
	}

	return videos, nil
}

func (r *PostgresVideoRepository) CreateComment(ctx context.Context, videoID, userID, content string) error {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// 1. Insert comment
	_, err = tx.ExecContext(ctx, "INSERT INTO comments (video_id, user_id, content) VALUES ($1, $2, $3)", videoID, userID, content)
	if err != nil {
		return err
	}

	// 2. Increment comment count
	_, err = tx.ExecContext(ctx, "UPDATE videos SET comment_count = comment_count + 1 WHERE id = $1", videoID)
	if err != nil {
		return err
	}

	return tx.Commit()
}

func (r *PostgresVideoRepository) GetCommentsByVideoID(ctx context.Context, videoID string) ([]map[string]interface{}, error) {
	query := `
		SELECT c.id, c.content, c.created_at, u.username, u.avatar_url
		FROM comments c
		JOIN users u ON c.user_id = u.id
		WHERE c.video_id = $1
		ORDER BY c.created_at ASC
	`
	rows, err := r.db.QueryContext(ctx, query, videoID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var comments []map[string]interface{}
	for rows.Next() {
		var id, content, username, avatarUrl string
		var createdAt sql.NullTime
		if err := rows.Scan(&id, &content, &createdAt, &username, &avatarUrl); err != nil {
			return nil, err
		}
		comments = append(comments, map[string]interface{}{
			"id":         id,
			"content":    content,
			"created_at": createdAt.Time,
			"username":   username,
			"avatar_url": avatarUrl,
		})
	}
	return comments, nil
}

func (r *PostgresVideoRepository) SearchVideos(ctx context.Context, query string) ([]*pb.Video, error) {
	sqlQuery := `
		SELECT v.id, v.creator_id, v.video_url, v.thumbnail_url, v.description, 
		       v.like_count, v.share_count, v.comment_count, v.created_at,
		       u.username, u.display_name, u.avatar_url, u.is_verified
		FROM videos v
		JOIN users u ON v.creator_id = u.id
		WHERE (v.description ILIKE $1 OR u.username ILIKE $1) AND v.deleted_at IS NULL
		ORDER BY v.created_at DESC
		LIMIT 20
	`
	searchTerm := "%" + query + "%"
	rows, err := r.db.QueryContext(ctx, sqlQuery, searchTerm)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var videos []*pb.Video
	for rows.Next() {
		video := &pb.Video{Creator: &pb.User{}}
		var createdAt sql.NullTime

		err := rows.Scan(
			&video.Id, &video.CreatorId, &video.VideoUrl, &video.ThumbnailUrl, &video.Description,
			&video.LikeCount, &video.ShareCount, &video.CommentCount, &createdAt,
			&video.Creator.Username, &video.Creator.DisplayName, &video.Creator.AvatarUrl, &video.Creator.IsVerified,
		)
		if err != nil {
			return nil, err
		}

		if createdAt.Valid {
			video.CreatedAt = timestamppb.New(createdAt.Time)
		}

		videos = append(videos, video)
	}

	return videos, nil
}

func (r *PostgresVideoRepository) ToggleLike(ctx context.Context, userID, videoID string) (bool, error) {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return false, err
	}
	defer tx.Rollback()

	var exists bool
	checkQuery := `SELECT EXISTS(SELECT 1 FROM likes WHERE user_id = $1 AND video_id = $2)`
	err = tx.QueryRowContext(ctx, checkQuery, userID, videoID).Scan(&exists)
	if err != nil {
		return false, err
	}

	var isLiked bool
	if exists {
		// Unlike
		_, err = tx.ExecContext(ctx, `DELETE FROM likes WHERE user_id = $1 AND video_id = $2`, userID, videoID)
		if err != nil {
			return false, err
		}
		_, err = tx.ExecContext(ctx, `UPDATE videos SET like_count = like_count - 1 WHERE id = $1`, videoID)
		if err != nil {
			return false, err
		}
		isLiked = false
	} else {
		// Like
		_, err = tx.ExecContext(ctx, `INSERT INTO likes (user_id, video_id) VALUES ($1, $2)`, userID, videoID)
		if err != nil {
			return false, err
		}
		_, err = tx.ExecContext(ctx, `UPDATE videos SET like_count = like_count + 1 WHERE id = $1`, videoID)
		if err != nil {
			return false, err
		}
		isLiked = true
	}

	err = tx.Commit()
	return isLiked, err
}

func (r *PostgresVideoRepository) CreateReport(ctx context.Context, reporterID, videoID, reason string) error {
	query := `
		INSERT INTO reports (reporter_id, video_id, reason)
		VALUES ($1, $2, $3)
	`
	_, err := r.db.ExecContext(ctx, query, reporterID, videoID, reason)
	return err
}

func (r *PostgresVideoRepository) GetTrendingVideos(ctx context.Context, limit int) ([]*pb.Video, error) {
	query := `
		SELECT v.id, v.creator_id, v.video_url, v.thumbnail_url, v.description, 
		       v.like_count, v.share_count, v.comment_count, v.created_at,
		       u.username, u.display_name, u.avatar_url, u.is_verified
		FROM videos v
		JOIN users u ON v.creator_id = u.id
		WHERE v.deleted_at IS NULL
		ORDER BY v.like_count DESC, v.created_at DESC
		LIMIT $1
	`
	rows, err := r.db.QueryContext(ctx, query, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var videos []*pb.Video
	for rows.Next() {
		video := &pb.Video{Creator: &pb.User{}}
		var createdAt sql.NullTime
		err := rows.Scan(
			&video.Id, &video.CreatorId, &video.VideoUrl, &video.ThumbnailUrl, &video.Description,
			&video.LikeCount, &video.ShareCount, &video.CommentCount, &createdAt,
			&video.Creator.Username, &video.Creator.DisplayName, &video.Creator.AvatarUrl, &video.Creator.IsVerified,
		)
		if err != nil {
			return nil, err
		}
		if createdAt.Valid {
			video.CreatedAt = timestamppb.New(createdAt.Time)
		}
		videos = append(videos, video)
	}
	return videos, nil
}
