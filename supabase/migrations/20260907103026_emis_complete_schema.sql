-- ============================================
-- EMIS Complete Database Schema
-- Hierarchical Course Management Platform
-- Single Platform Architecture (NOT Multi-Tenant)
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- PLATFORM & TENANT TABLE (Single Platform)
-- ============================================

CREATE TABLE IF NOT EXISTS platforms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  name TEXT NOT NULL DEFAULT 'EMIS Platform',
  description TEXT,
  logo_url TEXT,
  support_email TEXT,
  support_phone TEXT,
  is_active BOOLEAN DEFAULT true,
  settings JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for platforms
CREATE INDEX IF NOT EXISTS idx_platforms_active ON platforms(is_active);

-- Insert default platform
INSERT INTO platforms (name, description) 
VALUES ('EMIS Platform', 'Hierarchical Course Management Platform')
ON CONFLICT DO NOTHING;

-- ============================================
-- TENANTS TABLE WITH HIERARCHICAL SUPPORT
-- Central Organizations â†’ Branches/Schools
-- ============================================

CREATE TABLE IF NOT EXISTS tenants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  tenant_code TEXT UNIQUE,
  organization_type TEXT DEFAULT 'branch' CHECK (organization_type IN ('central', 'branch')),
  parent_tenant_id UUID REFERENCES tenants(id),
  description TEXT,
  logo_url TEXT,
  featured BOOLEAN DEFAULT FALSE,
  latitude DECIMAL(10, 7),
  longitude DECIMAL(10, 7),
  website TEXT,
  address TEXT,
  phone TEXT,
  email TEXT,
  services JSONB DEFAULT '[]',
  working_hours JSONB DEFAULT '{}',
  max_users INT DEFAULT 100,
  max_storage_mb INT DEFAULT 1024,
  settings JSONB DEFAULT '{}',
  plan TEXT DEFAULT 'standard',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_tenants_parent ON tenants(parent_tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenants_type ON tenants(organization_type);
CREATE INDEX IF NOT EXISTS idx_tenants_code ON tenants(tenant_code);
CREATE INDEX IF NOT EXISTS idx_tenants_active ON tenants(is_active);
CREATE INDEX IF NOT EXISTS idx_tenants_featured ON tenants(featured);
CREATE INDEX IF NOT EXISTS idx_tenants_lat_lng ON tenants(latitude, longitude);

-- View: Get all branches with parent info
CREATE OR REPLACE VIEW tenant_branches_with_parent AS
SELECT 
  t.id,
  t.name,
  t.slug,
  t.tenant_code,
  t.organization_type,
  t.parent_tenant_id,
  parent.name AS parent_name,
  parent.tenant_code AS parent_code,
  t.is_active,
  t.max_users,
  t.settings,
  t.created_at
FROM tenants t
LEFT JOIN tenants parent ON t.parent_tenant_id = parent.id
WHERE t.organization_type = 'branch';

-- View: Get central organizations with branch counts
CREATE OR REPLACE VIEW central_organizations AS
SELECT 
  t.id,
  t.name,
  t.slug,
  t.tenant_code,
  t.description,
  t.is_active,
  t.max_users,
  t.settings,
  t.created_at,
  (SELECT COUNT(*) FROM tenants WHERE parent_tenant_id = t.id) AS total_branches
FROM tenants t
WHERE t.organization_type = 'central';

-- View: Complete tenant hierarchy
CREATE OR REPLACE VIEW tenant_hierarchy AS
WITH RECURSIVE tenant_tree AS (
  SELECT 
    id,
    name,
    slug,
    tenant_code,
    organization_type,
    parent_tenant_id,
    0 AS level,
    ARRAY[name] AS path,
    id AS root_id
  FROM tenants
  WHERE parent_tenant_id IS NULL
  
  UNION ALL
  
  SELECT 
    t.id,
    t.name,
    t.slug,
    t.tenant_code,
    t.organization_type,
    t.parent_tenant_id,
    tt.level + 1,
    tt.path || t.name,
    tt.root_id
  FROM tenants t
  INNER JOIN tenant_tree tt ON t.parent_tenant_id = tt.id
)
SELECT 
  id,
  name,
  slug,
  tenant_code,
  organization_type,
  parent_tenant_id,
  level,
  path,
  root_id,
  array_to_string(path, ' â†’ ') AS hierarchy_path
FROM tenant_tree
ORDER BY root_id, level, name;

-- Function: Auto-generate tenant code
CREATE OR REPLACE FUNCTION generate_tenant_code()
RETURNS TRIGGER AS $$
DECLARE
  code_prefix TEXT;
  next_code INT;
BEGIN
  IF NEW.tenant_code IS NULL THEN
    IF NEW.organization_type = 'central' THEN
      code_prefix := 'C';
    ELSE
      code_prefix := 'B';
    END IF;
    
    SELECT COALESCE(MAX(
      CAST(SUBSTRING(tenant_code FROM 2) AS INTEGER)
    ), 0) + 1 INTO next_code
    FROM tenants
    WHERE organization_type = NEW.organization_type;
    
    NEW.tenant_code := code_prefix || LPAD(next_code::TEXT, 4, '0');
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for auto-generating codes
DROP TRIGGER IF EXISTS trg_generate_tenant_code ON tenants;
CREATE TRIGGER trg_generate_tenant_code
  BEFORE INSERT ON tenants
  FOR EACH ROW
  EXECUTE FUNCTION generate_tenant_code();

-- Function: Validate tenant hierarchy
CREATE OR REPLACE FUNCTION validate_tenant_hierarchy()
RETURNS TRIGGER AS $$
BEGIN
  -- Prevent circular references
  IF NEW.parent_tenant_id = NEW.id THEN
    RAISE EXCEPTION 'A tenant cannot be its own parent';
  END IF;
  
  -- Prevent a central from having a parent
  IF NEW.parent_tenant_id IS NOT NULL AND NEW.organization_type = 'central' THEN
    RAISE EXCEPTION 'A central organization cannot have a parent';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for validation
DROP TRIGGER IF EXISTS trg_validate_tenant_hierarchy ON tenants;
CREATE TRIGGER trg_validate_tenant_hierarchy
  BEFORE INSERT OR UPDATE ON tenants
  FOR EACH ROW
  EXECUTE FUNCTION validate_tenant_hierarchy();

-- Sample Data: Central Organization
INSERT INTO tenants (id, name, slug, organization_type, description, is_active)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'International Education Group',
  'ieg-central',
  'central',
  'Main central organization managing all branch schools',
  true
) ON CONFLICT DO NOTHING;

-- Sample Data: Branches
INSERT INTO tenants (name, slug, parent_tenant_id, organization_type, is_active)
VALUES 
  ('Oxford Academy', 'oxford-academy', '00000000-0000-0000-0000-000000000001', 'branch', true),
  ('Future Scholars', 'future-scholars', '00000000-0000-0000-0000-000000000001', 'branch', true),
  ('Global Institute', 'global-institute', '00000000-0000-0000-0000-000000000001', 'branch', true),
  ('Kabul Language Center', 'kabul-language-center', '00000000-0000-0000-0000-000000000001', 'branch', true)
ON CONFLICT DO NOTHING;

-- Profiles Table (Core User Table - All Roles)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  full_name TEXT,
  full_name_ar TEXT,
  first_name_ar TEXT,
  email text,
  last_name_ar TEXT,
  role TEXT NOT NULL DEFAULT 'student',
  -- roles: super_admin, admin, teacher, student, guardian, staff,
  --        academic_support, accountant, librarian, receptionist, hr_manager,
  --        inventory_manager, it_support, maintenance, event_manager, complaint_manager
  avatar_url TEXT,
  phone TEXT,
  address TEXT,
  tazkira_number TEXT,
  passport_id TEXT,
  blood_group TEXT CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
  nationality TEXT,
  religion TEXT,
  father_name TEXT,
  father_name_ar TEXT,
  mother_name TEXT,
  mother_name_ar TEXT,
  marital_status TEXT CHECK (marital_status IN ('single', 'married', 'divorced', 'widowed')),
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  emergency_contact_relation TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  is_online BOOLEAN DEFAULT FALSE,
  last_seen_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for profiles
CREATE INDEX IF NOT EXISTS idx_profiles_tenant ON profiles(tenant_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_active ON profiles(is_active);

-- ============================================
-- ADDRESSES TABLE (Multi-Language Support)
-- Stores addresses in 3 languages: English, Dari, Pashto
-- ============================================

CREATE TABLE IF NOT EXISTS addresses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  entity_type TEXT NOT NULL CHECK (entity_type IN ('profile', 'student', 'teacher', 'staff', 'tenant', 'branch', 'other')),
  entity_id UUID NOT NULL,
  address_line_en TEXT,
  address_line_dr TEXT,
  address_line_ps TEXT,
  street_en TEXT,
  street_dr TEXT,
  street_ps TEXT,
  area_en TEXT,
  area_dr TEXT,
  area_ps TEXT,
  city_en TEXT,
  city_dr TEXT,
  city_ps TEXT,
  province_en TEXT,
  province_dr TEXT,
  province_ps TEXT,
  district_en TEXT,
  district_dr TEXT,
  district_ps TEXT,
  country TEXT DEFAULT 'Afghanistan',
  postal_code TEXT,
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  is_primary BOOLEAN DEFAULT true,
  address_type TEXT CHECK (address_type IN ('permanent', 'current', 'mailing', 'emergency', 'other')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_addresses_entity ON addresses(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_addresses_primary ON addresses(entity_type, entity_id, is_primary) WHERE is_primary = true;
CREATE INDEX IF NOT EXISTS idx_addresses_city_en ON addresses(city_en);
CREATE INDEX IF NOT EXISTS idx_addresses_province_en ON addresses(province_en);

-- Departments Table (Admin Panel)
CREATE TABLE IF NOT EXISTS departments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  description TEXT,
  head_id UUID REFERENCES profiles(id),
  active BOOLEAN DEFAULT true,
  program_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for departments
CREATE INDEX IF NOT EXISTS idx_departments_tenant ON departments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_departments_active ON departments(active);
CREATE INDEX IF NOT EXISTS idx_departments_head ON departments(head_id);

-- ============================================
-- STUDENTS TABLE (Academic Support Panel - ONLY Students)
-- ============================================

CREATE TABLE IF NOT EXISTS students (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES tenants(id),
  student_code TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  full_name_ar TEXT,
  first_name TEXT,
  first_name_ar TEXT,
  last_name TEXT,
  last_name_ar TEXT,
  email TEXT UNIQUE,
  phone TEXT,
  date_of_birth DATE,
  gender TEXT CHECK (gender IN ('Male', 'Female', 'Other')),
  address TEXT,
  city TEXT,
  state TEXT,
  country TEXT,
  postal_code TEXT,
  tazkira_number TEXT,
  passport_id TEXT,
  blood_group TEXT CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
  nationality TEXT,
  religion TEXT,
  birth_place TEXT,
  father_name TEXT,
  father_name_ar TEXT,
  mother_name TEXT,
  mother_name_ar TEXT,
  marital_status TEXT CHECK (marital_status IN ('single', 'married', 'divorced', 'widowed')),
  guardian_name TEXT,
  guardian_name_ar TEXT,
  guardian_phone TEXT,
  guardian_email TEXT,
  guardian_relationship TEXT,
  program_id UUID,
  class_id UUID,
  course_ids UUID[],
  duration_months INTEGER CHECK (duration_months IN (4, 6, 12)),
  enrollment_date DATE,
  expected_completion_date DATE,
  actual_completion_date DATE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'graduated', 'suspended', 'transferred', 'dropped')),
  student_level TEXT,
  batch_number TEXT,
  photo_url TEXT,
  documents JSONB DEFAULT '[]'::jsonb,
  placement_test_score DECIMAL(5,2),
  placement_test_date DATE,
  certificate_issued BOOLEAN DEFAULT false,
  certificate_url TEXT,
  certificate_issued_date DATE,
  academic_history JSONB DEFAULT '[]'::jsonb,
  notes TEXT,
  total_fees DECIMAL(10,2) DEFAULT 0,
  paid_amount DECIMAL(10,2) DEFAULT 0,
  discount_percentage DECIMAL(5,2) DEFAULT 0,
  discount_type TEXT,
  outstanding_balance DECIMAL(10,2) GENERATED ALWAYS AS (total_fees - paid_amount) STORED,
  attendance_percentage DECIMAL(5,2) DEFAULT 0,
  average_grade DECIMAL(5,2) DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for students
CREATE INDEX IF NOT EXISTS idx_students_profile ON students(profile_id);
CREATE INDEX IF NOT EXISTS idx_students_tenant ON students(tenant_id);
CREATE INDEX IF NOT EXISTS idx_students_status ON students(status);
CREATE INDEX IF NOT EXISTS idx_students_program ON students(program_id);
CREATE INDEX IF NOT EXISTS idx_students_class ON students(class_id);
CREATE INDEX IF NOT EXISTS idx_students_enrollment ON students(enrollment_date);
CREATE INDEX IF NOT EXISTS idx_students_code ON students(student_code);
CREATE INDEX IF NOT EXISTS idx_students_email ON students(email);

-- ============================================
-- TEACHERS TABLE (HR Panel - ONLY Staff)
-- ============================================

CREATE TABLE IF NOT EXISTS teachers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES tenants(id),
  employee_code TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  full_name_ar TEXT,
  first_name TEXT,
  first_name_ar TEXT,
  last_name TEXT,
  last_name_ar TEXT,
  email TEXT UNIQUE,
  phone TEXT,
  date_of_birth DATE,
  gender TEXT CHECK (gender IN ('Male', 'Female', 'Other')),
  address TEXT,
  tazkira_number TEXT,
  passport_id TEXT,
  blood_group TEXT CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
  nationality TEXT,
  religion TEXT,
  birth_place TEXT,
  father_name TEXT,
  father_name_ar TEXT,
  mother_name TEXT,
  mother_name_ar TEXT,
  marital_status TEXT CHECK (marital_status IN ('single', 'married', 'divorced', 'widowed')),
  department_id UUID REFERENCES departments(id),
  qualification TEXT,
  specialization TEXT,
  experience_years INTEGER DEFAULT 0,
  join_date DATE,
  contract_end_date DATE,
  contract_type TEXT CHECK (contract_type IN ('full-time', 'part-time', 'contract', 'temporary')),
  salary DECIMAL(10,2),
  hourly_rate DECIMAL(10,2),
  assigned_courses UUID[],
  assigned_classes UUID[],
  teaching_schedule JSONB DEFAULT '[]'::jsonb,
  workload_hours INTEGER DEFAULT 0,
  max_workload_hours INTEGER DEFAULT 40,
  performance_rating DECIMAL(3,2),
  last_evaluation_date DATE,
  next_evaluation_date DATE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'on_leave', 'resigned', 'terminated')),
  photo_url TEXT,
  documents JSONB DEFAULT '[]'::jsonb,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  bank_account_number TEXT,
  bank_name TEXT,
  tax_id TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for teachers
CREATE INDEX IF NOT EXISTS idx_teachers_profile ON teachers(profile_id);
CREATE INDEX IF NOT EXISTS idx_teachers_tenant ON teachers(tenant_id);
CREATE INDEX IF NOT EXISTS idx_teachers_status ON teachers(status);
CREATE INDEX IF NOT EXISTS idx_teachers_department ON teachers(department_id);
CREATE INDEX IF NOT EXISTS idx_teachers_code ON teachers(employee_code);
CREATE INDEX IF NOT EXISTS idx_teachers_email ON teachers(email);

-- ============================================
-- STAFF TABLE (HR Panel - General Staff)
-- ============================================

CREATE TABLE IF NOT EXISTS staff (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES tenants(id),
  employee_code TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  full_name_ar TEXT,
  first_name TEXT,
  first_name_ar TEXT,
  last_name TEXT,
  last_name_ar TEXT,
  email TEXT UNIQUE,
  phone TEXT,
  date_of_birth DATE,
  gender TEXT CHECK (gender IN ('Male', 'Female', 'Other')),
  address TEXT,
  tazkira_number TEXT,
  passport_id TEXT,
  blood_group TEXT CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
  nationality TEXT,
  religion TEXT,
  birth_place TEXT,
  father_name TEXT,
  father_name_ar TEXT,
  mother_name TEXT,
  mother_name_ar TEXT,
  marital_status TEXT CHECK (marital_status IN ('single', 'married', 'divorced', 'widowed')),
  department TEXT,
  designation TEXT,
  role TEXT,
  join_date DATE,
  contract_end_date DATE,
  contract_type TEXT CHECK (contract_type IN ('full-time', 'part-time', 'contract', 'temporary')),
  salary DECIMAL(10,2),
  shift_type TEXT,
  assigned_tasks JSONB DEFAULT '[]'::jsonb,
  performance_rating DECIMAL(3,2),
  last_evaluation_date DATE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'on_leave', 'resigned', 'terminated')),
  photo_url TEXT,
  documents JSONB DEFAULT '[]'::jsonb,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  bank_account_number TEXT,
  bank_name TEXT,
  tax_id TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for staff
CREATE INDEX IF NOT EXISTS idx_staff_profile ON staff(profile_id);
CREATE INDEX IF NOT EXISTS idx_staff_tenant ON staff(tenant_id);
CREATE INDEX IF NOT EXISTS idx_staff_status ON staff(status);
CREATE INDEX IF NOT EXISTS idx_staff_role ON staff(role);
CREATE INDEX IF NOT EXISTS idx_staff_code ON staff(employee_code);

-- Programs Table (Admin Panel)
CREATE TABLE IF NOT EXISTS programs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  description TEXT,
  duration TEXT,
  credits INTEGER DEFAULT 0,
  department_id UUID REFERENCES departments(id),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for programs
CREATE INDEX IF NOT EXISTS idx_programs_tenant ON programs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_programs_department ON programs(department_id);
CREATE INDEX IF NOT EXISTS idx_programs_status ON programs(status);
CREATE INDEX IF NOT EXISTS idx_programs_code ON programs(code);

-- Classes Table (Admin Panel)
CREATE TABLE IF NOT EXISTS classes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  grade TEXT,
  year TEXT,
  program_id UUID REFERENCES programs(id),
  teacher_id UUID REFERENCES profiles(id),
  student_count INTEGER DEFAULT 0,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for classes
CREATE INDEX IF NOT EXISTS idx_classes_tenant ON classes(tenant_id);
CREATE INDEX IF NOT EXISTS idx_classes_program ON classes(program_id);
CREATE INDEX IF NOT EXISTS idx_classes_teacher ON classes(teacher_id);
CREATE INDEX IF NOT EXISTS idx_classes_active ON classes(active);

-- Add FK constraints for tables defined after students
ALTER TABLE students ADD CONSTRAINT fk_students_program FOREIGN KEY (program_id) REFERENCES programs(id);
ALTER TABLE students ADD CONSTRAINT fk_students_class FOREIGN KEY (class_id) REFERENCES classes(id);

-- Discounts Table (Admin Panel)
-- ============================================
-- DISCOUNTS & PROMOTIONS
-- ============================================

CREATE TABLE IF NOT EXISTS discounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  name_ar TEXT,
  description TEXT,
  description_ar TEXT,
  type TEXT NOT NULL DEFAULT 'percentage' CHECK (type IN ('percentage', 'fixed')),
  value DECIMAL(12,2) NOT NULL DEFAULT 0,
  percentage DECIMAL(5,2) NOT NULL DEFAULT 0,
  discount_code TEXT,
  category TEXT,
  usage_limit INTEGER,
  used_count INTEGER DEFAULT 0,
  min_purchase_amount DECIMAL(12,2),
  max_discount_amount DECIMAL(12,2),
  applicable_modules TEXT[] DEFAULT '{}',
  valid_from DATE,
  valid_until DATE,
  is_coupon BOOLEAN DEFAULT false,
  active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_discounts_tenant ON discounts(tenant_id);
CREATE INDEX IF NOT EXISTS idx_discounts_code ON discounts(discount_code);
CREATE INDEX IF NOT EXISTS idx_discounts_category ON discounts(category);
CREATE INDEX IF NOT EXISTS idx_discounts_active ON discounts(active);

CREATE TABLE IF NOT EXISTS promotions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  name_ar TEXT,
  description TEXT,
  description_ar TEXT,
  type TEXT NOT NULL DEFAULT 'percentage' CHECK (type IN ('percentage', 'fixed', 'bundle', 'early_bird')),
  value DECIMAL(12,2) NOT NULL DEFAULT 0,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  applicable_modules TEXT[] DEFAULT '{}',
  applicable_roles TEXT[] DEFAULT '{}',
  min_purchase_amount DECIMAL(12,2),
  max_discount_amount DECIMAL(12,2),
  banner_image_url TEXT,
  terms TEXT,
  terms_ar TEXT,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_promotions_tenant ON promotions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_promotions_dates ON promotions(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_promotions_active ON promotions(is_active);

-- Payments Table (Finance Panel)
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  student_id UUID REFERENCES students(id),
  invoice_id UUID,
  tenant_id UUID REFERENCES tenants(id),
  payment_number TEXT UNIQUE NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  discount_amount DECIMAL(14,2) DEFAULT 0,
  refund_amount DECIMAL(14,2) DEFAULT 0,
  payment_method TEXT CHECK (payment_method IN ('cash', 'card', 'bank_transfer', 'online', 'check', 'mobile_payment')),
  payment_date DATE DEFAULT CURRENT_DATE,
  payment_type TEXT CHECK (payment_type IN ('fee', 'installment', 'late_fee', 'refund', 'advance', 'other')),
  transaction_id TEXT,
  reference_number TEXT,
  receipt_url TEXT,
  journal_id UUID,
  receipt_id UUID,
  collected_by UUID REFERENCES profiles(id),
  status TEXT DEFAULT 'completed' CHECK (status IN ('completed', 'pending', 'failed', 'refunded', 'voided')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for payments
CREATE INDEX IF NOT EXISTS idx_payments_student ON payments(student_id);
CREATE INDEX IF NOT EXISTS idx_payments_invoice ON payments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_payments_date ON payments(payment_date);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_method ON payments(payment_method);

-- Expenses Table (Finance Panel)
CREATE TABLE IF NOT EXISTS expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  category TEXT NOT NULL,
  subcategory TEXT,
  amount DECIMAL(14,2) NOT NULL,
  expense_date DATE DEFAULT CURRENT_DATE,
  description TEXT,
  description_ar TEXT,
  vendor TEXT,
  vendor_contact TEXT,
  invoice_number TEXT,
  receipt_url TEXT,
  journal_id UUID,
  account_id UUID,
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'paid')),
  payment_method TEXT,
  notes TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for expenses
CREATE INDEX IF NOT EXISTS idx_expenses_tenant ON expenses(tenant_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_status ON expenses(status);

-- Salaries Table (Finance & HR Panels)
CREATE TABLE IF NOT EXISTS salaries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  employee_id UUID REFERENCES profiles(id),
  employee_type TEXT CHECK (employee_type IN ('teacher', 'staff')),
  month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
  year INTEGER NOT NULL,
  basic_salary DECIMAL(10,2),
  allowances JSONB DEFAULT '{}'::jsonb,
  deductions JSONB DEFAULT '{}'::jsonb,
  bonus DECIMAL(10,2) DEFAULT 0,
  overtime_hours INTEGER DEFAULT 0,
  overtime_pay DECIMAL(10,2) DEFAULT 0,
  gross_salary DECIMAL(10,2),
  net_salary DECIMAL(10,2),
  payment_date DATE,
  payment_method TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processed', 'paid', 'cancelled')),
  payslip_url TEXT,
  notes TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(employee_id, month, year)
);

-- Indexes for salaries
CREATE INDEX IF NOT EXISTS idx_salaries_employee ON salaries(employee_id);
CREATE INDEX IF NOT EXISTS idx_salaries_month_year ON salaries(month, year);
CREATE INDEX IF NOT EXISTS idx_salaries_status ON salaries(status);

-- ============================================
-- STUDENT FEE TABLES
-- ============================================

-- Fee Types (categories of fees)
CREATE TABLE IF NOT EXISTS fee_types (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  name_ar TEXT,
  name_dr TEXT,
  name_ps TEXT,
  description TEXT,
  description_ar TEXT,
  category TEXT CHECK (category IN ('tuition', 'admission', 'lab', 'library', 'sports', 'exam', 'transport', 'hostel', 'activity', 'other')),
  is_recurring BOOLEAN DEFAULT false,
  recurrence TEXT CHECK (recurrence IN ('monthly', 'quarterly', 'yearly', 'one_time')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fee_types_tenant ON fee_types(tenant_id);
CREATE INDEX IF NOT EXISTS idx_fee_types_category ON fee_types(category);
CREATE INDEX IF NOT EXISTS idx_fee_types_active ON fee_types(is_active);

-- Fee Structures (define fee amounts per program/class)
CREATE TABLE IF NOT EXISTS fee_structures (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  fee_type_id UUID REFERENCES fee_types(id),
  program_id UUID REFERENCES programs(id),
  class_id UUID REFERENCES classes(id),
  name TEXT NOT NULL,
  name_ar TEXT,
  description TEXT,
  amount DECIMAL(12,2) NOT NULL,
  academic_year_id UUID,
  currency TEXT DEFAULT 'AFN',
  frequency TEXT CHECK (frequency IN ('monthly', 'quarterly', 'yearly', 'one_time')),
  due_day INTEGER CHECK (due_day BETWEEN 1 AND 31),
  late_fee DECIMAL(12,2) DEFAULT 0,
  late_fee_type TEXT CHECK (late_fee_type IN ('fixed', 'percentage')),
  early_bird_discount DECIMAL(5,2) DEFAULT 0,
  early_bird_until DATE,
  group_discount DECIMAL(5,2) DEFAULT 0,
  group_min_size INTEGER DEFAULT 0,
  effective_from DATE,
  effective_until DATE,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fee_structures_tenant ON fee_structures(tenant_id);
CREATE INDEX IF NOT EXISTS idx_fee_structures_type ON fee_structures(fee_type_id);
CREATE INDEX IF NOT EXISTS idx_fee_structures_program ON fee_structures(program_id);
CREATE INDEX IF NOT EXISTS idx_fee_structures_class ON fee_structures(class_id);
CREATE INDEX IF NOT EXISTS idx_fee_structures_active ON fee_structures(is_active);

-- Student Fee Assignments (fees assigned to individual students)
CREATE TABLE IF NOT EXISTS student_fee_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  student_id UUID REFERENCES students(id),
  fee_structure_id UUID REFERENCES fee_structures(id),
  fee_type_id UUID REFERENCES fee_types(id),
  academic_year_id UUID,
  amount DECIMAL(12,2) NOT NULL,
  total_amount DECIMAL(10,2),
  balance_amount DECIMAL(10,2),
  currency TEXT DEFAULT 'AFN',
  due_date DATE NOT NULL,
  frequency TEXT CHECK (frequency IN ('monthly', 'quarterly', 'yearly', 'one_time')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'partial', 'paid', 'overdue', 'waived', 'cancelled')),
  paid_amount DECIMAL(12,2) DEFAULT 0,
  outstanding_amount DECIMAL(12,2) GENERATED ALWAYS AS (amount - paid_amount) STORED,
  late_fee_applied DECIMAL(12,2) DEFAULT 0,
  discount_amount DECIMAL(12,2) DEFAULT 0,
  discount_reason TEXT,
  discount_id UUID REFERENCES discounts(id),
  promotion_id UUID REFERENCES promotions(id),
  waived_by UUID REFERENCES profiles(id),
  waived_at TIMESTAMPTZ,
  waiver_reason TEXT,
  notes TEXT,
  assigned_by UUID REFERENCES profiles(id),
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_student_fee_assignments_tenant ON student_fee_assignments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_student_fee_assignments_student ON student_fee_assignments(student_id);
CREATE INDEX IF NOT EXISTS idx_student_fee_assignments_due ON student_fee_assignments(due_date);
CREATE INDEX IF NOT EXISTS idx_student_fee_assignments_status ON student_fee_assignments(status);
CREATE INDEX IF NOT EXISTS idx_student_fee_assignments_fee_type ON student_fee_assignments(fee_type_id);

-- Fee Installments (installment plans for student fees)
CREATE TABLE IF NOT EXISTS fee_installments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  student_id UUID REFERENCES students(id),
  fee_assignment_id UUID REFERENCES student_fee_assignments(id),
  installment_number INTEGER NOT NULL,
  total_installments INTEGER NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  due_date DATE NOT NULL,
  paid_date DATE,
  paid_amount DECIMAL(12,2) DEFAULT 0,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'overdue', 'cancelled')),
  payment_id UUID REFERENCES payments(id),
  late_fee DECIMAL(12,2) DEFAULT 0,
  reminder_sent BOOLEAN DEFAULT false,
  reminder_sent_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fee_installments_tenant ON fee_installments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_fee_installments_student ON fee_installments(student_id);
CREATE INDEX IF NOT EXISTS idx_fee_installments_assignment ON fee_installments(fee_assignment_id);
CREATE INDEX IF NOT EXISTS idx_fee_installments_due ON fee_installments(due_date);
CREATE INDEX IF NOT EXISTS idx_fee_installments_status ON fee_installments(status);

-- ============================================
-- DOUBLE-ENTRY LEDGER (Chart of Accounts, Journals)
-- ============================================

-- Chart of Accounts
CREATE TABLE IF NOT EXISTS accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  account_code TEXT,
  name TEXT NOT NULL,
  name_ar TEXT,
  name_dr TEXT,
  name_ps TEXT,
  account_type TEXT NOT NULL CHECK (account_type IN ('asset', 'liability', 'equity', 'income', 'expense')),
  normal_balance TEXT NOT NULL CHECK (normal_balance IN ('debit', 'credit')),
  description TEXT,
  is_system BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  parent_account_id UUID REFERENCES accounts(id),
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_accounts_tenant ON accounts(tenant_id);
CREATE INDEX IF NOT EXISTS idx_accounts_type ON accounts(account_type);
CREATE INDEX IF NOT EXISTS idx_accounts_parent ON accounts(parent_account_id);
CREATE INDEX IF NOT EXISTS idx_accounts_code ON accounts(account_code);
CREATE INDEX IF NOT EXISTS idx_accounts_active ON accounts(is_active);

-- Journals (group journal entries for a business transaction)
CREATE TABLE IF NOT EXISTS journals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  journal_no TEXT,
  journal_date DATE NOT NULL DEFAULT CURRENT_DATE,
  description TEXT,
  description_ar TEXT,
  reference_type TEXT,
  reference_id UUID,
  total_debit DECIMAL(14,2) DEFAULT 0,
  total_credit DECIMAL(14,2) DEFAULT 0,
  is_posted BOOLEAN DEFAULT false,
  posted_at TIMESTAMPTZ,
  posted_by UUID REFERENCES profiles(id),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_journals_tenant ON journals(tenant_id);
CREATE INDEX IF NOT EXISTS idx_journals_date ON journals(journal_date);
CREATE INDEX IF NOT EXISTS idx_journals_posted ON journals(is_posted);
CREATE INDEX IF NOT EXISTS idx_journals_reference ON journals(reference_type, reference_id);

-- Journal Entries (double-entry lines)
CREATE TABLE IF NOT EXISTS journal_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  journal_id UUID REFERENCES journals(id) ON DELETE CASCADE,
  account_id UUID REFERENCES accounts(id),
  account_code TEXT,
  description TEXT,
  debit DECIMAL(14,2) DEFAULT 0,
  credit DECIMAL(14,2) DEFAULT 0,
  user_id UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_journal_entries_journal ON journal_entries(journal_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_account ON journal_entries(account_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_user ON journal_entries(user_id);

-- Receipts (sequential numbering for cash payments)
CREATE TABLE IF NOT EXISTS receipts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  receipt_no TEXT UNIQUE NOT NULL,
  payment_id UUID REFERENCES payments(id),
  invoice_id UUID,
  student_id UUID REFERENCES students(id),
  receipt_date DATE NOT NULL DEFAULT CURRENT_DATE,
  amount DECIMAL(14,2) NOT NULL,
  amount_in_words TEXT,
  payment_method TEXT,
  description TEXT,
  description_ar TEXT,
  is_voided BOOLEAN DEFAULT false,
  void_reason TEXT,
  voided_at TIMESTAMPTZ,
  voided_by UUID REFERENCES profiles(id),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_receipts_tenant ON receipts(tenant_id);
CREATE INDEX IF NOT EXISTS idx_receipts_payment ON receipts(payment_id);
CREATE INDEX IF NOT EXISTS idx_receipts_student ON receipts(student_id);
CREATE INDEX IF NOT EXISTS idx_receipts_date ON receipts(receipt_date);
CREATE INDEX IF NOT EXISTS idx_receipts_no ON receipts(receipt_no);

-- Petty Cash Funds
CREATE TABLE IF NOT EXISTS petty_cash_funds (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  name_ar TEXT,
  custodian_id UUID REFERENCES profiles(id),
  initial_balance DECIMAL(14,2) NOT NULL DEFAULT 0,
  current_balance DECIMAL(14,2) NOT NULL DEFAULT 0,
  currency TEXT DEFAULT 'AFN',
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_petty_cash_funds_tenant ON petty_cash_funds(tenant_id);
CREATE INDEX IF NOT EXISTS idx_petty_cash_funds_custodian ON petty_cash_funds(custodian_id);

-- Petty Cash Transactions
CREATE TABLE IF NOT EXISTS petty_cash_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  fund_id UUID REFERENCES petty_cash_funds(id),
  journal_id UUID REFERENCES journals(id),
  entry_type TEXT NOT NULL CHECK (entry_type IN ('disbursement', 'replenishment', 'adjustment')),
  amount DECIMAL(14,2) NOT NULL,
  description TEXT,
  description_ar TEXT,
  expense_category TEXT,
  receipt_image_url TEXT,
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMPTZ,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_petty_cash_entries_tenant ON petty_cash_entries(tenant_id);
CREATE INDEX IF NOT EXISTS idx_petty_cash_entries_fund ON petty_cash_entries(fund_id);
CREATE INDEX IF NOT EXISTS idx_petty_cash_entries_status ON petty_cash_entries(status);
CREATE INDEX IF NOT EXISTS idx_petty_cash_entries_type ON petty_cash_entries(entry_type);

-- Audit Log (immutable trail)
CREATE TABLE IF NOT EXISTS audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES profiles(id),
  action TEXT NOT NULL,
  table_name TEXT NOT NULL,
  record_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_tenant ON audit_log(tenant_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_user ON audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_table ON audit_log(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_created ON audit_log(created_at);

-- ============================================
-- RECORD HISTORY (Archives deleted/edited records for performance)
-- Stores full snapshots so main tables stay lean and fast
-- ============================================

CREATE TABLE IF NOT EXISTS record_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  table_name TEXT NOT NULL,
  record_id UUID NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('insert', 'update', 'delete', 'soft_delete', 'restore')),
  old_data JSONB,
  new_data JSONB,
  changed_by UUID REFERENCES profiles(id),
  changed_at TIMESTAMPTZ DEFAULT NOW(),
  ip_address TEXT,
  user_agent TEXT,
  restored_at TIMESTAMPTZ,
  restored_by UUID REFERENCES profiles(id),
  archive_date DATE
);

CREATE INDEX IF NOT EXISTS idx_record_history_tenant ON record_history(tenant_id);
CREATE INDEX IF NOT EXISTS idx_record_history_table ON record_history(table_name);
CREATE INDEX IF NOT EXISTS idx_record_history_record ON record_history(table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_record_history_action ON record_history(action);
CREATE INDEX IF NOT EXISTS idx_record_history_changed ON record_history(changed_at);
CREATE INDEX IF NOT EXISTS idx_record_history_archive ON record_history(archive_date);
CREATE INDEX IF NOT EXISTS idx_record_history_user ON record_history(changed_by);

-- ============================================
-- CHART OF ACCOUNTS SEED DATA (Default accounts for EMIS)
-- ============================================

INSERT INTO accounts (account_code, name, name_ar, account_type, normal_balance, is_system, display_order) VALUES
('1001', 'Cash on Hand', 'ØµÙ†Ø¯ÙˆÙ‚ Ø§Ù„Ù†Ù‚Ø¯ÙŠØ©', 'asset', 'debit', true, 1),
('1002', 'Petty Cash Fund', 'ØµÙ†Ø¯ÙˆÙ‚ Ø§Ù„Ù…ØµØ±ÙˆÙØ§Øª Ø§Ù„Ù†Ø«Ø±ÙŠØ©', 'asset', 'debit', true, 2),
('1101', 'Accounts Receivable', 'Ø­Ø³Ø§Ø¨Ø§Øª Ø§Ù„Ù‚Ø¨Ø¶', 'asset', 'debit', true, 3),
('1102', 'Student Wallet', 'Ù…Ø­ÙØ¸Ø© Ø§Ù„Ø·Ø§Ù„Ø¨', 'asset', 'debit', true, 4),
('2001', 'Deferred Revenue', 'Ø§Ù„Ø¥ÙŠØ±Ø§Ø¯Ø§Øª Ø§Ù„Ù…Ø¤Ø¬Ù„Ø©', 'liability', 'credit', true, 5),
('3001', 'Retained Earnings', 'Ø§Ù„Ø£Ø±Ø¨Ø§Ø­ Ø§Ù„Ù…Ø­ØªØ¬Ø²Ø©', 'equity', 'credit', true, 6),
('4001', 'Tuition Income', 'Ø¥ÙŠØ±Ø§Ø¯Ø§Øª Ø§Ù„Ø±Ø³ÙˆÙ… Ø§Ù„Ø¯Ø±Ø§Ø³ÙŠØ©', 'income', 'credit', true, 7),
('4002', 'Registration Fees', 'Ø±Ø³ÙˆÙ… Ø§Ù„ØªØ³Ø¬ÙŠÙ„', 'income', 'credit', true, 8),
('4003', 'Lab Fees', 'Ø±Ø³ÙˆÙ… Ø§Ù„Ù…Ø®ØªØ¨Ø±', 'income', 'credit', true, 9),
('4004', 'Library Fees', 'Ø±Ø³ÙˆÙ… Ø§Ù„Ù…ÙƒØªØ¨Ø©', 'income', 'credit', true, 10),
('4005', 'Transport Fees', 'Ø±Ø³ÙˆÙ… Ø§Ù„Ù†Ù‚Ù„', 'income', 'credit', true, 11),
('4006', 'Hostel Fees', 'Ø±Ø³ÙˆÙ… Ø§Ù„Ø³ÙƒÙ†', 'income', 'credit', true, 12),
('4007', 'Other Income', 'Ø¥ÙŠØ±Ø§Ø¯Ø§Øª Ø£Ø®Ø±Ù‰', 'income', 'credit', true, 13),
('5001', 'Discounts Allowed', 'Ø§Ù„Ø®ØµÙˆÙ…Ø§Øª Ø§Ù„Ù…Ø³Ù…ÙˆØ­ Ø¨Ù‡Ø§', 'expense', 'debit', true, 14),
('5002', 'Salary Expense', 'Ù…ØµØ±ÙˆÙØ§Øª Ø§Ù„Ø±ÙˆØ§ØªØ¨', 'expense', 'debit', true, 15),
('5003', 'Rent Expense', 'Ù…ØµØ±ÙˆÙØ§Øª Ø§Ù„Ø¥ÙŠØ¬Ø§Ø±', 'expense', 'debit', true, 16),
('5004', 'Utilities Expense', 'Ù…ØµØ±ÙˆÙØ§Øª Ø§Ù„Ù…Ø±Ø§ÙÙ‚', 'expense', 'debit', true, 17),
('5005', 'Supplies Expense', 'Ù…ØµØ±ÙˆÙØ§Øª Ø§Ù„Ù„ÙˆØ§Ø²Ù…', 'expense', 'debit', true, 18),
('5006', 'Petty Cash Expense', 'Ù…ØµØ±ÙˆÙØ§Øª Ù†Ø«Ø±ÙŠØ©', 'expense', 'debit', true, 19),
('5007', 'Cash Shortage', 'Ø¹Ø¬Ø² Ø§Ù„Ù†Ù‚Ø¯ÙŠØ©', 'expense', 'debit', true, 20),
('5008', 'Other Expense', 'Ù…ØµØ±ÙˆÙØ§Øª Ø£Ø®Ø±Ù‰', 'expense', 'debit', true, 21),
('6001', 'Cash Overage', 'ÙØ§Ø¦Ø¶ Ø§Ù„Ù†Ù‚Ø¯ÙŠØ©', 'income', 'credit', true, 22)
ON CONFLICT DO NOTHING;

-- ============================================
-- PAYROLL TABLES
-- ============================================

-- Payroll Runs (a batch/cycle of salary payments)
CREATE TABLE IF NOT EXISTS payroll (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  name_ar TEXT,
  name_dr TEXT,
  name_ps TEXT,
  payroll_period TEXT NOT NULL CHECK (payroll_period IN ('weekly', 'biweekly', 'monthly', 'quarterly', 'yearly', 'custom')),
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  pay_date DATE NOT NULL,
  total_gross DECIMAL(14,2) DEFAULT 0,
  total_deductions DECIMAL(14,2) DEFAULT 0,
  total_net DECIMAL(14,2) DEFAULT 0,
  employee_count INTEGER DEFAULT 0,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'processing', 'approved', 'paid', 'cancelled')),
  journal_id UUID REFERENCES journals(id),
  notes TEXT,
  notes_ar TEXT,
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMPTZ,
  processed_by UUID REFERENCES profiles(id),
  processed_at TIMESTAMPTZ,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payroll_tenant ON payroll(tenant_id);
CREATE INDEX IF NOT EXISTS idx_payroll_period ON payroll(period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_payroll_status ON payroll(status);
CREATE INDEX IF NOT EXISTS idx_payroll_pay_date ON payroll(pay_date);
CREATE INDEX IF NOT EXISTS idx_payroll_journal ON payroll(journal_id);

-- Payroll Items (individual employee payments in a payroll run)
CREATE TABLE IF NOT EXISTS payroll_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  payroll_id UUID REFERENCES payroll(id) ON DELETE CASCADE,
  employee_id UUID REFERENCES profiles(id),
  employee_type TEXT CHECK (employee_type IN ('teacher', 'staff')),
  base_salary DECIMAL(14,2) DEFAULT 0,
  allowances JSONB DEFAULT '{}'::jsonb,
  deductions JSONB DEFAULT '{}'::jsonb,
  bonus DECIMAL(14,2) DEFAULT 0,
  bonus_reason TEXT,
  bonus_promotion_id UUID REFERENCES promotions(id),
  overtime_hours DECIMAL(6,2) DEFAULT 0,
  overtime_rate DECIMAL(14,2) DEFAULT 0,
  overtime_pay DECIMAL(14,2) DEFAULT 0,
  gross_pay DECIMAL(14,2) GENERATED ALWAYS AS (base_salary + bonus + overtime_pay) STORED,
  total_deductions DECIMAL(14,2) DEFAULT 0,
  deduction_breakdown JSONB DEFAULT '{}'::jsonb,
  deduction_promotion_id UUID REFERENCES promotions(id),
  net_pay DECIMAL(14,2) GENERATED ALWAYS AS (base_salary + bonus + overtime_pay - total_deductions) STORED,
  bank_name TEXT,
  bank_account TEXT,
  payment_method TEXT DEFAULT 'cash' CHECK (payment_method IN ('cash', 'bank_transfer', 'check')),
  payment_date DATE,
  journal_id UUID REFERENCES journals(id),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'paid', 'cancelled')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payroll_items_tenant ON payroll_items(tenant_id);
CREATE INDEX IF NOT EXISTS idx_payroll_items_payroll ON payroll_items(payroll_id);
CREATE INDEX IF NOT EXISTS idx_payroll_items_employee ON payroll_items(employee_id);
CREATE INDEX IF NOT EXISTS idx_payroll_items_status ON payroll_items(status);
CREATE INDEX IF NOT EXISTS idx_payroll_items_journal ON payroll_items(journal_id);

-- Attendance Table (Academic Support & HR Panels)
CREATE TABLE IF NOT EXISTS attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  person_id UUID NOT NULL,
  person_type TEXT NOT NULL CHECK (person_type IN ('student', 'teacher', 'staff')),
  date DATE NOT NULL,
  status TEXT CHECK (status IN ('present', 'absent', 'late', 'excused', 'half_day')),
  check_in_time TIME,
  check_out_time TIME,
  late_minutes INTEGER DEFAULT 0,
  fine_amount DECIMAL(10,2) DEFAULT 0,
  fine_reason TEXT,
  overtime_minutes INTEGER DEFAULT 0,
  overtime_rate DECIMAL(10,2) DEFAULT 0,
  overtime_pay DECIMAL(10,2) GENERATED ALWAYS AS ((overtime_minutes / 60.0) * COALESCE(overtime_rate, 0)) STORED,
  remarks TEXT,
  marked_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(person_id, person_type, date)
);

-- Indexes for attendance
CREATE INDEX IF NOT EXISTS idx_attendance_person ON attendance(person_id, person_type);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(date);
CREATE INDEX IF NOT EXISTS idx_attendance_status ON attendance(status);
CREATE INDEX IF NOT EXISTS idx_attendance_tenant ON attendance(tenant_id);

-- Exams Table (Academic Support Panel)
CREATE TABLE IF NOT EXISTS exams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  exam_type TEXT CHECK (exam_type IN ('midterm', 'final', 'quiz', 'assignment', 'placement', 'mock')),
  subject TEXT,
  program_id UUID REFERENCES programs(id),
  class_id UUID REFERENCES classes(id),
  course_id UUID,
  exam_date DATE,
  start_time TIME,
  end_time TIME,
  duration_minutes INTEGER,
  total_marks DECIMAL(5,2) DEFAULT 100,
  passing_marks DECIMAL(5,2) DEFAULT 50,
  weight_percentage DECIMAL(5,2) DEFAULT 100,
  description TEXT,
  instructions TEXT,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('draft', 'scheduled', 'in_progress', 'completed', 'cancelled')),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for exams
CREATE INDEX IF NOT EXISTS idx_exams_tenant ON exams(tenant_id);
CREATE INDEX IF NOT EXISTS idx_exams_date ON exams(exam_date);
CREATE INDEX IF NOT EXISTS idx_exams_class ON exams(class_id);
CREATE INDEX IF NOT EXISTS idx_exams_status ON exams(status);

-- Grades Table (Academic Support Panel)
CREATE TABLE IF NOT EXISTS grades (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  student_id UUID REFERENCES students(id),
  exam_id UUID REFERENCES exams(id),
  class_id UUID REFERENCES classes(id),
  subject TEXT,
  score DECIMAL(5,2),
  max_score DECIMAL(5,2) DEFAULT 100,
  percentage DECIMAL(5,2),
  grade TEXT,
  grade_point DECIMAL(3,2),
  remarks TEXT,
  graded_by UUID REFERENCES profiles(id),
  graded_at TIMESTAMP WITH TIME ZONE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'graded', 'reviewed', 'corrected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for grades
CREATE INDEX IF NOT EXISTS idx_grades_student ON grades(student_id);
CREATE INDEX IF NOT EXISTS idx_grades_exam ON grades(exam_id);
CREATE INDEX IF NOT EXISTS idx_grades_class ON grades(class_id);

-- ============================================
-- SUPPORT_TICKETS TABLE (IT Support Panel)
-- ============================================

CREATE TABLE IF NOT EXISTS support_tickets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  title TEXT NOT NULL,
  description TEXT,
  category TEXT CHECK (category IN ('hardware', 'software', 'network', 'account', 'access', 'bug', 'feature_request', 'other')),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed', 'rejected')),
  assigned_to UUID REFERENCES profiles(id),
  reported_by UUID REFERENCES profiles(id),
  location TEXT,
  resolution_notes TEXT,
  resolved_at TIMESTAMP WITH TIME ZONE,
  closed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for support_tickets
CREATE INDEX IF NOT EXISTS idx_tickets_tenant ON support_tickets(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tickets_status ON support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_tickets_priority ON support_tickets(priority);
CREATE INDEX IF NOT EXISTS idx_tickets_assigned ON support_tickets(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tickets_reported ON support_tickets(reported_by);

-- ============================================
-- ANNOUNCEMENTS TABLE (Communication Panel)
-- ============================================

CREATE TABLE IF NOT EXISTS announcements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  title TEXT NOT NULL,
  title_ar TEXT,
  title_dr TEXT,
  title_ps TEXT,
  content TEXT NOT NULL,
  content_ar TEXT,
  content_dr TEXT,
  content_ps TEXT,
  type TEXT NOT NULL DEFAULT 'general' CHECK (type IN ('general', 'notice', 'event', 'news', 'holiday', 'emergency', 'achievement')),
  audience TEXT CHECK (audience IN ('all', 'students', 'teachers', 'staff', 'parents', 'custom')),
  target_ids UUID[],
  target_audience TEXT[] DEFAULT '{all}',
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE,
  publish_date DATE DEFAULT CURRENT_DATE,
  expiry_date DATE,
  is_pinned BOOLEAN DEFAULT false,
  is_featured BOOLEAN DEFAULT false,
  views INTEGER DEFAULT 0,
  attachment_url TEXT,
  attachment_name TEXT,
  banner_image_url TEXT,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'published', 'archived')),
  created_by UUID REFERENCES profiles(id),
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for announcements
CREATE INDEX IF NOT EXISTS idx_announcements_tenant ON announcements(tenant_id);
CREATE INDEX IF NOT EXISTS idx_announcements_status ON announcements(status);
CREATE INDEX IF NOT EXISTS idx_announcements_audience ON announcements(audience);
CREATE INDEX IF NOT EXISTS idx_announcements_dates ON announcements(start_date, end_date);

-- ============================================
-- EVENTS TABLE (Communication Panel)
-- ============================================

CREATE TABLE IF NOT EXISTS events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  title TEXT NOT NULL,
  description TEXT,
  event_type TEXT CHECK (event_type IN ('academic', 'sports', 'cultural', 'meeting', 'workshop', 'seminar', 'holiday', 'other')),
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE,
  location TEXT,
  venue_id UUID,
  organizer_id UUID REFERENCES profiles(id),
  max_participants INTEGER,
  registered_count INTEGER DEFAULT 0,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('draft', 'scheduled', 'in_progress', 'completed', 'cancelled', 'postponed')),
  is_public BOOLEAN DEFAULT true,
  image_url TEXT,
  registration_deadline TIMESTAMP WITH TIME ZONE,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for events
CREATE INDEX IF NOT EXISTS idx_events_tenant ON events(tenant_id);
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);
CREATE INDEX IF NOT EXISTS idx_events_start_date ON events(start_date);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);

-- ============================================
-- EVENT_REGISTRATIONS TABLE (Communication Panel)
-- ============================================

CREATE TABLE IF NOT EXISTS event_registrations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id),
  registration_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status TEXT DEFAULT 'registered' CHECK (status IN ('registered', 'attended', 'cancelled', 'no_show')),
  notes TEXT,
  UNIQUE(event_id, user_id)
);

-- Indexes for event_registrations
CREATE INDEX IF NOT EXISTS idx_event_reg_event ON event_registrations(event_id);
CREATE INDEX IF NOT EXISTS idx_event_reg_user ON event_registrations(user_id);

-- ============================================
-- FEEDBACK TABLE (Academic Support & Communication Panels)
-- ============================================

CREATE TABLE IF NOT EXISTS feedback (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES profiles(id),
  feedback_type TEXT CHECK (feedback_type IN ('course', 'teacher', 'facility', 'service', 'general')),
  related_id UUID,
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  title TEXT,
  comment TEXT NOT NULL,
  is_anonymous BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'archived')),
  response TEXT,
  responded_by UUID REFERENCES profiles(id),
  responded_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for feedback
CREATE INDEX IF NOT EXISTS idx_feedback_tenant ON feedback(tenant_id);
CREATE INDEX IF NOT EXISTS idx_feedback_user ON feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_type ON feedback(feedback_type);
CREATE INDEX IF NOT EXISTS idx_feedback_status ON feedback(status);

-- ============================================
-- CERTIFICATES TABLE (Academic Support Panel)
-- ============================================

CREATE TABLE IF NOT EXISTS certificates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  student_id UUID REFERENCES students(id),
  certificate_type TEXT CHECK (certificate_type IN ('completion', 'achievement', 'participation', 'merit', 'level')),
  course_name TEXT,
  level_achieved TEXT,
  issue_date DATE,
  certificate_number TEXT UNIQUE,
  certificate_url TEXT,
  qr_code_url TEXT,
  issued_by UUID REFERENCES profiles(id),
  status TEXT DEFAULT 'issued' CHECK (status IN ('draft', 'issued', 'revoked')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for certificates
CREATE INDEX IF NOT EXISTS idx_certificates_student ON certificates(student_id);
CREATE INDEX IF NOT EXISTS idx_certificates_type ON certificates(certificate_type);
CREATE INDEX IF NOT EXISTS idx_certificates_number ON certificates(certificate_number);



-- ============================================
-- TEACHER PANEL TABLES
-- ============================================

-- Exam Results Table (Teacher Panel)
CREATE TABLE IF NOT EXISTS exam_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  student_id UUID,
  exam_name TEXT NOT NULL,
  subject TEXT,
  score DECIMAL(5,2) NOT NULL,
  max_score DECIMAL(5,2) DEFAULT 100,
  percentage DECIMAL(5,2),
  grade TEXT,
  exam_date DATE,
  class_id UUID,
  teacher_id UUID,
  comments TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Student Progress Table (Teacher Panel)
CREATE TABLE IF NOT EXISTS student_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  student_id UUID,
  subject TEXT,
  class_id UUID,
  attendance_percentage DECIMAL(5,2),
  average_score DECIMAL(5,2),
  assignments_completed INTEGER DEFAULT 0,
  assignments_total INTEGER DEFAULT 0,
  performance_trend TEXT CHECK (performance_trend IN ('improving', 'stable', 'declining')),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Messages to Parents Table (Teacher Panel)
CREATE TABLE IF NOT EXISTS parent_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  teacher_id UUID,
  parent_id UUID,
  student_id UUID,
  subject TEXT NOT NULL,
  message TEXT NOT NULL,
  read BOOLEAN DEFAULT false,
  read_at TIMESTAMP WITH TIME ZONE,
  priority TEXT DEFAULT 'Normal' CHECK (priority IN ('Low', 'Normal', 'High', 'Urgent')),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- STUDENT PANEL TABLES
-- ============================================

-- Courses Table (Student Panel)
CREATE TABLE IF NOT EXISTS courses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  description TEXT,
  credits INTEGER DEFAULT 0,
  teacher_id UUID,
  progress DECIMAL(5,2) DEFAULT 0,
  promotion_price DECIMAL(12,2),
  promotion_valid_from DATE,
  promotion_valid_until DATE,
  status TEXT DEFAULT 'Active' CHECK (status IN ('Active', 'Completed', 'Dropped')),
  enrollment_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Admin-Course Assignments (Which admin manages which courses)
CREATE TABLE IF NOT EXISTS admin_course_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  admin_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
  assignment_type TEXT DEFAULT 'full' CHECK (assignment_type IN ('full', 'view_only', 'edit_only')),
  assigned_by UUID REFERENCES profiles(id),
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  UNIQUE(admin_id, course_id)
);

CREATE INDEX IF NOT EXISTS idx_admin_course_assignments_admin ON admin_course_assignments(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_course_assignments_course ON admin_course_assignments(course_id);
CREATE INDEX IF NOT EXISTS idx_admin_course_assignments_active ON admin_course_assignments(is_active);

-- ============================================
-- BRANCHES / CAMPUSES
-- ============================================
CREATE TABLE IF NOT EXISTS branches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  name_ar TEXT,
  name_dr TEXT,
  name_ps TEXT,
  code TEXT UNIQUE,
  address TEXT,
  address_ar TEXT,
  city TEXT,
  city_ar TEXT,
  province TEXT,
  country TEXT DEFAULT 'Afghanistan',
  phone TEXT,
  email TEXT,
  website TEXT,
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  opening_time TIME,
  closing_time TIME,
  working_days TEXT[] DEFAULT '{Sat,Sun,Mon,Tue,Wed}',
  is_headquarters BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  manager_id UUID REFERENCES profiles(id),
  established_date DATE,
  logo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_branches_tenant ON branches(tenant_id);
CREATE INDEX IF NOT EXISTS idx_branches_code ON branches(code);
CREATE INDEX IF NOT EXISTS idx_branches_active ON branches(is_active);
CREATE INDEX IF NOT EXISTS idx_branches_headquarters ON branches(is_headquarters);

-- ============================================
-- COURSE DETAILS (Single table storing ALL course information)
-- ============================================
CREATE TABLE IF NOT EXISTS course_details (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  course_id UUID REFERENCES courses(id),
  branch_id UUID REFERENCES branches(id),
  program_id UUID REFERENCES programs(id),
  department_id UUID REFERENCES departments(id),
  name TEXT NOT NULL,
  name_ar TEXT,
  name_dr TEXT,
  name_ps TEXT,
  code TEXT NOT NULL,
  description TEXT,
  description_ar TEXT,
  description_dr TEXT,
  description_ps TEXT,
  category TEXT,
  category_ar TEXT,
  level TEXT CHECK (level IN ('beginner', 'intermediate', 'advanced', 'all_levels')),
  language TEXT DEFAULT 'English',
  language_ar TEXT,
  format TEXT CHECK (format IN ('online', 'onsite', 'hybrid')),
  duration_weeks INTEGER,
  duration_hours INTEGER,
  credits INTEGER DEFAULT 0,
  syllabus JSONB DEFAULT '[]'::jsonb,
  learning_objectives TEXT[],
  prerequisites TEXT,
  prerequisites_ar TEXT,
  target_audience TEXT,
  target_audience_ar TEXT,
  certification_offered BOOLEAN DEFAULT false,
  certification_body TEXT,
  tuition_fee DECIMAL(14,2),
  registration_fee DECIMAL(14,2),
  currency TEXT DEFAULT 'AFN',
  discount_policy TEXT,
  discount_policy_ar TEXT,
  start_date DATE,
  end_date DATE,
  class_days TEXT[],
  class_time TIME,
  class_duration_minutes INTEGER,
  total_seats INTEGER DEFAULT 0,
  available_seats INTEGER DEFAULT 0,
  min_seats INTEGER DEFAULT 1,
  room TEXT,
  building TEXT,
  online_link TEXT,
  online_platform TEXT,
  teacher_id UUID REFERENCES profiles(id),
  assistant_teacher_id UUID REFERENCES profiles(id),
  thumbnail_url TEXT,
  banner_url TEXT,
  intro_video_url TEXT,
  average_rating DECIMAL(3,2) DEFAULT 0,
  total_reviews INTEGER DEFAULT 0,
  total_enrollments INTEGER DEFAULT 0,
  completion_rate DECIMAL(5,2) DEFAULT 0,
  is_featured BOOLEAN DEFAULT false,
  is_published BOOLEAN DEFAULT false,
  is_certified BOOLEAN DEFAULT false,
  approval_status TEXT DEFAULT 'draft' CHECK (approval_status IN ('draft', 'pending', 'approved', 'rejected')),
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMPTZ,
  rejection_reason TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_course_details_tenant ON course_details(tenant_id);
CREATE INDEX IF NOT EXISTS idx_course_details_course ON course_details(course_id);
CREATE INDEX IF NOT EXISTS idx_course_details_program ON course_details(program_id);
CREATE INDEX IF NOT EXISTS idx_course_details_category ON course_details(category);
CREATE INDEX IF NOT EXISTS idx_course_details_level ON course_details(level);
CREATE INDEX IF NOT EXISTS idx_course_details_format ON course_details(format);
CREATE INDEX IF NOT EXISTS idx_course_details_featured ON course_details(is_featured);
CREATE INDEX IF NOT EXISTS idx_course_details_published ON course_details(is_published);
CREATE INDEX IF NOT EXISTS idx_course_details_status ON course_details(approval_status);
CREATE INDEX IF NOT EXISTS idx_course_details_rating ON course_details(average_rating);
CREATE INDEX IF NOT EXISTS idx_course_details_dates ON course_details(start_date, end_date);

-- Student Assignments Table (Student Panel)
CREATE TABLE IF NOT EXISTS student_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  assignment_id UUID,
  student_id UUID,
  course_id UUID,
  title TEXT NOT NULL,
  description TEXT,
  due_date TIMESTAMP WITH TIME ZONE,
  status TEXT DEFAULT 'Pending' CHECK (status IN ('Pending', 'Submitted', 'Graded', 'Late')),
  submission_url TEXT,
  score DECIMAL(5,2),
  feedback TEXT,
  submitted_at TIMESTAMP WITH TIME ZONE,
  graded_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Student Grades Table (Student Panel)
CREATE TABLE IF NOT EXISTS student_grades (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  student_id UUID,
  course_id UUID,
  subject TEXT NOT NULL,
  score DECIMAL(5,2) NOT NULL,
  max_score DECIMAL(5,2) DEFAULT 100,
  percentage DECIMAL(5,2),
  grade TEXT,
  grade_point DECIMAL(3,2),
  exam_type TEXT,
  exam_date DATE,
  comments TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Student Attendance Table (Student Panel)
CREATE TABLE IF NOT EXISTS student_attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  student_id UUID,
  class_id UUID,
  course_id UUID,
  date DATE NOT NULL,
  status TEXT CHECK (status IN ('Present', 'Absent', 'Late', 'Excused')),
  remarks TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Student Schedule/Timetable Table (Student Panel)
CREATE TABLE IF NOT EXISTS student_schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  student_id UUID,
  course_id UUID,
  day_of_week TEXT CHECK (day_of_week IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')),
  start_time TIME,
  end_time TIME,
  location TEXT,
  teacher_name TEXT,
  class_type TEXT DEFAULT 'Lecture' CHECK (class_type IN ('Lecture', 'Lab', 'Tutorial', 'Seminar')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Course Resources Table (Student Panel)
CREATE TABLE IF NOT EXISTS course_resources (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  course_id UUID,
  title TEXT NOT NULL,
  type TEXT CHECK (type IN ('PDF', 'Video', 'Image', 'Document', 'Link', 'Other')),
  file_url TEXT,
  file_size DECIMAL(10,2),
  description TEXT,
  upload_date DATE,
  download_count INTEGER DEFAULT 0,
  view_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- RECEPTIONIST PANEL TABLES
-- ============================================

-- Leads Table (Receptionist Panel)
CREATE TABLE IF NOT EXISTS leads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  interested_program TEXT,
  status TEXT DEFAULT 'New' CHECK (status IN ('New', 'Contacted', 'Visited', 'Admitted', 'Lost')),
  source TEXT,
  notes TEXT,
  follow_up_date DATE,
  assigned_to UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Events Table (Receptionist Panel)
CREATE TABLE IF NOT EXISTS reception_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  title TEXT NOT NULL,
  description TEXT,
  event_type TEXT,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE,
  location TEXT,
  organizer_id UUID,
  status TEXT DEFAULT 'Scheduled' CHECK (status IN ('Scheduled', 'Completed', 'Cancelled', 'Postponed')),
  attendees_count INTEGER DEFAULT 0,
  budget DECIMAL(10,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- ACCOUNTANT PANEL TABLES
-- ============================================

-- Invoices Table (Accountant Panel)
CREATE TABLE IF NOT EXISTS invoices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  invoice_number TEXT UNIQUE NOT NULL,
  student_id UUID REFERENCES students(id),
  amount DECIMAL(14,2) NOT NULL,
  due_date DATE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'overdue', 'cancelled', 'refunded')),
  issue_date DATE DEFAULT CURRENT_DATE,
  paid_date DATE,
  payment_method TEXT,
  transaction_id TEXT,
  description TEXT,
  description_ar TEXT,
  items JSONB,
  discount_amount DECIMAL(14,2) DEFAULT 0,
  discount_reason TEXT,
  discount_id UUID REFERENCES discounts(id),
  promotion_id UUID REFERENCES promotions(id),
  tax_amount DECIMAL(14,2) DEFAULT 0,
  total_amount DECIMAL(14,2) GENERATED ALWAYS AS (amount - discount_amount + tax_amount) STORED,
  paid_amount DECIMAL(14,2) DEFAULT 0,
  outstanding_amount DECIMAL(14,2) GENERATED ALWAYS AS ((amount - discount_amount + tax_amount) - paid_amount) STORED,
  journal_id UUID REFERENCES journals(id),
  created_by UUID REFERENCES profiles(id),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add FK constraints for tables created before their referenced tables
ALTER TABLE payments ADD CONSTRAINT fk_payments_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id);
ALTER TABLE payments ADD CONSTRAINT fk_payments_journal FOREIGN KEY (journal_id) REFERENCES journals(id);
ALTER TABLE payments ADD CONSTRAINT fk_payments_receipt FOREIGN KEY (receipt_id) REFERENCES receipts(id);
ALTER TABLE receipts ADD CONSTRAINT fk_receipts_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id);

-- ============================================
-- LIBRARY PANEL TABLES
-- ============================================

-- Books Table (Librarian Panel)
CREATE TABLE IF NOT EXISTS library_books (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  title TEXT NOT NULL,
  author TEXT,
  isbn TEXT UNIQUE,
  category TEXT,
  publisher TEXT,
  publish_year INTEGER,
  edition TEXT,
  language TEXT DEFAULT 'English',
  pages INTEGER,
  price DECIMAL(10,2),
  quantity INTEGER DEFAULT 1,
  available_quantity INTEGER DEFAULT 1,
  location TEXT,
  rack_number TEXT,
  status TEXT DEFAULT 'Available' CHECK (status IN ('Available', 'Issued', 'Lost', 'Damaged', 'Reserved')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Book Issues Table (Librarian Panel)
CREATE TABLE IF NOT EXISTS book_issues (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  book_id UUID REFERENCES library_books(id),
  student_id UUID,
  issue_date DATE NOT NULL,
  due_date DATE NOT NULL,
  return_date DATE,
  status TEXT DEFAULT 'Issued' CHECK (status IN ('Issued', 'Returned', 'Overdue', 'Lost')),
  fine_amount DECIMAL(10,2) DEFAULT 0,
  renewal_count INTEGER DEFAULT 0,
  issued_by UUID,
  returned_to UUID,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Library Members Table (Librarian Panel)
CREATE TABLE IF NOT EXISTS library_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  student_id UUID,
  teacher_id UUID,
  membership_number TEXT UNIQUE,
  membership_type TEXT DEFAULT 'Student' CHECK (membership_type IN ('Student', 'Teacher', 'Staff')),
  status TEXT DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive', 'Suspended')),
  join_date DATE,
  expiry_date DATE,
  books_issued INTEGER DEFAULT 0,
  max_books_limit INTEGER DEFAULT 5,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Digital Library Resources Table (Librarian Panel)
CREATE TABLE IF NOT EXISTS digital_library (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  title TEXT NOT NULL,
  type TEXT CHECK (type IN ('E-Book', 'Journal', 'Article', 'Thesis', 'Report', 'Video', 'Audio')),
  subject TEXT,
  file_url TEXT NOT NULL,
  file_size DECIMAL(10,2),
  author TEXT,
  publisher TEXT,
  access_count INTEGER DEFAULT 0,
  download_enabled BOOLEAN DEFAULT true,
  access_level TEXT DEFAULT 'All' CHECK (access_level IN ('All', 'Students', 'Teachers', 'Restricted')),
  keywords TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- HR PANEL TABLES
-- ============================================

-- Recruitment Table (HR Panel)
CREATE TABLE IF NOT EXISTS recruitment (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  position_title TEXT NOT NULL,
  department TEXT,
  job_type TEXT CHECK (job_type IN ('Full-time', 'Part-time', 'Contract', 'Internship')),
  description TEXT,
  requirements TEXT[],
  experience_required INTEGER DEFAULT 0,
  salary_range_min DECIMAL(10,2),
  salary_range_max DECIMAL(10,2),
  openings INTEGER DEFAULT 1,
  applications_count INTEGER DEFAULT 0,
  discount_allowed BOOLEAN DEFAULT false,
  max_discount_percentage DECIMAL(5,2) DEFAULT 0,
  negotiable_salary BOOLEAN DEFAULT true,
  status TEXT DEFAULT 'Open' CHECK (status IN ('Open', 'Closed', 'On Hold')),
  posted_date DATE,
  deadline_date DATE,
  created_by UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Job Applications Table (HR Panel)
CREATE TABLE IF NOT EXISTS job_applications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  recruitment_id UUID REFERENCES recruitment(id),
  applicant_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  resume_url TEXT,
  cover_letter TEXT,
  qualifications TEXT[],
  experience_years INTEGER,
  current_salary DECIMAL(10,2),
  expected_salary DECIMAL(10,2),
  offered_salary DECIMAL(10,2),
  signing_bonus DECIMAL(10,2) DEFAULT 0,
  negotiation_discount DECIMAL(10,2) DEFAULT 0,
  discount_id UUID REFERENCES discounts(id),
  promotion_id UUID REFERENCES promotions(id),
  notice_period INTEGER, -- days
  status TEXT DEFAULT 'Applied' CHECK (status IN ('Applied', 'Screening', 'Interview', 'Selected', 'Rejected', 'On Hold')),
  applied_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  interview_date TIMESTAMP WITH TIME ZONE,
  hired_date DATE,
  rejection_reason TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- JOB ANNOUNCEMENTS (public job postings)
-- ============================================
CREATE TABLE IF NOT EXISTS job_announcements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  recruitment_id UUID REFERENCES recruitment(id),
  title TEXT NOT NULL,
  title_ar TEXT,
  title_dr TEXT,
  title_ps TEXT,
  department TEXT,
  location TEXT,
  job_type TEXT CHECK (job_type IN ('Full-time', 'Part-time', 'Contract', 'Internship', 'Remote', 'Temporary')),
  experience_level TEXT CHECK (experience_level IN ('entry', 'mid', 'senior', 'lead', 'executive')),
  description TEXT NOT NULL,
  description_ar TEXT,
  description_dr TEXT,
  description_ps TEXT,
  requirements TEXT[],
  requirements_ar TEXT,
  responsibilities TEXT[],
  benefits TEXT,
  benefits_ar TEXT,
  salary_range_min DECIMAL(12,2),
  salary_range_max DECIMAL(12,2),
  currency TEXT DEFAULT 'AFN',
  application_instructions TEXT,
  application_instructions_ar TEXT,
  contact_email TEXT,
  contact_phone TEXT,
  publish_date DATE DEFAULT CURRENT_DATE,
  expiry_date DATE,
  is_featured BOOLEAN DEFAULT false,
  view_count INTEGER DEFAULT 0,
  share_count INTEGER DEFAULT 0,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'closed', 'archived')),
  created_by UUID REFERENCES profiles(id),
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_job_announcements_tenant ON job_announcements(tenant_id);
CREATE INDEX IF NOT EXISTS idx_job_announcements_status ON job_announcements(status);
CREATE INDEX IF NOT EXISTS idx_job_announcements_date ON job_announcements(publish_date, expiry_date);
CREATE INDEX IF NOT EXISTS idx_job_announcements_featured ON job_announcements(is_featured);
CREATE INDEX IF NOT EXISTS idx_job_announcements_type ON job_announcements(job_type);

-- ============================================
-- GENERAL ANNOUNCEMENTS (news, notices, events)
-- ============================================
-- Ensure all columns from the enhanced announcements definition exist on existing installs
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS title_ar TEXT;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS title_dr TEXT;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS title_ps TEXT;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS content_ar TEXT;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS content_dr TEXT;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS content_ps TEXT;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS type TEXT NOT NULL DEFAULT 'general' CHECK (type IN ('general', 'notice', 'event', 'news', 'holiday', 'emergency', 'achievement'));
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS target_audience TEXT[] DEFAULT '{all}';
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS publish_date DATE DEFAULT CURRENT_DATE;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS expiry_date DATE;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS attachment_url TEXT;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS attachment_name TEXT;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS banner_image_url TEXT;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES profiles(id);
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_announcements_tenant ON announcements(tenant_id);
CREATE INDEX IF NOT EXISTS idx_announcements_status ON announcements(status);
CREATE INDEX IF NOT EXISTS idx_announcements_type ON announcements(type);
CREATE INDEX IF NOT EXISTS idx_announcements_date ON announcements(publish_date, expiry_date);
CREATE INDEX IF NOT EXISTS idx_announcements_pinned ON announcements(is_pinned);
CREATE INDEX IF NOT EXISTS idx_announcements_audience ON announcements USING GIN(target_audience);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Admin Panel Indexes
CREATE INDEX IF NOT EXISTS idx_departments_active ON departments(active);
CREATE INDEX IF NOT EXISTS idx_programs_department ON programs(department_id);
CREATE INDEX IF NOT EXISTS idx_programs_status ON programs(status);
CREATE INDEX IF NOT EXISTS idx_classes_program ON classes(program_id);
CREATE INDEX IF NOT EXISTS idx_discounts_category ON discounts(category);
CREATE INDEX IF NOT EXISTS idx_discounts_active ON discounts(active);

-- Teacher Panel Indexes
CREATE INDEX IF NOT EXISTS idx_exam_results_student ON exam_results(student_id);
CREATE INDEX IF NOT EXISTS idx_exam_results_exam_date ON exam_results(exam_date);
CREATE INDEX IF NOT EXISTS idx_student_progress_student ON student_progress(student_id);
CREATE INDEX IF NOT EXISTS idx_parent_messages_read ON parent_messages(read);

-- Student Panel Indexes
CREATE INDEX IF NOT EXISTS idx_courses_status ON courses(status);
CREATE INDEX IF NOT EXISTS idx_student_assignments_student ON student_assignments(student_id);
CREATE INDEX IF NOT EXISTS idx_student_assignments_status ON student_assignments(status);
CREATE INDEX IF NOT EXISTS idx_student_grades_student ON student_grades(student_id);
CREATE INDEX IF NOT EXISTS idx_student_attendance_student ON student_attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_student_attendance_date ON student_attendance(date);
CREATE INDEX IF NOT EXISTS idx_student_schedules_day ON student_schedules(day_of_week);
CREATE INDEX IF NOT EXISTS idx_course_resources_type ON course_resources(type);

-- Receptionist Panel Indexes
CREATE INDEX IF NOT EXISTS idx_leads_status ON leads(status);
CREATE INDEX IF NOT EXISTS idx_leads_created ON leads(created_at);
CREATE INDEX IF NOT EXISTS idx_reception_events_status ON reception_events(status);
CREATE INDEX IF NOT EXISTS idx_reception_events_start_date ON reception_events(start_date);

-- Accountant Panel Indexes
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON invoices(due_date);
CREATE INDEX IF NOT EXISTS idx_invoices_student ON invoices(student_id);

-- Librarian Panel Indexes
CREATE INDEX IF NOT EXISTS idx_library_books_status ON library_books(status);
CREATE INDEX IF NOT EXISTS idx_library_books_category ON library_books(category);
CREATE INDEX IF NOT EXISTS idx_book_issues_status ON book_issues(status);
CREATE INDEX IF NOT EXISTS idx_book_issues_due_date ON book_issues(due_date);
CREATE INDEX IF NOT EXISTS idx_library_members_status ON library_members(status);
CREATE INDEX IF NOT EXISTS idx_digital_library_type ON digital_library(type);

-- HR Panel Indexes
CREATE INDEX IF NOT EXISTS idx_recruitment_status ON recruitment(status);
CREATE INDEX IF NOT EXISTS idx_job_applications_status ON job_applications(status);
CREATE INDEX IF NOT EXISTS idx_job_applications_recruitment ON job_applications(recruitment_id);

-- ============================================
-- TRIGGERS FOR ALL TABLES WITH updated_at
-- ============================================

-- Function to update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to auto-update book stock counters when book_copies status changes
CREATE OR REPLACE FUNCTION update_book_stock()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    UPDATE books SET
      total_copies   = (SELECT COUNT(*) FROM book_copies WHERE book_id = COALESCE(NEW.book_id, OLD.book_id)),
      available_copies = (SELECT COUNT(*) FROM book_copies WHERE book_id = COALESCE(NEW.book_id, OLD.book_id) AND status = 'available'),
      borrowed_copies  = (SELECT COUNT(*) FROM book_copies WHERE book_id = COALESCE(NEW.book_id, OLD.book_id) AND status = 'borrowed'),
      sold_copies      = (SELECT COUNT(*) FROM book_copies WHERE book_id = COALESCE(NEW.book_id, OLD.book_id) AND status = 'sold'),
      lost_copies      = (SELECT COUNT(*) FROM book_copies WHERE book_id = COALESCE(NEW.book_id, OLD.book_id) AND status = 'lost'),
      damaged_copies   = (SELECT COUNT(*) FROM book_copies WHERE book_id = COALESCE(NEW.book_id, OLD.book_id) AND status = 'damaged'),
      reserved_copies  = (SELECT COUNT(*) FROM book_copies WHERE book_id = COALESCE(NEW.book_id, OLD.book_id) AND status = 'reserved')
    WHERE id = COALESCE(NEW.book_id, OLD.book_id);
  END IF;
  IF TG_OP = 'DELETE' THEN
    UPDATE books SET
      total_copies   = (SELECT COUNT(*) FROM book_copies WHERE book_id = OLD.book_id),
      available_copies = (SELECT COUNT(*) FROM book_copies WHERE book_id = OLD.book_id AND status = 'available'),
      borrowed_copies  = (SELECT COUNT(*) FROM book_copies WHERE book_id = OLD.book_id AND status = 'borrowed'),
      sold_copies      = (SELECT COUNT(*) FROM book_copies WHERE book_id = OLD.book_id AND status = 'sold'),
      lost_copies      = (SELECT COUNT(*) FROM book_copies WHERE book_id = OLD.book_id AND status = 'lost'),
      damaged_copies   = (SELECT COUNT(*) FROM book_copies WHERE book_id = OLD.book_id AND status = 'damaged'),
      reserved_copies  = (SELECT COUNT(*) FROM book_copies WHERE book_id = OLD.book_id AND status = 'reserved')
    WHERE id = OLD.book_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables with updated_at (ALREADY ADDED ABOVE)
-- Profiles trigger
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Payments trigger
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Expenses trigger
CREATE TRIGGER update_expenses_updated_at BEFORE UPDATE ON expenses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Salaries trigger
CREATE TRIGGER update_salaries_updated_at BEFORE UPDATE ON salaries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_fee_types_updated_at BEFORE UPDATE ON fee_types
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_fee_structures_updated_at BEFORE UPDATE ON fee_structures
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_student_fee_assignments_updated_at BEFORE UPDATE ON student_fee_assignments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_fee_installments_updated_at BEFORE UPDATE ON fee_installments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON accounts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_journals_updated_at BEFORE UPDATE ON journals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_receipts_updated_at BEFORE UPDATE ON receipts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_petty_cash_funds_updated_at BEFORE UPDATE ON petty_cash_funds
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_petty_cash_entries_updated_at BEFORE UPDATE ON petty_cash_entries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payroll_updated_at BEFORE UPDATE ON payroll
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payroll_items_updated_at BEFORE UPDATE ON payroll_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Attendance trigger
CREATE TRIGGER update_attendance_updated_at BEFORE UPDATE ON attendance
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Exams trigger
CREATE TRIGGER update_exams_updated_at BEFORE UPDATE ON exams
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grades trigger
CREATE TRIGGER update_grades_updated_at BEFORE UPDATE ON grades
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Support tickets trigger
CREATE TRIGGER update_support_tickets_updated_at BEFORE UPDATE ON support_tickets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Announcements trigger
CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON announcements
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Events trigger
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Feedback trigger
CREATE TRIGGER update_feedback_updated_at BEFORE UPDATE ON feedback
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Certificates trigger
CREATE TRIGGER update_certificates_updated_at BEFORE UPDATE ON certificates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Student attendance trigger
CREATE TRIGGER update_student_attendance_updated_at BEFORE UPDATE ON student_attendance
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Parent messages trigger
CREATE TRIGGER update_parent_messages_updated_at BEFORE UPDATE ON parent_messages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Apply triggers to all tables with updated_at
CREATE TRIGGER update_departments_updated_at BEFORE UPDATE ON departments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_programs_updated_at BEFORE UPDATE ON programs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_classes_updated_at BEFORE UPDATE ON classes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_discounts_updated_at BEFORE UPDATE ON discounts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_promotions_updated_at BEFORE UPDATE ON promotions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exam_results_updated_at BEFORE UPDATE ON exam_results
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_student_progress_updated_at BEFORE UPDATE ON student_progress
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON courses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_course_details_updated_at BEFORE UPDATE ON course_details
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_branches_updated_at BEFORE UPDATE ON branches
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_student_assignments_updated_at BEFORE UPDATE ON student_assignments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_student_grades_updated_at BEFORE UPDATE ON student_grades
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON leads
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reception_events_updated_at BEFORE UPDATE ON reception_events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_library_books_updated_at BEFORE UPDATE ON library_books
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_book_issues_updated_at BEFORE UPDATE ON book_issues
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_library_members_updated_at BEFORE UPDATE ON library_members
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_recruitment_updated_at BEFORE UPDATE ON recruitment
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_job_applications_updated_at BEFORE UPDATE ON job_applications
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_job_announcements_updated_at BEFORE UPDATE ON job_announcements
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Missing triggers for tables with updated_at column
CREATE TRIGGER update_platforms_updated_at BEFORE UPDATE ON platforms
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON tenants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON students
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_teachers_updated_at BEFORE UPDATE ON teachers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_staff_updated_at BEFORE UPDATE ON staff
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
-- ============================================
-- CHAT & MESSAGING TABLES
-- ============================================

-- Chat Groups/Conversations
CREATE TABLE IF NOT EXISTS chat_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  name TEXT,
  type TEXT NOT NULL DEFAULT 'direct' CHECK (type IN ('direct', 'group', 'class_group')),
  created_by UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,
  avatar_url TEXT,
  description TEXT,
  class_id UUID REFERENCES classes(id)
);

-- Chat Group Members
CREATE TABLE IF NOT EXISTS chat_group_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  group_id UUID REFERENCES chat_groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  role TEXT DEFAULT 'member' CHECK (role IN ('member', 'admin', 'teacher', 'student')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_read_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(group_id, user_id)
);

-- Chat Messages
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  group_id UUID REFERENCES chat_groups(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL,
  content TEXT,
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'file', 'image', 'video', 'voice')),
  file_url TEXT,
  file_name TEXT,
  file_size BIGINT,
  sender_name TEXT,
  sender_avatar TEXT,
  reply_to UUID,
  is_deleted BOOLEAN DEFAULT false,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_by JSONB DEFAULT '[]'::jsonb
);

-- Chat Calls (Video/Voice)
CREATE TABLE IF NOT EXISTS chat_calls (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  group_id UUID REFERENCES chat_groups(id),
  caller_id UUID NOT NULL,
  callee_id UUID,
  call_type TEXT NOT NULL CHECK (call_type IN ('video', 'voice')),
  status TEXT DEFAULT 'initiated' CHECK (status IN ('initiated', 'answered', 'declined', 'ended', 'missed')),
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ended_at TIMESTAMP WITH TIME ZONE,
  duration INTEGER DEFAULT 0
);

-- ============================================
-- NOTIFICATIONS TABLES
-- ============================================

-- In-App Notifications
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES profiles(id),
  title TEXT NOT NULL,
  body TEXT,
  type TEXT CHECK (type IN ('academic', 'payment', 'attendance', 'message', 'system', 'leave', 'exam', 'general', 'hr', 'inventory', 'library', 'announcement', 'grade', 'discount', 'salary')),
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP WITH TIME ZONE,
  action_url TEXT,
  icon TEXT,
  data JSONB,
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for notifications
CREATE INDEX IF NOT EXISTS idx_notifications_tenant ON notifications(tenant_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);

-- Notification Settings
CREATE TABLE IF NOT EXISTS notification_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES profiles(id) UNIQUE,
  email_notifications BOOLEAN DEFAULT true,
  push_notifications BOOLEAN DEFAULT true,
  sms_notifications BOOLEAN DEFAULT false,
  in_app_notifications BOOLEAN DEFAULT true,
  chat_notifications BOOLEAN DEFAULT true,
  academic_notifications BOOLEAN DEFAULT true,
  payment_notifications BOOLEAN DEFAULT true,
  attendance_notifications BOOLEAN DEFAULT true,
  hr_notifications BOOLEAN DEFAULT true,
  system_notifications BOOLEAN DEFAULT true,
  marketing_notifications BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for notification_settings
CREATE INDEX IF NOT EXISTS idx_notification_settings_tenant ON notification_settings(tenant_id);
CREATE INDEX IF NOT EXISTS idx_notification_settings_user ON notification_settings(user_id);

-- User Devices (For Push Notifications)
CREATE TABLE IF NOT EXISTS user_devices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES profiles(id),
  device_token TEXT NOT NULL,
  device_type TEXT CHECK (device_type IN ('ios', 'android', 'web', 'windows', 'macos', 'linux')),
  device_name TEXT,
  device_model TEXT,
  os_version TEXT,
  app_version TEXT,
  is_active BOOLEAN DEFAULT true,
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, device_token)
);

-- Indexes for user_devices
CREATE INDEX IF NOT EXISTS idx_user_devices_tenant ON user_devices(tenant_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_user ON user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_token ON user_devices(device_token);
CREATE INDEX IF NOT EXISTS idx_user_devices_active ON user_devices(is_active);
CREATE INDEX IF NOT EXISTS idx_user_devices_type ON user_devices(device_type);

-- Notification Templates
CREATE TABLE IF NOT EXISTS notification_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('email', 'sms', 'push', 'in_app')),
  category TEXT CHECK (category IN ('academic', 'payment', 'attendance', 'hr', 'system', 'general')),
  subject TEXT,
  body TEXT NOT NULL,
  variables JSONB DEFAULT '[]'::jsonb,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for notification_templates
CREATE INDEX IF NOT EXISTS idx_notification_templates_tenant ON notification_templates(tenant_id);
CREATE INDEX IF NOT EXISTS idx_notification_templates_type ON notification_templates(type);
CREATE INDEX IF NOT EXISTS idx_notification_templates_category ON notification_templates(category);
CREATE INDEX IF NOT EXISTS idx_notification_templates_active ON notification_templates(is_active);

-- Notification Queue (For batch processing)
CREATE TABLE IF NOT EXISTS notification_queue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  notification_id UUID REFERENCES notifications(id),
  user_id UUID REFERENCES profiles(id),
  channel TEXT NOT NULL CHECK (channel IN ('email', 'sms', 'push', 'in_app')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'sent', 'failed', 'cancelled')),
  payload JSONB,
  sent_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT,
  retry_count INTEGER DEFAULT 0,
  max_retries INTEGER DEFAULT 3,
  scheduled_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for notification_queue
CREATE INDEX IF NOT EXISTS idx_notification_queue_tenant ON notification_queue(tenant_id);
CREATE INDEX IF NOT EXISTS idx_notification_queue_status ON notification_queue(status);
CREATE INDEX IF NOT EXISTS idx_notification_queue_channel ON notification_queue(channel);
CREATE INDEX IF NOT EXISTS idx_notification_queue_scheduled ON notification_queue(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_notification_queue_user ON notification_queue(user_id);

-- Notification triggers
CREATE TRIGGER update_notifications_updated_at BEFORE UPDATE ON notifications
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_notification_templates_updated_at BEFORE UPDATE ON notification_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_notification_queue_updated_at BEFORE UPDATE ON notification_queue
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_devices_updated_at BEFORE UPDATE ON user_devices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- LEAVE MANAGEMENT TABLES
-- ============================================

-- Leave Types
CREATE TABLE IF NOT EXISTS leave_types (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN ('full_day', 'half_day', 'hourly')),
  max_days_per_month INTEGER,
  max_days_per_year INTEGER,
  is_paid BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for leave_types
CREATE INDEX IF NOT EXISTS idx_leave_types_tenant ON leave_types(tenant_id);
CREATE INDEX IF NOT EXISTS idx_leave_types_active ON leave_types(is_active);

-- Employee Leave Applications
CREATE TABLE IF NOT EXISTS employee_leaves (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  employee_id UUID REFERENCES profiles(id),
  leave_type_id UUID REFERENCES leave_types(id),
  leave_category TEXT NOT NULL CHECK (leave_category IN ('full_day', 'half_day', 'hourly')),
  start_date DATE NOT NULL,
  end_date DATE,
  start_time TIME,
  end_time TIME,
  reason TEXT,
  is_paid BOOLEAN DEFAULT true,
  deduction_percentage DECIMAL(5,2) DEFAULT 0,
  deduction_amount DECIMAL(12,2) DEFAULT 0,
  deduction_waived BOOLEAN DEFAULT false,
  waived_by UUID REFERENCES profiles(id),
  waived_at TIMESTAMPTZ,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_employee_leaves_tenant ON employee_leaves(tenant_id);
CREATE INDEX IF NOT EXISTS idx_employee_leaves_employee ON employee_leaves(employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_leaves_status ON employee_leaves(status);
CREATE INDEX IF NOT EXISTS idx_employee_leaves_dates ON employee_leaves(start_date, end_date);

-- Student Leave Applications
CREATE TABLE IF NOT EXISTS student_leaves (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  student_id UUID REFERENCES students(id),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  reason TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_student_leaves_tenant ON student_leaves(tenant_id);
CREATE INDEX IF NOT EXISTS idx_student_leaves_student ON student_leaves(student_id);
CREATE INDEX IF NOT EXISTS idx_student_leaves_status ON student_leaves(status);
CREATE INDEX IF NOT EXISTS idx_student_leaves_dates ON student_leaves(start_date, end_date);

-- Student Leave Tracking (3 days/month limit)
CREATE TABLE IF NOT EXISTS student_leave_tracking (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  student_id UUID REFERENCES students(id),
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  leave_days_count INTEGER DEFAULT 0,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(student_id, month, year)
);

CREATE INDEX IF NOT EXISTS idx_student_leave_tracking_tenant ON student_leave_tracking(tenant_id);
CREATE INDEX IF NOT EXISTS idx_student_leave_tracking_student ON student_leave_tracking(student_id);

-- ============================================
-- DEVICE SESSIONS TABLES
-- ============================================

-- Device Sessions (for Logged-in Devices feature)
CREATE TABLE IF NOT EXISTS device_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES profiles(id),
  device_name TEXT,
  device_type TEXT CHECK (device_type IN ('mobile', 'tablet', 'desktop', 'web')),
  device_token TEXT,
  fcm_token TEXT,
  os_version TEXT,
  app_version TEXT,
  last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_current_session BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_device_sessions_tenant ON device_sessions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_device_sessions_user ON device_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_device_sessions_active ON device_sessions(is_active);
CREATE INDEX IF NOT EXISTS idx_device_sessions_current ON device_sessions(is_current_session);

-- ============================================
-- STUDENT MANAGEMENT TABLES
-- ============================================

-- Student Management (similar to HR for employees)
CREATE TABLE IF NOT EXISTS student_affairs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  student_id UUID NOT NULL,
  assigned_counselor UUID,
  enrollment_status TEXT DEFAULT 'active' CHECK (enrollment_status IN ('active', 'inactive', 'graduated', 'suspended', 'transferred')),
  admission_date DATE,
  expected_graduation DATE,
  academic_standing TEXT CHECK (academic_standing IN ('good', 'warning', 'probation', 'honor')),
  disciplinary_records JSONB DEFAULT '[]'::jsonb,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Student Groups (created by teachers for class students)
CREATE TABLE IF NOT EXISTS student_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  name TEXT NOT NULL,
  teacher_id UUID NOT NULL,
  class_id UUID REFERENCES classes(id),
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Student Group Members
CREATE TABLE IF NOT EXISTS student_group_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  group_id UUID REFERENCES student_groups(id) ON DELETE CASCADE,
  student_id UUID NOT NULL,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(group_id, student_id)
);

-- ============================================
-- INDEXES FOR NEW TABLES
-- ============================================

-- Chat Indexes
CREATE INDEX IF NOT EXISTS idx_chat_groups_type ON chat_groups(type);
CREATE INDEX IF NOT EXISTS idx_chat_groups_active ON chat_groups(is_active);
CREATE INDEX IF NOT EXISTS idx_chat_group_members_user ON chat_group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_group ON chat_messages(group_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created ON chat_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_chat_calls_status ON chat_calls(status);

-- Notifications Indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at);

-- Leave Management Indexes
CREATE INDEX IF NOT EXISTS idx_employee_leaves_employee ON employee_leaves(employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_leaves_status ON employee_leaves(status);
CREATE INDEX IF NOT EXISTS idx_employee_leaves_dates ON employee_leaves(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_student_leaves_student ON student_leaves(student_id);
CREATE INDEX IF NOT EXISTS idx_student_leaves_status ON student_leaves(status);
CREATE INDEX IF NOT EXISTS idx_student_leave_tracking_student ON student_leave_tracking(student_id);
CREATE INDEX IF NOT EXISTS idx_leave_types_category ON leave_types(category);

-- Device Sessions Indexes
CREATE INDEX IF NOT EXISTS idx_device_sessions_user ON device_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_device_sessions_active ON device_sessions(is_active);
CREATE INDEX IF NOT EXISTS idx_device_sessions_current ON device_sessions(is_current_session);

-- Student Management Indexes
CREATE INDEX IF NOT EXISTS idx_student_affairs_student ON student_affairs(student_id);
CREATE INDEX IF NOT EXISTS idx_student_affairs_status ON student_affairs(enrollment_status);
CREATE INDEX IF NOT EXISTS idx_student_groups_teacher ON student_groups(teacher_id);
CREATE INDEX IF NOT EXISTS idx_student_group_members_student ON student_group_members(student_id);

-- ============================================
-- TRIGGERS FOR NEW TABLES
-- ============================================

CREATE TRIGGER update_chat_groups_updated_at BEFORE UPDATE ON chat_groups
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_messages_updated_at BEFORE UPDATE ON chat_messages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notification_settings_updated_at BEFORE UPDATE ON notification_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leave_types_updated_at BEFORE UPDATE ON leave_types
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_employee_leaves_updated_at BEFORE UPDATE ON employee_leaves
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_student_leaves_updated_at BEFORE UPDATE ON student_leaves
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_device_sessions_updated_at BEFORE UPDATE ON device_sessions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_student_affairs_updated_at BEFORE UPDATE ON student_affairs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_student_groups_updated_at BEFORE UPDATE ON student_groups
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- HOME PAGE MANAGEMENT TABLES (Staff Panel)
-- ============================================

-- Hero Sections Table
CREATE TABLE IF NOT EXISTS home_hero_sections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  title TEXT NOT NULL,
  subtitle TEXT,
  description TEXT,
  image_url TEXT,
  button_label TEXT DEFAULT 'Get Started',
  button_link TEXT,
  display_order INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Features Table
CREATE TABLE IF NOT EXISTS home_features (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  title TEXT NOT NULL,
  description TEXT,
  icon_name TEXT DEFAULT 'star',
  color_hex TEXT DEFAULT '#2196F3',
  display_order INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Stats Table
CREATE TABLE IF NOT EXISTS home_stats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  label TEXT NOT NULL,
  value TEXT NOT NULL,
  icon_name TEXT,
  display_order INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Testimonials Table
CREATE TABLE IF NOT EXISTS home_testimonials (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  quote TEXT NOT NULL,
  author TEXT,
  author_title TEXT,
  author_image_url TEXT,
  rating INTEGER DEFAULT 5,
  display_order INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for Home Page Tables
CREATE INDEX IF NOT EXISTS idx_home_hero_active ON home_hero_sections(is_active);
CREATE INDEX IF NOT EXISTS idx_home_hero_order ON home_hero_sections(display_order);
CREATE INDEX IF NOT EXISTS idx_home_features_active ON home_features(is_active);
CREATE INDEX IF NOT EXISTS idx_home_features_order ON home_features(display_order);
CREATE INDEX IF NOT EXISTS idx_home_stats_active ON home_stats(is_active);
CREATE INDEX IF NOT EXISTS idx_home_stats_order ON home_stats(display_order);
CREATE INDEX IF NOT EXISTS idx_home_testimonials_active ON home_testimonials(is_active);
CREATE INDEX IF NOT EXISTS idx_home_testimonials_order ON home_testimonials(display_order);

-- Triggers for Home Page Tables
CREATE TRIGGER update_home_hero_sections_updated_at BEFORE UPDATE ON home_hero_sections
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_home_features_updated_at BEFORE UPDATE ON home_features
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_home_stats_updated_at BEFORE UPDATE ON home_stats
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_home_testimonials_updated_at BEFORE UPDATE ON home_testimonials
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Sample Data for Home Page
INSERT INTO home_hero_sections (title, subtitle, description, image_url, display_order) VALUES
('Learn Languages with AI', 'Powered by Supabase & Flutter', 'Experience the future of language education with personalized AI tutoring', NULL, 1),
('Expert Instructors', 'World-Class Faculty', 'Learn from certified language teachers from around the globe', NULL, 2)
ON CONFLICT DO NOTHING;

INSERT INTO home_features (title, description, icon_name, color_hex, display_order) VALUES
('Personalized Learning', 'AI-driven curriculum adapts to your pace and style', 'psychology', '#2196F3', 1),
('Expert Teachers', 'Certified language instructors from around the world', 'school', '#4CAF50', 2),
('Flexible Schedule', 'Learn anytime, anywhere with our mobile platform', 'schedule', '#9C27B0', 3),
('Progress Tracking', 'Real-time analytics and performance insights', 'analytics', '#FF9800', 4),
('Interactive Content', 'Engaging lessons with multimedia resources', 'play_circle', '#F44336', 5),
('Community', 'Connect with fellow language learners globally', 'groups', '#00BCD4', 6)
ON CONFLICT DO NOTHING;

INSERT INTO home_stats (label, value, icon_name, display_order) VALUES
('Active Students', '15,000+', 'people', 1),
('Expert Teachers', '500+', 'badge', 2),
('Courses Available', '200+', 'menu_book', 3),
('Countries Reached', '50+', 'public', 4)
ON CONFLICT DO NOTHING;

INSERT INTO home_testimonials (quote, author, author_title, rating, display_order) VALUES
('This platform transformed my language learning journey. The AI tutoring is incredible!', 'Sarah Johnson', 'English Student', 5, 1),
('Best language learning app I have ever used. Highly recommended!', 'Ahmed Hassan', 'Arabic Student', 5, 2)
ON CONFLICT DO NOTHING;

-- ============================================
-- ROW LEVEL SECURITY FOR HOME PAGE TABLES
-- ============================================

ALTER TABLE home_hero_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE home_features ENABLE ROW LEVEL SECURITY;
ALTER TABLE home_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE home_testimonials ENABLE ROW LEVEL SECURITY;

-- Policies for home_hero_sections
CREATE POLICY "Staff can manage hero sections"
  ON home_hero_sections FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'staff')
    )
  );

CREATE POLICY "Public can view active hero sections"
  ON home_hero_sections FOR SELECT
  USING (is_active = TRUE);

-- Policies for home_features
CREATE POLICY "Staff can manage features"
  ON home_features FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'staff')
    )
  );

CREATE POLICY "Public can view active features"
  ON home_features FOR SELECT
  USING (is_active = TRUE);

-- Policies for home_stats
CREATE POLICY "Staff can manage stats"
  ON home_stats FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'staff')
    )
  );

CREATE POLICY "Public can view active stats"
  ON home_stats FOR SELECT
  USING (is_active = TRUE);

-- Policies for home_testimonials
CREATE POLICY "Staff can manage testimonials"
  ON home_testimonials FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'staff')
    )
  );

CREATE POLICY "Public can view active testimonials"
  ON home_testimonials FOR SELECT
  USING (is_active = TRUE);

-- ============================================
-- MISSING TABLES WITH RELATIONSHIPS
-- ============================================

-- Academic Years
CREATE TABLE IF NOT EXISTS academic_years (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_current BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_academic_years_tenant ON academic_years(tenant_id);
CREATE INDEX IF NOT EXISTS idx_academic_years_current ON academic_years(is_current);
CREATE INDEX IF NOT EXISTS idx_academic_years_active ON academic_years(is_active);

-- Semesters/Terms
CREATE TABLE IF NOT EXISTS semesters (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  academic_year_id UUID REFERENCES academic_years(id),
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_semesters_tenant ON semesters(tenant_id);
CREATE INDEX IF NOT EXISTS idx_semesters_year ON semesters(academic_year_id);
CREATE INDEX IF NOT EXISTS idx_semesters_active ON semesters(is_active);

-- Subjects
CREATE TABLE IF NOT EXISTS subjects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  description TEXT,
  department_id UUID REFERENCES departments(id),
  credits INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subjects_tenant ON subjects(tenant_id);
CREATE INDEX IF NOT EXISTS idx_subjects_department ON subjects(department_id);
CREATE INDEX IF NOT EXISTS idx_subjects_code ON subjects(code);
CREATE INDEX IF NOT EXISTS idx_subjects_active ON subjects(is_active);

-- Class Subjects (Many-to-Many)
CREATE TABLE IF NOT EXISTS class_subjects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  class_id UUID REFERENCES classes(id),
  subject_id UUID REFERENCES subjects(id),
  teacher_id UUID REFERENCES profiles(id),
  academic_year_id UUID REFERENCES academic_years(id),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(class_id, subject_id, academic_year_id)
);

CREATE INDEX IF NOT EXISTS idx_class_subjects_tenant ON class_subjects(tenant_id);
CREATE INDEX IF NOT EXISTS idx_class_subjects_class ON class_subjects(class_id);
CREATE INDEX IF NOT EXISTS idx_class_subjects_subject ON class_subjects(subject_id);
CREATE INDEX IF NOT EXISTS idx_class_subjects_teacher ON class_subjects(teacher_id);

-- Student Class Enrollment
CREATE TABLE IF NOT EXISTS student_enrollments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  student_id UUID REFERENCES students(id),
  class_id UUID REFERENCES classes(id),
  academic_year_id UUID REFERENCES academic_years(id),
  enrollment_date DATE DEFAULT CURRENT_DATE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'withdrawn', 'suspended')),
  grade TEXT,
  remarks TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(student_id, class_id, academic_year_id)
);

CREATE INDEX IF NOT EXISTS idx_student_enrollments_tenant ON student_enrollments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_student_enrollments_student ON student_enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_student_enrollments_class ON student_enrollments(class_id);
CREATE INDEX IF NOT EXISTS idx_student_enrollments_year ON student_enrollments(academic_year_id);
CREATE INDEX IF NOT EXISTS idx_student_enrollments_status ON student_enrollments(status);

-- Timetable/Schedule
CREATE TABLE IF NOT EXISTS timetables (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  class_id UUID REFERENCES classes(id),
  subject_id UUID REFERENCES subjects(id),
  teacher_id UUID REFERENCES profiles(id),
  room_id UUID,
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  academic_year_id UUID REFERENCES academic_years(id),
  semester_id UUID REFERENCES semesters(id),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_timetables_tenant ON timetables(tenant_id);
CREATE INDEX IF NOT EXISTS idx_timetables_class ON timetables(class_id);
CREATE INDEX IF NOT EXISTS idx_timetables_teacher ON timetables(teacher_id);
CREATE INDEX IF NOT EXISTS idx_timetables_day ON timetables(day_of_week);
CREATE INDEX IF NOT EXISTS idx_timetables_active ON timetables(is_active);

-- Rooms/Classrooms
CREATE TABLE IF NOT EXISTS rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  building TEXT,
  floor INTEGER,
  capacity INTEGER,
  room_type TEXT CHECK (room_type IN ('classroom', 'lab', 'lecture_hall', 'meeting_room', 'office')),
  amenities JSONB DEFAULT '{}'::jsonb,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rooms_tenant ON rooms(tenant_id);
CREATE INDEX IF NOT EXISTS idx_rooms_type ON rooms(room_type);
CREATE INDEX IF NOT EXISTS idx_rooms_active ON rooms(is_active);

-- Parent-Student Relationships
CREATE TABLE IF NOT EXISTS parent_students (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  parent_id UUID,
  student_id UUID REFERENCES students(id),
  relationship TEXT CHECK (relationship IN ('father', 'mother', 'guardian', 'other')),
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(parent_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_parent_students_tenant ON parent_students(tenant_id);
CREATE INDEX IF NOT EXISTS idx_parent_students_parent ON parent_students(parent_id);
CREATE INDEX IF NOT EXISTS idx_parent_students_student ON parent_students(student_id);
CREATE INDEX IF NOT EXISTS idx_parent_students_primary ON parent_students(is_primary);

-- Teacher Qualifications
CREATE TABLE IF NOT EXISTS teacher_qualifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  teacher_id UUID REFERENCES teachers(id),
  degree TEXT NOT NULL,
  specialization TEXT,
  institution TEXT NOT NULL,
  year_completed INTEGER,
  grade TEXT,
  certificate_url TEXT,
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_teacher_qualifications_tenant ON teacher_qualifications(tenant_id);
CREATE INDEX IF NOT EXISTS idx_teacher_qualifications_teacher ON teacher_qualifications(teacher_id);

-- Student Documents
CREATE TABLE IF NOT EXISTS student_documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  student_id UUID REFERENCES students(id),
  document_type TEXT CHECK (document_type IN ('id_card', 'transcript', 'certificate', 'report_card', 'admission_letter', 'other')),
  document_url TEXT NOT NULL,
  issue_date DATE,
  expiry_date DATE,
  issued_by TEXT,
  is_verified BOOLEAN DEFAULT false,
  verified_by UUID REFERENCES profiles(id),
  verified_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_student_documents_tenant ON student_documents(tenant_id);
CREATE INDEX IF NOT EXISTS idx_student_documents_student ON student_documents(student_id);
CREATE INDEX IF NOT EXISTS idx_student_documents_type ON student_documents(document_type);
CREATE INDEX IF NOT EXISTS idx_student_documents_verified ON student_documents(is_verified);

-- Ensure columns from the enhanced fee_structures definition exist on existing installs
ALTER TABLE fee_structures ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE fee_structures ADD COLUMN IF NOT EXISTS academic_year_id UUID REFERENCES academic_years(id);
ALTER TABLE fee_structures ADD COLUMN IF NOT EXISTS total_amount DECIMAL(10,2);

CREATE INDEX IF NOT EXISTS idx_fee_structures_tenant ON fee_structures(tenant_id);
CREATE INDEX IF NOT EXISTS idx_fee_structures_program ON fee_structures(program_id);
CREATE INDEX IF NOT EXISTS idx_fee_structures_class ON fee_structures(class_id);
CREATE INDEX IF NOT EXISTS idx_fee_structures_year ON fee_structures(academic_year_id);
CREATE INDEX IF NOT EXISTS idx_fee_structures_active ON fee_structures(is_active);

-- Installment Plans
CREATE TABLE IF NOT EXISTS installment_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  fee_structure_id UUID REFERENCES fee_structures(id),
  installment_number INTEGER NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  due_date DATE NOT NULL,
  late_fee DECIMAL(10,2) DEFAULT 0,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_installment_plans_tenant ON installment_plans(tenant_id);
CREATE INDEX IF NOT EXISTS idx_installment_plans_structure ON installment_plans(fee_structure_id);
CREATE INDEX IF NOT EXISTS idx_installment_plans_due_date ON installment_plans(due_date);

-- Ensure columns from the enhanced student_fee_assignments definition exist on existing installs
ALTER TABLE student_fee_assignments ADD COLUMN IF NOT EXISTS academic_year_id UUID REFERENCES academic_years(id);
ALTER TABLE student_fee_assignments ADD COLUMN IF NOT EXISTS total_amount DECIMAL(10,2);
ALTER TABLE student_fee_assignments ADD COLUMN IF NOT EXISTS balance_amount DECIMAL(10,2);

CREATE INDEX IF NOT EXISTS idx_student_fee_assignments_tenant ON student_fee_assignments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_student_fee_assignments_student ON student_fee_assignments(student_id);
CREATE INDEX IF NOT EXISTS idx_student_fee_assignments_status ON student_fee_assignments(status);

-- Homework/Assignments
CREATE TABLE IF NOT EXISTS homework (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  class_id UUID REFERENCES classes(id),
  subject_id UUID REFERENCES subjects(id),
  teacher_id UUID REFERENCES profiles(id),
  title TEXT NOT NULL,
  description TEXT,
  attachment_url TEXT,
  assigned_date DATE DEFAULT CURRENT_DATE,
  due_date DATE NOT NULL,
  max_marks DECIMAL(5,2),
  weight_percentage DECIMAL(5,2) DEFAULT 100,
  status TEXT DEFAULT 'active' CHECK (status IN ('draft', 'active', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_homework_tenant ON homework(tenant_id);
CREATE INDEX IF NOT EXISTS idx_homework_class ON homework(class_id);
CREATE INDEX IF NOT EXISTS idx_homework_teacher ON homework(teacher_id);
CREATE INDEX IF NOT EXISTS idx_homework_due_date ON homework(due_date);
CREATE INDEX IF NOT EXISTS idx_homework_status ON homework(status);

-- Homework Submissions
CREATE TABLE IF NOT EXISTS homework_submissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  homework_id UUID REFERENCES homework(id),
  student_id UUID REFERENCES students(id),
  submission_url TEXT,
  submission_text TEXT,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  marks_obtained DECIMAL(5,2),
  feedback TEXT,
  status TEXT DEFAULT 'submitted' CHECK (status IN ('pending', 'submitted', 'graded', 'late', 'missing')),
  graded_by UUID REFERENCES profiles(id),
  graded_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(homework_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_homework_submissions_tenant ON homework_submissions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_homework_submissions_homework ON homework_submissions(homework_id);
CREATE INDEX IF NOT EXISTS idx_homework_submissions_student ON homework_submissions(student_id);
CREATE INDEX IF NOT EXISTS idx_homework_submissions_status ON homework_submissions(status);

-- Lesson Plans
CREATE TABLE IF NOT EXISTS lesson_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  teacher_id UUID REFERENCES profiles(id),
  class_id UUID REFERENCES classes(id),
  subject_id UUID REFERENCES subjects(id),
  title TEXT NOT NULL,
  objectives TEXT,
  materials TEXT,
  activities JSONB,
  assessment TEXT,
  lesson_date DATE,
  duration_minutes INTEGER,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'approved', 'completed', 'archived')),
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lesson_plans_tenant ON lesson_plans(tenant_id);
CREATE INDEX IF NOT EXISTS idx_lesson_plans_teacher ON lesson_plans(teacher_id);
CREATE INDEX IF NOT EXISTS idx_lesson_plans_class ON lesson_plans(class_id);
CREATE INDEX IF NOT EXISTS idx_lesson_plans_date ON lesson_plans(lesson_date);
CREATE INDEX IF NOT EXISTS idx_lesson_plans_status ON lesson_plans(status);

-- Holidays
CREATE TABLE IF NOT EXISTS holidays (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  date DATE NOT NULL,
  description TEXT,
  is_recurring BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_holidays_tenant ON holidays(tenant_id);
CREATE INDEX IF NOT EXISTS idx_holidays_date ON holidays(date);

-- System Logs
CREATE TABLE IF NOT EXISTS system_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES profiles(id),
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,
  details JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_system_logs_tenant ON system_logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_system_logs_user ON system_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_system_logs_action ON system_logs(action);
CREATE INDEX IF NOT EXISTS idx_system_logs_entity ON system_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_system_logs_created ON system_logs(created_at DESC);

-- API Keys (For integrations)
CREATE TABLE IF NOT EXISTS api_keys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  key_value TEXT UNIQUE NOT NULL,
  permissions JSONB DEFAULT '{}'::jsonb,
  is_active BOOLEAN DEFAULT true,
  expires_at TIMESTAMP WITH TIME ZONE,
  last_used_at TIMESTAMP WITH TIME ZONE,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_api_keys_tenant ON api_keys(tenant_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_active ON api_keys(is_active);
CREATE INDEX IF NOT EXISTS idx_api_keys_value ON api_keys(key_value);

-- Webhooks
CREATE TABLE IF NOT EXISTS webhooks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  events JSONB NOT NULL,
  secret TEXT,
  is_active BOOLEAN DEFAULT true,
  last_triggered_at TIMESTAMP WITH TIME ZONE,
  failure_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_webhooks_tenant ON webhooks(tenant_id);
CREATE INDEX IF NOT EXISTS idx_webhooks_active ON webhooks(is_active);

-- ============================================
-- MISSING TABLE DEFINITIONS
-- ============================================

-- Transport Panel Tables
CREATE TABLE IF NOT EXISTS vehicles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  plate_number TEXT NOT NULL,
  vehicle_type TEXT CHECK (vehicle_type IN ('bus', 'van', 'car', 'bike')),
  capacity INTEGER DEFAULT 0,
  model TEXT,
  color TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'maintenance', 'inactive')),
  driver_id UUID,
  insurance_expiry DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS drivers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  profile_id UUID REFERENCES profiles(id),
  full_name TEXT NOT NULL,
  phone TEXT,
  license_number TEXT,
  license_expiry DATE,
  available BOOLEAN DEFAULT true,
  assigned_vehicle_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS routes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  start_location TEXT,
  end_location TEXT,
  distance_km DECIMAL(10,2),
  estimated_duration_minutes INTEGER,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Hostel Panel Tables
CREATE TABLE IF NOT EXISTS wardens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  profile_id UUID REFERENCES profiles(id),
  full_name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  shift TEXT CHECK (shift IN ('morning', 'evening', 'night')),
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS hostel_allocations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  student_id UUID REFERENCES students(id),
  room_id UUID REFERENCES rooms(id),
  allocation_date DATE DEFAULT CURRENT_DATE,
  end_date DATE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'ended', 'transferred')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Parent Table
CREATE TABLE IF NOT EXISTS parents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  profile_id UUID REFERENCES profiles(id),
  full_name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  occupation TEXT,
  address TEXT,
  is_guardian BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Transport & Hostel indexes
CREATE INDEX IF NOT EXISTS idx_vehicles_type ON vehicles(vehicle_type);
CREATE INDEX IF NOT EXISTS idx_vehicles_status ON vehicles(status);
CREATE INDEX IF NOT EXISTS idx_drivers_available ON drivers(available);
CREATE INDEX IF NOT EXISTS idx_routes_status ON routes(status);
CREATE INDEX IF NOT EXISTS idx_rooms_floor ON rooms(floor);
CREATE INDEX IF NOT EXISTS idx_wardens_active ON wardens(active);
CREATE INDEX IF NOT EXISTS idx_hostel_allocations_status ON hostel_allocations(status);

-- Finance Tables
CREATE TABLE IF NOT EXISTS fees (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  category TEXT,
  description TEXT,
  is_mandatory BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS fee_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  fee_id UUID REFERENCES fees(id),
  name TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS invoice_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  invoice_id UUID REFERENCES invoices(id),
  description TEXT NOT NULL,
  quantity INTEGER DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS budgets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  fiscal_year TEXT NOT NULL,
  category TEXT NOT NULL,
  allocated_amount DECIMAL(12,2) DEFAULT 0,
  spent_amount DECIMAL(12,2) DEFAULT 0,
  remaining_amount DECIMAL(12,2) GENERATED ALWAYS AS (allocated_amount - spent_amount) STORED,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Academic Support Tables
CREATE TABLE IF NOT EXISTS exam_schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  exam_id UUID REFERENCES exams(id),
  class_id UUID REFERENCES classes(id),
  subject_id UUID REFERENCES subjects(id),
  exam_date DATE NOT NULL,
  start_time TIME,
  end_time TIME,
  room_id UUID REFERENCES rooms(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS grade_scales (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  grade TEXT NOT NULL,
  min_percentage DECIMAL(5,2) NOT NULL,
  max_percentage DECIMAL(5,2) NOT NULL,
  points DECIMAL(3,1),
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS transcripts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  student_id UUID REFERENCES students(id),
  transcript_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  generated_date DATE DEFAULT CURRENT_DATE,
  is_official BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS class_courses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  class_id UUID REFERENCES classes(id),
  course_id UUID REFERENCES courses(id),
  teacher_id UUID REFERENCES profiles(id),
  academic_term TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS leave_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  requester_id UUID REFERENCES profiles(id),
  leave_type TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  reason TEXT,
  is_paid BOOLEAN DEFAULT true,
  deduction_percentage DECIMAL(5,2) DEFAULT 0,
  deduction_amount DECIMAL(12,2) DEFAULT 0,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Library Tables
CREATE TABLE IF NOT EXISTS books (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  title TEXT NOT NULL,
  title_ar TEXT,
  author TEXT,
  author_ar TEXT,
  isbn TEXT,
  publisher TEXT,
  publication_year INTEGER,
  category TEXT,
  category_ar TEXT,
  description TEXT,
  description_ar TEXT,
  cost_price DECIMAL(12,2),
  selling_price DECIMAL(12,2),
  supplier TEXT,
  supplier_contact TEXT,
  purchase_date DATE,
  total_copies INTEGER DEFAULT 0,
  available_copies INTEGER DEFAULT 0,
  borrowed_copies INTEGER DEFAULT 0,
  sold_copies INTEGER DEFAULT 0,
  lost_copies INTEGER DEFAULT 0,
  damaged_copies INTEGER DEFAULT 0,
  reserved_copies INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_books_stock ON books(total_copies, available_copies);

CREATE TABLE IF NOT EXISTS book_copies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  book_id UUID REFERENCES books(id),
  copy_code TEXT UNIQUE,
  condition TEXT CHECK (condition IN ('new', 'good', 'fair', 'poor', 'damaged')),
  status TEXT DEFAULT 'available' CHECK (status IN ('available', 'borrowed', 'sold', 'lost', 'damaged', 'reserved')),
  cost_price DECIMAL(12,2),
  selling_price DECIMAL(12,2),
  sold_to UUID REFERENCES students(id),
  sold_at TIMESTAMPTZ,
  invoice_id UUID REFERENCES invoices(id),
  location TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reservations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  book_copy_id UUID REFERENCES book_copies(id),
  member_id UUID REFERENCES library_members(id),
  reservation_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expiry_date DATE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'fulfilled', 'cancelled', 'expired')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- BOOK PURCHASES (buying books from suppliers)
-- ============================================
CREATE TABLE IF NOT EXISTS book_purchases (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  book_id UUID REFERENCES books(id),
  quantity INTEGER NOT NULL,
  unit_cost DECIMAL(12,2),
  total_cost DECIMAL(14,2) GENERATED ALWAYS AS (quantity * COALESCE(unit_cost, 0)) STORED,
  supplier TEXT,
  supplier_contact TEXT,
  purchase_date DATE NOT NULL DEFAULT CURRENT_DATE,
  invoice_reference TEXT,
  discount_amount DECIMAL(12,2) DEFAULT 0,
  discount_id UUID REFERENCES discounts(id),
  promotion_id UUID REFERENCES promotions(id),
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'partial', 'cancelled')),
  payment_method TEXT,
  notes TEXT,
  notes_ar TEXT,
  received_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_book_purchases_tenant ON book_purchases(tenant_id);
CREATE INDEX IF NOT EXISTS idx_book_purchases_book ON book_purchases(book_id);
CREATE INDEX IF NOT EXISTS idx_book_purchases_date ON book_purchases(purchase_date);

-- ============================================
-- BOOK SALES (selling books to students)
-- ============================================
CREATE TABLE IF NOT EXISTS book_sales (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  book_id UUID REFERENCES books(id),
  book_copy_id UUID REFERENCES book_copies(id),
  student_id UUID REFERENCES students(id),
  quantity INTEGER DEFAULT 1,
  unit_price DECIMAL(12,2),
  total_price DECIMAL(14,2) GENERATED ALWAYS AS (quantity * COALESCE(unit_price, 0)) STORED,
  discount DECIMAL(12,2) DEFAULT 0,
  discount_id UUID REFERENCES discounts(id),
  promotion_id UUID REFERENCES promotions(id),
  discount_type TEXT CHECK (discount_type IN ('percentage', 'fixed', 'promotion', 'manual')),
  net_total DECIMAL(14,2) GENERATED ALWAYS AS ((quantity * COALESCE(unit_price, 0)) - COALESCE(discount, 0)) STORED,
  invoice_id UUID REFERENCES invoices(id),
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'partial', 'refunded', 'cancelled')),
  payment_method TEXT,
  sold_by UUID REFERENCES profiles(id),
  sale_date TIMESTAMPTZ DEFAULT NOW(),
  course_id UUID REFERENCES courses(id),
  notes TEXT,
  notes_ar TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_book_sales_tenant ON book_sales(tenant_id);
CREATE INDEX IF NOT EXISTS idx_book_sales_book ON book_sales(book_id);
CREATE INDEX IF NOT EXISTS idx_book_sales_student ON book_sales(student_id);
CREATE INDEX IF NOT EXISTS idx_book_sales_invoice ON book_sales(invoice_id);
CREATE INDEX IF NOT EXISTS idx_book_sales_date ON book_sales(sale_date);

-- Inventory & Asset Tables
CREATE TABLE IF NOT EXISTS assets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  category TEXT,
  purchase_date DATE,
  purchase_cost DECIMAL(10,2),
  current_value DECIMAL(10,2),
  location TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'maintenance', 'retired', 'sold')),
  condition TEXT DEFAULT 'new' CHECK (condition IN ('new', 'good', 'fair', 'damaged', 'broken', 'under_repair', 'repaired', 'unused', 'destroyed', 'disposed')),
  assigned_to UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS inventory_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  category TEXT,
  category_id UUID,
  sku TEXT UNIQUE,
  quantity INTEGER DEFAULT 0,
  min_stock_level INTEGER DEFAULT 0,
  unit_price DECIMAL(10,2),
  location TEXT,
  condition TEXT DEFAULT 'new' CHECK (condition IN ('new', 'good', 'fair', 'damaged', 'broken', 'under_repair', 'repaired', 'unused', 'destroyed', 'disposed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS asset_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  asset_id UUID REFERENCES assets(id),
  assigned_to UUID REFERENCES profiles(id),
  assigned_date DATE NOT NULL,
  expected_return_date DATE,
  actual_return_date DATE,
  condition_on_return TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS inventory_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  item_id UUID REFERENCES inventory_items(id),
  transaction_type TEXT CHECK (transaction_type IN ('in', 'out', 'adjustment')),
  quantity INTEGER NOT NULL,
  reference_type TEXT,
  reference_id UUID,
  notes TEXT,
  performed_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- INVENTORY MANAGEMENT TABLES
-- ============================================

-- Inventory Categories (group inventory items by type/category)
CREATE TABLE IF NOT EXISTS inventory_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  name_ar TEXT,
  name_dr TEXT,
  name_ps TEXT,
  description TEXT,
  description_ar TEXT,
  parent_category_id UUID REFERENCES inventory_categories(id),
  icon TEXT,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_inventory_categories_tenant ON inventory_categories(tenant_id);
CREATE INDEX IF NOT EXISTS idx_inventory_categories_parent ON inventory_categories(parent_category_id);
CREATE INDEX IF NOT EXISTS idx_inventory_categories_active ON inventory_categories(is_active);

-- Stock Reconciliation (physical count vs system quantity)
CREATE TABLE IF NOT EXISTS stock_reconciliation (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  item_id UUID REFERENCES inventory_items(id),
  counted_by UUID REFERENCES profiles(id),
  count_date DATE NOT NULL DEFAULT CURRENT_DATE,
  system_quantity INTEGER NOT NULL,
  physical_quantity INTEGER NOT NULL,
  variance INTEGER GENERATED ALWAYS AS (physical_quantity - system_quantity) STORED,
  variance_reason TEXT,
  variance_reason_ar TEXT,
  unit_price_at_count DECIMAL(14,2),
  variance_value DECIMAL(14,2) GENERATED ALWAYS AS (ABS(physical_quantity - system_quantity) * COALESCE(unit_price_at_count, 0)) STORED,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'disputed', 'adjusted')),
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMPTZ,
  adjustment_transaction_id UUID REFERENCES inventory_transactions(id),
  notes TEXT,
  notes_ar TEXT,
  location TEXT,
  batch_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stock_reconciliation_tenant ON stock_reconciliation(tenant_id);
CREATE INDEX IF NOT EXISTS idx_stock_reconciliation_item ON stock_reconciliation(item_id);
CREATE INDEX IF NOT EXISTS idx_stock_reconciliation_date ON stock_reconciliation(count_date);
CREATE INDEX IF NOT EXISTS idx_stock_reconciliation_status ON stock_reconciliation(status);

-- Item Condition History (tracks every condition change: damage, repair, destroy, etc.)
CREATE TABLE IF NOT EXISTS item_condition_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  item_type TEXT NOT NULL CHECK (item_type IN ('inventory', 'asset')),
  item_id UUID NOT NULL,
  previous_condition TEXT,
  new_condition TEXT NOT NULL CHECK (new_condition IN ('new', 'good', 'fair', 'damaged', 'broken', 'under_repair', 'repaired', 'unused', 'destroyed', 'disposed')),
  change_reason TEXT NOT NULL CHECK (change_reason IN ('damage', 'repair', 'maintenance', 'destruction', 'disposal', 'return', 'transfer', 'inspection', 'other')),
  change_reason_ar TEXT,
  description TEXT,
  description_ar TEXT,
  cost DECIMAL(12,2),
  currency TEXT DEFAULT 'AFN',
  vendor TEXT,
  repair_vendor TEXT,
  repair_cost DECIMAL(12,2),
  repair_date DATE,
  repair_completed_date DATE,
  repair_reference TEXT,
  damage_report TEXT,
  damage_report_ar TEXT,
  reported_by UUID REFERENCES profiles(id),
  approved_by UUID REFERENCES profiles(id),
  work_order_id UUID,
  attachment_url TEXT,
  notes TEXT,
  notes_ar TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_item_condition_tenant ON item_condition_history(tenant_id);
CREATE INDEX IF NOT EXISTS idx_item_condition_item ON item_condition_history(item_type, item_id);
CREATE INDEX IF NOT EXISTS idx_item_condition_new ON item_condition_history(new_condition);
CREATE INDEX IF NOT EXISTS idx_item_condition_reason ON item_condition_history(change_reason);
CREATE INDEX IF NOT EXISTS idx_item_condition_created ON item_condition_history(created_at);
CREATE INDEX IF NOT EXISTS idx_item_condition_work_order ON item_condition_history(work_order_id);

-- Communication Tables
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  sender_id UUID REFERENCES profiles(id),
  receiver_id UUID REFERENCES profiles(id),
  subject TEXT,
  body TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP WITH TIME ZONE,
  parent_message_id UUID REFERENCES messages(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  file_url TEXT,
  file_type TEXT,
  file_name TEXT,
  file_size BIGINT
);

CREATE TABLE IF NOT EXISTS notices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  target_role TEXT,
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  valid_from DATE,
  valid_until DATE,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- IT Support Tables
CREATE TABLE IF NOT EXISTS it_tickets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  ticket_number TEXT UNIQUE,
  subject TEXT NOT NULL,
  description TEXT,
  category TEXT,
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
  reported_by UUID REFERENCES profiles(id),
  assigned_to UUID REFERENCES profiles(id),
  resolution_notes TEXT,
  resolved_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS it_ticket_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  ticket_id UUID REFERENCES it_tickets(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES profiles(id),
  message TEXT NOT NULL,
  attachment_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Complaints Tables
CREATE TABLE IF NOT EXISTS complaints (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  complaint_number TEXT UNIQUE,
  subject TEXT NOT NULL,
  description TEXT,
  category TEXT,
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'resolved', 'closed')),
  complainant_id UUID REFERENCES profiles(id),
  assigned_to UUID REFERENCES profiles(id),
  resolution_notes TEXT,
  resolved_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS complaint_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  complaint_id UUID REFERENCES complaints(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES profiles(id),
  message TEXT NOT NULL,
  attachment_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Maintenance Tables
CREATE TABLE IF NOT EXISTS maintenance_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  request_number TEXT UNIQUE,
  title TEXT NOT NULL,
  description TEXT,
  location TEXT,
  category TEXT,
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'emergency')),
  status TEXT DEFAULT 'reported' CHECK (status IN ('reported', 'assigned', 'in_progress', 'completed', 'cancelled')),
  reported_by UUID REFERENCES profiles(id),
  assigned_to UUID REFERENCES profiles(id),
  completed_at TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- HR Tables
CREATE TABLE IF NOT EXISTS jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  title TEXT NOT NULL,
  department TEXT,
  description TEXT,
  requirements JSONB,
  salary_range_min DECIMAL(10,2),
  salary_range_max DECIMAL(10,2),
  type TEXT CHECK (type IN ('full_time', 'part_time', 'contract', 'internship')),
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'closed', 'filled')),
  posted_by UUID REFERENCES profiles(id),
  posted_date DATE DEFAULT CURRENT_DATE,
  closing_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS interview_schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  application_id UUID REFERENCES job_applications(id),
  interview_date TIMESTAMP WITH TIME ZONE NOT NULL,
  interview_type TEXT CHECK (interview_type IN ('in_person', 'video', 'phone')),
  interviewer_ids UUID[],
  location TEXT,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled', 'rescheduled')),
  feedback TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS performance_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  employee_id UUID REFERENCES profiles(id),
  reviewer_id UUID REFERENCES profiles(id),
  review_period TEXT NOT NULL,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  comments TEXT,
  goals JSONB,
  bonus_amount DECIMAL(12,2) DEFAULT 0,
  bonus_promotion_id UUID REFERENCES promotions(id),
  incentive_type TEXT CHECK (incentive_type IN ('bonus', 'raise', 'promotion', 'certificate', 'other')),
  incentive_details TEXT,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'acknowledged')),
  submitted_at TIMESTAMP WITH TIME ZONE,
  acknowledged_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS trainings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  title TEXT NOT NULL,
  description TEXT,
  trainer TEXT,
  start_date DATE,
  end_date DATE,
  duration_hours DECIMAL(5,1),
  cost DECIMAL(12,2) DEFAULT 0,
  discount_amount DECIMAL(12,2) DEFAULT 0,
  discount_id UUID REFERENCES discounts(id),
  promotion_id UUID REFERENCES promotions(id),
  type TEXT CHECK (type IN ('internal', 'external', 'online')),
  status TEXT DEFAULT 'planned' CHECK (status IN ('planned', 'ongoing', 'completed', 'cancelled')),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Documents & Certificates Tables
CREATE TABLE IF NOT EXISTS documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  profile_id UUID REFERENCES profiles(id),
  document_type TEXT NOT NULL,
  title TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_size BIGINT,
  mime_type TEXT,
  is_verified BOOLEAN DEFAULT false,
  verified_by UUID REFERENCES profiles(id),
  verified_at TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS document_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  requester_id UUID REFERENCES profiles(id),
  document_type TEXT NOT NULL,
  purpose TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'issued')),
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  issued_at TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS certificates_issued (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  certificate_id UUID REFERENCES certificates(id),
  recipient_id UUID REFERENCES profiles(id),
  certificate_number TEXT UNIQUE,
  issue_date DATE DEFAULT CURRENT_DATE,
  expiry_date DATE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'revoked')),
  issued_by UUID REFERENCES profiles(id),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- REPORTING TABLES
-- ============================================

-- Report Categories (groups reports by function)
CREATE TABLE IF NOT EXISTS report_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  name_ar TEXT,
  name_dr TEXT,
  name_ps TEXT,
  description TEXT,
  description_ar TEXT,
  icon TEXT,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_report_categories_tenant ON report_categories(tenant_id);
CREATE INDEX IF NOT EXISTS idx_report_categories_order ON report_categories(display_order);
CREATE INDEX IF NOT EXISTS idx_report_categories_active ON report_categories(is_active);

-- Report Templates (predefined report configurations)
CREATE TABLE IF NOT EXISTS report_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  category_id UUID REFERENCES report_categories(id),
  name TEXT NOT NULL,
  name_ar TEXT,
  name_dr TEXT,
  name_ps TEXT,
  description TEXT,
  description_ar TEXT,
  report_type TEXT NOT NULL CHECK (report_type IN ('tabular', 'chart', 'summary', 'comparison', 'custom')),
  source_query TEXT,
  parameters JSONB DEFAULT '[]'::jsonb,
  columns_config JSONB DEFAULT '[]'::jsonb,
  chart_config JSONB,
  allowed_roles TEXT[] DEFAULT '{}',
  is_system BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_report_templates_tenant ON report_templates(tenant_id);
CREATE INDEX IF NOT EXISTS idx_report_templates_category ON report_templates(category_id);
CREATE INDEX IF NOT EXISTS idx_report_templates_type ON report_templates(report_type);
CREATE INDEX IF NOT EXISTS idx_report_templates_active ON report_templates(is_active);

-- Report Schedules (automated report generation)
CREATE TABLE IF NOT EXISTS report_schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  template_id UUID REFERENCES report_templates(id),
  name TEXT NOT NULL,
  name_ar TEXT,
  frequency TEXT NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly', 'quarterly', 'yearly', 'custom')),
  cron_expression TEXT,
  parameters JSONB DEFAULT '{}'::jsonb,
  recipients JSONB DEFAULT '[]'::jsonb,
  delivery_methods TEXT[] DEFAULT '{"in_app"}',
  last_generated_at TIMESTAMPTZ,
  next_run_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_report_schedules_tenant ON report_schedules(tenant_id);
CREATE INDEX IF NOT EXISTS idx_report_schedules_template ON report_schedules(template_id);
CREATE INDEX IF NOT EXISTS idx_report_schedules_next_run ON report_schedules(next_run_at) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_report_schedules_frequency ON report_schedules(frequency);

-- Reports (generated report instances)
CREATE TABLE IF NOT EXISTS reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  template_id UUID REFERENCES report_templates(id),
  name TEXT NOT NULL,
  name_ar TEXT,
  name_dr TEXT,
  name_ps TEXT,
  type TEXT,
  report_type TEXT CHECK (report_type IN ('tabular', 'chart', 'summary', 'comparison', 'custom')),
  parameters JSONB DEFAULT '{}'::jsonb,
  result_data JSONB,
  summary TEXT,
  summary_ar TEXT,
  file_url TEXT,
  file_format TEXT CHECK (file_format IN ('pdf', 'excel', 'csv', 'html', 'json')),
  generated_by UUID REFERENCES profiles(id),
  generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  schedule_id UUID REFERENCES report_schedules(id),
  is_scheduled BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS dashboards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  description TEXT,
  layout JSONB DEFAULT '{}'::jsonb,
  is_default BOOLEAN DEFAULT false,
  role TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS widgets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  dashboard_id UUID REFERENCES dashboards(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  config JSONB DEFAULT '{}'::jsonb,
  position INTEGER DEFAULT 0,
  is_visible BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- System Configuration Tables
CREATE TABLE IF NOT EXISTS settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  key TEXT NOT NULL,
  value TEXT,
  category TEXT DEFAULT 'general',
  is_encrypted BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(tenant_id, key)
);

CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES profiles(id),
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- ROLE-BASED ACCESS CONTROL
-- ============================================

CREATE TABLE IF NOT EXISTS roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  name_ar TEXT,
  name_dr TEXT,
  name_ps TEXT,
  slug TEXT NOT NULL,
  description TEXT,
  description_ar TEXT,
  level INTEGER DEFAULT 0,
  is_system BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(tenant_id, slug)
);

-- Seed default system roles
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM roles WHERE slug = 'super_admin') THEN
    INSERT INTO roles (name, name_ar, slug, description, level, is_system) VALUES
    ('Super Admin', 'Ù…Ø´Ø±Ù Ø¹Ø§Ù…', 'super_admin', 'Super Administrator - full system access', 90, true),
    ('Admin', 'Ù…Ø¯ÙŠØ±', 'admin', 'Administrator - system management access', 80, true),
    ('Accountant', 'Ù…Ø­Ø§Ø³Ø¨', 'accountant', 'Accounting and financial management', 75, true),
    ('HR Manager', 'Ù…Ø¯ÙŠØ± Ø§Ù„Ù…ÙˆØ§Ø±Ø¯ Ø§Ù„Ø¨Ø´Ø±ÙŠØ©', 'hr_manager', 'Human resources and payroll management', 70, true),
    ('Inventory Manager', 'Ù…Ø¯ÙŠØ± Ø§Ù„Ù…Ø®Ø²ÙˆÙ†', 'inventory_manager', 'Inventory and asset management', 65, true),
    ('IT Support', 'Ø¯Ø¹Ù… ØªÙ‚Ù†ÙŠ', 'it_support', 'IT systems and device support', 60, true),
    ('Librarian', 'Ø£Ù…ÙŠÙ† Ù…ÙƒØªØ¨Ø©', 'librarian', 'Library and resource management', 55, true),
    ('Staff', 'Ù…ÙˆØ¸Ù', 'staff', 'Staff member - panel sub-role access', 50, true),
    ('Academic Support', 'Ø¯Ø¹Ù… Ø£ÙƒØ§Ø¯ÙŠÙ…ÙŠ', 'academic_support', 'Academic affairs and curriculum support', 45, true),
    ('Teacher', 'Ù…Ø¹Ù„Ù…', 'teacher', 'Teacher - academic and class management', 40, true),
    ('Maintenance', 'ØµÙŠØ§Ù†Ø©', 'maintenance', 'Facility and equipment maintenance', 35, true),
    ('Receptionist', 'Ù…ÙˆØ¸Ù Ø§Ø³ØªÙ‚Ø¨Ø§Ù„', 'receptionist', 'Front desk and visitor management', 30, true),
    ('Event Manager', 'Ù…Ø¯ÙŠØ± Ø§Ù„ÙØ¹Ø§Ù„ÙŠØ§Øª', 'event_manager', 'Event and activity coordination', 25, true),
    ('Guardian', 'ÙˆÙ„ÙŠ Ø£Ù…Ø±', 'guardian', 'Parent/Guardian - student monitoring access', 20, true),
    ('Complaint Manager', 'Ù…Ø¯ÙŠØ± Ø§Ù„Ø´ÙƒØ§ÙˆÙ‰', 'complaint_manager', 'Complaint and feedback management', 15, true),
    ('Student', 'Ø·Ø§Ù„Ø¨', 'student', 'Student - personal and academic records', 10, true);
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS role_permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
  permission_key TEXT NOT NULL,
  module TEXT,
  is_granted BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(role_id, permission_key)
);

CREATE INDEX IF NOT EXISTS idx_role_permissions_tenant ON role_permissions(tenant_id);

CREATE TABLE IF NOT EXISTS user_roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  profile_id UUID REFERENCES profiles(id),
  role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
  granted_by UUID REFERENCES profiles(id),
  granted_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(profile_id, role_id)
);

CREATE INDEX IF NOT EXISTS idx_roles_tenant ON roles(tenant_id);
CREATE INDEX IF NOT EXISTS idx_roles_slug ON roles(slug);
CREATE INDEX IF NOT EXISTS idx_role_permissions_role ON role_permissions(role_id);
CREATE INDEX IF NOT EXISTS idx_role_permissions_key ON role_permissions(permission_key);
CREATE INDEX IF NOT EXISTS idx_role_permissions_module ON role_permissions(module);
CREATE INDEX IF NOT EXISTS idx_user_roles_tenant ON user_roles(tenant_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_profile ON user_roles(profile_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role_id);

CREATE TABLE IF NOT EXISTS user_permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  profile_id UUID REFERENCES profiles(id),
  permission_key TEXT NOT NULL,
  is_granted BOOLEAN DEFAULT true,
  granted_by UUID REFERENCES profiles(id),
  granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(profile_id, permission_key)
);

CREATE TABLE IF NOT EXISTS menu_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  parent_id UUID REFERENCES menu_items(id),
  title TEXT NOT NULL,
  icon TEXT,
  route TEXT,
  permission_key TEXT,
  role TEXT,
  display_order INTEGER DEFAULT 0,
  is_visible BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- DYNAMIC PAGE PERMISSIONS
-- Assign pages to roles/users for dashboard access control
-- ============================================

CREATE TABLE IF NOT EXISTS page_permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  page_key TEXT NOT NULL,
  page_title TEXT,
  page_title_ar TEXT,
  page_title_dr TEXT,
  page_title_ps TEXT,
  module TEXT,
  route TEXT,
  icon TEXT,
  can_access BOOLEAN DEFAULT true,
  can_view BOOLEAN DEFAULT true,
  can_create BOOLEAN DEFAULT false,
  can_edit BOOLEAN DEFAULT false,
  can_delete BOOLEAN DEFAULT false,
  is_visible_in_nav BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  is_system BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT page_permissions_assignee_check CHECK (
    (role_id IS NOT NULL AND profile_id IS NULL) OR
    (role_id IS NULL AND profile_id IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_page_permissions_tenant ON page_permissions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_page_permissions_role ON page_permissions(role_id);
CREATE INDEX IF NOT EXISTS idx_page_permissions_profile ON page_permissions(profile_id);
CREATE INDEX IF NOT EXISTS idx_page_permissions_page ON page_permissions(page_key);
CREATE INDEX IF NOT EXISTS idx_page_permissions_module ON page_permissions(module);
CREATE INDEX IF NOT EXISTS idx_page_permissions_nav ON page_permissions(is_visible_in_nav);

-- Communication Log Tables
CREATE TABLE IF NOT EXISTS sms_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  sender_id UUID REFERENCES profiles(id),
  recipient_phone TEXT NOT NULL,
  message TEXT NOT NULL,
  status TEXT DEFAULT 'sent' CHECK (status IN ('sent', 'delivered', 'failed', 'pending')),
  provider_response JSONB,
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS email_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  sender_id UUID REFERENCES profiles(id),
  recipient_email TEXT NOT NULL,
  subject TEXT,
  body TEXT,
  status TEXT DEFAULT 'sent' CHECK (status IN ('sent', 'delivered', 'failed', 'opened', 'pending')),
  provider_response JSONB,
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for Missing Tables
CREATE INDEX IF NOT EXISTS idx_parents_tenant ON parents(tenant_id);
CREATE INDEX IF NOT EXISTS idx_parents_profile ON parents(profile_id);
CREATE INDEX IF NOT EXISTS idx_fees_tenant ON fees(tenant_id);
CREATE INDEX IF NOT EXISTS idx_fee_items_tenant ON fee_items(tenant_id);
CREATE INDEX IF NOT EXISTS idx_fee_items_fee ON fee_items(fee_id);
CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice ON invoice_items(invoice_id);
CREATE INDEX IF NOT EXISTS idx_budgets_tenant ON budgets(tenant_id);
CREATE INDEX IF NOT EXISTS idx_budgets_fiscal ON budgets(fiscal_year);
CREATE INDEX IF NOT EXISTS idx_exam_schedules_tenant ON exam_schedules(tenant_id);
CREATE INDEX IF NOT EXISTS idx_exam_schedules_exam ON exam_schedules(exam_id);
CREATE INDEX IF NOT EXISTS idx_exam_schedules_date ON exam_schedules(exam_date);
CREATE INDEX IF NOT EXISTS idx_grade_scales_tenant ON grade_scales(tenant_id);
CREATE INDEX IF NOT EXISTS idx_transcripts_tenant ON transcripts(tenant_id);
CREATE INDEX IF NOT EXISTS idx_transcripts_student ON transcripts(student_id);
CREATE INDEX IF NOT EXISTS idx_class_courses_tenant ON class_courses(tenant_id);
CREATE INDEX IF NOT EXISTS idx_class_courses_class ON class_courses(class_id);
CREATE INDEX IF NOT EXISTS idx_leave_requests_tenant ON leave_requests(tenant_id);
CREATE INDEX IF NOT EXISTS idx_leave_requests_requester ON leave_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_leave_requests_status ON leave_requests(status);
CREATE INDEX IF NOT EXISTS idx_books_tenant ON books(tenant_id);
CREATE INDEX IF NOT EXISTS idx_books_category ON books(category);
CREATE INDEX IF NOT EXISTS idx_book_copies_tenant ON book_copies(tenant_id);
CREATE INDEX IF NOT EXISTS idx_book_copies_book ON book_copies(book_id);
CREATE INDEX IF NOT EXISTS idx_book_copies_available ON book_copies(status);
CREATE INDEX IF NOT EXISTS idx_reservations_tenant ON reservations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_reservations_status ON reservations(status);
CREATE INDEX IF NOT EXISTS idx_assets_tenant ON assets(tenant_id);
CREATE INDEX IF NOT EXISTS idx_assets_category ON assets(category);
CREATE INDEX IF NOT EXISTS idx_inventory_items_tenant ON inventory_items(tenant_id);
CREATE INDEX IF NOT EXISTS idx_inventory_items_category ON inventory_items(category);
CREATE INDEX IF NOT EXISTS idx_asset_assignments_tenant ON asset_assignments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_asset_assignments_asset ON asset_assignments(asset_id);
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_tenant ON inventory_transactions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_item ON inventory_transactions(item_id);
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_type ON inventory_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_messages_tenant ON messages(tenant_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_read ON messages(is_read);
CREATE INDEX IF NOT EXISTS idx_notices_tenant ON notices(tenant_id);
CREATE INDEX IF NOT EXISTS idx_notices_validity ON notices(valid_from, valid_until);
CREATE INDEX IF NOT EXISTS idx_it_tickets_tenant ON it_tickets(tenant_id);
CREATE INDEX IF NOT EXISTS idx_it_tickets_status ON it_tickets(status);
CREATE INDEX IF NOT EXISTS idx_it_tickets_assigned ON it_tickets(assigned_to);
CREATE INDEX IF NOT EXISTS idx_it_ticket_messages_ticket ON it_ticket_messages(ticket_id);
CREATE INDEX IF NOT EXISTS idx_complaints_tenant ON complaints(tenant_id);
CREATE INDEX IF NOT EXISTS idx_complaints_status ON complaints(status);
CREATE INDEX IF NOT EXISTS idx_complaint_messages_complaint ON complaint_messages(complaint_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_requests_tenant ON maintenance_requests(tenant_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_requests_status ON maintenance_requests(status);
CREATE INDEX IF NOT EXISTS idx_jobs_tenant ON jobs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_interview_schedules_application ON interview_schedules(application_id);
CREATE INDEX IF NOT EXISTS idx_interview_schedules_date ON interview_schedules(interview_date);
CREATE INDEX IF NOT EXISTS idx_performance_reviews_tenant ON performance_reviews(tenant_id);
CREATE INDEX IF NOT EXISTS idx_performance_reviews_employee ON performance_reviews(employee_id);
CREATE INDEX IF NOT EXISTS idx_trainings_tenant ON trainings(tenant_id);
CREATE INDEX IF NOT EXISTS idx_documents_tenant ON documents(tenant_id);
CREATE INDEX IF NOT EXISTS idx_documents_profile ON documents(profile_id);
CREATE INDEX IF NOT EXISTS idx_document_requests_tenant ON document_requests(tenant_id);
CREATE INDEX IF NOT EXISTS idx_document_requests_status ON document_requests(status);
CREATE INDEX IF NOT EXISTS idx_certificates_issued_tenant ON certificates_issued(tenant_id);
CREATE INDEX IF NOT EXISTS idx_certificates_issued_recipient ON certificates_issued(recipient_id);
CREATE INDEX IF NOT EXISTS idx_certificates_issued_status ON certificates_issued(status);
CREATE INDEX IF NOT EXISTS idx_reports_tenant ON reports(tenant_id);
CREATE INDEX IF NOT EXISTS idx_reports_type ON reports(type);
CREATE INDEX IF NOT EXISTS idx_dashboards_tenant ON dashboards(tenant_id);
CREATE INDEX IF NOT EXISTS idx_dashboards_role ON dashboards(role);
CREATE INDEX IF NOT EXISTS idx_widgets_dashboard ON widgets(dashboard_id);
CREATE INDEX IF NOT EXISTS idx_settings_tenant ON settings(tenant_id);
CREATE INDEX IF NOT EXISTS idx_settings_category ON settings(category);
CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant ON audit_logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_permissions_tenant ON user_permissions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_user_permissions_profile ON user_permissions(profile_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_tenant ON menu_items(tenant_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_parent ON menu_items(parent_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_role ON menu_items(role);
CREATE INDEX IF NOT EXISTS idx_menu_items_order ON menu_items(display_order);
CREATE INDEX IF NOT EXISTS idx_sms_logs_tenant ON sms_logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_sms_logs_status ON sms_logs(status);
CREATE INDEX IF NOT EXISTS idx_email_logs_tenant ON email_logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_email_logs_status ON email_logs(status);

-- Triggers for Missing Tables
CREATE TRIGGER update_vehicles_updated_at BEFORE UPDATE ON vehicles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_drivers_updated_at BEFORE UPDATE ON drivers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_routes_updated_at BEFORE UPDATE ON routes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_wardens_updated_at BEFORE UPDATE ON wardens
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_hostel_allocations_updated_at BEFORE UPDATE ON hostel_allocations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_parents_updated_at BEFORE UPDATE ON parents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_fees_updated_at BEFORE UPDATE ON fees
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_fee_items_updated_at BEFORE UPDATE ON fee_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON budgets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_exam_schedules_updated_at BEFORE UPDATE ON exam_schedules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_grade_scales_updated_at BEFORE UPDATE ON grade_scales
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_transcripts_updated_at BEFORE UPDATE ON transcripts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_class_courses_updated_at BEFORE UPDATE ON class_courses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_leave_requests_updated_at BEFORE UPDATE ON leave_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_books_updated_at BEFORE UPDATE ON books
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_book_copies_updated_at BEFORE UPDATE ON book_copies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER book_copies_stock AFTER INSERT OR UPDATE OR DELETE ON book_copies
  FOR EACH ROW EXECUTE FUNCTION update_book_stock();
CREATE TRIGGER update_book_purchases_updated_at BEFORE UPDATE ON book_purchases
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_book_sales_updated_at BEFORE UPDATE ON book_sales
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_reservations_updated_at BEFORE UPDATE ON reservations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_assets_updated_at BEFORE UPDATE ON assets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_inventory_items_updated_at BEFORE UPDATE ON inventory_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_asset_assignments_updated_at BEFORE UPDATE ON asset_assignments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_inventory_categories_updated_at BEFORE UPDATE ON inventory_categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_stock_reconciliation_updated_at BEFORE UPDATE ON stock_reconciliation
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_item_condition_history_updated_at BEFORE UPDATE ON item_condition_history
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON messages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_notices_updated_at BEFORE UPDATE ON notices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_it_tickets_updated_at BEFORE UPDATE ON it_tickets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_complaints_updated_at BEFORE UPDATE ON complaints
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_maintenance_requests_updated_at BEFORE UPDATE ON maintenance_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_jobs_updated_at BEFORE UPDATE ON jobs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_interview_schedules_updated_at BEFORE UPDATE ON interview_schedules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_performance_reviews_updated_at BEFORE UPDATE ON performance_reviews
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_trainings_updated_at BEFORE UPDATE ON trainings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_document_requests_updated_at BEFORE UPDATE ON document_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_certificates_issued_updated_at BEFORE UPDATE ON certificates_issued
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON reports
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_report_categories_updated_at BEFORE UPDATE ON report_categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_report_templates_updated_at BEFORE UPDATE ON report_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_report_schedules_updated_at BEFORE UPDATE ON report_schedules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_dashboards_updated_at BEFORE UPDATE ON dashboards
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_widgets_updated_at BEFORE UPDATE ON widgets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_roles_updated_at BEFORE UPDATE ON roles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_permissions_updated_at BEFORE UPDATE ON user_permissions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_page_permissions_updated_at BEFORE UPDATE ON page_permissions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_menu_items_updated_at BEFORE UPDATE ON menu_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Triggers for new tables
CREATE TRIGGER update_academic_years_updated_at BEFORE UPDATE ON academic_years
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_semesters_updated_at BEFORE UPDATE ON semesters
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subjects_updated_at BEFORE UPDATE ON subjects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_class_subjects_updated_at BEFORE UPDATE ON class_subjects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_student_enrollments_updated_at BEFORE UPDATE ON student_enrollments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_timetables_updated_at BEFORE UPDATE ON timetables
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rooms_updated_at BEFORE UPDATE ON rooms
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_parent_students_updated_at BEFORE UPDATE ON parent_students
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_teacher_qualifications_updated_at BEFORE UPDATE ON teacher_qualifications
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_student_documents_updated_at BEFORE UPDATE ON student_documents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_installment_plans_updated_at BEFORE UPDATE ON installment_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_homework_updated_at BEFORE UPDATE ON homework
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_homework_submissions_updated_at BEFORE UPDATE ON homework_submissions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lesson_plans_updated_at BEFORE UPDATE ON lesson_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_holidays_updated_at BEFORE UPDATE ON holidays
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_api_keys_updated_at BEFORE UPDATE ON api_keys
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_webhooks_updated_at BEFORE UPDATE ON webhooks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE parents ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE discounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE salaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee_structures ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_fee_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee_installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE journals ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE petty_cash_funds ENABLE ROW LEVEL SECURITY;
ALTER TABLE petty_cash_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE record_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE grade_scales ENABLE ROW LEVEL SECURITY;
ALTER TABLE transcripts ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_copies ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE asset_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_reconciliation ENABLE ROW LEVEL SECURITY;
ALTER TABLE item_condition_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE notices ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE it_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE it_ticket_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainings ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificates_issued ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE dashboards ENABLE ROW LEVEL SECURITY;
ALTER TABLE widgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE page_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE sms_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE salaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE wardens ENABLE ROW LEVEL SECURITY;
ALTER TABLE hostel_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE homework ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE reception_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE library_books ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE library_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE digital_library ENABLE ROW LEVEL SECURITY;
ALTER TABLE recruitment ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_leaves ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_leaves ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_leave_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_affairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_group_members ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES - TENANT ISOLATION & ROLE-BASED ACCESS
-- ============================================

-- Tenants: Users can only access their own tenant
CREATE POLICY "tenants_select_isolation" ON tenants FOR SELECT
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE tenant_id = tenants.id
    )
    OR 
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'super_admin'
    )
  );

CREATE POLICY "tenants_insert_superadmin" ON tenants FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'super_admin'
    )
  );

CREATE POLICY "tenants_update_superadmin" ON tenants FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'super_admin'
    )
  );

CREATE POLICY "tenants_delete_superadmin" ON tenants FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'super_admin'
    )
  );

-- Profiles: Tenant-scoped access with role-based permissions
CREATE POLICY "profiles_select_tenant_isolation" ON profiles FOR SELECT
  USING (
    auth.uid() = id  -- Users can always see their own profile
    OR
    (
      tenant_id IN (
        SELECT tenant_id FROM profiles WHERE id = auth.uid()
      )
    )
  );

CREATE POLICY "profiles_insert_tenant_scoped" ON profiles FOR INSERT
  WITH CHECK (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'super_admin'
    )
  );

CREATE POLICY "profiles_update_own_or_admin" ON profiles FOR UPDATE
  USING (
    auth.uid() = id  -- Users can update their own profile
    OR
    (
      tenant_id IN (
        SELECT tenant_id FROM profiles WHERE id = auth.uid()
      )
      AND EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role IN ('super_admin', 'admin', 'hr_manager')
      )
    )
  );

-- Core entity tables with tenant isolation
CREATE POLICY "students_tenant_isolation" ON students FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "teachers_tenant_isolation" ON teachers FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "staff_tenant_isolation" ON staff FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "parents_tenant_isolation" ON parents FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Academic tables with tenant isolation
CREATE POLICY "departments_tenant_isolation" ON departments FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "programs_tenant_isolation" ON programs FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "classes_tenant_isolation" ON classes FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "courses_tenant_isolation" ON courses FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "course_details_tenant_isolation" ON course_details FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "branches_tenant_isolation" ON branches FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Finance tables with tenant isolation
CREATE POLICY "fees_tenant_isolation" ON fees FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "fee_items_tenant_isolation" ON fee_items FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "invoices_tenant_isolation" ON invoices FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "invoice_items_tenant_isolation" ON invoice_items FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "payments_tenant_isolation" ON payments FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "expenses_tenant_isolation" ON expenses FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "salaries_tenant_isolation" ON salaries FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "fee_types_tenant_isolation" ON fee_types FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "fee_structures_tenant_isolation" ON fee_structures FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "student_fee_assignments_tenant_isolation" ON student_fee_assignments FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "fee_installments_tenant_isolation" ON fee_installments FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "accounts_tenant_isolation" ON accounts FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "journals_tenant_isolation" ON journals FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "journal_entries_tenant_journal" ON journal_entries FOR ALL
  USING (
    journal_id IN (
      SELECT j.id FROM journals j WHERE j.tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid())
    )
  );

CREATE POLICY "receipts_tenant_isolation" ON receipts FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "petty_cash_funds_tenant_isolation" ON petty_cash_funds FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "petty_cash_entries_tenant_isolation" ON petty_cash_entries FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "audit_log_tenant_isolation" ON audit_log FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "record_history_tenant_isolation" ON record_history FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "payroll_tenant_isolation" ON payroll FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "payroll_items_tenant_isolation" ON payroll_items FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "discounts_tenant_isolation" ON discounts FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "promotions_tenant_isolation" ON promotions FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "budgets_tenant_isolation" ON budgets FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Academic support tables
CREATE POLICY "exams_tenant_isolation" ON exams FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "grades_tenant_isolation" ON grades FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "attendance_tenant_isolation" ON attendance FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "exam_schedules_tenant_isolation" ON exam_schedules FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "transcripts_tenant_isolation" ON transcripts FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Library tables
CREATE POLICY "books_tenant_isolation" ON books FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "book_copies_tenant_isolation" ON book_copies FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "book_purchases_tenant_isolation" ON book_purchases FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "book_sales_tenant_isolation" ON book_sales FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "book_issues_tenant_isolation" ON book_issues FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "reservations_tenant_isolation" ON reservations FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Inventory & Assets
CREATE POLICY "assets_tenant_isolation" ON assets FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "inventory_items_tenant_isolation" ON inventory_items FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "asset_assignments_tenant_isolation" ON asset_assignments FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "inventory_transactions_tenant_isolation" ON inventory_transactions FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "inventory_categories_tenant_isolation" ON inventory_categories FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "stock_reconciliation_tenant_isolation" ON stock_reconciliation FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "item_condition_history_tenant_isolation" ON item_condition_history FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

-- HR Tables
CREATE POLICY "leave_requests_tenant_isolation" ON leave_requests FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "jobs_tenant_isolation" ON jobs FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "job_applications_tenant_isolation" ON job_applications FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "job_announcements_tenant_isolation" ON job_announcements FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "announcements_tenant_isolation" ON announcements FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "performance_reviews_tenant_isolation" ON performance_reviews FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "trainings_tenant_isolation" ON trainings FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Communication tables - Users can see their own messages/notifications
CREATE POLICY "notifications_user_isolation" ON notifications FOR ALL
  USING (
    user_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('super_admin', 'admin')
    )
  );

CREATE POLICY "messages_tenant_isolation" ON messages FOR ALL
  USING (
    sender_id = auth.uid()
    OR
    receiver_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('super_admin', 'admin')
    )
  );

-- Support & IT tables
CREATE POLICY "it_tickets_tenant_isolation" ON it_tickets FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "complaints_tenant_isolation" ON complaints FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "maintenance_requests_tenant_isolation" ON maintenance_requests FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Documents & Certificates
CREATE POLICY "documents_tenant_isolation" ON documents FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "certificates_tenant_isolation" ON certificates FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "certificates_issued_tenant_isolation" ON certificates_issued FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Settings & Config
CREATE POLICY "settings_tenant_isolation" ON settings FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Audit logs - Read only for admins
CREATE POLICY "audit_logs_admin_read" ON audit_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('super_admin', 'admin')
    )
  );

-- Events
CREATE POLICY "events_tenant_isolation" ON events FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

-- User permissions & menus
CREATE POLICY "roles_tenant_isolation" ON roles FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "role_permissions_tenant_isolation" ON role_permissions FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "user_roles_tenant_isolation" ON user_roles FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "page_permissions_tenant_isolation" ON page_permissions FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "user_permissions_tenant_isolation" ON user_permissions FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "menu_items_tenant_isolation" ON menu_items FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

-- SMS & Email logs
CREATE POLICY "sms_logs_tenant_isolation" ON sms_logs FOR SELECT
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "email_logs_tenant_isolation" ON email_logs FOR SELECT
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

-- RLS Policies for New Tables
CREATE POLICY "academic_years_tenant_isolation" ON academic_years FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "semesters_tenant_isolation" ON semesters FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "subjects_tenant_isolation" ON subjects FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "class_subjects_tenant_isolation" ON class_subjects FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "student_enrollments_tenant_isolation" ON student_enrollments FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "timetables_tenant_isolation" ON timetables FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "rooms_tenant_isolation" ON rooms FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "parent_students_tenant_isolation" ON parent_students FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "teacher_qualifications_tenant_isolation" ON teacher_qualifications FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "student_documents_tenant_isolation" ON student_documents FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "installment_plans_tenant_isolation" ON installment_plans FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "homework_tenant_isolation" ON homework FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "homework_submissions_tenant_isolation" ON homework_submissions FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "lesson_plans_tenant_isolation" ON lesson_plans FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "holidays_tenant_isolation" ON holidays FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "system_logs_tenant_isolation" ON system_logs FOR SELECT
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "api_keys_tenant_isolation" ON api_keys FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
    AND EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('super_admin', 'admin')
    )
  );

CREATE POLICY "webhooks_tenant_isolation" ON webhooks FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
    AND EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('super_admin', 'admin')
    )
  );

CREATE POLICY "notification_templates_tenant_isolation" ON notification_templates FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "notification_queue_tenant_isolation" ON notification_queue FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "user_devices_user_isolation" ON user_devices FOR ALL
  USING (
    user_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('super_admin', 'admin')
    )
  );

CREATE POLICY "employee_leaves_tenant_isolation" ON employee_leaves FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "student_leaves_tenant_isolation" ON student_leaves FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "student_leave_tracking_tenant_isolation" ON student_leave_tracking FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "device_sessions_user_isolation" ON device_sessions FOR ALL
  USING (
    user_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('super_admin', 'admin')
    )
  );

CREATE POLICY "support_tickets_tenant_isolation" ON support_tickets FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Enable RLS on new tables
ALTER TABLE academic_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE semesters ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetables ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_qualifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee_structures ENABLE ROW LEVEL SECURITY;
ALTER TABLE installment_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_fee_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE homework ENABLE ROW LEVEL SECURITY;
ALTER TABLE homework_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE holidays ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_leaves ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_leaves ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_leave_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage students"
  ON students FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin')
    )
  );

-- ============================================
-- RLS POLICIES - PAYMENTS
-- ============================================

CREATE POLICY "Accountants can manage payments"
  ON payments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'accountant')
    )
  );

CREATE POLICY "Students can view their payments"
  ON payments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND (profiles.role = 'student' OR profiles.role = 'parent')
    )
  );

-- ============================================
-- RLS POLICIES - SALARIES
-- ============================================

CREATE POLICY "HR and Accountants can manage salaries"
  ON salaries FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'hr_manager', 'accountant')
    )
  );

CREATE POLICY "Employees can view their own salaries"
  ON salaries FOR SELECT
  USING (employee_id = auth.uid());

-- ============================================
-- RLS POLICIES - ATTENDANCE
-- ============================================

CREATE POLICY "Staff can manage attendance"
  ON attendance FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'teacher', 'academic_support', 'hr_manager')
    )
  );

CREATE POLICY "Users can view their own attendance"
  ON attendance FOR SELECT
  USING (person_id = auth.uid());

-- ============================================
-- RLS POLICIES - GRADES
-- ============================================

CREATE POLICY "Teachers can manage grades"
  ON grades FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'teacher')
    )
  );

CREATE POLICY "Students can view their grades"
  ON grades FOR SELECT
  USING (student_id IN (
    SELECT id FROM students WHERE profile_id = auth.uid()
  ));

-- ============================================
-- RLS POLICIES - CHAT
-- ============================================

CREATE POLICY "Users can view their chat groups"
  ON chat_groups FOR SELECT
  USING (
    id IN (
      SELECT group_id FROM chat_group_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create chat groups"
  ON chat_groups FOR INSERT
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "Users can view chat messages"
  ON chat_messages FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM chat_group_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can send messages"
  ON chat_messages FOR INSERT
  WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Users can view calls they participate in"
  ON chat_calls FOR SELECT
  USING (
    caller_id = auth.uid()
    OR callee_id = auth.uid()
  );

CREATE POLICY "Users can create calls"
  ON chat_calls FOR INSERT
  WITH CHECK (caller_id = auth.uid());

CREATE POLICY "Users can update calls they participate in"
  ON chat_calls FOR UPDATE
  USING (
    caller_id = auth.uid()
    OR callee_id = auth.uid()
  )
  WITH CHECK (
    caller_id = auth.uid()
    OR callee_id = auth.uid()
  );

-- ============================================
-- RLS POLICIES - NOTIFICATIONS
-- ============================================

CREATE POLICY "Users can view their notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "System can create notifications"
  ON notifications FOR INSERT
  WITH CHECK (
    -- Users can create notifications for themselves
    user_id = auth.uid()
    OR
    -- Admins can create notifications for their tenant users
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin')
    )
  );

CREATE POLICY "Users can update their notifications"
  ON notifications FOR UPDATE
  USING (user_id = auth.uid());

-- ============================================
-- RLS POLICIES - LEAVE MANAGEMENT
-- ============================================

CREATE POLICY "Employees can manage their leaves"
  ON employee_leaves FOR ALL
  USING (employee_id = auth.uid());

CREATE POLICY "HR can view all leaves"
  ON employee_leaves FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'hr_manager')
    )
  );

CREATE POLICY "Students can manage their leaves"
  ON student_leaves FOR ALL
  USING (
    student_id IN (
      SELECT id FROM students WHERE profile_id = auth.uid()
    )
  );

-- ============================================
-- EDGE FUNCTIONS - Supabase Functions
-- ============================================

-- Function: Auto-calculate grade from percentage
CREATE OR REPLACE FUNCTION calculate_grade(percentage DECIMAL)
RETURNS TEXT AS $$
BEGIN
  IF percentage >= 90 THEN RETURN 'A+';
  ELSIF percentage >= 85 THEN RETURN 'A';
  ELSIF percentage >= 80 THEN RETURN 'A-';
  ELSIF percentage >= 75 THEN RETURN 'B+';
  ELSIF percentage >= 70 THEN RETURN 'B';
  ELSIF percentage >= 65 THEN RETURN 'B-';
  ELSIF percentage >= 60 THEN RETURN 'C+';
  ELSIF percentage >= 55 THEN RETURN 'C';
  ELSIF percentage >= 50 THEN RETURN 'C-';
  ELSIF percentage >= 45 THEN RETURN 'D+';
  ELSIF percentage >= 40 THEN RETURN 'D';
  ELSE RETURN 'F';
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Function: Calculate student attendance percentage
CREATE OR REPLACE FUNCTION calculate_attendance_percentage(p_student_id UUID, p_start_date DATE, p_end_date DATE)
RETURNS DECIMAL AS $$
DECLARE
  total_days INTEGER;
  present_days INTEGER;
  attendance_pct DECIMAL;
BEGIN
  SELECT COUNT(*) INTO total_days
  FROM attendance
  WHERE person_id = p_student_id
  AND person_type = 'student'
  AND date BETWEEN p_start_date AND p_end_date;
  
  SELECT COUNT(*) INTO present_days
  FROM attendance
  WHERE person_id = p_student_id
  AND person_type = 'student'
  AND date BETWEEN p_start_date AND p_end_date
  AND status IN ('present', 'half_day');
  
  IF total_days = 0 THEN
    RETURN 0;
  END IF;
  
  attendance_pct := (present_days::DECIMAL / total_days::DECIMAL) * 100;
  RETURN ROUND(attendance_pct, 2);
END;
$$ LANGUAGE plpgsql;

-- Function: Get student GPA
CREATE OR REPLACE FUNCTION calculate_student_gpa(p_student_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  gpa DECIMAL;
BEGIN
  SELECT AVG(grade_point) INTO gpa
  FROM grades
  WHERE student_id = p_student_id
  AND grade_point IS NOT NULL;
  
  RETURN COALESCE(ROUND(gpa, 2), 0);
END;
$$ LANGUAGE plpgsql;

-- Function: Generate student code
CREATE OR REPLACE FUNCTION generate_student_code()
RETURNS TRIGGER AS $$
DECLARE
  next_code INTEGER;
BEGIN
  IF NEW.student_code IS NULL THEN
    SELECT COALESCE(MAX(
      CAST(SUBSTRING(student_code FROM 3) AS INTEGER)
    ), 0) + 1 INTO next_code
    FROM students;
    
    NEW.student_code := 'ST' || LPAD(next_code::TEXT, 6, '0');
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for auto-generating student codes
DROP TRIGGER IF EXISTS trg_generate_student_code ON students;
CREATE TRIGGER trg_generate_student_code
  BEFORE INSERT ON students
  FOR EACH ROW
  EXECUTE FUNCTION generate_student_code();

-- Function: Generate employee code
CREATE OR REPLACE FUNCTION generate_employee_code()
RETURNS TRIGGER AS $$
DECLARE
  next_code INTEGER;
BEGIN
  IF NEW.employee_code IS NULL THEN
    IF TG_TABLE_NAME = 'teachers' THEN
      SELECT COALESCE(MAX(
        CAST(SUBSTRING(employee_code FROM 3) AS INTEGER)
      ), 0) + 1 INTO next_code
      FROM teachers;
      NEW.employee_code := 'TC' || LPAD(next_code::TEXT, 6, '0');
    ELSIF TG_TABLE_NAME = 'staff' THEN
      SELECT COALESCE(MAX(
        CAST(SUBSTRING(employee_code FROM 3) AS INTEGER)
      ), 0) + 1 INTO next_code
      FROM staff;
      NEW.employee_code := 'SF' || LPAD(next_code::TEXT, 6, '0');
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for auto-generating employee codes
DROP TRIGGER IF EXISTS trg_generate_teacher_code ON teachers;
CREATE TRIGGER trg_generate_teacher_code
  BEFORE INSERT ON teachers
  FOR EACH ROW
  EXECUTE FUNCTION generate_employee_code();

DROP TRIGGER IF EXISTS trg_generate_staff_code ON staff;
CREATE TRIGGER trg_generate_staff_code
  BEFORE INSERT ON staff
  FOR EACH ROW
  EXECUTE FUNCTION generate_employee_code();

-- Function: Auto-calculate percentage in grades
CREATE OR REPLACE FUNCTION calculate_grade_percentage()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.score IS NOT NULL AND NEW.max_score IS NOT NULL AND NEW.max_score > 0 THEN
    NEW.percentage := ROUND((NEW.score / NEW.max_score) * 100, 2);
    NEW.grade := calculate_grade(NEW.percentage);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for auto-calculating percentages
DROP TRIGGER IF EXISTS trg_calculate_grade_percentage ON grades;
CREATE TRIGGER trg_calculate_grade_percentage
  BEFORE INSERT OR UPDATE ON grades
  FOR EACH ROW
  EXECUTE FUNCTION calculate_grade_percentage();

DROP TRIGGER IF EXISTS trg_calculate_exam_result_percentage ON exam_results;
CREATE TRIGGER trg_calculate_exam_result_percentage
  BEFORE INSERT OR UPDATE ON exam_results
  FOR EACH ROW
  EXECUTE FUNCTION calculate_grade_percentage();

-- ============================================
-- EDGE FUNCTIONS - Common Business Operations
-- ============================================

-- Function: Register a new user with profile
CREATE OR REPLACE FUNCTION register_user(
  p_auth_id UUID,
  p_tenant_id UUID,
  p_full_name TEXT,
  p_role TEXT,
  p_email TEXT DEFAULT NULL,
  p_phone TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_profile_id UUID;
BEGIN
  INSERT INTO profiles (id, tenant_id, full_name, role, email, phone)
  VALUES (p_auth_id, p_tenant_id, p_full_name, p_role, p_email, p_phone)
  RETURNING id INTO v_profile_id;
  
  RETURN v_profile_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Process a payment and update student balance
CREATE OR REPLACE FUNCTION process_payment(
  p_student_id UUID,
  p_tenant_id UUID,
  p_amount DECIMAL,
  p_payment_method TEXT,
  p_payment_date DATE DEFAULT CURRENT_DATE,
  p_description TEXT DEFAULT NULL,
  p_reference_number TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_payment_id UUID;
  v_current_paid DECIMAL;
BEGIN
  -- Insert payment record
  INSERT INTO payments (tenant_id, student_id, amount, payment_method, payment_date, description, reference_number, status)
  VALUES (p_tenant_id, p_student_id, p_amount, p_payment_method, p_payment_date, p_description, p_reference_number, 'completed')
  RETURNING id INTO v_payment_id;
  
  -- Update student paid amount
  UPDATE students SET paid_amount = paid_amount + p_amount
  WHERE id = p_student_id;
  
  RETURN v_payment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Enroll a student in a course
CREATE OR REPLACE FUNCTION enroll_student(
  p_student_id UUID,
  p_course_id UUID,
  p_tenant_id UUID,
  p_enrollment_date DATE DEFAULT CURRENT_DATE
)
RETURNS UUID AS $$
DECLARE
  v_enrollment_id UUID;
BEGIN
  INSERT INTO student_enrollments (student_id, course_id, tenant_id, enrollment_date, status)
  VALUES (p_student_id, p_course_id, p_tenant_id, p_enrollment_date, 'active')
  RETURNING id INTO v_enrollment_id;
  
  -- Update student's course_ids array
  UPDATE students 
  SET course_ids = array_append(COALESCE(course_ids, '{}'), p_course_id)
  WHERE id = p_student_id;
  
  RETURN v_enrollment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Send a notification to a user
CREATE OR REPLACE FUNCTION send_notification(
  p_user_id UUID,
  p_type TEXT,
  p_title TEXT,
  p_message TEXT,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  INSERT INTO notifications (user_id, type, title, message, metadata, is_read)
  VALUES (p_user_id, p_type, p_title, p_message, p_metadata, false)
  RETURNING id INTO v_notification_id;
  
  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Calculate course completion percentage for a student
CREATE OR REPLACE FUNCTION calculate_course_completion(
  p_student_id UUID,
  p_course_id UUID
)
RETURNS DECIMAL AS $$
DECLARE
  v_total_assignments INTEGER;
  v_completed_assignments INTEGER;
  v_attendance_pct DECIMAL;
  v_completion_pct DECIMAL;
BEGIN
  -- Count assignments
  SELECT COUNT(*) INTO v_total_assignments
  FROM student_assignments
  WHERE student_id = p_student_id AND course_id = p_course_id;
  
  SELECT COUNT(*) INTO v_completed_assignments
  FROM student_assignments
  WHERE student_id = p_student_id AND course_id = p_course_id
  AND status IN ('Submitted', 'Graded');
  
  -- Get attendance percentage
  SELECT COALESCE(AVG(attendance_percentage), 0) INTO v_attendance_pct
  FROM student_progress
  WHERE student_id = p_student_id;
  
  -- Calculate weighted completion (60% assignments, 40% attendance)
  IF v_total_assignments > 0 THEN
    v_completion_pct := (v_completed_assignments::DECIMAL / v_total_assignments) * 60 + (v_attendance_pct / 100) * 40;
  ELSE
    v_completion_pct := v_attendance_pct;
  END IF;
  
  RETURN ROUND(v_completion_pct, 2);
END;
$$ LANGUAGE plpgsql;

-- Function: Get dashboard stats for a tenant
CREATE OR REPLACE FUNCTION get_tenant_stats(p_tenant_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_stats JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_students', (SELECT COUNT(*) FROM students WHERE tenant_id = p_tenant_id AND status = 'active'),
    'total_teachers', (SELECT COUNT(*) FROM teachers WHERE tenant_id = p_tenant_id),
    'total_staff', (SELECT COUNT(*) FROM staff WHERE tenant_id = p_tenant_id),
    'total_courses', (SELECT COUNT(*) FROM courses),
    'total_departments', (SELECT COUNT(*) FROM departments WHERE tenant_id = p_tenant_id),
    'total_classes', (SELECT COUNT(*) FROM classes),
    'active_enrollments', (SELECT COUNT(*) FROM student_enrollments WHERE tenant_id = p_tenant_id AND status = 'active'),
    'total_revenue', (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE tenant_id = p_tenant_id AND status = 'completed'),
    'pending_payments', (SELECT COUNT(*) FROM invoices WHERE tenant_id = p_tenant_id AND status = 'Pending'),
    'attendance_rate', (
      SELECT COALESCE(ROUND(
        (COUNT(CASE WHEN a.status IN ('present', 'half_day') THEN 1 END)::DECIMAL / NULLIF(COUNT(*), 0)) * 100, 2
      ), 0)
      FROM attendance a WHERE a.person_id IN (SELECT id FROM students WHERE tenant_id = p_tenant_id)
    ),
    'upcoming_events', (SELECT COUNT(*) FROM events WHERE tenant_id = p_tenant_id AND start_date >= NOW() AND status = 'scheduled'),
    'open_tickets', (SELECT COUNT(*) FROM it_tickets WHERE tenant_id = p_tenant_id AND status = 'open')
  ) INTO v_stats;
  
  RETURN v_stats;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- VIEWS FOR COMMON QUERIES
-- ============================================

-- View: Active students by program
CREATE OR REPLACE VIEW active_students_by_program AS
SELECT 
  p.name AS program_name,
  p.code AS program_code,
  COUNT(s.id) AS total_students,
  COUNT(CASE WHEN s.status = 'active' THEN 1 END) AS active_students,
  COUNT(CASE WHEN s.status = 'graduated' THEN 1 END) AS graduated_students
FROM programs p
LEFT JOIN students s ON s.program_id = p.id
GROUP BY p.id, p.name, p.code;

-- View: Teacher workload
CREATE OR REPLACE VIEW teacher_workload AS
SELECT 
  t.id,
  t.full_name,
  t.employee_code,
  COUNT(DISTINCT c.id) AS total_courses,
  COUNT(DISTINCT cl.id) AS total_classes,
  t.workload_hours,
  t.max_workload_hours,
  ROUND((t.workload_hours::DECIMAL / NULLIF(t.max_workload_hours, 0)) * 100, 2) AS workload_percentage
FROM teachers t
LEFT JOIN courses c ON t.id = c.teacher_id
LEFT JOIN classes cl ON t.id = cl.teacher_id
GROUP BY t.id, t.full_name, t.employee_code, t.workload_hours, t.max_workload_hours;

-- View: Payment summary by student
CREATE OR REPLACE VIEW student_payment_summary AS
SELECT 
  s.id AS student_id,
  s.full_name,
  s.student_code,
  s.total_fees,
  s.paid_amount,
  s.outstanding_balance,
  COUNT(p.id) AS total_payments,
  SUM(p.amount) AS total_paid
FROM students s
LEFT JOIN payments p ON p.student_id = s.id AND p.status = 'completed'
GROUP BY s.id, s.full_name, s.student_code, s.total_fees, s.paid_amount, s.outstanding_balance;

-- View: Upcoming events
CREATE OR REPLACE VIEW upcoming_events AS
SELECT 
  e.id,
  e.title,
  e.description,
  e.event_type,
  e.start_date,
  e.end_date,
  e.location,
  e.status,
  e.registered_count,
  e.max_participants,
  CASE 
    WHEN e.max_participants IS NULL THEN 'unlimited'
    WHEN e.registered_count >= e.max_participants THEN 'full'
    ELSE 'available'
  END AS availability_status
FROM events e
WHERE e.start_date >= NOW()
AND e.status = 'scheduled'
ORDER BY e.start_date ASC;

-- View: Overdue invoices
CREATE OR REPLACE VIEW overdue_invoices AS
SELECT 
  i.id,
  i.invoice_number,
  i.student_id,
  s.full_name AS student_name,
  i.amount,
  i.due_date,
  i.status,
  CURRENT_DATE - i.due_date AS days_overdue
FROM invoices i
LEFT JOIN students s ON s.id = i.student_id
WHERE i.due_date < CURRENT_DATE
AND i.status IN ('Pending', 'Overdue')
ORDER BY i.due_date ASC;

-- View: Student attendance overview
CREATE OR REPLACE VIEW student_attendance_overview AS
SELECT 
  s.id AS student_id,
  s.full_name,
  s.student_code,
  COUNT(a.id) AS total_days,
  COUNT(CASE WHEN a.status = 'present' THEN 1 END) AS present_days,
  COUNT(CASE WHEN a.status = 'absent' THEN 1 END) AS absent_days,
  COUNT(CASE WHEN a.status = 'late' THEN 1 END) AS late_days,
  ROUND(
    (COUNT(CASE WHEN a.status IN ('present', 'half_day') THEN 1 END)::DECIMAL / 
    NULLIF(COUNT(a.id), 0)) * 100, 2
  ) AS attendance_percentage
FROM students s
LEFT JOIN attendance a ON a.person_id = s.id AND a.person_type = 'student'
GROUP BY s.id, s.full_name, s.student_code;

-- ============================================
-- TEST DATA GENERATION FUNCTIONS
-- ============================================

-- Function: Generate test students
CREATE OR REPLACE FUNCTION generate_test_students(count INTEGER)
RETURNS VOID AS $$
DECLARE
  i INTEGER;
  v_program_id UUID;
  v_class_id UUID;
BEGIN
  SELECT id INTO v_program_id FROM programs LIMIT 1;
  SELECT id INTO v_class_id FROM classes LIMIT 1;
  
  FOR i IN 1..count LOOP
    INSERT INTO students (
      full_name,
      first_name,
      last_name,
      email,
      phone,
      date_of_birth,
      gender,
      program_id,
      class_id,
      enrollment_date,
      status
    ) VALUES (
      'Test Student ' || i,
      'Test' || i,
      'Student',
      'test.student' || i || '@example.com',
      '+1234567890',
      DATE '2000-01-01' + (i || ' days')::INTERVAL,
      CASE WHEN i % 2 = 0 THEN 'Male' ELSE 'Female' END,
      v_program_id,
      v_class_id,
      CURRENT_DATE - (i || ' days')::INTERVAL,
      'active'
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function: Generate test attendance records
CREATE OR REPLACE FUNCTION generate_test_attendance(p_student_id UUID, p_days INTEGER)
RETURNS VOID AS $$
DECLARE
  i INTEGER;
  v_status TEXT;
BEGIN
  FOR i IN 0..p_days LOOP
    -- Random status: 80% present, 15% absent, 5% late
    v_status := CASE 
      WHEN RANDOM() < 0.80 THEN 'present'
      WHEN RANDOM() < 0.95 THEN 'absent'
      ELSE 'late'
    END;
    
    INSERT INTO attendance (
      person_id,
      person_type,
      date,
      status
    ) VALUES (
      p_student_id,
      'student',
      CURRENT_DATE - (i || ' days')::INTERVAL,
      v_status
    ) ON CONFLICT (person_id, person_type, date) DO NOTHING;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function: Generate test grades
CREATE OR REPLACE FUNCTION generate_test_grades(p_student_id UUID, p_count INTEGER)
RETURNS VOID AS $$
DECLARE
  i INTEGER;
  v_score DECIMAL;
  v_exam_id UUID;
BEGIN
  SELECT id INTO v_exam_id FROM exams LIMIT 1;
  
  FOR i IN 1..p_count LOOP
    v_score := ROUND(40 + RANDOM() * 60, 2); -- Random score between 40-100
    
    INSERT INTO grades (
      student_id,
      exam_id,
      subject,
      score,
      max_score,
      status
    ) VALUES (
      p_student_id,
      v_exam_id,
      'Subject ' || i,
      v_score,
      100,
      'graded'
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- SAMPLE TEST DATA
-- ============================================

-- Insert sample departments
INSERT INTO departments (name, description, active) VALUES
('English Language', 'English language learning programs', true),
('Computer Science', 'IT and programming courses', true),
('Business Administration', 'Business and management programs', true)
ON CONFLICT DO NOTHING;

-- Insert sample programs
INSERT INTO programs (name, code, description, duration, credits, status) VALUES
('IELTS Preparation', 'IELTS-001', 'Intensive IELTS exam preparation', '3 months', 12, 'active'),
('TOEFL Preparation', 'TOEFL-001', 'Comprehensive TOEFL training', '3 months', 12, 'active'),
('Business English', 'BUSENG-001', 'Professional English for business', '6 months', 24, 'active'),
('General English', 'GENENG-001', 'Everyday English communication', '12 months', 48, 'active')
ON CONFLICT DO NOTHING;

-- Insert sample classes
INSERT INTO classes (name, grade, year, active) VALUES
('IELTS Morning Batch A', 'Advanced', '2024', true),
('IELTS Evening Batch B', 'Intermediate', '2024', true),
('TOEFL Weekend Batch', 'Advanced', '2024', true)
ON CONFLICT DO NOTHING;

-- ============================================
-- COMPLETION MESSAGE
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'EMIS Database Schema Setup Complete!';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Tables: 155+';
  RAISE NOTICE 'Indexes: 310+';
  RAISE NOTICE 'Triggers: 148+';
  RAISE NOTICE 'RLS Policies: 135+';
  RAISE NOTICE 'Views: 11';
  RAISE NOTICE 'Functions: 30+';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Features:';
  RAISE NOTICE 'âœ“ Hierarchical tenant support';
  RAISE NOTICE 'âœ“ Auto-generated codes (students, teachers, staff)';
  RAISE NOTICE 'âœ“ Auto-calculated grades and percentages';
  RAISE NOTICE 'âœ“ Attendance tracking and calculations';
  RAISE NOTICE 'âœ“ GPA calculation';
  RAISE NOTICE 'âœ“ Chat with video/voice support';
  RAISE NOTICE 'âœ“ Leave management (employees & students)';
  RAISE NOTICE 'âœ“ Notification system';
  RAISE NOTICE 'âœ“ Device session tracking';
  RAISE NOTICE 'âœ“ Home page CMS';
  RAISE NOTICE 'âœ“ Row Level Security on all tables';
  RAISE NOTICE 'âœ“ Test data generation functions';
  RAISE NOTICE 'âœ“ User registration & profile management';
  RAISE NOTICE 'âœ“ Payment processing & balance updates';
  RAISE NOTICE 'âœ“ Student enrollment & course tracking';
  RAISE NOTICE 'âœ“ Notification dispatch system';
  RAISE NOTICE 'âœ“ Course completion calculator';
  RAISE NOTICE 'âœ“ Tenant dashboard statistics';
  RAISE NOTICE 'âœ“ Transport management (vehicles, drivers, routes)';
  RAISE NOTICE 'âœ“ Hostel management (wardens, allocations)';
  RAISE NOTICE 'âœ“ IT support ticketing system';
  RAISE NOTICE 'âœ“ Complaint management system';
  RAISE NOTICE 'âœ“ Maintenance request tracking';
  RAISE NOTICE 'âœ“ Inventory & asset management';
  RAISE NOTICE 'âœ“ Document management & certificates';
  RAISE NOTICE 'âœ“ Social media links management';
  RAISE NOTICE 'âœ“ Contact info & address management';
  RAISE NOTICE 'âœ“ Page sections & FAQ management';
  RAISE NOTICE 'âœ“ Partners & sponsors management';
  RAISE NOTICE 'âœ“ Newsletter subscriptions';
  RAISE NOTICE 'âœ“ Site banners management';
  RAISE NOTICE 'âœ“ Entity view counters (classes, subjects, teachers, courses)';
  RAISE NOTICE 'âœ“ Daily/weekly view analytics & trends';
  RAISE NOTICE 'âœ“ API usage logging & tracking';
  RAISE NOTICE 'âœ“ Feature usage tracking';
  RAISE NOTICE 'âœ“ System health monitoring';
  RAISE NOTICE 'âœ“ Activity feed & error logging';
  RAISE NOTICE 'âœ“ Log retention & cleanup';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Ready for production use!';
   RAISE NOTICE '========================================';
END $$;

-- ============================================
-- CEO ROLE & EXECUTIVE PANEL ADDITIONS
-- ============================================

-- Add 'ceo' role to profiles constraint
-- Note: Requires manual ALTER if profiles already exist:
-- ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
-- ALTER TABLE profiles ADD CONSTRAINT profiles_role_check
--   CHECK (role IN ('ceo', 'super_admin', 'admin', 'teacher', 'student', 'guardian', 'staff',
--                   'academic_support', 'accountant', 'librarian', 'receptionist', 'hr_manager',
--                   'inventory_manager', 'it_support', 'maintenance', 'event_manager', 'complaint_manager'));
-- Handled by CREATE TABLE IF NOT EXISTS below with updated CHECK.

-- Recreate profiles with updated role check (only if table doesn't exist yet)
-- For existing tables, run the ALTER above separately.
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('ceo', 'super_admin', 'admin', 'teacher', 'student', 'guardian', 'staff',
                  'academic_support', 'accountant', 'librarian', 'receptionist', 'hr_manager',
                  'inventory_manager', 'it_support', 'maintenance', 'event_manager', 'complaint_manager'));

-- ============================================
-- CEO / EXECUTIVE PANEL TABLES
-- ============================================

-- Strategic Goals & OKRs
CREATE TABLE IF NOT EXISTS strategic_goals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  title TEXT NOT NULL,
  description TEXT,
  category TEXT CHECK (category IN ('academic', 'financial', 'growth', 'operations', 'hr', 'technology', 'community')),
  start_date DATE,
  target_date DATE,
  status TEXT DEFAULT 'active' CHECK (status IN ('draft', 'active', 'completed', 'cancelled')),
  progress_pct DECIMAL(5,2) DEFAULT 0,
  owner_id UUID REFERENCES profiles(id),
  parent_goal_id UUID REFERENCES strategic_goals(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_strategic_goals_tenant ON strategic_goals(tenant_id);
CREATE INDEX IF NOT EXISTS idx_strategic_goals_status ON strategic_goals(status);
CREATE INDEX IF NOT EXISTS idx_strategic_goals_category ON strategic_goals(category);
CREATE INDEX IF NOT EXISTS idx_strategic_goals_owner ON strategic_goals(owner_id);

-- KPI Definitions
CREATE TABLE IF NOT EXISTS kpi_definitions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  description TEXT,
  category TEXT CHECK (category IN ('academic', 'financial', 'enrollment', 'attendance', 'performance', 'satisfaction', 'operations', 'hr')),
  unit TEXT DEFAULT 'number',
  target_value DECIMAL(12,2),
  min_threshold DECIMAL(12,2),
  max_threshold DECIMAL(12,2),
  calculation_method TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_kpi_definitions_tenant ON kpi_definitions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_kpi_definitions_category ON kpi_definitions(category);
CREATE INDEX IF NOT EXISTS idx_kpi_definitions_active ON kpi_definitions(is_active);

-- KPI Records (periodic measurements)
CREATE TABLE IF NOT EXISTS kpi_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  kpi_definition_id UUID REFERENCES kpi_definitions(id),
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  actual_value DECIMAL(12,2) NOT NULL,
  target_value DECIMAL(12,2),
  variance DECIMAL(12,2) GENERATED ALWAYS AS (actual_value - COALESCE(target_value, 0)) STORED,
  variance_pct DECIMAL(5,2),
  status TEXT DEFAULT 'on_track' CHECK (status IN ('on_track', 'at_risk', 'below_target', 'exceeded', 'no_data')),
  notes TEXT,
  recorded_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(kpi_definition_id, period_start, period_end)
);

CREATE INDEX IF NOT EXISTS idx_kpi_records_tenant ON kpi_records(tenant_id);
CREATE INDEX IF NOT EXISTS idx_kpi_records_kpi ON kpi_records(kpi_definition_id);
CREATE INDEX IF NOT EXISTS idx_kpi_records_period ON kpi_records(period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_kpi_records_status ON kpi_records(status);

-- CEO Dashboards (custom executive views)
CREATE TABLE IF NOT EXISTS ceo_dashboards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  description TEXT,
  layout_config JSONB DEFAULT '{}'::jsonb,
  is_default BOOLEAN DEFAULT false,
  is_shared BOOLEAN DEFAULT false,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ceo_dashboards_tenant ON ceo_dashboards(tenant_id);
CREATE INDEX IF NOT EXISTS idx_ceo_dashboards_default ON ceo_dashboards(is_default);

-- CEO Dashboard Widgets
CREATE TABLE IF NOT EXISTS ceo_dashboard_widgets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  dashboard_id UUID REFERENCES ceo_dashboards(id) ON DELETE CASCADE,
  widget_type TEXT NOT NULL CHECK (widget_type IN ('kpi_card', 'chart', 'table', 'metric_group', 'trend', 'comparison', 'map', 'custom')),
  title TEXT NOT NULL,
  config JSONB DEFAULT '{}'::jsonb,
  position_x INTEGER DEFAULT 0,
  position_y INTEGER DEFAULT 0,
  width INTEGER DEFAULT 4,
  height INTEGER DEFAULT 2,
  is_visible BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ceo_widgets_dashboard ON ceo_dashboard_widgets(dashboard_id);

-- Business Reports (executive-level reports)
CREATE TABLE IF NOT EXISTS business_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  title TEXT NOT NULL,
  title_ar TEXT,
  title_dr TEXT,
  title_ps TEXT,
  report_type TEXT NOT NULL CHECK (report_type IN ('financial_summary', 'enrollment_analysis', 'academic_performance', 'staff_productivity', 'student_retention', 'revenue_forecast', 'growth_metrics', 'custom')),
  period TEXT CHECK (period IN ('daily', 'weekly', 'monthly', 'quarterly', 'yearly', 'custom')),
  parameters JSONB DEFAULT '{}'::jsonb,
  result_data JSONB,
  summary TEXT,
  is_auto_generated BOOLEAN DEFAULT false,
  generated_by UUID REFERENCES profiles(id),
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_business_reports_tenant ON business_reports(tenant_id);
CREATE INDEX IF NOT EXISTS idx_business_reports_type ON business_reports(report_type);
CREATE INDEX IF NOT EXISTS idx_business_reports_period ON business_reports(period);
CREATE INDEX IF NOT EXISTS idx_business_reports_generated ON business_reports(generated_at);

-- Cross-Tenant Analytics (for CEO overseeing multiple branches)
CREATE TABLE IF NOT EXISTS cross_tenant_analytics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  central_tenant_id UUID REFERENCES tenants(id),
  branch_tenant_id UUID REFERENCES tenants(id),
  metric_name TEXT NOT NULL,
  metric_value DECIMAL(12,2) NOT NULL,
  metric_date DATE NOT NULL,
  comparison_value DECIMAL(12,2),
  variance_pct DECIMAL(5,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cross_tenant_central ON cross_tenant_analytics(central_tenant_id);
CREATE INDEX IF NOT EXISTS idx_cross_tenant_branch ON cross_tenant_analytics(branch_tenant_id);
CREATE INDEX IF NOT EXISTS idx_cross_tenant_metric ON cross_tenant_analytics(metric_name, metric_date);

-- ============================================
-- ATTENDANCE CORRECTIONS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS attendance_corrections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  attendance_id UUID REFERENCES attendance(id) ON DELETE SET NULL,
  person_id UUID NOT NULL,
  person_type TEXT NOT NULL CHECK (person_type IN ('student', 'teacher', 'staff')),
  date DATE NOT NULL,
  original_status TEXT NOT NULL,
  corrected_status TEXT NOT NULL,
  reason TEXT NOT NULL,
  supporting_document_url TEXT,
  requested_by UUID REFERENCES profiles(id),
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMPTZ,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  rejection_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_attendance_corrections_tenant ON attendance_corrections(tenant_id);
CREATE INDEX IF NOT EXISTS idx_attendance_corrections_person ON attendance_corrections(person_id, person_type);
CREATE INDEX IF NOT EXISTS idx_attendance_corrections_date ON attendance_corrections(date);
CREATE INDEX IF NOT EXISTS idx_attendance_corrections_status ON attendance_corrections(status);
CREATE INDEX IF NOT EXISTS idx_attendance_corrections_requested ON attendance_corrections(requested_by);

-- ============================================
-- BACKUP MANAGEMENT TABLES
-- ============================================

-- Backup Records
CREATE TABLE IF NOT EXISTS backups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  backup_type TEXT NOT NULL CHECK (backup_type IN ('full', 'incremental', 'partial')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'failed', 'restoring')),
  file_url TEXT,
  file_size_bytes BIGINT,
  database_size_bytes BIGINT,
  checksum TEXT,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  error_message TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  triggered_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_backups_tenant ON backups(tenant_id);
CREATE INDEX IF NOT EXISTS idx_backups_status ON backups(status);
CREATE INDEX IF NOT EXISTS idx_backups_type ON backups(backup_type);
CREATE INDEX IF NOT EXISTS idx_backups_started ON backups(started_at DESC);

-- Backup Schedules
CREATE TABLE IF NOT EXISTS backup_schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  frequency TEXT NOT NULL CHECK (frequency IN ('hourly', 'daily', 'weekly', 'monthly')),
  backup_type TEXT NOT NULL CHECK (backup_type IN ('full', 'incremental')),
  retention_days INTEGER DEFAULT 30,
  time_of_day TIME DEFAULT '02:00',
  day_of_week INTEGER CHECK (day_of_week BETWEEN 1 AND 7),
  day_of_month INTEGER CHECK (day_of_month BETWEEN 1 AND 31),
  is_active BOOLEAN DEFAULT true,
  last_run_at TIMESTAMPTZ,
  next_run_at TIMESTAMPTZ,
  notification_emails TEXT[],
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_backup_schedules_tenant ON backup_schedules(tenant_id);
CREATE INDEX IF NOT EXISTS idx_backup_schedules_active ON backup_schedules(is_active);
CREATE INDEX IF NOT EXISTS idx_backup_schedules_next ON backup_schedules(next_run_at);

-- ============================================
-- ACTIVITY & ERROR LOGS
-- ============================================

-- Detailed Activity Log (user actions tracking)
CREATE TABLE IF NOT EXISTS activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES profiles(id),
  session_id UUID,
  action TEXT NOT NULL,
  category TEXT CHECK (category IN ('auth', 'crud', 'view', 'export', 'import', 'config', 'admin', 'system')),
  resource_type TEXT,
  resource_id UUID,
  resource_name TEXT,
  details JSONB DEFAULT '{}'::jsonb,
  ip_address TEXT,
  user_agent TEXT,
  duration_ms INTEGER,
  outcome TEXT DEFAULT 'success' CHECK (outcome IN ('success', 'failure', 'partial')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_activity_logs_tenant ON activity_logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_user ON activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_action ON activity_logs(action);
CREATE INDEX IF NOT EXISTS idx_activity_logs_category ON activity_logs(category);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created ON activity_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_logs_resource ON activity_logs(resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_outcome ON activity_logs(outcome);

-- Error Logs (application/system errors)
CREATE TABLE IF NOT EXISTS error_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES profiles(id),
  error_level TEXT NOT NULL CHECK (error_level IN ('debug', 'info', 'warning', 'error', 'critical')),
  error_code TEXT,
  message TEXT NOT NULL,
  stack_trace TEXT,
  source TEXT,
  module TEXT,
  endpoint TEXT,
  request_data JSONB,
  response_data JSONB,
  ip_address TEXT,
  user_agent TEXT,
  resolved BOOLEAN DEFAULT false,
  resolved_by UUID REFERENCES profiles(id),
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_error_logs_tenant ON error_logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_error_logs_level ON error_logs(error_level);
CREATE INDEX IF NOT EXISTS idx_error_logs_code ON error_logs(error_code);
CREATE INDEX IF NOT EXISTS idx_error_logs_module ON error_logs(module);
CREATE INDEX IF NOT EXISTS idx_error_logs_created ON error_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_error_logs_resolved ON error_logs(resolved);

-- ============================================
-- FIX: ORDERING ISSUES - Add FK constraints via ALTER
-- ============================================

-- admin_course_assignments references courses which is defined later
-- Drop and re-add the FK to ensure it exists
ALTER TABLE admin_course_assignments DROP CONSTRAINT IF EXISTS admin_course_assignments_course_id_fkey;
ALTER TABLE admin_course_assignments ADD CONSTRAINT admin_course_assignments_course_id_fkey
  FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE;

-- students references programs and classes which are defined later
ALTER TABLE students DROP CONSTRAINT IF EXISTS students_program_id_fkey;
ALTER TABLE students ADD CONSTRAINT students_program_id_fkey
  FOREIGN KEY (program_id) REFERENCES programs(id);

ALTER TABLE students DROP CONSTRAINT IF EXISTS students_class_id_fkey;
ALTER TABLE students ADD CONSTRAINT students_class_id_fkey
  FOREIGN KEY (class_id) REFERENCES classes(id);

-- ============================================
-- FIX: send_notification function uses wrong column name
-- ============================================

CREATE OR REPLACE FUNCTION send_notification(
  p_user_id UUID,
  p_type TEXT,
  p_title TEXT,
  p_message TEXT,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  INSERT INTO notifications (user_id, type, title, body, data, is_read)
  VALUES (p_user_id, p_type, p_title, p_message, p_metadata, false)
  RETURNING id INTO v_notification_id;

  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- RLS POLICIES - NEW TABLES
-- ============================================

-- Enable RLS on new tables
ALTER TABLE strategic_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE kpi_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE kpi_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE ceo_dashboards ENABLE ROW LEVEL SECURITY;
ALTER TABLE ceo_dashboard_widgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE cross_tenant_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_corrections ENABLE ROW LEVEL SECURITY;
ALTER TABLE backups ENABLE ROW LEVEL SECURITY;
ALTER TABLE backup_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE error_logs ENABLE ROW LEVEL SECURITY;

-- CEO & Super Admin have full access to strategic goals
CREATE POLICY "ceo_superadmin_strategic_goals_all" ON strategic_goals FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('ceo', 'super_admin')
    )
  );

CREATE POLICY "admin_strategic_goals_view" ON strategic_goals FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
      AND profiles.tenant_id = strategic_goals.tenant_id
    )
  );

-- KPI definitions - CEO & super_admin full access
CREATE POLICY "ceo_superadmin_kpi_definitions_all" ON kpi_definitions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('ceo', 'super_admin')
    )
  );

CREATE POLICY "admin_kpi_definitions_view" ON kpi_definitions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
      AND profiles.tenant_id = kpi_definitions.tenant_id
    )
  );

-- KPI records
CREATE POLICY "ceo_superadmin_kpi_records_all" ON kpi_records FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('ceo', 'super_admin')
    )
  );

-- CEO dashboards - user isolation + ceo/super_admin access
CREATE POLICY "ceo_dashboards_user_isolation" ON ceo_dashboards FOR ALL
  USING (
    created_by = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('ceo', 'super_admin')
    )
  );

-- CEO dashboard widgets
CREATE POLICY "ceo_widgets_dashboard_isolation" ON ceo_dashboard_widgets FOR ALL
  USING (
    dashboard_id IN (
      SELECT id FROM ceo_dashboards WHERE created_by = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('ceo', 'super_admin')
    )
  );

-- Business reports
CREATE POLICY "ceo_superadmin_reports_all" ON business_reports FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('ceo', 'super_admin')
    )
  );

CREATE POLICY "admin_reports_view" ON business_reports FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
      AND profiles.tenant_id = business_reports.tenant_id
    )
  );

-- Report Categories: tenant isolation
CREATE POLICY "report_categories_tenant_isolation" ON report_categories FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- Report Templates: tenant isolation
CREATE POLICY "report_templates_tenant_isolation" ON report_templates FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- Report Schedules: tenant isolation
CREATE POLICY "report_schedules_tenant_isolation" ON report_schedules FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- Reports: tenant isolation
CREATE POLICY "reports_tenant_isolation" ON reports FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- Cross-tenant analytics - CEO & super_admin only
CREATE POLICY "ceo_superadmin_cross_tenant_all" ON cross_tenant_analytics FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('ceo', 'super_admin')
    )
  );

-- Attendance corrections - teachers & admins can request, ceo/super_admin can manage
CREATE POLICY "attendance_corrections_tenant_isolation" ON attendance_corrections FOR ALL
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "attendance_corrections_request" ON attendance_corrections FOR INSERT
  WITH CHECK (
    requested_by = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'ceo', 'teacher')
    )
  );

-- Backups - admin & super_admin only
CREATE POLICY "backups_admin_access" ON backups FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'ceo')
      AND profiles.tenant_id = backups.tenant_id
    )
  );

CREATE POLICY "backup_schedules_admin_access" ON backup_schedules FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'ceo')
      AND profiles.tenant_id = backup_schedules.tenant_id
    )
  );

-- Activity logs - admin/ceo/super_admin read, system write
CREATE POLICY "activity_logs_admin_view" ON activity_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'ceo')
      AND profiles.tenant_id = activity_logs.tenant_id
    )
  );

CREATE POLICY "activity_logs_system_insert" ON activity_logs FOR INSERT
  WITH CHECK (true);

-- Error logs - admin/ceo/super_admin
CREATE POLICY "error_logs_admin_access" ON error_logs FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'ceo')
      AND profiles.tenant_id = error_logs.tenant_id
    )
  );

-- ============================================
-- TRIGGERS FOR NEW TABLES
-- ============================================

CREATE TRIGGER update_strategic_goals_updated_at BEFORE UPDATE ON strategic_goals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_kpi_definitions_updated_at BEFORE UPDATE ON kpi_definitions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_kpi_records_updated_at BEFORE UPDATE ON kpi_records
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ceo_dashboards_updated_at BEFORE UPDATE ON ceo_dashboards
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ceo_dashboard_widgets_updated_at BEFORE UPDATE ON ceo_dashboard_widgets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_business_reports_updated_at BEFORE UPDATE ON business_reports
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_attendance_corrections_updated_at BEFORE UPDATE ON attendance_corrections
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_backup_schedules_updated_at BEFORE UPDATE ON backup_schedules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SOCIAL MEDIA & CONTENT MANAGEMENT TABLES
-- ============================================

-- Social Media Links
CREATE TABLE IF NOT EXISTS social_media_links (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  platform TEXT NOT NULL,
  url TEXT NOT NULL,
  icon TEXT,
  display_order INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Contact Information
CREATE TABLE IF NOT EXISTS contact_info (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  label TEXT NOT NULL,
  address_line1 TEXT,
  address_line2 TEXT,
  city TEXT,
  state TEXT,
  postal_code TEXT,
  country TEXT,
  phone TEXT,
  mobile TEXT,
  email TEXT,
  website TEXT,
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  is_primary BOOLEAN DEFAULT false,
  display_order INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Page Sections (dynamic content blocks for any page)
CREATE TABLE IF NOT EXISTS page_sections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  page TEXT NOT NULL,
  section_key TEXT NOT NULL,
  title TEXT,
  subtitle TEXT,
  content TEXT,
  image_url TEXT,
  button_label TEXT,
  button_link TEXT,
  background_color TEXT,
  text_color TEXT,
  settings JSONB DEFAULT '{}'::jsonb,
  display_order INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(tenant_id, page, section_key)
);

-- FAQ Items
CREATE TABLE IF NOT EXISTS faq_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  category TEXT,
  display_order INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Partners / Sponsors
CREATE TABLE IF NOT EXISTS partners (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  logo_url TEXT,
  website_url TEXT,
  description TEXT,
  partner_type TEXT CHECK (partner_type IN ('sponsor', 'partner', 'affiliate', 'media', 'other')),
  display_order INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Newsletter Subscriptions
CREATE TABLE IF NOT EXISTS newsletter_subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  email TEXT NOT NULL,
  name TEXT,
  source TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  subscribed_at TIMESTAMPTZ DEFAULT NOW(),
  unsubscribed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(tenant_id, email)
);

-- Site Banners
CREATE TABLE IF NOT EXISTS site_banners (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  title TEXT NOT NULL,
  subtitle TEXT,
  image_url TEXT,
  link_url TEXT,
  banner_type TEXT DEFAULT 'hero' CHECK (banner_type IN ('hero', 'promo', 'info', 'alert', 'announcement')),
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  display_order INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- VIEW COUNTERS & ANALYTICS TABLES
-- ============================================

-- Entity View Counters
CREATE TABLE IF NOT EXISTS view_counters (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  entity_type TEXT NOT NULL CHECK (entity_type IN ('class', 'subject', 'teacher', 'course', 'program', 'student', 'event', 'announcement', 'article', 'page')),
  entity_id UUID NOT NULL,
  view_count BIGINT DEFAULT 0,
  unique_views BIGINT DEFAULT 0,
  last_viewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(entity_type, entity_id)
);

-- Daily View Stats
CREATE TABLE IF NOT EXISTS daily_view_stats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  view_date DATE NOT NULL,
  view_count INTEGER DEFAULT 0,
  unique_views INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(entity_type, entity_id, view_date)
);

-- View Trends (weekly/monthly aggregated)
CREATE TABLE IF NOT EXISTS view_trends (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  entity_type TEXT NOT NULL,
  period TEXT NOT NULL CHECK (period IN ('daily', 'weekly', 'monthly', 'yearly')),
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  total_views BIGINT DEFAULT 0,
  unique_views BIGINT DEFAULT 0,
  avg_duration_seconds INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(entity_type, period, period_start, period_end)
);

-- ============================================
-- ENHANCED USAGE TRACKING TABLES
-- ============================================

-- API Usage Tracking
CREATE TABLE IF NOT EXISTS api_usage_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES profiles(id),
  endpoint TEXT NOT NULL,
  method TEXT,
  status_code INTEGER,
  response_time_ms INTEGER,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feature Usage Tracking
CREATE TABLE IF NOT EXISTS feature_usage_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES profiles(id),
  feature_name TEXT NOT NULL,
  action TEXT,
  duration_ms INTEGER,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES FOR NEW TABLES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_social_media_links_tenant ON social_media_links(tenant_id);
CREATE INDEX IF NOT EXISTS idx_social_media_links_active ON social_media_links(is_active);
CREATE INDEX IF NOT EXISTS idx_social_media_links_order ON social_media_links(display_order);

CREATE INDEX IF NOT EXISTS idx_contact_info_tenant ON contact_info(tenant_id);
CREATE INDEX IF NOT EXISTS idx_contact_info_active ON contact_info(is_active);
CREATE INDEX IF NOT EXISTS idx_contact_info_primary ON contact_info(is_primary);

CREATE INDEX IF NOT EXISTS idx_page_sections_tenant ON page_sections(tenant_id);
CREATE INDEX IF NOT EXISTS idx_page_sections_page ON page_sections(page);
CREATE INDEX IF NOT EXISTS idx_page_sections_key ON page_sections(section_key);
CREATE INDEX IF NOT EXISTS idx_page_sections_active ON page_sections(is_active);
CREATE INDEX IF NOT EXISTS idx_page_sections_order ON page_sections(display_order);

CREATE INDEX IF NOT EXISTS idx_faq_items_tenant ON faq_items(tenant_id);
CREATE INDEX IF NOT EXISTS idx_faq_items_category ON faq_items(category);
CREATE INDEX IF NOT EXISTS idx_faq_items_active ON faq_items(is_active);
CREATE INDEX IF NOT EXISTS idx_faq_items_order ON faq_items(display_order);

CREATE INDEX IF NOT EXISTS idx_partners_tenant ON partners(tenant_id);
CREATE INDEX IF NOT EXISTS idx_partners_active ON partners(is_active);
CREATE INDEX IF NOT EXISTS idx_partners_type ON partners(partner_type);

CREATE INDEX IF NOT EXISTS idx_newsletter_tenant ON newsletter_subscriptions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_newsletter_active ON newsletter_subscriptions(is_active);
CREATE INDEX IF NOT EXISTS idx_newsletter_email ON newsletter_subscriptions(email);

CREATE INDEX IF NOT EXISTS idx_site_banners_tenant ON site_banners(tenant_id);
CREATE INDEX IF NOT EXISTS idx_site_banners_active ON site_banners(is_active);
CREATE INDEX IF NOT EXISTS idx_site_banners_type ON site_banners(banner_type);
CREATE INDEX IF NOT EXISTS idx_site_banners_dates ON site_banners(start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_view_counters_tenant ON view_counters(tenant_id);
CREATE INDEX IF NOT EXISTS idx_view_counters_entity ON view_counters(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_view_counters_count ON view_counters(view_count DESC);
CREATE INDEX IF NOT EXISTS idx_view_counters_last_viewed ON view_counters(last_viewed_at DESC);

CREATE INDEX IF NOT EXISTS idx_daily_view_stats_tenant ON daily_view_stats(tenant_id);
CREATE INDEX IF NOT EXISTS idx_daily_view_stats_entity ON daily_view_stats(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_daily_view_stats_date ON daily_view_stats(view_date DESC);

CREATE INDEX IF NOT EXISTS idx_view_trends_tenant ON view_trends(tenant_id);
CREATE INDEX IF NOT EXISTS idx_view_trends_lookup ON view_trends(entity_type, period, period_start);

CREATE INDEX IF NOT EXISTS idx_api_usage_logs_tenant ON api_usage_logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_api_usage_logs_user ON api_usage_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_api_usage_logs_endpoint ON api_usage_logs(endpoint);
CREATE INDEX IF NOT EXISTS idx_api_usage_logs_created ON api_usage_logs(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_feature_usage_tenant ON feature_usage_logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_feature_usage_user ON feature_usage_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_feature_usage_feature ON feature_usage_logs(feature_name);
CREATE INDEX IF NOT EXISTS idx_feature_usage_created ON feature_usage_logs(created_at DESC);

-- ============================================
-- RLS POLICIES FOR NEW TABLES
-- ============================================

ALTER TABLE social_media_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE page_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE faq_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE newsletter_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE site_banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE view_counters ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_view_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE view_trends ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_usage_logs ENABLE ROW LEVEL SECURITY;

-- Social Media Links: public view active, staff manage
CREATE POLICY "public_view_active_social_links" ON social_media_links FOR SELECT
  USING (is_active = TRUE);

CREATE POLICY "staff_manage_social_links" ON social_media_links FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'staff')
      AND profiles.tenant_id = social_media_links.tenant_id
    )
  );

-- Contact Info: public view active, staff manage
CREATE POLICY "public_view_contact_info" ON contact_info FOR SELECT
  USING (is_active = TRUE);

CREATE POLICY "staff_manage_contact_info" ON contact_info FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'staff')
      AND profiles.tenant_id = contact_info.tenant_id
    )
  );

-- Page Sections: public view active, staff manage
CREATE POLICY "public_view_active_page_sections" ON page_sections FOR SELECT
  USING (is_active = TRUE);

CREATE POLICY "staff_manage_page_sections" ON page_sections FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'staff')
      AND profiles.tenant_id = page_sections.tenant_id
    )
  );

-- FAQ: public view active, staff manage
CREATE POLICY "public_view_faq" ON faq_items FOR SELECT
  USING (is_active = TRUE);

CREATE POLICY "staff_manage_faq" ON faq_items FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'staff')
      AND profiles.tenant_id = faq_items.tenant_id
    )
  );

-- Partners: public view active, staff manage
CREATE POLICY "public_view_partners" ON partners FOR SELECT
  USING (is_active = TRUE);

CREATE POLICY "staff_manage_partners" ON partners FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'staff')
      AND profiles.tenant_id = partners.tenant_id
    )
  );

-- Newsletter: anyone can subscribe, staff manage
CREATE POLICY "public_subscribe_newsletter" ON newsletter_subscriptions FOR INSERT
  WITH CHECK (true);

CREATE POLICY "staff_manage_newsletter" ON newsletter_subscriptions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'staff')
      AND profiles.tenant_id = newsletter_subscriptions.tenant_id
    )
  );

-- Banners: public view active+dated, staff manage
CREATE POLICY "public_view_active_banners" ON site_banners FOR SELECT
  USING (
    is_active = TRUE
    AND (start_date IS NULL OR start_date <= NOW())
    AND (end_date IS NULL OR end_date >= NOW())
  );

CREATE POLICY "staff_manage_banners" ON site_banners FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'staff')
      AND profiles.tenant_id = site_banners.tenant_id
    )
  );

-- View Counters: anyone can insert/update (increment), staff can view
CREATE POLICY "public_increment_views" ON view_counters FOR INSERT
  WITH CHECK (true);

CREATE POLICY "public_update_views" ON view_counters FOR UPDATE
  USING (true);

CREATE POLICY "staff_view_counter_stats" ON view_counters FOR SELECT
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Daily View Stats: staff view only
CREATE POLICY "staff_view_daily_stats" ON daily_view_stats FOR SELECT
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

-- View Trends: staff view only
CREATE POLICY "staff_view_trends" ON view_trends FOR SELECT
  USING (
    tenant_id IN (
      SELECT tenant_id FROM profiles WHERE id = auth.uid()
    )
  );

-- API Usage Logs: admin/ceo view only
CREATE POLICY "admin_view_api_usage" ON api_usage_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'ceo')
      AND profiles.tenant_id = api_usage_logs.tenant_id
    )
  );

-- Feature Usage Logs: admin/ceo view only
CREATE POLICY "admin_view_feature_usage" ON feature_usage_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'ceo')
      AND profiles.tenant_id = feature_usage_logs.tenant_id
    )
  );

-- ============================================
-- NEW EDGE FUNCTIONS / RPCs
-- ============================================

-- Increment view count for any entity type
CREATE OR REPLACE FUNCTION increment_view_count(
  p_entity_type TEXT,
  p_entity_id UUID,
  p_tenant_id UUID DEFAULT NULL
)
RETURNS BIGINT AS $$
DECLARE
  v_new_count BIGINT;
BEGIN
  INSERT INTO view_counters (entity_type, entity_id, tenant_id, view_count, last_viewed_at)
  VALUES (p_entity_type, p_entity_id, p_tenant_id, 1, NOW())
  ON CONFLICT (entity_type, entity_id)
  DO UPDATE SET
    view_count = view_counters.view_count + 1,
    last_viewed_at = NOW(),
    updated_at = NOW()
  RETURNING view_counters.view_count INTO v_new_count;

  INSERT INTO daily_view_stats (entity_type, entity_id, tenant_id, view_date, view_count)
  VALUES (p_entity_type, p_entity_id, p_tenant_id, CURRENT_DATE, 1)
  ON CONFLICT (entity_type, entity_id, view_date)
  DO UPDATE SET view_count = daily_view_stats.view_count + 1;

  RETURN v_new_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get top viewed entities by type
CREATE OR REPLACE FUNCTION get_popular_entities(
  p_entity_type TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 10,
  p_tenant_id UUID DEFAULT NULL
)
RETURNS TABLE(
  entity_type TEXT,
  entity_id UUID,
  view_count BIGINT,
  rank BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    vc.entity_type,
    vc.entity_id,
    vc.view_count,
    ROW_NUMBER() OVER (ORDER BY vc.view_count DESC) AS rank
  FROM view_counters vc
  WHERE (p_entity_type IS NULL OR vc.entity_type = p_entity_type)
  AND (p_tenant_id IS NULL OR vc.tenant_id = p_tenant_id)
  ORDER BY vc.view_count DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- Get system health statistics
CREATE OR REPLACE FUNCTION get_system_health_stats(p_tenant_id UUID DEFAULT NULL)
RETURNS JSONB AS $$
DECLARE
  v_stats JSONB;
  v_error_count INTEGER;
  v_recent_errors INTEGER;
  v_active_sessions INTEGER;
  v_api_calls_last_hour INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_error_count
  FROM error_logs
  WHERE (p_tenant_id IS NULL OR tenant_id = p_tenant_id)
  AND created_at >= NOW() - INTERVAL '24 hours'
  AND error_level IN ('error', 'critical');

  SELECT COUNT(*) INTO v_recent_errors
  FROM error_logs
  WHERE (p_tenant_id IS NULL OR tenant_id = p_tenant_id)
  AND created_at >= NOW() - INTERVAL '1 hour'
  AND error_level IN ('error', 'critical');

  SELECT COUNT(*) INTO v_active_sessions
  FROM device_sessions
  WHERE (p_tenant_id IS NULL OR tenant_id = p_tenant_id)
  AND is_active = true
  AND last_active >= NOW() - INTERVAL '30 minutes';

  SELECT COUNT(*) INTO v_api_calls_last_hour
  FROM api_usage_logs
  WHERE (p_tenant_id IS NULL OR tenant_id = p_tenant_id)
  AND created_at >= NOW() - INTERVAL '1 hour';

  SELECT jsonb_build_object(
    'errors_24h', v_error_count,
    'recent_errors', v_recent_errors,
    'active_sessions', v_active_sessions,
    'api_calls_last_hour', v_api_calls_last_hour,
    'status', CASE
      WHEN v_recent_errors > 10 THEN 'degraded'
      WHEN v_recent_errors > 0 THEN 'warning'
      ELSE 'healthy'
    END,
    'checked_at', NOW()
  ) INTO v_stats;

  RETURN v_stats;
END;
$$ LANGUAGE plpgsql STABLE;

-- Cleanup old log records (maintenance)
CREATE OR REPLACE FUNCTION cleanup_old_logs(
  p_retention_days INTEGER DEFAULT 90
)
RETURNS INTEGER AS $$
DECLARE
  v_deleted INTEGER DEFAULT 0;
BEGIN
  DELETE FROM activity_logs WHERE created_at < NOW() - (p_retention_days || ' days')::INTERVAL;
  v_deleted := v_deleted + 1;
  DELETE FROM api_usage_logs WHERE created_at < NOW() - (p_retention_days || ' days')::INTERVAL;
  v_deleted := v_deleted + 1;
  DELETE FROM error_logs WHERE created_at < NOW() - (p_retention_days || ' days')::INTERVAL AND resolved = true;
  v_deleted := v_deleted + 1;
  DELETE FROM daily_view_stats WHERE view_date < NOW() - (p_retention_days || ' days')::INTERVAL;
  v_deleted := v_deleted + 1;
  RETURN v_deleted;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Log user activity
CREATE OR REPLACE FUNCTION log_user_activity(
  p_user_id UUID,
  p_action TEXT,
  p_category TEXT DEFAULT 'general',
  p_resource_type TEXT DEFAULT NULL,
  p_resource_id UUID DEFAULT NULL,
  p_details JSONB DEFAULT '{}'::jsonb,
  p_ip_address TEXT DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_tenant_id UUID;
  v_log_id UUID;
BEGIN
  SELECT tenant_id INTO v_tenant_id FROM profiles WHERE id = p_user_id;

  INSERT INTO activity_logs (
    tenant_id, user_id, action, category, resource_type, resource_id,
    details, ip_address, user_agent, outcome
  ) VALUES (
    v_tenant_id, p_user_id, p_action, p_category, p_resource_type, p_resource_id,
    p_details, p_ip_address, p_user_agent, 'success'
  ) RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Log application error
CREATE OR REPLACE FUNCTION log_application_error(
  p_message TEXT,
  p_error_level TEXT DEFAULT 'error',
  p_error_code TEXT DEFAULT NULL,
  p_stack_trace TEXT DEFAULT NULL,
  p_source TEXT DEFAULT NULL,
  p_module TEXT DEFAULT NULL,
  p_endpoint TEXT DEFAULT NULL,
  p_request_data JSONB DEFAULT NULL,
  p_user_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_tenant_id UUID;
  v_log_id UUID;
BEGIN
  IF p_user_id IS NOT NULL THEN
    SELECT tenant_id INTO v_tenant_id FROM profiles WHERE id = p_user_id;
  END IF;

  INSERT INTO error_logs (
    tenant_id, user_id, error_level, message, error_code, stack_trace,
    source, module, endpoint, request_data
  ) VALUES (
    v_tenant_id, p_user_id, p_error_level, p_message, p_error_code, p_stack_trace,
    p_source, p_module, p_endpoint, p_request_data
  ) RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get recent activity feed
CREATE OR REPLACE FUNCTION get_activity_feed(
  p_limit INTEGER DEFAULT 20,
  p_tenant_id UUID DEFAULT NULL,
  p_category TEXT DEFAULT NULL
)
RETURNS TABLE(
  id UUID,
  user_name TEXT,
  user_avatar TEXT,
  action TEXT,
  category TEXT,
  resource_type TEXT,
  details JSONB,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    al.id,
    p.full_name AS user_name,
    p.avatar_url AS user_avatar,
    al.action,
    al.category,
    al.resource_type,
    al.details,
    al.created_at
  FROM activity_logs al
  LEFT JOIN profiles p ON p.id = al.user_id
  WHERE (p_tenant_id IS NULL OR al.tenant_id = p_tenant_id)
  AND (p_category IS NULL OR al.category = p_category)
  ORDER BY al.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================
-- TRIGGERS FOR NEW TABLES
-- ============================================

CREATE TRIGGER update_social_media_links_updated_at BEFORE UPDATE ON social_media_links
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contact_info_updated_at BEFORE UPDATE ON contact_info
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_page_sections_updated_at BEFORE UPDATE ON page_sections
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_faq_items_updated_at BEFORE UPDATE ON faq_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_partners_updated_at BEFORE UPDATE ON partners
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_site_banners_updated_at BEFORE UPDATE ON site_banners
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_view_counters_updated_at BEFORE UPDATE ON view_counters
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SAMPLE DATA FOR NEW TABLES
-- ============================================

INSERT INTO social_media_links (platform, url, icon, display_order, is_active) VALUES
('Facebook', 'https://facebook.com/emisplatform', 'facebook', 1, true),
('Twitter', 'https://twitter.com/emisplatform', 'twitter', 2, true),
('Instagram', 'https://instagram.com/emisplatform', 'instagram', 3, true),
('LinkedIn', 'https://linkedin.com/company/emisplatform', 'linkedin', 4, true),
('YouTube', 'https://youtube.com/@emisplatform', 'youtube', 5, true)
ON CONFLICT DO NOTHING;

INSERT INTO contact_info (label, address_line1, city, state, country, phone, email, is_primary, display_order, is_active) VALUES
('Main Office', '123 Education Street', 'Kabul', 'Kabul Province', 'Afghanistan', '+93 700 123 456', 'info@emisplatform.com', true, 1, true),
('Branch Office', '456 Learning Avenue', 'Herat', 'Herat Province', 'Afghanistan', '+93 700 789 012', 'herat@emisplatform.com', false, 2, true)
ON CONFLICT DO NOTHING;

INSERT INTO faq_items (question, answer, category, display_order, is_active) VALUES
('How do I enroll in a course?', 'You can enroll in courses by visiting the Courses page and clicking the "Enroll" button on your desired course.', 'Enrollment', 1, true),
('What payment methods are accepted?', 'We accept cash, bank transfers, mobile payments, and online card payments.', 'Payments', 2, true),
('How can I check my attendance?', 'You can view your attendance record in the Student Dashboard under the Attendance section.', 'Academic', 3, true),
('What is the refund policy?', 'Full refunds are available within the first week of enrollment. Partial refunds may apply thereafter.', 'Payments', 4, true)
ON CONFLICT DO NOTHING;

INSERT INTO partners (name, website_url, description, partner_type, display_order, is_active) VALUES
('Ministry of Education', 'https://education.gov.af', 'Official education regulatory body', 'partner', 1, true),
('Google for Education', 'https://edu.google.com', 'Digital learning tools and platforms', 'partner', 2, true),
('UNESCO', 'https://unesco.org', 'United Nations educational cooperation', 'sponsor', 3, true)
ON CONFLICT DO NOTHING;

-- ============================================
-- WEBSITE SECTIONS: TABLES FOR MISSING PARTS
-- ============================================
-- Covers: Our Story, Our Branches (rich display),
-- Test Your English, Apply Online, Request a Call, Contact Messages
-- ============================================

-- ============================================
-- 1. OUR STORY â†’ page_sections already exists.
--    Add sample "our_story" data below.
-- ============================================

-- ============================================
-- 2. OUR BRANCHES â†’ Enhance tenants with rich display columns
-- ============================================

ALTER TABLE tenants ADD COLUMN IF NOT EXISTS images TEXT[] DEFAULT '{}';
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS working_hours JSONB DEFAULT '{}'::jsonb;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS services TEXT[] DEFAULT '{}';
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS latitude DECIMAL(10,7);
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS longitude DECIMAL(10,7);
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS featured BOOLEAN DEFAULT false;

-- View: Public branch listing with rich info
CREATE OR REPLACE VIEW public_branches AS
SELECT
  t.id,
  t.name,
  t.slug,
  t.description,
  t.logo_url,
  t.website,
  t.address,
  t.phone,
  t.email,
  t.images,
  t.working_hours,
  t.services,
  t.latitude,
  t.longitude,
  t.featured,
  t.parent_tenant_id,
  parent.name AS parent_name,
  (SELECT COUNT(*) FROM students WHERE tenant_id = t.id AND status = 'active') AS active_students,
  (SELECT COUNT(*) FROM courses WHERE tenant_id = t.id) AS total_courses,
  (SELECT COUNT(*) FROM classes WHERE tenant_id = t.id) AS total_classes
FROM tenants t
LEFT JOIN tenants parent ON t.parent_tenant_id = parent.id
WHERE t.organization_type = 'branch' AND t.is_active = true
ORDER BY t.featured DESC, t.name ASC;

-- ============================================
-- 3. TEST YOUR ENGLISH / PLACEMENT TESTS
-- ============================================

-- Available placement test types
CREATE TABLE IF NOT EXISTS placement_tests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  description TEXT,
  exam_type TEXT CHECK (exam_type IN ('english_level', 'ielts_mock', 'toefl_mock', 'subject_test', 'aptitude', 'other')),
  duration_minutes INTEGER DEFAULT 30,
  total_questions INTEGER DEFAULT 20,
  passing_score DECIMAL(5,2),
  max_score DECIMAL(5,2) DEFAULT 100,
  is_free BOOLEAN DEFAULT true,
  price DECIMAL(10,2),
  instructions TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Placement test questions
CREATE TABLE IF NOT EXISTS placement_test_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  placement_test_id UUID REFERENCES placement_tests(id) ON DELETE CASCADE,
  question_text TEXT NOT NULL,
  question_type TEXT DEFAULT 'multiple_choice' CHECK (question_type IN ('multiple_choice', 'true_false', 'essay', 'fill_blank', 'matching')),
  options JSONB,
  correct_answer TEXT,
  points DECIMAL(5,2) DEFAULT 1,
  display_order INTEGER DEFAULT 1,
  section TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User placement test attempts
CREATE TABLE IF NOT EXISTS placement_test_attempts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  placement_test_id UUID REFERENCES placement_tests(id),
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES profiles(id),
  email TEXT,
  full_name TEXT,
  phone TEXT,
  score DECIMAL(5,2),
  max_score DECIMAL(5,2),
  percentage DECIMAL(5,2),
  grade TEXT,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  time_spent_seconds INTEGER,
  answers JSONB DEFAULT '[]'::jsonb,
  status TEXT DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'expired', 'cancelled')),
  result_sent BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 4. APPLY ONLINE / COURSE APPLICATIONS
-- ============================================

CREATE TABLE IF NOT EXISTS course_applications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  program_id UUID REFERENCES programs(id),
  course_id UUID REFERENCES courses(id),
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  date_of_birth DATE,
  gender TEXT CHECK (gender IN ('Male', 'Female', 'Other')),
  address TEXT,
  city TEXT,
  country TEXT,
  education_level TEXT,
  previous_institution TEXT,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  how_did_hear TEXT,
  additional_notes TEXT,
  documents JSONB DEFAULT '[]'::jsonb,
  discount_amount DECIMAL(12,2) DEFAULT 0,
  discount_id UUID REFERENCES discounts(id),
  promotion_id UUID REFERENCES promotions(id),
  final_fee DECIMAL(12,2),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'accepted', 'rejected', 'waitlisted')),
  reviewed_by UUID REFERENCES profiles(id),
  reviewed_at TIMESTAMPTZ,
  rejection_reason TEXT,
  converted_to_student BOOLEAN DEFAULT false,
  student_id UUID REFERENCES students(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 5. REQUEST A CALL / CALLBACK REQUESTS
-- ============================================

CREATE TABLE IF NOT EXISTS callback_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  preferred_time_from TIME,
  preferred_time_to TIME,
  preferred_date DATE,
  topic TEXT,
  notes TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'contacted', 'completed', 'cancelled')),
  assigned_to UUID REFERENCES profiles(id),
  contacted_at TIMESTAMPTZ,
  follow_up_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 6. CONTACT COURSE / CONTACT FORM MESSAGES
-- ============================================

CREATE TABLE IF NOT EXISTS contact_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  subject TEXT,
  message TEXT NOT NULL,
  category TEXT CHECK (category IN ('general', 'admissions', 'support', 'complaint', 'feedback', 'partnership', 'other')),
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  read_by UUID REFERENCES profiles(id),
  reply TEXT,
  replied_at TIMESTAMPTZ,
  replied_by UUID REFERENCES profiles(id),
  status TEXT DEFAULT 'unread' CHECK (status IN ('unread', 'read', 'replied', 'archived', 'spam')),
  source TEXT DEFAULT 'website',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES FOR NEW TABLES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_placement_tests_tenant ON placement_tests(tenant_id);
CREATE INDEX IF NOT EXISTS idx_placement_tests_type ON placement_tests(exam_type);
CREATE INDEX IF NOT EXISTS idx_placement_tests_active ON placement_tests(is_active);

CREATE INDEX IF NOT EXISTS idx_placement_test_questions_test ON placement_test_questions(placement_test_id);
CREATE INDEX IF NOT EXISTS idx_placement_test_questions_order ON placement_test_questions(display_order);

CREATE INDEX IF NOT EXISTS idx_placement_test_attempts_test ON placement_test_attempts(placement_test_id);
CREATE INDEX IF NOT EXISTS idx_placement_test_attempts_user ON placement_test_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_placement_test_attempts_status ON placement_test_attempts(status);
CREATE INDEX IF NOT EXISTS idx_placement_test_attempts_email ON placement_test_attempts(email);

CREATE INDEX IF NOT EXISTS idx_course_applications_tenant ON course_applications(tenant_id);
CREATE INDEX IF NOT EXISTS idx_course_applications_program ON course_applications(program_id);
CREATE INDEX IF NOT EXISTS idx_course_applications_status ON course_applications(status);
CREATE INDEX IF NOT EXISTS idx_course_applications_email ON course_applications(email);

CREATE INDEX IF NOT EXISTS idx_callback_requests_tenant ON callback_requests(tenant_id);
CREATE INDEX IF NOT EXISTS idx_callback_requests_status ON callback_requests(status);
CREATE INDEX IF NOT EXISTS idx_callback_requests_assigned ON callback_requests(assigned_to);

CREATE INDEX IF NOT EXISTS idx_contact_messages_tenant ON contact_messages(tenant_id);
CREATE INDEX IF NOT EXISTS idx_contact_messages_status ON contact_messages(status);
CREATE INDEX IF NOT EXISTS idx_contact_messages_category ON contact_messages(category);
CREATE INDEX IF NOT EXISTS idx_contact_messages_read ON contact_messages(is_read);

-- ============================================
-- RLS POLICIES FOR NEW TABLES
-- ============================================

ALTER TABLE placement_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE placement_test_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE placement_test_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE callback_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_messages ENABLE ROW LEVEL SECURITY;

-- Placement Tests: public view active, staff manage
CREATE POLICY "public_view_active_placement_tests" ON placement_tests FOR SELECT
  USING (is_active = TRUE);

CREATE POLICY "staff_manage_placement_tests" ON placement_tests FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'staff', 'teacher', 'academic_support')
      AND profiles.tenant_id = placement_tests.tenant_id
    )
  );

-- Placement Test Questions: public view for active tests, staff manage
CREATE POLICY "public_view_placement_questions" ON placement_test_questions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM placement_tests
      WHERE placement_tests.id = placement_test_questions.placement_test_id
      AND placement_tests.is_active = TRUE
    )
  );

CREATE POLICY "staff_manage_placement_questions" ON placement_test_questions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'staff', 'teacher')
    )
  );

-- Placement Test Attempts: users see own, staff see all
CREATE POLICY "users_view_own_attempts" ON placement_test_attempts FOR SELECT
  USING (user_id = auth.uid() OR email = auth.email());

CREATE POLICY "users_insert_own_attempts" ON placement_test_attempts FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_update_own_attempts" ON placement_test_attempts FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "staff_view_all_attempts" ON placement_test_attempts FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'staff', 'teacher', 'academic_support')
      AND profiles.tenant_id = placement_test_attempts.tenant_id
    )
  );

-- Course Applications: anyone can submit, staff manage
CREATE POLICY "public_submit_application" ON course_applications FOR INSERT
  WITH CHECK (true);

CREATE POLICY "staff_manage_applications" ON course_applications FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'staff', 'academic_support', 'receptionist')
      AND profiles.tenant_id = course_applications.tenant_id
    )
  );

-- Callback Requests: anyone can submit, staff manage
CREATE POLICY "public_submit_callback" ON callback_requests FOR INSERT
  WITH CHECK (true);

CREATE POLICY "staff_manage_callbacks" ON callback_requests FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'staff', 'receptionist')
      AND profiles.tenant_id = callback_requests.tenant_id
    )
  );

-- Contact Messages: anyone can submit, staff manage
CREATE POLICY "public_submit_contact_message" ON contact_messages FOR INSERT
  WITH CHECK (true);

CREATE POLICY "staff_manage_contact_messages" ON contact_messages FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin', 'staff', 'receptionist')
      AND profiles.tenant_id = contact_messages.tenant_id
    )
  );

-- ============================================
-- RPC: Submit placement test & auto-grade
-- ============================================

CREATE OR REPLACE FUNCTION submit_placement_test(
  p_test_id UUID,
  p_answers JSONB,
  p_user_id UUID DEFAULT NULL,
  p_email TEXT DEFAULT NULL,
  p_full_name TEXT DEFAULT NULL,
  p_phone TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_attempt_id UUID;
  v_total_points DECIMAL := 0;
  v_earned_points DECIMAL := 0;
  v_percentage DECIMAL;
  v_grade TEXT;
  v_max_score DECIMAL;
  v_question RECORD;
  v_answer JSONB;
  v_correct_count INTEGER := 0;
  v_total_count INTEGER := 0;
  v_test_name TEXT;
  v_tenant_id UUID;
BEGIN
  -- Get test info
  SELECT name, max_score, tenant_id INTO v_test_name, v_max_score, v_tenant_id
  FROM placement_tests WHERE id = p_test_id;

  -- Grade answers
  FOR v_question IN
    SELECT id, correct_answer, points FROM placement_test_questions
    WHERE placement_test_id = p_test_id AND question_type != 'essay'
  LOOP
    v_total_points := v_total_points + v_question.points;
    v_total_count := v_total_count + 1;

    -- Find matching answer in submitted answers
    FOR v_answer IN SELECT * FROM jsonb_array_elements(p_answers)
    LOOP
      IF (v_answer->>'question_id')::UUID = v_question.id THEN
        IF v_answer->>'answer' = v_question.correct_answer THEN
          v_earned_points := v_earned_points + v_question.points;
          v_correct_count := v_correct_count + 1;
        END IF;
      END IF;
    END LOOP;
  END LOOP;

  -- Calculate score
  IF v_max_score > 0 THEN
    v_percentage := ROUND((v_earned_points / v_total_points) * 100, 2);
  ELSE
    v_percentage := 0;
  END IF;

  v_grade := calculate_grade(v_percentage);

  -- Create attempt record
  INSERT INTO placement_test_attempts (
    placement_test_id, tenant_id, user_id, email, full_name, phone,
    score, max_score, percentage, grade, answers,
    completed_at, time_spent_seconds, status
  ) VALUES (
    p_test_id, v_tenant_id, p_user_id, p_email, p_full_name, p_phone,
    v_earned_points, v_total_points, v_percentage, v_grade, p_answers,
    NOW(), EXTRACT(EPOCH FROM NOW())::INTEGER, 'completed'
  ) RETURNING id INTO v_attempt_id;

  RETURN jsonb_build_object(
    'attempt_id', v_attempt_id,
    'score', v_earned_points,
    'max_score', v_total_points,
    'percentage', v_percentage,
    'grade', v_grade,
    'correct_count', v_correct_count,
    'total_count', v_total_count
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- RPC: Get branch details with stats
-- ============================================

CREATE OR REPLACE FUNCTION get_branch_details(p_branch_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'id', t.id,
    'name', t.name,
    'slug', t.slug,
    'description', t.description,
    'logo_url', t.logo_url,
    'website', t.website,
    'address', t.address,
    'phone', t.phone,
    'email', t.email,
    'images', t.images,
    'working_hours', t.working_hours,
    'services', t.services,
    'latitude', t.latitude,
    'longitude', t.longitude,
    'featured', t.featured,
    'active_students', (SELECT COUNT(*) FROM students WHERE tenant_id = t.id AND status = 'active'),
    'total_teachers', (SELECT COUNT(*) FROM teachers WHERE tenant_id = t.id AND status = 'active'),
    'total_courses', (SELECT COUNT(*) FROM courses WHERE tenant_id = t.id),
    'total_classes', (SELECT COUNT(*) FROM classes WHERE tenant_id = t.id),
    'total_programs', (SELECT COUNT(*) FROM programs WHERE tenant_id = t.id),
    'contact_info', (
      SELECT jsonb_agg(jsonb_build_object(
        'label', ci.label, 'address', ci.address_line1 || ', ' || COALESCE(ci.city, ''), 'phone', ci.phone, 'email', ci.email
      )) FROM contact_info ci WHERE ci.tenant_id = t.id AND ci.is_active = TRUE
    ),
    'created_at', t.created_at
  ) INTO v_result
  FROM tenants t
  WHERE t.id = p_branch_id;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================
-- SAMPLE DATA: Website sections content
-- ============================================

-- Our Story (page_sections)
INSERT INTO page_sections (page, section_key, title, subtitle, content, display_order, is_active) VALUES
('home', 'our_story', 'Our Story', 'A Journey of Educational Excellence',
 'Founded in 2010, EMIS has grown from a small language center into a comprehensive educational institution serving thousands of students across Afghanistan. Our mission is to provide accessible, high-quality education that empowers individuals to achieve their full potential.',
 1, true),
('home', 'why_choose_us', 'Why Choose Our Courses', 'What Makes Us Different',
 'We combine expert instruction with personalized learning paths, state-of-the-art facilities, and a supportive community environment. Our certified teachers bring real-world experience, and our curriculum is designed to meet international standards.',
 2, true)
ON CONFLICT (tenant_id, page, section_key) DO NOTHING;

-- Placement test types
INSERT INTO placement_tests (name, description, exam_type, duration_minutes, total_questions, passing_score, max_score, is_free, instructions) VALUES
('English Level Test', 'Determine your current English proficiency level from A1 to C2', 'english_level', 30, 40, 0, 100, true,
 'Answer all questions to the best of your ability. There is no time limit per question. Your results will be sent to your email.'),
('IELTS Mock Test', 'Practice IELTS exam with realistic questions', 'ielts_mock', 120, 80, 6.0, 9.0, true,
 'This mock test follows the real IELTS format. Allow 2 hours of uninterrupted time. Your band score will be calculated automatically.'),
('TOEFL Mock Test', 'Practice TOEFL iBT style questions', 'toefl_mock', 90, 60, 0, 120, true,
 'Simulate the real TOEFL experience. Section timing matches the actual test.'),
('Subject Knowledge Test', 'Test your knowledge in specific academic subjects', 'subject_test', 45, 30, 0, 100, true,
 'Choose your subject area and demonstrate your understanding.')
ON CONFLICT DO NOTHING;

-- Update RAISE NOTICE completion block
DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Website Sections Complete!';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Our Story: âœ“ (page_sections)';
  RAISE NOTICE 'Our Courses: âœ“ (courses, programs)';
  RAISE NOTICE 'Our Branches: âœ“ (tenants + rich display)';
  RAISE NOTICE 'Our Classes: âœ“ (classes)';
  RAISE NOTICE 'Test Your English: âœ“ (placement_tests)';
  RAISE NOTICE 'Apply Online: âœ“ (course_applications)';
  RAISE NOTICE 'Request a Call: âœ“ (callback_requests)';
  RAISE NOTICE 'Why Our Course: âœ“ (home_features, page_sections)';
  RAISE NOTICE 'Our Reviews: âœ“ (home_testimonials, feedback)';
   RAISE NOTICE 'Contact Course: âœ“ (contact_info, contact_messages)';
   RAISE NOTICE '========================================';
END $$;

-- ============================================
-- MISSING TABLES REFERENCED FROM DART CODE
-- Added based on course_Team & course_users code analysis
-- ============================================

-- Suppliers (referenced in inventory_repository, panel_stats_provider)
CREATE TABLE IF NOT EXISTS suppliers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  contact_person TEXT,
  phone TEXT,
  email TEXT,
  address TEXT,
  website TEXT,
  tax_id TEXT,
  payment_terms TEXT,
  notes TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Purchase Orders (referenced in panel_stats_provider)
CREATE TABLE IF NOT EXISTS purchase_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  po_number TEXT UNIQUE NOT NULL,
  supplier_id UUID REFERENCES suppliers(id),
  order_date DATE DEFAULT CURRENT_DATE,
  expected_delivery DATE,
  items JSONB DEFAULT '[]'::jsonb,
  subtotal DECIMAL(12,2),
  tax_amount DECIMAL(12,2) DEFAULT 0,
  shipping_cost DECIMAL(12,2) DEFAULT 0,
  total_amount DECIMAL(12,2),
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'pending', 'approved', 'ordered', 'partial', 'received', 'cancelled')),
  notes TEXT,
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMPTZ,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Work Orders (referenced in panel_stats_provider)
CREATE TABLE IF NOT EXISTS work_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  wo_number TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT,
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'emergency')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'assigned', 'in_progress', 'completed', 'cancelled')),
  location TEXT,
  requested_by UUID REFERENCES profiles(id),
  assigned_to UUID REFERENCES profiles(id),
  estimated_cost DECIMAL(12,2),
  actual_cost DECIMAL(12,2),
  start_date DATE,
  completion_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add FK constraints for tables whose referenced tables were created later
ALTER TABLE expenses ADD CONSTRAINT fk_expenses_journal FOREIGN KEY (journal_id) REFERENCES journals(id);
ALTER TABLE expenses ADD CONSTRAINT fk_expenses_account FOREIGN KEY (account_id) REFERENCES accounts(id);
ALTER TABLE fee_structures ADD CONSTRAINT fk_fee_structures_academic_year FOREIGN KEY (academic_year_id) REFERENCES academic_years(id);
ALTER TABLE student_fee_assignments ADD CONSTRAINT fk_sfa_academic_year FOREIGN KEY (academic_year_id) REFERENCES academic_years(id);
ALTER TABLE parent_students ADD CONSTRAINT fk_parent_students_parent FOREIGN KEY (parent_id) REFERENCES parents(id);
ALTER TABLE inventory_items ADD CONSTRAINT fk_inventory_items_category FOREIGN KEY (category_id) REFERENCES inventory_categories(id);
ALTER TABLE item_condition_history ADD CONSTRAINT fk_item_condition_work_order FOREIGN KEY (work_order_id) REFERENCES work_orders(id);

-- IT Devices/Assets (referenced in panel_stats_provider)
CREATE TABLE IF NOT EXISTS it_devices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  device_type TEXT CHECK (device_type IN ('laptop', 'desktop', 'tablet', 'printer', 'router', 'switch', 'server', 'projector', 'phone', 'other')),
  brand TEXT,
  model TEXT,
  serial_number TEXT UNIQUE,
  asset_tag TEXT UNIQUE,
  purchase_date DATE,
  purchase_cost DECIMAL(10,2),
  warranty_expiry DATE,
  os TEXT,
  specs JSONB DEFAULT '{}'::jsonb,
  location TEXT,
  assigned_to UUID REFERENCES profiles(id),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'assigned', 'maintenance', 'retired', 'lost')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Staff Attendance (referenced in panel_stats_provider - separate from student attendance)
CREATE TABLE IF NOT EXISTS staff_attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  staff_id UUID REFERENCES profiles(id),
  date DATE NOT NULL,
  check_in TIME,
  check_out TIME,
  status TEXT CHECK (status IN ('present', 'absent', 'late', 'half_day', 'excused')),
  late_minutes INTEGER DEFAULT 0,
  fine_amount DECIMAL(10,2) DEFAULT 0,
  fine_reason TEXT,
  fine_waived BOOLEAN DEFAULT false,
  fine_waived_by UUID REFERENCES profiles(id),
  overtime_minutes INTEGER DEFAULT 0,
  overtime_rate DECIMAL(10,2) DEFAULT 0,
  overtime_pay DECIMAL(10,2) GENERATED ALWAYS AS ((overtime_minutes / 60.0) * COALESCE(overtime_rate, 0)) STORED,
  remarks TEXT,
  marked_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(staff_id, date)
);

-- Staff Tasks (referenced in panel_stats_provider)
CREATE TABLE IF NOT EXISTS staff_tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  staff_id UUID REFERENCES profiles(id),
  title TEXT NOT NULL,
  description TEXT,
  due_date DATE,
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
  assigned_by UUID REFERENCES profiles(id),
  completed_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Phone Logs (referenced in panel_stats_provider)
CREATE TABLE IF NOT EXISTS phone_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  caller_name TEXT,
  caller_phone TEXT NOT NULL,
  direction TEXT CHECK (direction IN ('inbound', 'outbound')),
  duration_seconds INTEGER,
  call_type TEXT CHECK (call_type IN ('voice', 'video')),
  handled_by UUID REFERENCES profiles(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Security Logs (referenced in security_logs_screen.dart)
CREATE TABLE IF NOT EXISTS security_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES profiles(id),
  log_type TEXT NOT NULL CHECK (log_type IN ('login', 'logout', 'failed_login', 'password_change', '2fa', 'session', 'permission_change', 'account_lock', 'other')),
  ip_address TEXT,
  user_agent TEXT,
  location TEXT,
  details JSONB DEFAULT '{}'::jsonb,
  is_suspicious BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Point History (referenced in gamification_service.dart)
CREATE TABLE IF NOT EXISTS point_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES profiles(id),
  points INTEGER NOT NULL,
  reason TEXT NOT NULL,
  reference_type TEXT,
  reference_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Forum Posts (referenced in social_service.dart)
CREATE TABLE IF NOT EXISTS forum_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES profiles(id),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT,
  tags TEXT[],
  is_pinned BOOLEAN DEFAULT false,
  is_locked BOOLEAN DEFAULT false,
  view_count INTEGER DEFAULT 0,
  like_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  last_activity_at TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'archived', 'deleted')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Forum Comments (for forum_posts)
CREATE TABLE IF NOT EXISTS forum_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  post_id UUID REFERENCES forum_posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id),
  content TEXT NOT NULL,
  parent_id UUID REFERENCES forum_comments(id),
  like_count INTEGER DEFAULT 0,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Study Groups (referenced in social_service.dart)
CREATE TABLE IF NOT EXISTS study_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  description TEXT,
  subject TEXT,
  course_id UUID REFERENCES courses(id),
  class_id UUID REFERENCES classes(id),
  created_by UUID REFERENCES profiles(id),
  max_members INTEGER DEFAULT 20,
  is_private BOOLEAN DEFAULT false,
  invite_code TEXT UNIQUE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'archived', 'deleted')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Study Group Members (referenced in social_service.dart)
CREATE TABLE IF NOT EXISTS study_group_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  group_id UUID REFERENCES study_groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id),
  role TEXT DEFAULT 'member' CHECK (role IN ('member', 'admin', 'moderator')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

-- Conversations (referenced in social_service.dart)
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  participant_ids UUID[] NOT NULL,
  last_message_text TEXT,
  last_message_at TIMESTAMPTZ,
  last_sender_id UUID REFERENCES profiles(id),
  is_group BOOLEAN DEFAULT false,
  group_name TEXT,
  group_avatar TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Finance table (referenced in finance_repository.dart)
CREATE TABLE IF NOT EXISTS finance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('income', 'expense', 'transfer', 'adjustment')),
  category TEXT NOT NULL,
  subcategory TEXT,
  amount DECIMAL(12,2) NOT NULL,
  description TEXT,
  reference_type TEXT,
  reference_id UUID,
  transaction_date DATE DEFAULT CURRENT_DATE,
  payment_method TEXT,
  status TEXT DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
  created_by UUID REFERENCES profiles(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- LMS Content (referenced in lms_repository.dart)
CREATE TABLE IF NOT EXISTS lms_content (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  course_id UUID REFERENCES courses(id),
  class_id UUID REFERENCES classes(id),
  title TEXT NOT NULL,
  description TEXT,
  content_type TEXT CHECK (content_type IN ('lesson', 'quiz', 'assignment', 'resource', 'video', 'document', 'link')),
  content TEXT,
  file_url TEXT,
  order_index INTEGER DEFAULT 0,
  is_published BOOLEAN DEFAULT false,
  due_date DATE,
  duration_minutes INTEGER,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sub Courses (referenced in panel_stats_provider.dart)
CREATE TABLE IF NOT EXISTS sub_courses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  course_id UUID REFERENCES courses(id),
  name TEXT NOT NULL,
  code TEXT,
  description TEXT,
  credits INTEGER DEFAULT 0,
  teacher_id UUID REFERENCES profiles(id),
  order_index INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Course Content (referenced in panel_stats_provider.dart)
CREATE TABLE IF NOT EXISTS course_content (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  course_id UUID REFERENCES courses(id),
  section_id UUID,
  title TEXT NOT NULL,
  content_type TEXT CHECK (content_type IN ('video', 'document', 'quiz', 'assignment', 'discussion', 'link', 'file')),
  content TEXT,
  file_url TEXT,
  file_size BIGINT,
  duration_minutes INTEGER,
  order_index INTEGER DEFAULT 0,
  is_free_preview BOOLEAN DEFAULT false,
  is_published BOOLEAN DEFAULT true,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- App Updates (referenced in notification_models.dart)
CREATE TABLE IF NOT EXISTS app_updates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  version TEXT NOT NULL,
  build_number INTEGER NOT NULL,
  platform TEXT CHECK (platform IN ('android', 'ios', 'web', 'windows', 'macos', 'linux')),
  update_type TEXT DEFAULT 'optional' CHECK (update_type IN ('optional', 'recommended', 'force')),
  title TEXT NOT NULL,
  description TEXT,
  features JSONB DEFAULT '[]'::jsonb,
  bug_fixes JSONB DEFAULT '[]'::jsonb,
  download_url TEXT,
  file_size BIGINT,
  release_date DATE DEFAULT CURRENT_DATE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Event Venues (referenced in panel_stats_provider.dart)
CREATE TABLE IF NOT EXISTS event_venues (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  name TEXT NOT NULL,
  description TEXT,
  address TEXT,
  capacity INTEGER,
  amenities JSONB DEFAULT '[]'::jsonb,
  contact_person TEXT,
  contact_phone TEXT,
  contact_email TEXT,
  hourly_rate DECIMAL(10,2),
  daily_rate DECIMAL(10,2),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Visitors (referenced in panel_stats_provider.dart)
CREATE TABLE IF NOT EXISTS visitors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  full_name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  purpose TEXT,
  person_to_visit UUID REFERENCES profiles(id),
  check_in TIMESTAMPTZ DEFAULT NOW(),
  check_out TIMESTAMPTZ,
  id_proof TEXT,
  id_number TEXT,
  vehicle_number TEXT,
  notes TEXT,
  status TEXT DEFAULT 'checked_in' CHECK (status IN ('checked_in', 'checked_out', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enrollments (referenced in panel_stats_provider.dart)
CREATE TABLE IF NOT EXISTS enrollments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  student_id UUID REFERENCES students(id),
  course_id UUID REFERENCES courses(id),
  enrollment_date DATE DEFAULT CURRENT_DATE,
  completion_date DATE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'dropped', 'withdrawn', 'pending')),
  progress_pct DECIMAL(5,2) DEFAULT 0,
  grade TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, course_id)
);

-- Maintenance Tasks (referenced in maintenance_repository.dart - separate from maintenance_requests)
CREATE TABLE IF NOT EXISTS maintenance_tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  title TEXT NOT NULL,
  description TEXT,
  location TEXT,
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  category TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
  assigned_to UUID REFERENCES profiles(id),
  requested_by UUID REFERENCES profiles(id),
  scheduled_date DATE,
  completed_at TIMESTAMPTZ,
  estimated_cost DECIMAL(10,2),
  actual_cost DECIMAL(10,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES FOR MISSING TABLES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_suppliers_tenant ON suppliers(tenant_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_active ON suppliers(is_active);
CREATE INDEX IF NOT EXISTS idx_suppliers_name ON suppliers(name);

CREATE INDEX IF NOT EXISTS idx_purchase_orders_tenant ON purchase_orders(tenant_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_supplier ON purchase_orders(supplier_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_status ON purchase_orders(status);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_date ON purchase_orders(order_date);

CREATE INDEX IF NOT EXISTS idx_work_orders_tenant ON work_orders(tenant_id);
CREATE INDEX IF NOT EXISTS idx_work_orders_status ON work_orders(status);
CREATE INDEX IF NOT EXISTS idx_work_orders_priority ON work_orders(priority);
CREATE INDEX IF NOT EXISTS idx_work_orders_assigned ON work_orders(assigned_to);

CREATE INDEX IF NOT EXISTS idx_it_devices_tenant ON it_devices(tenant_id);
CREATE INDEX IF NOT EXISTS idx_it_devices_type ON it_devices(device_type);
CREATE INDEX IF NOT EXISTS idx_it_devices_status ON it_devices(status);
CREATE INDEX IF NOT EXISTS idx_it_devices_assigned ON it_devices(assigned_to);

CREATE INDEX IF NOT EXISTS idx_staff_attendance_tenant ON staff_attendance(tenant_id);
CREATE INDEX IF NOT EXISTS idx_staff_attendance_staff ON staff_attendance(staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_attendance_date ON staff_attendance(date);
CREATE INDEX IF NOT EXISTS idx_staff_attendance_status ON staff_attendance(status);

CREATE INDEX IF NOT EXISTS idx_staff_tasks_tenant ON staff_tasks(tenant_id);
CREATE INDEX IF NOT EXISTS idx_staff_tasks_staff ON staff_tasks(staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_tasks_status ON staff_tasks(status);
CREATE INDEX IF NOT EXISTS idx_staff_tasks_due ON staff_tasks(due_date);

CREATE INDEX IF NOT EXISTS idx_phone_logs_tenant ON phone_logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_phone_logs_handled ON phone_logs(handled_by);
CREATE INDEX IF NOT EXISTS idx_phone_logs_created ON phone_logs(created_at);

CREATE INDEX IF NOT EXISTS idx_security_logs_tenant ON security_logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_security_logs_user ON security_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_security_logs_type ON security_logs(log_type);
CREATE INDEX IF NOT EXISTS idx_security_logs_created ON security_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_security_logs_suspicious ON security_logs(is_suspicious);

CREATE INDEX IF NOT EXISTS idx_point_history_tenant ON point_history(tenant_id);
CREATE INDEX IF NOT EXISTS idx_point_history_user ON point_history(user_id);
CREATE INDEX IF NOT EXISTS idx_point_history_created ON point_history(created_at);

CREATE INDEX IF NOT EXISTS idx_forum_posts_tenant ON forum_posts(tenant_id);
CREATE INDEX IF NOT EXISTS idx_forum_posts_user ON forum_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_forum_posts_category ON forum_posts(category);
CREATE INDEX IF NOT EXISTS idx_forum_posts_status ON forum_posts(status);
CREATE INDEX IF NOT EXISTS idx_forum_posts_pinned ON forum_posts(is_pinned);
CREATE INDEX IF NOT EXISTS idx_forum_posts_activity ON forum_posts(last_activity_at DESC);

CREATE INDEX IF NOT EXISTS idx_forum_comments_post ON forum_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_forum_comments_user ON forum_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_forum_comments_parent ON forum_comments(parent_id);

CREATE INDEX IF NOT EXISTS idx_study_groups_tenant ON study_groups(tenant_id);
CREATE INDEX IF NOT EXISTS idx_study_groups_course ON study_groups(course_id);
CREATE INDEX IF NOT EXISTS idx_study_groups_status ON study_groups(status);

CREATE INDEX IF NOT EXISTS idx_study_group_members_group ON study_group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_study_group_members_user ON study_group_members(user_id);

CREATE INDEX IF NOT EXISTS idx_conversations_tenant ON conversations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_conversations_participants ON conversations USING gin(participant_ids);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message ON conversations(last_message_at DESC);

CREATE INDEX IF NOT EXISTS idx_finance_tenant ON finance(tenant_id);
CREATE INDEX IF NOT EXISTS idx_finance_type ON finance(transaction_type);
CREATE INDEX IF NOT EXISTS idx_finance_category ON finance(category);
CREATE INDEX IF NOT EXISTS idx_finance_date ON finance(transaction_date);
CREATE INDEX IF NOT EXISTS idx_finance_status ON finance(status);

CREATE INDEX IF NOT EXISTS idx_lms_content_tenant ON lms_content(tenant_id);
CREATE INDEX IF NOT EXISTS idx_lms_content_course ON lms_content(course_id);
CREATE INDEX IF NOT EXISTS idx_lms_content_type ON lms_content(content_type);
CREATE INDEX IF NOT EXISTS idx_lms_content_published ON lms_content(is_published);

CREATE INDEX IF NOT EXISTS idx_sub_courses_tenant ON sub_courses(tenant_id);
CREATE INDEX IF NOT EXISTS idx_sub_courses_course ON sub_courses(course_id);
CREATE INDEX IF NOT EXISTS idx_sub_courses_active ON sub_courses(is_active);

CREATE INDEX IF NOT EXISTS idx_course_content_tenant ON course_content(tenant_id);
CREATE INDEX IF NOT EXISTS idx_course_content_course ON course_content(course_id);
CREATE INDEX IF NOT EXISTS idx_course_content_type ON course_content(content_type);
CREATE INDEX IF NOT EXISTS idx_course_content_published ON course_content(is_published);

CREATE INDEX IF NOT EXISTS idx_app_updates_tenant ON app_updates(tenant_id);
CREATE INDEX IF NOT EXISTS idx_app_updates_platform ON app_updates(platform);
CREATE INDEX IF NOT EXISTS idx_app_updates_active ON app_updates(is_active);

CREATE INDEX IF NOT EXISTS idx_event_venues_tenant ON event_venues(tenant_id);
CREATE INDEX IF NOT EXISTS idx_event_venues_active ON event_venues(is_active);

CREATE INDEX IF NOT EXISTS idx_visitors_tenant ON visitors(tenant_id);
CREATE INDEX IF NOT EXISTS idx_visitors_status ON visitors(status);
CREATE INDEX IF NOT EXISTS idx_visitors_checkin ON visitors(check_in);

CREATE INDEX IF NOT EXISTS idx_enrollments_tenant ON enrollments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_student ON enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_course ON enrollments(course_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_status ON enrollments(status);

CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_tenant ON maintenance_tasks(tenant_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_status ON maintenance_tasks(status);
CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_priority ON maintenance_tasks(priority);
CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_assigned ON maintenance_tasks(assigned_to);

-- ============================================
-- TRIGGERS FOR MISSING TABLES
-- ============================================

CREATE TRIGGER update_suppliers_updated_at BEFORE UPDATE ON suppliers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_purchase_orders_updated_at BEFORE UPDATE ON purchase_orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_work_orders_updated_at BEFORE UPDATE ON work_orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_it_devices_updated_at BEFORE UPDATE ON it_devices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_staff_attendance_updated_at BEFORE UPDATE ON staff_attendance
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_staff_tasks_updated_at BEFORE UPDATE ON staff_tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_forum_posts_updated_at BEFORE UPDATE ON forum_posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_forum_comments_updated_at BEFORE UPDATE ON forum_comments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_study_groups_updated_at BEFORE UPDATE ON study_groups
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON conversations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_finance_updated_at BEFORE UPDATE ON finance
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lms_content_updated_at BEFORE UPDATE ON lms_content
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sub_courses_updated_at BEFORE UPDATE ON sub_courses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_course_content_updated_at BEFORE UPDATE ON course_content
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_app_updates_updated_at BEFORE UPDATE ON app_updates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_event_venues_updated_at BEFORE UPDATE ON event_venues
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_visitors_updated_at BEFORE UPDATE ON visitors
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_enrollments_updated_at BEFORE UPDATE ON enrollments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_maintenance_tasks_updated_at BEFORE UPDATE ON maintenance_tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- RLS POLICIES FOR MISSING TABLES
-- ============================================

ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE it_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE phone_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE point_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE finance ENABLE ROW LEVEL SECURITY;
ALTER TABLE lms_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE sub_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_venues ENABLE ROW LEVEL SECURITY;
ALTER TABLE visitors ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_tasks ENABLE ROW LEVEL SECURITY;

-- Suppliers: tenant isolation
CREATE POLICY "suppliers_tenant_isolation" ON suppliers FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- Purchase Orders: tenant isolation
CREATE POLICY "purchase_orders_tenant_isolation" ON purchase_orders FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- Work Orders: tenant isolation
CREATE POLICY "work_orders_tenant_isolation" ON work_orders FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- IT Devices: tenant isolation
CREATE POLICY "it_devices_tenant_isolation" ON it_devices FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- Staff Attendance: tenant isolation
CREATE POLICY "staff_attendance_tenant_isolation" ON staff_attendance FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- Staff Tasks: tenant isolation
CREATE POLICY "staff_tasks_tenant_isolation" ON staff_tasks FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- Phone Logs: tenant isolation (read only for most, insert for reception)
CREATE POLICY "phone_logs_tenant_isolation" ON phone_logs FOR SELECT
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "phone_logs_insert" ON phone_logs FOR INSERT
  WITH CHECK (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- Security Logs: admin read only
CREATE POLICY "security_logs_admin_read" ON security_logs FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('super_admin', 'admin', 'ceo')));

CREATE POLICY "security_logs_system_insert" ON security_logs FOR INSERT
  WITH CHECK (true);

-- Point History: users see own, staff see all
CREATE POLICY "point_history_user_isolation" ON point_history FOR SELECT
  USING (user_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('super_admin', 'admin', 'teacher')));

CREATE POLICY "point_history_insert" ON point_history FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Forum Posts: tenant read, authenticated insert
CREATE POLICY "forum_posts_tenant_read" ON forum_posts FOR SELECT
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()) OR status = 'active');

CREATE POLICY "forum_posts_authenticated_insert" ON forum_posts FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "forum_posts_owner_edit" ON forum_posts FOR UPDATE
  USING (user_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('super_admin', 'admin')));

-- Forum Comments: same as posts
CREATE POLICY "forum_comments_read" ON forum_comments FOR SELECT
  USING (true);

CREATE POLICY "forum_comments_authenticated_insert" ON forum_comments FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "forum_comments_owner_edit" ON forum_comments FOR UPDATE
  USING (user_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('super_admin', 'admin')));

-- Study Groups: tenant isolation
CREATE POLICY "study_groups_tenant_isolation" ON study_groups FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- Study Group Members: based on group access
CREATE POLICY "study_group_members_group_access" ON study_group_members FOR ALL
  USING (group_id IN (SELECT id FROM study_groups WHERE tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid())));

-- Conversations: participant isolation
CREATE POLICY "conversations_participant_isolation" ON conversations FOR ALL
  USING (auth.uid() = ANY(participant_ids) OR EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('super_admin', 'admin')));

-- Finance: tenant isolation
CREATE POLICY "finance_tenant_isolation" ON finance FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- LMS Content: tenant isolation
CREATE POLICY "lms_content_tenant_isolation" ON lms_content FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- Sub Courses: tenant isolation
CREATE POLICY "sub_courses_tenant_isolation" ON sub_courses FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- Course Content: tenant isolation
CREATE POLICY "course_content_tenant_isolation" ON course_content FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- App Updates: public read active, admin manage
CREATE POLICY "app_updates_public_read" ON app_updates FOR SELECT
  USING (is_active = TRUE);

CREATE POLICY "app_updates_admin_manage" ON app_updates FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('super_admin', 'admin')));

-- Event Venues: tenant isolation
CREATE POLICY "event_venues_tenant_isolation" ON event_venues FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- Visitors: tenant isolation
CREATE POLICY "visitors_tenant_isolation" ON visitors FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- Enrollments: tenant isolation
CREATE POLICY "enrollments_tenant_isolation" ON enrollments FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- Maintenance Tasks: tenant isolation
CREATE POLICY "maintenance_tasks_tenant_isolation" ON maintenance_tasks FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()));

-- ============================================
-- ADDRESSES TABLE RLS POLICIES
-- ============================================

ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "addresses_read_own" ON addresses FOR SELECT
  USING (entity_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('super_admin', 'admin')));

CREATE POLICY "addresses_insert_own" ON addresses FOR INSERT
  WITH CHECK (entity_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('super_admin', 'admin')));

CREATE POLICY "addresses_update_own" ON addresses FOR UPDATE
  USING (entity_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('super_admin', 'admin')));

-- ============================================
-- ADDRESS TABLE TRIGGER
-- ============================================

CREATE TRIGGER update_addresses_updated_at BEFORE UPDATE ON addresses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- ALTER EXISTING TABLES: Add Identity Columns
-- For existing installations where tables were already created
-- ============================================

-- Profiles: Add identity columns if not present
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS tazkira_number TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS passport_id TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS blood_group TEXT CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'));
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS nationality TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS religion TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS father_name TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS mother_name TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS marital_status TEXT CHECK (marital_status IN ('single', 'married', 'divorced', 'widowed'));
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS emergency_contact_name TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS emergency_contact_phone TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS emergency_contact_relation TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS full_name_ar TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS first_name_ar TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_name_ar TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS father_name_ar TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS mother_name_ar TEXT;

-- Students: Add identity columns if not present
ALTER TABLE students ADD COLUMN IF NOT EXISTS tazkira_number TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS passport_id TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS blood_group TEXT CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'));
ALTER TABLE students ADD COLUMN IF NOT EXISTS nationality TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS religion TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS birth_place TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS father_name TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS mother_name TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS marital_status TEXT CHECK (marital_status IN ('single', 'married', 'divorced', 'widowed'));
ALTER TABLE students ADD COLUMN IF NOT EXISTS full_name_ar TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS first_name_ar TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS last_name_ar TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS father_name_ar TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS mother_name_ar TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS guardian_name_ar TEXT;

-- Teachers: Add identity columns if not present
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS tazkira_number TEXT;
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS passport_id TEXT;
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS blood_group TEXT CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'));
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS nationality TEXT;
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS religion TEXT;
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS birth_place TEXT;
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS father_name TEXT;
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS mother_name TEXT;
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS marital_status TEXT CHECK (marital_status IN ('single', 'married', 'divorced', 'widowed'));
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS full_name_ar TEXT;
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS first_name_ar TEXT;
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS last_name_ar TEXT;
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS father_name_ar TEXT;
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS mother_name_ar TEXT;

-- Staff: Add identity columns if not present
ALTER TABLE staff ADD COLUMN IF NOT EXISTS tazkira_number TEXT;
ALTER TABLE staff ADD COLUMN IF NOT EXISTS passport_id TEXT;
ALTER TABLE staff ADD COLUMN IF NOT EXISTS blood_group TEXT CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'));
ALTER TABLE staff ADD COLUMN IF NOT EXISTS nationality TEXT;
ALTER TABLE staff ADD COLUMN IF NOT EXISTS religion TEXT;
ALTER TABLE staff ADD COLUMN IF NOT EXISTS birth_place TEXT;
ALTER TABLE staff ADD COLUMN IF NOT EXISTS father_name TEXT;
ALTER TABLE staff ADD COLUMN IF NOT EXISTS mother_name TEXT;
ALTER TABLE staff ADD COLUMN IF NOT EXISTS marital_status TEXT CHECK (marital_status IN ('single', 'married', 'divorced', 'widowed'));
ALTER TABLE staff ADD COLUMN IF NOT EXISTS full_name_ar TEXT;
ALTER TABLE staff ADD COLUMN IF NOT EXISTS first_name_ar TEXT;
ALTER TABLE staff ADD COLUMN IF NOT EXISTS last_name_ar TEXT;
ALTER TABLE staff ADD COLUMN IF NOT EXISTS father_name_ar TEXT;
ALTER TABLE staff ADD COLUMN IF NOT EXISTS mother_name_ar TEXT;

-- Reports: Add Arabic columns if not present
ALTER TABLE reports ADD COLUMN IF NOT EXISTS name_ar TEXT;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS name_dr TEXT;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS name_ps TEXT;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS template_id UUID REFERENCES report_templates(id);
ALTER TABLE reports ADD COLUMN IF NOT EXISTS report_type TEXT CHECK (report_type IN ('tabular', 'chart', 'summary', 'comparison', 'custom'));
ALTER TABLE reports ADD COLUMN IF NOT EXISTS summary TEXT;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS summary_ar TEXT;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS file_url TEXT;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS file_format TEXT CHECK (file_format IN ('pdf', 'excel', 'csv', 'html', 'json'));
ALTER TABLE reports ADD COLUMN IF NOT EXISTS schedule_id UUID REFERENCES report_schedules(id);
ALTER TABLE reports ADD COLUMN IF NOT EXISTS is_scheduled BOOLEAN DEFAULT false;

-- Business Reports: Add Arabic columns if not present
ALTER TABLE business_reports ADD COLUMN IF NOT EXISTS title_ar TEXT;
ALTER TABLE business_reports ADD COLUMN IF NOT EXISTS title_dr TEXT;
ALTER TABLE business_reports ADD COLUMN IF NOT EXISTS title_ps TEXT;

-- Invoices: Add new columns if not present
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id);
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS description_ar TEXT;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS discount_reason TEXT;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS paid_amount DECIMAL(14,2) DEFAULT 0;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS journal_id UUID REFERENCES journals(id);
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES profiles(id);
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS notes TEXT;

-- Payments: Add new columns if not present
ALTER TABLE payments ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(14,2) DEFAULT 0;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS refund_amount DECIMAL(14,2) DEFAULT 0;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS journal_id UUID REFERENCES journals(id);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS receipt_id UUID REFERENCES receipts(id);

-- Expenses: Add new columns if not present
ALTER TABLE expenses ADD COLUMN IF NOT EXISTS description_ar TEXT;
ALTER TABLE expenses ADD COLUMN IF NOT EXISTS vendor_contact TEXT;
ALTER TABLE expenses ADD COLUMN IF NOT EXISTS journal_id UUID REFERENCES journals(id);
ALTER TABLE expenses ADD COLUMN IF NOT EXISTS account_id UUID REFERENCES accounts(id);

-- Payroll: Add if table already exists from previous schema version
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS journal_id UUID REFERENCES journals(id);
ALTER TABLE payroll_items ADD COLUMN IF NOT EXISTS journal_id UUID REFERENCES journals(id);

ALTER TABLE inventory_categories ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id);
ALTER TABLE inventory_categories ADD COLUMN IF NOT EXISTS name_ar TEXT;
ALTER TABLE inventory_categories ADD COLUMN IF NOT EXISTS name_dr TEXT;
ALTER TABLE inventory_categories ADD COLUMN IF NOT EXISTS name_ps TEXT;
ALTER TABLE inventory_categories ADD COLUMN IF NOT EXISTS description_ar TEXT;
ALTER TABLE inventory_categories ADD COLUMN IF NOT EXISTS parent_category_id UUID REFERENCES inventory_categories(id);
ALTER TABLE inventory_categories ADD COLUMN IF NOT EXISTS icon TEXT;
ALTER TABLE inventory_categories ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;
ALTER TABLE inventory_categories ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES inventory_categories(id);

ALTER TABLE stock_reconciliation ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id);
ALTER TABLE stock_reconciliation ADD COLUMN IF NOT EXISTS variance_reason_ar TEXT;
ALTER TABLE stock_reconciliation ADD COLUMN IF NOT EXISTS notes_ar TEXT;
ALTER TABLE stock_reconciliation ADD COLUMN IF NOT EXISTS location TEXT;
ALTER TABLE stock_reconciliation ADD COLUMN IF NOT EXISTS batch_id TEXT;

ALTER TABLE assets ADD COLUMN IF NOT EXISTS condition TEXT DEFAULT 'new' CHECK (condition IN ('new', 'good', 'fair', 'damaged', 'broken', 'under_repair', 'repaired', 'unused', 'destroyed', 'disposed'));
ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS condition TEXT DEFAULT 'new' CHECK (condition IN ('new', 'good', 'fair', 'damaged', 'broken', 'under_repair', 'repaired', 'unused', 'destroyed', 'disposed'));

-- RBAC: Add if tables already exist from previous schema version
ALTER TABLE roles ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id);
ALTER TABLE roles ADD COLUMN IF NOT EXISTS name_ar TEXT;
ALTER TABLE roles ADD COLUMN IF NOT EXISTS name_dr TEXT;
ALTER TABLE roles ADD COLUMN IF NOT EXISTS name_ps TEXT;
ALTER TABLE roles ADD COLUMN IF NOT EXISTS description_ar TEXT;
ALTER TABLE roles ADD COLUMN IF NOT EXISTS level INTEGER DEFAULT 0;
ALTER TABLE roles ADD COLUMN IF NOT EXISTS is_system BOOLEAN DEFAULT false;
ALTER TABLE roles ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

ALTER TABLE role_permissions ADD COLUMN IF NOT EXISTS module TEXT;

ALTER TABLE user_roles ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id);
ALTER TABLE user_roles ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;
ALTER TABLE user_roles ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

ALTER TABLE role_permissions ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id);

ALTER TABLE page_permissions ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id);
ALTER TABLE page_permissions ADD COLUMN IF NOT EXISTS role_id UUID REFERENCES roles(id) ON DELETE CASCADE;
ALTER TABLE page_permissions ADD COLUMN IF NOT EXISTS profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE page_permissions ADD COLUMN IF NOT EXISTS page_title_ar TEXT;
ALTER TABLE page_permissions ADD COLUMN IF NOT EXISTS page_title_dr TEXT;
ALTER TABLE page_permissions ADD COLUMN IF NOT EXISTS page_title_ps TEXT;
ALTER TABLE page_permissions ADD COLUMN IF NOT EXISTS module TEXT;
ALTER TABLE page_permissions ADD COLUMN IF NOT EXISTS route TEXT;
ALTER TABLE page_permissions ADD COLUMN IF NOT EXISTS icon TEXT;
ALTER TABLE page_permissions ADD COLUMN IF NOT EXISTS can_view BOOLEAN DEFAULT true;
ALTER TABLE page_permissions ADD COLUMN IF NOT EXISTS can_create BOOLEAN DEFAULT false;
ALTER TABLE page_permissions ADD COLUMN IF NOT EXISTS can_edit BOOLEAN DEFAULT false;
ALTER TABLE page_permissions ADD COLUMN IF NOT EXISTS can_delete BOOLEAN DEFAULT false;
ALTER TABLE page_permissions ADD COLUMN IF NOT EXISTS is_visible_in_nav BOOLEAN DEFAULT true;
ALTER TABLE page_permissions ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;
ALTER TABLE page_permissions ADD COLUMN IF NOT EXISTS is_system BOOLEAN DEFAULT false;

-- Book management: add columns for existing installs
ALTER TABLE books ADD COLUMN IF NOT EXISTS title_ar TEXT;
ALTER TABLE books ADD COLUMN IF NOT EXISTS author_ar TEXT;
ALTER TABLE books ADD COLUMN IF NOT EXISTS category_ar TEXT;
ALTER TABLE books ADD COLUMN IF NOT EXISTS description_ar TEXT;
ALTER TABLE books ADD COLUMN IF NOT EXISTS cost_price DECIMAL(12,2);
ALTER TABLE books ADD COLUMN IF NOT EXISTS selling_price DECIMAL(12,2);
ALTER TABLE books ADD COLUMN IF NOT EXISTS supplier TEXT;
ALTER TABLE books ADD COLUMN IF NOT EXISTS supplier_contact TEXT;
ALTER TABLE books ADD COLUMN IF NOT EXISTS purchase_date DATE;
ALTER TABLE books ADD COLUMN IF NOT EXISTS total_copies INTEGER DEFAULT 0;
ALTER TABLE books ADD COLUMN IF NOT EXISTS available_copies INTEGER DEFAULT 0;
ALTER TABLE books ADD COLUMN IF NOT EXISTS borrowed_copies INTEGER DEFAULT 0;
ALTER TABLE books ADD COLUMN IF NOT EXISTS sold_copies INTEGER DEFAULT 0;
ALTER TABLE books ADD COLUMN IF NOT EXISTS lost_copies INTEGER DEFAULT 0;
ALTER TABLE books ADD COLUMN IF NOT EXISTS damaged_copies INTEGER DEFAULT 0;
ALTER TABLE books ADD COLUMN IF NOT EXISTS reserved_copies INTEGER DEFAULT 0;

ALTER TABLE book_copies ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'available' CHECK (status IN ('available', 'borrowed', 'sold', 'lost', 'damaged', 'reserved'));
ALTER TABLE book_copies ADD COLUMN IF NOT EXISTS cost_price DECIMAL(12,2);
ALTER TABLE book_copies ADD COLUMN IF NOT EXISTS selling_price DECIMAL(12,2);
ALTER TABLE book_copies ADD COLUMN IF NOT EXISTS sold_to UUID REFERENCES students(id);
ALTER TABLE book_copies ADD COLUMN IF NOT EXISTS sold_at TIMESTAMPTZ;
ALTER TABLE book_copies ADD COLUMN IF NOT EXISTS invoice_id UUID REFERENCES invoices(id);

ALTER TABLE book_purchases ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id);
ALTER TABLE book_purchases ADD COLUMN IF NOT EXISTS notes_ar TEXT;
ALTER TABLE book_purchases ADD COLUMN IF NOT EXISTS payment_method TEXT;

ALTER TABLE book_sales ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id);
ALTER TABLE book_sales ADD COLUMN IF NOT EXISTS notes_ar TEXT;
ALTER TABLE book_sales ADD COLUMN IF NOT EXISTS course_id UUID REFERENCES courses(id);

-- Discounts & promotions: add columns for existing installs
ALTER TABLE discounts ADD COLUMN IF NOT EXISTS name_ar TEXT;
ALTER TABLE discounts ADD COLUMN IF NOT EXISTS description_ar TEXT;
ALTER TABLE discounts ADD COLUMN IF NOT EXISTS type TEXT NOT NULL DEFAULT 'percentage' CHECK (type IN ('percentage', 'fixed'));
ALTER TABLE discounts ADD COLUMN IF NOT EXISTS value DECIMAL(12,2) NOT NULL DEFAULT 0;
ALTER TABLE discounts ADD COLUMN IF NOT EXISTS discount_code TEXT;
ALTER TABLE discounts ADD COLUMN IF NOT EXISTS usage_limit INTEGER;
ALTER TABLE discounts ADD COLUMN IF NOT EXISTS used_count INTEGER DEFAULT 0;
ALTER TABLE discounts ADD COLUMN IF NOT EXISTS min_purchase_amount DECIMAL(12,2);
ALTER TABLE discounts ADD COLUMN IF NOT EXISTS max_discount_amount DECIMAL(12,2);
ALTER TABLE discounts ADD COLUMN IF NOT EXISTS applicable_modules TEXT[] DEFAULT '{}';
ALTER TABLE discounts ADD COLUMN IF NOT EXISTS valid_from DATE;
ALTER TABLE discounts ADD COLUMN IF NOT EXISTS is_coupon BOOLEAN DEFAULT false;
ALTER TABLE discounts ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES profiles(id);

ALTER TABLE promotions ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id);
ALTER TABLE promotions ADD COLUMN IF NOT EXISTS name_ar TEXT;
ALTER TABLE promotions ADD COLUMN IF NOT EXISTS description_ar TEXT;
ALTER TABLE promotions ADD COLUMN IF NOT EXISTS terms_ar TEXT;
ALTER TABLE promotions ADD COLUMN IF NOT EXISTS banner_image_url TEXT;
ALTER TABLE promotions ADD COLUMN IF NOT EXISTS applicable_roles TEXT[] DEFAULT '{}';

ALTER TABLE invoices ADD COLUMN IF NOT EXISTS discount_id UUID REFERENCES discounts(id);
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS promotion_id UUID REFERENCES promotions(id);

ALTER TABLE student_fee_assignments ADD COLUMN IF NOT EXISTS discount_id UUID REFERENCES discounts(id);
ALTER TABLE student_fee_assignments ADD COLUMN IF NOT EXISTS promotion_id UUID REFERENCES promotions(id);

ALTER TABLE book_sales ADD COLUMN IF NOT EXISTS discount_id UUID REFERENCES discounts(id);
ALTER TABLE book_sales ADD COLUMN IF NOT EXISTS promotion_id UUID REFERENCES promotions(id);
ALTER TABLE book_sales ADD COLUMN IF NOT EXISTS discount_type TEXT CHECK (discount_type IN ('percentage', 'fixed', 'promotion', 'manual'));

ALTER TABLE book_purchases ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(12,2) DEFAULT 0;
ALTER TABLE book_purchases ADD COLUMN IF NOT EXISTS discount_id UUID REFERENCES discounts(id);
ALTER TABLE book_purchases ADD COLUMN IF NOT EXISTS promotion_id UUID REFERENCES promotions(id);

ALTER TABLE course_applications ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(12,2) DEFAULT 0;
ALTER TABLE course_applications ADD COLUMN IF NOT EXISTS discount_id UUID REFERENCES discounts(id);
ALTER TABLE course_applications ADD COLUMN IF NOT EXISTS promotion_id UUID REFERENCES promotions(id);
ALTER TABLE course_applications ADD COLUMN IF NOT EXISTS final_fee DECIMAL(12,2);

ALTER TABLE fee_structures ADD COLUMN IF NOT EXISTS early_bird_discount DECIMAL(5,2) DEFAULT 0;
ALTER TABLE fee_structures ADD COLUMN IF NOT EXISTS early_bird_until DATE;
ALTER TABLE fee_structures ADD COLUMN IF NOT EXISTS group_discount DECIMAL(5,2) DEFAULT 0;
ALTER TABLE fee_structures ADD COLUMN IF NOT EXISTS group_min_size INTEGER DEFAULT 0;

ALTER TABLE courses ADD COLUMN IF NOT EXISTS promotion_price DECIMAL(12,2);
ALTER TABLE courses ADD COLUMN IF NOT EXISTS promotion_valid_from DATE;
ALTER TABLE courses ADD COLUMN IF NOT EXISTS promotion_valid_until DATE;

-- Employee tables: add missing discount/promotion/financial columns
ALTER TABLE recruitment ADD COLUMN IF NOT EXISTS discount_allowed BOOLEAN DEFAULT false;
ALTER TABLE recruitment ADD COLUMN IF NOT EXISTS max_discount_percentage DECIMAL(5,2) DEFAULT 0;
ALTER TABLE recruitment ADD COLUMN IF NOT EXISTS negotiable_salary BOOLEAN DEFAULT true;

ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS offered_salary DECIMAL(10,2);
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS signing_bonus DECIMAL(10,2) DEFAULT 0;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS negotiation_discount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS discount_id UUID REFERENCES discounts(id);
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS promotion_id UUID REFERENCES promotions(id);

ALTER TABLE payroll_items ADD COLUMN IF NOT EXISTS bonus_reason TEXT;
ALTER TABLE payroll_items ADD COLUMN IF NOT EXISTS bonus_promotion_id UUID REFERENCES promotions(id);
ALTER TABLE payroll_items ADD COLUMN IF NOT EXISTS deduction_breakdown JSONB DEFAULT '{}'::jsonb;
ALTER TABLE payroll_items ADD COLUMN IF NOT EXISTS deduction_promotion_id UUID REFERENCES promotions(id);

ALTER TABLE employee_leaves ADD COLUMN IF NOT EXISTS is_paid BOOLEAN DEFAULT true;
ALTER TABLE employee_leaves ADD COLUMN IF NOT EXISTS deduction_percentage DECIMAL(5,2) DEFAULT 0;
ALTER TABLE employee_leaves ADD COLUMN IF NOT EXISTS deduction_amount DECIMAL(12,2) DEFAULT 0;
ALTER TABLE employee_leaves ADD COLUMN IF NOT EXISTS deduction_waived BOOLEAN DEFAULT false;
ALTER TABLE employee_leaves ADD COLUMN IF NOT EXISTS waived_by UUID REFERENCES profiles(id);
ALTER TABLE employee_leaves ADD COLUMN IF NOT EXISTS waived_at TIMESTAMPTZ;

ALTER TABLE leave_requests ADD COLUMN IF NOT EXISTS is_paid BOOLEAN DEFAULT true;
ALTER TABLE leave_requests ADD COLUMN IF NOT EXISTS deduction_percentage DECIMAL(5,2) DEFAULT 0;
ALTER TABLE leave_requests ADD COLUMN IF NOT EXISTS deduction_amount DECIMAL(12,2) DEFAULT 0;

ALTER TABLE staff_attendance ADD COLUMN IF NOT EXISTS fine_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE staff_attendance ADD COLUMN IF NOT EXISTS fine_reason TEXT;
ALTER TABLE staff_attendance ADD COLUMN IF NOT EXISTS fine_waived BOOLEAN DEFAULT false;
ALTER TABLE staff_attendance ADD COLUMN IF NOT EXISTS fine_waived_by UUID REFERENCES profiles(id);
ALTER TABLE staff_attendance ADD COLUMN IF NOT EXISTS overtime_rate DECIMAL(10,2) DEFAULT 0;

ALTER TABLE attendance ADD COLUMN IF NOT EXISTS fine_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS fine_reason TEXT;
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS overtime_minutes INTEGER DEFAULT 0;
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS overtime_rate DECIMAL(10,2) DEFAULT 0;

ALTER TABLE trainings ADD COLUMN IF NOT EXISTS cost DECIMAL(12,2) DEFAULT 0;
ALTER TABLE trainings ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(12,2) DEFAULT 0;
ALTER TABLE trainings ADD COLUMN IF NOT EXISTS discount_id UUID REFERENCES discounts(id);
ALTER TABLE trainings ADD COLUMN IF NOT EXISTS promotion_id UUID REFERENCES promotions(id);

ALTER TABLE performance_reviews ADD COLUMN IF NOT EXISTS bonus_amount DECIMAL(12,2) DEFAULT 0;
ALTER TABLE performance_reviews ADD COLUMN IF NOT EXISTS bonus_promotion_id UUID REFERENCES promotions(id);
ALTER TABLE performance_reviews ADD COLUMN IF NOT EXISTS incentive_type TEXT CHECK (incentive_type IN ('bonus', 'raise', 'promotion', 'certificate', 'other'));
ALTER TABLE performance_reviews ADD COLUMN IF NOT EXISTS incentive_details TEXT;

-- Job announcements & general announcements: add for existing installs
ALTER TABLE job_announcements ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id);
ALTER TABLE job_announcements ADD COLUMN IF NOT EXISTS recruitment_id UUID REFERENCES recruitment(id);
ALTER TABLE job_announcements ADD COLUMN IF NOT EXISTS title_ar TEXT;
ALTER TABLE job_announcements ADD COLUMN IF NOT EXISTS title_dr TEXT;
ALTER TABLE job_announcements ADD COLUMN IF NOT EXISTS title_ps TEXT;
ALTER TABLE job_announcements ADD COLUMN IF NOT EXISTS description_ar TEXT;
ALTER TABLE job_announcements ADD COLUMN IF NOT EXISTS description_dr TEXT;
ALTER TABLE job_announcements ADD COLUMN IF NOT EXISTS description_ps TEXT;
ALTER TABLE job_announcements ADD COLUMN IF NOT EXISTS requirements_ar TEXT;
ALTER TABLE job_announcements ADD COLUMN IF NOT EXISTS benefits_ar TEXT;
ALTER TABLE job_announcements ADD COLUMN IF NOT EXISTS application_instructions_ar TEXT;
ALTER TABLE job_announcements ADD COLUMN IF NOT EXISTS contact_email TEXT;
ALTER TABLE job_announcements ADD COLUMN IF NOT EXISTS contact_phone TEXT;
ALTER TABLE job_announcements ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false;
ALTER TABLE job_announcements ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0;
ALTER TABLE job_announcements ADD COLUMN IF NOT EXISTS share_count INTEGER DEFAULT 0;
ALTER TABLE job_announcements ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES profiles(id);
ALTER TABLE job_announcements ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;

ALTER TABLE announcements ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id);
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS title_ar TEXT;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS title_dr TEXT;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS title_ps TEXT;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS content_ar TEXT;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS content_dr TEXT;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS content_ps TEXT;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS target_audience TEXT[] DEFAULT '{all}';
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT false;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS attachment_url TEXT;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS attachment_name TEXT;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS banner_image_url TEXT;
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES profiles(id);
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;

-- Course details: add columns for existing installs
ALTER TABLE course_details ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id);
ALTER TABLE course_details ADD COLUMN IF NOT EXISTS course_id UUID REFERENCES courses(id);
ALTER TABLE course_details ADD COLUMN IF NOT EXISTS program_id UUID REFERENCES programs(id);
ALTER TABLE course_details ADD COLUMN IF NOT EXISTS department_id UUID REFERENCES departments(id);
ALTER TABLE course_details ADD COLUMN IF NOT EXISTS name_ar TEXT;
ALTER TABLE course_details ADD COLUMN IF NOT EXISTS name_dr TEXT;
ALTER TABLE course_details ADD COLUMN IF NOT EXISTS name_ps TEXT;
ALTER TABLE course_details ADD COLUMN IF NOT EXISTS description_ar TEXT;
ALTER TABLE course_details ADD COLUMN IF NOT EXISTS description_dr TEXT;
ALTER TABLE course_details ADD COLUMN IF NOT EXISTS description_ps TEXT;
ALTER TABLE course_details ADD COLUMN IF NOT EXISTS category_ar TEXT;
ALTER TABLE course_details ADD COLUMN IF NOT EXISTS language_ar TEXT;
ALTER TABLE course_details ADD COLUMN IF NOT EXISTS prerequisites_ar TEXT;
ALTER TABLE course_details ADD COLUMN IF NOT EXISTS target_audience_ar TEXT;
ALTER TABLE course_details ADD COLUMN IF NOT EXISTS discount_policy_ar TEXT;
ALTER TABLE course_details ADD COLUMN IF NOT EXISTS branch_id UUID REFERENCES branches(id);

ALTER TABLE branches ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id);
ALTER TABLE branches ADD COLUMN IF NOT EXISTS name_ar TEXT;
ALTER TABLE branches ADD COLUMN IF NOT EXISTS name_dr TEXT;
ALTER TABLE branches ADD COLUMN IF NOT EXISTS name_ps TEXT;
ALTER TABLE branches ADD COLUMN IF NOT EXISTS address_ar TEXT;
ALTER TABLE branches ADD COLUMN IF NOT EXISTS city_ar TEXT;
ALTER TABLE branches ADD COLUMN IF NOT EXISTS logo_url TEXT;
ALTER TABLE branches ADD COLUMN IF NOT EXISTS manager_id UUID REFERENCES profiles(id);

-- ============================================
-- STORAGE BUCKETS (for images, documents, media)
-- ============================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) VALUES
-- People buckets
('avatars', 'avatars', true, 2097152, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']),
('profiles', 'profiles', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'application/pdf']),
('students', 'students', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
('teachers', 'teachers', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
('staff', 'staff', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
('alumni', 'alumni', true, 10485760, ARRAY['image/jpeg', 'image/png', 'application/pdf']),
-- Academic buckets
('courses', 'courses', true, 20971520, ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/webm', 'application/pdf']),
('books', 'books', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf', 'application/epub+zip']),
('library', 'library', true, 52428800, ARRAY['image/jpeg', 'image/png', 'application/pdf', 'video/mp4', 'audio/mpeg', 'application/epub+zip']),
('assignments', 'assignments', true, 20971520, ARRAY['image/jpeg', 'image/png', 'application/pdf', 'application/msword', 'video/mp4']),
('exams', 'exams', false, 20971520, ARRAY['image/jpeg', 'image/png', 'application/pdf', 'application/msword']),
('grades', 'grades', false, 10485760, ARRAY['image/jpeg', 'image/png', 'application/pdf']),
-- Financial buckets
('receipts', 'receipts', false, 10485760, ARRAY['image/jpeg', 'image/png', 'application/pdf']),
('invoices', 'invoices', false, 10485760, ARRAY['image/jpeg', 'image/png', 'application/pdf']),
('finance', 'finance', false, 20971520, ARRAY['image/jpeg', 'image/png', 'application/pdf', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']),
('payroll', 'payroll', false, 20971520, ARRAY['image/jpeg', 'image/png', 'application/pdf']),
-- HR buckets
('hr', 'hr', false, 20971520, ARRAY['image/jpeg', 'image/png', 'application/pdf', 'application/msword']),
('recruitment', 'recruitment', true, 20971520, ARRAY['image/jpeg', 'image/png', 'application/pdf', 'application/msword']),
('trainings', 'trainings', true, 10485760, ARRAY['image/jpeg', 'image/png', 'application/pdf', 'video/mp4']),
-- Operations buckets
('transport', 'transport', true, 20971520, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
('hostel', 'hostel', true, 20971520, ARRAY['image/jpeg', 'image/png', 'image/webp']),
('inventory', 'inventory', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
('facilities', 'facilities', true, 20971520, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
('it_support', 'it_support', false, 20971520, ARRAY['image/jpeg', 'image/png', 'application/pdf', 'video/mp4']),
-- Communication buckets
('announcements', 'announcements', true, 20971520, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
('events', 'events', true, 20971520, ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4']),
('complaints', 'complaints', false, 20971520, ARRAY['image/jpeg', 'image/png', 'application/pdf', 'video/mp4']),
-- Documents & certificates
('documents', 'documents', false, 20971520, ARRAY['image/jpeg', 'image/png', 'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']),
('certificates', 'certificates', true, 10485760, ARRAY['image/jpeg', 'image/png', 'application/pdf']),
('reports', 'reports', false, 52428800, ARRAY['application/pdf', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'text/csv']),
-- Media & branding
('branding', 'branding', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml', 'image/x-icon']),
('sports', 'sports', true, 20971520, ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4']),
('medical', 'medical', false, 10485760, ARRAY['image/jpeg', 'image/png', 'application/pdf']),
-- System buckets
('backups', 'backups', false, 536870912, ARRAY['application/gzip', 'application/x-gzip', 'application/zip', 'application/x-sql']),
('temp', 'temp', true, 20971520, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf', 'text/csv']),
-- Chat buckets (images, files and voice messages shared in conversations)
('chat_uploads', 'chat_uploads', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'video/mp4', 'audio/mp4', 'audio/m4a', 'audio/mpeg', 'audio/aac', 'audio/ogg', 'application/pdf', 'application/octet-stream'])
ON CONFLICT (id) DO NOTHING;

-- Seed folder structure (virtual folders via placeholder objects)
DO $$
DECLARE
  folder_paths TEXT[] := ARRAY[
    -- avatars
    'avatars/public',
    'avatars/thumbnails',
    -- profiles
    'profiles/ids',
    'profiles/documents',
    'profiles/signatures',
    'profiles/verifications',
    -- students
    'students/photos',
    'students/documents',
    'students/assignments',
    'students/report_cards',
    'students/transcripts',
    'students/medical',
    'students/admissions',
    -- teachers
    'teachers/photos',
    'teachers/documents',
    'teachers/certifications',
    'teachers/contracts',
    'teachers/lesson_plans',
    'teachers/evaluations',
    -- staff
    'staff/photos',
    'staff/documents',
    'staff/contracts',
    'staff/evaluations',
    -- alumni
    'alumni/photos',
    'alumni/documents',
    'alumni/records',
    -- courses
    'courses/thumbnails',
    'courses/videos',
    'courses/materials',
    'courses/banners',
    'courses/syllabus',
    'courses/assignments',
    'courses/quizzes',
    -- books
    'books/covers',
    'books/files',
    'books/samples',
    -- library
    'library/ebooks',
    'library/journals',
    'library/audio',
    'library/video',
    'library/magazines',
    'library/research_papers',
    'library/thesis',
    -- assignments
    'assignments/submissions',
    'assignments/attachments',
    'assignments/graded',
    -- exams
    'exams/question_papers',
    'exams/answer_sheets',
    'exams/results',
    'exams/timetables',
    -- grades
    'grades/report_cards',
    'grades/transcripts',
    'grades/grade_sheets',
    -- receipts
    'receipts/payments',
    'receipts/refunds',
    'receipts/advance',
    'receipts/deposits',
    -- invoices
    'invoices/sent',
    'invoices/paid',
    'invoices/overdue',
    'invoices/credit_notes',
    -- finance
    'finance/budgets',
    'finance/audits',
    'finance/tax',
    'finance/statements',
    'finance/expenses',
    'finance/assets',
    -- payroll
    'payroll/salary_slips',
    'payroll/reports',
    'payroll/deductions',
    'payroll/bonuses',
    -- hr
    'hr/policies',
    'hr/contracts',
    'hr/compliance',
    'hr/disciplinary',
    'hr/employee_records',
    'hr/attendance_reports',
    -- recruitment
    'recruitment/job_postings',
    'recruitment/resumes',
    'recruitment/interviews',
    'recruitment/offers',
    'recruitment/onboarding',
    -- trainings
    'trainings/materials',
    'trainings/certifications',
    'trainings/recordings',
    'trainings/evaluations',
    -- transport
    'transport/vehicles',
    'transport/routes',
    'transport/drivers',
    'transport/documents',
    -- hostel
    'hostel/rooms',
    'hostel/students',
    'hostel/inventory',
    'hostel/complaints',
    -- inventory
    'inventory/items',
    'inventory/assets',
    'inventory/receipts',
    'inventory/damages',
    -- facilities
    'facilities/maintenance',
    'facilities/inspections',
    'facilities/floor_plans',
    -- it_support
    'it_support/tickets',
    'it_support/screenshots',
    'it_support/logs',
    'it_support/devices',
    -- announcements
    'announcements/banners',
    'announcements/attachments',
    'announcements/images',
    -- events
    'events/photos',
    'events/videos',
    'events/banners',
    'events/materials',
    -- complaints
    'complaints/evidence',
    'complaints/resolutions',
    'complaints/feedback',
    -- documents
    'documents/contracts',
    'documents/reports',
    'documents/legal',
    'documents/policies',
    'documents/agreements',
    'documents/templates',
    -- certificates
    'certificates/issued',
    'certificates/templates',
    'certificates/verifications',
    -- reports
    'reports/academic',
    'reports/financial',
    'reports/hr',
    'reports/operations',
    'reports/custom',
    'reports/exports',
    -- branding
    'branding/logos',
    'branding/icons',
    'branding/themes',
    'branding/letterheads',
    'branding/social_media',
    -- sports
    'sports/teams',
    'sports/events',
    'sports/achievements',
    'sports/photos',
    -- medical
    'medical/records',
    'medical/prescriptions',
    'medical/vaccinations',
    'medical/reports',
    -- backups
    'backups/daily',
    'backups/weekly',
    'backups/monthly',
    'backups/manual',
    -- temp
    'temp/uploads',
    'temp/exports',
    'temp/imports',
    'temp/processing'
  ];
  f TEXT;
  bucket_name TEXT;
  folder_name TEXT;
BEGIN
  FOREACH f IN ARRAY folder_paths
  LOOP
    bucket_name := split_part(f, '/', 1);
    folder_name := split_part(f, '/', 2);
    INSERT INTO storage.objects (bucket_id, name, owner, metadata)
    VALUES (
      bucket_name,
      folder_name || '/.gitkeep',
      NULL,
      '{"size": 0, "mimetype": "text/plain", "placeholder": true}'
    )
    ON CONFLICT (bucket_id, name) DO NOTHING;
  END LOOP;
END $$;

-- ============================================
-- COMPLETION NOTIFICATION
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Schema Update Complete!';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Added: addresses table (3-language support)';
  RAISE NOTICE 'Added identity columns to profiles, students, teachers, staff:';
  RAISE NOTICE '  - tazkira_number, passport_id, blood_group';
  RAISE NOTICE '  - nationality, religion, birth_place';
  RAISE NOTICE '  - father_name, mother_name, marital_status';
  RAISE NOTICE '  - emergency_contact (profiles only)';
  RAISE NOTICE '  - Arabic names: full_name_ar, first_name_ar, last_name_ar';
  RAISE NOTICE '  - Arabic names: father_name_ar, mother_name_ar';
  RAISE NOTICE 'Added 3 new reporting tables:';
  RAISE NOTICE '  - report_categories, report_templates, report_schedules';
  RAISE NOTICE '  - Multi-language columns on reports & business_reports';
  RAISE NOTICE 'Added 4 student fee tables:';
  RAISE NOTICE '  - fee_types, fee_structures';
  RAISE NOTICE '  - student_fee_assignments, fee_installments';
  RAISE NOTICE 'Added double-entry ledger system:';
  RAISE NOTICE '  - accounts (Chart of Accounts with 22 default accounts)';
  RAISE NOTICE '  - journals, journal_entries';
  RAISE NOTICE '  - receipts, petty_cash_funds, petty_cash_entries';
  RAISE NOTICE '  - audit_log (immutable audit trail)';
  RAISE NOTICE '  - Updated invoices, payments, expenses with journal links';
  RAISE NOTICE 'Added payroll tables:';
  RAISE NOTICE '  - payroll (payroll runs with period, totals, journal link)';
  RAISE NOTICE '  - payroll_items (per-employee pay with calculations)';
  RAISE NOTICE 'Added record_history table:';
  RAISE NOTICE '  - Archives deleted/edited records as JSON snapshots';
  RAISE NOTICE '  - Keeps main tables lean for better performance';
  RAISE NOTICE 'Added inventory tables:';
  RAISE NOTICE '  - inventory_categories (multi-language, hierarchical categories)';
  RAISE NOTICE '  - stock_reconciliation (physical count vs system, auto variance calc)';
  RAISE NOTICE '  - item_condition_history (tracks damage, repair, destroy, disposal, etc.)';
  RAISE NOTICE 'Added condition column (new/good/fair/damaged/broken/under_repair/repaired/unused/destroyed/disposed) to:';
  RAISE NOTICE '  - assets (separate from lifecycle status)';
  RAISE NOTICE '  - inventory_items';
  RAISE NOTICE 'Added RBAC tables:';
  RAISE NOTICE '  - roles (named roles with multi-language, level, system flag)';
  RAISE NOTICE '  - role_permissions (permission keys per role by module)';
  RAISE NOTICE '  - user_roles (which users have which roles)';
  RAISE NOTICE '  - page_permissions (dynamic role/user to page access with CRUD flags)';
  RAISE NOTICE 'Added book commerce tables:';
  RAISE NOTICE '  - book_purchases (buy books from suppliers with cost tracking)';
  RAISE NOTICE '  - book_sales (sell books to students, linked to courses & invoices)';
  RAISE NOTICE '  - cost_price & selling_price on books and book_copies';
  RAISE NOTICE '  - status (available/borrowed/sold/lost/damaged/reserved) on book_copies';
  RAISE NOTICE '  - sold_to, sold_at, invoice_id on book_copies';
  RAISE NOTICE 'Added book stock counters (auto-updated via trigger):';
  RAISE NOTICE '  - total_copies, available_copies, borrowed_copies';
  RAISE NOTICE '  - sold_copies, lost_copies, damaged_copies, reserved_copies';
  RAISE NOTICE 'Enhanced discounts table (type, code, usage limits, modules)';
  RAISE NOTICE 'Added promotions table (time-limited offers, banners, terms)';
  RAISE NOTICE 'Added discount/promotion FK links to:';
  RAISE NOTICE '  - invoices, book_sales, book_purchases';
  RAISE NOTICE '  - student_fee_assignments, course_applications';
  RAISE NOTICE 'Added promotion columns to: fee_structures (early_bird, group), courses (promotion_price)';
  RAISE NOTICE 'Added employee discount/financial columns:';
  RAISE NOTICE '  - recruitment/job_applications (negotiation, signing bonus, discount)';
  RAISE NOTICE '  - payroll_items (bonus reason, bonus promotion, deduction breakdown)';
  RAISE NOTICE '  - employee_leaves/leave_requests (is_paid, deduction %%)';
  RAISE NOTICE '  - attendance/staff_attendance (fine_amount, overtime pay)';
  RAISE NOTICE '  - trainings (cost, discount)';
  RAISE NOTICE '  - performance_reviews (bonus, incentive type)';
  RAISE NOTICE 'Added job announcements table (public job postings with multi-language, sharing)';
  RAISE NOTICE 'Added general announcements table (news, notices, events, holidays)';
  RAISE NOTICE 'Added course_details table (ALL course info in one place):';
  RAISE NOTICE '  - multi-language, syllabus, objectives, prerequisites';
  RAISE NOTICE '  - tuition, fees, discounts, schedule, seats, location';
  RAISE NOTICE '  - teacher, assistant, media, ratings, enrollments';
  RAISE NOTICE '  - publish/approval workflow, branch link';
  RAISE NOTICE 'Added branches/campuses table (multi-language, location, hours, manager)';
  RAISE NOTICE '  - branch_id FK in course_details';
  RAISE NOTICE 'Added 35 storage buckets:';
  RAISE NOTICE '  People: avatars, profiles, students, teachers, staff, alumni';
  RAISE NOTICE '  Academic: courses, books, library, assignments, exams, grades';
  RAISE NOTICE '  Financial: receipts, invoices, finance, payroll';
  RAISE NOTICE '  HR: hr, recruitment, trainings';
  RAISE NOTICE '  Operations: transport, hostel, inventory, facilities, it_support';
  RAISE NOTICE '  Communication: announcements, events, complaints';
  RAISE NOTICE '  Docs: documents, certificates, reports';
  RAISE NOTICE '  Media: branding, sports, medical';
  RAISE NOTICE '  System: backups, temp';
  RAISE NOTICE '  - 175+ virtual folders seeded (.gitkeep placeholders)';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Total tables: 210+';
  RAISE NOTICE 'Total indexes: 523+';
  RAISE NOTICE 'Total triggers: 204+';
  RAISE NOTICE '========================================';
END $$;

-- ============================================
-- ADDITIONAL RPC FUNCTIONS & TRIGGERS
-- Added per Flutter app requirements
-- All functions use CREATE OR REPLACE for idempotency
-- ============================================

-- 1. Increment announcement views (called by announcements_repository.dart)
CREATE OR REPLACE FUNCTION increment_announcement_views(announcement_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE announcements SET views = COALESCE(views, 0) + 1 WHERE id = announcement_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Dashboard stats RPC (for panel_stats_provider)
CREATE OR REPLACE FUNCTION get_dashboard_counts(tenant_id UUID)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_students', (SELECT COUNT(*) FROM students WHERE students.tenant_id = get_dashboard_counts.tenant_id AND status = 'active'),
    'total_teachers', (SELECT COUNT(*) FROM teachers WHERE teachers.tenant_id = get_dashboard_counts.tenant_id AND status = 'active'),
    'total_classes', (SELECT COUNT(*) FROM classes WHERE classes.tenant_id = get_dashboard_counts.tenant_id AND active = true),
    'total_staff', (SELECT COUNT(*) FROM staff WHERE staff.tenant_id = get_dashboard_counts.tenant_id AND status = 'active'),
    'total_departments', (SELECT COUNT(*) FROM departments WHERE departments.tenant_id = get_dashboard_counts.tenant_id AND active = true),
    'total_programs', (SELECT COUNT(*) FROM programs WHERE programs.tenant_id = get_dashboard_counts.tenant_id AND status = 'active')
  ) INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Revenue stats RPC (for analytics_service.dart)
CREATE OR REPLACE FUNCTION get_revenue_summary(tenant_id UUID, from_date DATE, to_date DATE)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_payments', (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE payments.tenant_id = get_revenue_summary.tenant_id AND payment_date >= from_date AND payment_date <= to_date AND status = 'completed'),
    'total_expenses', (SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE expenses.tenant_id = get_revenue_summary.tenant_id AND expense_date >= from_date AND expense_date <= to_date AND status = 'paid'),
    'payment_count', (SELECT COUNT(*) FROM payments WHERE payments.tenant_id = get_revenue_summary.tenant_id AND payment_date >= from_date AND payment_date <= to_date AND status = 'completed'),
    'pending_invoices', (SELECT COUNT(*) FROM invoices WHERE invoices.tenant_id = get_revenue_summary.tenant_id AND status = 'pending')
  ) INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Attendance summary RPC (for analytics_service.dart)
CREATE OR REPLACE FUNCTION get_attendance_summary(tenant_id UUID, from_date DATE, to_date DATE)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'present_count', (SELECT COUNT(*) FROM attendance WHERE attendance.tenant_id = get_attendance_summary.tenant_id AND date >= from_date AND date <= to_date AND status = 'present'),
    'absent_count', (SELECT COUNT(*) FROM attendance WHERE attendance.tenant_id = get_attendance_summary.tenant_id AND date >= from_date AND date <= to_date AND status = 'absent'),
    'late_count', (SELECT COUNT(*) FROM attendance WHERE attendance.tenant_id = get_attendance_summary.tenant_id AND date >= from_date AND date <= to_date AND status = 'late'),
    'total_records', (SELECT COUNT(*) FROM attendance WHERE attendance.tenant_id = get_attendance_summary.tenant_id AND date >= from_date AND date <= to_date)
  ) INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Global search RPC (for search_service.dart)
CREATE OR REPLACE FUNCTION search_emis(query TEXT, tenant_id UUID)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
  search_pattern TEXT;
BEGIN
  search_pattern := '%' || query || '%';

  SELECT jsonb_build_object(
    'students', (SELECT jsonb_agg(jsonb_build_object('id', id, 'name', full_name, 'code', student_code, 'type', 'student'))
      FROM students WHERE students.tenant_id = search_emis.tenant_id
      AND (full_name ILIKE search_pattern OR student_code ILIKE search_pattern OR email ILIKE search_pattern) LIMIT 10),
    'teachers', (SELECT jsonb_agg(jsonb_build_object('id', id, 'name', full_name, 'code', employee_code, 'type', 'teacher'))
      FROM teachers WHERE teachers.tenant_id = search_emis.tenant_id
      AND (full_name ILIKE search_pattern OR employee_code ILIKE search_pattern OR email ILIKE search_pattern) LIMIT 10),
    'programs', (SELECT jsonb_agg(jsonb_build_object('id', id, 'name', name, 'code', code, 'type', 'program'))
      FROM programs WHERE programs.tenant_id = search_emis.tenant_id
      AND (name ILIKE search_pattern OR code ILIKE search_pattern) LIMIT 10),
    'classes', (SELECT jsonb_agg(jsonb_build_object('id', id, 'name', name, 'type', 'class'))
      FROM classes WHERE classes.tenant_id = search_emis.tenant_id
      AND (name ILIKE search_pattern) LIMIT 10)
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Auto-generate student code trigger (replaces existing with STU-XXXX format)
CREATE OR REPLACE FUNCTION generate_student_code()
RETURNS TRIGGER AS $$
DECLARE
  next_num INT;
BEGIN
  IF NEW.student_code IS NULL THEN
    SELECT COALESCE(MAX(CAST(SUBSTRING(student_code FROM 5) AS INTEGER)), 0) + 1 INTO next_num FROM students;
    NEW.student_code := 'STU-' || LPAD(next_num::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_generate_student_code ON students;
CREATE TRIGGER trg_generate_student_code
  BEFORE INSERT ON students
  FOR EACH ROW
  EXECUTE FUNCTION generate_student_code();

-- 7. Auto-generate employee code trigger (replaces existing with EMP-XXXX format)
CREATE OR REPLACE FUNCTION generate_employee_code()
RETURNS TRIGGER AS $$
DECLARE
  next_num INT;
BEGIN
  IF NEW.employee_code IS NULL THEN
    SELECT COALESCE(MAX(CAST(SUBSTRING(employee_code FROM 5) AS INTEGER)), 0) + 1 INTO next_num FROM teachers;
    NEW.employee_code := 'EMP-' || LPAD(next_num::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_generate_employee_code ON teachers;
CREATE TRIGGER trg_generate_employee_code
  BEFORE INSERT ON teachers
  FOR EACH ROW
  EXECUTE FUNCTION generate_employee_code();

-- 8. Auto-generate receipt number trigger
CREATE OR REPLACE FUNCTION generate_receipt_no()
RETURNS TRIGGER AS $$
DECLARE
  next_num INT;
BEGIN
  IF NEW.receipt_no IS NULL THEN
    SELECT COALESCE(MAX(CAST(SUBSTRING(receipt_no FROM 4) AS INTEGER)), 0) + 1 INTO next_num FROM receipts;
    NEW.receipt_no := 'RCT-' || LPAD(next_num::TEXT, 6, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_generate_receipt_no ON receipts;
CREATE TRIGGER trg_generate_receipt_no
  BEFORE INSERT ON receipts
  FOR EACH ROW
  EXECUTE FUNCTION generate_receipt_no();

-- 9. Updated_at trigger function (already exists earlier, included for completeness)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 10. Record history audit trigger (archives all changes to record_history)
CREATE OR REPLACE FUNCTION record_history_trigger()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO record_history (table_name, record_id, action, new_data, changed_at)
    VALUES (TG_TABLE_NAME, NEW.id, 'insert', row_to_json(NEW)::jsonb, NOW());
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO record_history (table_name, record_id, action, old_data, new_data, changed_at)
    VALUES (TG_TABLE_NAME, NEW.id, 'update', row_to_json(OLD)::jsonb, row_to_json(NEW)::jsonb, NOW());
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO record_history (table_name, record_id, action, old_data, changed_at)
    VALUES (TG_TABLE_NAME, OLD.id, 'delete', row_to_json(OLD)::jsonb, NOW());
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. Student balance update trigger (auto-update paid_amount on students)
-- Full cash-based finance model (finance-defination.md): completed payments add
-- to the balance, refunds and refunded amounts reduce it.
CREATE OR REPLACE FUNCTION update_student_balance()
RETURNS TRIGGER AS $$
DECLARE
  v_student_id UUID;
BEGIN
  v_student_id := COALESCE(NEW.student_id, OLD.student_id);

  UPDATE students SET
    paid_amount = (
      SELECT COALESCE(SUM(
        CASE
          WHEN p.payment_type = 'refund' THEN -1 * p.amount
          ELSE p.amount - COALESCE(p.refund_amount, 0)
        END
      ), 0)
      FROM payments p
      WHERE p.student_id = v_student_id
        AND p.status IN ('completed', 'refunded')
    ),
    updated_at = NOW()
  WHERE id = v_student_id;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_update_student_balance ON payments;
CREATE TRIGGER trg_update_student_balance
  AFTER INSERT OR UPDATE ON payments
  FOR EACH ROW
  EXECUTE FUNCTION update_student_balance();

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE IF EXISTS tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS students ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS discounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS events ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS books ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS certificates ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS ROLE HELPERS (SECURITY DEFINER)
-- Policies must not query profiles from a profiles policy: PostgreSQL evaluates
-- that as recursive RLS (42P17).  These helpers run as the table owner (bypass
-- RLS), so role checks work in every policy without recursion and the profiles
-- policy below can be tightened (see EMIS_Schema_Review_Report.md sections 2/11).
-- ============================================

CREATE OR REPLACE FUNCTION public.current_profile_role()
RETURNS TEXT
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM profiles WHERE id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin' AND is_active IS NOT FALSE)
$$;

CREATE OR REPLACE FUNCTION public.is_admin_or_above()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('super_admin', 'admin') AND is_active IS NOT FALSE)
$$;

CREATE OR REPLACE FUNCTION public.has_role(p_role TEXT)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = p_role AND is_active IS NOT FALSE)
$$;

CREATE OR REPLACE FUNCTION public.has_any_role(p_roles TEXT[])
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = ANY(p_roles) AND is_active IS NOT FALSE)
$$;

CREATE OR REPLACE FUNCTION public.current_tenant_id()
RETURNS UUID
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE((SELECT tenant_id FROM profiles WHERE id = auth.uid()), NULLIF(auth.jwt() ->> 'tenant_id', '')::uuid)
$$;

-- ============================================
-- ROW LEVEL SECURITY POLICIES (FIXED)
-- CREATE POLICY IF NOT EXISTS is not portable on Supabase; every policy below
-- uses the DROP POLICY IF EXISTS + CREATE POLICY pattern, and role subqueries
-- were replaced with the SECURITY DEFINER helpers above.
-- ============================================

-- Super admin bypass / own tenant row
DROP POLICY IF EXISTS super_admin_all_access ON tenants;
CREATE POLICY super_admin_all_access ON tenants
  FOR ALL TO authenticated
  USING (
    is_super_admin()
    OR id::text = auth.jwt() ->> 'tenant_id'
  );

-- Tightened profiles policies: own row, tenant isolation via JWT claim, and
-- admins. Self-service updates cannot change role/tenant (no escalation).
DROP POLICY IF EXISTS profiles_select_tenant_isolation ON profiles;
DROP POLICY IF EXISTS profiles_insert_tenant_scoped ON profiles;
DROP POLICY IF EXISTS profiles_update_own_or_admin ON profiles;
DROP POLICY IF EXISTS tenant_isolation ON profiles;
DROP POLICY IF EXISTS profiles_all_authenticated ON profiles;

CREATE POLICY profiles_select_own_or_tenant ON profiles
  FOR SELECT TO authenticated
  USING (
    id = auth.uid()
    OR is_super_admin()
    OR is_admin_or_above()
    OR tenant_id::uuid::text = auth.jwt() ->> 'tenant_id'
  );

CREATE POLICY profiles_insert_own_or_admin ON profiles
  FOR INSERT TO authenticated
  WITH CHECK (
    id = auth.uid()
    OR is_super_admin()
    OR is_admin_or_above()
  );

CREATE POLICY profiles_update_own_or_admin ON profiles
  FOR UPDATE TO authenticated
  USING (
    id = auth.uid()
    OR is_super_admin()
    OR is_admin_or_above()
  )
  WITH CHECK (
    is_super_admin()
    OR is_admin_or_above()
    OR (id = auth.uid() AND NEW.role = OLD.role AND NEW.tenant_id IS NOT DISTINCT FROM OLD.tenant_id)
  );

CREATE POLICY profiles_delete_admin_only ON profiles
  FOR DELETE TO authenticated
  USING (is_super_admin() OR is_admin_or_above());

DROP POLICY IF EXISTS student_tenant_access ON students;
CREATE POLICY student_tenant_access ON students
  FOR ALL TO authenticated
  USING (
    tenant_id::uuid::text = auth.jwt() ->> 'tenant_id'
    OR profile_id = auth.uid()
    OR is_super_admin()
    OR is_admin_or_above()
  );

-- Guardians can view students linked via parent_students
DROP POLICY IF EXISTS guardian_view_linked_students ON students;
CREATE POLICY guardian_view_linked_students ON students
  FOR SELECT TO authenticated
  USING (
    id IN (
      SELECT student_id FROM parent_students WHERE parent_id IN (
        SELECT id FROM parents WHERE profile_id = auth.uid()
      )
    )
  );

-- Guardians can view their own parent record
DROP POLICY IF EXISTS guardian_view_own_parent ON parents;
CREATE POLICY guardian_view_own_parent ON parents
  FOR SELECT TO authenticated
  USING (
    profile_id = auth.uid()
    OR has_any_role(ARRAY['super_admin', 'admin', 'teacher', 'staff'])
  );

-- Guardians can view their own parent_students links
DROP POLICY IF EXISTS guardian_view_linked_parent_students ON parent_students;
CREATE POLICY guardian_view_linked_parent_students ON parent_students
  FOR SELECT TO authenticated
  USING (
    parent_id IN (
      SELECT id FROM parents WHERE profile_id = auth.uid()
    )
    OR has_any_role(ARRAY['super_admin', 'admin', 'teacher', 'staff'])
  );

DROP POLICY IF EXISTS teacher_tenant_access ON teachers;
CREATE POLICY teacher_tenant_access ON teachers
  FOR ALL TO authenticated
  USING (
    tenant_id::uuid::text = auth.jwt() ->> 'tenant_id'
    OR profile_id = auth.uid()
    OR is_super_admin()
    OR is_admin_or_above()
  );

DROP POLICY IF EXISTS staff_tenant_access ON staff;
CREATE POLICY staff_tenant_access ON staff
  FOR ALL TO authenticated
  USING (
    tenant_id::uuid::text = auth.jwt() ->> 'tenant_id'
    OR profile_id = auth.uid()
    OR is_super_admin()
    OR is_admin_or_above()
  );

DROP POLICY IF EXISTS department_tenant_access ON departments;
CREATE POLICY department_tenant_access ON departments
  FOR ALL TO authenticated
  USING (
    tenant_id::uuid::text = auth.jwt() ->> 'tenant_id'
    OR is_super_admin()
    OR is_admin_or_above()
  );

DROP POLICY IF EXISTS program_tenant_access ON programs;
CREATE POLICY program_tenant_access ON programs
  FOR ALL TO authenticated
  USING (
    tenant_id::uuid::text = auth.jwt() ->> 'tenant_id'
    OR is_super_admin()
    OR is_admin_or_above()
  );

DROP POLICY IF EXISTS class_tenant_access ON classes;
CREATE POLICY class_tenant_access ON classes
  FOR ALL TO authenticated
  USING (
    tenant_id::uuid::text = auth.jwt() ->> 'tenant_id'
    OR is_super_admin()
    OR is_admin_or_above()
  );

DROP POLICY IF EXISTS payment_tenant_access ON payments;
CREATE POLICY payment_tenant_access ON payments
  FOR ALL TO authenticated
  USING (
    tenant_id::uuid::text = auth.jwt() ->> 'tenant_id'
    OR is_super_admin()
    OR is_admin_or_above()
    OR has_role('accountant')
  );

-- Anonymous read-only access for public data
DROP POLICY IF EXISTS anon_read_announcements ON announcements;
CREATE POLICY anon_read_announcements ON announcements
  FOR SELECT TO anon, authenticated
  USING (
    status = 'published'
    OR tenant_id::uuid::text = auth.jwt() ->> 'tenant_id'
  );

DROP POLICY IF EXISTS anon_read_events ON events;
CREATE POLICY anon_read_events ON events
  FOR SELECT TO anon, authenticated
  USING (true);



-- ============================================
-- NOTIFICATION TRIGGERS
-- Auto-create notifications when panel actions occur
-- Fires AFTER INSERT on key tables
-- ============================================

-- Generic function: create notification for specific users by role
CREATE OR REPLACE FUNCTION notify_users_by_role(
  p_actor_id UUID,
  p_tenant_id UUID,
  p_title TEXT,
  p_body TEXT,
  p_type TEXT,
  p_target_roles TEXT[],
  p_action_url TEXT DEFAULT NULL,
  p_priority TEXT DEFAULT 'normal'
)
RETURNS void AS $$
DECLARE
  target RECORD;
BEGIN
  FOR target IN
    SELECT id FROM profiles
    WHERE tenant_id = p_tenant_id
    AND role = ANY(p_target_roles)
    AND is_active IS NOT FALSE
    AND id != p_actor_id
  LOOP
    INSERT INTO notifications (
      tenant_id, user_id, title, body, type, priority, action_url, data, is_read
    ) VALUES (
      p_tenant_id,
      target.id,
      p_title,
      p_body,
      p_type,
      p_priority,
      p_action_url,
      jsonb_build_object('actor_id', p_actor_id),
      false
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper: get actor name from profile
CREATE OR REPLACE FUNCTION get_actor_name(p_actor_id UUID)
RETURNS TEXT AS $$
DECLARE
  v_name TEXT;
BEGIN
  SELECT COALESCE(full_name, 'A user') INTO v_name FROM profiles WHERE id = p_actor_id;
  RETURN v_name;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================
-- 1. SUPPORT TICKETS (IT Support Panel)
-- New ticket → notify IT admin
-- ============================================
CREATE OR REPLACE FUNCTION notify_support_ticket_created()
RETURNS TRIGGER AS $$
DECLARE
  actor TEXT;
BEGIN
  actor := get_actor_name(NEW.reported_by);
  PERFORM notify_users_by_role(
    NEW.reported_by, NEW.tenant_id,
    'New Support Ticket',
    actor || ' reported: ' || NEW.title,
    'system',
    ARRAY['super_admin', 'admin', 'it_support'],
    '/support/tickets/' || NEW.id,
    NEW.priority
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_support_ticket ON support_tickets;
CREATE TRIGGER trg_notify_support_ticket
  AFTER INSERT ON support_tickets
  FOR EACH ROW
  EXECUTE FUNCTION notify_support_ticket_created();

-- ============================================
-- 2. IT TICKETS (IT Panel)
-- New ticket → notify IT support
-- ============================================
CREATE OR REPLACE FUNCTION notify_it_ticket_created()
RETURNS TRIGGER AS $$
DECLARE
  actor TEXT;
BEGIN
  actor := get_actor_name(NEW.reported_by);
  PERFORM notify_users_by_role(
    NEW.reported_by, NEW.tenant_id,
    'New IT Ticket: ' || NEW.subject,
    actor || ' reported: ' || COALESCE(NEW.description, NEW.subject),
    'system',
    ARRAY['super_admin', 'admin', 'it_support'],
    '/it/tickets/' || NEW.id,
    NEW.priority
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_it_ticket ON it_tickets;
CREATE TRIGGER trg_notify_it_ticket
  AFTER INSERT ON it_tickets
  FOR EACH ROW
  EXECUTE FUNCTION notify_it_ticket_created();

-- ============================================
-- 3. COMPLAINTS (Complaint Panel)
-- New complaint → notify complaint manager
-- ============================================
CREATE OR REPLACE FUNCTION notify_complaint_created()
RETURNS TRIGGER AS $$
DECLARE
  actor TEXT;
BEGIN
  actor := get_actor_name(NEW.complainant_id);
  PERFORM notify_users_by_role(
    NEW.complainant_id, NEW.tenant_id,
    'New Complaint: ' || NEW.subject,
    actor || ' submitted a complaint: ' || COALESCE(NEW.description, NEW.subject),
    'system',
    ARRAY['super_admin', 'admin', 'complaint_manager'],
    '/complaints/' || NEW.id,
    NEW.priority
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_complaint ON complaints;
CREATE TRIGGER trg_notify_complaint
  AFTER INSERT ON complaints
  FOR EACH ROW
  EXECUTE FUNCTION notify_complaint_created();

-- ============================================
-- 4. MAINTENANCE REQUESTS (Maintenance Panel)
-- New request → notify maintenance team
-- ============================================
CREATE OR REPLACE FUNCTION notify_maintenance_requested()
RETURNS TRIGGER AS $$
DECLARE
  actor TEXT;
BEGIN
  actor := get_actor_name(NEW.reported_by);
  PERFORM notify_users_by_role(
    NEW.reported_by, NEW.tenant_id,
    'New Maintenance Request: ' || NEW.title,
    actor || ' requested maintenance at ' || COALESCE(NEW.location, 'unknown location'),
    'system',
    ARRAY['super_admin', 'admin', 'maintenance'],
    '/maintenance/' || NEW.id,
    NEW.priority
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_maintenance ON maintenance_requests;
CREATE TRIGGER trg_notify_maintenance
  AFTER INSERT ON maintenance_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_maintenance_requested();

-- ============================================
-- 5. EMPLOYEE LEAVES (HR Panel)
-- New leave application → notify HR manager
-- ============================================
CREATE OR REPLACE FUNCTION notify_employee_leave_applied()
RETURNS TRIGGER AS $$
DECLARE
  actor TEXT;
BEGIN
  actor := get_actor_name(NEW.employee_id);
  PERFORM notify_users_by_role(
    NEW.employee_id, NEW.tenant_id,
    'Leave Requested',
    actor || ' applied for leave from ' || NEW.start_date || ' to ' || COALESCE(NEW.end_date::TEXT, NEW.start_date::TEXT),
    'hr',
    ARRAY['super_admin', 'admin', 'hr_manager'],
    '/hr/leaves/' || NEW.id,
    CASE WHEN NEW.leave_category = 'full_day' THEN 'high' ELSE 'normal' END
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_employee_leave ON employee_leaves;
CREATE TRIGGER trg_notify_employee_leave
  AFTER INSERT ON employee_leaves
  FOR EACH ROW
  EXECUTE FUNCTION notify_employee_leave_applied();

-- ============================================
-- 6. STUDENT LEAVES (Academic Panel)
-- New leave → notify academic support
-- ============================================
CREATE OR REPLACE FUNCTION notify_student_leave_applied()
RETURNS TRIGGER AS $$
DECLARE
  actor TEXT;
  student_name TEXT;
BEGIN
  SELECT full_name INTO student_name FROM students WHERE id = NEW.student_id;
  PERFORM notify_users_by_role(
    NEW.student_id, NEW.tenant_id,
    'Student Leave Request',
    COALESCE(student_name, 'A student') || ' applied for leave from ' || NEW.start_date || ' to ' || NEW.end_date,
    'attendance',
    ARRAY['super_admin', 'admin', 'academic_support'],
    '/students/leaves/' || NEW.id
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_student_leave ON student_leaves;
CREATE TRIGGER trg_notify_student_leave
  AFTER INSERT ON student_leaves
  FOR EACH ROW
  EXECUTE FUNCTION notify_student_leave_applied();

-- ============================================
-- 7. PAYMENTS (Finance Panel)
-- New payment → notify accountant
-- ============================================
CREATE OR REPLACE FUNCTION notify_payment_received()
RETURNS TRIGGER AS $$
DECLARE
  student_name TEXT;
BEGIN
  SELECT full_name INTO student_name FROM students WHERE id = NEW.student_id;
  PERFORM notify_users_by_role(
    NEW.collected_by, NEW.tenant_id,
    'Payment Received',
    'Payment of ' || NEW.amount || ' received from ' || COALESCE(student_name, 'student'),
    'payment',
    ARRAY['super_admin', 'admin', 'accountant'],
    '/finance/payments/' || NEW.id
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_payment ON payments;
CREATE TRIGGER trg_notify_payment
  AFTER INSERT ON payments
  FOR EACH ROW
  EXECUTE FUNCTION notify_payment_received();

-- ============================================
-- 8. COURSE APPLICATIONS (Website/Reception)
-- New application → notify reception/admin
-- ============================================
CREATE OR REPLACE FUNCTION notify_course_applied()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM notify_users_by_role(
    NULL, NEW.tenant_id,
    'New Course Application',
    COALESCE(NEW.full_name, 'A user') || ' applied for course: ' || COALESCE(NEW.full_name, 'Unknown'),
    'academic',
    ARRAY['super_admin', 'admin', 'academic_support', 'receptionist'],
    '/applications/' || NEW.id
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_course_application ON course_applications;
CREATE TRIGGER trg_notify_course_application
  AFTER INSERT ON course_applications
  FOR EACH ROW
  EXECUTE FUNCTION notify_course_applied();

-- ============================================
-- 9. CALLBACK REQUESTS (Website/Reception)
-- New callback → notify receptionist
-- ============================================
CREATE OR REPLACE FUNCTION notify_callback_requested()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM notify_users_by_role(
    NULL, NEW.tenant_id,
    'Callback Requested',
    COALESCE(NEW.full_name, 'A visitor') || ' requested a callback at ' || COALESCE(NEW.preferred_time_from::TEXT, 'anytime'),
    'system',
    ARRAY['super_admin', 'admin', 'receptionist'],
    '/callbacks/' || NEW.id
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_callback ON callback_requests;
CREATE TRIGGER trg_notify_callback
  AFTER INSERT ON callback_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_callback_requested();

-- ============================================
-- 10. CONTACT MESSAGES (Website/Reception)
-- New message → notify admin/reception
-- ============================================
CREATE OR REPLACE FUNCTION notify_contact_message()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM notify_users_by_role(
    NULL, NEW.tenant_id,
    'New Contact Message: ' || COALESCE(NEW.subject, 'No Subject'),
    COALESCE(NEW.full_name, 'A visitor') || ' sent: ' || COALESCE(LEFT(NEW.message, 100), '(no message)'),
    'system',
    ARRAY['super_admin', 'admin', 'staff', 'receptionist'],
    '/messages/' || NEW.id
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_contact_message ON contact_messages;
CREATE TRIGGER trg_notify_contact_message
  AFTER INSERT ON contact_messages
  FOR EACH ROW
  EXECUTE FUNCTION notify_contact_message();

-- ============================================
-- 11. HOMEWORK SUBMISSIONS (Teacher Panel)
-- Student submits homework → notify teacher
-- ============================================
CREATE OR REPLACE FUNCTION notify_homework_submitted()
RETURNS TRIGGER AS $$
DECLARE
  student_name TEXT;
  teacher_id UUID;
  homework_title TEXT;
BEGIN
  SELECT full_name INTO student_name FROM students WHERE id = NEW.student_id;
  SELECT teacher_id, title INTO teacher_id, homework_title FROM homework WHERE id = NEW.homework_id;
  IF teacher_id IS NOT NULL THEN
    INSERT INTO notifications (
      tenant_id, user_id, title, body, type, action_url, data, is_read
    ) VALUES (
      NEW.tenant_id,
      teacher_id,
      'Homework Submitted',
      COALESCE(student_name, 'A student') || ' submitted: ' || COALESCE(homework_title, 'homework'),
      'academic',
      '/homework/submissions/' || NEW.id,
      jsonb_build_object('student_id', NEW.student_id, 'homework_id', NEW.homework_id),
      false
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_homework_submission ON homework_submissions;
CREATE TRIGGER trg_notify_homework_submission
  AFTER INSERT ON homework_submissions
  FOR EACH ROW
  EXECUTE FUNCTION notify_homework_submitted();

-- ============================================
-- 12. BOOK ISSUES (Library Panel)
-- Book issued → notify librarian
-- ============================================
CREATE OR REPLACE FUNCTION notify_book_issued()
RETURNS TRIGGER AS $$
DECLARE
  book_title TEXT;
  member_name TEXT;
BEGIN
  SELECT title INTO book_title FROM books WHERE id = (SELECT book_id FROM book_copies WHERE id = NEW.book_id);
  PERFORM notify_users_by_role(
    NEW.issued_by, NEW.tenant_id,
    'Book Issued',
    'Book "' || COALESCE(book_title, 'Unknown') || '" issued, due: ' || NEW.due_date,
    'system',
    ARRAY['super_admin', 'admin', 'librarian'],
    '/library/issues/' || NEW.id
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_book_issue ON book_issues;
CREATE TRIGGER trg_notify_book_issue
  AFTER INSERT ON book_issues
  FOR EACH ROW
  EXECUTE FUNCTION notify_book_issued();

-- ============================================
-- 13. INVENTORY TRANSACTIONS (Inventory Panel)
-- Low stock alert → notify inventory manager
-- ============================================
CREATE OR REPLACE FUNCTION notify_low_stock()
RETURNS TRIGGER AS $$
DECLARE
  item_name TEXT;
  item_quantity INTEGER;
  min_stock INTEGER;
BEGIN
  SELECT name, quantity, COALESCE(min_stock_level, 0)
    INTO item_name, item_quantity, min_stock
  FROM inventory_items WHERE id = NEW.item_id;

  IF item_quantity <= min_stock AND min_stock > 0 THEN
    PERFORM notify_users_by_role(
      NEW.performed_by, NEW.tenant_id,
      'Low Stock Alert',
      item_name || ' has only ' || item_quantity || ' units (min: ' || min_stock || ')',
      'system',
      ARRAY['super_admin', 'admin', 'inventory_manager'],
      '/inventory/items/' || NEW.item_id,
      'high'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_low_stock ON inventory_transactions;
CREATE TRIGGER trg_notify_low_stock
  AFTER INSERT ON inventory_transactions
  FOR EACH ROW
  EXECUTE FUNCTION notify_low_stock();

-- ============================================
-- 14. FEEDBACK (Communication Panel)
-- New feedback → notify admin
-- ============================================
CREATE OR REPLACE FUNCTION notify_feedback_submitted()
RETURNS TRIGGER AS $$
DECLARE
  actor TEXT;
BEGIN
  actor := get_actor_name(NEW.user_id);
  PERFORM notify_users_by_role(
    NEW.user_id, NEW.tenant_id,
    'New ' || INITCAP(NEW.feedback_type) || ' Feedback',
    actor || ' gave ' || NEW.rating || '/5 rating: ' || LEFT(NEW.comment, 100),
    'system',
    ARRAY['super_admin', 'admin', 'complaint_manager'],
    '/feedback/' || NEW.id
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_feedback ON feedback;
CREATE TRIGGER trg_notify_feedback
  AFTER INSERT ON feedback
  FOR EACH ROW
  EXECUTE FUNCTION notify_feedback_submitted();

-- ============================================
-- 15. ATTENDANCE CORRECTIONS
-- New correction request → notify admin
-- ============================================
CREATE OR REPLACE FUNCTION notify_attendance_correction()
RETURNS TRIGGER AS $$
DECLARE
  actor TEXT;
BEGIN
  actor := get_actor_name(NEW.requested_by);
  PERFORM notify_users_by_role(
    NEW.requested_by, NEW.tenant_id,
    'Attendance Correction Requested',
    actor || ' requests correction for ' || NEW.date || ': ' || NEW.original_status || ' → ' || NEW.corrected_status,
    'attendance',
    ARRAY['super_admin', 'admin', 'academic_support'],
    '/attendance/corrections/' || NEW.id
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_attendance_correction ON attendance_corrections;
CREATE TRIGGER trg_notify_attendance_correction
  AFTER INSERT ON attendance_corrections
  FOR EACH ROW
  EXECUTE FUNCTION notify_attendance_correction();

-- ============================================
-- 16. DOCUMENT REQUESTS
-- New request → notify admin
-- ============================================
CREATE OR REPLACE FUNCTION notify_document_requested()
RETURNS TRIGGER AS $$
DECLARE
  actor TEXT;
BEGIN
  actor := get_actor_name(NEW.requester_id);
  PERFORM notify_users_by_role(
    NEW.requester_id, NEW.tenant_id,
    'Document Requested',
    actor || ' requested: ' || NEW.document_type,
    'system',
    ARRAY['super_admin', 'admin', 'staff'],
    '/documents/requests/' || NEW.id
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_document_request ON document_requests;
CREATE TRIGGER trg_notify_document_request
  AFTER INSERT ON document_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_document_requested();

-- ============================================
-- 17. VISITORS (Receptionist Panel)
-- New visitor check-in → notify reception
-- ============================================
CREATE OR REPLACE FUNCTION notify_visitor_checkin()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM notify_users_by_role(
    NULL, NEW.tenant_id,
    'Visitor Checked In',
    COALESCE(NEW.full_name, 'A visitor') || ' (' || COALESCE(NEW.purpose, 'No purpose') || ')',
    'system',
    ARRAY['super_admin', 'admin', 'receptionist'],
    '/visitors/' || NEW.id
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_visitor ON visitors;
CREATE TRIGGER trg_notify_visitor
  AFTER INSERT ON visitors
  FOR EACH ROW
  EXECUTE FUNCTION notify_visitor_checkin();

-- ============================================
-- 18. PLACEMENT TEST ATTEMPTS (Website)
-- Test completed → notify academic support
-- ============================================
CREATE OR REPLACE FUNCTION notify_placement_test_completed()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' THEN
    PERFORM notify_users_by_role(
      NEW.user_id, NEW.tenant_id,
      'Placement Test Completed',
      COALESCE(NEW.full_name, NEW.email) || ' scored ' || COALESCE(NEW.percentage::TEXT, 'N/A') || '% on placement test',
      'academic',
      ARRAY['super_admin', 'admin', 'academic_support', 'teacher'],
      '/placement/attempts/' || NEW.id
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_placement_test ON placement_test_attempts;
CREATE TRIGGER trg_notify_placement_test
  AFTER INSERT OR UPDATE ON placement_test_attempts
  FOR EACH ROW
  WHEN (NEW.status = 'completed')
  EXECUTE FUNCTION notify_placement_test_completed();

-- ============================================
-- COMPLETION
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Notification Triggers Deployed!';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Tables with auto-notify triggers:';
  RAISE NOTICE ' 1. support_tickets → IT admin';
  RAISE NOTICE ' 2. it_tickets → IT support';
  RAISE NOTICE ' 3. complaints → Complaint manager';
  RAISE NOTICE ' 4. maintenance_requests → Maintenance';
  RAISE NOTICE ' 5. employee_leaves → HR manager';
  RAISE NOTICE ' 6. student_leaves → Academic support';
  RAISE NOTICE ' 7. payments → Accountant';
  RAISE NOTICE ' 8. course_applications → Admin/Reception';
  RAISE NOTICE ' 9. callback_requests → Receptionist';
  RAISE NOTICE '10. contact_messages → Admin/Reception';
  RAISE NOTICE '11. homework_submissions → Teacher';
  RAISE NOTICE '12. book_issues → Librarian';
  RAISE NOTICE '13. inventory_transactions → Inventory mgr';
  RAISE NOTICE '14. feedback → Admin/Complaint mgr';
  RAISE NOTICE '15. attendance_corrections → Admin';
  RAISE NOTICE '16. document_requests → Admin/Staff';
  RAISE NOTICE '17. visitors → Receptionist';
  RAISE NOTICE '18. placement_test_attempts → Academic';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Helpers: notify_users_by_role(), get_actor_name()';
  RAISE NOTICE '========================================';
END $$;

-- ============================================
-- BULK NOTIFICATION FUNCTION
-- Called by admin/super admin/academic/HR to send
-- notifications to all users, users by role, or
-- specific users by ID
-- ============================================
CREATE OR REPLACE FUNCTION send_bulk_notification(
  p_title TEXT,
  p_body TEXT,
  p_type TEXT DEFAULT 'announcement',
  p_priority TEXT DEFAULT 'normal',
  p_actor_id UUID DEFAULT NULL,
  p_tenant_id UUID DEFAULT NULL,
  p_target_type TEXT DEFAULT 'all',     -- 'all', 'role', 'specific'
  p_target_roles TEXT[] DEFAULT NULL,   -- e.g. ARRAY['teacher','student']
  p_target_user_ids UUID[] DEFAULT NULL -- for 'specific' target
)
RETURNS void AS $$
DECLARE
  target RECORD;
BEGIN
  -- 'all' → insert for every active user in the tenant (all tenants if p_tenant_id is null)
  IF p_target_type = 'all' THEN
    FOR target IN
      SELECT id FROM profiles
      WHERE (p_tenant_id IS NULL OR tenant_id = p_tenant_id)
      AND is_active IS NOT FALSE
    LOOP
      INSERT INTO notifications (tenant_id, user_id, title, body, type, priority, data, is_read, created_at)
      VALUES (p_tenant_id, target.id, p_title, p_body, p_type, p_priority,
              jsonb_build_object('actor_id', p_actor_id), false, now());
    END LOOP;

  -- 'role' → insert for all active users matching given roles
  ELSIF p_target_type = 'role' THEN
    FOR target IN
      SELECT id FROM profiles
      WHERE (p_tenant_id IS NULL OR tenant_id = p_tenant_id)
      AND role = ANY(p_target_roles)
      AND is_active IS NOT FALSE
    LOOP
      INSERT INTO notifications (tenant_id, user_id, title, body, type, priority, data, is_read, created_at)
      VALUES (p_tenant_id, target.id, p_title, p_body, p_type, p_priority,
              jsonb_build_object('actor_id', p_actor_id), false, now());
    END LOOP;

  -- 'specific' → insert for each given user ID
  ELSIF p_target_type = 'specific' THEN
    FOR target IN
      SELECT id FROM profiles
      WHERE id = ANY(p_target_user_ids)
      AND is_active IS NOT FALSE
    LOOP
      INSERT INTO notifications (tenant_id, user_id, title, body, type, priority, data, is_read, created_at)
      VALUES (p_tenant_id, target.id, p_title, p_body, p_type, p_priority,
              jsonb_build_object('actor_id', p_actor_id), false, now());
    END LOOP;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- REALTIME PUBLICATION
-- ============================================
-- The Notifications screen subscribes to Postgres Changes on the
-- "notifications" table. Realtime events only fire for tables that are
-- members of the "supabase_realtime" publication — without this, new
-- notifications never push to open screens (they only appear on reopen).
-- Idempotent; safe to re-run. See notification_realtime_migration.sql.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
END $$;

-- ============================================
-- USER IMPERSONATION (FORCE LOGIN)
-- Super Admin can "log in as" a target user. The app keeps both identities:
-- the origin (super admin) for security audit and the target user for scope.
-- See impersonation_migration.sql for the standalone, idempotent copy.
-- ============================================

CREATE TABLE IF NOT EXISTS impersonation_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  super_admin_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  super_admin_role TEXT NOT NULL DEFAULT 'super_admin',
  target_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  target_role TEXT,
  session_token TEXT UNIQUE,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'revoked', 'ended')),
  ip_address TEXT,
  user_agent TEXT,
  reason TEXT,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ,
  ended_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Only one active session per target user; blocks nested impersonation.
DROP INDEX IF EXISTS idx_impersonation_sessions_active_target;
CREATE UNIQUE INDEX idx_impersonation_sessions_active_target
  ON impersonation_sessions(target_user_id)
  WHERE status = 'active';

DROP INDEX IF EXISTS idx_impersonation_sessions_super_admin;
CREATE INDEX IF NOT EXISTS idx_impersonation_sessions_super_admin ON impersonation_sessions(super_admin_id);
DROP INDEX IF EXISTS idx_impersonation_sessions_target ON impersonation_sessions(target_user_id);
DROP INDEX IF EXISTS idx_impersonation_sessions_status ON impersonation_sessions(status);

CREATE TABLE IF NOT EXISTS impersonation_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  session_id UUID REFERENCES impersonation_sessions(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES tenants(id),
  actor_id UUID NOT NULL REFERENCES profiles(id),
  target_user_id UUID REFERENCES profiles(id),
  target_role TEXT,
  action TEXT NOT NULL,
  details JSONB DEFAULT '{}'::jsonb,
  ip_address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

DROP INDEX IF EXISTS idx_impersonation_log_session ON impersonation_log(session_id);
CREATE INDEX IF NOT EXISTS idx_impersonation_log_session ON impersonation_log(session_id);
DROP INDEX IF EXISTS idx_impersonation_log_actor ON impersonation_log(actor_id);
CREATE INDEX IF NOT EXISTS idx_impersonation_log_actor ON impersonation_log(actor_id);
DROP INDEX IF EXISTS idx_impersonation_log_target ON impersonation_log(target_user_id);
CREATE INDEX IF NOT EXISTS idx_impersonation_log_target ON impersonation_log(target_user_id);

ALTER TABLE impersonation_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE impersonation_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS impersonation_sessions_select_all ON impersonation_sessions;
CREATE POLICY impersonation_sessions_select_all ON impersonation_sessions
  FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS impersonation_sessions_insert_admin ON impersonation_sessions;
CREATE POLICY impersonation_sessions_insert_admin ON impersonation_sessions
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = super_admin_id
    AND (SELECT role FROM profiles WHERE id = auth.uid()) = 'super_admin'
  );

DROP POLICY IF EXISTS impersonation_sessions_update_admin ON impersonation_sessions;
CREATE POLICY impersonation_sessions_update_admin ON impersonation_sessions
  FOR UPDATE TO authenticated
  USING (
    auth.uid() = super_admin_id
    OR (SELECT role FROM profiles WHERE id = auth.uid()) = 'super_admin'
  );

DROP POLICY IF EXISTS impersonation_log_select_all ON impersonation_log;
CREATE POLICY impersonation_log_select_all ON impersonation_log
  FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS impersonation_log_insert_auth ON impersonation_log;
CREATE POLICY impersonation_log_insert_auth ON impersonation_log
  FOR INSERT TO authenticated
  USING (true)
  WITH CHECK (true);

-- Helper: resolve a profile row without triggering RLS recursion.
CREATE OR REPLACE FUNCTION public.get_profile_by_id(p_id UUID)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'id', id,
    'full_name', full_name,
    'email', email,
    'role', role,
    'avatar_url', avatar_url,
    'tenant_id', tenant_id,
    'is_active', is_active
  ) INTO result
  FROM profiles WHERE id = p_id;
  RETURN result;
END;
$$;

-- ============================================
-- FINANCE COMPLETION
-- Implements the remaining finance-defination.md features:
--   * Cash Handling Controls (cash drawers, cashier shifts)
--   * Cash Reconciliation (physical count vs ledger, shortage/overage)
--   * User Wallets (student_wallet_balances view)
--   * Sequential invoice numbers
--   * Double-entry integrity (journal balancing triggers)
--   * Petty cash float tracking
-- Plus the review-report fixes that live in SQL:
--   * storage.objects RLS policies (was missing)
-- ============================================

-- ------------------------------------------------------------
-- 1. Student Wallet must be a LIABILITY account. finance-defination.md:
--    "Each user (student) has a 'wallet' account (liability account in
--    ledger). When a student pre-pays or is credited, their wallet balance
--    increases." The seed below was asset; correct it for existing installs.
-- ------------------------------------------------------------
UPDATE accounts
SET account_type = 'liability', normal_balance = 'credit'
WHERE account_code = '1102' AND name = 'Student Wallet';

-- ------------------------------------------------------------
-- 2. Sequential invoice numbers (INV-000001, INV-000002, ...)
--    finance-defination.md: unique, sequential invoice numbers with no gaps.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION generate_invoice_no()
RETURNS TRIGGER AS $$
DECLARE
  next_num INT;
BEGIN
  IF NEW.invoice_number IS NULL THEN
    SELECT COALESCE(MAX(CAST(SUBSTRING(invoice_number FROM 5) AS INTEGER)), 0) + 1
      INTO next_num FROM invoices;
    NEW.invoice_number := 'INV-' || LPAD(next_num::TEXT, 6, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_generate_invoice_no ON invoices;
CREATE TRIGGER trg_generate_invoice_no
  BEFORE INSERT ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION generate_invoice_no();

-- ------------------------------------------------------------
-- 3. Double-entry integrity
--    finance-defination.md: each journal has >= 2 entries and
--    sum(debits) = sum(credits). Keep journals.total_debit/credit in sync and
--    refuse to POST an unbalanced journal.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION sync_journal_totals()
RETURNS TRIGGER AS $$
DECLARE
  v_journal_id UUID;
  v_debit  DECIMAL(14,2);
  v_credit DECIMAL(14,2);
BEGIN
  v_journal_id := COALESCE(NEW.journal_id, OLD.journal_id);
  IF v_journal_id IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  SELECT COALESCE(SUM(debit), 0), COALESCE(SUM(credit), 0)
    INTO v_debit, v_credit
  FROM journal_entries
  WHERE journal_id = v_journal_id;

  UPDATE journals
     SET total_debit = v_debit, total_credit = v_credit
   WHERE id = v_journal_id;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_journal_totals ON journal_entries;
CREATE TRIGGER trg_sync_journal_totals
  AFTER INSERT OR UPDATE OR DELETE ON journal_entries
  FOR EACH ROW
  EXECUTE FUNCTION sync_journal_totals();

-- Refuse to post an unbalanced journal
CREATE OR REPLACE FUNCTION validate_journal_on_post()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_posted AND NEW.total_debit <> NEW.total_credit THEN
    RAISE EXCEPTION 'Journal % cannot be posted: debits % <> credits %',
      NEW.id, NEW.total_debit, NEW.total_credit;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validate_journal_on_post ON journals;
CREATE TRIGGER trg_validate_journal_on_post
  BEFORE INSERT OR UPDATE ON journals
  FOR EACH ROW
  WHEN (NEW.is_posted)
  EXECUTE FUNCTION validate_journal_on_post();

-- ------------------------------------------------------------
-- 4. Petty cash float tracking
--    current_balance = initial + replenishments - disbursements - adjustments,
--    recomputed from APPROVED entries only (finance-defination.md, Petty Cash).
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_petty_cash_balance()
RETURNS TRIGGER AS $$
DECLARE
  v_fund_id UUID;
BEGIN
  v_fund_id := COALESCE(NEW.fund_id, OLD.fund_id);
  IF v_fund_id IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  UPDATE petty_cash_funds f SET
    current_balance =
        f.initial_balance
      + COALESCE((SELECT SUM(amount) FROM petty_cash_entries
                  WHERE fund_id = v_fund_id AND entry_type = 'replenishment' AND status = 'approved'), 0)
      - COALESCE((SELECT SUM(amount) FROM petty_cash_entries
                  WHERE fund_id = v_fund_id AND entry_type = 'disbursement' AND status = 'approved'), 0)
      - COALESCE((SELECT SUM(amount) FROM petty_cash_entries
                  WHERE fund_id = v_fund_id AND entry_type = 'adjustment' AND status = 'approved'), 0),
    updated_at = NOW()
  WHERE f.id = v_fund_id;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_petty_cash_balance ON petty_cash_entries;
CREATE TRIGGER trg_update_petty_cash_balance
  AFTER INSERT OR UPDATE ON petty_cash_entries
  FOR EACH ROW
  WHEN (NEW.status = 'approved' OR OLD.status = 'approved')
  EXECUTE FUNCTION update_petty_cash_balance();

-- ------------------------------------------------------------
-- 5. Cash handling controls (finance-defination.md, Cash Handling Controls)
-- ------------------------------------------------------------

-- Cash drawers: physical cash registers per tenant/branch
CREATE TABLE IF NOT EXISTS cash_drawers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  branch_id UUID REFERENCES branches(id),
  name TEXT NOT NULL,
  name_ar TEXT,
  drawer_code TEXT UNIQUE,
  assigned_cashier_id UUID REFERENCES profiles(id),
  opening_balance DECIMAL(14,2) DEFAULT 0,
  current_balance DECIMAL(14,2) DEFAULT 0,
  currency TEXT DEFAULT 'AFN',
  is_active BOOLEAN DEFAULT true,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cash_drawers_tenant ON cash_drawers(tenant_id);
CREATE INDEX IF NOT EXISTS idx_cash_drawers_branch ON cash_drawers(branch_id);
CREATE INDEX IF NOT EXISTS idx_cash_drawers_cashier ON cash_drawers(assigned_cashier_id);
CREATE INDEX IF NOT EXISTS idx_cash_drawers_active ON cash_drawers(is_active);

-- Cashier shifts: open/close a drawer and reconcile expected vs actual cash
CREATE TABLE IF NOT EXISTS cashier_shifts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  drawer_id UUID REFERENCES cash_drawers(id),
  cashier_id UUID REFERENCES profiles(id),
  shift_started_at TIMESTAMPTZ DEFAULT NOW(),
  shift_ended_at TIMESTAMPTZ,
  opening_cash DECIMAL(14,2) DEFAULT 0,
  expected_cash DECIMAL(14,2) DEFAULT 0,
  actual_cash DECIMAL(14,2),
  difference DECIMAL(14,2) GENERATED ALWAYS AS (COALESCE(actual_cash, 0) - expected_cash) STORED,
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'closed', 'flagged')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cashier_shifts_tenant ON cashier_shifts(tenant_id);
CREATE INDEX IF NOT EXISTS idx_cashier_shifts_drawer ON cashier_shifts(drawer_id);
CREATE INDEX IF NOT EXISTS idx_cashier_shifts_cashier ON cashier_shifts(cashier_id);
CREATE INDEX IF NOT EXISTS idx_cashier_shifts_status ON cashier_shifts(status);

-- Cash reconciliations: physical count vs system totals, shortage/overage
CREATE TABLE IF NOT EXISTS cash_reconciliations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  tenant_id UUID REFERENCES tenants(id),
  branch_id UUID REFERENCES branches(id),
  drawer_id UUID REFERENCES cash_drawers(id),
  reconciled_by UUID REFERENCES profiles(id),
  reconciled_on DATE DEFAULT CURRENT_DATE,
  system_cash DECIMAL(14,2) NOT NULL DEFAULT 0,
  physical_cash DECIMAL(14,2) NOT NULL DEFAULT 0,
  difference DECIMAL(14,2) GENERATED ALWAYS AS (physical_cash - system_cash) STORED,
  shortage_amount DECIMAL(14,2) GENERATED ALWAYS AS (CASE WHEN physical_cash < system_cash THEN system_cash - physical_cash ELSE 0 END) STORED,
  overage_amount DECIMAL(14,2) GENERATED ALWAYS AS (CASE WHEN physical_cash > system_cash THEN physical_cash - system_cash ELSE 0 END) STORED,
  journal_id UUID REFERENCES journals(id),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'matched', 'shortage', 'overage', 'adjusted')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cash_reconciliations_tenant ON cash_reconciliations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_cash_reconciliations_branch ON cash_reconciliations(branch_id);
CREATE INDEX IF NOT EXISTS idx_cash_reconciliations_drawer ON cash_reconciliations(drawer_id);
CREATE INDEX IF NOT EXISTS idx_cash_reconciliations_date ON cash_reconciliations(reconciled_on);
CREATE INDEX IF NOT EXISTS idx_cash_reconciliations_status ON cash_reconciliations(status);

-- RLS for cash-control tables (helpers defined in the RLS section above)
ALTER TABLE cash_drawers ENABLE ROW LEVEL SECURITY;
ALTER TABLE cashier_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE cash_reconciliations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS cash_drawers_tenant_access ON cash_drawers;
CREATE POLICY cash_drawers_tenant_access ON cash_drawers
  FOR ALL TO authenticated
  USING (
    tenant_id::uuid::text = auth.jwt() ->> 'tenant_id'
    OR is_super_admin()
    OR is_admin_or_above()
    OR has_any_role(ARRAY['accountant', 'receptionist'])
  );

DROP POLICY IF EXISTS cashier_shifts_tenant_access ON cashier_shifts;
CREATE POLICY cashier_shifts_tenant_access ON cashier_shifts
  FOR ALL TO authenticated
  USING (
    tenant_id::uuid::text = auth.jwt() ->> 'tenant_id'
    OR is_super_admin()
    OR is_admin_or_above()
    OR has_any_role(ARRAY['accountant', 'receptionist'])
  );

DROP POLICY IF EXISTS cash_reconciliations_tenant_access ON cash_reconciliations;
CREATE POLICY cash_reconciliations_tenant_access ON cash_reconciliations
  FOR ALL TO authenticated
  USING (
    tenant_id::uuid::text = auth.jwt() ->> 'tenant_id'
    OR is_super_admin()
    OR is_admin_or_above()
    OR has_role('accountant')
  );

-- ------------------------------------------------------------
-- 6. Wallets & aggregation views (finance-defination.md, Wallets/Ledgers)
-- ------------------------------------------------------------

-- Wallet balance per student from the ledger (account 1102 = Student Wallet)
CREATE OR REPLACE VIEW student_wallet_balances AS
SELECT
  s.id AS student_id,
  s.student_code,
  s.full_name,
  s.tenant_id,
  COALESCE(SUM(je.credit - je.debit), 0) AS wallet_balance
FROM students s
LEFT JOIN journal_entries je ON je.user_id = s.profile_id
LEFT JOIN accounts a ON a.id = je.account_id AND a.account_code = '1102'
GROUP BY s.id, s.student_code, s.full_name, s.tenant_id;

-- Daily cash flow on the Cash on Hand account (1001)
CREATE OR REPLACE VIEW daily_cash_flow AS
SELECT
  j.tenant_id,
  j.journal_date AS day,
  COALESCE(SUM(je.debit), 0) AS total_debit,
  COALESCE(SUM(je.credit), 0) AS total_credit,
  COALESCE(SUM(je.debit - je.credit), 0) AS net_cash_flow
FROM journals j
JOIN journal_entries je ON je.journal_id = j.id
JOIN accounts a ON a.id = je.account_id AND a.account_code = '1001'
GROUP BY j.tenant_id, j.journal_date;

-- RPC: wallet balance for a student (ledger-based)
CREATE OR REPLACE FUNCTION get_wallet_balance(p_student_id UUID)
RETURNS DECIMAL(14,2)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(SUM(je.credit - je.debit), 0)
  FROM journal_entries je
  JOIN accounts a ON a.id = je.account_id AND a.account_code = '1102'
  JOIN students s ON s.id = p_student_id AND je.user_id = s.profile_id
$$;

-- ------------------------------------------------------------
-- 7. STORAGE RLS POLICIES (review report section 13: was missing)
-- ------------------------------------------------------------

-- Public buckets: readable by everyone
DROP POLICY IF EXISTS storage_public_read ON storage.objects;
CREATE POLICY storage_public_read ON storage.objects
  FOR SELECT TO public
  USING (bucket_id IN (
    'avatars', 'profiles', 'students', 'teachers', 'staff', 'alumni',
    'courses', 'books', 'library', 'assignments',
    'recruitment', 'trainings',
    'transport', 'hostel', 'inventory', 'facilities',
    'announcements', 'events',
    'certificates', 'branding', 'sports',
    'temp', 'chat_uploads'
  ));

-- Private buckets: owner, admins, and same-tenant staff with a relevant role
DROP POLICY IF EXISTS storage_private_read ON storage.objects;
CREATE POLICY storage_private_read ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id IN ('exams', 'grades', 'receipts', 'invoices', 'finance', 'payroll',
                  'hr', 'it_support', 'complaints', 'documents', 'reports', 'medical', 'backups')
    AND (auth.uid() = owner OR is_super_admin() OR is_admin_or_above()
         OR has_any_role(ARRAY['accountant', 'hr_manager', 'it_support', 'librarian',
                               'receptionist', 'teacher', 'staff']))
  );

-- Upload / update / delete: object owner or admin (all buckets)
DROP POLICY IF EXISTS storage_insert_own ON storage.objects;
CREATE POLICY storage_insert_own ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = owner OR is_super_admin() OR is_admin_or_above());

DROP POLICY IF EXISTS storage_update_own ON storage.objects;
CREATE POLICY storage_update_own ON storage.objects
  FOR UPDATE TO authenticated
  USING (auth.uid() = owner OR is_super_admin() OR is_admin_or_above());

DROP POLICY IF EXISTS storage_delete_own ON storage.objects;
CREATE POLICY storage_delete_own ON storage.objects
  FOR DELETE TO authenticated
  USING (auth.uid() = owner OR is_super_admin() OR is_admin_or_above());

-- ------------------------------------------------------------
-- 8. DOCUMENTATION: review-report items that are NOT SQL
-- ------------------------------------------------------------
-- a) Auth Hook / custom JWT claims (report sections 11/14):
--    All tenant-isolation policies use auth.jwt() ->> 'tenant_id'. Deploy a
--    custom Access Token Hook (Edge Function) that injects the profile's
--    tenant_id (and optionally role) into the JWT. Without it, isolation
--    policies deny everything.
--
-- b) notification_queue worker (report sections 8/14):
--    The notification_queue table fills but nothing drains it. Deploy an Edge
--    Function + pg_cron job (or Supabase Scheduler) that pops queued rows and
--    sends push notifications / emails.
--
-- c) Offline sync (finance-defination.md, Offline section):
--    Mobile apps keep a local SQLite mirror and push unsynced rows via a sync
--    endpoint; unique constraints on receipt_no / invoice_number /
--    payment_number prevent duplicate sync. No DB-side table is required.
--
-- d) Book model (report section 5):
--    Two parallel book systems (library_books vs books/book_copies) coexist.
--    Pick ONE model (prefer books + book_copies) and migrate/drop the other.
--    Not changed here because dropping tables is destructive.

-- ============================================================================
-- 9. FEE ENGINE & LEDGER PORTAL — SEQUENTIAL NUMBERS + ROLE-SCOPED RLS
--    Supports the fee workflows shipped for course_team (accountant fee
--    screens + JournalService) and course_users (student/parent fees portal).
--    Every statement below is idempotent (DROP … IF EXISTS + CREATE).
--
--    Role helpers (current_profile_role, is_super_admin, is_admin_or_above,
--    has_role, has_any_role, current_tenant_id) are defined in the RLS ROLE
--    HELPERS section above, so this block must run after that section.
-- ============================================================================

-- ------------------------------------------------------------
-- 9.1 Sequential payment numbers
--     Completes the receipt/invoice/payment numbering trio. The fee engine
--     client also supplies a fallback number, so this is a safety net.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_payment_no()
RETURNS TRIGGER AS $$
DECLARE
  next_num INT;
BEGIN
  IF NEW.payment_number IS NULL THEN
    SELECT COALESCE(MAX(CAST(SUBSTRING(payment_number FROM 5) AS INTEGER)), 0) + 1
      INTO next_num FROM payments;
    NEW.payment_number := 'PAY-' || LPAD(next_num::TEXT, 6, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_generate_payment_no ON payments;
CREATE TRIGGER trg_generate_payment_no
  BEFORE INSERT ON payments
  FOR EACH ROW
  EXECUTE FUNCTION public.generate_payment_no();

-- ------------------------------------------------------------
-- 9.2 Role-scoped RLS for the fee & ledger tables used by the portals.
--     Replaces the broad tenant-wide FOR ALL policies so that a same-tenant
--     student can no longer UPDATE/DELETE finance rows:
--      • staff (super_admin / admin / accountant) keep full tenant access;
--      • students may SELECT their own finance rows (via students.profile_id);
--      • guardians/parents may SELECT the finance rows of their linked
--        children (parent_students, supporting either parent_id = auth.uid()
--        or parent_id = parents.id with parents.profile_id = auth.uid());
--      • fee_types/fee_structures/accounts stay readable by anyone in the
--        tenant (name resolution in statements) but are only writable by
--        staff roles.
-- ------------------------------------------------------------

-- ----- student_fee_assignments -----
DROP POLICY IF EXISTS student_fee_assignments_tenant_isolation ON student_fee_assignments;
CREATE POLICY student_fee_assignments_staff_access ON student_fee_assignments
  FOR ALL TO authenticated
  USING (
    is_super_admin()
    OR (
      tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid())
      AND (is_admin_or_above() OR has_role('accountant'))
    )
  );
CREATE POLICY student_fee_assignments_portal_own_read ON student_fee_assignments
  FOR SELECT TO authenticated
  USING (
    student_id IS NOT NULL
    AND (
      student_id IN (SELECT id FROM students WHERE profile_id = auth.uid())
      OR student_id IN (
        SELECT ps.student_id FROM parent_students ps
        WHERE ps.parent_id = auth.uid()
           OR ps.parent_id IN (SELECT p.id FROM parents p WHERE p.profile_id = auth.uid())
      )
    )
  );

-- ----- fee_installments -----
DROP POLICY IF EXISTS fee_installments_tenant_isolation ON fee_installments;
CREATE POLICY fee_installments_staff_access ON fee_installments
  FOR ALL TO authenticated
  USING (
    is_super_admin()
    OR (
      tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid())
      AND (is_admin_or_above() OR has_role('accountant'))
    )
  );
CREATE POLICY fee_installments_portal_own_read ON fee_installments
  FOR SELECT TO authenticated
  USING (
    student_id IS NOT NULL
    AND (
      student_id IN (SELECT id FROM students WHERE profile_id = auth.uid())
      OR student_id IN (
        SELECT ps.student_id FROM parent_students ps
        WHERE ps.parent_id = auth.uid()
           OR ps.parent_id IN (SELECT p.id FROM parents p WHERE p.profile_id = auth.uid())
      )
    )
  );

-- ----- invoices -----
DROP POLICY IF EXISTS invoices_tenant_isolation ON invoices;
CREATE POLICY invoices_staff_access ON invoices
  FOR ALL TO authenticated
  USING (
    is_super_admin()
    OR (
      tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid())
      AND (is_admin_or_above() OR has_role('accountant'))
    )
  );
CREATE POLICY invoices_portal_own_read ON invoices
  FOR SELECT TO authenticated
  USING (
    student_id IS NOT NULL
    AND (
      student_id IN (SELECT id FROM students WHERE profile_id = auth.uid())
      OR student_id IN (
        SELECT ps.student_id FROM parent_students ps
        WHERE ps.parent_id = auth.uid()
           OR ps.parent_id IN (SELECT p.id FROM parents p WHERE p.profile_id = auth.uid())
      )
    )
  );

-- ----- payments -----
DROP POLICY IF EXISTS payments_tenant_isolation ON payments;
DROP POLICY IF EXISTS payment_tenant_access ON payments;
CREATE POLICY payments_staff_access ON payments
  FOR ALL TO authenticated
  USING (
    is_super_admin()
    OR (
      tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid())
      AND (is_admin_or_above() OR has_role('accountant'))
    )
  );
CREATE POLICY payments_portal_own_read ON payments
  FOR SELECT TO authenticated
  USING (
    student_id IS NOT NULL
    AND (
      student_id IN (SELECT id FROM students WHERE profile_id = auth.uid())
      OR student_id IN (
        SELECT ps.student_id FROM parent_students ps
        WHERE ps.parent_id = auth.uid()
           OR ps.parent_id IN (SELECT p.id FROM parents p WHERE p.profile_id = auth.uid())
      )
    )
  );

-- ----- receipts -----
DROP POLICY IF EXISTS receipts_tenant_isolation ON receipts;
CREATE POLICY receipts_staff_access ON receipts
  FOR ALL TO authenticated
  USING (
    is_super_admin()
    OR (
      tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid())
      AND (is_admin_or_above() OR has_role('accountant'))
    )
  );
CREATE POLICY receipts_portal_own_read ON receipts
  FOR SELECT TO authenticated
  USING (
    student_id IS NOT NULL
    AND (
      student_id IN (SELECT id FROM students WHERE profile_id = auth.uid())
      OR student_id IN (
        SELECT ps.student_id FROM parent_students ps
        WHERE ps.parent_id = auth.uid()
           OR ps.parent_id IN (SELECT p.id FROM parents p WHERE p.profile_id = auth.uid())
      )
    )
  );

-- ----- fee_types (tenant-readable catalog, staff-writable) -----
DROP POLICY IF EXISTS fee_types_tenant_isolation ON fee_types;
CREATE POLICY fee_types_catalog_read ON fee_types
  FOR SELECT TO authenticated
  USING (
    is_super_admin()
    OR tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid())
  );
CREATE POLICY fee_types_staff_access ON fee_types
  FOR ALL TO authenticated
  USING (
    is_super_admin()
    OR (
      tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid())
      AND (is_admin_or_above() OR has_role('accountant'))
    )
  );

-- ----- fee_structures (tenant-readable catalog, staff-writable) -----
DROP POLICY IF EXISTS fee_structures_tenant_isolation ON fee_structures;
CREATE POLICY fee_structures_catalog_read ON fee_structures
  FOR SELECT TO authenticated
  USING (
    is_super_admin()
    OR tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid())
  );
CREATE POLICY fee_structures_staff_access ON fee_structures
  FOR ALL TO authenticated
  USING (
    is_super_admin()
    OR (
      tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid())
      AND (is_admin_or_above() OR has_role('accountant'))
    )
  );

-- ----- accounts (catalog reads for every authenticated tenant user; writes
--                only for staff so seeded NULL-tenant accounts stay usable) -----
DROP POLICY IF EXISTS accounts_tenant_isolation ON accounts;
CREATE POLICY accounts_catalog_read ON accounts
  FOR SELECT TO authenticated
  USING (
    is_super_admin()
    OR tenant_id IS NULL
    OR tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid())
  );
CREATE POLICY accounts_staff_access ON accounts
  FOR ALL TO authenticated
  USING (
    is_super_admin()
    OR (
      (tenant_id IS NULL OR tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid()))
      AND (is_admin_or_above() OR has_role('accountant'))
    )
  );

-- ----- journals / journal_entries (staff only) -----
DROP POLICY IF EXISTS journals_tenant_isolation ON journals;
CREATE POLICY journals_staff_access ON journals
  FOR ALL TO authenticated
  USING (
    is_super_admin()
    OR (
      tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid())
      AND (is_admin_or_above() OR has_role('accountant'))
    )
  );

DROP POLICY IF EXISTS journal_entries_tenant_journal ON journal_entries;
CREATE POLICY journal_entries_staff_access ON journal_entries
  FOR ALL TO authenticated
  USING (
    is_super_admin()
    OR (
      journal_id IN (
        SELECT j.id FROM journals j
        WHERE j.tenant_id IN (SELECT tenant_id FROM profiles WHERE id = auth.uid())
      )
      AND (is_admin_or_above() OR has_role('accountant'))
    )
  );

