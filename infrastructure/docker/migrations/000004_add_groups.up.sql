-- Group Messaging Support
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255), -- NULL for 1:1 chats
    is_group BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE conversation_members (
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (conversation_id, user_id)
);

-- Update messages to use conversation_id
ALTER TABLE messages ADD COLUMN conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE;

-- Index for fast lookup
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_conversation_members_user ON conversation_members(user_id);
