-- ============================================================
-- EMIS Supabase Schema
-- ============================================================

-- ─── Extensions ──────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── Tenants ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tenants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  logo_url TEXT,
  address TEXT,
  phone TEXT,
  email TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Users (extends Supabase auth.users) ─────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES tenants(id),
  full_name TEXT,
  role TEXT NOT NULL DEFAULT 'student',
  -- roles: super_admin, admin, teacher, student, parent, staff,
  --        accountant, librarian, receptionist, hr_manager,
  --        transport_manager, hostel_manager, inventory_manager,
  --        it_support, maintenance, security, event_manager, complaint_manager
  avatar_url TEXT,
  phone TEXT,
  address TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  is_online BOOLEAN DEFAULT FALSE,
  last_seen_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Departments ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS departments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  head_id UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Programs ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS programs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  description TEXT,
  duration_months INT,
  fee NUMERIC(10,2),
  department_id UUID REFERENCES departments(id),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Classes ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS classes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  program_id UUID REFERENCES programs(id),
  teacher_id UUID REFERENCES profiles(id),
  capacity INT DEFAULT 30,
  room TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Students ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS students (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES tenants(id),
  student_code TEXT UNIQUE,
  class_id UUID REFERENCES classes(id),
  program_id UUID REFERENCES programs(id),
  enrollment_date DATE,
  guardian_name TEXT,
  guardian_phone TEXT,
  date_of_birth DATE,
  gender TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Teachers ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS teachers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES tenants(id),
  employee_code TEXT UNIQUE,
  department_id UUID REFERENCES departments(id),
  qualification TEXT,
  specialization TEXT,
  join_date DATE,
  salary NUMERIC(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Attendance ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES profiles(id),
  class_id UUID REFERENCES classes(id),
  date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'present', -- present, absent, late, excused
  marked_by UUID REFERENCES profiles(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Leave Management ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS leave_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  applicant_id UUID REFERENCES profiles(id),
  applicant_role TEXT NOT NULL,
  leave_type TEXT NOT NULL, -- full_day, half_day, hourly
  date DATE NOT NULL,
  start_time TIME,   -- for hourly leave
  end_time TIME,     -- for hourly leave
  reason TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending', -- pending, approved, rejected
  reviewed_by UUID REFERENCES profiles(id),
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Student monthly leave quota (max 3 per month)
CREATE OR REPLACE VIEW student_monthly_leave_usage AS
SELECT
  applicant_id,
  DATE_TRUNC('month', date) AS month,
  COUNT(*) AS used_days
FROM leave_requests
WHERE applicant_role = 'student'
  AND status = 'approved'
GROUP BY applicant_id, DATE_TRUNC('month', date);

-- ─── Payments / Fees ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  student_id UUID REFERENCES students(id),
  amount NUMERIC(10,2) NOT NULL,
  payment_type TEXT, -- tuition, hostel, transport, library_fine
  payment_method TEXT, -- cash, bank, online
  reference_no TEXT,
  status TEXT DEFAULT 'paid', -- paid, pending, overdue
  due_date DATE,
  paid_at TIMESTAMPTZ,
  collected_by UUID REFERENCES profiles(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Payroll ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payroll (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  employee_id UUID REFERENCES profiles(id),
  month INT NOT NULL,
  year INT NOT NULL,
  basic_salary NUMERIC(10,2),
  allowances NUMERIC(10,2) DEFAULT 0,
  deductions NUMERIC(10,2) DEFAULT 0,
  net_salary NUMERIC(10,2),
  status TEXT DEFAULT 'pending', -- pending, paid
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Exams ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS exams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  class_id UUID REFERENCES classes(id),
  subject TEXT NOT NULL,
  exam_date DATE,
  total_marks INT DEFAULT 100,
  passing_marks INT DEFAULT 50,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS exam_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  exam_id UUID REFERENCES exams(id),
  student_id UUID REFERENCES students(id),
  marks_obtained NUMERIC(5,2),
  grade TEXT,
  remarks TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Grades ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS grades (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  student_id UUID REFERENCES students(id),
  class_id UUID REFERENCES classes(id),
  subject TEXT,
  grade TEXT,
  score NUMERIC(5,2),
  semester TEXT,
  academic_year TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Notifications ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES profiles(id) NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  type TEXT, -- info, warning, success, alert
  is_read BOOLEAN DEFAULT FALSE,
  action_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Chat Groups ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chat_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL DEFAULT 'group', -- group, direct
  class_id UUID REFERENCES classes(id), -- for class groups
  created_by UUID REFERENCES profiles(id),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chat_group_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID REFERENCES chat_groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id),
  role TEXT DEFAULT 'member', -- admin, member
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID REFERENCES chat_groups(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES profiles(id),
  message_type TEXT NOT NULL DEFAULT 'text', -- text, file, image, video, audio
  content TEXT,
  file_url TEXT,
  file_name TEXT,
  file_size INT,
  reply_to UUID REFERENCES chat_messages(id),
  is_edited BOOLEAN DEFAULT FALSE,
  edited_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chat_message_reads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id UUID REFERENCES chat_messages(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id),
  read_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(message_id, user_id)
);

-- ─── Call Logs ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS call_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  group_id UUID REFERENCES chat_groups(id),
  caller_id UUID REFERENCES profiles(id),
  call_type TEXT NOT NULL, -- video, voice
  status TEXT NOT NULL DEFAULT 'initiated', -- initiated, answered, missed, ended
  duration INT DEFAULT 0, -- seconds
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS call_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  call_id UUID REFERENCES call_logs(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id),
  status TEXT DEFAULT 'invited', -- invited, joined, left, declined
  joined_at TIMESTAMPTZ,
  left_at TIMESTAMPTZ
);

-- ─── Books / Library ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS books (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  title TEXT NOT NULL,
  author TEXT,
  isbn TEXT,
  category TEXT,
  total_copies INT DEFAULT 1,
  available_copies INT DEFAULT 1,
  location TEXT,
  cover_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS book_issues (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  book_id UUID REFERENCES books(id),
  member_id UUID REFERENCES profiles(id),
  issued_at TIMESTAMPTZ DEFAULT NOW(),
  due_date DATE,
  returned_at TIMESTAMPTZ,
  fine_amount NUMERIC(8,2) DEFAULT 0,
  status TEXT DEFAULT 'issued' -- issued, returned, overdue
);

-- ─── Homework / Assignments ───────────────────────────────────
CREATE TABLE IF NOT EXISTS homework (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  class_id UUID REFERENCES classes(id),
  teacher_id UUID REFERENCES profiles(id),
  title TEXT NOT NULL,
  description TEXT,
  due_date DATE,
  attachment_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS homework_submissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  homework_id UUID REFERENCES homework(id),
  student_id UUID REFERENCES students(id),
  submission_url TEXT,
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  grade TEXT,
  feedback TEXT,
  status TEXT DEFAULT 'submitted' -- submitted, graded, late
);

-- ─── Lesson Plans ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lesson_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  teacher_id UUID REFERENCES profiles(id),
  class_id UUID REFERENCES classes(id),
  subject TEXT,
  title TEXT NOT NULL,
  objectives TEXT,
  content TEXT,
  resources TEXT,
  date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Schedules / Timetable ───────────────────────────────────
CREATE TABLE IF NOT EXISTS schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  class_id UUID REFERENCES classes(id),
  teacher_id UUID REFERENCES profiles(id),
  subject TEXT,
  day_of_week INT, -- 0=Mon, 6=Sun
  start_time TIME,
  end_time TIME,
  room TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Events ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  title TEXT NOT NULL,
  description TEXT,
  event_date DATE,
  start_time TIME,
  end_time TIME,
  venue TEXT,
  organizer_id UUID REFERENCES profiles(id),
  status TEXT DEFAULT 'upcoming', -- upcoming, ongoing, completed, cancelled
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Complaints ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS complaints (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  complainant_id UUID REFERENCES profiles(id),
  subject TEXT NOT NULL,
  description TEXT,
  category TEXT, -- academic, financial, facility, staff, other
  status TEXT DEFAULT 'pending', -- pending, under_review, resolved, closed
  assigned_to UUID REFERENCES profiles(id),
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Transport ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vehicles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  plate_number TEXT UNIQUE,
  model TEXT,
  capacity INT,
  driver_id UUID REFERENCES profiles(id),
  status TEXT DEFAULT 'active', -- active, maintenance, inactive
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS transport_routes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  vehicle_id UUID REFERENCES vehicles(id),
  stops JSONB, -- array of stop names/coordinates
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Hostel ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS hostel_rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  room_number TEXT NOT NULL,
  floor INT,
  capacity INT DEFAULT 2,
  occupied INT DEFAULT 0,
  room_type TEXT, -- single, double, dormitory
  monthly_fee NUMERIC(10,2),
  status TEXT DEFAULT 'available', -- available, full, maintenance
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS hostel_allocations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID REFERENCES hostel_rooms(id),
  student_id UUID REFERENCES students(id),
  allocated_at TIMESTAMPTZ DEFAULT NOW(),
  vacated_at TIMESTAMPTZ,
  status TEXT DEFAULT 'active' -- active, vacated
);

-- ─── Inventory ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS inventory_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  category TEXT,
  quantity INT DEFAULT 0,
  unit TEXT,
  unit_price NUMERIC(10,2),
  reorder_level INT DEFAULT 5,
  supplier TEXT,
  location TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS inventory_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  item_id UUID REFERENCES inventory_items(id),
  transaction_type TEXT, -- in, out, adjustment
  quantity INT,
  notes TEXT,
  performed_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── HR / Recruitment ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS job_postings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  title TEXT NOT NULL,
  department_id UUID REFERENCES departments(id),
  description TEXT,
  requirements TEXT,
  status TEXT DEFAULT 'open', -- open, closed, filled
  posted_at TIMESTAMPTZ DEFAULT NOW(),
  deadline DATE
);

CREATE TABLE IF NOT EXISTS job_applications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID REFERENCES job_postings(id),
  applicant_name TEXT,
  applicant_email TEXT,
  resume_url TEXT,
  status TEXT DEFAULT 'applied', -- applied, shortlisted, interviewed, hired, rejected
  applied_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Security Logs ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS security_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  log_type TEXT, -- entry, exit, incident, visitor
  person_name TEXT,
  person_id UUID REFERENCES profiles(id),
  notes TEXT,
  logged_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Visitors ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS visitors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  phone TEXT,
  purpose TEXT,
  host_id UUID REFERENCES profiles(id),
  check_in TIMESTAMPTZ DEFAULT NOW(),
  check_out TIMESTAMPTZ,
  id_type TEXT,
  id_number TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Maintenance Work Orders ─────────────────────────────────
CREATE TABLE IF NOT EXISTS work_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  title TEXT NOT NULL,
  description TEXT,
  location TEXT,
  priority TEXT DEFAULT 'medium', -- low, medium, high, urgent
  status TEXT DEFAULT 'open', -- open, in_progress, completed, cancelled
  assigned_to UUID REFERENCES profiles(id),
  reported_by UUID REFERENCES profiles(id),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── IT Support Tickets ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS it_tickets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  title TEXT NOT NULL,
  description TEXT,
  category TEXT, -- hardware, software, network, account, other
  priority TEXT DEFAULT 'medium',
  status TEXT DEFAULT 'open', -- open, in_progress, resolved, closed
  reported_by UUID REFERENCES profiles(id),
  assigned_to UUID REFERENCES profiles(id),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Discounts ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS discounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  discount_type TEXT, -- percentage, fixed
  value NUMERIC(10,2),
  applicable_to TEXT, -- all, program, student
  program_id UUID REFERENCES programs(id),
  valid_from DATE,
  valid_until DATE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Notice Board ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  title TEXT NOT NULL,
  content TEXT,
  target_roles TEXT[], -- array of roles this notice is for
  is_pinned BOOLEAN DEFAULT FALSE,
  published_by UUID REFERENCES profiles(id),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── LMS Content ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lms_courses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id),
  class_id UUID REFERENCES classes(id),
  teacher_id UUID REFERENCES profiles(id),
  title TEXT NOT NULL,
  description TEXT,
  thumbnail_url TEXT,
  is_published BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS lms_lessons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id UUID REFERENCES lms_courses(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT,
  video_url TEXT,
  attachment_url TEXT,
  order_index INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Row Level Security (RLS) ─────────────────────────────────
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_group_members ENABLE ROW LEVEL SECURITY;

-- Profiles: users can read their own, admins can read all in tenant
CREATE POLICY "profiles_self_read" ON profiles
  FOR SELECT USING (auth.uid() = id);

-- Leave requests: users see their own; managers see all in tenant
CREATE POLICY "leave_own_read" ON leave_requests
  FOR SELECT USING (auth.uid() = applicant_id);

-- Notifications: users see their own
CREATE POLICY "notifications_own" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "notifications_insert_own" ON notifications
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "notifications_update_own" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);

-- Chat messages: members of the group can read
CREATE POLICY "chat_messages_group_members" ON chat_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chat_group_members
      WHERE chat_group_members.group_id = chat_messages.group_id
        AND chat_group_members.user_id = auth.uid()
    )
  );

-- ─── Indexes ─────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_attendance_user_date ON attendance(user_id, date);
CREATE INDEX IF NOT EXISTS idx_leave_requests_applicant ON leave_requests(applicant_id, date);
CREATE INDEX IF NOT EXISTS idx_chat_messages_group ON chat_messages(group_id, created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_payments_student ON payments(student_id);
CREATE INDEX IF NOT EXISTS idx_profiles_tenant ON profiles(tenant_id, role);

-- ============================================================
-- Incremental schema additions for panel messaging, settings,
-- leave policy enforcement, notifications, and device tracking
-- ============================================================

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS can_self_edit BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS managed_by_role TEXT;

UPDATE profiles
SET can_self_edit = FALSE,
    managed_by_role = COALESCE(managed_by_role, 'teacher_or_staff')
WHERE role = 'student';

ALTER TABLE leave_requests
  ADD COLUMN IF NOT EXISTS end_date DATE,
  ADD COLUMN IF NOT EXISTS requested_days NUMERIC(4,2) NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS duration_hours NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS leave_month DATE;

UPDATE leave_requests
SET end_date = COALESCE(end_date, date),
    leave_month = COALESCE(leave_month, DATE_TRUNC('month', date)::DATE)
WHERE end_date IS NULL OR leave_month IS NULL;

ALTER TABLE notifications
  ADD COLUMN IF NOT EXISTS sender_id UUID REFERENCES profiles(id),
  ADD COLUMN IF NOT EXISTS category TEXT,
  ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'normal',
  ADD COLUMN IF NOT EXISTS channel TEXT DEFAULT 'in_app',
  ADD COLUMN IF NOT EXISTS target_role TEXT,
  ADD COLUMN IF NOT EXISTS panel_key TEXT,
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ;

ALTER TABLE chat_groups
  ADD COLUMN IF NOT EXISTS managed_by_role TEXT,
  ADD COLUMN IF NOT EXISTS created_for_role TEXT,
  ADD COLUMN IF NOT EXISTS class_teacher_id UUID REFERENCES profiles(id),
  ADD COLUMN IF NOT EXISTS allow_students_to_post BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS allow_file_sharing BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS allow_voice_calls BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS allow_video_calls BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS direct_message_policy TEXT NOT NULL DEFAULT 'open';

ALTER TABLE chat_group_members
  ADD COLUMN IF NOT EXISTS added_by UUID REFERENCES profiles(id),
  ADD COLUMN IF NOT EXISTS muted_until TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS last_read_at TIMESTAMPTZ;

ALTER TABLE chat_messages
  ADD COLUMN IF NOT EXISTS mime_type TEXT,
  ADD COLUMN IF NOT EXISTS storage_bucket TEXT,
  ADD COLUMN IF NOT EXISTS storage_path TEXT,
  ADD COLUMN IF NOT EXISTS thumbnail_url TEXT,
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

ALTER TABLE call_logs
  ADD COLUMN IF NOT EXISTS room_id TEXT,
  ADD COLUMN IF NOT EXISTS ended_reason TEXT,
  ADD COLUMN IF NOT EXISTS recording_url TEXT;

CREATE TABLE IF NOT EXISTS notification_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES tenants(id),
  notification_type TEXT NOT NULL,
  in_app_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  push_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  email_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  sms_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  quiet_hours JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, notification_type)
);

