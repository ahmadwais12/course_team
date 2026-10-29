import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/otp_verification_screen.dart';
import '../screens/two_factor_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/change_password_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/notification_compose_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/chat_screen.dart';
// import '../screens/chat_conversation_screen.dart'; // Requires chatId parameter
import '../screens/help_support_screen.dart';
import '../screens/about_emis_screen.dart';
import '../screens/our_story_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/global_search_screen.dart';
import '../screens/command_center_screen.dart';
import '../screens/analytics_panel_screen.dart';
import '../screens/compliance_panel_screen.dart';
import '../screens/dispatch_panel_screen.dart';
import '../screens/operations_panel_screen.dart';
// import '../screens/ai_insights_screen.dart'; // Requires studentId parameter
// import '../screens/gamification_screen.dart'; // Requires studentId parameter
import '../screens/social_hub_screen.dart';
// import '../screens/feature_hub_screen.dart'; // Requires multiple parameters
import '../screens/english_test_screen.dart';
// import '../screens/video_player_screen.dart'; // Requires videoUrl and title parameters
import '../screens/calendar_screen.dart';
import '../screens/academic_year_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/admissions_screen.dart';
import '../screens/students_screen.dart';
import '../screens/student_profile_screen.dart';
import '../screens/teachers_screen.dart';
import '../screens/staff_directory_screen.dart';
import '../screens/classes_screen.dart';
import '../screens/departments_screen.dart';
import '../screens/programs_screen.dart';
import '../screens/exams_screen.dart';
import '../screens/grades_screen.dart';
import '../screens/homework_screen.dart';
import '../screens/library_screen.dart';
import '../screens/books_screen.dart';
import '../screens/lms_screen.dart';
import '../screens/timetable_screen.dart';
import '../screens/fee_management_screen.dart';
import '../screens/payments_screen.dart';
import '../screens/payroll_screen.dart';
import '../screens/discounts_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/leave_management_screen.dart';
import '../screens/my_schedule_screen.dart';
import '../screens/notice_board_screen.dart';
import '../screens/mobile_home.dart';
import '../screens/error_showcase_page.dart';
import '../screens/placeholder_screen.dart';
// import '../screens/simple_page.dart'; // Requires title parameter

// Dynamic CRUD screen import
import '../widgets/skeleton_screen.dart';
import 'skeleton_screen_map.dart';
import 'all_page_definitions.dart';

// Academic Support screens
import '../screens/academic_support/all_academic_support_screens.dart' as academic_support;

// HR screens
import '../screens/hr/all_hr_screens.dart' as hr_screens;

// Finance screens
import '../screens/finance/all_finance_screens.dart' as finance;

// Communication screens
import '../screens/communication/all_communication_screens.dart' as communication;

// Accountant extra screens
import '../screens/accountant/accountant_more_screens.dart' as accountant_more;

// Librarian extra screens
import '../screens/librarian/librarian_more_screens.dart' as librarian_more;

// HR extra screens
import '../screens/hr/hr_more_screens.dart' as hr_more;

// Staff screens
import '../screens/staff/home_page_management_screen.dart' as staff_home;

// Admin specific screens
import '../screens/admin/classes_screen.dart' as admin_classes;
import '../screens/admin/departments_screen.dart' as admin_depts;
import '../screens/admin/programs_screen.dart' as admin_programs;
import '../screens/admin/discounts_screen.dart' as admin_discounts;
import '../screens/admin/account_creation_screen.dart' as admin_accounts;

// Teacher specific screens
import '../screens/teacher/homework_screen.dart' as teacher_homework;
import '../screens/teacher/lesson_plans_screen.dart' as teacher_lessons;
import '../screens/teacher/student_progress_screen.dart' as teacher_progress;
import '../screens/teacher/exam_results_screen.dart' as teacher_exams;
import '../screens/teacher/student_groups_screen.dart' as teacher_groups;
import '../screens/teacher/message_parents_screen.dart' as teacher_messages;
import '../screens/teacher/my_students_screen.dart' as teacher_students;

// IT Support screens
import '../screens/it_support/all_it_support_screens.dart' as it_support;

// Inventory screens
import '../screens/inventory/all_inventory_screens.dart' as inventory;

// Maintenance screens
import '../screens/maintenance/all_maintenance_screens.dart' as maintenance;

// Event Manager screens
import '../screens/event_manager/all_event_manager_screens.dart' as event_manager;

// Complaint Manager screens
import '../screens/complaint_manager/all_complaint_manager_screens.dart' as complaint_manager;

// Super Admin specific screens
import '../screens/super_admin/all_super_admin_screens.dart'
    as super_admin_tenants;
import '../screens/super_admin/api_integrations_screen.dart' as super_admin_api;
import '../screens/super_admin/system_logs_screen.dart' as super_admin_logs;

// Accountant screens
import '../screens/accountant/invoices_screen.dart' as accountant_invoices;
import '../screens/accountant/payment_management_screen.dart';
import '../screens/accountant/invoice_management_screen.dart';
import '../screens/accountant/fee_types_screen.dart' as accountant_fee_types;
import '../screens/accountant/fee_structures_screen.dart' as accountant_fee_structures;
import '../screens/accountant/fee_assignment_screen.dart' as accountant_fee_assign;
import '../screens/accountant/fee_statement_screen.dart' as accountant_fee_statement;

// Librarian screens
import '../screens/librarian/digital_library_screen.dart' as librarian_digital;
import '../screens/librarian/issue_book_screen.dart' as librarian_issue;
import '../screens/librarian/members_screen.dart' as librarian_members;

// HR screens
import '../screens/hr/recruitment_screen.dart' as hr_recruitment;

// Staff Attendance screen (full implementation)
import '../screens/hr/staff_attendance_screen.dart' as hr_attendance;

// Receptionist screens
import '../screens/receptionist/events_screen.dart' as receptionist_events;
import '../screens/receptionist/leads_screen.dart' as receptionist_leads;

// Page model for registry
class PageRegistry {
  final String id;
  final String name;
  final String description;
  final String category;
  final String
      role; // 'all', 'admin', 'super_admin', 'teacher', 'student', etc.
  final WidgetBuilder builder;
  final IconData icon;
  final bool isActive;
  final Map<String, dynamic>? metadata;
  final String? route; // GoRouter path for navigation

  PageRegistry({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.role,
    required this.builder,
    required this.icon,
    this.isActive = true,
    this.metadata,
    this.route,
  });
}

