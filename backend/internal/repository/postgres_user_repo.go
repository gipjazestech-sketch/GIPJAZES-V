package repository

import (
	"context"
	"database/sql"
	"fmt"

	pb "github.com/gipjazes/backend/internal/proto"
)

type PostgresUserRepository struct {
	db *sql.DB
}

func NewPostgresUserRepository(db *sql.DB) *PostgresUserRepository {
	return &PostgresUserRepository{db: db}
}

func (r *PostgresUserRepository) CreateUser(ctx context.Context, user *pb.User, email string, passwordHash string) error {
	query := `
		INSERT INTO users (username, display_name, email, avatar_url, password_hash)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id
	`

	err := r.db.QueryRowContext(ctx, query,
		user.Username, user.DisplayName, email, user.AvatarUrl, passwordHash,
	).Scan(&user.Id)

	return err
}

func (r *PostgresUserRepository) GetByEmail(ctx context.Context, email string) (*pb.User, string, error) {
	query := `SELECT id, username, display_name, avatar_url, is_verified, password_hash FROM users WHERE (email = $1 OR username = $1) AND deleted_at IS NULL`

	user := &pb.User{}
	var passHash sql.NullString

	err := r.db.QueryRowContext(ctx, query, email).Scan(
		&user.Id, &user.Username, &user.DisplayName, &user.AvatarUrl, &user.IsVerified, &passHash,
	)

	if err != nil {
		return nil, "", err
	}
	return user, passHash.String, nil
}

func (r *PostgresUserRepository) GetUserByID(ctx context.Context, id string) (*pb.User, error) {
	query := `SELECT id, username, display_name, avatar_url, is_verified FROM users WHERE id = $1 AND deleted_at IS NULL`

	user := &pb.User{}

	err := r.db.QueryRowContext(ctx, query, id).Scan(
		&user.Id, &user.Username, &user.DisplayName, &user.AvatarUrl, &user.IsVerified,
	)

	if err != nil {
		return nil, err
	}
	return user, nil
}

func (r *PostgresUserRepository) FollowUser(ctx context.Context, followerID, followingID string) error {
	query := `INSERT INTO follows (follower_id, following_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`
	_, err := r.db.ExecContext(ctx, query, followerID, followingID)
	return err
}

func (r *PostgresUserRepository) UnfollowUser(ctx context.Context, followerID, followingID string) error {
	query := `DELETE FROM follows WHERE follower_id = $1 AND following_id = $2`
	_, err := r.db.ExecContext(ctx, query, followerID, followingID)
	return err
}

func (r *PostgresUserRepository) GetFollowCounts(ctx context.Context, userID string) (int, int, error) {
	var followers, following int
	queryFollowers := `SELECT COUNT(*) FROM follows WHERE following_id = $1`
	queryFollowing := `SELECT COUNT(*) FROM follows WHERE follower_id = $1`

	err := r.db.QueryRowContext(ctx, queryFollowers, userID).Scan(&followers)
	if err != nil {
		return 0, 0, err
	}
	err = r.db.QueryRowContext(ctx, queryFollowing, userID).Scan(&following)
	return followers, following, err
}

func (r *PostgresUserRepository) GetFollowers(ctx context.Context, userID string) ([]*pb.User, error) {
	query := `
		SELECT u.id, u.username, u.display_name, u.avatar_url, u.is_verified 
		FROM users u 
		JOIN follows f ON u.id = f.follower_id 
		WHERE f.following_id = $1 AND u.deleted_at IS NULL
	`
	rows, err := r.db.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []*pb.User
	for rows.Next() {
		u := &pb.User{}
		if err := rows.Scan(&u.Id, &u.Username, &u.DisplayName, &u.AvatarUrl, &u.IsVerified); err != nil {
			return nil, err
		}
		users = append(users, u)
	}
	return users, nil
}

func (r *PostgresUserRepository) GetFollowing(ctx context.Context, userID string) ([]*pb.User, error) {
	query := `
		SELECT u.id, u.username, u.display_name, u.avatar_url, u.is_verified 
		FROM users u 
		JOIN follows f ON u.id = f.following_id 
		WHERE f.follower_id = $1 AND u.deleted_at IS NULL
	`
	rows, err := r.db.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []*pb.User
	for rows.Next() {
		u := &pb.User{}
		if err := rows.Scan(&u.Id, &u.Username, &u.DisplayName, &u.AvatarUrl, &u.IsVerified); err != nil {
			return nil, err
		}
		users = append(users, u)
	}
	return users, nil
}

func (r *PostgresUserRepository) GetBalance(ctx context.Context, userID string) (int64, error) {
	var balance int64
	err := r.db.QueryRowContext(ctx, "SELECT balance FROM users WHERE id = $1", userID).Scan(&balance)
	return balance, err
}

func (r *PostgresUserRepository) SendGift(ctx context.Context, senderID, receiverID string, amount int64) error {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// 1. Check sender balance
	var senderBalance int64
	err = tx.QueryRowContext(ctx, "SELECT balance FROM users WHERE id = $1 FOR UPDATE", senderID).Scan(&senderBalance)
	if err != nil {
		return err
	}
	if senderBalance < amount {
		return fmt.Errorf("insufficient balance")
	}

	// 2. Deduct from sender
	_, err = tx.ExecContext(ctx, "UPDATE users SET balance = balance - $1 WHERE id = $2", amount, senderID)
	if err != nil {
		return err
	}

	// 3. Add to receiver
	_, err = tx.ExecContext(ctx, "UPDATE users SET balance = balance + $1 WHERE id = $2", amount, receiverID)
	if err != nil {
		return err
	}

	// 4. Record transaction
	_, err = tx.ExecContext(ctx, "INSERT INTO transactions (sender_id, receiver_id, amount, type) VALUES ($1, $2, $3, 'gift')", senderID, receiverID, amount)
	if err != nil {
		return err
	}

	return tx.Commit()
}
