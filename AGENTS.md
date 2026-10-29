# EMIS Course Team - Project Summary

## Objective
Build a full EMIS Flutter app with complete CRUD on all panels, connected to Supabase backend. Course management focused.

## Important Details
- **System Settings merged into Settings page** — `lib/screens/settings_screen.dart` embeds an admin-only `_SystemSettingsSection` (the old standalone `system_settings_screen.dart` still exists but is orphaned; no menu entry points to it). It uses the `settings` table (schema has `settings` + `notification_settings`; there is **NO `system_settings` table** — earlier code hit a non-existent table and failed silently). `settings` is tenant-scoped via `settings_tenant_isolation` RLS (matches current user's `profiles.tenant_id`), so the section resolves `tenant_id` from the current profile and filters/inserts with it. `settings.value` is TEXT, so booleans/ints are stored as strings (`'true'`/`'false'`/`'30'`) via `_encodeValue`.

## Important Details
- Flutter + Dart, Riverpod state management, Supabase backend, go_router navigation
- `DropdownButtonFormField` uses `initialValue` not `value` (Flutter 3.33+)
- Roles: `guardian` replaces `parent` everywhere; `profiles.role` is a text column (no CHECK constraint in live DB)
- Auth: signUp uses `auth.signUp(email:password:data:)`, profiles inserted with `id` from auth user (FK `profiles.id → auth.users.id`). **Session restore**: save both `access_token` AND `refresh_token` from `currentSession` before `signUp()`, then restore via `setSession("{\"access_token\":\"$at\",\"refresh_token\":\"$rt\"}")`. The JSON string **must use double quotes** (`"..."`) for proper Dart string interpolation — single quotes pass the literal `$token` text to Supabase, causing "Refresh token is not valid" errors.
- **Desktop Dashboard** (>=1024px): Defined in `dashboard_desktop_layout.dart` — dark theme (`#121018` bg, `#A855F7` accent purple), 88px icon sidebar, 340px right analytics panel, KPI cards with sparklines, session line chart, browser usage bars, circular progress indicators. Mobile/tablet keeps existing Insight design.
- Color constants for desktop dashboard are **top-level `const`** (not class members) so private widgets can access them.
- RadarChart from fl_chart ^1.2.0 has incompatible API — replaced with `_BrowserBar` horizontal progress bars.
- Student+guardian flow: creates auth user → profile → student/parent record → parent_students link
- `_UserFormPage` in users_screen.dart: 5-step wizard; guardian fields shown in Step 5 when role=`student` && adding
- `profiles` table has NO `email` column in the schema file — user added it manually to the live DB
- RLS policies on `profiles` had infinite recursion (42P17) — replaced with `profiles_all_authenticated` (auth.role() = 'authenticated') — no subqueries, no recursion
- Every table now has both `id UUID` (PK, for FK relationships) and `nid BIGSERIAL UNIQUE` (numeric ID for display)
- **Notification Triggers** (appended at end of `supabase_schema.sql`): 18 `AFTER INSERT` triggers on panel tables auto-create `notifications` rows for the relevant admin/super admin roles. Key helpers: `notify_users_by_role()` (inserts into `notifications` for each matching `profiles` in a tenant) and `get_actor_name()` (resolves profile `full_name`). Tables covered: `support_tickets`, `it_tickets`, `complaints`, `maintenance_requests`, `employee_leaves`, `student_leaves`, `payments`, `course_applications`, `callback_requests`, `contact_messages`, `homework_submissions`, `book_issues`, `inventory_transactions` (low‑stock), `feedback`, `attendance_corrections`, `document_requests`, `visitors`, `placement_test_attempts`.
- Flutter `notifications_screen.dart` now uses `notificationStreamProvider` (Riverpod `StreamProvider`) backed by a Supabase realtime subscription on the `notifications` table — updates arrive instantly when triggers fire. The model `AppNotification` now includes `body`, `priority` (`low`/`normal`/`high`/`urgent`), `actionUrl`, `data` (jsonb), `tenantId`, and new `NotificationType` values (`system`, `attendance`, `hr`, `academic`). The card UI shows priority badges and "View Details →" link when `action_url` is set.
- **Notification Compose** (`notification_compose_screen.dart`): Super Admin, Admin, Academic Support, and HR can send notifications. Three target modes: **All Users** (every active profile in tenant), **By Role** (multi-select roles like teacher/student/staff), **Specific Users** (searchable multi-select from non-student profiles). Backed by `send_bulk_notification()` PL/pgSQL function appended to `supabase_schema.sql`. A compose button (bell+ icon) appears in the notifications screen app bar for authorized roles. Registered in `page_registry.dart` as `notification_compose`, listed in `panel_pages_config.dart` for the four admin panels, and routed via `nav.dart` at `/notification-compose`.
- **More menu dedup** — `panel_pages_config.dart` merges static + dynamic pages through `_combine()` which drops any page whose `id` or `name` (case-insensitive) already appeared (static pages win). This removes exact-name repeats like `System Settings`/`sa_settings`; same-table-but-different-title overlaps are intentionally kept.

## Work State
### Completed
- **Back buttons added to 21 screens** — All More-menu destination screens without AppBars now have `Scaffold(appBar: AppBar(..., leading: IconButton(arrow_back)))` with `context.pop()`. Covers super_admin (8), admin (2), teacher (5), accountant (1), hr (1), librarian (1) panels.
- **`chat_service.dart` PGRST200 fix** — `_fetchActiveCalls`/`_fetchCall` replaced FK-join queries with flat `select()` + separate `_attachCallerInfo()` profile lookups.
- **`users_screen.dart` DropdownButtonFormField overflow** — Fixed via `isExpanded: true`, `initialValue:`, `TextOverflow.ellipsis`.
- **`notifications_screen.dart`** — Compose button changed to `ElevatedButton.icon` with "Compose" label; filters upgraded to `ChoiceChip` with icons.
- **`settings_screen.dart`** — Back button conditional via `context.canPop()` guard.
- **`dashboard_desktop_layout.dart`** — Full rewrite: `StatefulWidget` with staggered `FadeTransition` entrance, auto-scrolling `PageView` carousel, `_QuickActionsCard`, `_RecentActivityCard`, animated KPI cards, `_BrowserBar` progress bars, circular gauges.
- **`page_registry.dart`** — Added `String? route` field; populated `route:` on 103+ entries with batch fix script.
- **`panel_pages_config.dart`** — Fixed complaint manager reference from `analytics` to `analytics_panel`.
- **`more_screen.dart`** — Profile page as first card; navigation changed from `context.goNamed(id)` to `context.go(route)` with fallback.
- **`base_panel_layout.dart`** — `defaultAppBar` leading shows back button when `context.canPop()`, else tenant logo.
- **Avatar display fixed** in both `user_creation_screen.dart` and `users_screen.dart`: uses `ImagePicker` directly → reads bytes → `MemoryImage(_avatarBytes!)` for instant display + background Supabase upload
- **`FileService.uploadImage` bypassed** in both screens — replaced with direct `ImagePicker` + `Supabase.storage.uploadBinary` + `getPublicUrl`
- **Missing `email` column in profiles** — user added it manually; code re-added `payload['email'] = email` in all three insert paths
- **Missing `auth.signUp()` for non-student path** in `users_screen.dart:882-888` — added auth signUp before profile insert
- **RLS recursion error** (42P17) resolved — user ran SQL: `DROP` recursive policies, `CREATE` single `profiles_all_authenticated` using `auth.role() = 'authenticated'`
- **`tenant_id` null in profiles** fixed — added `_tenants` loading, `_requiresTenant` getter, tenant dropdown in Step 1, and `'tenant_id'` in profilePayload
- **Storage buckets** (`lib/utils/storage_buckets.dart`) fully documented with DB column references from `supabase_schema.sql`
- **`add_numeric_ids.sql`** created — adds `nid BIGSERIAL UNIQUE` column to all 209 tables via `ALTER TABLE` loop (auto-generated from `supabase_schema.sql`)
- **`nid` displayed in UI** — user list cards show `#<nid>  <email>`, edit form title shows `Edit User [#<nid>]`
- **`user_roles` table evaluated** — currently unused in Flutter code (app uses `profiles.role` directly); kept for future multi-role/expiration/audit features
- **`nid` column added to schema files** — `nid BIGSERIAL UNIQUE` added to every `CREATE TABLE` in `supabase_schema.sql` and `tables.md`
- **`setSession` interpolation bug** — all 5 restore sites (`main.dart`, `auth_service.dart`, `splash_screen.dart`, `users_screen.dart`, `user_creation_screen.dart`) changed from single-quote strings to double-quote with escaped inner quotes. `SecureStorageService` now saves both tokens (`saveAccessToken`+`saveRefreshToken` / `clearTokens` / `hasTokens`). Updated all 9 call sites.
- **Proactive session restore** — `users_screen.dart:_save` and `user_creation_screen.dart:_createUser` now check if `currentSession` is null and proactively restore from secure storage (both tokens) before capturing admin tokens for post-signUp recovery.
- **Notification trigger system** — `supabase_notification_triggers.sql` created with 18 `AFTER INSERT` triggers across all major panel tables. Key trigger functions: `notify_users_by_role()` (generic role‑based notifier) and `get_actor_name()`. Appended to end of `supabase_schema.sql`. Each trigger maps to the correct admin role array (e.g., `support_tickets` → `super_admin,admin,it_support`).
- **Flutter notification realtime stream** — `notification_service.dart`: added `subscribeToNotifications()` (Supabase PostgresChanges subscription), `notificationStream` broadcast stream, `unreadCount`. `notification_repository.dart`: rewired from polling to realtime stream via Supabase channel. `notification_provider.dart`: added `notificationStreamProvider` (Riverpod `StreamProvider`) alongside existing `StateNotifier`. `notifications_screen.dart`: switched to `notificationStreamProvider`, added priority badge UI, "View Details →" link, and icons/colors for new types (`system`, `attendance`, `hr`, `academic`).
- **Model upgraded** — `notification.dart`: `AppNotification` now has `body`, `priority` (`NotificationPriority` enum), `actionUrl`, `data` (`Map?`), `tenantId`, and new `NotificationType` values (`system`, `attendance`, `hr`, `academic`). `fromJson`/`toJson` updated to handle both DB snake_case and JSON camelCase keys.
- **Notification Compose system** — `send_bulk_notification()` PL/pgSQL function supports three target modes: `all`, `role`, `specific`. Flutter `notification_compose_screen.dart` has title, body, type, priority fields + segment toggle for target mode. Role mode shows multi-select chips for all roles. Specific mode shows a searchable list of non-student profiles. Backed by `sendBulkNotification()` in `NotificationRepository`. Registered in page registry, listed in 4 admin panel configs, and routed via go_router at `/notification-compose`. A compose button appears in the notifications screen app bar for authorized roles.

### Active
- (none)

### Blocked
- None. `notify_course_applied`, `notify_callback_requested`, `notify_visitor_checkin` were already NULL-safe (every `NEW.*` column wrapped in `COALESCE` before `||`); `notify_contact_message` had a real NULL risk — `LEFT(NEW.message, 100)` was un-coalesced (a NULL `message` would NULL out the whole body) — fixed to `COALESCE(LEFT(NEW.message, 100), '(no message)')` in both `supabase_schema.sql` and `supabase_notification_triggers.sql`.

## Work State (Users list pagination + skeleton - FIXED)
### Completed
- **Infinite scroll pagination (10 per page)** — `users_screen.dart` (`_UsersScreenState`): `_pageSize = 10`, `_visibleCount` slices `_filteredUsers`; `ScrollController` triggers `_loadMore()` within 200px of the bottom (simulated 700ms, trailing skeleton card while loading). Search/role/status/tenant filter changes and "Clear filters" reset `_visibleCount`; `_loadUsers()` also resets it after fetching.
- **User skeleton shimmer** — new `_UserSkeletonCard` (ShimmerLoading card mimicking the `_UserCard` layout: avatar circle + name/role lines + 3 action dots) shown while `_isLoading` (10 cards) and as the trailing card during `_loadMore`. Loading branch switched from `CircularProgressIndicator` to the skeleton list; added `widgets/shimmer_loading.dart` import.
- Verification: `dart analyze` on the file → no errors (4 pre-existing `curly_braces` info lints remain); `flutter test` → **34/34 pass**.

## Work State (Notifications pagination + skeleton - FIXED)
### Completed
- **Infinite scroll pagination (10 per page)** — `notifications_screen.dart`: `_pageSize = 10`, `_visibleCount` slices the filtered list; `ScrollController` on the `ListView.separated` triggers `_loadMore()` within 200px of the bottom (simulated 700ms, trailing skeleton card while loading). Filter chip changes reset `_visibleCount`; filter logic extracted into `_applyFilter()`.
- **Notification skeleton shimmer** — new `_NotificationSkeletonCard` (ShimmerLoading box mimicking the notification card: icon box + title/message/date lines) shown in the stream `loading` branch (8 cards) and as the trailing card during `_loadMore`. Import changed from `skeleton_loader.dart` to `shimmer_loading.dart` (ChatSkeleton no longer used here).
- Verification: `dart analyze` on the file → No issues; `flutter test` → **34/34 pass**.

## Work State (Tenant list pagination + skeleton - FIXED)
### Completed
- **Infinite scroll pagination (10 per page)** — `tenant_management_screen.dart`: `_pageSize = 10`, `_visibleCount` slices the filtered list; `ScrollController` listener triggers `_loadMore()` when within 200px of the bottom (simulated 700ms load). Search/filter changes reset `_visibleCount`.
- **Skeleton shimmer loading** — new `_ShimmerBox` (repeating `FadeTransition` pulse) + `_TenantSkeletonCard` (mimics the tenant card layout). Shown for ~900ms on first mount (`_initialLoading`) and as a trailing card while `_loadingMore`.
- Verification: `dart analyze` on the file → No issues; `flutter test` → **34/34 pass**.

## Work State (Tenant management wizard - FIXED)
### Completed
- **View action added to tenant cards** (`lib/screens/super_admin/tenant_management_screen.dart`) — each `_TenantCard` now has a View icon button (eye) alongside Edit/Delete, and the whole card is tappable (`InkWell`/`onTap`). Both open the new read-only **`_TenantDetailPage`** (header gradient card with name/slug/type/plan/status badges + sections: Organization [code, type, parent, slug, status], Contact [email, phone, address, website, owner email, contact phone], Plan & Limits [plan, max users, max storage, active users/students/branches counts], Other [description, logo URL, created/expiry dates]).
- `dart analyze` on the file → No issues; `flutter test` → **34/34 pass**.

## Work State (Tenant Management wizard - FIXED)
### Completed
- **`_TenantFormPage` converted to a 4-step wizard** (`lib/screens/super_admin/tenant_management_screen.dart`) — step indicator circles + connecting lines + labels (same style as `users_screen.dart`/`registration_screen.dart`), `PageView` with `NeverScrollableScrollPhysics`, bottom Back / Next bar, Save/Add on the final step.
- **All missing `tenants` columns added** — the form previously only edited name/slug/email/phone/address/website/plan/type/active. Now Step 1 (Organization): Name, Slug, Tenant Code (`tenant_code`), Organization Type, Parent Organization dropdown (shown only when type = branch; fed from central orgs in `tenantProvider`), Active switch. Step 2 (Contact): Email, Phone, Address, Website. Step 3 (Details): Description, Logo URL. Step 4 (Limits): Plan, Max Users (`max_users`), Max Storage MB (`max_storage_mb`).
- **Save now persists all fields** into the `Tenant` model (`tenantCode`, `parentTenantId`, `parentName`, `description`, `logoUrl`, `maxUsers`, `maxStorageMB`) via `addTenant`/`updateTenant`; name+slug validated (snackbar if empty); `parentName` resolved from central list (no `firstWhere` throw risk). Selecting 'central' clears `parentTenantId`.
- Note: `tenants` provider is still in-memory mock data (not Supabase-backed); the DB `tenants` table already has all these columns (`address`, not `location`, is the real column — UI keeps model's `location` field).
- Verification: `dart analyze` on the file → No issues; `flutter test` → **34/34 pass**.

## Work State (Settings pages combined - FIXED)
### Completed
- **System Settings merged into the Settings page** — `lib/screens/settings_screen.dart` now embeds an admin-only `_SystemSettingsSection` (rendered right after the profile card, before Appearance). It self-gates: loads the current user's `profiles.role`, shows only for `super_admin`/`admin` (returns `SizedBox.shrink()` otherwise), and is tenant-scoped via `profiles.tenant_id` + `settings.tenant_id` filter (same as the old standalone screen). All 8 settings controls (Maintenance Mode, Registration Enabled, Email/SMS Notifications, Session Timeout, Max Login Attempts, Default Language, Default Timezone) with instant per-toggle save + "Save All System Settings" button. `settings.value` is TEXT → `_encodeValue()` stores `'true'`/`'false'`/`'30'`. Number fields use dedicated disposed `TextEditingController`s.
- **Standalone System Settings menu entry removed** — dropped `'system_settings'` from the super_admin static list (`panel_pages_config.dart` `_getSuperAdminPages`); removed the dynamic `sa_settings` PageDefinition from `all_page_definitions.dart` (and its `skeleton_screen_map.dart` entry) so "System Settings" no longer appears as a separate menu item or as a generic settings-table CRUD page. `Settings` is now the single settings page for super_admin AND admin.
- **Old `SystemSettingsScreen` kept but orphaned** — `nav.dart` route `/super-admin/settings` (name `system-settings`) and `page_registry.dart` id `system_settings` still point to `lib/screens/super_admin/system_settings_screen.dart`; no menu item references it anymore (deep links still work). Harmless leftover.
- Verification: `dart analyze lib` → **0 errors / 0 warnings** (631 pre-existing info lints); `flutter test` → **34/34 pass** (dedup test updated: super_admin "system settings" now expected 0 occurrences).

## Work State (Notification realtime + is_active fix - DB deploy pending)
### Completed
- **Realtime not pushing root cause** — the `notifications` table was never added to the `supabase_realtime` publication, so Postgres emitted no change events to the open screen's channel (`notification-realtime`); new notifications only appeared on reopen (screen re-fetches on mount).
- **DB fix (must run once in Supabase SQL editor)** — `notification_realtime_migration.sql` (idempotent): `ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications` guarded by `pg_publication_tables`, plus `ENABLE ROW LEVEL SECURITY`. Same idempotent block appended to end of `supabase_schema.sql`. Hard-restart the app after applying so the channel reconnects.
- **Client belt-and-suspenders** — `NotificationRepository.refresh()` re-fetches and re-emits through the stream; `notification_compose_screen.dart` `_send()` awaits `refresh()` after the RPC so the list updates on pop even before the migration runs.
- **Specific-user compose bug fixed** — `send_bulk_notification` filtered every target branch with `AND is_active = true`, so profiles with NULL `is_active` were silently skipped (notification never inserted, even on reopen). All 3 branches now use `is_active IS NOT FALSE`. Applied to `supabase_schema.sql` (main function), `supabase_notification_triggers.sql`, and `notification_type_fix_migration.sql`.
- **Realtime duplicate fix** — `notification_repository.dart` INSERT handler dedupes by `id` (refresh-then-realtime event could show the same notification twice).
- **Compose UI cleanup** — Type dropdown shows the full meaningful set (general, announcement, academic, attendance, payment, grade, discount, salary, hr, system); "Send To" has only All Users / Specific Users (removed By Role segment + role chips + `_loadRoles`/`_availableRoles`/`_selectedRoles` state; RPC sends `targetRoles: null`); AppBar Send button removed (bottom "Send Notification" button remains).
- Verification: `dart analyze lib` → **0 errors / 0 warnings**; `flutter test` → **34/34 pass**.
### Blocked
- **User must run SQL in Supabase editor**: (1) `notification_realtime_migration.sql` (publication add + RLS), and (2) the updated `CREATE OR REPLACE FUNCTION send_bulk_notification(...)` with `is_active IS NOT FALSE` filters (re-run from `supabase_schema.sql` or the three SQL files above).

## Work State (System Settings fix)
### Completed
- **`system_settings_screen.dart` fixed — was querying a non-existent `system_settings` table** (schema only has `settings` + `notification_settings`). Every load failed silently and every toggle/Save showed "Failed to save: ..." — exactly the reported bug. Now reads/writes the real `settings` table.
- **Tenant-scoped loads/saves** — mirrors `branch_info_screen.dart`: resolves the current user's `profiles.tenant_id` and applies `.eq('tenant_id', ...)` on select and insert/update (the `settings` table is isolated via `settings_tenant_isolation` RLS).
- **`_encodeValue()` added** — `settings.value` is TEXT, so booleans/ints are stored as strings (`'true'`/`'false'`/`'30'`); `_applySettings` already handles both string and native values.
- **"Save All" button now actually persists** — previously only showed a "Settings saved" snackbar; now saves all 8 settings then confirms.
- **Load errors are surfaced** — `_loadSettings` catch now shows a "Failed to load settings: ..." snackbar instead of silently swallowing.
- **`_applySettings` missing `break`s confirmed harmless** — Dart 3.11 switch statements don't fall through (verified in isolated test at `$env:TEMP\switchtest`).
- `dart analyze lib`: **0 errors / 0 warnings** (remaining ~631 are pre-existing `constant_identifier_names` info lints in `keys.dart` + 5 `curly_braces`).

## Work State (Chat Fixes - voice call, voice message, file upload)
### Completed
- **File upload, voice message, and voice call REMOVED** (per user request, 2026) — `lib/screens/call_screen.dart` deleted; `IncomingCallListenerWidget` unwired from `main.dart`; `ChatService` stripped of `sendFileMessage`, `uploadVoiceMessage`, `streamIncomingCalls`, `initiateCall`, `answerCall`, `endCall`, `declineCall`, `_fetchActiveCalls`, `_fetchCall`, `_attachCallerInfo`. `chat_conversation_screen.dart` and `messages_screen.dart` no longer show call buttons, attach/mic buttons, or recording bars; removed `_pickImage`, `_pickFile`, `_startRecording`, `_stopRecording`, `_startCall`, `_startVoiceCall`, `_downloadMessageFile`, `_downloadFile`, `_insertFileMessage`, media bubble builders. Chat is text-only now (forward only sends text). `pubspec.yaml`: dropped `file_picker`, `record`, and `record_linux` override. Android manifest: removed `RECORD_AUDIO` + `MODIFY_AUDIO_SETTINGS`. `chat_screen.dart` capabilities row reduced to Direct DM + Group Chat. `dart analyze lib` clean. The `chat_calls`/`chat_messages` file columns and `chat_uploads` bucket remain in the DB schema (harmless; generic admin CRUD panel `gn_chat_calls` still exists).
- **`lib/utils/app_logger.dart` created** — `AppLogger.log/w/e/uploadFailed` using `dart:developer`. Used across `chat_service.dart`, `call_screen.dart`, `chat_conversation_screen.dart`, `messages_screen.dart`. `e()` takes named `error:`/`stackTrace:` (Dart forbids mixing optional positional + named params).
- **Voice message DB CHECK fix** — `uploadVoiceMessage` sent `messageType: 'audio'`, but `chat_messages.message_type` CHECK only allows `('text','file','image','video','voice')` → CHECK violation on insert. Changed to `'voice'`. UI `_buildMessageContent` now handles `case 'voice':` (and `'audio'` for legacy); reply indicator + forward both normalize `'audio'`→`'voice'`.
- **Voice call DB CHECK/column fixes** — `chat_calls.status` CHECK only allows `('initiated','answered','declined','ended','missed')`; `initiateCall` was inserting `'ringing'` → CHECK violation. Now inserts `'initiated'`. `answerCall` no longer writes non-existent `answered_at`; `endCall` writes `duration` (not `duration_seconds`). `_fetchActiveCalls` filters `['initiated','answered']`. `call_screen.dart` maps `'initiated'`→`ringing`(incoming)/`calling`(outgoing); `IncomingCallListenerWidget` now listens for `'initiated'`.
- **`initiateCall` PGRST200 fix** — embedded FK select `*, caller:caller_id(...), callee:callee_id(...)` fails (chat_calls has no FK constraints). Replaced with flat `.select().single()` + `_attachCallerInfo()`.
- **`chat_uploads` storage bucket missing** — bucket wasn't in the schema seed → file/voice/image uploads failed with "bucket not found". Added to `supabase_schema.sql` seed + created `chat_fix_migration.sql` (bucket + storage policies + RLS).
- **`chat_calls` RLS policies missing** — table had `ENABLE ROW LEVEL SECURITY` but zero policies → all call ops denied. Added SELECT/INSERT/UPDATE policies to `supabase_schema.sql` + migration.
- **`chat_calls` missing `callee_id`** — code inserts `callee_id` but schema had no such column. Added `callee_id UUID` to schema + migration.
- **Legacy `messages` table missing file columns** — `messages_screen.dart` inserts `file_url`/`file_type`/`file_name`/`file_size` but schema lacked them. Added to schema + migration.
- **`chat_messages` missing columns** — added `sender_name`, `sender_avatar`, `reply_to` to schema + migration (code selects/inserts them).
- **Android manifest missing permissions** — added `INTERNET`, `ACCESS_NETWORK_STATE`, `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS` (voice recording/calls need RECORD_AUDIO; RECORD_AUDIO + MODIFY_AUDIO_SETTINGS later removed with the features).

### Active
- (none)

### Blocked
- None for chat fixes. Note: `chat_fix_migration.sql` (bucket + RLS + columns) was for the removed features; now optional unless the schema files should be reverted too.

## Work State (Reply & Forward)
### Completed
- **Reply + Forward added to chat screen** (`lib/screens/messages_screen.dart` `_ChatScreen`) — the screen previously only had Copy in its long-press bottom sheet. Now: **Reply** (sets `_replyingTo`, shows banner above input with sender name + preview + close button; message persists `parent_message_id` into the `messages` table; bubbles render a `_replyPreviewFor` quoted preview with left accent border), **Copy** (unchanged), **Forward** (fetches all other chats via `_fetchThreadsForUser()` and shows a bottom-sheet picker; forwards text to the chosen chat by inserting a new `messages` row). `_ChatEntry` gained `id`, `senderId`, `replyToId` fields; `_loadMessages` now reads `id`/`parent_message_id`; `_ChatBubble` gained `replyPreview` param.
- **Thread loader refactored** — `_loadThreads()` in `_MessagesScreenState` now delegates to a shared private `_fetchThreadsForUser()` helper (same logic, reused by the forward picker).
- **`chat_fix_migration.sql`** — added `parent_message_id UUID REFERENCES messages(id)` defensive column (section 4b); the column already exists in `supabase_schema.sql`.

### Localization completed
- `keys.dart` declares **1623** keys; **all 1623 are now translated in all three files** (`app_localizations_en.dart`, `_prs.dart` [Dari], `_ps.dart` [Pashto]) — zero missing.
- The 44 previously‑unused orphan `LAll.*` keys (e.g. `all_lead`, `all_room_r`, `all_total_fees_data`, `all_replying_to_replyingtosendername_`, `all_pkr_row`, etc.) had no translation entry in any file; added English/Dari/Pashto entries to all three so no key can fall back to its raw key string. None are referenced in app code.
- Verified every `t(...)`/`tt(...)` key used in `lib/` has a translation in all 3 locales (the 3 apparent `leave.endDate`/`reason`/`applicantName` hits are `Map` field accesses, not keys).
- `dart analyze lib\l10n`: **0 errors**; only 613 pre-existing `constant_identifier_names` info lints in `keys.dart`.

### Blocked
- None. Note: `chat_fix_migration.sql` (bucket + RLS + columns) was for the removed features; now optional unless the schema files should be reverted too.

## Work State (Build Fixes - localization compile errors)
### Completed
- **`flutter run` build errors fixed** (broke after earlier localization pass): `dart analyze lib` now **0 errors / 0 warnings** (only 618 pre-existing info lints: 613 `constant_identifier_names` in `keys.dart` + 5 `curly_braces`).
- **Object→String in `tt()`** — `tt(LX.y, ref, [e])`/`[error]` passed an `Object` where `List<String>` is required. Changed to `[e.toString()]`/`[error.toString()]` in: `command_center_screen.dart`, `finance/expenses_tracking_screen.dart` (incl. `[error]`), `super_admin/address_management_screen.dart`, `super_admin/fee_type_templates_screen.dart`, `super_admin/backup_restore_screen.dart`, `super_admin/multi_language_screen.dart`, `two_factor_screen.dart`.
- **`exams_screen.dart`** — `_UpcomingExams`/`_UpcomingExamsState` converted from `StatefulWidget`/`State` to `ConsumerStatefulWidget`/`ConsumerState` (`ref` was undefined); `_ExamCard`, `_ResultCard`, `_CertificateCard` `ConsumerWidget.build` overrides gained the missing `WidgetRef ref` parameter (were ignoring it → "fewer positional arguments than overridden method").
- **`command_center_screen.dart:459`** — `TextButton` in the app bar `actions` was missing its closing `)` (syntax error); added it.

### Blocked
- None.

## Work State (Chat Fixes - Reply & Forward)
### Completed
- **Reply + Forward added to chat screen** (`lib/screens/messages_screen.dart` `_ChatScreen`) — the screen previously only had Copy in its long-press bottom sheet. Now: **Reply** (sets `_replyingTo`, shows banner above input with sender name + preview + close button; message persists `parent_message_id` into the `messages` table; bubbles render a `_replyPreviewFor` quoted preview with left accent border), **Copy** (unchanged), **Forward** (fetches all other chats via `_fetchThreadsForUser()` and shows a bottom-sheet picker; forwards text to the chosen chat by inserting a new `messages` row). `_ChatEntry` gained `id`, `senderId`, `replyToId` fields; `_loadMessages` now reads `id`/`parent_message_id`; `_ChatBubble` gained `replyPreview` param.
- **Thread loader refactored** — `_loadThreads()` in `_MessagesScreenState` now delegates to a shared private `_fetchThreadsForUser()` helper (same logic, reused by the forward picker).
- **`chat_fix_migration.sql`** — added `parent_message_id UUID REFERENCES messages(id)` defensive column (section 4b) for the reply feature; the column already exists in `supabase_schema.sql`.
- `dart analyze lib` clean (only 5 pre-existing `curly_braces_in_flow_control_structures` info lints).

## Work State (More menu dedup)
### Completed
- **More menu duplicates removed** — `panel_pages_config.dart` now merges static + dynamic pages through a shared `_combine()` helper. Dedup rules (static pages win): same page `id`, or same page `name` (case-insensitive). Applied to all 16 roles (`getPagesForPanel`).
- Resolved exact-name repeats: super_admin `System Settings` (drops dynamic `sa_settings`), admin `Announcements` (drops `ad_announcements`), teacher `Student Groups` (drops `tc_student_groups`), maintenance `Work Orders` (drops `mt_work_orders`).
- Same-table-but-different-title overlaps (e.g. `Tenant Management` vs `All Tenants`, `Expenses` placeholder vs `All Expenses` CRUD) intentionally left untouched per user choice.
- Added regression test `test/panel_pages_dedup_test.dart` — asserts every role has unique page ids + names and the 4 known repeats appear once. **All 17 tests pass.**
- `dart analyze lib`: **0 errors / 0 warnings** (631 pre-existing info lints).

## Work State (More menu items not clickable - FIXED)
### Completed
- **Root cause**: `showCurvedMoreSheet()` (curved_bottom_nav.dart:171) pushes `MoreScreen` via `Navigator.push`. Inside MoreScreen, tapping an item called `context.go(route)`, which navigates **underneath** the still-visible pushed More page — so nothing appeared to happen.
- **Fix** (`more_screen.dart`): added `_navigateTo()` — captures `GoRouter.of(context)`, pops the full-screen More page, then `router.go(route)` (fallback `router.goNamed(id)`). Applied to the profile header card, all ListTile items, and the logout button (which also used `context.go('/login')`).
- `dart analyze lib`: **0 errors / 0 warnings**; `flutter test test/panel_pages_dedup_test.dart`: all 17 pass.

### Blocked
- None.

## Work State (More page routes not registered - FIXED)
### Completed
- **Route-registration verification test** (`test/panel_pages_routes_test.dart`): go_router 17.x has NO public route-match API (`GoRouter.match`/`findMatch`/`buildTopLevelGoRouterState` are internal in `package:go_router/src/configuration.dart`), so the test reconstructs the set of registered paths from source instead: it parses every `path:` literal and `path: AppRoutesAll.<name>` identifier from `lib/nav.dart` (identifiers resolved against `lib/app_routes_all.dart`) and unions them with `AllPageDefinitions.pages` → `.route` (the dynamic routes built by `_buildDynamicRoutes()`). For each of the 16 roles it asserts every More page has a non-null `route`, no `:` path params, and that the route is in the registered set.
- **4 static More pages had routes that were NOT registered in nav.dart** → tapping them would throw `GoError: No route ...` after the pop-then-`context.go` fix. Fixed by registering GoRoutes in `lib/nav.dart` (after `/exams`):
  - `/student-profile` → `StudentProfileScreen` (`student_profile`, academic_support/admin)
  - `/library` → `LibraryScreen` (`library`, librarian)
  - `/calendar` → `CalendarScreen` (`calendar`, receptionist/event_manager)
  - `/home-page-management` → `staff_home.HomePageManagementScreen` (`home_page_management`, staff)
  - Added 4 imports at the top of `nav.dart` (`student_profile_screen.dart`, `library_screen.dart`, `calendar_screen.dart`, `staff/home_page_management_screen.dart` as `staff_home`). No class-name collisions.
- `flutter test test/panel_pages_routes_test.dart test/panel_pages_dedup_test.dart`: **all 33 tests pass**. `dart analyze lib`: **0 errors / 0 warnings** (631 pre-existing info lints).
- Note: `skeleton_screen_map.dart` had `em_event_calendar` → `EmEventCalendarScreen` (distinct from `calendar_screen.dart` `CalendarScreen`); no overlap.

### Blocked
- None.

## Work State (Notification realtime not pushing - FIXED)
### Completed
- **Root cause**: The notifications screen already subscribes to Supabase Realtime (`notificationStreamProvider` -> `NotificationRepository.subscribe()` -> channel `notification-realtime` -> PostgresChanges on `notifications`), but **no SQL ever added `notifications` to the `supabase_realtime` publication** (zero `PUBLICATION` statements in the repo). Without publication membership, Postgres emits NO change events, so new notifications never pushed to an open screen — they only appeared on reopen because the screen re-fetches on mount (`_loadInitial`).
- **DB fix** (`notification_realtime_migration.sql`): idempotent `ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications` guarded by a `pg_publication_tables` check, plus `ENABLE ROW LEVEL SECURITY`. The same idempotent block was appended to the end of `supabase_schema.sql`. RLS SELECT policy (`user_id = auth.uid()` / `notifications_own`) already allows realtime delivery to the target user. NOTE: must be run once in the Supabase SQL editor, then hard-restart the app so the channel reconnects.
- **Belt-and-suspenders client fix** (`notification_repository.dart`): added `refresh()` (re-fetches from DB and re-emits through the stream). `notification_compose_screen.dart` `_send()` now awaits `refresh()` after the RPC succeeds, so the still-mounted list screen updates immediately on pop even before the DB migration is run.
- `dart analyze lib`: **0 errors / 0 warnings** (631 pre-existing info lints); `flutter test`: all 34 pass.
- Note: `NotificationService.subscribeToNotifications()` (the FCM `NotificationService`, channel `app-notifications`) is NOT called anywhere in the app — only the repository realtime path is used, so no duplicate-channel conflict.

### Blocked
- None.

## Work State (Tenant wizard step logging - DONE)
### Completed
- **Per-step logging added to tenant wizard** (`lib/screens/super_admin/tenant_management_screen.dart`): `AppLogger` calls with tag `'TenantForm'` in `initState` (mode + loaded tenant fields), `_nextStep`/`_prevStep` (step transitions), every step builder (`_buildStep1..4` logs all current controller values + resolved centrals count), and `_save()` (logs all 4 steps' field values, validation block reason, parent resolution, the `addTenant`/`updateTenant` call, and a closing NOTE that the provider is in-memory).
- **Provider logging** (`lib/providers/tenant_provider.dart`): `addTenant`/`updateTenant`/`deleteTenant` now log with tag `'TenantProvider'` and an explicit warning that they are **IN-MEMORY ONLY — no Supabase call runs, nothing is written to the `tenants` table, data is lost on restart**. This is the answer to "why data does not save in tables".
- Root cause remains: `tenantProvider`/`TenantNotifier` is a mock `StateNotifier<List<Tenant>>` seeded with 5 hardcoded tenants; the wizard's `_save()` only mutates in-memory state. Fixing persistence requires wiring `TenantNotifier` to the Supabase `tenants` table (columns: `id, nid, name, slug, tenant_code, organization_type, parent_tenant_id, description, logo_url, featured, latitude, longitude, website, address, phone, email, services, working_hours, max_users, max_storage_mb, settings, plan, is_active, created_at, updated_at`).
- Verification: `flutter analyze` on both files → No issues; `flutter test` → **34/34 pass**.

## Work State (Tenant management columns + logo via buckets - DONE)
### Completed
- **Live DB checked via REST**: `tenants` HAS 5 seeded rows but anon-key queries return 0 because RLS (`tenants_select_isolation`) requires a session; views `tenant_hierarchy` (recursive CTE over `tenants`) and `tenant_branches_with_parent` are read-only, owned by `postgres` (bypass RLS) so they show the 5 rows. `cross_tenant_analytics` is a real table, 0 rows.
- **New tenants columns added** — `featured BOOLEAN DEFAULT FALSE`, `latitude DECIMAL(10,7)`, `longitude DECIMAL(10,7)`, `services JSONB DEFAULT '[]'`, `working_hours JSONB DEFAULT '{}'` (plus idempotent `nid`/`settings`). Applied to `supabase_schema.sql` `tenants` CREATE TABLE, `supabase/schema_hierarchical_tenants.sql` ALTER block, and one-shot `tenant_columns_migration.sql` (run in Supabase SQL editor; also creates `branding` bucket + storage policies).
- **`Tenant` model extended** (`lib/providers/tenant_provider.dart`): `featured`, `latitude`, `longitude`, `services` (List<String>), `workingHours` (Map<String,dynamic>{open,close}) + `copyWith`.
- **Wizard updated** (`tenant_management_screen.dart`): Step 2 gained Latitude/Longitude fields; Step 3 replaced the Logo URL text field with a **bucket image picker** (Camera/Gallery → `ImagePicker` → upload to `StorageBuckets.branding` path `tenants/<ts>.<ext>` → `getPublicUrl` stored in `logo_url`), added Featured switch, Services chip-input (InputChip + add field), and Working Hours open/close `showTimePicker` fields. `_save()` builds the new model fields; per-step logs include the new values.
- **Display**: `_TenantCard` (via `_TenantLogo` ClipOval widget) and `_TenantDetailPage` header now render `tenant.logoUrl` (`Image.network` with errorBuilder → business-icon fallback); detail page gained a Featured badge and a "Services & Hours" section (coordinates in Contact).
- **`tenantProvider` is now Supabase-backed** — `addTenant`/`updateTenant`/`deleteTenant` persist to the `tenants` table; wizard `_save()` awaits them with try/catch + error SnackBar and logs `'Tenant saved to Supabase'`. (The earlier "in-memory mock" conclusion is obsolete.)
- **Logo preview fix** (`_pickLogo`): the picker sets `_selectedLogoBytes` for an instant `Image.memory` preview that is **no longer cleared on upload failure** (old catch did `_selectedLogoBytes = null`, destroying the preview whenever upload threw). On failure it keeps the local image, shows a snackbar, and `_save()` **retries the upload** before persisting if `_logoUrl` is still null. Upload helper extracted to `_uploadLogoToBucket(bytes, ext, {contentType})` → `StorageBuckets.branding` path `tenants/<ts>.<ext>`.
- **Bucket verified live**: REST `POST /storage/v1/object/list/branding` → `200 []` — the `branding` bucket **exists** on the live project (the earlier empty `GET /storage/v1/bucket` under anon key does not list buckets; the object-list check confirms it). `StorageBuckets.branding = 'branding'` matches the DB bucket, so the name is correct.
- **Subfolder paths** — tenant & branch logos keep the flat top-level `branding/tenants/<ts>.<ext>` / `branding/branches/<ts>.<ext>` paths (the `logos/` folder is schema-seeded but has **no** `tenants`/`branches` subfolders, so we don't nest under it). `branch_info_screen.dart` catch now restores the old URL + shows a snackbar instead of silently swallowing. `storage_buckets.dart` doc notes `logos/` is seeded.
- Verification: `flutter analyze` on the file → No issues; `flutter test` → **34/34 pass**.

### Blocked
- `tenant_columns_migration.sql` must be run once in the Supabase SQL editor for the live DB (creates the new `tenants` columns + `branding` bucket + storage policies if not already applied).

## Work State (Tenant delete + edit - FIXED)
### Completed
- **Delete of central orgs failed (confirmed via live DB)**: `tenants` self-FK `parent_tenant_id REFERENCES tenants(id)` (no CASCADE) blocks deleting a central with branches. Live DB: central "International Education Group" has 4 branches (`B0001`–`B0004`). Fix in `TenantNotifier.deleteTenant`: first `UPDATE tenants SET parent_tenant_id = NULL WHERE parent_tenant_id = $id` (unlink branches), then `DELETE`. Test tenants `test`/`test 2` were created TODAY via the app (insert works ⇒ user role is super_admin ⇒ RLS insert/update/delete policies all present), so RLS is NOT the blocker.
- **All `_payload` columns verified present** on live `tenants` (REST select of every column returned `200`, no PGRST204) — update failure is not a missing-column issue.
- **Visible error reporting added** — `_TenantFormPageState` and list state each have an in-screen `_showErrorDialog(title, error, stackTrace, tenant:)` helper (AppLogger.e + debugPrint + `SelectableText` AlertDialog) wired into the update/create/delete catch blocks, replacing the bare snackbar so the exact Supabase error text is readable/copyable for further diagnosis.
- Verification: `flutter analyze` on both files → No issues; `flutter test` → **34/34 pass**.

### Active
- If update still fails after this change, the new error dialog exposes the exact message (paste it); likely candidates then are a UNIQUE violation (duplicate slug/tenant_code) or a data CHECK.

## Relevant Files
- `lib/utils/app_logger.dart`: Logging helper (log/w/e/uploadFailed, named error/stackTrace params)
- `lib/screens/super_admin/tenant_management_screen.dart`: 4-step wizard with per-step TenantForm logging + bucket logo picker with persistent preview + upload retry at save
- `lib/providers/tenant_provider.dart`: `Tenant` model (featured/latitude/longitude/services/workingHours) + Supabase-backed `TenantNotifier` (add/update/delete persist to `tenants`)
- `tenant_columns_migration.sql`: One-shot migration for the live DB (new tenants columns + `branding` bucket + storage policies)
- `chat_fix_migration.sql`: One-shot migration for the live DB (chat_uploads bucket + policies, chat_calls RLS/columns, messages/chat_messages columns)
- `notification_realtime_migration.sql`: Adds `notifications` to the `supabase_realtime` publication (idempotent) so realtime pushes work
- `test/panel_pages_dedup_test.dart`: Regression test for More-menu duplicate page ids/names
- `test/panel_pages_routes_test.dart`: Regression test that every More page route is registered in nav.dart/AllPageDefinitions

## Relevant Files
- `lib/screens/super_admin/user_creation_screen.dart`: Avatar picker with MemoryImage, _createUser with prints, tenant dropdown
- `lib/screens/users_screen.dart`: _UserFormPage 5-step wizard, full CRUD, tenant support, nid display, avatar fix
- `lib/utils/storage_buckets.dart`: All buckets documented with DB column references
- `add_numeric_ids.sql`: Adds `nid BIGSERIAL UNIQUE` to every table
- `supabase_schema.sql`: Full DB schema with all 100+ tables, RLS policies, functions, and appended notification triggers
- `supabase_notification_triggers.sql`: Standalone copy of all 18 notification triggers (appended to schema above)
- `tables.md`: Schema reference documentation (reference only, not executable)
- `lib/models/notification.dart`: Upgraded model with `body`, `priority`, `actionUrl`, `data`, `tenantId`, new types
- `lib/repositories/notification_repository.dart`: Realtime stream subscription + CRUD
- `lib/providers/notification_provider.dart`: `notificationStreamProvider` (StreamProvider) + existing StateNotifier
- `lib/services/notification_service.dart`: Added `subscribeToNotifications()`, `notificationStream`, `unreadCount`
- `lib/services/chat_service.dart`: PGRST200 join fix for `_fetchActiveCalls`/`_fetchCall`
- `lib/screens/notifications_screen.dart`: Stream-based display with priority badges and action links
- `lib/screens/notification_compose_screen.dart`: Compose form with General/By Role/Specific target modes
- `lib/screens/more_screen.dart`: Profile-first layout, `context.go(route)` navigation
- `lib/screens/settings_screen.dart`: `context.canPop()` guard on back button
- `lib/widgets/dashboard_desktop_layout.dart`: Full animated dashboard with carousel, staggered entrance, quick actions
- `lib/widgets/base_panel_layout.dart`: Conditional back button in `defaultAppBar`, bottom nav bar
- `lib/config/page_registry.dart`: `String? route` field on all PageRegistry entries
- `lib/config/panel_pages_config.dart`: Fixed `analytics` → `analytics_panel` reference
- `lib/app_routes_all.dart`: `notificationCompose` route constant
- `lib/screens/super_admin/system_settings_screen.dart`: Fixed System Settings screen using the real `settings` table (tenant-scoped, string-encoded values)

## Work State (User Impersonation / Force Login)
### Completed
- **Feature (adapted from `ai_agent_impersonation_blueprint.md` + `MIS_Enterprise_User_Impersonation_Complete_Cursor_Guide.md`)**: Super Admin can "Login As" any active non-super-admin user. Supabase auth stays the super admin (anon-key app, RLS sees the admin token); impersonation is an **app-layer session** in secure storage (key `impersonation_session`) that makes the whole UI behave as the target role for **30 minutes**, with a red banner + live countdown + Exit button. All actions are audited with dual identity (actor = admin, acting-as = target).
- **DB (run `impersonation_migration.sql` once in Supabase SQL editor; same SQL appended to end of `supabase_schema.sql`)** — new tables `impersonation_sessions` (tenant-scoped, `status` active/expired/revoked/ended, partial unique index `idx_impersonation_sessions_active_target` on `(target_user_id) WHERE status='active'` blocks duplicate impersonation) and `impersonation_log` (dual-identity audit: `actor_id` = admin, `target_user_id` = impersonated). Optional RPC `start_impersonation(p_target_user_id, p_reason)`; inserts fall back to guarded table writes if RPC missing. RLS: super-admin check via subquery `(SELECT role FROM profiles WHERE id = auth.uid()) = 'super_admin'` (safe — subquery targets a different table than the policy). Also documented in `tables.md`.
- **`lib/services/impersonation_service.dart`** — `ImpersonationSession` model + `ImpersonationService.start/exit/clear/getHistory/_log/_normalizeSession`; persists via `SecureStorageService.writeSession`, uses `AuthService` digest for verification hash in audit details.
- **`lib/services/secure_storage_service.dart`** — added `dart:convert`, `_impersonationSessionKey`, `writeSession/readSession/clearSession`.
- **`lib/providers/impersonation_provider.dart`** — `ImpersonationUiState` (`isImpersonating`, `effectiveRole`, `session`), `ImpersonationNotifier` (load/start/exit), `impersonationServiceProvider`, plus helpers **`resolveEffectiveRole(WidgetRef)`** and **`homeRouteForRole(String?)`** mapping roles → `AppRoutesAll.*` panel paths (verified: all route constants exist).
- **Global banner** — `lib/widgets/impersonation_banner.dart`: `ImpersonationBannerHost` (mounted in `main.dart` `MaterialApp.router` builder inside `PresenceObserver`/`DeepLinkHandler`) + `ImpersonationBanner` (red, countdown, Exit → `/super-admin`, 0s auto-exit). NOTE: `resolveEffectiveRole` is widget-only (`WidgetRef`); `nav.dart` redirect uses `Ref` so it reads `impersonationProvider` directly instead of the helper.
- **Effective-role wiring** — `nav.dart` redirect, `splash_screen.dart` (`impersonationProvider.notifier.load()` then `homeRouteForRole`), `base_panel_layout.dart`, `more_screen.dart`, `dashboard_screen.dart` all use `resolveEffectiveRole` so impersonated sessions land in the target user's panel/More menu.
- **Users screen** — `lib/screens/users_screen.dart`: per-card "Login As" button (icon `admin_panel_settings_outlined`, spinner while starting) shown only when caller is super_admin, target != self, target role != super_admin; reason-required confirmation dialog → `impersonationProvider.notifier.start()` → `context.go(homeRouteForRole(targetRole))`. App bar (super admin only) gains an **Impersonation Log** icon dialog (reads `impersonation_log` with `actor`/`target` profile joins, green→/red← arrows, reason + local time).
- **Logout clears impersonation** — `more_screen.dart` and `dashboard_screen.dart` sign-out handlers call `impersonationProvider.notifier.exit()` before clearing tokens/signOut (writes the audit trail then cleans local session).
- Verification: `flutter analyze lib` → **0 errors / 0 warnings** (remaining 631 pre-existing info lints); `flutter test` → **34/34 pass**.

### Blocked
- **User must run the SQL**: `impersonation_migration.sql` in the Supabase SQL editor (or re-run the appended section of `supabase_schema.sql`) so `impersonation_sessions`/`impersonation_log` tables + policies + optional RPC exist. Until then `start()` falls through to the guarded fallback inserts (which will fail until the tables exist — the snackbar will surface the error).
- Design note: impersonation is app-layer only — Supabase RLS still sees the super admin's token, so row-level data restrictions of the impersonated user are NOT applied by the DB (only the UI/panel routing reflects the target role). If true DB-level restriction is required, that'd need an auth-session swap (e.g. `auth.signOut` + `setSession` with the target's tokens), which is out of scope for the anon-key build.