// Centralized page registry
class AppPageRegistry {
  static final List<PageRegistry> _pages = [
    // Authentication Pages
    PageRegistry(
      id: 'splash',
      name: 'Splash Screen',
      description: 'App splash screen',
      category: 'Authentication',
      role: 'all',
      icon: Icons.play_arrow,
      builder: (context) => const SplashScreen(),
    ),
    PageRegistry(
      id: 'onboarding',
      name: 'Onboarding',
      description: 'User onboarding flow',
      category: 'Authentication',
      role: 'all',
      icon: Icons.swipe,
      builder: (context) => const OnboardingScreen(),
    ),
    PageRegistry(
      id: 'login',
      name: 'Login',
      description: 'User login screen',
      category: 'Authentication',
      role: 'all',
      icon: Icons.login,
      builder: (context) => const LoginScreen(),
    ),
    PageRegistry(
      id: 'signup',
      name: 'Sign Up',
      description: 'User registration screen',
      category: 'Authentication',
      role: 'all',
      icon: Icons.app_registration,
      builder: (context) => const SignupScreen(),
    ),
    PageRegistry(
      id: 'forgot_password',
      name: 'Forgot Password',
      description: 'Password recovery screen',
      category: 'Authentication',
      role: 'all',
      icon: Icons.lock_reset,
      builder: (context) => const ForgotPasswordScreen(),
    ),
    PageRegistry(
      id: 'otp_verification',
      name: 'OTP Verification',
      description: 'OTP verification screen',
      category: 'Authentication',
      role: 'all',
      icon: Icons.pin,
      builder: (context) => const OTPVerificationScreen(),
    ),
    PageRegistry(
      id: 'two_factor',
      name: 'Two Factor Auth',
      description: 'Two-factor authentication screen',
      category: 'Authentication',
      role: 'all',
      icon: Icons.security,
      builder: (context) => const TwoFactorSetupScreen(),
    ),

    // Main Navigation Pages
    // Note: Home page removed - app now starts at login
    PageRegistry(
      id: 'dashboard',
      name: 'Dashboard',
      description: 'Main dashboard page',
      category: 'Navigation',
      role: 'all',
      icon: Icons.dashboard,
      builder: (context) => const DashboardScreen(),
    ),
    PageRegistry(
      id: 'mobile_home',
      name: 'Mobile Home',
      description: 'Mobile optimized home page',
      category: 'Navigation',
      role: 'all',
      icon: Icons.phone_android,
      builder: (context) => const MobileHome(),
    ),
    PageRegistry(
      id: 'command_center',
      route: '/command-center',
      name: 'Command Center',
      description: 'System command center',
      category: 'Navigation',
      role: 'admin',
      icon: Icons.control_point,
      builder: (context) => const CommandCenterScreen(),
    ),

    // User Management Pages
    PageRegistry(
      id: 'profile',
      name: 'Profile',
      description: 'User profile management',
      category: 'User Management',
      role: 'all',
      icon: Icons.person,
      route: '/profile',
      builder: (context) => const ProfileScreen(),
    ),
    PageRegistry(
      id: 'settings',
      name: 'Settings',
      description: 'Application settings',
      category: 'User Management',
      role: 'all',
      icon: Icons.settings,
      route: '/settings',
      builder: (context) => const SettingsScreen(),
    ),
    PageRegistry(
      id: 'change_password',
      name: 'Change Password',
      description: 'Password change screen',
      category: 'User Management',
      role: 'all',
      icon: Icons.password,
      builder: (context) => const ChangePasswordScreen(),
    ),
    PageRegistry(
      id: 'notifications',
      name: 'Notifications',
      description: 'Notifications center',
      category: 'User Management',
      role: 'all',
      icon: Icons.notifications,
      builder: (context) => const NotificationsScreen(),
    ),
    PageRegistry(
      id: 'notification_compose',
      name: 'Compose Notification',
      description: 'Send notifications to all users, by role, or specific users',
      category: 'User Management',
      role: 'all',
      icon: Icons.add_alert,
      route: '/notification-compose',
      builder: (context) => const NotificationComposeScreen(),
    ),
    PageRegistry(
      id: 'messages',
      name: 'Messages',
      description: 'Messaging system',
      category: 'Communication',
      role: 'all',
      icon: Icons.message,
      builder: (context) => const MessagesScreen(),
    ),
    PageRegistry(
      id: 'chat',
      name: 'Chat',
      description: 'Chat interface',
      category: 'Communication',
      role: 'all',
      icon: Icons.chat,
      route: '/chat',
      builder: (context) => const ChatScreen(),
    ),
    // ChatConversationScreen requires chatId parameter - not suitable for static registry
    // PageRegistry(
    //   id: 'chat_conversation',
    //   name: 'Chat Conversation',
    //   description: 'Individual chat conversation',
    //   category: 'Communication',
    //   role: 'all',
    //   icon: Icons.chat_bubble,
    //   builder: (context) => const ChatConversationScreen(),
    // ),

    // Academic Management Pages
    PageRegistry(
      id: 'students',
      route: '/students',
      name: 'Students',
      description: 'Student management',
      category: 'Academic',
      role: 'admin',
      icon: Icons.school,
      builder: (context) => const StudentsScreen(),
    ),
    PageRegistry(
      id: 'student_profile',
      route: '/student-profile',
      name: 'Student Profile',
      description: 'Individual student profile',
      category: 'Academic',
      role: 'admin',
      icon: Icons.person_outline,
      builder: (context) => const StudentProfileScreen(),
    ),
    PageRegistry(
      id: 'teachers',
      route: '/teachers',
      name: 'Teachers',
      description: 'Teacher management',
      category: 'Academic',
      role: 'admin',
      icon: Icons.person,
      builder: (context) => const TeachersScreen(),
    ),
    PageRegistry(
      id: 'staff_directory',
      route: '/staff-directory',
      name: 'Staff Directory',
      description: 'Staff directory listing',
      category: 'Academic',
      role: 'admin',
      icon: Icons.groups,
      builder: (context) => const StaffDirectoryScreen(),
    ),
    PageRegistry(
      id: 'classes',
      route: '/classes',
      name: 'Classes',
      description: 'Class management',
      category: 'Academic',
      role: 'admin',
      icon: Icons.class_,
      builder: (context) => const ClassesScreen(),
    ),
    PageRegistry(
      id: 'admin_classes',
      name: 'Admin Classes',
      description: 'Admin class management',
      category: 'Academic',
      role: 'admin',
      icon: Icons.class_,
      builder: (context) => const admin_classes.ClassesScreen(),
    ),
    PageRegistry(
      id: 'departments',
      route: '/departments',
      name: 'Departments',
      description: 'Department management',
      category: 'Academic',
      role: 'admin',
      icon: Icons.business,
      builder: (context) => const DepartmentsScreen(),
    ),
    PageRegistry(
      id: 'admin_departments',
      name: 'Admin Departments',
      description: 'Admin department management',
      category: 'Academic',
      role: 'admin',
      icon: Icons.business,
      builder: (context) => const admin_depts.DepartmentsScreen(),
    ),
    PageRegistry(
      id: 'programs',
      route: '/programs',
      name: 'Programs',
      description: 'Academic programs',
      category: 'Academic',
      role: 'admin',
      icon: Icons.menu_book,
      builder: (context) => const ProgramsScreen(),
    ),
    PageRegistry(
      id: 'admin_programs',
      name: 'Admin Programs',
      description: 'Admin program management',
      category: 'Academic',
      role: 'admin',
      icon: Icons.menu_book,
      builder: (context) => const admin_programs.ProgramsScreen(),
    ),
    PageRegistry(
      id: 'academic_year',
      route: '/academic-year',
      name: 'Academic Year',
      description: 'Academic year management',
      category: 'Academic',
      role: 'admin',
      icon: Icons.calendar_today,
      builder: (context) => const AcademicYearScreen(),
    ),
    PageRegistry(
      id: 'admissions',
      route: '/admissions',
      name: 'Admissions',
      description: 'Student admissions process',
      category: 'Academic',
      role: 'admin',
      icon: Icons.how_to_reg,
      builder: (context) => const AdmissionsScreen(),
    ),
    PageRegistry(
      id: 'attendance',
      route: '/attendance',
      name: 'Attendance',
      description: 'Attendance tracking',
      category: 'Academic',
      role: 'all',
      icon: Icons.check_circle,
      builder: (context) => const AttendanceScreen(),
    ),
    PageRegistry(
      id: 'exams',
      route: '/exams',
      name: 'Exams',
      description: 'Exam management',
      category: 'Academic',
      role: 'admin',
      icon: Icons.assignment,
      builder: (context) => const ExamsScreen(),
    ),
    PageRegistry(
      id: 'grades',
      route: '/grades',
      name: 'Grades',
      description: 'Grade management',
      category: 'Academic',
      role: 'all',
      icon: Icons.grade,
      builder: (context) => const GradesScreen(),
    ),
    PageRegistry(
      id: 'homework',
      name: 'Homework',
      description: 'Homework management',
      category: 'Academic',
      role: 'teacher',
      icon: Icons.assignment_outlined,
      builder: (context) => const HomeworkScreen(),
    ),
    PageRegistry(
      id: 'teacher_homework',
      route: '/homework',
      name: 'Teacher Homework',
      description: 'Teacher homework management',
      category: 'Academic',
      role: 'teacher',
      icon: Icons.assignment_outlined,
      builder: (context) => const teacher_homework.HomeworkScreen(),
    ),
    PageRegistry(
      id: 'library',
      route: '/library',
      name: 'Library',
      description: 'Library management',
      category: 'Academic',
      role: 'all',
      icon: Icons.local_library,
      builder: (context) => const LibraryScreen(),
    ),
    PageRegistry(
      id: 'books',
      route: '/books',
      name: 'Books',
      description: 'Book catalog',
      category: 'Academic',
      role: 'all',
      icon: Icons.book,
      builder: (context) => const BooksScreen(),
    ),
    PageRegistry(
      id: 'lms',
      name: 'LMS',
      description: 'Learning management system',
      category: 'Academic',
      role: 'all',
      icon: Icons.computer,
      builder: (context) => const LMSScreen(),
    ),
    PageRegistry(
      id: 'timetable',
      name: 'Timetable',
      description: 'Class timetable',
      category: 'Academic',
      role: 'all',
      icon: Icons.schedule,
      builder: (context) => const TimetableScreen(),
    ),
    PageRegistry(
      id: 'my_schedule',
      route: '/my-schedule',
      name: 'My Schedule',
      description: 'Personal schedule',
      category: 'Academic',
      role: 'all',
      icon: Icons.today,
      builder: (context) => const MyScheduleScreen(),
    ),
    PageRegistry(
      id: 'calendar',
      route: '/calendar',
      name: 'Calendar',
      description: 'Academic calendar',
      category: 'Academic',
      role: 'all',
      icon: Icons.calendar_month,
      builder: (context) => const CalendarScreen(),
    ),

    // Financial Management Pages
    PageRegistry(
      id: 'fee_management',
      route: '/fee-management',
      name: 'Fee Management',
      description: 'Fee structure and management',
      category: 'Financial',
      role: 'admin',
      icon: Icons.attach_money,
      builder: (context) => const FeeManagementScreen(),
    ),
    PageRegistry(
      id: 'payments',
      route: '/payments',
      name: 'Payments',
      description: 'Payment processing',
      category: 'Financial',
      role: 'all',
      icon: Icons.payment,
      builder: (context) => const PaymentsScreen(),
    ),
    PageRegistry(
      id: 'payroll',
      route: '/payroll',
      name: 'Payroll',
      description: 'Staff payroll management',
      category: 'Financial',
      role: 'admin',
      icon: Icons.money,
      builder: (context) => const PayrollScreen(),
    ),
    PageRegistry(
      id: 'discounts',
      route: '/discounts',
      name: 'Discounts',
      description: 'Discount management',
      category: 'Financial',
      role: 'admin',
      icon: Icons.local_offer,
      builder: (context) => const DiscountsScreen(),
    ),
    PageRegistry(
      id: 'admin_discounts',
      name: 'Admin Discounts',
      description: 'Admin discount management',
      category: 'Financial',
      role: 'admin',
      icon: Icons.local_offer,
      builder: (context) => const admin_discounts.DiscountsScreen(),
    ),
    PageRegistry(
      id: 'admin_account_creation',
      name: 'Create Account',
      description: 'Register students, teachers, staff, and other roles',
      category: 'Admin Portal',
      role: 'admin',
      icon: Icons.person_add,
      builder: (context) => const admin_accounts.AccountCreationScreen(),
    ),

    // Teacher Portal Pages
    PageRegistry(
      id: 'teacher_lessons',
      route: '/lesson-plans',
      name: 'Lesson Plans',
      description: 'Teacher lesson plans',
      category: 'Teacher Portal',
      role: 'teacher',
      icon: Icons.school,
      builder: (context) => const teacher_lessons.LessonPlansScreen(),
    ),
    PageRegistry(
      id: 'teacher_progress',
      route: '/student-progress',
      name: 'Student Progress',
      description: 'Student progress tracking',
      category: 'Teacher Portal',
      role: 'teacher',
      icon: Icons.trending_up,
      builder: (context) => const teacher_progress.StudentProgressScreen(),
    ),
    PageRegistry(
      id: 'teacher_exams',
      route: '/exam-results',
      name: 'Exam Results',
      description: 'Exam results management',
      category: 'Teacher Portal',
      role: 'teacher',
      icon: Icons.assessment,
      builder: (context) => const teacher_exams.ExamResultsScreen(),
    ),
    PageRegistry(
      id: 'teacher_groups',
      route: '/student-groups',
      name: 'Student Groups',
      description: 'Student group management',
      category: 'Teacher Portal',
      role: 'teacher',
      icon: Icons.group_work,
      builder: (context) => const teacher_groups.StudentGroupsScreen(),
    ),
    PageRegistry(
      id: 'teacher_messages',
      route: '/message-parents',
      name: 'Message Parents',
      description: 'Teacher-parent communication',
      category: 'Teacher Portal',
      role: 'teacher',
      icon: Icons.message_outlined,
      builder: (context) => const teacher_messages.MessageParentsScreen(),
    ),
    PageRegistry(
      id: 'teacher_my_students',
      name: 'My Students',
      description: 'View students assigned to the teacher',
      category: 'Teacher Portal',
      role: 'teacher',
      icon: Icons.people,
      builder: (context) => const teacher_students.MyStudentsScreen(),
    ),

    // Super Admin Pages
    PageRegistry(
      id: 'tenant_management',
      name: 'Tenant Management',
      description: 'Multi-tenant management',
      category: 'Super Admin',
      role: 'super_admin',
      icon: Icons.admin_panel_settings,
      route: '/tenants',
      builder: (context) => const super_admin_tenants.TenantManagementScreen(),
    ),
    PageRegistry(
      id: 'api_integrations',
      name: 'API Integrations',
      description: 'API management and integrations',
      category: 'Super Admin',
      role: 'super_admin',
      icon: Icons.api,
      route: '/api-integrations',
      builder: (context) => const super_admin_api.APIIntegrationsScreen(),
    ),
    PageRegistry(
      id: 'system_logs',
      name: 'System Logs',
      description: 'System activity logs',
      category: 'Super Admin',
      role: 'super_admin',
      icon: Icons.description,
      route: '/system-logs',
      builder: (context) => const super_admin_logs.SystemLogsScreen(),
    ),
    PageRegistry(
      id: 'platform_management',
      name: 'Platform Management',
      description: 'Manage platforms and their configurations',
      category: 'Super Admin',
      role: 'super_admin',
      icon: Icons.cloud,
      route: '/super-admin/platforms',
      builder: (context) => const super_admin_tenants.PlatformManagementScreen(),
    ),
    PageRegistry(
      id: 'profile_management',
      name: 'Profile Management',
      description: 'User profiles across all tenants',
      category: 'Super Admin',
      role: 'super_admin',
      icon: Icons.people,
      route: '/super-admin/profiles',
      builder: (context) => const super_admin_tenants.ProfileManagementScreen(),
    ),
    PageRegistry(
      id: 'chart_of_accounts',
      name: 'Chart of Accounts',
      description: 'Financial account management',
      category: 'Super Admin',
      role: 'super_admin',
      icon: Icons.account_balance,
      route: '/super-admin/chart-of-accounts',
      builder: (context) => const super_admin_tenants.ChartOfAccountsScreen(),
    ),
    PageRegistry(
      id: 'promotions',
      name: 'Promotions',
      description: 'Platform-wide promotions and discounts',
      category: 'Super Admin',
      role: 'super_admin',
      icon: Icons.discount,
      route: '/super-admin/promotions',
      builder: (context) => const super_admin_tenants.PromotionsManagementScreen(),
    ),
    PageRegistry(
      id: 'audit_log',
      name: 'Audit Log',
      description: 'Immutable audit trail',
      category: 'Super Admin',
      role: 'super_admin',
      icon: Icons.security,
      route: '/super-admin/audit-log',
      builder: (context) => const super_admin_tenants.AuditLogScreen(),
    ),
    PageRegistry(
      id: 'record_history',
      name: 'Record History',
      description: 'Deleted and edited record history',
      category: 'Super Admin',
      role: 'super_admin',
      icon: Icons.history,
      route: '/super-admin/record-history',
      builder: (context) => const super_admin_tenants.RecordHistoryScreen(),
    ),
    PageRegistry(
      id: 'address_management',
      name: 'Address Management',
      description: 'Multi-language address configurations',
      category: 'Super Admin',
      role: 'super_admin',
      icon: Icons.location_on,
      route: '/super-admin/addresses',
      builder: (context) => const super_admin_tenants.AddressManagementScreen(),
    ),
    PageRegistry(
      id: 'fee_type_templates',
      name: 'Fee Type Templates',
      description: 'Platform-wide fee type templates',
      category: 'Super Admin',
      role: 'super_admin',
      icon: Icons.receipt_long,
      route: '/super-admin/fee-types',
      builder: (context) => const super_admin_tenants.FeeTypeTemplatesScreen(),
    ),
    PageRegistry(
      id: 'system_settings',
      name: 'System Settings',
      description: 'Platform-wide settings and preferences',
      category: 'Super Admin',
      role: 'super_admin',
      icon: Icons.settings,
      route: '/super-admin/settings',
      builder: (context) => const super_admin_tenants.SystemSettingsScreen(),
    ),
    PageRegistry(
      id: 'backup_restore',
      name: 'Backup & Restore',
      description: 'System backup and restore management',
      category: 'Super Admin',
      role: 'super_admin',
      icon: Icons.backup,
      route: '/super-admin/backup',
      builder: (context) => const super_admin_tenants.BackupRestoreScreen(),
    ),
    PageRegistry(
      id: 'multi_language',
      name: 'Multi-Language',
      description: 'Translation and localization management',
      category: 'Super Admin',
      role: 'super_admin',
      icon: Icons.language,
      route: '/super-admin/language',
      builder: (context) => const super_admin_tenants.MultiLanguageScreen(),
    ),
    PageRegistry(
      id: 'user_creation',
      name: 'Create Admin / Super Admin',
      description: 'Create authentication accounts with role-based access',
      category: 'Super Admin',
      role: 'super_admin',
      icon: Icons.person_add_alt_1,
      route: '/super-admin/create-user',
      builder: (context) => const super_admin_tenants.UserCreationScreen(),
    ),
    PageRegistry(
      id: 'branch_info',
      name: 'Branches & App Info',
      description: 'Manage branch information and locations',
      category: 'Super Admin',
      role: 'super_admin',
      icon: Icons.business,
      route: '/super-admin/branches',
      builder: (context) => const super_admin_tenants.BranchInfoScreen(),
    ),
    PageRegistry(
      id: 'branch_info_admin',
      name: 'Branch Info',
      description: 'View and edit your branch information',
      category: 'Administration',
      role: 'admin',
      icon: Icons.business,
      route: '/admin/branch-info',
      builder: (context) => const super_admin_tenants.BranchInfoScreen(),
    ),

    // Accountant Pages
    PageRegistry(
      id: 'invoices',
      route: '/invoices',
      name: 'Invoices',
      description: 'Invoice management',
      category: 'Accountant',
      role: 'accountant',
      icon: Icons.receipt,
      builder: (context) => const accountant_invoices.InvoicesScreen(),
    ),

    // Librarian Pages
    PageRegistry(
      id: 'digital_library',
      route: '/digital-library',
      name: 'Digital Library',
      description: 'Digital library resources',
      category: 'Librarian',
      role: 'librarian',
      icon: Icons.cloud_queue,
      builder: (context) => const librarian_digital.DigitalLibraryScreen(),
    ),
    PageRegistry(
      id: 'issue_book',
      route: '/issue-book',
      name: 'Issue Book',
      description: 'Book issuing system',
      category: 'Librarian',
      role: 'librarian',
      icon: Icons.menu_book_rounded,
      builder: (context) => const librarian_issue.IssueBookScreen(),
    ),
    PageRegistry(
      id: 'members',
      route: '/members',
      name: 'Library Members',
      description: 'Library membership management',
      category: 'Librarian',
      role: 'librarian',
      icon: Icons.card_membership,
      builder: (context) => const librarian_members.MembersScreen(),
    ),

    // HR Pages
    PageRegistry(
      id: 'recruitment',
      route: '/recruitment',
      name: 'Recruitment',
      description: 'Staff recruitment process',
      category: 'HR',
      role: 'hr',
      icon: Icons.person_add,
      builder: (context) => const hr_recruitment.RecruitmentScreen(),
    ),

    // Receptionist Pages
    PageRegistry(
      id: 'events',
      route: '/events',
      name: 'Events',
      description: 'Event management',
      category: 'Receptionist',
      role: 'receptionist',
      icon: Icons.event,
      builder: (context) => const receptionist_events.EventsScreen(),
    ),
    PageRegistry(
      id: 'leads',
      route: '/leads',
      name: 'Leads',
      description: 'Lead management',
      category: 'Receptionist',
      role: 'receptionist',
      icon: Icons.leaderboard,
      builder: (context) => const receptionist_leads.LeadsScreen(),
    ),

    // Analytics & Reports Pages
    PageRegistry(
      id: 'reports',
      name: 'Reports',
      description: 'System reports',
      category: 'Analytics',
      role: 'all',
      icon: Icons.bar_chart,
      route: '/reports',
      builder: (context) => const ReportsScreen(),
    ),
    PageRegistry(
      id: 'analytics_panel',
      name: 'Analytics Panel',
      description: 'Data analytics dashboard',
      category: 'Analytics',
      role: 'admin',
      icon: Icons.analytics,
      route: '/analytics',
      builder: (context) => const AnalyticsPanelScreen(),
    ),
    PageRegistry(
      id: 'compliance_panel',
      name: 'Compliance Panel',
      description: 'Regulatory compliance tracking',
      category: 'Analytics',
      role: 'admin',
      icon: Icons.verified,
      route: '/compliance',
      builder: (context) => const CompliancePanelScreen(),
    ),
    PageRegistry(
      id: 'dispatch_panel',
      route: '/dispatch',
      name: 'Dispatch Panel',
      description: 'Dispatch management',
      category: 'Analytics',
      role: 'admin',
      icon: Icons.local_shipping,
      builder: (context) => const DispatchPanelScreen(),
    ),
    PageRegistry(
      id: 'operations_panel',
      route: '/operations',
      name: 'Operations Panel',
      description: 'Operations management',
      category: 'Analytics',
      role: 'admin',
      icon: Icons.factory,
      builder: (context) => const OperationsPanelScreen(),
    ),
    // AIInsightsScreen requires studentId parameter - not suitable for static registry
    // PageRegistry(
    //   id: 'ai_insights',
    //   name: 'AI Insights',
    //   description: 'AI-powered insights',
    //   category: 'Analytics',
    //   role: 'admin',
    //   icon: Icons.psychology,
    //   builder: (context) => const AIInsightsScreen(),
    // ),

    // Support & Info Pages
    PageRegistry(
      id: 'help_support',
      name: 'Help & Support',
      description: 'Help and support center',
      category: 'Support',
      role: 'all',
      icon: Icons.help,
      route: '/help-support',
      builder: (context) => const HelpSupportScreen(),
    ),
    PageRegistry(
      id: 'about_emis',
      name: 'About EMIS',
      description: 'About the system',
      category: 'Support',
      role: 'all',
      icon: Icons.info,
      route: '/about-emis',
      builder: (context) => const AboutEmisScreen(),
    ),
    PageRegistry(
      id: 'our_story',
      name: 'Our Story',
      description: 'Our organizational story',
      category: 'Support',
      role: 'all',
      icon: Icons.history,
      builder: (context) => const OurStoryScreen(),
    ),
    PageRegistry(
      id: 'feedback',
      route: '/feedback',
      name: 'Feedback',
      description: 'User feedback collection',
      category: 'Support',
      role: 'all',
      icon: Icons.feedback,
      builder: (context) => const FeedbackScreen(),
    ),

    // Utility Pages
    PageRegistry(
      id: 'global_search',
      name: 'Global Search',
      description: 'System-wide search',
      category: 'Utility',
      role: 'all',
      icon: Icons.search,
      builder: (context) => const GlobalSearchScreen(),
    ),
    // GamificationScreen requires studentId parameter - not suitable for static registry
    // PageRegistry(
    //   id: 'gamification',
    //   name: 'Gamification',
    //   description: 'Gamification features',
    //   category: 'Utility',
    //   role: 'all',
    //   icon: Icons.emoji_events,
    //   builder: (context) => const GamificationScreen(),
    // ),
    PageRegistry(
      id: 'social_hub',
      name: 'Social Hub',
      description: 'Social interaction center',
      category: 'Utility',
      role: 'all',
      icon: Icons.people,
      builder: (context) => const SocialHubScreen(),
    ),
    // FeatureHubScreen requires multiple parameters - not suitable for static registry
    // PageRegistry(
    //   id: 'feature_hub',
    //   name: 'Feature Hub',
    //   description: 'Feature showcase',
    //   category: 'Utility',
    //   role: 'all',
    //   icon: Icons.star,
    //   builder: (context) => const FeatureHubScreen(),
    // ),
    PageRegistry(
      id: 'english_test',
      route: '/english-test',
      name: 'English Test',
      description: 'English proficiency test',
      category: 'Utility',
      role: 'all',
      icon: Icons.translate,
      builder: (context) => const EnglishTestScreen(),
    ),
    // VideoPlayerScreen requires videoUrl and title parameters - not suitable for static registry
    // PageRegistry(
    //   id: 'video_player',
    //   name: 'Video Player',
    //   description: 'Video playback',
    //   category: 'Utility',
    //   role: 'all',
    //   icon: Icons.play_circle,
    //   builder: (context) => const VideoPlayerScreen(),
    // ),
    PageRegistry(
      id: 'leave_management',
      route: '/leave-management',
      name: 'Leave Management',
      description: 'Staff leave management',
      category: 'Utility',
      role: 'all',
      icon: Icons.event_busy,
      builder: (context) => const LeaveManagementScreen(),
    ),
    PageRegistry(
      id: 'notice_board',
      route: '/notice-board',
      name: 'Notice Board',
      description: 'Announcements and notices',
      category: 'Utility',
      role: 'all',
      icon: Icons.campaign,
      builder: (context) => const NoticeBoardScreen(),
    ),

    // IT Support Pages
    PageRegistry(
      id: 'tickets',
      route: '/helpdesk',
      name: 'Help Desk',
      description: 'Support ticket management',
      category: 'IT Support',
      role: 'it_support',
      icon: Icons.support_agent,
      builder: (context) => const it_support.HelpdeskScreen(),
    ),
    PageRegistry(
      id: 'devices',
      route: '/it-assets',
      name: 'IT Assets',
      description: 'Device inventory and tracking',
      category: 'IT Support',
      role: 'it_support',
      icon: Icons.devices,
      builder: (context) => const it_support.ITAssetsScreen(),
    ),
    PageRegistry(
      id: 'bug_reports',
      route: '/incident-logs',
      name: 'Incident Logs',
      description: 'Technical incident reporting',
      category: 'IT Support',
      role: 'it_support',
      icon: Icons.bug_report,
      builder: (context) => const it_support.IncidentLogsScreen(),
    ),
    PageRegistry(
      id: 'network_status',
      route: '/network-monitoring',
      name: 'Network Monitoring',
      description: 'Network health and connectivity',
      category: 'IT Support',
      role: 'it_support',
      icon: Icons.wifi_tethering,
      builder: (context) => const it_support.NetworkMonitoringScreen(),
    ),
    PageRegistry(
      id: 'system_updates',
      route: '/system-status',
      name: 'System Status',
      description: 'System health and updates',
      category: 'IT Support',
      role: 'it_support',
      icon: Icons.dns,
      builder: (context) => const it_support.SystemStatusScreen(),
    ),

    // Inventory Pages
    PageRegistry(
      id: 'stock_management',
      route: '/inventory-list',
      name: 'Inventory List',
      description: 'Stock and inventory management',
      category: 'Inventory',
      role: 'inventory_manager',
      icon: Icons.inventory,
      builder: (context) => const inventory.InventoryListScreen(),
    ),
    PageRegistry(
      id: 'purchase_orders',
      route: '/purchase-orders',
      name: 'Purchase Orders',
      description: 'Order tracking and procurement',
      category: 'Inventory',
      role: 'inventory_manager',
      icon: Icons.add_shopping_cart,
      builder: (context) => const inventory.PurchaseOrdersScreen(),
    ),
    PageRegistry(
      id: 'inventory_reports',
      route: '/stock-audit',
      name: 'Stock Audit',
      description: 'Inventory audit and reports',
      category: 'Inventory',
      role: 'inventory_manager',
      icon: Icons.fact_check,
      builder: (context) => const inventory.StockAuditScreen(),
    ),
    PageRegistry(
      id: 'suppliers',
      route: '/suppliers',
      name: 'Supplier Hub',
      description: 'Supplier and vendor management',
      category: 'Inventory',
      role: 'inventory_manager',
      icon: Icons.business_center,
      builder: (context) => const inventory.SupplierHubScreen(),
    ),
    PageRegistry(
      id: 'assets',
      route: '/asset-tracking',
      name: 'Asset Tracking',
      description: 'Asset lifecycle management',
      category: 'Inventory',
      role: 'inventory_manager',
      icon: Icons.qr_code_scanner,
      builder: (context) => const inventory.AssetTrackingScreen(),
    ),

    // Maintenance Pages
    PageRegistry(
      id: 'service_requests',
      route: '/work-orders',
      name: 'Work Orders',
      description: 'Service and repair requests',
      category: 'Maintenance',
      role: 'maintenance',
      icon: Icons.assignment,
      builder: (context) => const maintenance.WorkOrdersScreen(),
    ),
    PageRegistry(
      id: 'repair_log',
      route: '/maint-logs',
      name: 'Maintenance Logs',
      description: 'Repair and service history',
      category: 'Maintenance',
      role: 'maintenance',
      icon: Icons.history_edu,
      builder: (context) => const maintenance.MaintenanceLogsScreen(),
    ),
    PageRegistry(
      id: 'equipment',
      route: '/equipment-status',
      name: 'Equipment Status',
      description: 'Equipment condition tracking',
      category: 'Maintenance',
      role: 'maintenance',
      icon: Icons.engineering,
      builder: (context) => const maintenance.EquipmentStatusScreen(),
    ),
    PageRegistry(
      id: 'maintenance_schedule',
      route: '/maint-schedule',
      name: 'Maintenance Schedule',
      description: 'Preventive maintenance planning',
      category: 'Maintenance',
      role: 'maintenance',
      icon: Icons.calendar_month,
      builder: (context) => const maintenance.MaintenanceScheduleScreen(),
    ),
    PageRegistry(
      id: 'vendors',
      route: '/vendors',
      name: 'Vendors',
      description: 'Maintenance vendor management',
      category: 'Maintenance',
      role: 'maintenance',
      icon: Icons.business_center,
      builder: (context) => const maintenance.VendorsScreen(),
    ),
    PageRegistry(
      id: 'asset_registry',
      route: '/asset-tracking',
      name: 'Asset Registry',
      description: 'Asset registration and tracking',
      category: 'Maintenance',
      role: 'maintenance',
      icon: Icons.folder,
      builder: (context) => const inventory.AssetTrackingScreen(),
    ),

    // Event Manager Pages
    PageRegistry(
      id: 'attendees',
      route: '/guests',
      name: 'Guest List',
      description: 'Event attendee management',
      category: 'Events',
      role: 'event_manager',
      icon: Icons.group_add,
      builder: (context) => const event_manager.GuestListScreen(),
    ),
    PageRegistry(
      id: 'venues',
      route: '/venues',
      name: 'Venues',
      description: 'Event venue management',
      category: 'Events',
      role: 'event_manager',
      icon: Icons.place,
      builder: (context) => const event_manager.VenuesScreen(),
    ),
    PageRegistry(
      id: 'ticketing',
      route: '/event-budget',
      name: 'Event Budget',
      description: 'Event ticketing and budget',
      category: 'Events',
      role: 'event_manager',
      icon: Icons.account_balance_wallet,
      builder: (context) => const event_manager.EventBudgetScreen(),
    ),
    PageRegistry(
      id: 'sponsorship',
      route: '/event-vendors',
      name: 'Event Vendors',
      description: 'Sponsorship and vendor management',
      category: 'Events',
      role: 'event_manager',
      icon: Icons.business_center,
      builder: (context) => const event_manager.EventVendorsScreen(),
    ),

    // Complaint Manager Pages
    PageRegistry(
      id: 'complaints',
      route: '/complaint-details',
      name: 'Complaint Details',
      description: 'Complaint tracking and management',
      category: 'Complaints',
      role: 'complaint_manager',
      icon: Icons.report,
      builder: (context) => const complaint_manager.ComplaintDetailsScreen(),
    ),
    PageRegistry(
      id: 'resolved_cases',
      route: '/resolved',
      name: 'Resolved Complaints',
      description: 'Completed complaint resolutions',
      category: 'Complaints',
      role: 'complaint_manager',
      icon: Icons.check_circle,
      builder: (context) => const complaint_manager.ResolvedComplaintsScreen(),
    ),
    PageRegistry(
      id: 'complainants',
      route: '/investigation',
      name: 'Investigation',
      description: 'Complainant and case investigation',
      category: 'Complaints',
      role: 'complaint_manager',
      icon: Icons.search,
      builder: (context) => const complaint_manager.InvestigationScreen(),
    ),
    PageRegistry(
      id: 'pending_review',
      route: '/pending-review',
      name: 'Pending Review',
      description: 'Monitor complaints awaiting validation, review, or routing',
      category: 'Complaints',
      role: 'complaint_manager',
      icon: Icons.hourglass_empty,
      builder: (context) => const complaint_manager.PendingReviewScreen(),
    ),
    PageRegistry(
      id: 'complaint_feedback',
      route: '/complaint-feedback',
      name: 'Complaint Feedback',
      description: 'Capture feedback quality and follow-up impressions',
      category: 'Complaints',
      role: 'complaint_manager',
      icon: Icons.feedback,
      builder: (context) => const complaint_manager.ComplaintFeedbackScreen(),
    ),

    // Staff Tasks
    PageRegistry(
      id: 'tasks',
      route: '/event-tasks',
      name: 'Tasks',
      description: 'Task management for staff',
      category: 'Utility',
      role: 'all',
      icon: Icons.task_alt,
      builder: (context) => const event_manager.EventTasksScreen(),
    ),

    // Placeholder & Debug Pages
    PageRegistry(
      id: 'placeholder',
      name: 'Placeholder',
      description: 'Placeholder screen',
      category: 'Debug',
      role: 'all',
      icon: Icons.crop_square,
      builder: (context) => const PlaceholderScreen(),
    ),
    // SimplePage requires title parameter - not suitable for static registry
    // PageRegistry(
    //   id: 'simple_page',
    //   name: 'Simple Page',
    //   description: 'Simple test page',
    //   category: 'Debug',
    //   role: 'all',
    //   icon: Icons.looks_one,
    //   builder: (context) => const SimplePage(),
    // ),
    PageRegistry(
      id: 'error_showcase',
      name: 'Error Showcase',
      description: 'Error handling showcase',
      category: 'Debug',
      role: 'all',
      icon: Icons.error,
      builder: (context) => const ErrorShowcasePage(),
    ),

    // Academic Support Pages
    PageRegistry(
      id: 'attendance_tracking',
      route: '/attendance-tracking',
      name: 'Attendance Tracking',
      description: 'Track and manage attendance records',
      category: 'Academic',
      role: 'academic_support',
      icon: Icons.checklist,
      builder: (context) => const academic_support.AttendanceTrackingScreen(),
    ),
    PageRegistry(
      id: 'placement_tests',
      route: '/placement-tests',
      name: 'Placement Tests',
      description: 'Student placement testing',
      category: 'Academic',
      role: 'academic_support',
      icon: Icons.quiz,
      builder: (context) => const academic_support.PlacementTestsScreen(),
    ),
    PageRegistry(
      id: 'academic_progress',
      route: '/academic-progress',
      name: 'Academic Progress',
      description: 'Track student academic progress',
      category: 'Academic',
      role: 'academic_support',
      icon: Icons.trending_up,
      builder: (context) => const academic_support.AcademicProgressScreen(),
    ),
    PageRegistry(
      id: 'course_material_management',
      route: '/course-material-management',
      name: 'Course Materials',
      description: 'Manage course materials and resources',
      category: 'Academic',
      role: 'academic_support',
      icon: Icons.folder,
      builder: (context) => const academic_support.CourseMaterialManagementScreen(),
    ),
    PageRegistry(
      id: 'report_cards_generation',
      route: '/report-cards-generation',
      name: 'Report Cards',
      description: 'Generate student report cards',
      category: 'Academic',
      role: 'academic_support',
      icon: Icons.card_membership,
      builder: (context) => const academic_support.ReportCardsGenerationScreen(),
    ),

    // Finance Pages
    PageRegistry(
      id: 'salary_management',
      route: '/salary-management',
      name: 'Salary Management',
      description: 'Manage salary processing and payments',
      category: 'Financial',
      role: 'accountant',
      icon: Icons.money,
      builder: (context) => const finance.SalaryManagementScreen(),
    ),
    PageRegistry(
      id: 'expenses_tracking',
      route: '/expenses-tracking',
      name: 'Expenses Tracking',
      description: 'Track operational expenses',
      category: 'Financial',
      role: 'accountant',
      icon: Icons.receipt,
      builder: (context) => const finance.ExpensesTrackingScreen(),
    ),
    PageRegistry(
      id: 'financial_reports',
      route: '/financial-reports',
      name: 'Financial Reports',
      description: 'Generate financial reports',
      category: 'Financial',
      role: 'accountant',
      icon: Icons.bar_chart,
      builder: (context) => const finance.FinancialReportsScreen(),
    ),
    PageRegistry(
      id: 'budget_management',
      route: '/budget-management',
      name: 'Budget Management',
      description: 'Manage budgets and allocations',
      category: 'Financial',
      role: 'accountant',
      icon: Icons.account_balance_wallet,
      builder: (context) => const finance.BudgetManagementScreen(),
    ),
    PageRegistry(
      id: 'accountant_expenses',
      route: '/expenses',
      name: 'Expenses',
      description: 'Track spending and outgoing payments',
      category: 'Financial',
      role: 'accountant',
      icon: Icons.receipt_long,
      builder: (context) => const accountant_more.ExpensesScreen(),
    ),
    PageRegistry(
      id: 'accountant_salaries',
      route: '/salaries',
      name: 'Salaries',
      description: 'Salary processing and staff compensation',
      category: 'Financial',
      role: 'accountant',
      icon: Icons.payments,
      builder: (context) => const accountant_more.SalariesScreen(),
    ),
    PageRegistry(
      id: 'accountant_budget',
      route: '/budget',
      name: 'Budget',
      description: 'Monitor allocations and budget usage',
      category: 'Financial',
      role: 'accountant',
      icon: Icons.account_balance_wallet,
      builder: (context) => const accountant_more.BudgetScreen(),
    ),
    PageRegistry(
      id: 'accountant_taxation',
      route: '/taxation',
      name: 'Taxation',
      description: 'Manage tax records and compliance',
      category: 'Financial',
      role: 'accountant',
      icon: Icons.gavel,
      builder: (context) => const accountant_more.TaxationScreen(),
    ),
    PageRegistry(
      id: 'payment_history',
      route: '/payment-history',
      name: 'Payment History',
      description: 'View completed transactions and payment logs',
      category: 'Financial',
      role: 'accountant',
      icon: Icons.history,
      builder: (context) => const accountant_more.PaymentHistoryScreen(),
    ),
    // Student fee engine (Finance module guide — Phase 2/3)
    PageRegistry(
      id: 'fee_types',
      route: '/fee-types',
      name: 'Fee Types',
      description: 'Define fee categories (tuition, lab, transport, …)',
      category: 'Financial',
      role: 'accountant',
      icon: Icons.category_outlined,
      builder: (context) => const accountant_fee_types.FeeTypesScreen(),
    ),
    PageRegistry(
      id: 'fee_structures',
      route: '/fee-structures',
      name: 'Fee Structures',
      description: 'Fee amounts per fee type, program and class',
      category: 'Financial',
      role: 'accountant',
      icon: Icons.account_balance_wallet_outlined,
      builder: (context) => const accountant_fee_structures.FeeStructuresScreen(),
    ),
    PageRegistry(
      id: 'fee_assignments',
      route: '/fee-assignments',
      name: 'Assign Fees',
      description: 'Assign fee structures to students with discounts and installments',
      category: 'Financial',
      role: 'accountant',
      icon: Icons.playlist_add_check_rounded,
      builder: (context) => const accountant_fee_assign.FeeAssignmentsScreen(),
    ),
    PageRegistry(
      id: 'fee_statement',
      route: '/fee-statement',
      name: 'Fee Statement',
      description: 'Student fee statements, payments, waivers and invoices',
      category: 'Financial',
      role: 'accountant',
      icon: Icons.receipt_long_rounded,
      builder: (context) => const accountant_fee_statement.FeeStatementScreen(),
    ),
    PageRegistry(
      id: 'payment_management',
      route: '/payment-management',
      name: 'Payment Management',
      description: 'Process and manage payments',
      category: 'Financial',
      role: 'accountant',
      icon: Icons.payment,
      builder: (context) => const PaymentManagementScreen(),
    ),
    PageRegistry(
      id: 'invoice_management',
      route: '/invoice-management',
      name: 'Invoice Management',
      description: 'Manage invoices and billing',
      category: 'Financial',
      role: 'accountant',
      icon: Icons.receipt,
      builder: (context) => const InvoiceManagementScreen(),
    ),

    // HR Pages
    PageRegistry(
      id: 'staff_registration',
      route: '/staff-registration',
      name: 'Staff Registration',
      description: 'Register new staff members',
      category: 'HR',
      role: 'hr',
      icon: Icons.person_add,
      builder: (context) => const hr_screens.StaffRegistrationScreen(),
    ),
    PageRegistry(
      id: 'hr_compliance',
      route: '/hr-compliance',
      name: 'HR Compliance',
      description: 'HR compliance and regulations',
      category: 'HR',
      role: 'hr',
      icon: Icons.verified,
      builder: (context) => const hr_screens.HRComplianceScreen(),
    ),
    PageRegistry(
      id: 'exit_management',
      route: '/exit-management',
      name: 'Exit Management',
      description: 'Manage employee exits and offboarding',
      category: 'HR',
      role: 'hr',
      icon: Icons.exit_to_app,
      builder: (context) => const hr_screens.ExitManagementScreen(),
    ),
    PageRegistry(
      id: 'contract_management',
      route: '/contract-management',
      name: 'Contract Management',
      description: 'Manage employee contracts',
      category: 'HR',
      role: 'hr',
      icon: Icons.description,
      builder: (context) => const hr_screens.ContractManagementScreen(),
    ),
    PageRegistry(
      id: 'benefits',
      route: '/benefits',
      name: 'Benefits',
      description: 'Manage employee benefits',
      category: 'HR',
      role: 'hr',
      icon: Icons.card_giftcard,
      builder: (context) => const hr_screens.BenefitsScreen(),
    ),
    PageRegistry(
      id: 'shift_management',
      route: '/shift-management',
      name: 'Shift Management',
      description: 'Manage staff shifts and schedules',
      category: 'HR',
      role: 'hr',
      icon: Icons.schedule,
      builder: (context) => const hr_screens.ShiftManagementScreen(),
    ),
    PageRegistry(
      id: 'performance_evaluation',
      route: '/performance-evaluation',
      name: 'Performance Evaluation',
      description: 'Evaluate staff performance',
      category: 'HR',
      role: 'hr',
      icon: Icons.trending_up,
      builder: (context) => const hr_screens.PerformanceEvaluationScreen(),
    ),
    PageRegistry(
      id: 'hr_training',
      route: '/training',
      name: 'Training',
      description: 'Organize staff training programs',
      category: 'HR',
      role: 'hr',
      icon: Icons.school,
      builder: (context) => const hr_more.TrainingScreen(),
    ),
    PageRegistry(
      id: 'hr_onboarding',
      route: '/onboarding-staff',
      name: 'Onboarding',
      description: 'Guide new staff through onboarding',
      category: 'HR',
      role: 'hr',
      icon: Icons.person_add_alt_1,
      builder: (context) => const hr_more.OnboardingStaffScreen(),
    ),
    PageRegistry(
      id: 'hr_staff_attendance',
      route: '/staff-attendance',
      name: 'Staff Attendance',
      description: 'Monitor staff attendance records',
      category: 'HR',
      role: 'hr',
      icon: Icons.fingerprint,
      builder: (context) => const hr_attendance.StaffAttendanceScreen(),
    ),
    PageRegistry(
      id: 'hr_performance',
      route: '/performance',
      name: 'Performance',
      description: 'Track staff performance reviews',
      category: 'HR',
      role: 'hr',
      icon: Icons.trending_up,
      builder: (context) => const hr_more.PerformanceScreen(),
    ),
    PageRegistry(
      id: 'hr_contracts',
      route: '/contracts',
      name: 'Contracts',
      description: 'Review employee contract status',
      category: 'HR',
      role: 'hr',
      icon: Icons.description,
      builder: (context) => const hr_more.ContractsScreen(),
    ),

    // IT Support Pages (extended)
    PageRegistry(
      id: 'user_management',
      route: '/user-management',
      name: 'User Management',
      description: 'Manage system users and accounts',
      category: 'IT Support',
      role: 'it_support',
      icon: Icons.people,
      builder: (context) => const it_support.UserManagementScreen(),
    ),
    PageRegistry(
      id: 'role_permission_management',
      route: '/role-permission-management',
      name: 'Roles & Permissions',
      description: 'Manage roles and permissions',
      category: 'IT Support',
      role: 'it_support',
      icon: Icons.admin_panel_settings,
      builder: (context) => const it_support.RolePermissionManagementScreen(),
    ),
    PageRegistry(
      id: 'database_backup_restore',
      route: '/database-backup-restore',
      name: 'Backup & Restore',
      description: 'Database backup and restoration',
      category: 'IT Support',
      role: 'it_support',
      icon: Icons.backup,
      builder: (context) => const it_support.DatabaseBackupRestoreScreen(),
    ),
    PageRegistry(
      id: 'security_audit',
      route: '/security-audit',
      name: 'Security Audit',
      description: 'System security assessments',
      category: 'IT Support',
      role: 'it_support',
      icon: Icons.security,
      builder: (context) => const it_support.SecurityAuditScreen(),
    ),
    PageRegistry(
      id: 'software_licenses',
      route: '/licenses',
      name: 'Software Licenses',
      description: 'Track software licenses',
      category: 'IT Support',
      role: 'it_support',
      icon: Icons.verified,
      builder: (context) => const it_support.SoftwareLicensesScreen(),
    ),

    // Inventory Pages (extended)
    PageRegistry(
      id: 'stock_check',
      route: '/stock-check',
      name: 'Stock Check',
      description: 'Check inventory stock levels',
      category: 'Inventory',
      role: 'inventory_manager',
      icon: Icons.inventory_2,
      builder: (context) => const inventory.StockCheckScreen(),
    ),
    PageRegistry(
      id: 'requisitions',
      route: '/requisitions',
      name: 'Requisitions',
      description: 'Manage stock requisitions',
      category: 'Inventory',
      role: 'inventory_manager',
      icon: Icons.request_quote,
      builder: (context) => const inventory.RequisitionsScreen(),
    ),
    PageRegistry(
      id: 'inventory_categories',
      route: '/inventory-categories',
      name: 'Categories',
      description: 'Manage inventory categories',
      category: 'Inventory',
      role: 'inventory_manager',
      icon: Icons.category,
      builder: (context) => const inventory.InventoryCategoriesScreen(),
    ),

    // Communication Pages
    PageRegistry(
      id: 'announcement_management',
      route: '/announcement-management',
      name: 'Announcements',
      description: 'Create and manage announcements',
      category: 'Communication',
      role: 'admin',
      icon: Icons.campaign,
      builder: (context) => const communication.AnnouncementManagementScreen(),
    ),
    PageRegistry(
      id: 'complaint_management',
      name: 'Complaint Management',
      description: 'Manage user complaints',
      category: 'Communication',
      role: 'admin',
      icon: Icons.report,
      builder: (context) => const communication.ComplaintManagementScreen(),
    ),
    PageRegistry(
      id: 'feedback_collection',
      name: 'Feedback Collection',
      description: 'Collect and manage feedback',
      category: 'Communication',
      role: 'admin',
      icon: Icons.feedback,
      builder: (context) => const communication.FeedbackCollectionScreen(),
    ),

    // Librarian Pages (extended)
    PageRegistry(
      id: 'return_book',
      route: '/return-book',
      name: 'Return Book',
      description: 'Process book returns',
      category: 'Librarian',
      role: 'librarian',
      icon: Icons.assignment_return,
      builder: (context) => const librarian_more.ReturnBookScreen(),
    ),
    PageRegistry(
      id: 'catalog',
      route: '/catalog',
      name: 'Catalog',
      description: 'Library catalog management',
      category: 'Librarian',
      role: 'librarian',
      icon: Icons.library_books,
      builder: (context) => const librarian_more.CatalogScreen(),
    ),
    PageRegistry(
      id: 'librarian_memberships',
      route: '/memberships',
      name: 'Memberships',
      description: 'Manage reader memberships',
      category: 'Librarian',
      role: 'librarian',
      icon: Icons.badge,
      builder: (context) => const librarian_more.MembershipsScreen(),
    ),
    PageRegistry(
      id: 'librarian_reservations',
      route: '/reservations',
      name: 'Reservations',
      description: 'Track book reservations',
      category: 'Librarian',
      role: 'librarian',
      icon: Icons.bookmark_added,
      builder: (context) => const librarian_more.ReservationsScreen(),
    ),
    PageRegistry(
      id: 'fine_management',
      route: '/fine-management',
      name: 'Fine Management',
      description: 'Handle overdue fines and fees',
      category: 'Librarian',
      role: 'librarian',
      icon: Icons.payments,
      builder: (context) => const librarian_more.FineManagementScreen(),
    ),

    // Staff Pages
    PageRegistry(
      id: 'home_page_management',
      route: '/home-page-management',
      name: 'Home Page',
      description: 'Manage website home page content',
      category: 'Staff',
      role: 'staff',
      icon: Icons.home,
      builder: (context) => const staff_home.HomePageManagementScreen(),
    ),
  ];

