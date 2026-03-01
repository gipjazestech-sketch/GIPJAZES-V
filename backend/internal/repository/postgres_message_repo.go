package repository

import (
	"context"
	"database/sql"
	"time"
)

type Message struct {
	ID             string    `json:"id"`
	ConversationID string    `json:"conversation_id"`
	SenderID       string    `json:"sender_id"`
	Content        string    `json:"content"`
	IsRead         bool      `json:"is_read"`
	CreatedAt      time.Time `json:"created_at"`
}

type Conversation struct {
	ID          string    `json:"id"`
	Name        string    `json:"name,omitempty"`
	IsGroup     bool      `json:"is_group"`
	LastMessage string    `json:"last_message,omitempty"`
	CreatedAt   time.Time `json:"created_at"`
}

type PostgresMessageRepository struct {
	db *sql.DB
}

func NewPostgresMessageRepository(db *sql.DB) *PostgresMessageRepository {
	return &PostgresMessageRepository{db: db}
}

// FindOrCreateDirectConversation finds a 1:1 conversation between two users or creates one if it doesn't exist
func (r *PostgresMessageRepository) FindOrCreateDirectConversation(ctx context.Context, user1, user2 string) (string, error) {
	var convID string
	query := `
		SELECT c.id
		FROM conversations c
		JOIN conversation_members cm1 ON c.id = cm1.conversation_id
		JOIN conversation_members cm2 ON c.id = cm2.conversation_id
		WHERE cm1.user_id = $1 AND cm2.user_id = $2 AND NOT c.is_group
		LIMIT 1
	`
	err := r.db.QueryRowContext(ctx, query, user1, user2).Scan(&convID)
	if err == nil {
		return convID, nil
	}
	if err != sql.ErrNoRows {
		return "", err
	}

	// Create new 1:1 conversation
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return "", err
	}
	defer tx.Rollback()

	err = tx.QueryRowContext(ctx, "INSERT INTO conversations (is_group) VALUES (FALSE) RETURNING id").Scan(&convID)
	if err != nil {
		return "", err
	}

	_, err = tx.ExecContext(ctx, "INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2), ($1, $3)", convID, user1, user2)
	if err != nil {
		return "", err
	}

	return convID, tx.Commit()
}

func (r *PostgresMessageRepository) CreateGroupConversation(ctx context.Context, name string, memberIDs []string) (string, error) {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return "", err
	}
	defer tx.Rollback()

	var convID string
	err = tx.QueryRowContext(ctx, "INSERT INTO conversations (name, is_group) VALUES ($1, TRUE) RETURNING id", name).Scan(&convID)
	if err != nil {
		return "", err
	}

	for _, userID := range memberIDs {
		_, err = tx.ExecContext(ctx, "INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2)", convID, userID)
		if err != nil {
			return "", err
		}
	}

	return convID, tx.Commit()
}

func (r *PostgresMessageRepository) SendMessage(ctx context.Context, conversationID, senderID, content string) (*Message, error) {
	query := `
		INSERT INTO messages (conversation_id, sender_id, content)
		VALUES ($1, $2, $3)
		RETURNING id, is_read, created_at
	`
	msg := &Message{
		ConversationID: conversationID,
		SenderID:       senderID,
		Content:        content,
	}

	err := r.db.QueryRowContext(ctx, query, conversationID, senderID, content).Scan(&msg.ID, &msg.IsRead, &msg.CreatedAt)
	if err != nil {
		return nil, err
	}

	return msg, nil
}

func (r *PostgresMessageRepository) GetConversationMessages(ctx context.Context, conversationID string, limit int) ([]*Message, error) {
	query := `
		SELECT id, sender_id, content, is_read, created_at
		FROM messages
		WHERE conversation_id = $1
		ORDER BY created_at DESC
		LIMIT $2
	`
	rows, err := r.db.QueryContext(ctx, query, conversationID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var messages []*Message
	for rows.Next() {
		msg := &Message{ConversationID: conversationID}
		err := rows.Scan(&msg.ID, &msg.SenderID, &msg.Content, &msg.IsRead, &msg.CreatedAt)
		if err != nil {
			return nil, err
		}
		messages = append(messages, msg)
	}
	return messages, nil
}

func (r *PostgresMessageRepository) GetUserConversations(ctx context.Context, userID string) ([]map[string]interface{}, error) {
	query := `
		SELECT 
			c.id, 
			c.name, 
			c.is_group,
			COALESCE((SELECT content FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1), '') as last_message,
			(SELECT created_at FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) as last_message_at,
			COALESCE((SELECT username FROM users u JOIN conversation_members cm ON u.id = cm.user_id WHERE cm.conversation_id = c.id AND cm.user_id != $1 LIMIT 1), '') as partner_username,
			COALESCE((SELECT avatar_url FROM users u JOIN conversation_members cm ON u.id = cm.user_id WHERE cm.conversation_id = c.id AND cm.user_id != $1 LIMIT 1), '') as partner_avatar_url,
			COALESCE((SELECT cm.user_id FROM conversation_members cm WHERE cm.conversation_id = c.id AND cm.user_id != $1 LIMIT 1)::text, '') as partner_id
		FROM conversations c
		JOIN conversation_members cm_me ON c.id = cm_me.conversation_id
		WHERE cm_me.user_id = $1
		ORDER BY last_message_at DESC NULLS LAST
	`
	rows, err := r.db.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var convs []map[string]interface{}
	for rows.Next() {
		var id, name, partnerUsername, partnerAvatarURL, partnerID, lastMessage string
		var isGroup bool
		var lastMessageAt sql.NullTime
		err := rows.Scan(&id, &name, &isGroup, &lastMessage, &lastMessageAt, &partnerUsername, &partnerAvatarURL, &partnerID)
		if err != nil {
			return nil, err
		}

		convName := name
		if !isGroup {
			convName = partnerUsername
		}

		convs = append(convs, map[string]interface{}{
			"id":              id,
			"name":            convName,
			"is_group":        isGroup,
			"last_message":    lastMessage,
			"last_message_at": lastMessageAt.Time,
			"partner_id":      partnerID,
			"avatar_url":      partnerAvatarURL,
		})
	}
	return convs, nil
}
