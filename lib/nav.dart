import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:course_emis/providers/auth_provider.dart';
import 'package:course_emis/screens/it_support/all_it_support_screens.dart'
    as it_support_screens;

// Screen Imports
import 'package:course_emis/screens/splash_screen.dart';
import 'package:course_emis/screens/onboarding_screen.dart';
import 'package:course_emis/screens/login_screen.dart';
import 'package:course_emis/screens/signup_screen.dart';
import 'package:course_emis/screens/registration_screen.dart';
import 'package:course_emis/screens/forgot_password_screen.dart';
import 'package:course_emis/screens/otp_verification_screen.dart';
import 'package:course_emis/screens/change_password_screen.dart';
import 'package:course_emis/screens/settings_screen.dart';
import 'package:course_emis/screens/dashboard_screen.dart';
import 'package:course_emis/screens/mobile_home.dart';

// Module Screens
import 'package:course_emis/screens/students_screen.dart';
import 'package:course_emis/screens/payments_screen.dart';
import 'package:course_emis/screens/books_screen.dart';
import 'package:course_emis/screens/attendance_screen.dart';
import 'package:course_emis/screens/grades_screen.dart';
import 'package:course_emis/screens/teachers_screen.dart';
import 'package:course_emis/screens/payroll_screen.dart';
import 'package:course_emis/screens/feedback_screen.dart';
import 'package:course_emis/screens/lms_screen.dart';
import 'package:course_emis/screens/notifications_screen.dart';
import 'package:course_emis/screens/notification_detail_screen.dart';
import 'package:course_emis/screens/notification_compose_screen.dart';
import 'package:course_emis/screens/reports_screen.dart';
import 'package:course_emis/screens/operations_panel_screen.dart';
import 'package:course_emis/screens/dispatch_panel_screen.dart';
import 'package:course_emis/screens/compliance_panel_screen.dart';
import 'package:course_emis/screens/command_center_screen.dart';
import 'package:course_emis/screens/analytics_panel_screen.dart';
import 'package:course_emis/screens/ads/ads_pages.dart';
import 'package:course_emis/screens/profile_screen.dart';
import 'package:course_emis/screens/help_support_screen.dart';
import 'package:course_emis/screens/about_emis_screen.dart';
import 'package:course_emis/screens/english_test_screen.dart';
import 'package:course_emis/screens/admissions_screen.dart';
import 'package:course_emis/screens/fee_management_screen.dart';
import 'package:course_emis/screens/staff_directory_screen.dart';
import 'package:course_emis/screens/academic_year_screen.dart';
import 'package:course_emis/screens/notice_board_screen.dart';
import 'package:course_emis/screens/my_schedule_screen.dart';
import 'package:course_emis/screens/messages_screen.dart';
import 'package:course_emis/screens/exams_screen.dart';
import 'package:course_emis/screens/chat_screen.dart';
import 'package:course_emis/screens/chat_conversation_screen.dart';
import 'package:course_emis/screens/leave_management_screen.dart';
import 'package:course_emis/screens/student_profile_screen.dart';
import 'package:course_emis/screens/library_screen.dart';
import 'package:course_emis/screens/calendar_screen.dart';
import 'package:course_emis/screens/staff/home_page_management_screen.dart'
    as staff_home;

// Admin Panel Screens
import 'package:course_emis/screens/admin/all_admin_screens.dart'
    as admin_screens;

// Teacher Panel Screens
import 'package:course_emis/screens/teacher/all_teacher_screens.dart'
    as teacher_screens;

import 'package:course_emis/screens/student_registration_screen.dart';
import 'package:course_emis/screens/certificate_generation_screen.dart';

// Accountant Panel Screens
import 'package:course_emis/screens/accountant/invoices_screen.dart'
    as accountant_screens;
import 'package:course_emis/screens/accountant/accountant_more_screens.dart'
    as accountant_more_screens;

// Librarian Panel Screens
import 'package:course_emis/screens/librarian/issue_book_screen.dart'
    as librarian_screens;
import 'package:course_emis/screens/librarian/digital_library_screen.dart'
    as librarian_screens2;
import 'package:course_emis/screens/librarian/members_screen.dart'
    as librarian_screens3;
import 'package:course_emis/screens/librarian/librarian_more_screens.dart'
    as librarian_more_screens;

// Super Admin Panel Screens
import 'package:course_emis/screens/super_admin/all_super_admin_screens.dart'
    as superadmin_screens;

// HR Panel Screens
import 'package:course_emis/screens/hr/recruitment_screen.dart' as hr_screens;
import 'package:course_emis/screens/hr/hr_more_screens.dart' as hr_more_screens;
import 'package:course_emis/screens/hr/staff_registration_screen.dart'
    as hr_screens2;
import 'package:course_emis/screens/hr/benefits_screen.dart' as hr_screens3;
import 'package:course_emis/screens/hr/hr_compliance_screen.dart'
    as hr_screens4;
import 'package:course_emis/screens/hr/exit_management_screen.dart'
    as hr_screens5;
import 'package:course_emis/screens/hr/performance_evaluation_screen.dart'
    as hr_screens6;
import 'package:course_emis/screens/hr/contract_management_screen.dart'
    as hr_screens7;