CREATE TABLE IF NOT EXISTS user_devices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES tenants(id),
  device_name TEXT NOT NULL,
  platform TEXT,
  app_version TEXT,
  session_token TEXT,
  ip_address INET,
  last_seen_at TIMESTAMPTZ DEFAULT NOW(),
  logged_in_at TIMESTAMPTZ DEFAULT NOW(),
  logged_out_at TIMESTAMPTZ,
  is_current BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS app_releases (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  version TEXT NOT NULL UNIQUE,
  build_number TEXT,
  title TEXT,
  release_notes TEXT,
  is_mandatory BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  published_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES profiles(id)
);

CREATE OR REPLACE VIEW student_monthly_leave_usage AS
SELECT
  applicant_id,
  DATE_TRUNC('month', date)::DATE AS month,
  SUM(COALESCE(requested_days, 1)) AS used_days
FROM leave_requests
WHERE applicant_role = 'student'
  AND status = 'approved'
GROUP BY applicant_id, DATE_TRUNC('month', date)::DATE;

CREATE OR REPLACE FUNCTION validate_leave_request_rules()
RETURNS TRIGGER AS $$
DECLARE
  approved_student_days NUMERIC(4,2);
BEGIN
  NEW.end_date := COALESCE(NEW.end_date, NEW.date);
  NEW.leave_month := DATE_TRUNC('month', NEW.date)::DATE;

  IF NEW.leave_type = 'full_day' THEN
    NEW.requested_days := 1;
    NEW.duration_hours := NULL;
    NEW.start_time := NULL;
    NEW.end_time := NULL;
  ELSIF NEW.leave_type = 'half_day' THEN
    NEW.requested_days := 0.5;
    NEW.duration_hours := NULL;
    NEW.start_time := NULL;
    NEW.end_time := NULL;
  ELSIF NEW.leave_type = 'hourly' THEN
    IF NEW.start_time IS NULL OR NEW.end_time IS NULL OR NEW.end_time <= NEW.start_time THEN
      RAISE EXCEPTION 'Hourly leave requires valid start_time and end_time';
    END IF;
    NEW.duration_hours := EXTRACT(EPOCH FROM (NEW.end_time - NEW.start_time)) / 3600.0;
    NEW.requested_days := ROUND(GREATEST(NEW.duration_hours / 8.0, 0.125), 2);
  END IF;

  IF NEW.applicant_role = 'student' THEN
    NEW.leave_type := 'full_day';
    NEW.requested_days := 1;
    NEW.duration_hours := NULL;
    NEW.start_time := NULL;
    NEW.end_time := NULL;
    NEW.end_date := NEW.date;

    SELECT COALESCE(SUM(COALESCE(requested_days, 1)), 0)
      INTO approved_student_days
    FROM leave_requests
    WHERE applicant_id = NEW.applicant_id
      AND applicant_role = 'student'
      AND status = 'approved'
      AND DATE_TRUNC('month', date) = DATE_TRUNC('month', NEW.date)
      AND (TG_OP = 'INSERT' OR id <> NEW.id);

    IF NEW.status = 'approved' AND approved_student_days + NEW.requested_days > 3 THEN
      RAISE EXCEPTION 'Students can only take 3 leave days per month';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validate_leave_request_rules ON leave_requests;
