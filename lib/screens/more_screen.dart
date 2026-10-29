import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:course_emis/config/page_registry.dart';
import 'package:course_emis/config/panel_pages_config.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/providers/auth_provider.dart';
import 'package:course_emis/providers/impersonation_provider.dart';
import 'package:course_emis/services/secure_storage_service.dart';
import 'package:course_emis/widgets/sign_out_dialog.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final role = resolveEffectiveRole(ref);

    String t(String key) => AppLocalizations.translate(key, locale);

    final userName = user?.userMetadata?['full_name'] as String? ?? '';
    final userEmail = user?.email ?? '';
    final avatarAsync = ref.watch(currentUserAvatarUrlProvider);
    final metaAvatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final avatarUrl = avatarAsync.valueOrNull ?? metaAvatarUrl;
    final pages = PanelPagesConfig.getPagesForPanel(role);

    // Extract profile page for first position
    PageRegistry? profilePage;
    final Map<String, List<PageRegistry>> grouped = {};
    for (final page in pages) {
      if (page.id == 'profile') {
        profilePage = page;
      } else {
        grouped.putIfAbsent(page.category, () => []).add(page);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t(LModule.moreOptions)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Profile Header ───
          if (profilePage != null)
            Material(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _navigateTo(context, profilePage!),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64, height: 64,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                              child: Icon(Icons.person,
                                  color: theme.colorScheme.primary, size: 32),
                            ),
                            if (avatarUrl != null && avatarUrl.isNotEmpty)
                              ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  width: 64, height: 64,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const SizedBox(),
                                  errorWidget: (_, __, ___) => const SizedBox(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName.isNotEmpty ? userName : t(LNav.profile),
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userEmail.isNotEmpty ? userEmail : _getRoleDisplay(role),
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getRoleDisplay(role),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.chevron_right_rounded,
                                    color: Colors.grey[400], size: 20),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),

          // ─── Pages by Category ───
          ...grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[500],
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < entry.value.length; i++) ...[
                        ListTile(
                          leading: Icon(entry.value[i].icon,
                              color: theme.colorScheme.primary),
                          title: Text(
                            entry.value[i].name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                          subtitle: Text(
                            entry.value[i].description,
                            style:
                                TextStyle(color: Colors.grey[500], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(Icons.chevron_right_rounded,
                              color: Colors.grey[400]),
                          onTap: () => _navigateTo(context, entry.value[i]),
                        ),
                        if (i < entry.value.length - 1)
                          Divider(height: 1, indent: 56, color: Colors.grey[100]),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          }),

          // ─── Logout ───
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showSignOutDialog(context, ref);
                if (confirmed && context.mounted) {
                  final router = GoRouter.of(context);
                  await ref.read(impersonationProvider.notifier).exit();
                  await SecureStorageService(const FlutterSecureStorage()).clearTokens();
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    router.go('/login');
                  }
                }
              },
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: Text(t(LNav.logout)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[700],
                side: BorderSide(color: Colors.red[200]!),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Close the full-screen More page, then navigate with the GoRouter.
  /// MoreScreen is pushed via Navigator.push, so a plain context.go would
  /// navigate underneath the still-visible More page (appears to do nothing).
  void _navigateTo(BuildContext context, PageRegistry page) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    final route = page.route;
    if (route != null) {
      router.go(route);
    } else {
      router.goNamed(page.id);
    }
  }

  String _getRoleDisplay(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'hr_manager':
        return 'HR Manager';
      case 'it_support':
        return 'IT Support';
      case 'academic_support':
        return 'Academic Support';
      case 'complaint_manager':
        return 'Complaint Manager';
      case 'inventory_manager':
        return 'Inventory Manager';
      case 'event_manager':
        return 'Event Manager';
      default:
        return role[0].toUpperCase() + role.substring(1);
    }
  }
}
