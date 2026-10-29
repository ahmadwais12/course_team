import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/nav.dart';
import 'package:course_emis/services/secure_storage_service.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/sign_out_dialog.dart';
import 'package:course_emis/widgets/adaptive/adaptive_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final isSystem = themeMode == ThemeMode.system;
    final locale = ref.watch(localeProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(t(LNav.settings, ref)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // Profile Summary
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: Icon(Icons.person_rounded, color: Colors.blue, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.userMetadata?['full_name'] ??
                            user?.userMetadata?['name'] ??
                            'User',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: () => context.go(AppRoutes.profile),
                  tooltip: t(LNav.profile, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // System Settings (server-side settings table, admins only)
          const _SystemSettingsSection(),

          const SizedBox(height: 20),

          // Appearance
          _SectionHeader(title: 'Appearance', icon: Icons.palette_outlined),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            title: 'Theme',
            subtitle: isSystem ? 'System' : (isDark ? 'Dark' : 'Light'),
            trailing: SizedBox(
              width: 160,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: ThemeMode.light, label: Text(t(L.light, ref))),
                  ButtonSegment(value: ThemeMode.system, label: Text(t(L.auto, ref))),
                  ButtonSegment(value: ThemeMode.dark, label: Text(t(L.dark, ref))),
                ],
                selected: {themeMode},
                onSelectionChanged: (v) {
                  ref.read(themeModeProvider.notifier).setThemeMode(v.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.language_outlined,
            title: t(LSettings.language, ref),
            subtitle: locale == 'en'
                ? 'English'
                : locale == 'fa'
                    ? 'Dari'
                    : 'Pashto',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context, ref, locale),
          ),

          const SizedBox(height: 20),

          // Notifications
          _SectionHeader(title: 'Notifications', icon: Icons.notifications_outlined),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.notifications_rounded,
            title: t(LNotif.pushNotifications, ref),
            trailing: AdaptiveSwitch(value: true, onChanged: (v) {}),
          ),
          _SettingsTile(
            icon: Icons.payment_outlined,
            title: t(LNotif.paymentReminders, ref),
            trailing: AdaptiveSwitch(value: true, onChanged: (v) {}),
          ),
          _SettingsTile(
            icon: Icons.event_outlined,
            title: t(LNotif.examReminders, ref),
            trailing: AdaptiveSwitch(value: true, onChanged: (v) {}),
          ),
          _SettingsTile(
            icon: Icons.attractions_outlined,
            title: t(LNotif.attendanceAlerts, ref),
            trailing: AdaptiveSwitch(value: true, onChanged: (v) {}),
          ),

          const SizedBox(height: 20),

          // Account & Security
          _SectionHeader(title: 'Account & Security', icon: Icons.shield_outlined),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: t(LSettings.changePassword, ref),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.changePassword),
          ),
          _SettingsTile(
            icon: Icons.devices_rounded,
            title: t(LModule.loggedInDevices, ref),
            subtitle: 'Manage active sessions',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.loggedInDevices),
          ),
          _SettingsTile(
            icon: Icons.fingerprint_rounded,
            title: 'Biometric & PIN Lock',
            subtitle: 'Secure app access',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t(LAll.all_coming_soon, ref))),
              );
            },
          ),

          const SizedBox(height: 20),

          // Data & Storage
          _SectionHeader(title: 'Data & Storage', icon: Icons.storage_outlined),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.cached_rounded,
            title: 'Clear Cache',
            subtitle: 'Free up local storage',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t(LAll.all_cache_cleared, ref))),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.download_rounded,
            title: 'Downloaded Content',
            subtitle: 'Manage offline files',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t(LAll.all_coming_soon, ref))),
              );
            },
          ),

          const SizedBox(height: 20),

          // Support & About
          _SectionHeader(title: 'Support & About', icon: Icons.help_outline),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.help_center_rounded,
            title: t(LModule.helpSupport, ref),
            subtitle: 'FAQs, contact, submit a ticket',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.helpSupport),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: t(LAbout.privacyPolicy, ref),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.aboutEmis),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: t(LAbout.termsOfService, ref),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.aboutEmis),
          ),
          _SettingsTile(
            icon: Icons.system_update_rounded,
            title: t(LModule.appUpdate, ref),
            subtitle: 'Check for updates',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.appUpdate),
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: t(LAbout.about, ref),
            subtitle: 'Version info & credits',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAboutDialog(context, ref),
          ),

          const SizedBox(height: 20),

          // Actions
          _SectionHeader(title: 'Actions', icon: Icons.tune_rounded),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.star_border_rounded,
            title: 'Rate the App',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(t(LAll.all_rate_on_play_store_app_store, ref))),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.share_rounded,
            title: 'Share the App',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t(LAll.all_share_link_copied, ref))),
              );
            },
          ),

          const SizedBox(height: 24),

          // Logout
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.red),
              ),
              title: Text(
                t(LNav.logout, ref),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.red),
              onTap: () async {
                final shouldSignOut = await showSignOutDialog(context, ref);
                if (!shouldSignOut) return;
                await SecureStorageService(const FlutterSecureStorage())
                    .clearTokens();
                await Supabase.instance.client.auth.signOut();
                ref.read(isDemoModeProvider.notifier).state = false;
                if (context.mounted) context.go(AppRoutes.login);
              },
            ),
          ),

          const SizedBox(height: 20),

          // App version footer
          Center(
            child: Text(
              'v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(
      BuildContext context, WidgetRef ref, String currentLocale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(LSettings.language, ref)),
        content: RadioGroup<String>(
          groupValue: currentLocale,
          onChanged: (v) {
            if (v == null) return;
            ref.read(localeProvider.notifier).setLocale(v);
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LangTile('English', 'en'),
              _LangTile('Dari', 'fa'),
              _LangTile('Pashto', 'ps'),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(LAbout.about, ref)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t(LAbout.aboutApp, ref)),
            const SizedBox(height: 8),
            Text(t(LAll.all_version_100, ref)),
            const SizedBox(height: 8),
            Text(t(LAll.all_copyright_2026_ahmad_wais_sarwari_all_rights_reser, ref)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(L.close, ref)),
          ),
        ],
      ),
    );
  }
}

