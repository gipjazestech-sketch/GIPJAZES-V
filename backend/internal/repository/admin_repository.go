package repository

import (
	"context"
	"database/sql"
	"time"
)

type AdminStats struct {
	TotalUsers     int64   `json:"total_users"`
	TotalVideos    int64   `json:"total_videos"`
	TotalTokens    float64 `json:"total_tokens"`
	TotalGifts     int64   `json:"total_gifts"`
	PendingReports int64   `json:"pending_reports"`
}

type AdminRepository struct {
	db *sql.DB
}

func NewAdminRepository(db *sql.DB) *AdminRepository {
	return &AdminRepository{db: db}
}

func (r *AdminRepository) GetStats(ctx context.Context) (*AdminStats, error) {
	stats := &AdminStats{}

	// Total Users
	err := r.db.QueryRowContext(ctx, "SELECT COUNT(*) FROM users").Scan(&stats.TotalUsers)
	if err != nil {
		return nil, err
	}

	// Total Videos
	err = r.db.QueryRowContext(ctx, "SELECT COUNT(*) FROM videos WHERE deleted_at IS NULL").Scan(&stats.TotalVideos)
	if err != nil {
		return nil, err
	}

	// Total Tokens (sum of balances)
	err = r.db.QueryRowContext(ctx, "SELECT COALESCE(SUM(balance), 0) FROM users").Scan(&stats.TotalTokens)
	if err != nil {
		return nil, err
	}

	// Total Gifts (count gift transactions)
	err = r.db.QueryRowContext(ctx, "SELECT COUNT(*) FROM transactions WHERE type = 'gift'").Scan(&stats.TotalGifts)
	if err != nil {
		return nil, err
	}

	// Pending Reports
	err = r.db.QueryRowContext(ctx, "SELECT COUNT(*) FROM reports WHERE status = 'pending'").Scan(&stats.PendingReports)
	if err != nil {
		// table might not exist if migration hasn't run yet, but we'll assume it exists
		stats.PendingReports = 0
	}

	return stats, nil
}

func (r *AdminRepository) GetRecentReports(ctx context.Context, limit int) ([]map[string]interface{}, error) {
	query := `
		SELECT r.id, r.reason, r.status, r.created_at, u.username as reporter, v.id as video_id, v.description as video_desc
		FROM reports r
		LEFT JOIN users u ON r.reporter_id = u.id
		JOIN videos v ON r.video_id = v.id
		ORDER BY r.created_at DESC
		LIMIT $1
	`
	rows, err := r.db.QueryContext(ctx, query, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var reports []map[string]interface{}
	for rows.Next() {
		var id, reason, status, reporter, videoID, videoDesc string
		var createdAt time.Time
		err := rows.Scan(&id, &reason, &status, &createdAt, &reporter, &videoID, &videoDesc)
		if err != nil {
			return nil, err
		}
		reports = append(reports, map[string]interface{}{
			"id":         id,
			"reason":     reason,
			"status":     status,
			"created_at": createdAt,
			"reporter":   reporter,
			"video_id":   videoID,
			"video_desc": videoDesc,
		})
	}
	return reports, nil
}

func (r *AdminRepository) GetTransactions(ctx context.Context, limit int) ([]map[string]interface{}, error) {
	query := `
		SELECT t.id, t.sender_id, t.receiver_id, t.amount, t.type, t.created_at, 
		       u1.username as from_user, u2.username as to_user
		FROM transactions t
		LEFT JOIN users u1 ON t.sender_id = u1.id
		LEFT JOIN users u2 ON t.receiver_id = u2.id
		ORDER BY t.created_at DESC
		LIMIT $1
	`
	rows, err := r.db.QueryContext(ctx, query, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var txs []map[string]interface{}
	for rows.Next() {
		var id string
		var senderID, receiverID, fromUser, toUser, txType sql.NullString
		var amount int64
		var createdAt time.Time
		err := rows.Scan(&id, &senderID, &receiverID, &amount, &txType, &createdAt, &fromUser, &toUser)
		if err != nil {
			return nil, err
		}
		txs = append(txs, map[string]interface{}{
			"id":         id,
			"from_id":    senderID.String,
			"to_id":      receiverID.String,
			"from_user":  fromUser.String,
			"to_user":    toUser.String,
			"amount":     amount,
			"type":       txType.String,
			"created_at": createdAt,
		})
	}
	return txs, nil
}

func (r *AdminRepository) BanUser(ctx context.Context, userID, reason string) error {
	query := `UPDATE users SET is_banned = TRUE, ban_reason = $1 WHERE id = $2`
	_, err := r.db.ExecContext(ctx, query, reason, userID)
	return err
}

func (r *AdminRepository) FeatureVideo(ctx context.Context, videoID string, featured bool) error {
	query := `UPDATE videos SET is_featured = $1 WHERE id = $2`
	_, err := r.db.ExecContext(ctx, query, featured, videoID)
	return err
}

func (r *AdminRepository) CreateNotification(ctx context.Context, userID, actorID, notifyType, title, body string, refID *string) error {
	query := `
		INSERT INTO notifications (user_id, actor_id, type, title, body, reference_id)
		VALUES ($1, $2, $3, $4, $5, $6)
	`
	_, err := r.db.ExecContext(ctx, query, userID, actorID, notifyType, title, body, refID)
	return err
}

func (r *AdminRepository) GetUserNotifications(ctx context.Context, userID string) ([]map[string]interface{}, error) {
	query := `
		SELECT n.id, n.type, n.title, n.body, n.created_at, n.is_read, u.username as actor_name, u.avatar_url as actor_avatar
		FROM notifications n
		LEFT JOIN users u ON n.actor_id = u.id
		WHERE n.user_id = $1
		ORDER BY n.created_at DESC
		LIMIT 50
	`
	rows, err := r.db.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var alerts []map[string]interface{}
	for rows.Next() {
		var id, nType, title, body, actorName, actorAvatar string
		var createdAt time.Time
		var isRead bool
		err := rows.Scan(&id, &nType, &title, &body, &createdAt, &isRead, &actorName, &actorAvatar)
		if err != nil {
			continue
		}
		alerts = append(alerts, map[string]interface{}{
			"id": id, "type": nType, "title": title, "body": body,
			"created_at": createdAt, "is_read": isRead,
			"actor_name": actorName, "actor_avatar": actorAvatar,
		})
	}
	return alerts, nil
}