  // Automatically register all dynamic pages from AllPageDefinitions
  static final List<PageRegistry> _dynamicPages = AllPageDefinitions.pages
      .where((def) => _pages.every((p) => p.id != def.id))
      .map((def) => PageRegistry(
            id: def.id,
            name: def.name,
            description: def.description,
            category: def.category,
            role: def.role,
            icon: def.icon,
            route: def.route,
            builder: (context) => skeletonScreenMap[def.id]?.call() ??
                SkeletonScreen(
                  title: def.name,
                  description: def.description,
                  category: def.category,
                  icon: def.icon,
                  accentColor: def.color,
                  tableName: def.tableName,
                ),
          ))
      .toList();

  static int get dynamicPageCount => _dynamicPages.length;
  static int get totalPageCount => _pages.length + _dynamicPages.length;

  /// All pages combined (static + dynamic)
  static List<PageRegistry> get _allPages => [..._pages, ..._dynamicPages];

  // Get all pages
  static List<PageRegistry> getAllPages() {
    return _allPages.where((page) => page.isActive).toList();
  }

  // Get pages by role
  static List<PageRegistry> getPagesByRole(String role) {
    return _allPages
        .where((page) =>
            page.isActive && (page.role == 'all' || page.role == role))
        .toList();
  }

  // Get pages by category
  static List<PageRegistry> getPagesByCategory(String category) {
    return _allPages
        .where((page) => page.isActive && page.category == category)
        .toList();
  }

