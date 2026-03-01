-- Add Wallet Balance to Users
ALTER TABLE users ADD COLUMN balance BIGINT DEFAULT 0;

-- Transactions Table
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID REFERENCES users(id) ON DELETE SET NULL,
    receiver_id UUID REFERENCES users(id) ON DELETE SET NULL,
    amount BIGINT NOT NULL,
    type VARCHAR(20) NOT NULL, -- 'gift', 'withdrawal', 'reward'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_transactions_sender ON transactions(sender_id);
CREATE INDEX idx_transactions_receiver ON transactions(receiver_id);
