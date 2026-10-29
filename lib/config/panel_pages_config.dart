import '../config/page_registry.dart';
import 'all_page_definitions.dart';

/// Panel-specific page configuration for bottom navigation "More" menu
/// Each panel/role gets its own unique set of pages combining:
/// - Static pages (existing dedicated screens)
/// - Dynamic pages (generic CRUD screens from AllPageDefinitions)
class PanelPagesConfig {
  /// Safely get a page by ID, returning null if not found
  static PageRegistry? _getPageOrNull(String id) {
    try {
      return AppPageRegistry.getPageById(id);
    } catch (_) {
      return null;
    }
  }

  /// Get a page list from IDs, filtering out nulls
  static List<PageRegistry> _getPages(List<String> ids) {
    return ids
        .map((id) => _getPageOrNull(id))
        .where((p) => p != null)
        .cast<PageRegistry>()
        .toList();
  }

  /// Get all dynamic page IDs for a role
  static List<PageRegistry> _getDynamicPagesForRole(String role) {
    return AllPageDefinitions.getPagesForRole(role)
        .map((def) => _getPageOrNull(def.id))
        .where((p) => p != null)
        .cast<PageRegistry>()
        .toList();
  }

  /// Get pages for a specific panel/role
  static List<PageRegistry> getPagesForPanel(String role) {
    switch (role) {
      case 'super_admin':
        return _getSuperAdminPages();
      case 'admin':
        return _getAdminPages();
      case 'teacher':
        return _getTeacherPages();
      case 'academic_support':
        return _getAcademicSupportPages();
      case 'accountant':
        return _getAccountantPages();
      case 'librarian':
        return _getLibrarianPages();
      case 'receptionist':
        return _getReceptionistPages();
      case 'hr_manager':
        return _getHRPages();
      case 'inventory_manager':
        return _getInventoryPages();
      case 'it_support':
        return _getITSupportPages();
      case 'maintenance':
        return _getMaintenancePages();
      case 'event_manager':
        return _getEventManagerPages();
      case 'complaint_manager':
        return _getComplaintManagerPages();
      case 'student':
        return _getStudentPages();
      case 'guardian':
        return _getGuardianPages();
      case 'staff':
        return _getStaffPages();
      default:
        return _getDefaultPages();
    }
  }

