import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/screens/more_screen.dart';

({Widget icon, Widget? selectedIcon, String label}) _navDest(
    IconData icon, IconData selectedIcon, String label) {
  return (
    icon: Icon(icon),
    selectedIcon: Icon(selectedIcon),
    label: label,
  );
}

/// Returns 4 role-specific nav items for the bottom navigation bar.
List<({Widget icon, Widget? selectedIcon, String label})> getRoleNavItems(
    String role,
    [String locale = 'en']) {
  String t(String key) => AppLocalizations.translate(key, locale);
  final dashboard = _navDest(
      Icons.dashboard_outlined, Icons.dashboard_rounded, t(LNav.dashboard));

    switch (role) {

      case 'super_admin':
        return [
          dashboard,
          _navDest(Icons.chat_bubble_outline, Icons.chat_bubble_rounded,
              t(LNav.messages)),
          _navDest(Icons.manage_accounts_outlined, Icons.manage_accounts_rounded,
              t(LModule.users)),
          _navDest(Icons.notifications_outlined, Icons.notifications_rounded,
              t(LNav.notifications)),
        ];
    case 'admin':
      return [
        dashboard,
        _navDest(Icons.people_outlined, Icons.people_rounded, t(LNav.teachers)),
        _navDest(Icons.school_outlined, Icons.school_rounded, t(LNav.students)),
        _navDest(
            Icons.payments_outlined, Icons.payments_rounded, t(LNav.payments)),
      ];
    case 'teacher':
      return [
        dashboard,
        _navDest(Icons.how_to_reg_outlined, Icons.how_to_reg_rounded,
            t(LNav.attendance)),
        _navDest(Icons.grade_outlined, Icons.grade_rounded, t(LNav.grades)),
        _navDest(Icons.calendar_today_outlined, Icons.calendar_today_rounded,
            t(LNav.timetable)),
      ];
    case 'accountant':
      return [
        dashboard,
        _navDest(Icons.payments_outlined, Icons.payments_rounded,
            t(LPayment.receipt)),
        _navDest(Icons.account_balance_wallet_outlined,
            Icons.account_balance_wallet_rounded, t(LPanelUI.salaries)),
        _navDest(Icons.description_outlined, Icons.description_rounded,
            t(LModule.invoices)),
      ];
    case 'librarian':
      return [
        dashboard,
        _navDest(Icons.book_outlined, Icons.book_rounded, t(LNav.books)),
        _navDest(Icons.bookmark_border, Icons.bookmark, t(LModule.issueBook)),
        _navDest(Icons.group_outlined, Icons.group_rounded, t(LModule.members)),
      ];
    case 'receptionist':
      return [
        dashboard,
        _navDest(Icons.person_add_outlined, Icons.person_add_rounded,
            t(LModule.admissions)),
        _navDest(Icons.contact_mail_outlined, Icons.contact_mail_rounded,
            t(LModule.leads)),
        _navDest(Icons.calendar_month_outlined, Icons.calendar_month_rounded,
            t(LModule.events)),
      ];
    case 'hr_manager':
      return [
        dashboard,
        _navDest(Icons.people_outlined, Icons.people_rounded,
            t(LPanelUI.totalStaff)),
        _navDest(
            Icons.payments_outlined, Icons.payments_rounded, t(LNav.payroll)),
        _navDest(Icons.time_to_leave_outlined, Icons.time_to_leave_rounded,
            t(LModule.leaveManagement)),
      ];
    case 'inventory_manager':
      return [
        dashboard,
        _navDest(Icons.inventory_2_outlined, Icons.inventory_2_rounded,
            t(LModule.stock)),
        _navDest(Icons.shopping_cart_outlined, Icons.shopping_cart_rounded,
            t(LModule.purchaseOrders)),
        _navDest(Icons.local_shipping_outlined, Icons.local_shipping_rounded,
            t(LModule.suppliers)),
      ];
    case 'it_support':
      return [
        dashboard,
        _navDest(Icons.confirmation_number_outlined,
            Icons.confirmation_number_rounded, t(LModule.tickets)),
        _navDest(Icons.computer_outlined, Icons.computer_rounded,
            t(LModule.devices)),
        _navDest(Icons.network_check_outlined, Icons.network_check_rounded,
            t(LModule.networkStatus)),
      ];
    case 'maintenance':
      return [
        dashboard,
        _navDest(Icons.build_outlined, Icons.build_rounded,
            t(LModule.serviceRequests)),
        _navDest(Icons.handyman_outlined, Icons.handyman_rounded,
            t(LModule.equipment)),
        _navDest(Icons.local_shipping_outlined, Icons.local_shipping_rounded,
            t(LModule.vendors)),
      ];
    case 'event_manager':
      return [
        dashboard,
        _navDest(Icons.event_outlined, Icons.event_rounded, t(LModule.events)),
        _navDest(Icons.calendar_month_outlined, Icons.calendar_month_rounded,
            t(LModule.calendar)),
        _navDest(Icons.group_outlined, Icons.group_rounded, t(LModule.attendees)),
      ];
    case 'complaint_manager':
      return [
        dashboard,
        _navDest(Icons.report_outlined, Icons.report_rounded,
            t(LModule.complaints)),
        _navDest(Icons.check_circle_outline, Icons.check_circle_rounded,
            t(LModule.resolvedCases)),
        _navDest(Icons.feedback_outlined, Icons.feedback_rounded,
            t(LModule.feedbackManagement)),
      ];
    case 'academic_support':
      return [
        dashboard,
        _navDest(Icons.school_outlined, Icons.school_rounded, t(LNav.students)),
        _navDest(Icons.how_to_reg_outlined, Icons.how_to_reg_rounded,
            t(LNav.attendance)),
        _navDest(Icons.assignment_outlined, Icons.assignment_rounded,
            t(LPanelUI.placementTests)),
      ];
    case 'staff':
      return [
        dashboard,
        _navDest(Icons.how_to_reg_outlined, Icons.how_to_reg_rounded,
            t(LNav.attendance)),
        _navDest(Icons.schedule_outlined, Icons.schedule_rounded,
            t(LModule.mySchedule)),
        _navDest(Icons.task_outlined, Icons.task_alt, t(LModule.tasks)),
      ];
    default:
      return [
        dashboard,
        _navDest(Icons.chat_bubble_outline, Icons.chat_bubble_rounded,
            t(LNav.messages)),
        _navDest(Icons.manage_accounts_outlined, Icons.manage_accounts_rounded,
            t(LModule.users)),
        _navDest(Icons.notifications_outlined, Icons.notifications_rounded,
            t(LNav.notifications)),
      ];
  }
}