  // Get page by ID
  static PageRegistry? getPageById(String id) {
    try {
      return _allPages.firstWhere((page) => page.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get all unique categories
  static List<String> getAllCategories() {
    final categories = _allPages.map((page) => page.category).toSet().toList();
    categories.sort();
    return categories;
  }

  // Get all unique roles
  static List<String> getAllRoles() {
    final roles = _allPages.map((page) => page.role).toSet().toList();
    roles.sort();
    return roles;
  }

  // Add a new page dynamically (for admin dashboard)
  static void addPage(PageRegistry page) {
    _pages.add(page);
  }

  // Remove a page by ID
  static bool removePage(String id) {
    final staticIndex = _pages.indexWhere((page) => page.id == id);
    if (staticIndex != -1) {
      _pages.removeAt(staticIndex);
      return true;
    }
    return false;
  }

  // Toggle page active status
  static bool togglePageStatus(String id) {
    final page = getPageById(id);
    if (page == null) return false;
    final staticIndex = _pages.indexWhere((p) => p.id == id);
    if (staticIndex != -1) {
      _pages[staticIndex] = PageRegistry(
        id: _pages[staticIndex].id,
        name: _pages[staticIndex].name,
        description: _pages[staticIndex].description,
        category: _pages[staticIndex].category,
        role: _pages[staticIndex].role,
        builder: _pages[staticIndex].builder,
        icon: _pages[staticIndex].icon,
        isActive: !_pages[staticIndex].isActive,
        metadata: _pages[staticIndex].metadata,
      );
      return true;
    }
    return false;
  }

  // Search pages by name or description
  static List<PageRegistry> searchPages(String query) {
    final lowerQuery = query.toLowerCase();
    return _allPages
        .where((page) =>
            page.isActive &&
            (page.name.toLowerCase().contains(lowerQuery) ||
                page.description.toLowerCase().contains(lowerQuery)))
        .toList();
  }

  // Get pages count by role
  static Map<String, int> getPageCountByRole() {
    final Map<String, int> counts = {};
    for (final page in _allPages) {
      if (page.isActive) {
        counts[page.role] = (counts[page.role] ?? 0) + 1;
      }
    }
    return counts;
  }

  // Get pages count by category
  static Map<String, int> getPageCountByCategory() {
    final Map<String, int> counts = {};
    for (final page in _allPages) {
      if (page.isActive) {
        counts[page.category] = (counts[page.category] ?? 0) + 1;
      }
    }
    return counts;
  }
}
