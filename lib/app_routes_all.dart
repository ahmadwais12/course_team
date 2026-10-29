/// Alias for backward compatibility - use AppRoutesAll instead
typedef AppRoutes = AppRoutesAll;

/// ============================================================================
/// ALL ROUTE CONSTANTS - Single source of truth for all route paths
/// ============================================================================
class AppRoutesAll {
  const AppRoutesAll._();

  // Auth & Common
  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';
  static const String otp = '/otp';
  static const String changePassword = '/change-password';
  static const String forgotPassword = '/forgot-password';
  static const String registration = '/registration';
  static const String mobileHome = '/m';

  // Ads Module
  static const String ads = '/ads';
  static const String adsCampaigns = '/ads/campaigns';
  static const String adsCreativeStudio = '/ads/creative-studio';
  static const String googleAds = '/ads/google';
  static const String courseAds = '/ads/courses';

  // Main Panels
  static const String superAdmin = '/super-admin';
  static const String adminPanel = '/admin-panel';
  static const String teacherPanel = '/teacher-panel';
  static const String staffPanel = '/staff-panel';

  // Staff Sub-Panels (11 panels for 16 roles total)
  static const String financeAccountsPanel = '/staff/finance-accounts';
  static const String academicSupportPanel = '/staff/academic-support';
  static const String hrOperationsPanel = '/staff/hr-operations';
  static const String itSystemSupportPanel = '/staff/it-system-support';
  static const String communicationEventsPanel = '/staff/communication-events';
  static const String operationsCenterPanel = '/staff/operations-center';

  // Dedicated Role Panels
  static const String librarianPanel = '/librarian-panel';
  static const String inventoryManagerPanel = '/inventory-manager-panel';
  static const String maintenancePanel = '/maintenance-panel';
  static const String receptionistPanel = '/receptionist-panel';
  static const String complaintManagerPanel = '/complaint-manager-panel';

  // Panel aliases for convenient access (used in panel screens)
  static const String accountantPanel = financeAccountsPanel;
  static const String hrManagerPanel = hrOperationsPanel;
  static const String itSupportPanel = itSystemSupportPanel;
  static const String eventManagerPanel = communicationEventsPanel;

  // Core Modules
  static const String students = '/students';
  static const String payments = '/payments';
  static const String books = '/books';
  static const String attendance = '/attendance';
  static const String grades = '/grades';
  static const String teachers = '/teachers';
  static const String payroll = '/payroll';
  static const String feedback = '/feedback';
  static const String lms = '/lms';
  static const String notifications = '/notifications';
  static const String reports = '/reports';
  static const String settings = '/settings';

  // Operations
  static const String operations = '/operations';
  static const String dispatch = '/dispatch';
  static const String compliance = '/compliance';
  static const String commandCenter = '/command-center';
  static const String analytics = '/analytics';
  static const String loggedInDevices = '/logged-in-devices';
  static const String appUpdate = '/app-update';

  // General
  static const String profile = '/profile';
  static const String helpSupport = '/help-support';
  static const String aboutEmis = '/about-emis';
  static const String admissions = '/admissions';
  static const String studentRegistration = '/student-registration';
  static const String certificateGeneration = '/certificate-generation';
  static const String englishTest = '/english-test';
  static const String feeManagement = '/fee-management';
  static const String staffDirectory = '/staff-directory';
  static const String academicYear = '/academic-year';
  static const String noticeBoard = '/notice-board';
  static const String mySchedule = '/my-schedule';
  static const String chat = '/chat';
  static const String leaveManagement = '/leave-management';
  static const String messages = '/messages';
  static const String exams = '/exams';
  static const String ourStory = '/our-story';

  // Admin Screens
  static const String departments = '/departments';
  static const String programs = '/programs';
  static const String classes = '/classes';
  static const String discounts = '/discounts';
  static const String accountCreation = '/admin/create-account';

  // Teacher Screens
  static const String lessonPlans = '/lesson-plans';
  static const String homework = '/homework';
  static const String examResults = '/exam-results';
  static const String messageParents = '/message-parents';
  static const String studentProgress = '/student-progress';
  static const String studentGroups = '/student-groups';
  static const String myStudents = '/my-students';

  // Super Admin Screens
  static const String branchInfo = '/super-admin/branches';
  static const String adminBranchInfo = '/admin/branch-info';

  // Accountant Screens
  static const String invoices = '/invoices';
  static const String expenses = '/expenses';
  static const String salaries = '/salaries';
  static const String budget = '/budget';
  static const String taxation = '/taxation';
  static const String paymentHistory = '/payment-history';

  // Accountant Fee Engine Screens (Finance module guide)
  static const String feeTypes = '/fee-types';
  static const String feeStructures = '/fee-structures';
  static const String feeAssignments = '/fee-assignments';
  static const String feeStatement = '/fee-statement';

