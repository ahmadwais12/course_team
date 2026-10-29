import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/providers/settings_provider.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/theme/dashboard_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    await ref.read(onboardingStatusProvider.notifier).completeOnboarding();
    if (!mounted) return;
    context.go('/home');
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return _buildDesktop();
        }
        return _buildMobile();
      },
    );
  }

  Widget _buildDesktop() {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final logoAsset = 'assets/logo/dreamflow-icon-black.png';

    return Scaffold(
      backgroundColor: dtBgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _currentPage = value),
                children: [
                  _IntroStep(
                    logoAsset: logoAsset,
                    appName: 'DreamFlow',
                    bgColor: dtCardColor,
                    fgColor: dtTextColor,
                    isDesktop: true,
                  ),
                  _StepContainer(
                    title: AppLocalizations.translate(L.selectLanguage, locale),
                    subtitle: t(LExtra.chooseLanguage, ref),
                    isDesktop: true,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _ChoicePill(
                          label: t(LExtra.english, ref),
                          selected: locale == 'en',
                          onTap: () => ref.read(localeProvider.notifier).setLocale('en'),
                        ),
                        _ChoicePill(
                          label: t(LExtra.pashto, ref),
                          selected: locale == 'ps',
                          onTap: () => ref.read(localeProvider.notifier).setLocale('ps'),
                        ),
                        _ChoicePill(
                          label: t(LExtra.dari, ref),
                          selected: locale == 'fa',
                          onTap: () => ref.read(localeProvider.notifier).setLocale('fa'),
                        ),
                      ],
                    ),
                  ),
                  _StepContainer(
                    title: AppLocalizations.translate(L.themeMode, locale),
                    subtitle: t(LSettings.theme, ref),
                    isDesktop: true,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _ChoicePill(
                          label: t(LExtra.lightMode, ref),
                          icon: Icons.light_mode_outlined,
                          selected: themeMode == ThemeMode.light,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.light),
                        ),
                        _ChoicePill(
                          label: t(LExtra.darkMode, ref),
                          icon: Icons.dark_mode_outlined,
                          selected: themeMode == ThemeMode.dark,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.dark),
                        ),
                        _ChoicePill(
                          label: t(LExtra.systemMode, ref),
                          icon: Icons.brightness_auto_outlined,
                          selected: themeMode == ThemeMode.system,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.system),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: AppSpacing.paddingXl,
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: List.generate(
                        3,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          width: _currentPage == index ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? dtPrimaryColor
                                : dtSecondaryColor.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_currentPage > 0) ...[
                    OutlinedButton(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: dtTextColor,
                        side: BorderSide(color: dtBorderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      child: Text(AppLocalizations.translate(L.back, locale)),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dtPrimaryColor,
                          foregroundColor: dtTextColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentPage == 0
                              ? AppLocalizations.translate(LDash.welcomeBack, locale)
                              : AppLocalizations.translate(L.cContinue, locale),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobile() {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = theme.brightness == Brightness.dark;
    final logoAsset = isDark
        ? 'assets/logo/dreamflow-icon-black.png'
        : 'assets/logo/dreamflow-icon-black.png';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (value) => setState(() => _currentPage = value),
                  children: [
                    _IntroStep(
                      logoAsset: logoAsset,
                      appName: 'DreamFlow',
                      bgColor: isDark ? AppColors.darkSurface.withValues(alpha: 0.85) : AppColors.lightSurface.withValues(alpha: 0.75),
                      fgColor: isDark ? Colors.white : Colors.black87,
                    ),
                    _StepContainer(
                      title: AppLocalizations.translate(L.selectLanguage, locale),
                      subtitle: t(LExtra.chooseLanguage, ref),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          _ChoicePill(
                            label: t(LExtra.english, ref),
                            selected: locale == 'en',
                            onTap: () => ref.read(localeProvider.notifier).setLocale('en'),
                          ),
                          _ChoicePill(
                            label: t(LExtra.pashto, ref),
                            selected: locale == 'ps',
                            onTap: () => ref.read(localeProvider.notifier).setLocale('ps'),
                          ),
                          _ChoicePill(
                            label: t(LExtra.dari, ref),
                            selected: locale == 'fa',
                            onTap: () => ref.read(localeProvider.notifier).setLocale('fa'),
                          ),
                        ],
                      ),
                    ),
                    _StepContainer(
                      title: AppLocalizations.translate(L.themeMode, locale),
                      subtitle: t(LSettings.theme, ref),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          _ChoicePill(
                            label: t(LExtra.lightMode, ref),
                            icon: Icons.light_mode_outlined,
                            selected: themeMode == ThemeMode.light,
                            onTap: () => ref
                                .read(themeModeProvider.notifier)
                                .setThemeMode(ThemeMode.light),
                          ),
                          _ChoicePill(
                            label: t(LExtra.darkMode, ref),
                            icon: Icons.dark_mode_outlined,
                            selected: themeMode == ThemeMode.dark,
                            onTap: () => ref
                                .read(themeModeProvider.notifier)
                                .setThemeMode(ThemeMode.dark),
                          ),
                          _ChoicePill(
                            label: t(LExtra.systemMode, ref),
                            icon: Icons.brightness_auto_outlined,
                            selected: themeMode == ThemeMode.system,
                            onTap: () => ref
                                .read(themeModeProvider.notifier)
                                .setThemeMode(ThemeMode.system),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: AppSpacing.paddingXl,
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: List.generate(
                          3,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            width: _currentPage == index ? 26 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: _currentPage == index ? 1.0 : 0.35)
                                  : Colors.black87.withValues(alpha: _currentPage == index ? 0.7 : 0.25),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_currentPage > 0) ...[
                      OutlinedButton(
                        onPressed: _previousPage,
                        child: Text(AppLocalizations.translate(L.back, locale)),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          child: Text(
                            _currentPage == 0
                                ? AppLocalizations.translate(LDash.welcomeBack, locale)
                                : AppLocalizations.translate(L.cContinue, locale),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({
    required this.logoAsset,
    required this.appName,
    required this.bgColor,
    required this.fgColor,
    this.isDesktop = false,
  });

  final String logoAsset;
  final String appName;
  final Color bgColor;
  final Color fgColor;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 640 : 480),
          child: Container(
            padding: isDesktop
                ? const EdgeInsets.symmetric(horizontal: 60, vertical: 56)
                : const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(isDesktop ? 32 : AppRadius.xl),
              border: Border.all(
                color: isDesktop ? dtBorderColor : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black87.withValues(alpha: 0.06)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isDesktop ? 200 : 160,
                  height: isDesktop ? 200 : 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: isDesktop
                        ? [
                            BoxShadow(color: dtPrimaryColor.withValues(alpha: 0.2), blurRadius: 70, spreadRadius: 12),
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 25, offset: const Offset(0, 8)),
                          ]
                        : [
                            BoxShadow(color: dtPrimaryColor.withValues(alpha: 0.15), blurRadius: 50, spreadRadius: 8),
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 6)),
                          ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        logoAsset,
                        width: isDesktop ? 140 : 100,
                        height: isDesktop ? 140 : 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  appName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: fgColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    fontSize: isDesktop ? 40 : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepContainer extends StatelessWidget {
  const _StepContainer({
    required this.title,
    required this.subtitle,
    required this.child,
    this.isDesktop = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 640 : 480),
          child: Container(
            padding: isDesktop
                ? const EdgeInsets.symmetric(horizontal: 48, vertical: 40)
                : const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDesktop ? dtCardColor : (isDark ? AppColors.darkSurface.withValues(alpha: 0.85) : AppColors.lightSurface.withValues(alpha: 0.75)),
              borderRadius: BorderRadius.circular(isDesktop ? 32 : AppRadius.xl),
            border: Border.all(
              color: isDesktop ? dtBorderColor : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black87.withValues(alpha: 0.06)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white.withValues(alpha: 0.82) : Colors.black87.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 24),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = selected ? theme.colorScheme.onPrimary : (isDark ? Colors.white : Colors.black87);
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
          ],
          Text(label),
        ],
      ),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: fg,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.10),
      side: BorderSide(
        color: selected
            ? theme.colorScheme.primary
            : (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.12),
      ),
    );
  }
}
