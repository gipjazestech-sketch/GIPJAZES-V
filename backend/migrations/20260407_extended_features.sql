-- Migration: Add extended features for GIPJAZES V
-- Purpose: Support reposts, hashtags, password recovery, and more
-- Application: GIPJAZES V Backend

DO $$ 
BEGIN
    -- 1. Add password recovery columns to users
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='users' AND column_name='recovery_token') THEN
        ALTER TABLE users ADD COLUMN recovery_token TEXT;
        ALTER TABLE users ADD COLUMN recovery_expires TIMESTAMP WITH TIME ZONE;
    END IF;

    -- 2. Add hashtag support to videos if not present
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='videos' AND column_name='hashtags') THEN
        ALTER TABLE videos ADD COLUMN hashtags TEXT[] DEFAULT '{}';
    END IF;

    -- 3. Create reposts table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='reposts') THEN
        CREATE TABLE reposts (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(user_id, video_id)
        );
    END IF;

    -- 4. Create indexes for performance
    CREATE INDEX IF NOT EXISTS idx_videos_hashtags ON videos USING GIN(hashtags);
    CREATE INDEX IF NOT EXISTS idx_reposts_video_id ON reposts(video_id);
    CREATE INDEX IF NOT EXISTS idx_reposts_user_id ON reposts(user_id);

END $$;
