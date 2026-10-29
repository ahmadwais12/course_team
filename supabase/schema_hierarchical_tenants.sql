-- ============================================================
-- EMIS Hierarchical Tenant Schema Update
-- Adds support for: Central Organization → Branches/Schools
-- ============================================================

-- ─── Update Tenants Table with Hierarchy Support ─────────────

-- Add hierarchy columns to existing tenants table
ALTER TABLE tenants 
ADD COLUMN IF NOT EXISTS parent_tenant_id UUID REFERENCES tenants(id),
ADD COLUMN IF NOT EXISTS organization_type TEXT DEFAULT 'branch',
ADD COLUMN IF NOT EXISTS tenant_code TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS website TEXT,
ADD COLUMN IF NOT EXISTS max_users INT DEFAULT 100,
ADD COLUMN IF NOT EXISTS max_storage_mb INT DEFAULT 1024,
ADD COLUMN IF NOT EXISTS settings JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS featured BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 7),
ADD COLUMN IF NOT EXISTS longitude DECIMAL(10, 7),
ADD COLUMN IF NOT EXISTS services JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS working_hours JSONB DEFAULT '{}';

-- Add comment to explain organization types
COMMENT ON COLUMN tenants.organization_type IS 'Type: central (main organization), branch (school/campus under central)';

-- ─── Create Index for Performance ────────────────────────────
CREATE INDEX IF NOT EXISTS idx_tenants_parent ON tenants(parent_tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenants_type ON tenants(organization_type);
CREATE INDEX IF NOT EXISTS idx_tenants_code ON tenants(tenant_code);
CREATE INDEX IF NOT EXISTS idx_profiles_tenant ON profiles(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenants_featured ON tenants(featured);
CREATE INDEX IF NOT EXISTS idx_tenants_lat_lng ON tenants(latitude, longitude);

-- ─── View: Get All Branches with Parent Info ─────────────────
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
  t.created_at,
  (SELECT COUNT(*) FROM profiles p WHERE p.tenant_id = t.id AND p.is_active = true) AS active_users,
  (SELECT COUNT(*) FROM students s WHERE s.tenant_id = t.id) AS total_students
FROM tenants t
LEFT JOIN tenants parent ON t.parent_tenant_id = parent.id
WHERE t.organization_type = 'branch';

-- ─── View: Get Central Organizations ─────────────────────────
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
  (SELECT COUNT(*) FROM tenants WHERE parent_tenant_id = t.id) AS total_branches,
  (SELECT COUNT(*) FROM profiles p WHERE p.tenant_id = t.id AND p.is_active = true) AS active_users
FROM tenants t
WHERE t.organization_type = 'central';

-- ─── View: Complete Tenant Hierarchy ─────────────────────────
CREATE OR REPLACE VIEW tenant_hierarchy AS
WITH RECURSIVE tenant_tree AS (
  -- Base case: Central organizations
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
  
  -- Recursive case: Branches
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
  array_to_string(path, ' → ') AS hierarchy_path
FROM tenant_tree
ORDER BY root_id, level, name;

-- ─── Function: Get All Branches for a Central Org ────────────
CREATE OR REPLACE FUNCTION get_branches_for_central(central_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  slug TEXT,
  tenant_code TEXT,
  is_active BOOLEAN,
  active_users BIGINT,
  total_students BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.id,
    t.name,
    t.slug,
    t.tenant_code,
    t.is_active,
    (SELECT COUNT(*) FROM profiles p WHERE p.tenant_id = t.id AND p.is_active = true) AS active_users,
    (SELECT COUNT(*) FROM students s WHERE s.tenant_id = t.id) AS total_students
  FROM tenants t
  WHERE t.parent_tenant_id = central_id
  ORDER BY t.name;
END;
$$ LANGUAGE plpgsql;

-- ─── Function: Get Central Organization for a Branch ─────────
CREATE OR REPLACE FUNCTION get_central_for_branch(branch_id UUID)
RETURNS TABLE (
  central_id UUID,
  central_name TEXT,
  central_code TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    parent.id,
    parent.name,
    parent.tenant_code
  FROM tenants t
  INNER JOIN tenants parent ON t.parent_tenant_id = parent.id
  WHERE t.id = branch_id;
END;
$$ LANGUAGE plpgsql;

-- ─── Function: Validate Tenant Hierarchy ─────────────────────
CREATE OR REPLACE FUNCTION validate_tenant_hierarchy()
RETURNS TRIGGER AS $$
BEGIN
  -- Prevent circular references
  IF NEW.parent_tenant_id = NEW.id THEN
    RAISE EXCEPTION 'A tenant cannot be its own parent';
  END IF;
  
  -- Prevent a branch from having branches (only central can have branches)
  IF NEW.parent_tenant_id IS NOT NULL AND NEW.organization_type = 'central' THEN
    RAISE EXCEPTION 'A central organization cannot have a parent';
  END IF;
  
  -- Ensure parent exists and is a central organization
  IF NEW.parent_tenant_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM tenants 
      WHERE id = NEW.parent_tenant_id 
      AND organization_type = 'central'
      AND is_active = true
    ) THEN
      RAISE EXCEPTION 'Parent tenant must be an active central organization';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for validation
DROP TRIGGER IF EXISTS trg_validate_tenant_hierarchy ON tenants;
CREATE TRIGGER trg_validate_tenant_hierarchy
  BEFORE INSERT OR UPDATE ON tenants
  FOR EACH ROW
  EXECUTE FUNCTION validate_tenant_hierarchy();

-- ─── Function: Auto-generate Tenant Code ─────────────────────
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

-- Create trigger for auto-generating codes
DROP TRIGGER IF EXISTS trg_generate_tenant_code ON tenants;
CREATE TRIGGER trg_generate_tenant_code
  BEFORE INSERT ON tenants
  FOR EACH ROW
  EXECUTE FUNCTION generate_tenant_code();

-- ─── Row Level Security (RLS) Policies ───────────────────────

-- Enable RLS on tenants
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;

-- Super admins can see all tenants
CREATE POLICY super_admin_view_all_tenants ON tenants
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'super_admin'
    )
  );

-- Central admins can see their own and their branches
CREATE POLICY central_admin_view_own_and_branches ON tenants
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
      AND (
        profiles.tenant_id = tenants.id 
        OR profiles.tenant_id = tenants.parent_tenant_id
      )
    )
  );