  // Librarian Screens
  static const String issueBook = '/issue-book';
  static const String returnBook = '/return-book';
  static const String catalog = '/catalog';
  static const String memberships = '/memberships';
  static const String reservations = '/reservations';
  static const String fineManagement = '/fine-management';
  static const String digitalLibrary = '/digital-library';
  static const String members = '/members';

  // NEW EMIS FEATURE SCREENS (IMPLEMENTED)
  static const String attendanceTracking = '/attendance-tracking';
  static const String staffRegistration = '/staff-registration';
  static const String paymentManagement = '/payment-management';
  static const String itSupportTickets = '/it-support-tickets';
  static const String communicationEvents = '/communication-events';
  static const String invoiceManagement = '/invoice-management';
  static const String announcementManagement = '/announcement-management';
  static const String salaryManagement = '/salary-management';
  static const String expensesTracking = '/expenses-tracking';

  // HR Manager Screens
  static const String recruitment = '/recruitment';
  static const String staffAttendance = '/staff-attendance';
  static const String contracts = '/contracts';
  static const String performance = '/performance';
  static const String training = '/training';
  static const String onboardingStaff = '/onboarding-staff';
  static const String benefits = '/benefits';
  static const String hrCompliance = '/hr-compliance';
  static const String exitManagement = '/exit-management';

  // Staff Role Dashboard Screens
  static const String staffAccountant = '/staff/accountant';
  static const String staffHR = '/staff/hr';
  static const String staffLibrarian = '/staff/librarian';
  static const String staffFrontDesk = '/staff/front-desk';
  static const String staffInventory = '/staff/inventory';
  static const String staffIT = '/staff/it-support';
  static const String staffMaintenance = '/staff/maintenance';
  static const String staffEvent = '/staff/event';
  static const String staffComplaint = '/staff/complaint';
  static const String staffSecurity = '/staff/security';
  static const String staffFinance = '/staff/finance';
  static const String staffAcademicSupport = '/staff/academic-support';

  // Inventory Manager Screens
  static const String inventoryList = '/inventory-list';
  static const String stockCheck = '/stock-check';
  static const String purchaseOrders = '/purchase-orders';
  static const String suppliers = '/suppliers';
  static const String assetTracking = '/asset-tracking';
  static const String requisitions = '/requisitions';
  static const String stockAudit = '/stock-audit';
  static const String inventoryCategories = '/inventory-categories';

  // Receptionist Screens
  static const String leads = '/leads';
  static const String events = '/events';

  // IT Support Screens
  static const String itAssets = '/it-assets';
  static const String systemStatus = '/system-status';
  static const String networkMonitoring = '/network-monitoring';
  static const String helpdesk = '/helpdesk';
  static const String incidentLogs = '/incident-logs';
  static const String licenses = '/licenses';

  // Maintenance Screens
  static const String maintSchedule = '/maint-schedule';
  static const String workOrders = '/work-orders';
  static const String equipmentStatus = '/equipment-status';
  static const String maintLogs = '/maint-logs';
  static const String vendors = '/vendors';

  // Event Manager Screens
  static const String eventCalendar = '/event-calendar';
  static const String venues = '/venues';
  static const String eventTasks = '/event-tasks';
  static const String guests = '/guests';
  static const String eventBudget = '/event-budget';
  static const String eventVendors = '/event-vendors';

  // Complaint Manager Screens
  static const String complaintDetails = '/complaint-details';
  static const String resolved = '/resolved';
  static const String pendingReview = '/pending-review';
  static const String investigation = '/investigation';
  static const String complaintFeedback = '/complaint-feedback';

  // Super Admin Screens
  static const String systemLogs = '/system-logs';
  static const String apiIntegrations = '/api-integrations';
  static const String tenants = '/tenants';
  static const String platforms = '/super-admin/platforms';
  static const String profiles = '/super-admin/profiles';
  static const String chartOfAccounts = '/super-admin/chart-of-accounts';
  static const String promotions = '/super-admin/promotions';
  static const String auditLog = '/super-admin/audit-log';
  static const String recordHistory = '/super-admin/record-history';
  static const String addresses = '/super-admin/addresses';
  static const String feeTypeTemplates = '/super-admin/fee-types';
  static const String systemSettings = '/super-admin/settings';
  static const String backupRestore = '/super-admin/backup';
  static const String multiLanguage = '/super-admin/language';
  static const String userCreation = '/super-admin/create-user';

  // Hostel
  static const String hostel = '/hostel';

  // Security & Visitors
  static const String securityLogs = '/security-logs';
  static const String visitors = '/visitors';

  // Notification Preferences
  static const String notificationPreferences = '/notification-preferences';

  // Notification Compose
  static const String notificationCompose = '/notification-compose';

  // Notification Detail
  static const String notificationDetail = '/notification-detail/:id';
  static const String notificationDetailBase = '/notification-detail';

