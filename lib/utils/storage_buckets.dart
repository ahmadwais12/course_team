class StorageBuckets {
  StorageBuckets._();

  // ────────────────────────── People ──────────────────────────
  /// Profile/avatar pictures for all roles (profiles.avatar_url)
  static const String avatars = 'avatars';

  /// avatars/profiles
  static const String avatarsProfiles = 'avatars/profiles';

  /// avatars/public
  static const String avatarsPublic = 'avatars/public';

  /// avatars/thumbnails
  static const String avatarsThumbnails = 'avatars/thumbnails';

  /// Profile-related documents (reserved for profile document uploads)
  static const String profiles = 'profiles';

  /// profiles/documents
  static const String profilesDocuments = 'profiles/documents';

  /// profiles/ids
  static const String profilesIds = 'profiles/ids';

  /// profiles/signatures
  static const String profilesSignatures = 'profiles/signatures';

  /// profiles/verifications
  static const String profilesVerifications = 'profiles/verifications';

  /// Student photos & documents (students.photo_url, students.documents JSONB)
  static const String students = 'students';

  /// students/admissions
  static const String studentsAdmissions = 'students/admissions';

  /// students/assignments
  static const String studentsAssignments = 'students/assignments';

  /// students/documents
  static const String studentsDocuments = 'students/documents';

  /// students/medical
  static const String studentsMedical = 'students/medical';

  /// students/photos
  static const String studentsPhotos = 'students/photos';

  /// students/report_cards
  static const String studentsReportCards = 'students/report_cards';

  /// students/transcripts
  static const String studentsTranscripts = 'students/transcripts';

  /// Teacher photos & documents (teachers.photo_url, teachers.documents JSONB)
  static const String teachers = 'teachers';

  /// teachers/certifications
  static const String teachersCertifications = 'teachers/certifications';

  /// teachers/contracts
  static const String teachersContracts = 'teachers/contracts';

  /// teachers/documents
  static const String teachersDocuments = 'teachers/documents';

  /// teachers/evaluations
  static const String teachersEvaluations = 'teachers/evaluations';

  /// teachers/lesson_plans
  static const String teachersLessonPlans = 'teachers/lesson_plans';

  /// teachers/photos
  static const String teachersPhotos = 'teachers/photos';

  /// Staff photos & documents (staff.photo_url, staff.documents JSONB)
  static const String staff = 'staff';

  /// staff/contracts
  static const String staffContracts = 'staff/contracts';

  /// staff/documents
  static const String staffDocuments = 'staff/documents';

  /// staff/evaluations
  static const String staffEvaluations = 'staff/evaluations';

  /// staff/photos
  static const String staffPhotos = 'staff/photos';

  /// Alumni records (reserved for future alumni table)
  static const String alumni = 'alumni';

  /// alumni/documents
  static const String alumniDocuments = 'alumni/documents';

  /// alumni/records
  static const String alumniRecords = 'alumni/records';

  /// alumni/photos
  static const String alumniPhotos = 'alumni/photos';

  // ────────────────────────── Academic ──────────────────────────
  /// Course media — thumbnail, banner, intro video (courses.thumbnail_url, .banner_url, .intro_video_url)
  static const String courses = 'courses';

  /// courses/assignments
  static const String coursesAssignments = 'courses/assignments';

  /// courses/banners
  static const String coursesBanners = 'courses/banners';

  /// courses/materials
  static const String coursesMaterials = 'courses/materials';

  /// courses/quizzes
  static const String coursesQuizzes = 'courses/quizzes';

  /// courses/syllabus
  static const String coursesSyllabus = 'courses/syllabus';

  /// courses/thumbnails
  static const String coursesThumbnails = 'courses/thumbnails';

  /// courses/videos
  static const String coursesVideos = 'courses/videos';

  /// Book covers & digital book files (library/books)
  static const String books = 'books';

  /// books/covers
  static const String booksCovers = 'books/covers';

  /// books/files
  static const String booksFiles = 'books/files';

  /// books/samples
  static const String booksSamples = 'books/samples';

  /// Library resources & materials
  static const String library = 'library';

  /// library/audio
  static const String libraryAudio = 'library/audio';

  /// library/ebooks
  static const String libraryEbooks = 'library/ebooks';

  /// library/journals
  static const String libraryJournals = 'library/journals';

  /// library/magazines
  static const String libraryMagazines = 'library/magazines';

  /// library/research_papers
  static const String libraryResearchPapers = 'library/research_papers';

  /// library/thesis
  static const String libraryThesis = 'library/thesis';

  /// library/video
  static const String libraryVideo = 'library/video';

  /// Student assignment submissions (assignments.submission_url)
  static const String assignments = 'assignments';

  /// assignments/attachments
  static const String assignmentsAttachments = 'assignments/attachments';

  /// assignments/graded
  static const String assignmentsGraded = 'assignments/graded';

  /// assignments/submissions
  static const String assignmentsSubmissions = 'assignments/submissions';

  /// Exam papers & related files (exams table)
  static const String exams = 'exams';

  /// exams/answer_sheets
  static const String examsAnswerSheets = 'exams/answer_sheets';

  /// exams/question_papers
  static const String examsQuestionPapers = 'exams/question_papers';

  /// exams/results
  static const String examsResults = 'exams/results';

  /// exams/timetables
  static const String examsTimetables = 'exams/timetables';

  /// Grade reports & transcripts
  static const String grades = 'grades';

  /// graders/grade_sheets
  static const String gradersGradeSheets = 'graders/grade_sheets';

  /// graders/report_cards
  static const String gradersReportCards = 'graders/report_cards';

  /// graders/transcripts
  static const String gradersTranscripts = 'graders/transcripts';

  // ────────────────────────── Financial ──────────────────────────
  /// Payment receipts (payments.receipt_url, expenses.receipt_url, petty_cash_entries.receipt_image_url)
  static const String receipts = 'receipts';

  /// receipts/advance
  static const String receiptsAdvance = 'receipts/advance';

  /// receipts/deposits
  static const String receiptsDeposits = 'receipts/deposits';

  /// receipts/payments
  static const String receiptsPayments = 'receipts/payments';

  /// receipts/refunds
  static const String receiptsRefunds = 'receipts/refunds';

  /// Invoice PDFs & related documents
  static const String invoices = 'invoices';

  /// invoices/credit_notes
  static const String invoicesCreditNotes = 'invoices/credit_notes';

  /// invoices/overdue
  static const String invoicesOverdue = 'invoices/overdue';

  /// invoices/paid
  static const String invoicesPaid = 'invoices/paid';

  /// invoices/sent
  static const String invoicesSent = 'invoices/sent';

  /// Financial reports & general finance documents
  static const String finance = 'finance';

  /// finance/assets
  static const String financeAssets = 'finance/assets';

  /// finance/audits
  static const String financeAudits = 'finance/audits';

  /// finance/budgets
  static const String financeBudgets = 'finance/budgets';

  /// finance/expenses
  static const String financeExpenses = 'finance/expenses';

  /// finance/statements
  static const String financeStatements = 'finance/statements';

  /// finance/tax
  static const String financeTax = 'finance/tax';

  /// Payroll payslips (salaries.payslip_url) & payroll run documents
  static const String payroll = 'payroll';

  /// payroll/bonuses
  static const String payrollBonuses = 'payroll/bonuses';

  /// payroll/deductions
  static const String payrollDeductions = 'payroll/deductions';

  /// payroll/reports
  static const String payrollReports = 'payroll/reports';

  /// payroll/salary_slips
  static const String payrollSalarySlips = 'payroll/salary_slips';

  // ────────────────────────── HR ──────────────────────────
  /// HR documents — contracts, letters, employee files
  static const String hr = 'hr';

  /// hr/attendance_reports
  static const String hrAttendanceReports = 'hr/attendance_reports';

  /// hr/compliance
  static const String hrCompliance = 'hr/compliance';

  /// hr/contracts
  static const String hrContracts = 'hr/contracts';

  /// hr/disciplinary
  static const String hrDisciplinary = 'hr/disciplinary';

  /// hr/employee_records
  static const String hrEmployeeRecords = 'hr/employee_records';

  /// hr/policies
  static const String hrPolicies = 'hr/policies';

  /// Recruitment files — resumes, applications (recruitment table)
  static const String recruitment = 'recruitment';

  /// recruitment/interviews
  static const String recruitmentInterviews = 'recruitment/interviews';

  /// recruitment/job_postings
  static const String recruitmentJobPostings = 'recruitment/job_postings';

  /// recruitment/offers
  static const String recruitmentOffers = 'recruitment/offers';

  /// recruitment/onboarding
  static const String recruitmentOnboarding = 'recruitment/onboarding';

  /// recruitment/resumes
  static const String recruitmentResumes = 'recruitment/resumes';

  /// Training materials & certificates
  static const String trainings = 'trainings';

  /// trainings/certifications
  static const String trainingsCertifications = 'trainings/certifications';

  /// trainings/evaluations
  static const String trainingsEvaluations = 'trainings/evaluations';

  /// trainings/materials
  static const String trainingsMaterials = 'trainings/materials';

  /// trainings/recordings
  static const String trainingsRecordings = 'trainings/recordings';

  // ────────────────────────── Operations ──────────────────────────
  /// Transport route maps, vehicle images
  static const String transport = 'transport';

  /// Hostel room photos, floor plans
  static const String hostel = 'hostel';

  /// Inventory item images
  static const String inventory = 'inventory';

  /// inventory/assets
  static const String inventoryAssets = 'inventory/assets';

  /// inventory/damages
  static const String inventoryDamages = 'inventory/damages';

  /// inventory/items
  static const String inventoryItems = 'inventory/items';

  /// inventory/receipts
  static const String inventoryReceipts = 'inventory/receipts';

  /// Facility photos & maintenance documents
  static const String facilities = 'facilities';

  /// facilities/floor_plans
  static const String facilitiesFloorPlans = 'facilities/floor_plans';

  /// facilities/inspections
  static const String facilitiesInspections = 'facilities/inspections';

  /// facilities/maintenance
  static const String facilitiesMaintenance = 'facilities/maintenance';

  /// IT ticket attachments (support_tickets table)
  static const String itSupport = 'it_support';

  /// it_support/devices
  static const String itSupportDevices = 'it_support/devices';

  /// it_support/logs
  static const String itSupportLogs = 'it_support/logs';

  /// it_support/screenshots
  static const String itSupportScreenshots = 'it_support/screenshots';

  /// it_support/tickets
  static const String itSupportTickets = 'it_support/tickets';

  // ────────────────────────── Communication ──────────────────────────
  /// Announcement attachments & banners (announcements.attachment_url, .banner_image_url)
  static const String announcements = 'announcements';

  /// announcements/attachments
  static const String announcementsAttachments = 'announcements/attachments';

  /// announcements/banners
  static const String announcementsBanners = 'announcements/banners';

  /// announcements/images
  static const String announcementsImages = 'announcements/images';

  /// Event images & posters (events.image_url)
  static const String events = 'events';

  /// events/banners
  static const String eventsBanners = 'events/banners';

  /// events/materials
  static const String eventsMaterials = 'events/materials';

  /// events/photos
  static const String eventsPhotos = 'events/photos';

  /// events/videos
  static const String eventsVideos = 'events/videos';

  /// Complaint attachments (complaints table)
  static const String complaints = 'complaints';

  /// complaints/evidence
  static const String complaintsEvidence = 'complaints/evidence';

  /// complaints/feedback
  static const String complaintsFeedback = 'complaints/feedback';

  /// complaints/resolutions
  static const String complaintsResolutions = 'complaints/resolutions';

  // ───────────────────── Documents & Certificates ─────────────────────
  /// General documents (various tables)
  static const String documents = 'documents';

  /// documents/agreements
  static const String documentsAgreements = 'documents/agreements';

  /// documents/contracts
  static const String documentsContracts = 'documents/contracts';

  /// documents/legal
  static const String documentsLegal = 'documents/legal';

  /// documents/policies
  static const String documentsPolicies = 'documents/policies';

  /// documents/reports
  static const String documentsReports = 'documents/reports';

  /// documents/templates
  static const String documentsTemplates = 'documents/templates';

  /// Student/teacher certificates (students.certificate_url)
  static const String certificates = 'certificates';

  /// certificates/issued
  static const String certificatesIssued = 'certificates/issued';

  /// certificates/templates
  static const String certificatesTemplates = 'certificates/templates';

  /// certificates/verifications
  static const String certificatesVerifications = 'certificates/verifications';

  /// Generated reports (reports.file_url)
  static const String reports = 'reports';

  /// reports/academic
  static const String reportsAcademic = 'reports/academic';

  /// reports/custom
  static const String reportsCustom = 'reports/custom';

  /// reports/exports
  static const String reportsExports = 'reports/exports';

  /// reports/financial
  static const String reportsFinancial = 'reports/financial';

  /// reports/hr
  static const String reportsHr = 'reports/hr';

  /// reports/operations
  static const String reportsOperations = 'reports/operations';

  // ─────────────────────── Media & Branding ───────────────────────
  /// Platform, tenant & branch logos, brand assets.
  /// Top-level folders (created lazily on first upload):
  ///   branding/tenants/ts.ext   -> tenants.logo_url
  ///   branding/branches/ts.ext  -> branches.logo_url
  ///   branding/logos/ (icons/letterheads/social_media/themes) are schema-seeded
  static const String branding = 'branding';

  /// branding/icons
  static const String brandingIcons = 'branding/icons';

  /// branding/letterheads
  static const String brandingLetterheads = 'branding/letterheads';

  /// branding/logos
  static const String brandingLogos = 'branding/logos';

  /// branding/social_media
  static const String brandingSocialMedia = 'branding/social_media';

  /// branding/themes
  static const String brandingThemes = 'branding/themes';

  /// Sports event photos & media
  static const String sports = 'sports';

  /// Medical records & health documents
  static const String medical = 'medical';

  // ────────────────────────── System ──────────────────────────
  /// Database & system backups
  static const String backups = 'backups';

  /// backups/daily
  static const String backupsDaily = 'backups/daily';

  /// backups/manual
  static const String backupsManual = 'backups/manual';

  /// backups/monthly
  static const String backupsMonthly = 'backups/monthly';

  /// backups/weekly
  static const String backupsWeekly = 'backups/weekly';

  /// backups/yearly
  static const String backupsYearly = 'backups/yearly';

  /// Temporary files (cleaned periodically)
  static const String temp = 'temp';

  /// temp/exports
  static const String tempExports = 'temp/exports';

  /// temp/imports
  static const String tempImports = 'temp/imports';

  /// temp/processing
  static const String tempProcessing = 'temp/processing';

  /// temp/uploads
  static const String tempUploads = 'temp/uploads';

  // ─────────────────────────── Chat ───────────────────────────
  /// Chat file attachments (images, documents shared in conversations)
  static const String chatUploads = 'chat_uploads';
}
