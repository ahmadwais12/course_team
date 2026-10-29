import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:course_emis/core/responsive/responsive.dart';
import 'package:course_emis/providers/tenant_provider.dart';
import 'package:course_emis/providers/navigation_provider.dart';
import 'package:course_emis/providers/auth_provider.dart';
import 'package:course_emis/providers/impersonation_provider.dart';
import 'package:course_emis/widgets/curved_bottom_nav.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';

// Module Screen Imports
import 'package:course_emis/screens/students_screen.dart';
import 'package:course_emis/screens/teachers_screen.dart';
import 'package:course_emis/screens/attendance_screen.dart';
import 'package:course_emis/screens/payments_screen.dart';
import 'package:course_emis/screens/grades_screen.dart';
import 'package:course_emis/screens/classes_screen.dart';
import 'package:course_emis/screens/payroll_screen.dart';
import 'package:course_emis/screens/books_screen.dart';
import 'package:course_emis/screens/users_screen.dart';
import 'package:course_emis/screens/messages_screen.dart';
import 'package:course_emis/screens/notifications_screen.dart';
import 'package:course_emis/screens/calendar_screen.dart';
import 'package:course_emis/screens/feedback_screen.dart';
import 'package:course_emis/screens/my_schedule_screen.dart';
import 'package:course_emis/screens/leave_management_screen.dart';
import 'package:course_emis/screens/academic_support/placement_tests_screen.dart';
import 'package:course_emis/screens/librarian/members_screen.dart';
import 'package:course_emis/screens/receptionist/leads_screen.dart';
import 'package:course_emis/screens/skeleton/it_support/it_devices_screen.dart';
import 'package:course_emis/screens/skeleton/it_support/it_network_status_screen.dart';
import 'package:course_emis/screens/skeleton/inventory/iv_purchase_orders_screen.dart';
import 'package:course_emis/screens/skeleton/inventory/iv_suppliers_screen.dart';
import 'package:course_emis/screens/skeleton/maintenance/mt_equipment_screen.dart';
import 'package:course_emis/screens/skeleton/maintenance/mt_vendors_screen.dart';
import 'package:course_emis/screens/skeleton/event_manager/em_attendees_screen.dart';
import 'package:course_emis/screens/skeleton/complaint_manager/cm_resolved_cases_screen.dart';
import 'package:course_emis/screens/skeleton/hr/hr_staff_tasks_screen.dart';

// Staff Module Imports
import 'package:course_emis/screens/staff_academic_support_screen.dart';
import 'package:course_emis/screens/staff_accountant_screen.dart';
import 'package:course_emis/screens/staff_librarian_screen.dart';
import 'package:course_emis/screens/staff_frontdesk_screen.dart';
import 'package:course_emis/screens/staff_hr_screen.dart';
import 'package:course_emis/screens/staff_it_support_screen.dart';
import 'package:course_emis/screens/staff_event_coordinator_screen.dart';
import 'package:course_emis/screens/staff_inventory_manager_screen.dart';
import 'package:course_emis/screens/staff_maintenance_screen.dart';
import 'package:course_emis/screens/staff_complaint_manager_screen.dart';
import 'package:course_emis/widgets/adaptive/adaptive_widgets.dart';
import 'package:course_emis/app_routes_all.dart';

class BasePanelLayout extends ConsumerWidget {
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final List<BottomNavigationBarItem>? customBottomNavItems;
  final Function(int)? onBottomNavTap;
  final bool isLoading;
  final PreferredSizeWidget? customAppBar;

