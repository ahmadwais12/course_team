-- ============================================================
-- CHAT FIX MIGRATION - voice call, voice message, file upload
-- Run this on the LIVE Supabase DB to fix:
--   1. Missing chat_uploads storage bucket (file/voice uploads failed)
--   2. Missing chat_calls.callee_id column (voice call insert failed)
--   3. Missing chat_calls RLS policies (all call ops denied)
--   4. Missing file columns on legacy messages table
-- ============================================================

-- 1. Create the chat_uploads storage bucket (missing from seed)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) VALUES
('chat_uploads', 'chat_uploads', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'video/mp4', 'audio/mp4', 'audio/m4a', 'audio/mpeg', 'audio/aac', 'audio/ogg', 'application/pdf', 'application/octet-stream'])
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload into chat_uploads
DROP POLICY IF EXISTS "chat_uploads_read" ON storage.objects;
CREATE POLICY "chat_uploads_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'chat_uploads');

DROP POLICY IF EXISTS "chat_uploads_insert" ON storage.objects;
CREATE POLICY "chat_uploads_insert" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'chat_uploads' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "chat_uploads_update" ON storage.objects;
CREATE POLICY "chat_uploads_update" ON storage.objects
  FOR UPDATE USING (bucket_id = 'chat_uploads' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "chat_uploads_delete" ON storage.objects;
CREATE POLICY "chat_uploads_delete" ON storage.objects
  FOR DELETE USING (bucket_id = 'chat_uploads' AND auth.role() = 'authenticated');

-- 2. Add callee_id column to chat_calls (code inserts it)
ALTER TABLE chat_calls ADD COLUMN IF NOT EXISTS callee_id UUID;

-- 3. Chat calls RLS policies (table had RLS enabled but zero policies)
DROP POLICY IF EXISTS "Users can view calls they participate in" ON chat_calls;
CREATE POLICY "Users can view calls they participate in"
  ON chat_calls FOR SELECT
  USING (caller_id = auth.uid() OR callee_id = auth.uid());

DROP POLICY IF EXISTS "Users can create calls" ON chat_calls;
CREATE POLICY "Users can create calls"
  ON chat_calls FOR INSERT
  WITH CHECK (caller_id = auth.uid());

DROP POLICY IF EXISTS "Users can update calls they participate in" ON chat_calls;
CREATE POLICY "Users can update calls they participate in"
  ON chat_calls FOR UPDATE
  USING (caller_id = auth.uid() OR callee_id = auth.uid())
  WITH CHECK (caller_id = auth.uid() OR callee_id = auth.uid());

-- 4. Legacy messages table file columns (messages_screen inserts them)
ALTER TABLE messages ADD COLUMN IF NOT EXISTS file_url TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS file_type TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS file_name TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS file_size BIGINT;

-- 4b. Legacy messages table reply column (messages_screen reply feature writes parent_message_id)
ALTER TABLE messages ADD COLUMN IF NOT EXISTS parent_message_id UUID REFERENCES messages(id);

-- 5. Defensive chat_messages columns used by the Flutter app
-- (sender_name/sender_avatar are selected for the chat list; reply_to is
--  written when replying to a message)
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS sender_name TEXT;
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS sender_avatar TEXT;
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS reply_to UUID;
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE;
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS read_by JSONB DEFAULT '[]'::jsonb;
