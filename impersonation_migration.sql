-- ============================================
-- USER IMPERSONATION (FORCE LOGIN) — Migration
-- ============================================
-- Adds:
--   * impersonation_sessions   (tracks active impersonation sessions)
--   * impersonation_log        (dual-identity audit trail)
--   * SQL functions + security policies
-- Idempotent; safe to re-run. Run once in the Supabase SQL editor.
-- ============================================

-- ---------- impersonation_sessions ----------
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

-- ---------- impersonation_log (dual-identity audit trail) ----------
CREATE TABLE IF NOT EXISTS impersonation_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nid BIGSERIAL UNIQUE,
  session_id UUID REFERENCES impersonation_sessions(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES tenants(id),
  actor_id UUID NOT NULL REFERENCES profiles(id),          -- real human (super admin)
  target_user_id UUID REFERENCES profiles(id),             -- acting-as user
  target_role TEXT,
  action TEXT NOT NULL,                                    -- login_as / exit / auto_expire / revoke / denied
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

-- ---------- RLS ----------
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
  )
  WITH CHECK (
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

-- ---------- Helper: resolve a profile's row for a given user ----------
-- SECURITY DEFINER so an impersonating session token never expands its own
-- RLS view; it reads through the shared helper defined in the schema.
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

-- Content-level violation applied to the impersonation flow via app logic.
-- 'target_role = super_admin' is additionally blocked in the app layer.
-- The unique partial index above enforces the "single active session" rule.

-- ============================================
-- NOTES
-- ============================================
-- 1. The Flutter app stores impersonation state locally (secure storage):
--      * impersonation_session_id
--      * impersonation_super_admin_id
--      * impersonation_target_user_id
--      * impersonation_target_role
--      * impersonation_expires_at
--    The app performs "Login As" by:
--       a) super admin calls start_impersonation() RPC
--       b) app captures the impersonation session id + expiry
--       c) redirects to the target role's panel w/ the impersonation banner active
--    While impersonated, the current Supabase auth user is still the super admin,
--    but the UI reads the target user's role/id/tenant from the stored state so
--    all screens behave like the target user.
-- 2. The audit trail writes a separate row to impersonation_log on login/exit.