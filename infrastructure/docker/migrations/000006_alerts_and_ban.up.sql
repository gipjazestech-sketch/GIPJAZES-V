-- Notifications for User Engagement
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    actor_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Who triggered the event
    type VARCHAR(50) NOT NULL, -- follow, gift, message, mention
    title TEXT NOT NULL,
    body TEXT,
    reference_id UUID, -- Optional ID of video, message, etc.
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_created ON notifications(created_at);

-- Support Banning Users
ALTER TABLE users ADD COLUMN is_banned BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN ban_reason TEXT;

-- Manual Video Featuring
ALTER TABLE videos ADD COLUMN is_featured BOOLEAN DEFAULT FALSE;
CREATE INDEX idx_videos_featured ON videos(is_featured);
