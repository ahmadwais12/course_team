import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/screens/ads/ads_pages.dart';
import 'package:course_emis/screens/dashboard_screen.dart';
import 'package:course_emis/screens/payments_screen.dart';
import 'package:course_emis/screens/programs_screen.dart';
import 'package:course_emis/screens/students_screen.dart';
import 'package:course_emis/screens/messages_screen.dart';
import 'package:course_emis/screens/settings_screen.dart';

class NavPage {
  final Widget screen;
  final NavItem item;
  const NavPage({required this.screen, required this.item});
}

class MobileHome extends ConsumerStatefulWidget {
  final List<NavPage>? navPages;

  const MobileHome({super.key, this.navPages});

  @override
  ConsumerState<MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends ConsumerState<MobileHome>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late AnimationController _animController;
  bool _loading = true;
  List<NavPage> _navPages = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (widget.navPages != null) {
      _navPages = widget.navPages!;
      _loading = false;
      _animController.forward();
    } else {
      _loadNavigation();
    }
  }

  Future<void> _loadNavigation() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      String role = 'student';
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('users')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();
        if (profile != null && profile['role'] != null) {
          role = profile['role'] as String;
        }
      }

      final pages = _buildPagesForRole(role);
      if (mounted) {
        setState(() {
          _navPages = pages;
          _loading = false;
        });
        _animController.forward();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _navPages = _buildPagesForRole('student');
          _loading = false;
        });
        _animController.forward();
      }
    }
  }

  List<NavPage> _buildPagesForRole(String role) {
    final r = role.toLowerCase();
    if (r == 'super_admin' || r == 'admin') {
      return [
        NavPage(screen: const DashboardScreen(), item: NavItem(t(LNav.home, ref), Icons.home_rounded, Icons.home_outlined)),
        NavPage(screen: const StudentsScreen(), item: NavItem(t(LNav.students, ref), Icons.groups_rounded, Icons.groups_outlined)),
        NavPage(screen: const ProgramsScreen(), item: NavItem(t(LNav.programs, ref), Icons.menu_book_rounded, Icons.menu_book_outlined)),
        NavPage(screen: const PaymentsScreen(), item: NavItem(t(LNav.payments, ref), Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined)),
        NavPage(screen: const AdsHubScreen(), item: NavItem(t(LAds.campaigns, ref), Icons.campaign_rounded, Icons.campaign_outlined)),
      ];
    }
    if (r == 'teacher') {
      return [
        NavPage(screen: const DashboardScreen(), item: NavItem(t(LNav.home, ref), Icons.home_rounded, Icons.home_outlined)),
        NavPage(screen: const StudentsScreen(), item: NavItem(t(LNav.students, ref), Icons.groups_rounded, Icons.groups_outlined)),
        NavPage(screen: const MessagesScreen(), item: NavItem(t(LNav.messages, ref), Icons.message_rounded, Icons.message_outlined)),
        NavPage(screen: const PaymentsScreen(), item: NavItem(t(LNav.payments, ref), Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined)),
        NavPage(screen: const SettingsScreen(), item: NavItem(t(LNav.settings, ref), Icons.settings_rounded, Icons.settings_outlined)),
      ];
    }
    // student, parent, staff, default
    return [
      NavPage(screen: const DashboardScreen(), item: NavItem(t(LNav.home, ref), Icons.home_rounded, Icons.home_outlined)),
      NavPage(screen: const ProgramsScreen(), item: NavItem(t(LNav.programs, ref), Icons.menu_book_rounded, Icons.menu_book_outlined)),
      NavPage(screen: const PaymentsScreen(), item: NavItem(t(LNav.payments, ref), Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined)),
      NavPage(screen: const MessagesScreen(), item: NavItem(t(LNav.messages, ref), Icons.message_rounded, Icons.message_outlined)),
      NavPage(screen: const SettingsScreen(), item: NavItem(t(LNav.settings, ref), Icons.settings_rounded, Icons.settings_outlined)),
    ];
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTap(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _animController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final pages = _navPages.map((p) => p.screen).toList();
    final items = _navPages.map((p) => p.item).toList();

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: _CurvedNavBar(
        selectedIndex: _index,
        items: items,
        primary: primary,
        surface: surface,
        animController: _animController,
        onTap: _onTap,
      ),
    );
  }
}