/// Navigates to the full-page More screen with all role-specific pages.
void showCurvedMoreSheet(BuildContext context, WidgetRef ref, String role) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const MoreScreen(),
      fullscreenDialog: true,
    ),
  );
}

class CurvedBottomNav extends StatelessWidget {
  final List<CurvedBottomNavItem> items;
  final Function(int) onTap;
  final int currentIndex;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double height;

  const CurvedBottomNav({
    super.key,
    required this.items,
    required this.onTap,
    required this.currentIndex,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.height = 70,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.surface;
    final selected = selectedColor ?? theme.colorScheme.primary;
    final unselected =
        unselectedColor ?? theme.colorScheme.outline.withValues(alpha: 0.5);
    final hasCenterButton = items.length.isOdd;

    return CustomPaint(
      painter: CurvedNavPainter(
        color: bg,
        showCenterCutout: hasCenterButton,
      ),
      child: SizedBox(
        height: hasCenterButton ? height + 10 : height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Navigation items
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(
                  top: hasCenterButton ? 0 : 8,
                  bottom: hasCenterButton ? 20 : 8,
                ),
                child: Row(
                  children: items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = index == currentIndex;
                    final isCenter =
                        hasCenterButton && index == items.length ~/ 2;

                    return Expanded(
                      child: InkWell(
                        onTap: () => onTap(index),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: Icon(
                                isSelected ? item.selectedIcon : item.icon,
                                color: isCenter
                                    ? Colors.white
                                    : (isSelected ? selected : unselected),
                                size: isCenter ? 28 : (isSelected ? 26 : 22),
                              ),
                            ),
                            if (!isCenter) ...[
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    color: isSelected ? selected : unselected,
                                    fontSize: isSelected ? 12 : 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Center floating button
            if (hasCenterButton)
              Positioned(
                top: 0,
                child: InkWell(
                  onTap: () => onTap(items.length ~/ 2),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          selected,
                          selected.withValues(alpha: 0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selected.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      items[items.length ~/ 2].selectedIcon,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CurvedBottomNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const CurvedBottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Builds a curved bottom navigation bar with role-based items + "More".
/// Used by both [BasePanelLayout] and standalone panel screens.
Widget buildCurvedBottomNavBar({
  required BuildContext context,
  required int currentIndex,
  required List<({Widget icon, Widget? selectedIcon, String label})> items,
  required ValueChanged<int> onItemTap,
  VoidCallback? onMoreTap,
  String locale = 'en',
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final selectedColor = isDark ? theme.colorScheme.primary : theme.colorScheme.primary;
  final unselectedColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
  final allItems = [
    ...items,
    (
      icon: const Icon(Icons.more_horiz_rounded),
      selectedIcon: const Icon(Icons.more_horiz_rounded),
      label: AppLocalizations.translate(LUX.more, locale),
    ),
  ];

  return Container(
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, -5),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex < items.length ? currentIndex : 0,
        onTap: (i) {
          if (i < allItems.length - 1) {
            onItemTap(i);
          } else if (onMoreTap != null) {
            onMoreTap();
          }
        },
        items: allItems
            .map((dest) => BottomNavigationBarItem(
                  icon: dest.icon,
                  activeIcon: dest.selectedIcon ?? dest.icon,
                  label: dest.label,
                ))
            .toList(),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 0,
      ),
    ),
  );
}

class CurvedNavPainter extends CustomPainter {
  final Color color;
  final bool showCenterCutout;

  CurvedNavPainter({
    required this.color,
    this.showCenterCutout = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (!showCenterCutout) {
      // Simple rectangle without cutout
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    final path = Path();
    final centerX = size.width / 2;
    final curveWidth = 80.0;
    final curveDepth = 35.0;
    final top = 0.0;

    path.moveTo(0, top);
    path.lineTo(centerX - curveWidth, top);

    // Left curve
    path.quadraticBezierTo(
      centerX - curveWidth / 2,
      curveDepth,
      centerX,
      curveDepth,
    );

    // Right curve
    path.quadraticBezierTo(
      centerX + curveWidth / 2,
      curveDepth,
      centerX + curveWidth,
      top,
    );

    path.lineTo(size.width, top);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
