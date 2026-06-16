-- Lumina Database Schema Migration Script
-- Version: 1.0.0
-- Description: Core schema tables, indexes, and RLS policies for Lumina.

-- ----------------------------------------------------
-- 1. Tables Creation
-- ----------------------------------------------------

-- Users Table
CREATE TABLE IF NOT EXISTS users (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  google_uid   TEXT UNIQUE NOT NULL,
  email        TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url   TEXT,
  ai_name      TEXT DEFAULT 'Lumina',
  archetype    TEXT,              -- venter|analyst|jester|seeker|drifter
  onboarded    BOOLEAN DEFAULT FALSE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Conversations Table
CREATE TABLE IF NOT EXISTS conversations (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID REFERENCES users(id) ON DELETE CASCADE,
  started_at   TIMESTAMPTZ DEFAULT NOW(),
  summary      TEXT,             -- AI-generated summary after session ends
  turn_count   INT DEFAULT 0
);

-- Messages Table
CREATE TABLE IF NOT EXISTS messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  role            TEXT NOT NULL,  -- 'user' | 'assistant'
  content         TEXT,
  image_url       TEXT,           -- null if text-only
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- User Memory Table
CREATE TABLE IF NOT EXISTS user_memory (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  memory_type TEXT,              -- 'short_term' | 'long_term'
  content     TEXT NOT NULL,     -- natural language fact or summary
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  expires_at  TIMESTAMPTZ        -- null = permanent (long_term)
);

-- User Rate Limit Table
CREATE TABLE IF NOT EXISTS user_rate_limit (
  user_id       UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  message_count INT DEFAULT 0,
  reset_at      TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '1 day')
);

-- API Keys Table (Used server-side, never exposed to clients)
CREATE TABLE IF NOT EXISTS api_keys (
  id             SERIAL PRIMARY KEY,
  key_value      TEXT NOT NULL,
  provider       TEXT,              -- e.g. 'openrouter', 'groq', etc.
  on_cooldown    BOOLEAN DEFAULT FALSE,
  cooldown_until TIMESTAMPTZ,
  request_count  INT DEFAULT 0,
  last_used      TIMESTAMPTZ
);

-- ----------------------------------------------------
-- 2. Indexes
-- ----------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_messages_conv ON messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_user ON conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_user ON messages(user_id);
CREATE INDEX IF NOT EXISTS idx_memory_user ON user_memory(user_id);

-- ----------------------------------------------------
-- 3. Row-Level Security (RLS) Policies
-- ----------------------------------------------------

-- Enable RLS on all user-facing tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_memory ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_rate_limit ENABLE ROW LEVEL SECURITY;

-- Note: api_keys does not need RLS because it is only accessed via service_role key server-side.

-- Users Table Policies
-- In Supabase auth, sub represents auth.uid() or auth.jwt()->>'sub'.
-- The app stores auth user IDs in users.google_uid and stores public users.id
-- in related tables, so related-row policies join through users.google_uid.
DROP POLICY IF EXISTS "Users can read own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users see only their conversations" ON conversations;
DROP POLICY IF EXISTS "Users see only their messages" ON messages;
DROP POLICY IF EXISTS "Users insert only their messages" ON messages;
DROP POLICY IF EXISTS "Memory is private per user" ON user_memory;
DROP POLICY IF EXISTS "Rate limit readable by owner" ON user_rate_limit;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'Users can read own profile'
  ) THEN
    CREATE POLICY "Users can read own profile"
      ON users FOR SELECT
      USING (google_uid = auth.jwt() ->> 'sub');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'Users can update own profile'
  ) THEN
    CREATE POLICY "Users can update own profile"
      ON users FOR UPDATE
      USING (google_uid = auth.jwt() ->> 'sub');
  END IF;

  -- Conversations Table Policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'conversations' AND policyname = 'Users see only their conversations'
  ) THEN
    CREATE POLICY "Users see only their conversations"
      ON conversations FOR ALL
      USING (
        EXISTS (
          SELECT 1 FROM users
          WHERE users.id = conversations.user_id
            AND users.google_uid = auth.jwt() ->> 'sub'
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM users
          WHERE users.id = conversations.user_id
            AND users.google_uid = auth.jwt() ->> 'sub'
        )
      );
  END IF;

  -- Messages Table Policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'messages' AND policyname = 'Users see only their messages'
  ) THEN
    CREATE POLICY "Users see only their messages"
      ON messages FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM users
          WHERE users.id = messages.user_id
            AND users.google_uid = auth.jwt() ->> 'sub'
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'messages' AND policyname = 'Users insert only their messages'
  ) THEN
    CREATE POLICY "Users insert only their messages"
      ON messages FOR INSERT
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM users
          WHERE users.id = messages.user_id
            AND users.google_uid = auth.jwt() ->> 'sub'
        )
      );
  END IF;

  -- User Memory Table Policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_memory' AND policyname = 'Memory is private per user'
  ) THEN
    CREATE POLICY "Memory is private per user"
      ON user_memory FOR ALL
      USING (
        EXISTS (
          SELECT 1 FROM users
          WHERE users.id = user_memory.user_id
            AND users.google_uid = auth.jwt() ->> 'sub'
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM users
          WHERE users.id = user_memory.user_id
            AND users.google_uid = auth.jwt() ->> 'sub'
        )
      );
  END IF;

  -- User Rate Limit Table Policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_rate_limit' AND policyname = 'Rate limit readable by owner'
  ) THEN
    CREATE POLICY "Rate limit readable by owner"
      ON user_rate_limit FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM users
          WHERE users.id = user_rate_limit.user_id
            AND users.google_uid = auth.jwt() ->> 'sub'
        )
      );
  END IF;
END
$$;

-- ----------------------------------------------------
-- 4. RPC Helper Functions
-- ----------------------------------------------------
CREATE OR REPLACE FUNCTION increment_conversation_turn(conv_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE conversations
  SET turn_count = turn_count + 1
  WHERE id = conv_id;
END;
$$ LANGUAGE plpgsql;