  /// Merge static + dynamic pages, removing repeated entries.
  /// Dedup rules (static pages take priority):
  /// - same page id
  /// - same page name (case-insensitive)
  static List<PageRegistry> _combine(
      List<PageRegistry> staticPages, List<PageRegistry> dynamicPages) {
    final result = <PageRegistry>[];
    final seenIds = <String>{};
    final seenNames = <String>{};
    for (final page in [...staticPages, ...dynamicPages]) {
      if (!seenIds.add(page.id)) continue;
      final nameKey = page.name.trim().toLowerCase();
      if (seenNames.contains(nameKey)) continue;
      seenNames.add(nameKey);
      result.add(page);
    }
    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  SUPER ADMIN — 21 static + 35 dynamic = ~56 pages
  // ─────────────────────────────────────────────────────────────────────────
  static List<PageRegistry> _getSuperAdminPages() {
    final staticPages = _getPages([
      'tenant_management', 'backup_restore', 'user_creation',
      'multi_language', 'system_logs', 'api_integrations', 'record_history',
      'platform_management', 'profile_management', 'chart_of_accounts',
      'promotions', 'audit_log', 'address_management', 'fee_type_templates',
      'notification_compose', 'analytics_panel', 'compliance_panel',
      'reports', 'settings', 'profile', 'branch_info',
    ]);
    return _combine(staticPages, _getDynamicPagesForRole('super_admin'));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ADMIN — 19 static + 63 dynamic = ~82 pages
  // ─────────────────────────────────────────────────────────────────────────
  static List<PageRegistry> _getAdminPages() {
    final staticPages = _getPages([
      'students', 'teachers', 'classes', 'departments', 'programs',
      'academic_year', 'admissions', 'staff_directory', 'fee_management',
      'notification_compose', 'analytics_panel', 'compliance_panel',
      'dispatch_panel', 'operations_panel', 'command_center',
      'announcement_management', 'reports', 'settings', 'profile',
      'branch_info_admin',
    ]);
    final dynamicAdminPages = _getDynamicPagesForRole('admin');
    return _combine(staticPages, dynamicAdminPages);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  TEACHER — 10 static + 5 dynamic = ~15 pages
  // ─────────────────────────────────────────────────────────────────────────
  static List<PageRegistry> _getTeacherPages() {
    final staticPages = _getPages([
      'teacher_lessons', 'teacher_homework', 'teacher_progress', 'teacher_exams',
      'teacher_groups', 'teacher_messages', 'attendance', 'my_schedule',
      'notification_compose', 'profile',
    ]);
    return _combine(staticPages, _getDynamicPagesForRole('teacher'));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ACADEMIC SUPPORT — 19 static + 3 dynamic = ~22 pages
  // ─────────────────────────────────────────────────────────────────────────
  static List<PageRegistry> _getAcademicSupportPages() {
    final staticPages = _getPages([
      'admissions', 'students', 'student_profile', 'classes', 'programs',
      'attendance', 'attendance_tracking', 'placement_tests',
      'academic_progress', 'course_material_management',
      'report_cards_generation', 'grades', 'exams', 'books', 'feedback',
      'english_test', 'notification_compose', 'reports', 'profile',
    ]);
    return _combine(staticPages, _getDynamicPagesForRole('academic_support'));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ACCOUNTANT — 19 static + 11 dynamic = ~30 pages
  // ─────────────────────────────────────────────────────────────────────────
  static List<PageRegistry> _getAccountantPages() {
    final staticPages = _getPages([
      'invoices', 'payments', 'payment_management', 'invoice_management',
      'payment_history', 'fee_management', 'payroll', 'discounts',
      'salary_management', 'expenses_tracking', 'financial_reports',
      'budget_management', 'accountant_expenses', 'accountant_salaries',
      'accountant_budget', 'accountant_taxation', 'notification_compose',
      'fee_types', 'fee_structures', 'fee_assignments', 'fee_statement',
      'reports', 'profile',
    ]);
    return _combine(staticPages, _getDynamicPagesForRole('accountant'));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  LIBRARIAN — 11 static + 6 dynamic = ~17 pages
  // ─────────────────────────────────────────────────────────────────────────
  static List<PageRegistry> _getLibrarianPages() {
    final staticPages = _getPages([
      'digital_library', 'issue_book', 'return_book', 'catalog', 'members',
      'librarian_memberships', 'librarian_reservations', 'fine_management',
      'books', 'library', 'profile',
    ]);
    return _combine(staticPages, _getDynamicPagesForRole('librarian'));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  RECEPTIONIST — 6 static + 2 dynamic = ~8 pages
  // ─────────────────────────────────────────────────────────────────────────
  static List<PageRegistry> _getReceptionistPages() {
    final staticPages = _getPages([
      'admissions', 'events', 'leads', 'attendance', 'calendar', 'profile',
    ]);
    return _combine(staticPages, _getDynamicPagesForRole('receptionist'));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  HR MANAGER — 24 static + 11 dynamic = ~35 pages
  // ─────────────────────────────────────────────────────────────────────────
  static List<PageRegistry> _getHRPages() {
    final staticPages = _getPages([
      'recruitment', 'staff_registration', 'hr_onboarding', 'staff_directory',
      'hr_compliance', 'contract_management', 'hr_contracts', 'exit_management',
      'benefits', 'shift_management', 'my_schedule', 'performance_evaluation',
      'hr_performance', 'hr_training', 'payroll', 'leave_management',
      'attendance', 'hr_staff_attendance', 'tasks', 'teachers', 'notice_board',
      'reports', 'notification_compose', 'profile',
    ]);
    return _combine(staticPages, _getDynamicPagesForRole('hr_manager'));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  INVENTORY MANAGER — 9 static + 4 dynamic = ~13 pages
  // ─────────────────────────────────────────────────────────────────────────
  static List<PageRegistry> _getInventoryPages() {
    final staticPages = _getPages([
      'stock_management', 'stock_check', 'requisitions', 'inventory_categories',
      'purchase_orders', 'inventory_reports', 'suppliers', 'assets', 'profile',
    ]);
    return _combine(staticPages, _getDynamicPagesForRole('inventory_manager'));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  IT SUPPORT — 11 static + 5 dynamic = ~16 pages
  // ─────────────────────────────────────────────────────────────────────────
  static List<PageRegistry> _getITSupportPages() {
    final staticPages = _getPages([
      'tickets', 'devices', 'bug_reports', 'network_status', 'system_updates',
      'user_management', 'role_permission_management', 'database_backup_restore',
      'security_audit', 'software_licenses', 'profile',
    ]);
    return _combine(staticPages, _getDynamicPagesForRole('it_support'));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  MAINTENANCE — 7 static + 3 dynamic = ~10 pages
  // ─────────────────────────────────────────────────────────────────────────
  static List<PageRegistry> _getMaintenancePages() {
    final staticPages = _getPages([
      'service_requests', 'repair_log', 'equipment', 'maintenance_schedule',
      'vendors', 'asset_registry', 'profile',
    ]);
    return _combine(staticPages, _getDynamicPagesForRole('maintenance'));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  EVENT MANAGER — 7 static + 1 dynamic = ~8 pages
  // ─────────────────────────────────────────────────────────────────────────
  static List<PageRegistry> _getEventManagerPages() {
    final staticPages = _getPages([
      'events', 'calendar', 'attendees', 'venues', 'ticketing', 'sponsorship',
      'profile',
    ]);
    return _combine(staticPages, _getDynamicPagesForRole('event_manager'));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  COMPLAINT MANAGER — 7 static + 1 dynamic = ~8 pages
  // ─────────────────────────────────────────────────────────────────────────
  static List<PageRegistry> _getComplaintManagerPages() {
    final staticPages = _getPages([
      'complaints', 'pending_review', 'complainants', 'resolved_cases',
      'complaint_feedback', 'analytics_panel', 'feedback', 'reports', 'profile',
    ]);
    return _combine(staticPages, _getDynamicPagesForRole('complaint_manager'));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  STAFF (General) — 6 static + 4 dynamic = ~10 pages
  // ─────────────────────────────────────────────────────────────────────────
  static List<PageRegistry> _getStaffPages() {
    final staticPages = _getPages([
      'attendance', 'my_schedule', 'leave_management', 'tasks',
      'home_page_management', 'profile',
    ]);
    return _combine(staticPages, _getDynamicPagesForRole('staff'));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  STUDENT — default + 5 dynamic = ~7 pages
  // ─────────────────────────────────────────────────────────────────────────
  static List<PageRegistry> _getStudentPages() {
    return _combine(
      _getDefaultPages(),
      _getDynamicPagesForRole('student'),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  GUARDIAN — default + 2 dynamic = ~4 pages
  // ─────────────────────────────────────────────────────────────────────────
  static List<PageRegistry> _getGuardianPages() {
    return _combine(
      _getDefaultPages(),
      _getDynamicPagesForRole('guardian'),
    );
  }

  /// Default Pages (Fallback)
  static List<PageRegistry> _getDefaultPages() {
    return _getPages([
      'profile', 'settings', 'help_support', 'about_emis',
    ]);
  }

  /// Get common pages for all panels
  static List<PageRegistry> getCommonPages() {
    return _getPages([
      'profile', 'settings', 'chat', 'help_support', 'about_emis',
    ]);
  }
}
