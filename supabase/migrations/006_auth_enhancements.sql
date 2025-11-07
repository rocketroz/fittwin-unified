-- Auth Enhancements Migration
-- Adds refresh tokens, failed attempts tracking, and user roles

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'users'
  ) THEN
    EXECUTE $DDL$
      CREATE TABLE users (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        email TEXT UNIQUE,
        password_hash TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      )
    $DDL$;
  END IF;
END
$$;

-- Add failed_attempts column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS failed_attempts INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'shopper';
ALTER TABLE users ADD COLUMN IF NOT EXISTS name VARCHAR(255);

-- Create refresh_tokens table
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  revoked BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create index on user_id and token for fast lookups
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token ON refresh_tokens(token);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);

-- Function to increment failed attempts
CREATE OR REPLACE FUNCTION increment_failed_attempts(user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE users 
  SET failed_attempts = failed_attempts + 1
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up expired refresh tokens (run periodically)
CREATE OR REPLACE FUNCTION cleanup_expired_refresh_tokens()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM refresh_tokens
  WHERE expires_at < NOW() OR revoked = TRUE;
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- RLS Policies for refresh_tokens
ALTER TABLE refresh_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own refresh tokens" ON refresh_tokens;
CREATE POLICY "Users can view their own refresh tokens"
  ON refresh_tokens FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own refresh tokens" ON refresh_tokens;
CREATE POLICY "Users can delete their own refresh tokens"
  ON refresh_tokens FOR DELETE
  USING (auth.uid() = user_id);

-- Comment on tables
COMMENT ON TABLE refresh_tokens IS 'Stores JWT refresh tokens for token rotation';
COMMENT ON COLUMN users.failed_attempts IS 'Number of consecutive failed login attempts';
COMMENT ON COLUMN users.role IS 'User role: shopper, brand, admin';
