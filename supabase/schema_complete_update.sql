-- ============================================================
-- EMIS SUPABASE SCHEMA - COMPLETE UPDATE
-- Date: March 28, 2026
-- Adds: Chat tables, indexes, triggers, RLS policies
-- ============================================================

-- ─── Extensions ──────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- CHAT SYSTEM TABLES
-- ============================================================

-- ─── Chat Groups ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chat_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL DEFAULT 'direct', -- 'direct' or 'group'
  avatar_url TEXT,
  created_by UUID REFERENCES profiles(id),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE chat_groups IS 'Chat groups for direct and group messaging';

-- ─── Chat Group Members ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS chat_group_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID REFERENCES chat_groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member', -- 'admin', 'member'
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

COMMENT ON TABLE chat_group_members IS 'Members of each chat group';

-- ─── Chat Messages ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID REFERENCES chat_groups(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT,
  message_type TEXT DEFAULT 'text', -- 'text', 'image', 'file', 'video', 'audio'
  file_url TEXT,
  file_name TEXT,
  file_size BIGINT,
  reply_to_id UUID REFERENCES chat_messages(id),
  is_edited BOOLEAN DEFAULT FALSE,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE chat_messages IS 'Messages sent in chat groups';

-- ─── Message Read Status ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS message_read_status (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id UUID REFERENCES chat_messages(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(message_id, user_id)
);

COMMENT ON TABLE message_read_status IS 'Tracks which users have read which messages';

-- ─── Typing Status (Real-time) ───────────────────────────────
CREATE TABLE IF NOT EXISTS typing_status (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID REFERENCES chat_groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  is_typing BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

COMMENT ON TABLE typing_status IS 'Real-time typing indicators';

-- ============================================================
-- EXISTING TABLE ENHANCEMENTS
-- ============================================================

-- ─── Attendance Enhancements ─────────────────────────────────
ALTER TABLE attendance 
ADD COLUMN IF NOT EXISTS notes TEXT,
ADD COLUMN IF NOT EXISTS late_minutes INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS excused BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS excused_by UUID REFERENCES profiles(id),
ADD COLUMN IF NOT EXISTS excused_reason TEXT;

-- ─── Assignments Enhancements ────────────────────────────────
ALTER TABLE assignments
ADD COLUMN IF NOT EXISTS max_score NUMERIC(5,2) DEFAULT 100,
ADD COLUMN IF NOT EXISTS submission_instructions TEXT,
ADD COLUMN IF NOT EXISTS allow_late_submission BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS late_penalty_percent NUMERIC(5,2) DEFAULT 0;

-- ─── Grades Enhancements ─────────────────────────────────────
ALTER TABLE grades
ADD COLUMN IF NOT EXISTS grade_point NUMERIC(3,2),
ADD COLUMN IF NOT EXISTS remarks TEXT,
ADD COLUMN IF NOT EXISTS graded_by UUID REFERENCES profiles(id),
ADD COLUMN IF NOT EXISTS graded_at TIMESTAMPTZ;

-- ============================================================
-- PERFORMANCE INDEXES
-- ============================================================

-- ─── Chat Indexes ────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_chat_messages_group_id ON chat_messages(group_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_type ON chat_messages(message_type);
CREATE INDEX IF NOT EXISTS idx_chat_group_members_group_id ON chat_group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_chat_group_members_user_id ON chat_group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_groups_tenant_id ON chat_groups(tenant_id);
CREATE INDEX IF NOT EXISTS idx_chat_groups_type ON chat_groups(type);

-- ─── Attendance Indexes ──────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_attendance_student_id ON attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(date DESC);
CREATE INDEX IF NOT EXISTS idx_attendance_class_id ON attendance(class_id);
CREATE INDEX IF NOT EXISTS idx_attendance_status ON attendance(status);

-- ─── Assignments Indexes ─────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_assignments_class_id ON assignments(class_id);
CREATE INDEX IF NOT EXISTS idx_assignments_due_date ON assignments(due_date);
CREATE INDEX IF NOT EXISTS idx_assignments_status ON assignments(status);
CREATE INDEX IF NOT EXISTS idx_assignments_teacher_id ON assignments(teacher_id);

-- ─── Grades Indexes ──────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_grades_student_id ON grades(student_id);
CREATE INDEX IF NOT EXISTS idx_grades_exam_id ON grades(exam_id);
CREATE INDEX IF NOT EXISTS idx_grades_subject_id ON grades(subject_id);

-- ─── Payments Indexes ────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_payments_student_id ON payments(student_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_due_date ON payments(due_date);

-- ─── Profile Indexes ─────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_profiles_tenant_id ON profiles(tenant_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_is_active ON profiles(is_active);

-- ─── Student Indexes ─────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_students_class_id ON students(class_id);
CREATE INDEX IF NOT EXISTS idx_students_program_id ON students(program_id);
CREATE INDEX IF NOT EXISTS idx_students_tenant_id ON students(tenant_id);

-- ============================================================
-- TRIGGERS
-- ============================================================

-- ─── Auto-update updated_at Function ─────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_updated_at_column IS 'Automatically updates the updated_at timestamp on row update';

-- ─── Apply updated_at Trigger to Tables ──────────────────────
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_groups_updated_at
  BEFORE UPDATE ON chat_groups
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_messages_updated_at
  BEFORE UPDATE ON chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_typing_status_updated_at
  BEFORE UPDATE ON typing_status
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ─── Auto-generate Student Code ──────────────────────────────
CREATE OR REPLACE FUNCTION generate_student_code()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.student_code IS NULL THEN
    NEW.student_code := 'STU-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(
      (SELECT COUNT(*) FROM students WHERE tenant_id = NEW.tenant_id)::text, 
      6, 
      '0'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generate_student_code IS 'Auto-generates unique student code on insert';

CREATE TRIGGER auto_generate_student_code
  BEFORE INSERT ON students
  FOR EACH ROW
  EXECUTE FUNCTION generate_student_code();

-- ─── Auto-generate Employee Code ─────────────────────────────
CREATE OR REPLACE FUNCTION generate_employee_code()
RETURNS TRIGGER AS $$
DECLARE
  role_prefix TEXT;
BEGIN
  -- Get role from profiles table
  SELECT LEFT(role, 3) INTO role_prefix
  FROM profiles 
  WHERE id = NEW.profile_id;
  
  role_prefix := UPPER(COALESCE(role_prefix, 'EMP'));
  
  IF NEW.employee_code IS NULL THEN
    NEW.employee_code := role_prefix || '-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(
      (SELECT COUNT(*) FROM teachers WHERE tenant_id = NEW.tenant_id)::text,
      6,
      '0'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generate_employee_code IS 'Auto-generates unique employee code based on role';

CREATE TRIGGER auto_generate_employee_code
  BEFORE INSERT ON teachers
  FOR EACH ROW
  EXECUTE FUNCTION generate_employee_code();

-- ─── Notify on New Message (Real-time) ───────────────────────
CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM pg_notify(
    'new_message',
    json_build_object(
      'message_id', NEW.id,
      'group_id', NEW.group_id,
      'sender_id', NEW.sender_id,
      'content', NEW.content,
      'message_type', NEW.message_type,
      'created_at', NEW.created_at
    )::text
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION notify_new_message IS 'Sends real-time notification when a new message is created';

CREATE TRIGGER on_new_message
  AFTER INSERT ON chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_message();

-- ─── Update Group Last Message ───────────────────────────────
CREATE OR REPLACE FUNCTION update_group_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE chat_groups
  SET updated_at = NOW()
  WHERE id = NEW.group_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_group_last_message IS 'Updates the group''s updated_at when a new message is sent';

CREATE TRIGGER on_message_sent_update_group
  AFTER INSERT ON chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_group_last_message();

-- ─── Auto-add Creator to Group Members ───────────────────────
CREATE OR REPLACE FUNCTION add_creator_to_group()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO chat_group_members (group_id, user_id, role)
  VALUES (NEW.id, NEW.created_by, 'admin')
  ON CONFLICT (group_id, user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION add_creator_to_group IS 'Automatically adds the group creator as an admin member';

CREATE TRIGGER auto_add_creator_to_group
  AFTER INSERT ON chat_groups
  FOR EACH ROW
  EXECUTE FUNCTION add_creator_to_group();

-- ============================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================

-- ─── Enable RLS on Chat Tables ───────────────────────────────
ALTER TABLE chat_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_read_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_status ENABLE ROW LEVEL SECURITY;

-- ─── Chat Groups Policies ────────────────────────────────────
CREATE POLICY "Users can view their chat groups"
  ON chat_groups FOR SELECT
  USING (
    tenant_id = (SELECT tenant_id FROM profiles WHERE id = auth.uid())
    AND id IN (
      SELECT group_id FROM chat_group_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Teachers and admins can create groups"
  ON chat_groups FOR INSERT
  WITH CHECK (
    auth.uid() = created_by
    AND (SELECT role FROM profiles WHERE id = auth.uid()) IN ('teacher', 'admin', 'super_admin')
  );

CREATE POLICY "Group admins can update group"
  ON chat_groups FOR UPDATE
  USING (
    id IN (
      SELECT group_id FROM chat_group_members 
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- ─── Chat Group Members Policies ─────────────────────────────
CREATE POLICY "Members can view group members"
  ON chat_group_members FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM chat_group_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Group admins can add members"
  ON chat_group_members FOR INSERT
  WITH CHECK (
    group_id IN (
      SELECT group_id FROM chat_group_members 
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Group admins can remove members"
  ON chat_group_members FOR DELETE
  USING (
    group_id IN (
      SELECT group_id FROM chat_group_members 
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- ─── Chat Messages Policies ──────────────────────────────────
CREATE POLICY "Users can send messages"
  ON chat_messages FOR INSERT
  WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Users can view messages in their groups"
  ON chat_messages FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM chat_group_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own messages"
  ON chat_messages FOR UPDATE
  USING (sender_id = auth.uid());

CREATE POLICY "Users can delete their own messages"
  ON chat_messages FOR DELETE
  USING (sender_id = auth.uid());

-- ─── Message Read Status Policies ────────────────────────────
CREATE POLICY "Users can update their read status"
  ON message_read_status FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can view read status"
  ON message_read_status FOR SELECT
  USING (
    message_id IN (
      SELECT id FROM chat_messages WHERE group_id IN (
        SELECT group_id FROM chat_group_members WHERE user_id = auth.uid()
      )
    )
  );

-- ─── Typing Status Policies ──────────────────────────────────
CREATE POLICY "Users can update their typing status"
  ON typing_status FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own typing status"
  ON typing_status FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can view typing status in their groups"
  ON typing_status FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM chat_group_members WHERE user_id = auth.uid()
    )
  );

-- ============================================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================================

-- Insert sample chat groups (run after creating tenants and profiles)
-- INSERT INTO chat_groups (tenant_id, name, description, type, created_by)
-- VALUES 
--   ('tenant-uuid-here', 'Class 10-A', 'Mathematics discussion group', 'group', 'teacher-uuid-here'),
--   ('tenant-uuid-here', 'Class 10-B', 'English literature group', 'group', 'teacher-uuid-here');

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

-- ─── Get Unread Message Count ────────────────────────────────
CREATE OR REPLACE FUNCTION get_unread_message_count(p_user_id UUID, p_group_id UUID)
RETURNS BIGINT AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)
    FROM chat_messages cm
    WHERE cm.group_id = p_group_id
      AND cm.sender_id != p_user_id
      AND cm.id NOT IN (
        SELECT message_id FROM message_read_status WHERE user_id = p_user_id
      )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_unread_message_count IS 'Returns the count of unread messages for a user in a specific group';

-- ─── Get Last Message for Group ──────────────────────────────
CREATE OR REPLACE FUNCTION get_last_message(p_group_id UUID)
RETURNS TABLE (
  message_id UUID,
  sender_id UUID,
  sender_name TEXT,
  content TEXT,
  message_type TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    cm.id,
    cm.sender_id,
    p.full_name,
    cm.content,
    cm.message_type,
    cm.created_at
  FROM chat_messages cm
  JOIN profiles p ON cm.sender_id = p.id
  WHERE cm.group_id = p_group_id
    AND cm.is_deleted = FALSE
  ORDER BY cm.created_at DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_last_message IS 'Returns the last message in a group with sender details';

-- ─── Get User's Chat Groups ──────────────────────────────────
CREATE OR REPLACE FUNCTION get_user_chat_groups(p_user_id UUID)
RETURNS TABLE (
  group_id UUID,
  group_name TEXT,
  group_type TEXT,
  avatar_url TEXT,
  member_count BIGINT,
  last_message_content TEXT,
  last_message_at TIMESTAMPTZ,
  unread_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    cg.id,
    cg.name,
    cg.type,
    cg.avatar_url,
    (SELECT COUNT(*) FROM chat_group_members cgm WHERE cgm.group_id = cg.id),
    (SELECT content FROM chat_messages cm WHERE cm.group_id = cg.id AND cm.is_deleted = FALSE ORDER BY cm.created_at DESC LIMIT 1),
    (SELECT created_at FROM chat_messages cm WHERE cm.group_id = cg.id AND cm.is_deleted = FALSE ORDER BY cm.created_at DESC LIMIT 1),
    get_unread_message_count(p_user_id, cg.id)
  FROM chat_groups cg
  WHERE cg.id IN (
    SELECT group_id FROM chat_group_members WHERE user_id = p_user_id
  )
  AND cg.is_active = TRUE
  ORDER BY (SELECT created_at FROM chat_messages cm WHERE cm.group_id = cg.id ORDER BY cm.created_at DESC LIMIT 1) DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_user_chat_groups IS 'Returns all chat groups for a user with last message and unread count';

-- ============================================================
-- END OF SCHEMA UPDATE
-- ============================================================

COMMENT ON SCHEMA public IS 'EMIS - Educational Management Information System - Complete Schema with Chat, Indexes, Triggers, and RLS';
