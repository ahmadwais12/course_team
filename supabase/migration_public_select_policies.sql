-- ============================================================================
-- Migration: Add public SELECT policies for reference/lookup tables
-- Purpose: Allow unauthenticated users (during registration) to read
--          roles, departments, and programs. Registration screen needs
--          this data before the user is logged in.
-- ============================================================================

-- Roles: allow anonymous SELECT
CREATE POLICY "roles_public_select" ON roles FOR SELECT
  USING (true);

-- Departments: allow anonymous SELECT
CREATE POLICY "departments_public_select" ON departments FOR SELECT
  USING (true);

-- Programs: allow anonymous SELECT
CREATE POLICY "programs_public_select" ON programs FOR SELECT
  USING (true);