// ─── Curved Nav Bar ──────────────────────────────────────────────────────────

class _CurvedNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<NavItem> items;
  final Color primary;
  final Color surface;
  final AnimationController animController;
  final ValueChanged<int> onTap;

  const _CurvedNavBar({
    required this.selectedIndex,
    required this.items,
    required this.primary,
    required this.surface,
    required this.animController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const barHeight = 72.0;
    const notchRadius = 30.0;
    final totalItems = items.length;
    final itemWidth =
        (MediaQuery.of(context).size.width) / totalItems;
    final notchCenterX = itemWidth * selectedIndex + itemWidth / 2;

    return SizedBox(
      height: barHeight + MediaQuery.of(context).padding.bottom,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Painted curved bar
          Positioned.fill(
            child: CustomPaint(
              painter: _CurvedBarPainter(
                notchCenterX: notchCenterX,
                notchRadius: notchRadius,
                color: surface,
                shadowColor: Colors.black.withValues(alpha: 0.12),
                borderColor:
                    theme.dividerColor.withValues(alpha: 0.6),
              ),
            ),
          ),
          // Nav items
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: barHeight,
            child: Row(
              children: List.generate(totalItems, (i) {
                final selected = i == selectedIndex;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: selected ? 0.0 : 1.0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          Icon(
                            items[i].icon,
                            size: 22,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            items[i].label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.55),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          // Floating active bubble
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            left: notchCenterX - notchRadius,
            top: -(notchRadius * 0.55),
            child: GestureDetector(
              onTap: () => onTap(selectedIndex),
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: animController,
                  curve: Curves.easeOutBack,
                ),
                child: Container(
                  width: notchRadius * 2,
                  height: notchRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primary,
                        Color.lerp(primary, Colors.purple, 0.4)!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[selectedIndex].selectedIcon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Active label below bubble
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: notchCenterX - 40,
            top: notchRadius + 10,
            child: SizedBox(
              width: 80,
              child: FadeTransition(
                opacity: animController,
                child: Text(
                  items[selectedIndex].label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CustomPainter for the curved notch bar ───────────────────────────────────

class _CurvedBarPainter extends CustomPainter {
  final double notchCenterX;
  final double notchRadius;
  final Color color;
  final Color shadowColor;
  final Color borderColor;

  _CurvedBarPainter({
    required this.notchCenterX,
    required this.notchRadius,
    required this.color,
    required this.shadowColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final path = _buildPath(size);

    // Shadow
    canvas.drawPath(path, shadowPaint);
    // Fill
    canvas.drawPath(path, paint);
    // Border
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  Path _buildPath(Size size) {
    const cornerRadius = 28.0;
    final notchDepth = notchRadius * 0.72;
    final curveWidth = notchRadius * 1.6;

    final path = Path();
    path.moveTo(cornerRadius, 0);

    // Top-left to notch start
    final notchLeft = notchCenterX - curveWidth;
    final notchRight = notchCenterX + curveWidth;

    path.lineTo(math.max(notchLeft, cornerRadius), 0);

    if (notchLeft > cornerRadius) {
      // Smooth curve down into notch
      path.cubicTo(
        notchCenterX - curveWidth * 0.55,
        0,
        notchCenterX - notchRadius * 0.9,
        notchDepth,
        notchCenterX,
        notchDepth,
      );
      path.cubicTo(
        notchCenterX + notchRadius * 0.9,
        notchDepth,
        notchCenterX + curveWidth * 0.55,
        0,
        notchRight,
        0,
      );
    }

    // Top-right to bottom-right corner
    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(_CurvedBarPainter old) =>
      old.notchCenterX != notchCenterX ||
      old.color != color ||
      old.borderColor != borderColor;
}

// ─── Nav Item model ───────────────────────────────────────────────────────────

class NavItem {
  final String label;
  final IconData selectedIcon;
  final IconData icon;

  const NavItem(this.label, this.selectedIcon, this.icon);
}