import 'package:course_emis/screens/hr/shift_management_screen.dart'
    as hr_screens8;

// Inventory Manager Screens
import 'package:course_emis/screens/inventory/all_inventory_screens.dart'
    as inventory_screens;

// Receptionist Screens
import 'package:course_emis/screens/receptionist/leads_screen.dart'
    as receptionist_screens;
import 'package:course_emis/screens/receptionist/events_screen.dart'
    as receptionist_screens2;

import 'package:course_emis/screens/academic_support/attendance_tracking_screen.dart'
    as academic_support_screens;
import 'package:course_emis/screens/academic_support/placement_tests_screen.dart'
    as academic_support_screens2;
import 'package:course_emis/screens/academic_support/academic_progress_screen.dart'
    as academic_support_screens3;
import 'package:course_emis/screens/academic_support/course_material_management_screen.dart'
    as academic_support_screens4;
import 'package:course_emis/screens/academic_support/report_cards_generation_screen.dart'
    as academic_support_screens5;

// New Panel Screens
import 'package:course_emis/screens/accountant/payment_management_screen.dart'
    as accountant_screens2;
import 'package:course_emis/screens/accountant/invoice_management_screen.dart'
    as accountant_screens3;
import 'package:course_emis/screens/accountant/fee_types_screen.dart'
    as accountant_fee_types;
import 'package:course_emis/screens/accountant/fee_structures_screen.dart'
    as accountant_fee_structures;
import 'package:course_emis/screens/accountant/fee_assignment_screen.dart'
    as accountant_fee_assign;
import 'package:course_emis/screens/accountant/fee_statement_screen.dart'
    as accountant_fee_statement;
import 'package:course_emis/screens/finance/salary_management_screen.dart'
    as finance_screens;
import 'package:course_emis/screens/finance/expenses_tracking_screen.dart'
    as finance_screens2;
import 'package:course_emis/screens/finance/financial_reports_screen.dart'
    as finance_screens3;
import 'package:course_emis/screens/finance/budget_management_screen.dart'
    as finance_screens4;
// leave_management and staff_attendance handled via hr_more_screens routes above
import 'package:course_emis/screens/communication/announcement_management_screen.dart'
    as communication_screens;
import 'package:course_emis/screens/communication/complaint_management_screen.dart'
    as communication_screens2;
import 'package:course_emis/screens/communication/feedback_collection_screen.dart'
    as communication_screens3;
import 'package:course_emis/screens/it_support/it_support_panel_screen.dart'
    as it_support_screens2;
import 'package:course_emis/screens/event_manager/communication_events_screen.dart'
    as event_manager_screens2;
import 'package:course_emis/screens/maintenance/all_maintenance_screens.dart'
    as maintenance_screens;
import 'package:course_emis/screens/event_manager/all_event_manager_screens.dart'
    as event_manager_screens;
import 'package:course_emis/screens/complaint_manager/all_complaint_manager_screens.dart'
    as complaint_manager_screens;
import 'package:course_emis/screens/transport/all_transport_screens.dart'
    as transport_screens;

// Staff Role Screens (for nav content)
import 'package:course_emis/screens/staff_accountant_screen.dart';
import 'package:course_emis/screens/staff_hr_screen.dart';
import 'package:course_emis/screens/staff_librarian_screen.dart';
import 'package:course_emis/screens/staff_frontdesk_screen.dart';
import 'package:course_emis/screens/staff_inventory_manager_screen.dart';
import 'package:course_emis/screens/staff_it_support_screen.dart';
import 'package:course_emis/screens/staff_maintenance_screen.dart';
import 'package:course_emis/screens/staff_event_coordinator_screen.dart';
import 'package:course_emis/screens/staff_complaint_manager_screen.dart';
import 'package:course_emis/screens/staff_security_screen.dart';
import 'package:course_emis/screens/staff_finance_screen.dart';
import 'package:course_emis/screens/staff_academic_support_screen.dart';

// Role-based Panel Screens (using the ones from lib/panels for consistency)
import 'package:course_emis/panels/super_admin/super_admin_panel_screen.dart';
import 'package:course_emis/panels/admin/admin_panel_screen.dart';
import 'package:course_emis/panels/teacher/teacher_panel_screen.dart';
import 'package:course_emis/panels/staff/staff_panel_screen.dart';
import 'package:course_emis/panels/academic_support/academic_support_panel_screen.dart';
import 'package:course_emis/panels/accountant/accountant_panel_screen.dart';
import 'package:course_emis/panels/it_support/it_support_panel_screen.dart';
import 'package:course_emis/panels/communication_events/communication_events_panel_screen.dart';
import 'package:course_emis/panels/hr_manager/hr_manager_panel_screen.dart';
import 'package:course_emis/panels/librarian/librarian_panel_screen.dart';
import 'package:course_emis/panels/inventory_manager/inventory_manager_panel_screen.dart';
import 'package:course_emis/panels/maintenance/maintenance_panel_screen.dart';
import 'package:course_emis/panels/receptionist/receptionist_panel_screen.dart';
import 'package:course_emis/panels/complaint_manager/complaint_manager_panel_screen.dart';

import 'package:course_emis/screens/logged_in_devices_screen.dart'
    as logged_in_devices;