class LoggedInDevicesScreen extends ConsumerStatefulWidget {
  const LoggedInDevicesScreen({super.key});

  @override
  ConsumerState<LoggedInDevicesScreen> createState() => _LoggedInDevicesScreenState();
}

class _LoggedInDevicesScreenState extends ConsumerState<LoggedInDevicesScreen> {
  List<_DeviceSession> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final data = await supabase
          .from('user_sessions')
          .select()
          .eq('user_id', userId)
          .order('last_active', ascending: false);

      final sessions = data.map<_DeviceSession>((row) {
        final platform = row['platform']?.toString() ?? '';
        return _DeviceSession(
          name: row['device_name']?.toString() ?? 'Unknown device',
          platform: platform,
          location: row['location']?.toString() ?? '',
          time: _formatTime(row['last_active']?.toString()),
          icon: _platformIcon(platform),
          isCurrent: row['is_current'] == true,
        );
      }).toList();

      if (mounted) setState(() => _devices = sessions);
    } catch (e) {
      if (mounted) setState(() => _devices = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    if (timestamp.length >= 19) {
      return timestamp.substring(0, 19).replaceAll('T', ' ');
    }
    return timestamp;
  }

  IconData _platformIcon(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('android') || p.contains('phone') || p.contains('mobile')) {
      return Icons.phone_android_rounded;
    } else if (p.contains('iphone') || p.contains('ios')) {
      return Icons.phone_iphone_rounded;
    } else if (p.contains('ipad') || p.contains('tablet')) {
      return Icons.tablet_mac_rounded;
    } else if (p.contains('chrome') ||
        p.contains('firefox') ||
        p.contains('safari') ||
        p.contains('browser') ||
        p.contains('web') ||
        p.contains('windows') ||
        p.contains('mac') ||
        p.contains('linux')) {
      return Icons.computer_rounded;
    }
    return Icons.devices_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(t(LModule.loggedInDevices, ref)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.devices_rounded, color: Colors.blue, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active devices and recent sign-ins',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Review where your account is being used',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_devices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(t(LAll.all_s590, ref)),
                    ),
                  )
                else
                  ..._devices.map(
                    (device) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.65),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(device.icon, color: const Color(0xFF1D4ED8)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          device.name,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (device.isCurrent)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            t(LStatus.activeStatus, ref),
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(tt(LAll.all_s11, ref, [device.platform, device.location])),
                                  Text(
                                    device.time,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: device.isCurrent
                                  ? null
                                  : () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(tt(LAll.all_s589, ref, [t(LNav.logout, ref), device.name])),
                                        ),
                                      );
                                    },
                              child: Text(
                                device.isCurrent ? t(LStatus.activeStatus, ref) : t(LNav.logout, ref),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_devices.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t(LNav.logout, ref))),
                      );
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    label: Text(t(LNav.logout, ref), style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ],
            ),
          );
  }
}

