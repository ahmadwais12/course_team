import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/theme/dashboard_theme.dart';
import 'package:course_emis/providers/settings_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:course_emis/nav.dart';
import 'package:course_emis/providers/impersonation_provider.dart';
import 'package:course_emis/services/secure_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    // Artificial delay for splash animation
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Wait for onboarding status to be loaded (not null)
    bool? hasSeenOnboarding = ref.read(onboardingStatusProvider);
    int retryCount = 0;
    while (hasSeenOnboarding == null && retryCount < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      hasSeenOnboarding = ref.read(onboardingStatusProvider);
      retryCount++;
    }

    // Default to false if it somehow fails to load
    hasSeenOnboarding ??= false;

    var session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      final secureStorage = SecureStorageService(const FlutterSecureStorage());
      final at = await secureStorage.getAccessToken();
      final rt = await secureStorage.getRefreshToken();
      if (at != null && at.isNotEmpty) {
        try {
          final json = rt != null && rt.isNotEmpty
              ? "{\"access_token\":\"$at\",\"refresh_token\":\"$rt\"}"
              : "{\"access_token\":\"$at\"}";
          await Supabase.instance.client.auth.setSession(json);
          session = Supabase.instance.client.auth.currentSession;
        } catch (_) {
          await secureStorage.clearTokens();
        }
      }
    }
    final user = session?.user;

    if (!mounted) return;

    if (!hasSeenOnboarding) {
      context.go(AppRoutesAll.onboarding);
    } else if (session == null) {
      context.go(AppRoutesAll.login);
    } else if (user != null) {
      // Restore any active impersonation before deciding where to land.
      await ref.read(impersonationProvider.notifier).load();
      if (!mounted) return;

      // Role-based redirection logic (honors an active impersonation).
      final role = resolveEffectiveRole(ref);
      debugPrint('User Logged In: ${user.email}, Role: $role');

      context.go(homeRouteForRole(role));
    } else {
      context.go(AppRoutesAll.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return _buildDesktop();
        }
        return _buildMobile(context);
      },
    );
  }

  Widget _buildDesktop() {
    return Scaffold(
      backgroundColor: dtBgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dtPrimaryColor.withValues(alpha: 0.15),
                    blurRadius: 80,
                    spreadRadius: 15,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: dtCardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: dtPrimaryColor.withValues(alpha: 0.4), width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo/dreamflow-icon-black.png',
                    width: 160, height: 160,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'DreamFlow',
              style: TextStyle(
                color: dtTextColor,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 32, height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: dtPrimaryColor,
              ),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(bottom: 32),
              child: Text(
                'Developed by Ahmad Wais Sarwari',
                style: TextStyle(color: dtSecondaryColor, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                    ),
                  ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          isDark
                              ? 'assets/logo/dreamflow-icon-black.png'
                              : 'assets/logo/dreamflow-icon-black.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'DreamFlow',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'Developed by Ahmad Wais Sarwari',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
