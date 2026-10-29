import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/providers/auth_provider.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _profile = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final email = _profile?['email']?.toString() ?? user?.email ?? 'Not available';
    final role = _profile?['role']?.toString() ?? user?.userMetadata?['role']?.toString() ?? 'Unknown';
    final name = _profile?['full_name']?.toString() ?? user?.userMetadata?['full_name']?.toString() ?? 'User';
    final phone = _profile?['phone']?.toString();
    final address = _profile?['address']?.toString();
    final nid = _profile?['nid']?.toString();
    final bloodGroup = _profile?['blood_group']?.toString();
    final maritalStatus = _profile?['marital_status']?.toString();
    final nationality = _profile?['nationality']?.toString();
    final religion = _profile?['religion']?.toString();
    final fatherName = _profile?['father_name']?.toString();
    final tazkiraNumber = _profile?['tazkira_number']?.toString();
    final passportId = _profile?['passport_id']?.toString();
    final joinedAt = _profile?['created_at']?.toString();
    final joinedDate = joinedAt != null && joinedAt.length >= 10 ? joinedAt.substring(0, 10) : null;
    final isStudent = role == 'student';

    final avatarAsync = ref.watch(currentUserAvatarUrlProvider);
    final avatarUrl = avatarAsync.valueOrNull ?? _profile?['avatar_url']?.toString();

    if (_loading) {
      return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()), title: Text(t(LNav.profile, ref))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        title: Text(t(LNav.profile, ref)),
        actions: [
          if (!isStudent)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => context.go('/settings'),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: AppSpacing.paddingLg,
            children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                SizedBox(
                  width: 120, height: 120,
                  child: Stack(
                    children: [
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFF67E8F9)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getRoleIcon(role),
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      if (avatarUrl != null && avatarUrl.isNotEmpty)
                        ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: avatarUrl,
                            width: 120, height: 120,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const SizedBox(),
                            errorWidget: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    role.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          if (isStudent) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Student profile updates are managed by teachers and staff. You can view your record here, but you cannot edit the student profile from this panel.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Profile Information
          Text(
            'Personal Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Card(
            child: Padding(
              padding: AppSpacing.paddingMd,
              child: Column(
                children: [
                  _buildInfoRow(Icons.person_rounded, 'Name', name),
                  const Divider(),
                  _buildInfoRow(Icons.email_rounded, 'Email', email),
                  const Divider(),
                  _buildInfoRow(Icons.badge_rounded, 'Role', role.replaceAll('_', ' ')),
                  const Divider(),
                  _buildInfoRow(Icons.phone_rounded, 'Phone', phone ?? 'Not provided'),
                  if (address != null) ...[
                    const Divider(),
                    _buildInfoRow(Icons.location_on_rounded, 'Address', address),
                  ],
                  if (nid != null) ...[
                    const Divider(),
                    _buildInfoRow(Icons.tag_rounded, 'NID', '#$nid'),
                  ],
                  if (bloodGroup != null) ...[
                    const Divider(),
                    _buildInfoRow(Icons.bloodtype_rounded, 'Blood Group', bloodGroup),
                  ],
                  if (maritalStatus != null) ...[
                    const Divider(),
                    _buildInfoRow(Icons.favorite_rounded, 'Marital Status', maritalStatus[0].toUpperCase() + maritalStatus.substring(1)),
                  ],
                  if (nationality != null) ...[
                    const Divider(),
                    _buildInfoRow(Icons.flag_rounded, 'Nationality', nationality),
                  ],
                  if (religion != null) ...[
                    const Divider(),
                    _buildInfoRow(Icons.church_rounded, 'Religion', religion),
                  ],
                  if (fatherName != null) ...[
                    const Divider(),
                    _buildInfoRow(Icons.man_rounded, "Father's Name", fatherName),
                  ],
                  if (tazkiraNumber != null) ...[
                    const Divider(),
                    _buildInfoRow(Icons.badge_outlined, 'Tazkira Number', tazkiraNumber),
                  ],
                  if (passportId != null) ...[
                    const Divider(),
                    _buildInfoRow(Icons.airplane_ticket_rounded, 'Passport ID', passportId),
                  ],
                  const Divider(),
                  _buildInfoRow(Icons.calendar_today_rounded, 'Joined', joinedDate ?? 'Unknown'),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Quick Actions
          Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: AppSpacing.paddingSm,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child:
                        const Icon(Icons.settings_rounded, color: Colors.blue),
                  ),
                  title: Text(t(LAll.all_account_settings, ref)),
                  subtitle: Text(
                    isStudent
                        ? 'Manage theme, language, and security preferences'
                        : 'Manage your account preferences',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go('/settings'),
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: AppSpacing.paddingSm,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.lock_outline_rounded,
                        color: Colors.orange),
                  ),
                  title: Text(t(LSettings.changePassword, ref)),
                  subtitle: Text(t(LAll.all_update_your_password, ref)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go('/change-password'),
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: AppSpacing.paddingSm,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        color: Colors.red),
                  ),
                  title: Text(t(LTitle.notificationPrefs, ref)),
                  subtitle: Text(t(LAll.all_customize_your_notifications, ref)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go('/notifications'),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Statistics
          Text(
            'Your Activity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard(
                context,
                'Tasks Completed',
                '45',
                Icons.check_circle_rounded,
                Colors.blue,
              ),
              _buildStatCard(
                context,
                'Pending Items',
                '12',
                Icons.pending_actions_rounded,
                Colors.orange,
              ),
              _buildStatCard(
                context,
                'Notifications',
                '8',
                Icons.notifications_rounded,
                Colors.blue,
              ),
              _buildStatCard(
                context,
                'Reports Viewed',
                '23',
                Icons.assessment_rounded,
                Colors.purple,
              ),
            ],
          ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: InkWell(
        onTap: () => context.go('/reports'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'super_admin':
        return Icons.admin_panel_settings_rounded;
      case 'admin':
        return Icons.verified_user_rounded;
      case 'teacher':
        return Icons.school_rounded;
      case 'student':
        return Icons.menu_book_rounded;
      case 'parent':
        return Icons.family_restroom_rounded;
      case 'guardian':
        return Icons.family_restroom_rounded;
      case 'academic_support':
        return Icons.school_rounded;
      case 'accountant':
        return Icons.account_balance_rounded;
      case 'librarian':
        return Icons.library_books_rounded;
      case 'receptionist':
        return Icons.receipt_long_rounded;
      default:
        return Icons.person_rounded;
    }
  }
}