class AppUpdateScreen extends ConsumerWidget {
  const AppUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final packageInfo = snapshot.data;
        final currentVersion =
            packageInfo == null ? 'Loading...' : packageInfo.version;
        final buildNumber =
            packageInfo == null ? '--' : packageInfo.buildNumber;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            title: Text(t(LModule.appUpdate, ref)),
          ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.system_update_rounded, color: Color(0xFF0F766E), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stay on the latest EMIS build',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track the installed version and review release notes.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _UpdateStatusCard(
            title: 'Current build status',
            value: '$currentVersion+$buildNumber',
            subtitle:
                'Voice calls, video calls, file sharing, and panel notifications are included in this rollout.',
            accent: const Color(0xFF16A34A),
            icon: Icons.verified_rounded,
          ),
          const SizedBox(height: 12),
          const _UpdateStatusCard(
            title: 'Latest tracked release',
            value: '1.0.0',
            subtitle:
                'This version matches the current project bundle version.',
            accent: Color(0xFF2563EB),
            icon: Icons.system_update_alt_rounded,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.notes_rounded, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Release Notes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _ReleaseNoteTile(
            title: 'Panel communication upgrade',
            details:
                'Added richer chat entry points, direct and group messaging visibility, and clearer permission guidance.',
          ),
          const _ReleaseNoteTile(
            title: 'Student leave and profile rules',
            details:
                'Student leave policy and profile edit restrictions are now reflected across the UI.',
          ),
          const _ReleaseNoteTile(
            title: 'Settings expansion',
            details:
                'Logged-in devices and app update tools are now available as dedicated settings pages.',
          ),
        ],
      ),
    );
      },
    );
  }
}

class _LangTile extends StatelessWidget {
  final String label;
  final String value;

  const _LangTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      leading: Radio<String>(
        value: value,
      ),
      onTap: () {
        RadioGroup.maybeOf<String>(context)?.onChanged.call(value);
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _SystemSettingsSection extends StatefulWidget {
  const _SystemSettingsSection();

  @override
  State<_SystemSettingsSection> createState() => _SystemSettingsSectionState();
}

class _SystemSettingsSectionState extends State<_SystemSettingsSection> {
  List<Map<String, dynamic>> _settings = [];
  bool _canManage = false;
  String? _tenantId;

  bool _maintenanceMode = false;
  bool _registrationEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  int _sessionTimeoutMinutes = 30;
  int _maxLoginAttempts = 5;
  String _defaultLanguage = 'en';
  String _defaultTimezone = 'UTC';

  final _sessionTimeoutCtrl = TextEditingController(text: '30');
  final _maxLoginCtrl = TextEditingController(text: '5');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sessionTimeoutCtrl.dispose();
    _maxLoginCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final profile = await Supabase.instance.client
          .from('users')
          .select('tenant_id, role')
          .eq('id', user.id)
          .maybeSingle();
      final role = profile?['role']?.toString().toLowerCase() ?? '';
      final isAdmin = role == 'super_admin' || role == 'admin';
      if (!mounted || !isAdmin) return;
      final tenantId = profile?['tenant_id']?.toString();
      _tenantId = tenantId;

      final baseQuery = Supabase.instance.client.from('settings').select();
      final filteredQuery =
          tenantId != null ? baseQuery.eq('tenant_id', tenantId) : baseQuery;
      final data = await filteredQuery.order('key');
      if (!mounted) return;
      setState(() {
        _settings = List<Map<String, dynamic>>.from(data);
        _applySettings(_settings);
        _canManage = true;
      });
    } catch (e) {
      debugPrint('[SystemSettings] load error: $e');
    }
  }