CREATE TRIGGER trg_validate_leave_request_rules
BEFORE INSERT OR UPDATE ON leave_requests
FOR EACH ROW
EXECUTE FUNCTION validate_leave_request_rules();

ALTER TABLE chat_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "chat_groups_group_members" ON chat_groups;
CREATE POLICY "chat_groups_group_members" ON chat_groups
  FOR SELECT USING (
    EXISTS (
      SELECT 1
      FROM chat_group_members
      WHERE chat_group_members.group_id = chat_groups.id
        AND chat_group_members.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "chat_group_members_self" ON chat_group_members;
CREATE POLICY "chat_group_members_self" ON chat_group_members
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "call_logs_group_members" ON call_logs;
CREATE POLICY "call_logs_group_members" ON call_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1
      FROM chat_group_members
      WHERE chat_group_members.group_id = call_logs.group_id
        AND chat_group_members.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "notification_preferences_self" ON notification_preferences;
CREATE POLICY "notification_preferences_self" ON notification_preferences
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "user_devices_self" ON user_devices;
CREATE POLICY "user_devices_self" ON user_devices
  FOR SELECT USING (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_chat_groups_tenant_type
  ON chat_groups(tenant_id, type, class_id);
CREATE INDEX IF NOT EXISTS idx_chat_group_members_user
  ON chat_group_members(user_id, group_id);
CREATE INDEX IF NOT EXISTS idx_call_logs_group_started
  ON call_logs(group_id, started_at);
CREATE INDEX IF NOT EXISTS idx_notification_preferences_user
  ON notification_preferences(user_id, notification_type);
CREATE INDEX IF NOT EXISTS idx_user_devices_user_active
  ON user_devices(user_id, is_active, last_seen_at);
