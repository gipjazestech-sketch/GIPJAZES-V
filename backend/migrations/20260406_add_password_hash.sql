-- Migration: Add password_hash column to users
-- Purpose: Safely adds missing column to users table if it does not exist
-- Application: GIPJAZES V Backend

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='users' AND column_name='password_hash') THEN
        ALTER TABLE users ADD COLUMN password_hash TEXT;
        -- Set empty string for existing users if any, then make it NOT NULL
        UPDATE users SET password_hash = '' WHERE password_hash IS NULL;
        ALTER TABLE users ALTER COLUMN password_hash SET NOT NULL;
        RAISE NOTICE 'Column password_hash added to users table.';
    ELSE
        RAISE NOTICE 'Column password_hash already exists.';
    END IF;
END $$;