  // Academic Support
  static const String placementTests = '/placement-tests';
  static const String academicProgress = '/academic-progress';
  static const String courseMaterialManagement = '/course-material-management';
  static const String reportCardsGeneration = '/report-cards-generation';

  // HR Operations
  static const String performanceEvaluation = '/performance-evaluation';
  static const String contractManagement = '/contract-management';
  static const String shiftManagement = '/shift-management';

  // Finance
  static const String financialReports = '/financial-reports';
  static const String budgetManagement = '/budget-management';

  // IT System Support
  static const String userManagement = '/user-management';
  static const String rolePermissionManagement = '/role-permission-management';
  static const String databaseBackupRestore = '/database-backup-restore';
  static const String securityAudit = '/security-audit';

  // Communication
  static const String complaintManagement = '/complaint-management';
  static const String feedbackCollection = '/feedback-collection';

  // Transport Management
  static const String transportVehicles = '/transport/vehicles';
  static const String transportDrivers = '/transport/drivers';
  static const String transportRoutes = '/transport/routes';
  static const String transportSchedule = '/transport/schedule';

  /// Get all routes as a list for debugging/validation
  static List<String> get allRoutes => [
        // Auth
        home, onboarding, splash, login, signup, dashboard, otp, changePassword,
        forgotPassword, mobileHome,
        // Ads
        ads, adsCampaigns, adsCreativeStudio, googleAds, courseAds,
        // Panels (5 main + 6 staff sub-panels)
         superAdmin, adminPanel, teacherPanel, staffPanel,
        financeAccountsPanel, academicSupportPanel, hrOperationsPanel,
        itSystemSupportPanel, communicationEventsPanel, operationsCenterPanel,
        // Modules
        students, payments, books, attendance, grades, teachers, payroll,
        feedback,
        lms, notifications, reports, settings, operations, dispatch, compliance,
        commandCenter, analytics, loggedInDevices, appUpdate,
        // General
        profile, helpSupport, aboutEmis, admissions, studentRegistration,
        certificateGeneration, englishTest, feeManagement, staffDirectory,
        academicYear, noticeBoard, mySchedule, chat, leaveManagement, messages,
        exams, ourStory,
        // Admin
        departments, programs, classes, discounts, accountCreation,
        // Teacher
        lessonPlans, homework, examResults, messageParents, studentProgress,
        studentGroups, myStudents,
        // Accountant
        invoices, expenses, salaries, budget, taxation, paymentHistory,
        // Librarian
        issueBook, returnBook, catalog, memberships, reservations,
        fineManagement,
        digitalLibrary, members,
        // New Features (Implemented)
        attendanceTracking, staffRegistration, paymentManagement,
        itSupportTickets,
        communicationEvents, invoiceManagement, announcementManagement,
        salaryManagement,
        expensesTracking,
        financialReports, budgetManagement,
        placementTests, academicProgress, courseMaterialManagement,
        reportCardsGeneration,
        // HR
        recruitment, staffAttendance, contracts, performance, training,
        onboardingStaff,
        benefits, hrCompliance, exitManagement,
        performanceEvaluation, contractManagement, shiftManagement,
        // Staff Role Dashboards
        staffAccountant, staffHR, staffLibrarian, staffFrontDesk,
        staffInventory,
        staffIT, staffMaintenance, staffEvent, staffComplaint, staffSecurity,
        staffFinance, staffAcademicSupport,
        // Inventory
        inventoryList, stockCheck, purchaseOrders, suppliers, assetTracking,
        requisitions,
        stockAudit, inventoryCategories,
        // Receptionist
        leads, events,
        // IT Support
        itAssets, systemStatus, networkMonitoring, helpdesk, incidentLogs,
        licenses,
        userManagement, rolePermissionManagement, databaseBackupRestore,
        securityAudit,
        // Maintenance
        maintSchedule, workOrders, equipmentStatus, maintLogs, vendors,
        // Event Manager
        eventCalendar, venues, eventTasks, guests, eventBudget, eventVendors,
        // Complaint
        complaintDetails, resolved, pendingReview, investigation,
        complaintFeedback,
        // Communication
        complaintManagement, feedbackCollection,
        // Super Admin
        systemLogs, apiIntegrations, tenants, platforms, profiles,
        chartOfAccounts, promotions, auditLog, recordHistory, addresses,
        feeTypeTemplates, systemSettings, backupRestore, multiLanguage, userCreation,
        // Hostel
        hostel,
        // Security & Visitors
        securityLogs, visitors,
        // Notification Preferences
        notificationPreferences,
        // Notification Compose
        notificationCompose,
        // Notification Detail
        notificationDetail,
        // Transport
        transportVehicles, transportDrivers, transportRoutes, transportSchedule,
      ];

  /// Get count of all routes
  static int get totalRouteCount => allRoutes.length;
}
