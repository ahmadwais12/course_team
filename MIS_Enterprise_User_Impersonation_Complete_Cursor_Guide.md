# MIS / EMIS Enterprise User Impersonation (Force Login) - Complete Cursor AI Implementation Guide

> Version: Enterprise v1.0
> Stack: Laravel 12 + Sanctum + Vue 3 + Pinia + Axios + PostgreSQL / Supabase

---

# 1. Feature Overview

## What is User Impersonation?

User Impersonation (Force Login / Login As User) allows a Super Admin to temporarily enter another user's account without knowing their password.

The system authenticates as the selected user while securely remembering who started the impersonation.

The application behaves exactly like the impersonated user.

This is an enterprise feature used in:

- ERP
- MIS
- EMIS
- CRM
- HRM
- Banking Systems
- SaaS Platforms

---

# 2. Business Requirements

(Extensive requirements for Super Admin, Admin, Teacher, Student, Parent, Staff...)

- Super Admin can impersonate any non-super-admin account.
- No password required.
- One click login.
- Exit returns original session.
- Logs preserve security trail.

---

# 3. Complete Authentication Flow

1. Super Admin logs in.
2. Users page loads.
3. Click Login As User.
4. Backend validates permission.
5. Create impersonation session.
6. Generate temporary Sanctum token.
7. Vue replaces authentication token.
8. Dashboard reloads.
9. All APIs use impersonated identity.
10. Exit restores Super Admin.

---

# 4. Database Design

## impersonation_sessions

Detailed schema with UUID, foreign keys, indexes, timestamps, IP, browser, expiration.

## audit_logs

Stores actor_id and acting_as_id.

## Optional activity_logs

Stores business actions performed while impersonating.

---

# 5. Laravel Backend Architecture

Directory structure.

app/
  Services/
  Controllers/
  Middleware/
  Policies/
  Models/

ImpersonationService handles all impersonation logic.

---

# 6. API Endpoints

POST /api/admin/impersonate/{userId}

POST /api/admin/impersonation/exit

GET /api/admin/impersonation/current

GET /api/admin/impersonation/history

DELETE /api/admin/impersonation/revoke/{sessionId}

Purpose of each endpoint explained.

---

# 7. Controller Responsibilities

loginAs()

Validation steps:

- Current user authenticated.
- Current user role == super_admin.
- Target exists.
- Target active.
- Target not deleted.
- Target not super_admin.

Create session.

Generate token.

Return payload.

exit()

Find active session.

Invalidate impersonation token.

Create admin token.

Return admin payload.

---

# 8. Middleware

ImpersonationAuditMiddleware

Responsibilities:

- Detect impersonation.
- Attach original admin into request.
- Save audit logs.

ImpersonationGuardMiddleware

- Block nested impersonation.
- Block expired sessions.
- Block revoked sessions.

---

# 9. Vue Frontend

Users table.

Confirmation modal.

Pinia auth store.

Axios interceptor.

Navbar banner.

Exit button.

Persistent impersonation after refresh.

---

# 10. Pinia State

user

token

role

impersonating

originalAdmin

sessionId

expiresAt

---

# 11. Axios Interceptor

Automatically attach bearer token.

Detect 401.

Detect expired impersonation.

Auto return to admin.

---

# 12. UI Components

ImpersonationBanner.vue

UsersTableAction.vue

ExitImpersonationButton.vue

ImpersonationHistoryModal.vue

---

# 13. Audit Logging Strategy

Business logs:

created_by = impersonated user.

Security logs:

actor_id = super admin.

acting_as_id = impersonated user.

Example records provided.

---

# 14. Permission Matrix

Role impersonation table.

Super Admin only.

Disabled users cannot be impersonated.

Soft deleted users blocked.

---

# 15. Security Best Practices

30-minute expiration.

Single active impersonation.

Revoke on logout.

Store browser/IP.

Never impersonate another Super Admin.

Never allow impersonation token to create admins.

---

# 16. Session Lifecycle

Start.

Refresh.

Expire.

Manual exit.

Forced revoke.

Automatic cleanup job.

---

# 17. Background Cleanup

Laravel Scheduler command removes expired sessions every 5 minutes.

---

# 18. Notifications

Optional banner.

Optional email notification.

Optional admin activity notification.

---

# 19. Error Handling

403 unauthorized.

404 user missing.

409 already impersonating.

419 expired.

401 invalid token.

Frontend handling.

---

# 20. Testing Checklist

Authentication.

Permissions.

Audit logs.

Exit.

Expiration.

Nested impersonation.

Disabled users.

Deleted users.

API protection.

Browser refresh.

---

# 21. Production Deployment Checklist

Run migrations.

Register middleware.

Protect routes.

Configure Sanctum expiration.

Enable audit logging.

Test every role.

Review security logs.

---

# 22. Cursor AI Implementation Instructions

Cursor should implement:

- All migrations.
- Models.
- Relationships.
- Service Layer.
- Controllers.
- Middleware.
- Policies.
- API routes.
- Pinia store.
- Axios service.
- Vue pages.
- Components.
- Tailwind UI.
- Audit logging.
- Scheduler cleanup.
- Tests.

The implementation must be production-ready, modular, reusable across all company products, and follow Laravel 12 best practices.