import 'package:course_emis/screens/app_update_screen.dart' as app_update;
import 'package:course_emis/screens/hostel/hostel_screen.dart';
import 'package:course_emis/screens/security/security_logs_screen.dart';
import 'package:course_emis/screens/visitors/visitors_screen.dart';
import 'package:course_emis/screens/notification_preferences_screen.dart';
import 'package:course_emis/widgets/skeleton_screen.dart';
import 'package:course_emis/config/skeleton_screen_map.dart';
import 'package:course_emis/config/all_page_definitions.dart';
import 'package:course_emis/providers/impersonation_provider.dart';

export 'app_routes_all.dart';

final isDemoModeProvider = StateProvider<bool>((ref) => false);
final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutesAll.splash,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isDemoMode = ref.read(isDemoModeProvider);
      final savedSession = ref.read(hasSavedSessionProvider).valueOrNull ?? false;
      final isAuth = session != null || isDemoMode || savedSession;
      final isAuthRoute = state.matchedLocation == AppRoutesAll.login ||
          state.matchedLocation == AppRoutesAll.signup ||
          state.matchedLocation == AppRoutesAll.registration;
      final isOnboarding = state.matchedLocation == AppRoutesAll.onboarding;
      final isHome = state.matchedLocation == AppRoutesAll.home;
      final isSplash = state.matchedLocation == AppRoutesAll.splash;

      // If it's splash screen, let it handle its own logic
      if (isSplash) return null;

      if (!isAuth &&
          !isAuthRoute &&
          !isOnboarding &&
          !isHome &&
          state.matchedLocation != '/forgot-password') {
        return AppRoutesAll.login;
      }

      // Handle actual authenticated user redirects
      if (session != null && isAuthRoute) {
        // Active impersonation takes precedence so the session lands in the
        // impersonated user's panel.
        final imp = ref.read(impersonationProvider);
        final role = imp.isImpersonating
            ? imp.effectiveRole
            : Supabase.instance.client.auth.currentUser
                    ?.userMetadata?['role']
                    ?.toString()
                    .toLowerCase();

        return homeRouteForRole(role);
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutesAll.home,
        name: 'home',
        redirect: (context, state) => AppRoutesAll.login,
      ),
      GoRoute(
        path: AppRoutesAll.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.registration,
        name: 'registration',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      GoRoute(
        path: AppRoutesAll.superAdmin,
        name: 'super-admin-panel',
        builder: (context, state) => const SuperAdminPanelScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.adminPanel,
        name: 'admin-panel',
        builder: (context, state) => const AdminPanelScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.teacherPanel,
        name: 'teacher-panel',
        builder: (context, state) => const TeacherPanelScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.staffPanel,
        name: 'staff-panel',
        builder: (context, state) => const StaffPanelScreen(),
      ),
      // Staff Sub-Panels (6 panels)
      GoRoute(
        path: AppRoutesAll.financeAccountsPanel,
        name: 'finance-accounts-panel',
        builder: (context, state) => const AccountantPanelScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.academicSupportPanel,
        name: 'academic-support-panel',
        builder: (context, state) => const AcademicSupportPanelScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.hrOperationsPanel,
        name: 'hr-operations-panel',
        builder: (context, state) => const HRManagerPanelScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.itSystemSupportPanel,
        name: 'it-system-support-panel',
        builder: (context, state) => const ITSupportPanelScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.communicationEventsPanel,
        name: 'communication-events-panel',
        builder: (context, state) => const CommunicationEventsPanelScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.librarianPanel,
        name: 'librarian-panel',
        builder: (context, state) => const LibrarianPanelScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.inventoryManagerPanel,
        name: 'inventory-manager-panel',
        builder: (context, state) => const InventoryManagerPanelScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.maintenancePanel,
        name: 'maintenance-panel',
        builder: (context, state) => const MaintenancePanelScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.receptionistPanel,
        name: 'receptionist-panel',
        builder: (context, state) => const ReceptionistPanelScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.complaintManagerPanel,
        name: 'complaint-manager-panel',
        builder: (context, state) => const ComplaintManagerPanelScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.operationsCenterPanel,
        name: 'operations-center-panel',
        builder: (context, state) => const StaffPanelScreen(),
      ),
      // Staff Role Dashboard Routes
      GoRoute(
        path: AppRoutesAll.staffAccountant,
        name: 'staff-accountant',
        builder: (context, state) => const StaffAccountantScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.staffHR,
        name: 'staff-hr',
        builder: (context, state) => const StaffHRScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.staffLibrarian,
        name: 'staff-librarian',
        builder: (context, state) => const StaffLibrarianScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.staffFrontDesk,
        name: 'staff-front-desk',
        builder: (context, state) => const StaffFrontDeskScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.staffInventory,
        name: 'staff-inventory',
        builder: (context, state) => const StaffInventoryManagerScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.staffIT,
        name: 'staff-it',
        builder: (context, state) => const StaffITSupportScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.staffMaintenance,
        name: 'staff-maintenance',
        builder: (context, state) => const StaffMaintenanceScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.staffEvent,
        name: 'staff-event',
        builder: (context, state) => const StaffEventCoordinatorScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.staffComplaint,
        name: 'staff-complaint',
        builder: (context, state) => const StaffComplaintManagerScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.staffSecurity,
        name: 'staff-security',
        builder: (context, state) => const StaffSecurityScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.staffFinance,
        name: 'staff-finance',
        builder: (context, state) => const StaffFinanceScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.staffAcademicSupport,
        name: 'staff-academic-support',
        builder: (context, state) => const StaffAcademicSupportScreen(),
      ),
      // Note: receptionist, inventory_manager, event_manager, complaint_manager,
      // librarian, maintenance panels removed (consolidated into 6 staff panels)
      // Modules
      GoRoute(
        path: AppRoutesAll.departments,
        name: 'departments',
        builder: (context, state) => const admin_screens.DepartmentsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.programs,
        name: 'programs',
        builder: (context, state) => const admin_screens.ProgramsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.classes,
        name: 'classes',
        builder: (context, state) => const admin_screens.ClassesScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.students,
        name: 'students',
        builder: (context, state) => const StudentsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.payments,
        name: 'payments',
        builder: (context, state) => const PaymentsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.discounts,
        name: 'discounts',
        builder: (context, state) => const admin_screens.DiscountsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.accountCreation,
        name: 'account-creation',
        builder: (context, state) =>
            const admin_screens.AccountCreationScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.adminBranchInfo,
        name: 'admin-branch-info',
        builder: (context, state) =>
            const superadmin_screens.BranchInfoScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.books,
        name: 'books',
        builder: (context, state) => const BooksScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.attendance,
        name: 'attendance',
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.grades,
        name: 'grades',
        builder: (context, state) => const GradesScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.teachers,
        name: 'teachers',
        builder: (context, state) => const TeachersScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.payroll,
        name: 'payroll',
        builder: (context, state) => const PayrollScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.feedback,
        name: 'feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.lms,
        name: 'lms',
        builder: (context, state) => const LMSScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.notificationCompose,
        name: 'notification-compose',
        builder: (context, state) => const NotificationComposeScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.notificationDetail,
        name: 'notification-detail',
        builder: (context, state) => NotificationDetailScreen(
          notificationId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutesAll.reports,
        name: 'reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.loggedInDevices,
        name: 'logged-in-devices',
        builder: (context, state) =>
            const logged_in_devices.LoggedInDevicesScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.appUpdate,
        name: 'app-update',
        builder: (context, state) => const app_update.AppUpdateScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.otp,
        name: 'otp',
        builder: (context, state) => const OTPVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.changePassword,
        name: 'change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.mobileHome,
        name: 'mobile-home',
        builder: (context, state) => const MobileHome(),
      ),
      GoRoute(
        path: AppRoutesAll.ads,
        name: 'ads',
        builder: (context, state) => const AdsHubScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.adsCampaigns,
        name: 'ads-campaigns',
        builder: (context, state) => const AdCampaignsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.adsCreativeStudio,
        name: 'ads-creative-studio',
        builder: (context, state) => const CreativeStudioScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.googleAds,
        name: 'google-ads',
        builder: (context, state) => const GoogleAdsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.courseAds,
        name: 'course-ads',
        builder: (context, state) => const CourseAdsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.operations,
        name: 'operations',
        builder: (context, state) => const OperationsPanelScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.dispatch,
        name: 'dispatch',
        builder: (context, state) => const DispatchPanelScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.compliance,
        name: 'compliance',
        builder: (context, state) => const CompliancePanelScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.commandCenter,
        name: 'command-center',
        builder: (context, state) => const CommandCenterScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.analytics,
        name: 'analytics',
        builder: (context, state) => const AnalyticsPanelScreen(),
      ),
      // New screens from More menu
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/help-support',
        name: 'help-support',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: '/about-emis',
        name: 'about-emis',
        builder: (context, state) => const AboutEmisScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.englishTest,
        name: 'english-test',
        builder: (context, state) => const EnglishTestScreen(),
      ),
      GoRoute(
        path: '/admissions',
        name: 'admissions',
        builder: (context, state) => const AdmissionsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.studentRegistration,
        name: 'student-registration',
        builder: (context, state) => const StudentRegistrationScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.certificateGeneration,
        name: 'certificate-generation',
        builder: (context, state) => const CertificateGenerationScreen(),
      ),
      GoRoute(
        path: '/fee-management',
        name: 'fee-management',
        builder: (context, state) => const FeeManagementScreen(),
      ),
      GoRoute(
        path: '/staff-directory',
        name: 'staff-directory',
        builder: (context, state) => const StaffDirectoryScreen(),
      ),
      GoRoute(
        path: '/academic-year',
        name: 'academic-year',
        builder: (context, state) => const AcademicYearScreen(),
      ),
      GoRoute(
        path: '/notice-board',
        name: 'notice-board',
        builder: (context, state) => const NoticeBoardScreen(),
      ),
      GoRoute(
        path: '/my-schedule',
        name: 'my-schedule',
        builder: (context, state) => const MyScheduleScreen(),
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        name: 'chat-conversation',
        builder: (context, state) => ChatConversationScreen(
          chatId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/leave-management',
        name: 'leave-management',
        builder: (context, state) => const LeaveManagementScreen(),
      ),
      GoRoute(
        path: '/messages',
        name: 'messages',
        builder: (context, state) => const MessagesScreen(),
      ),
      GoRoute(
        path: '/exams',
        name: 'exams',
        builder: (context, state) => const ExamsScreen(),
      ),
      // Additional Module Screens (from page_registry static pages)
      GoRoute(
        path: '/student-profile',
        name: 'student-profile',
        builder: (context, state) => const StudentProfileScreen(),
      ),
      GoRoute(
        path: '/library',
        name: 'library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/home-page-management',
        name: 'home-page-management',
        builder: (context, state) =>
            const staff_home.HomePageManagementScreen(),
      ),
      // Teacher Panel Screens
      GoRoute(
        path: AppRoutesAll.lessonPlans,
        name: 'lesson-plans',
        builder: (context, state) => const teacher_screens.LessonPlansScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.homework,
        name: 'homework',
        builder: (context, state) => const teacher_screens.HomeworkScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.examResults,
        name: 'exam-results',
        builder: (context, state) => const teacher_screens.ExamResultsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.messageParents,
        name: 'message-parents',
        builder: (context, state) =>
            const teacher_screens.MessageParentsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.studentProgress,
        name: 'student-progress',
        builder: (context, state) =>
            const teacher_screens.StudentProgressScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.studentGroups,
        name: 'student-groups',
        builder: (context, state) =>
            const teacher_screens.StudentGroupsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.myStudents,
        name: 'my-students',
        builder: (context, state) =>
            const teacher_screens.MyStudentsScreen(),
      ),
      // Accountant Panel Screens
      GoRoute(
        path: AppRoutesAll.invoices,
        name: 'invoices',
        builder: (context, state) => const accountant_screens.InvoicesScreen(),
      ),
      // Librarian Panel Screens
      GoRoute(
        path: AppRoutesAll.issueBook,
        name: 'issue-book',
        builder: (context, state) => const librarian_screens.IssueBookScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.digitalLibrary,
        name: 'digital-library',
        builder: (context, state) =>
            const librarian_screens2.DigitalLibraryScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.members,
        name: 'members',
        builder: (context, state) => const librarian_screens3.MembersScreen(),
      ),
      // Super Admin Panel Screens
      GoRoute(
        path: AppRoutesAll.systemLogs,
        name: 'system-logs',
        builder: (context, state) =>
            const superadmin_screens.SystemLogsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.apiIntegrations,
        name: 'api-integrations',
        builder: (context, state) =>
            const superadmin_screens.APIIntegrationsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.platforms,
        name: 'platform-management',
        builder: (context, state) =>
            const superadmin_screens.PlatformManagementScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.profiles,
        name: 'profile-management',
        builder: (context, state) =>
            const superadmin_screens.ProfileManagementScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.chartOfAccounts,
        name: 'chart-of-accounts',
        builder: (context, state) =>
            const superadmin_screens.ChartOfAccountsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.promotions,
        name: 'promotions-management',
        builder: (context, state) =>
            const superadmin_screens.PromotionsManagementScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.auditLog,
        name: 'audit-log',
        builder: (context, state) =>
            const superadmin_screens.AuditLogScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.recordHistory,
        name: 'record-history',
        builder: (context, state) =>
            const superadmin_screens.RecordHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.addresses,
        name: 'address-management',
        builder: (context, state) =>
            const superadmin_screens.AddressManagementScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.feeTypeTemplates,
        name: 'fee-type-templates',
        builder: (context, state) =>
            const superadmin_screens.FeeTypeTemplatesScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.systemSettings,
        name: 'system-settings',
        builder: (context, state) =>
            const superadmin_screens.SystemSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.backupRestore,
        name: 'backup-restore',
        builder: (context, state) =>
            const superadmin_screens.BackupRestoreScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.multiLanguage,
        name: 'multi-language',
        builder: (context, state) =>
            const superadmin_screens.MultiLanguageScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.userCreation,
        name: 'user-creation',
        builder: (context, state) =>
            const superadmin_screens.UserCreationScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.branchInfo,
        name: 'super-admin-branches',
        builder: (context, state) =>
            const superadmin_screens.BranchInfoScreen(),
      ),
      // HR Panel Screens
      GoRoute(
        path: AppRoutesAll.recruitment,
        name: 'recruitment',
        builder: (context, state) => const hr_screens.RecruitmentScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.benefits,
        name: 'benefits',
        builder: (context, state) => const hr_screens3.BenefitsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.hrCompliance,
        name: 'hr-compliance',
        builder: (context, state) => const hr_screens4.HRComplianceScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.exitManagement,
        name: 'exit-management',
        builder: (context, state) => const hr_screens5.ExitManagementScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.performanceEvaluation,
        name: 'performance-evaluation',
        builder: (context, state) =>
            const hr_screens6.PerformanceEvaluationScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.contractManagement,
        name: 'contract-management',
        builder: (context, state) =>
            const hr_screens7.ContractManagementScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.shiftManagement,
        name: 'shift-management',
        builder: (context, state) => const hr_screens8.ShiftManagementScreen(),
      ),
      // Inventory Manager Screens
      GoRoute(
        path: AppRoutesAll.inventoryList,
        name: 'inventory-list',
        builder: (context, state) =>
            const inventory_screens.InventoryListScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.stockCheck,
        name: 'stock-check',
        builder: (context, state) => const inventory_screens.StockCheckScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.purchaseOrders,
        name: 'purchase-orders',
        builder: (context, state) =>
            const inventory_screens.PurchaseOrdersScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.suppliers,
        name: 'suppliers',
        builder: (context, state) =>
            const inventory_screens.SupplierHubScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.assetTracking,
        name: 'asset-tracking',
        builder: (context, state) =>
            const inventory_screens.AssetTrackingScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.requisitions,
        name: 'requisitions',
        builder: (context, state) =>
            const inventory_screens.RequisitionsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.stockAudit,
        name: 'stock-audit',
        builder: (context, state) => const inventory_screens.StockAuditScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.inventoryCategories,
        name: 'inventory-categories',
        builder: (context, state) =>
            const inventory_screens.InventoryCategoriesScreen(),
      ),
      // Receptionist Screens
      GoRoute(
        path: AppRoutesAll.leads,
        name: 'leads',
        builder: (context, state) => const receptionist_screens.LeadsScreen(),
      ),
      GoRoute(
        path: AppRoutesAll.events,
        name: 'events',
        builder: (context, state) => const receptionist_screens2.EventsScreen(),
      ),

      GoRoute(
          path: AppRoutesAll.expenses,
          name: 'expenses',
          builder: (context, state) =>
              const accountant_more_screens.ExpensesScreen()),
      GoRoute(
          path: AppRoutesAll.salaries,
          name: 'salaries',
          builder: (context, state) =>
              const accountant_more_screens.SalariesScreen()),
      GoRoute(
          path: AppRoutesAll.budget,
          name: 'budget',
          builder: (context, state) =>
              const accountant_more_screens.BudgetScreen()),
      GoRoute(
          path: AppRoutesAll.taxation,
          name: 'taxation',
          builder: (context, state) =>
              const accountant_more_screens.TaxationScreen()),
      GoRoute(
          path: AppRoutesAll.paymentHistory,
          name: 'payment-history',
          builder: (context, state) =>
              const accountant_more_screens.PaymentHistoryScreen()),
      GoRoute(
          path: AppRoutesAll.returnBook,
          name: 'return-book',
          builder: (context, state) =>
              const librarian_more_screens.ReturnBookScreen()),
      GoRoute(
          path: AppRoutesAll.catalog,
          name: 'catalog',
          builder: (context, state) =>
              const librarian_more_screens.CatalogScreen()),
      GoRoute(
          path: AppRoutesAll.memberships,
          name: 'memberships',
          builder: (context, state) =>
              const librarian_more_screens.MembershipsScreen()),
      GoRoute(
          path: AppRoutesAll.reservations,
          name: 'reservations',
          builder: (context, state) =>
              const librarian_more_screens.ReservationsScreen()),
      GoRoute(
          path: AppRoutesAll.fineManagement,
          name: 'fine-management',
          builder: (context, state) =>
              const librarian_more_screens.FineManagementScreen()),
      GoRoute(
          path: AppRoutesAll.staffAttendance,
          name: 'staff-attendance',
          builder: (context, state) =>
              const hr_more_screens.StaffAttendanceScreen()),
      GoRoute(
          path: AppRoutesAll.contracts,
          name: 'contracts',
          builder: (context, state) => const hr_more_screens.ContractsScreen()),
      GoRoute(
          path: AppRoutesAll.performance,
          name: 'performance',
          builder: (context, state) =>
              const hr_more_screens.PerformanceScreen()),
      GoRoute(
          path: AppRoutesAll.training,
          name: 'training',
          builder: (context, state) => const hr_more_screens.TrainingScreen()),
      GoRoute(
          path: AppRoutesAll.onboardingStaff,
          name: 'onboarding-staff',
          builder: (context, state) =>
              const hr_more_screens.OnboardingStaffScreen()),
      GoRoute(
          path: AppRoutesAll.itAssets,
          name: 'it-assets',
          builder: (context, state) =>
              const it_support_screens.ITAssetsScreen()),
      GoRoute(
          path: AppRoutesAll.systemStatus,
          name: 'system-status',
          builder: (context, state) =>
              const it_support_screens.SystemStatusScreen()),
      GoRoute(
          path: AppRoutesAll.networkMonitoring,
          name: 'network-monitoring',
          builder: (context, state) =>
              const it_support_screens.NetworkMonitoringScreen()),
      GoRoute(
          path: AppRoutesAll.helpdesk,
          name: 'helpdesk',
          builder: (context, state) =>
              const it_support_screens.HelpdeskScreen()),
      GoRoute(
          path: AppRoutesAll.incidentLogs,
          name: 'incident-logs',
          builder: (context, state) =>
              const it_support_screens.IncidentLogsScreen()),
      GoRoute(
          path: AppRoutesAll.licenses,
          name: 'licenses',
          builder: (context, state) =>
              const it_support_screens.SoftwareLicensesScreen()),
      GoRoute(
          path: AppRoutesAll.maintSchedule,
          name: 'maint-schedule',
          builder: (context, state) =>
              const maintenance_screens.MaintenanceScheduleScreen()),
      GoRoute(
          path: AppRoutesAll.workOrders,
          name: 'work-orders',
          builder: (context, state) =>
              const maintenance_screens.WorkOrdersScreen()),
      GoRoute(
          path: AppRoutesAll.equipmentStatus,
          name: 'equipment-status',
          builder: (context, state) =>
              const maintenance_screens.EquipmentStatusScreen()),
      GoRoute(
          path: AppRoutesAll.maintLogs,
          name: 'maint-logs',
          builder: (context, state) =>
              const maintenance_screens.MaintenanceLogsScreen()),
      GoRoute(
          path: AppRoutesAll.vendors,
          name: 'vendors',
          builder: (context, state) =>
              const maintenance_screens.VendorsScreen()),
      GoRoute(
          path: AppRoutesAll.eventCalendar,
          name: 'event-calendar',
          builder: (context, state) =>
              const event_manager_screens.EventCalendarScreen()),
      GoRoute(
          path: AppRoutesAll.venues,
          name: 'venues',
          builder: (context, state) =>
              const event_manager_screens.VenuesScreen()),
      GoRoute(
          path: AppRoutesAll.eventTasks,
          name: 'event-tasks',
          builder: (context, state) =>
              const event_manager_screens.EventTasksScreen()),
      GoRoute(
          path: AppRoutesAll.guests,
          name: 'guests',
          builder: (context, state) =>
              const event_manager_screens.GuestListScreen()),
      GoRoute(
          path: AppRoutesAll.eventBudget,
          name: 'event-budget',
          builder: (context, state) =>
              const event_manager_screens.EventBudgetScreen()),
      GoRoute(
          path: AppRoutesAll.eventVendors,
          name: 'event-vendors',
          builder: (context, state) =>
              const event_manager_screens.EventVendorsScreen()),
      GoRoute(
          path: AppRoutesAll.complaintDetails,
          name: 'complaint-details',
          builder: (context, state) =>
              const complaint_manager_screens.ComplaintDetailsScreen()),
      GoRoute(
          path: AppRoutesAll.resolved,
          name: 'resolved',
          builder: (context, state) =>
              const complaint_manager_screens.ResolvedComplaintsScreen()),
      GoRoute(
          path: AppRoutesAll.pendingReview,
          name: 'pending-review',
          builder: (context, state) =>
              const complaint_manager_screens.PendingReviewScreen()),
      GoRoute(
          path: AppRoutesAll.investigation,
          name: 'investigation',
          builder: (context, state) =>
              const complaint_manager_screens.InvestigationScreen()),
      GoRoute(
          path: AppRoutesAll.complaintFeedback,
          name: 'complaint-feedback',
          builder: (context, state) =>
              const complaint_manager_screens.ComplaintFeedbackScreen()),
      GoRoute(
          path: AppRoutesAll.tenants,
          name: 'tenants',
          builder: (context, state) =>
              const superadmin_screens.TenantManagementScreen()),
      // New EMIS Feature Routes
      GoRoute(
          path: AppRoutesAll.attendanceTracking,
          name: 'attendance-tracking',
          builder: (context, state) =>
              const academic_support_screens.AttendanceTrackingScreen()),
      GoRoute(
          path: AppRoutesAll.placementTests,
          name: 'placement-tests',
          builder: (context, state) =>
              const academic_support_screens2.PlacementTestsScreen()),
      GoRoute(
          path: AppRoutesAll.academicProgress,
          name: 'academic-progress',
          builder: (context, state) =>
              const academic_support_screens3.AcademicProgressScreen()),
      GoRoute(
          path: AppRoutesAll.courseMaterialManagement,
          name: 'course-material-management',
          builder: (context, state) =>
              const academic_support_screens4.CourseMaterialManagementScreen()),
      GoRoute(
          path: AppRoutesAll.reportCardsGeneration,
          name: 'report-cards-generation',
          builder: (context, state) =>
              const academic_support_screens5.ReportCardsGenerationScreen()),
      GoRoute(
          path: AppRoutesAll.staffRegistration,
          name: 'staff-registration',
          builder: (context, state) =>
              const hr_screens2.StaffRegistrationScreen()),
      GoRoute(
          path: AppRoutesAll.paymentManagement,
          name: 'payment-management',
          builder: (context, state) =>
              const accountant_screens2.PaymentManagementScreen()),
      GoRoute(
          path: AppRoutesAll.feeTypes,
          name: 'fee-types',
          builder: (context, state) =>
              const accountant_fee_types.FeeTypesScreen()),
      GoRoute(
          path: AppRoutesAll.feeStructures,
          name: 'fee-structures',
          builder: (context, state) =>
              const accountant_fee_structures.FeeStructuresScreen()),
      GoRoute(
          path: AppRoutesAll.feeAssignments,
          name: 'fee-assignments',
          builder: (context, state) =>
              const accountant_fee_assign.FeeAssignmentsScreen()),
      GoRoute(
          path: AppRoutesAll.feeStatement,
          name: 'fee-statement',
          builder: (context, state) =>
              const accountant_fee_statement.FeeStatementScreen()),
      GoRoute(
          path: AppRoutesAll.itSupportTickets,
          name: 'it-support-tickets',
          builder: (context, state) =>
              const it_support_screens2.ITSupportPanelScreen()),
      GoRoute(
          path: AppRoutesAll.userManagement,
          name: 'user-management',
          builder: (context, state) =>
              const it_support_screens.UserManagementScreen()),
      GoRoute(
          path: AppRoutesAll.rolePermissionManagement,
          name: 'role-permission-management',
          builder: (context, state) =>
              const it_support_screens.RolePermissionManagementScreen()),
      GoRoute(
          path: AppRoutesAll.databaseBackupRestore,
          name: 'database-backup-restore',
          builder: (context, state) =>
              const it_support_screens.DatabaseBackupRestoreScreen()),
      GoRoute(
          path: AppRoutesAll.securityAudit,
          name: 'security-audit',
          builder: (context, state) =>
              const it_support_screens.SecurityAuditScreen()),
      GoRoute(
          path: AppRoutesAll.communicationEvents,
          name: 'communication-events',
          builder: (context, state) =>
              const event_manager_screens2.CommunicationEventsScreen()),
      GoRoute(
          path: AppRoutesAll.invoiceManagement,
          name: 'invoice-management',
          builder: (context, state) =>
              const accountant_screens3.InvoiceManagementScreen()),
      GoRoute(
          path: AppRoutesAll.announcementManagement,
          name: 'announcement-management',
          builder: (context, state) =>
              const communication_screens.AnnouncementManagementScreen()),
      GoRoute(
          path: AppRoutesAll.complaintManagement,
          name: 'complaint-management',
          builder: (context, state) =>
              const communication_screens2.ComplaintManagementScreen()),
      GoRoute(
          path: AppRoutesAll.feedbackCollection,
          name: 'feedback-collection',
          builder: (context, state) =>
              const communication_screens3.FeedbackCollectionScreen()),
      GoRoute(
          path: AppRoutesAll.salaryManagement,
          name: 'salary-management',
          builder: (context, state) =>
              const finance_screens.SalaryManagementScreen()),
      GoRoute(
          path: AppRoutesAll.expensesTracking,
          name: 'expenses-tracking',
          builder: (context, state) =>
              const finance_screens2.ExpensesTrackingScreen()),
      GoRoute(
          path: AppRoutesAll.financialReports,
          name: 'financial-reports',
          builder: (context, state) =>
              const finance_screens3.FinancialReportsScreen()),
      GoRoute(
          path: AppRoutesAll.budgetManagement,
          name: 'budget-management',
          builder: (context, state) =>
              const finance_screens4.BudgetManagementScreen()),

      // Hostel
      GoRoute(
          path: AppRoutesAll.hostel,
          name: 'hostel',
          builder: (context, state) => const HostelScreen()),
      // Security
      GoRoute(
          path: AppRoutesAll.securityLogs,
          name: 'security-logs',
          builder: (context, state) => const SecurityLogsScreen()),
      // Visitors
      GoRoute(
          path: AppRoutesAll.visitors,
          name: 'visitors',
          builder: (context, state) => const VisitorsScreen()),
      // Notification Preferences
      GoRoute(
          path: AppRoutesAll.notificationPreferences,
          name: 'notification-preferences',
          builder: (context, state) => const NotificationPreferencesScreen()),
      // Transport Management
      GoRoute(
          path: AppRoutesAll.transportVehicles,
          name: 'transport-vehicles',
          builder: (context, state) =>
              const transport_screens.VehiclesScreen()),
      GoRoute(
          path: AppRoutesAll.transportDrivers,
          name: 'transport-drivers',
          builder: (context, state) => const transport_screens.DriversScreen()),
      GoRoute(
          path: AppRoutesAll.transportRoutes,
          name: 'transport-routes',
          builder: (context, state) => const transport_screens.RoutesScreen()),
      GoRoute(
          path: AppRoutesAll.transportSchedule,
          name: 'transport-schedule',
          builder: (context, state) =>
              const transport_screens.ScheduleScreen()),

      // ─────────────────────────────────────────────────────────────────────
      //  DYNAMIC PAGE ROUTES — auto-generated from AllPageDefinitions
      //  Each dynamic page has a route defined in AllPageDefinitions.
      //  We add them as GoRoute entries that render SkeletonScreen.
      // ─────────────────────────────────────────────────────────────────────
      ..._buildDynamicRoutes(),
    ],
  );
});

/// Build GoRoute entries for all dynamic pages from AllPageDefinitions
List<GoRoute> _buildDynamicRoutes() {
  // Import is at top of file: config/all_page_definitions.dart
  // and widgets/dynamic_table_screen.dart
  final routes = <GoRoute>[];
  final seenPaths = <String>{};
  for (final def in AllPageDefinitions.pages) {
    final path = def.route;
    // Avoid duplicate routes
    if (seenPaths.contains(path)) continue;
    seenPaths.add(path);
    routes.add(GoRoute(
      path: path,
      name: def.id,
      builder: (context, state) => skeletonScreenMap[def.id]?.call() ??
          SkeletonScreen(
            title: def.name,
            description: def.description,
            category: def.category,
            icon: def.icon,
            accentColor: def.color,
            tableName: def.tableName,
          ),
    ));
  }
  return routes;
}