  void _applySettings(List<Map<String, dynamic>> data) {
    for (final s in data) {
      final key = s['key']?.toString() ?? '';
      final value = s['value'];
      switch (key) {
        case 'maintenance_mode':
          _maintenanceMode = value == true || value == 'true';
        case 'registration_enabled':
          _registrationEnabled = value != false && value != 'false';
        case 'email_notifications':
          _emailNotifications = value != false && value != 'false';
        case 'sms_notifications':
          _smsNotifications = value == true || value == 'true';
        case 'session_timeout_minutes':
          _sessionTimeoutMinutes =
              int.tryParse(value?.toString() ?? '') ?? 30;
          _sessionTimeoutCtrl.text = _sessionTimeoutMinutes.toString();
        case 'max_login_attempts':
          _maxLoginAttempts = int.tryParse(value?.toString() ?? '') ?? 5;
          _maxLoginCtrl.text = _maxLoginAttempts.toString();
        case 'default_language':
          _defaultLanguage = value?.toString() ?? 'en';
        case 'default_timezone':
          _defaultTimezone = value?.toString() ?? 'UTC';
      }
    }
  }

  String _encodeValue(dynamic value) {
    if (value is bool) return value ? 'true' : 'false';
    return value.toString();
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final encoded = _encodeValue(value);
      final existing = _settings.any((s) => s['key'] == key);
      final tenantId = _tenantId;
      var query = Supabase.instance.client
          .from('settings')
          .update({
            'value': encoded,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('key', key);
      if (tenantId != null) query = query.eq('tenant_id', tenantId);
      if (existing) {
        await query;
      } else {
        final payload = <String, dynamic>{
          'key': key,
          'value': encoded,
          'category': 'general',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (tenantId != null) payload['tenant_id'] = tenantId;
        await Supabase.instance.client.from('settings').insert(payload);
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Future<void> _saveAll() async {
    final messenger = ScaffoldMessenger.of(context);
    await _saveSetting('maintenance_mode', _maintenanceMode);
    await _saveSetting('registration_enabled', _registrationEnabled);
    await _saveSetting('email_notifications', _emailNotifications);
    await _saveSetting('sms_notifications', _smsNotifications);
    await _saveSetting('session_timeout_minutes', _sessionTimeoutMinutes);
    await _saveSetting('max_login_attempts', _maxLoginAttempts);
    await _saveSetting('default_language', _defaultLanguage);
    await _saveSetting('default_timezone', _defaultTimezone);
    if (mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('System settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canManage) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const _SectionHeader(title: 'System Settings', icon: Icons.settings_outlined),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.build_circle_outlined,
          title: 'Maintenance Mode',
          subtitle: 'Put the system in maintenance mode',
          trailing: AdaptiveSwitch(
            value: _maintenanceMode,
            onChanged: (v) {
              setState(() => _maintenanceMode = v);
              _saveSetting('maintenance_mode', v);
            },
          ),
        ),
        _SettingsTile(
          icon: Icons.person_add_outlined,
          title: 'Registration Enabled',
          subtitle: 'Allow new user registrations',
          trailing: AdaptiveSwitch(
            value: _registrationEnabled,
            onChanged: (v) {
              setState(() => _registrationEnabled = v);
              _saveSetting('registration_enabled', v);
            },
          ),
        ),
        _SettingsTile(
          icon: Icons.email_outlined,
          title: 'Email Notifications',
          subtitle: 'Send email notifications for system events',
          trailing: AdaptiveSwitch(
            value: _emailNotifications,
            onChanged: (v) {
              setState(() => _emailNotifications = v);
              _saveSetting('email_notifications', v);
            },
          ),
        ),
        _SettingsTile(
          icon: Icons.sms_outlined,
          title: 'SMS Notifications',
          subtitle: 'Send SMS notifications for critical alerts',
          trailing: AdaptiveSwitch(
            value: _smsNotifications,
            onChanged: (v) {
              setState(() => _smsNotifications = v);
              _saveSetting('sms_notifications', v);
            },
          ),
        ),
        _SettingsTile(
          icon: Icons.timer_outlined,
          title: 'Session Timeout (minutes)',
          subtitle: 'Auto-logout after inactivity',
          trailing: _numberField(
            _sessionTimeoutCtrl,
            (v) {
              final parsed = int.tryParse(v);
              if (parsed != null && parsed > 0) {
                setState(() => _sessionTimeoutMinutes = parsed);
                _saveSetting('session_timeout_minutes', parsed);
              }
            },
          ),
        ),
        _SettingsTile(
          icon: Icons.lock_outline_rounded,
          title: 'Max Login Attempts',
          subtitle: 'Lock account after failed attempts',
          trailing: _numberField(
            _maxLoginCtrl,
            (v) {
              final parsed = int.tryParse(v);
              if (parsed != null && parsed > 0) {
                setState(() => _maxLoginAttempts = parsed);
                _saveSetting('max_login_attempts', parsed);
              }
            },
          ),
        ),
        _SettingsTile(
          icon: Icons.language_outlined,
          title: 'Default Language',
          subtitle: 'Language for new users',
          trailing: DropdownButton<String>(
            value: _defaultLanguage,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'prs', child: Text('Dari')),
              DropdownMenuItem(value: 'ps', child: Text('Pashto')),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => _defaultLanguage = v);
                _saveSetting('default_language', v);
              }
            },
          ),
        ),
        _SettingsTile(
          icon: Icons.access_time_outlined,
          title: 'Default Timezone',
          subtitle: 'System-wide timezone',
          trailing: DropdownButton<String>(
            value: _defaultTimezone,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'UTC', child: Text('UTC')),
              DropdownMenuItem(value: 'Asia/Kabul', child: Text('Asia/Kabul')),
              DropdownMenuItem(value: 'Asia/Dubai', child: Text('Asia/Dubai')),
              DropdownMenuItem(
                  value: 'America/New_York', child: Text('America/New_York')),
              DropdownMenuItem(
                  value: 'Europe/London', child: Text('Europe/London')),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => _defaultTimezone = v);
                _saveSetting('default_timezone', v);
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _saveAll,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save All System Settings'),
        ),
      ],
    );
  }

  Widget _numberField(
      TextEditingController controller, ValueChanged<String> onSubmitted) {
    return SizedBox(
      width: 100,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(),
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }
}

class _DeviceSession {
  final String name;
  final String platform;
  final String location;
  final String time;
  final IconData icon;
  final bool isCurrent;

  const _DeviceSession({
    required this.name,
    required this.platform,
    required this.location,
    required this.time,
    required this.icon,
    this.isCurrent = false,
  });
}

class _UpdateStatusCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;

  const _UpdateStatusCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                ),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReleaseNoteTile extends StatelessWidget {
  final String title;
  final String details;

  const _ReleaseNoteTile({
    required this.title,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.65),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF0F766E),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(details),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
