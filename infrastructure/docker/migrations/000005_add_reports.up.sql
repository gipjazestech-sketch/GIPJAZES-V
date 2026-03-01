-- Content Moderation & Reporting
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID REFERENCES users(id) ON DELETE SET NULL,
    video_id UUID REFERENCES videos(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- pending, reviewed, resolved, dismissed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for admin lookup
CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_video ON reports(video_id);
