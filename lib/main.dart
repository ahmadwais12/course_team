import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'nav.dart';
import 'config/supabase_config.dart';
import 'l10n/app_localizations.dart';
import 'core/deep_link/deep_link_service.dart';
import 'core/deep_link/widgets/deep_link_handler.dart';
import 'services/secure_storage_service.dart';
import 'widgets/presence_observer.dart';
import 'widgets/impersonation_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  // Restore session from saved tokens
  try {
    final secureStorage = SecureStorageService(const FlutterSecureStorage());
    final at = await secureStorage.getAccessToken();
    final rt = await secureStorage.getRefreshToken();
    if (at != null && at.isNotEmpty) {
      final currentSession = Supabase.instance.client.auth.currentSession;
      if (currentSession == null) {
        final json = rt != null && rt.isNotEmpty
            ? "{\"access_token\":\"$at\",\"refresh_token\":\"$rt\"}"
            : "{\"access_token\":\"$at\"}";
        await Supabase.instance.client.auth.setSession(json);
        debugPrint('Session restored from saved tokens');
      }
    }
  } catch (e) {
    debugPrint('Session restore error (non-fatal): $e');
  }

  final deepLinkService = DeepLinkService();
  await deepLinkService.init();

  // Pre-load saved locale + theme so they apply from the very first frame
  // (otherwise they'd fall back to defaults / flash on every app start).
  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('app_locale');
  const supportedLocales = {'en', 'fa', 'prs', 'ps'};
  final initialLocale =
      savedLocale != null && supportedLocales.contains(savedLocale)
          ? savedLocale
          : null;

  ThemeMode? initialThemeMode;
  switch (prefs.getString('app_theme_mode')) {
    case 'light':
      initialThemeMode = ThemeMode.light;
    case 'dark':
      initialThemeMode = ThemeMode.dark;
    case 'system':
      initialThemeMode = ThemeMode.system;
  }

  runApp(ProviderScope(
    overrides: [
      if (initialLocale != null)
        localeProvider.overrideWith((ref) => LocaleNotifier(initialLocale)),
      if (initialThemeMode != null)
        themeModeProvider.overrideWith(
            (ref) => ThemeModeNotifier(initialThemeMode)),
      deepLinkServiceProvider.overrideWithValue(deepLinkService),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);
    final textDirection = ref.watch(textDirectionProvider);

    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 1024;

    return ScreenUtilInit(
      designSize: isDesktop ? const Size(1440, 900) : const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      builder: (context, child) {
        return Directionality(
          textDirection: textDirection,
          child: ResponsiveBreakpoints.builder(
            breakpoints: [
              const Breakpoint(start: 0, end: 599, name: MOBILE),
              const Breakpoint(start: 600, end: 1023, name: TABLET),
              const Breakpoint(start: 1024, end: 1439, name: DESKTOP),
              const Breakpoint(start: 1440, end: 1919, name: 'LARGE'),
              const Breakpoint(start: 1920, end: double.infinity, name: 'ULTRA_WIDE'),
            ],
            child: MaterialApp.router(
              title: 'Ahmad Wais Sarwari',
              debugShowCheckedModeBanner: false,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeMode,
              locale: Locale(locale),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('fa'),
                Locale('ps'),
              ],
              localeResolutionCallback: (locale, supportedLocales) {
                if (locale == null) return const Locale('en');
                final lang = locale.languageCode == 'prs' ? 'fa' : locale.languageCode;
                for (final supported in supportedLocales) {
                  if (supported.languageCode == lang) return supported;
                }
                return const Locale('en');
              },
              routerConfig: router,
              builder: (context, child) => PresenceObserver(
                child: DeepLinkHandler(
                  child: ImpersonationBannerHost(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