  const BasePanelLayout({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.floatingActionButton,
    this.customBottomNavItems,
    this.onBottomNavTap,
    this.isLoading = false,
    this.customAppBar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentTenant = ref.watch(currentTenantProvider);
    final navIndex = ref.watch(navigationIndexProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final role = resolveEffectiveRole(ref);
    final locale = ref.watch(localeProvider);
    final isDesktop = context.isDesktop;

    final avatarAsync = ref.watch(currentUserAvatarUrlProvider);
    final metaAvatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final avatarUrl = avatarAsync.valueOrNull ?? metaAvatarUrl;
    final tenantLogoUrl = currentTenant?.logoUrl;

    final logoSize = context.isMobile ? 72.0 : (context.isTablet ? 88.0 : 96.0);

    final defaultAppBar = AppBar(
      leading: context.canPop()
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            )
          : Padding(
              padding: const EdgeInsets.all(6.0),
              child: SizedBox(
                width: logoSize,
                height: logoSize,
                child: tenantLogoUrl != null && tenantLogoUrl.isNotEmpty
                    ? Image.network(
                        tenantLogoUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/logo/dreamflow-icon-black.png',
                          fit: BoxFit.contain,
                        ),
                      )
                    : Image.asset(
                        'assets/logo/dreamflow-icon-black.png',
                        fit: BoxFit.contain,
                      ),
              ),
            ),
      title: const SizedBox.shrink(),
      actions: [
        if (!PlatformAdaptive.showFab && floatingActionButton is FloatingActionButton)
          IconButton(
            tooltip: 'Add',
            icon: const Icon(Icons.add),
            onPressed: () {
              PlatformAdaptive.lightHaptic();
              (floatingActionButton as FloatingActionButton).onPressed?.call();
            },
          ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => showCurvedMoreSheet(context, ref, role),
            child: SizedBox(
              width: 32, height: 32,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[200],
                    child: Icon(Icons.person, color: Colors.grey[500], size: 18),
                  ),
                  if (avatarUrl != null && avatarUrl.isNotEmpty)
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: avatarUrl,
                        width: 32, height: 32,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const SizedBox(),
                        errorWidget: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (actions != null) ...actions!,
      ],
    );

    return Scaffold(
      appBar: customAppBar ?? (!isDesktop ? defaultAppBar : null),
      bottomNavigationBar: _buildBottomNav(context, ref, role, locale),
      floatingActionButton:
          PlatformAdaptive.showFab ? floatingActionButton : null,
      body: LayoutSwitcher(
        mobileLayout: _buildMobileBody(context, ref, role, navIndex, locale),
        desktopLayout: _buildDesktopBody(context, ref, theme, role, navIndex, locale, currentTenant),
      ),
    );
  }

  Widget _buildMobileBody(BuildContext context, WidgetRef ref, String role, int navIndex, String locale) {
    final padding = context.isMobile ? 12.0 : (context.isTablet ? 20.0 : 24.0);
    return isLoading
        ? const Center(child: AdaptiveProgress())
        : navIndex == 0
            ? ListView(
                physics: PlatformAdaptive.scrollPhysics(),
                padding: EdgeInsets.all(padding),
                children: children,
              )
            : _buildNavContent(context, role, navIndex, locale);
  }

  Widget _buildDesktopBody(BuildContext context, WidgetRef ref, ThemeData theme, String role, int navIndex, String locale, dynamic currentTenant) {
    final roleItems = getRoleNavItems(role, locale);
    final user = Supabase.instance.client.auth.currentUser;
    final avatarAsync = ref.watch(currentUserAvatarUrlProvider);
    final metaAvatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final avatarUrl = avatarAsync.valueOrNull ?? metaAvatarUrl;
    final tenantLogoUrl = currentTenant?.logoUrl as String?;

    final drawerLogoSize = context.isDesktop ? 100.0 : 112.0;

    return Row(
      children: [
        Container(
          width: 260,
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: drawerLogoSize,
                            height: drawerLogoSize,
                            child: tenantLogoUrl != null && tenantLogoUrl.isNotEmpty
                                ? Image.network(
                                    tenantLogoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      'assets/logo/dreamflow-icon-black.png',
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/logo/dreamflow-icon-black.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentTenant?.name ?? 'EMIS',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                role.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => showCurvedMoreSheet(context, ref, role),
                          child: SizedBox(
                            width: 32, height: 32,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  child: const Icon(Icons.person,
                                      color: Colors.white70, size: 18),
                                ),
                                if (avatarUrl != null && avatarUrl.isNotEmpty)
                                  ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: avatarUrl,
                                      width: 32, height: 32,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const SizedBox(),
                                      errorWidget: (_, __, ___) => const SizedBox(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    ...List.generate(
                      roleItems.length,
                      (index) {
                        final item = roleItems[index];
                        final selected = navIndex == index;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: ListTile(
                            dense: true,
                            leading: selected && item.selectedIcon != null
                                ? item.selectedIcon!
                                : item.icon,
                            title: Text(
                              item.label,
                              style: TextStyle(
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                              ),
                            ),
                            selected: selected,
                            selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            onTap: () {
                              ref.read(navigationIndexProvider.notifier).state = index;
                              if (onBottomNavTap != null) onBottomNavTap!(index);
                            },
                          ),
                        );
                      },
                    ),
                    if (role == 'super_admin') ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          'MODULES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ..._buildSuperAdminModuleItems(context, theme),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton.outlined(
                      icon: const Icon(Icons.notifications_outlined, size: 20),
                      onPressed: () => context.go('/notifications'),
                      tooltip: t(LNav.notifications, ref),
                    ),
                    IconButton.outlined(
                      icon: const Icon(Icons.more_horiz_rounded, size: 20),
                      onPressed: () => showCurvedMoreSheet(context, ref, role),
                      tooltip: t(LUX.more, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : navIndex == 0
                      ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: children,
                        )
                      : _buildNavContent(context, role, navIndex, locale),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(
      BuildContext context, WidgetRef ref, String role, String locale) {
    final navIndex = ref.watch(navigationIndexProvider);
    final roleItems = getRoleNavItems(role, locale);

    return buildCurvedBottomNavBar(
      context: context,
      currentIndex: navIndex,
      items: roleItems,
      onItemTap: (i) {
        ref.read(navigationIndexProvider.notifier).state = i;
        if (onBottomNavTap != null) onBottomNavTap!(i);
      },
      onMoreTap: () => showCurvedMoreSheet(context, ref, role),
      locale: locale,
    );
  }



  Widget _buildNavContent(
      BuildContext context, String role, int index, String locale) {
    switch (role) {

      case 'super_admin':
        if (index == 1) return const MessagesScreen();
        if (index == 2) return const UsersScreen();
        if (index == 3) return const NotificationsScreen();
        break;
      case 'admin':
        if (index == 1) return const TeachersScreen();
        if (index == 2) return const StudentsScreen();
        if (index == 3) return const PaymentsScreen();
        break;
      case 'teacher':
        if (index == 1) return const AttendanceScreen();
        if (index == 2) return const GradesScreen();
        if (index == 3) return const ClassesScreen();
        break;
      case 'accountant':
        if (index == 1) return const StaffAccountantScreen();
        if (index == 2) return const PayrollScreen();
        if (index == 3) return const PaymentsScreen();
        break;
      case 'librarian':
        if (index == 1) return const StaffLibrarianScreen();
        if (index == 2) return const BooksScreen();
        if (index == 3) return const MembersScreen();
        break;
      case 'receptionist':
        if (index == 1) return const StaffFrontDeskScreen();
        if (index == 2) return const LeadsScreen();
        if (index == 3) return const StaffEventCoordinatorScreen();
        break;
      case 'hr_manager':
        if (index == 1) return const StaffHRScreen();
        if (index == 2) return const PayrollScreen();
        if (index == 3) return const LeaveManagementScreen();
        break;
      case 'staff_finance':
        if (index == 1) return const StaffAccountantScreen();
        break;
      case 'staff_academic':
        if (index == 1) return const StaffAcademicSupportScreen();
        break;
      case 'staff_hr':
        if (index == 1) return const StaffHRScreen();
        break;
      case 'staff_it':
        if (index == 1) return const StaffITSupportScreen();
        break;
      case 'staff_comm':
        if (index == 1) return const StaffEventCoordinatorScreen();
        break;
      case 'inventory_manager':
        if (index == 1) return const StaffInventoryManagerScreen();
        if (index == 2) return const IvPurchaseOrdersScreen();
        if (index == 3) return const IvSuppliersScreen();
        break;
      case 'it_support':
        if (index == 1) return const StaffITSupportScreen();
        if (index == 2) return const ItDevicesScreen();
        if (index == 3) return const ItNetworkStatusScreen();
        break;
      case 'maintenance':
        if (index == 1) return const StaffMaintenanceScreen();
        if (index == 2) return const MtEquipmentScreen();
        if (index == 3) return const MtVendorsScreen();
        break;
      case 'event_manager':
        if (index == 1) return const StaffEventCoordinatorScreen();
        if (index == 2) return const CalendarScreen();
        if (index == 3) return const EmAttendeesScreen();
        break;
      case 'complaint_manager':
        if (index == 1) return const StaffComplaintManagerScreen();
        if (index == 2) return const CmResolvedCasesScreen();
        if (index == 3) return const FeedbackScreen();
        break;
      case 'academic_support':
        if (index == 1) return const StaffAcademicSupportScreen();
        if (index == 2) return const AttendanceScreen();
        if (index == 3) return const PlacementTestsScreen();
        break;
      case 'staff':
        if (index == 1) return const AttendanceScreen();
        if (index == 2) return const MyScheduleScreen();
        if (index == 3) return const HrStaffTasksScreen();
        break;
      default:
        if (index == 1) return const MessagesScreen();
        if (index == 2) return const UsersScreen();
        if (index == 3) return const NotificationsScreen();
        break;
    }
    return _buildComingSoon(locale);
  }

  List<Widget> _buildSuperAdminModuleItems(BuildContext context, ThemeData theme) {
    final modules = <(String, IconData, Color, String)>[
      ('Tenant Management', Icons.admin_panel_settings_rounded, Colors.purple, AppRoutesAll.tenants),
      ('System Settings', Icons.settings_rounded, Colors.grey, AppRoutesAll.systemSettings),
      ('Backup & Restore', Icons.backup_rounded, Colors.teal, AppRoutesAll.backupRestore),
      ('System Logs', Icons.article_rounded, Colors.orange, AppRoutesAll.systemLogs),
      ('API Integrations', Icons.api_rounded, Colors.indigo, AppRoutesAll.apiIntegrations),
      ('Create User', Icons.person_add_alt_1, Colors.blue, AppRoutesAll.userCreation),
      ('Multi-language', Icons.language_rounded, Colors.cyan, AppRoutesAll.multiLanguage),
      ('Record History', Icons.history_rounded, Colors.brown, AppRoutesAll.recordHistory),
      ('Platforms', Icons.devices_rounded, Colors.indigo, AppRoutesAll.platforms),
      ('Profile Management', Icons.manage_accounts_rounded, Colors.blue, AppRoutesAll.profiles),
      ('Chart of Accounts', Icons.account_tree_rounded, Colors.orange, AppRoutesAll.chartOfAccounts),
      ('Promotions', Icons.local_offer_rounded, Colors.pink, AppRoutesAll.promotions),
      ('Audit Log', Icons.shield_rounded, Colors.red, AppRoutesAll.auditLog),
      ('Addresses', Icons.location_on_rounded, Colors.green, AppRoutesAll.addresses),
      ('Fee Templates', Icons.receipt_rounded, Colors.teal, AppRoutesAll.feeTypeTemplates),
    ];

    return modules.map((m) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        child: ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: m.$3.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(m.$2, color: m.$3, size: 18),
          ),
          title: Text(
            m.$1,
            style: const TextStyle(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onTap: () => context.go(m.$4),
        ),
      );
    }).toList();
  }

  Widget _buildComingSoon(String locale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(AppLocalizations.translate(LUX.featureComingSoon, locale),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(AppLocalizations.translate(LUX.underDevelopment, locale)),
        ],
      ),
    );
  }
}