-- Branch users can only see their own tenant
CREATE POLICY branch_user_view_own ON tenants
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.tenant_id = tenants.id
      AND profiles.role NOT IN ('super_admin', 'admin')
    )
  );

-- Only super admins can insert tenants
CREATE POLICY super_admin_insert_tenants ON tenants
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'super_admin'
    )
  );

-- Only super admins can update tenants
CREATE POLICY super_admin_update_tenants ON tenants
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'super_admin'
    )
  );

-- Only super admins can delete tenants
CREATE POLICY super_admin_delete_tenants ON tenants
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'super_admin'
    )
  );

-- ─── Sample Data: Create Central Organization with Branches ──

-- Insert Central Organization (if not exists)
INSERT INTO tenants (id, name, slug, organization_type, description, is_active)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'International Education Group',
  'ieg-central',
  'central',
  'Main central organization managing all branch schools',
  true
) ON CONFLICT DO NOTHING;

-- Insert Sample Branches
INSERT INTO tenants (name, slug, parent_tenant_id, organization_type, is_active)
VALUES 
  ('Oxford Academy', 'oxford-academy', '00000000-0000-0000-0000-000000000001', 'branch', true),
  ('Cambridge School', 'cambridge-school', '00000000-0000-0000-0000-000000000001', 'branch', true),
  ('Harvard International', 'harvard-intl', '00000000-0000-0000-0000-000000000001', 'branch', true)
ON CONFLICT DO NOTHING;

-- ─── Comments and Documentation ──────────────────────────────
COMMENT ON TABLE tenants IS 'Educational institutions - can be central organizations or branches/schools';
COMMENT ON COLUMN tenants.parent_tenant_id IS 'References the central organization this branch belongs to (NULL for central orgs)';
COMMENT ON COLUMN tenants.organization_type IS 'central = main organization, branch = school/campus';
COMMENT ON COLUMN tenants.tenant_code IS 'Auto-generated unique code (C0001 for central, B0001 for branch)';
COMMENT ON COLUMN tenants.max_users IS 'Maximum number of users allowed for this tenant';
COMMENT ON COLUMN tenants.settings IS 'JSON settings object for tenant-specific configurations';

-- ============================================================
-- END OF HIERARCHICAL TENANT SCHEMA UPDATE
-- ============================================================
