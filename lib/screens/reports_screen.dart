import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

import 'package:course_emis/services/export_service.dart';
import 'package:course_emis/widgets/insight_ui.dart';
import 'package:course_emis/widgets/glass_card.dart';
import 'package:course_emis/widgets/modern_ui.dart';
import 'package:course_emis/widgets/fade_slide_animation.dart';
import 'package:course_emis/widgets/scale_animation.dart';

// -----------------------------------------------------------------------------
//  Period filter
// -----------------------------------------------------------------------------

enum ReportPeriod { daily, weekly, monthly, yearly }

// -----------------------------------------------------------------------------
//  Report type definitions
// -----------------------------------------------------------------------------

enum ReportType {
  attendance(Icons.fact_check_outlined, 'Attendance', 'Attendance records & hourly trends', Color(0xFF6366F1)),
  grades(Icons.grade_outlined, 'Grades', 'Student grade summaries & distribution', Color(0xFF10B981)),
  payments(Icons.payments_outlined, 'Payments', 'Fee collection & transaction flow', Color(0xFFF59E0B)),
  students(Icons.school_outlined, 'Students', 'Enrollment & demographics', Color(0xFF8B5CF6)),
  teachers(Icons.person_outlined, 'Teachers', 'Teacher roster & assignments', Color(0xFFEC4899)),
  staff(Icons.groups_outlined, 'Staff', 'Staff directory & role distribution', Color(0xFF06B6D4)),
  fee(Icons.receipt_long_outlined, 'Fee Management', 'Fee structures & dues status', Color(0xFFF97316)),
  payroll(Icons.money_off_outlined, 'Payroll', 'Salary & payroll disbursement', Color(0xFF14B8A6)),
  exams(Icons.assignment_outlined, 'Exams', 'Exam schedules & results', Color(0xFFA855F7)),
  leaves(Icons.event_busy_outlined, 'Leaves', 'Employee & student leave trends', Color(0xFFE11D48)),
  tickets(Icons.support_agent_outlined, 'Support Tickets', 'IT & support ticket lifecycle', Color(0xFF0EA5E9)),
  library(Icons.local_library_outlined, 'Library', 'Book issues & inventory flow', Color(0xFF84CC16));

  final IconData icon;
  final String label;
  final String description;
  final Color color;

  const ReportType(this.icon, this.label, this.description, this.color);
}

// -----------------------------------------------------------------------------
//  Data models
// -----------------------------------------------------------------------------

class ReportData {
  final ReportType type;
  final List<String> headers;
  final List<List<String>> rows;
  final List<SummaryMetric> metrics;
  final List<InsightPoint> chartPoints;
  final List<InsightSegment> segments;
  final List<InsightFlowStep> flowSteps;

  ReportData({
    required this.type,
    required this.headers,
    required this.rows,
    this.metrics = const [],
    this.chartPoints = const [],
    this.segments = const [],
    this.flowSteps = const [],
  });

  bool get isEmpty => rows.isEmpty;
}

class SummaryMetric {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const SummaryMetric(this.label, this.value, this.icon, this.color);
}

// -----------------------------------------------------------------------------
//  Main screen
// -----------------------------------------------------------------------------

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportType? _selectedType;
  ReportPeriod _selectedPeriod = ReportPeriod.monthly;
  bool _loading = false;
  ReportData? _reportData;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  int _totalRecords = 0;

  DateTime _periodStart(ReportPeriod p) {
    final now = DateTime.now();
    switch (p) {
      case ReportPeriod.daily: return DateTime(now.year, now.month, now.day);
      case ReportPeriod.weekly: return now.subtract(const Duration(days: 7));
      case ReportPeriod.monthly: return DateTime(now.year, now.month, 1);
      case ReportPeriod.yearly: return DateTime(now.year, 1, 1);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Data fetching ---

  Future<void> _loadReport(ReportType type, [ReportPeriod? period]) async {
    final p = period ?? _selectedPeriod;
    setState(() {
      _selectedType = type;
      _selectedPeriod = p;
      _loading = true;
      _reportData = null;
    });

    try {
      final sb = Supabase.instance.client;
      final data = await _fetchReportData(sb, type, p);
      if (mounted) {
        setState(() {
          _reportData = data;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[ReportsScreen] Error loading ${type.label}: $e');
      if (mounted) {
        setState(() {
          _reportData = ReportData(
            type: type,
            headers: ['Error'],
            rows: [['Failed to load data: $e']],
          );
          _loading = false;
        });
      }
    }
  }

  Future<ReportData> _fetchReportData(SupabaseClient sb, ReportType type, ReportPeriod period) async {
    final since = _periodStart(period).toIso8601String();
    switch (type) {
      case ReportType.attendance:
        final raw = await sb.from('attendance').select().gte('date', since).order('date', ascending: false).limit(100);
        final list = List<Map<String, dynamic>>.from(raw);
        final present = list.where((a) => a['status']?.toString() == 'present').length;
        final absent = list.where((a) => a['status']?.toString() == 'absent').length;
        final late = list.where((a) => a['status']?.toString() == 'late').length;
        _totalRecords = list.length;

        // Weekly chart points
        final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        final weeklyPoints = weekDays.map((day) {
          final count = list.where((a) {
            final d = a['date']?.toString() ?? '';
            final parsed = DateTime.tryParse(d);
            return d.length >= 10 && parsed != null && parsed.weekday == weekDays.indexOf(day) + 1;
          }).length;
          return InsightPoint(day, count.toDouble());
        }).toList();

        return ReportData(
          type: type,
          headers: ['Date', 'Student/Staff', 'Class', 'Status', 'Remarks'],
          rows: list.map((r) => [
            (r['date']?.toString() ?? '').length >= 10 ? r['date'].toString().substring(0, 10) : '-',
            '${r['student_name'] ?? r['staff_name'] ?? '-'}',
            r['class']?.toString() ?? '-',
            r['status']?.toString() ?? '-',
            r['remarks']?.toString() ?? '',
          ]).toList(),
          metrics: [
            SummaryMetric('Present', '$present', Icons.check_circle, Colors.green),
            SummaryMetric('Absent', '$absent', Icons.cancel, Colors.red),
            SummaryMetric('Late', '$late', Icons.access_time, Colors.orange),
            SummaryMetric('Total', '${list.length}', Icons.people, Colors.blue),
          ],
          chartPoints: weeklyPoints,
          segments: [
            InsightSegment(label: 'Present', value: present.toDouble(), color: Colors.green),
            InsightSegment(label: 'Absent', value: absent.toDouble(), color: Colors.red),
            InsightSegment(label: 'Late', value: late.toDouble(), color: Colors.orange),
          ],
          flowSteps: [
            InsightFlowStep(title: 'Mark', subtitle: 'Capture presence during each class.', icon: Icons.edit_calendar_outlined),
            InsightFlowStep(title: 'Review', subtitle: 'Identify late or absent students.', icon: Icons.rule_folder_outlined),
            InsightFlowStep(title: 'Notify', subtitle: 'Alert students or guardians.', icon: Icons.notifications_active_outlined),
            InsightFlowStep(title: 'Intervene', subtitle: 'Follow up before engagement drops.', icon: Icons.support_agent_outlined),
          ],
        );

      case ReportType.grades:
        final raw = await sb.from('grades').select().gte('created_at', since).order('created_at', ascending: false).limit(100);
        final list = List<Map<String, dynamic>>.from(raw);
        final avg = list.isEmpty ? 0 : list.fold<int>(0, (s, g) => s + ((g['score'] ?? 0) as num).toInt()) ~/ list.length;
        _totalRecords = list.length;

        final subjects = <String, List<int>>{};
        for (final g in list) {
          final subj = g['subject']?.toString() ?? 'General';
          subjects.putIfAbsent(subj, () => []);
          subjects[subj]!.add(((g['score'] ?? 0) as num).toInt());
        }
        final segs = subjects.entries.map((e) {
          final a = e.value.isEmpty ? 0 : e.value.reduce((a, b) => a + b) ~/ e.value.length;
          return InsightSegment(label: e.key, value: a.toDouble(), color: Colors.primaries[e.key.hashCode % Colors.primaries.length]);
        }).toList();

        final chartPoints = list.take(7).toList().asMap().entries.map((e) {
          return InsightPoint('T${e.key + 1}', ((e.value['score'] ?? 0) as num).toDouble());
        }).toList();

        return ReportData(
          type: type,
          headers: ['Student', 'Subject', 'Score', 'Grade', 'Term'],
          rows: list.map((r) => [
            r['student_name']?.toString() ?? '-',
            r['subject']?.toString() ?? '-',
            '${r['score'] ?? 0}',
            r['grade']?.toString() ?? '-',
            r['term']?.toString() ?? '-',
          ]).toList(),
          metrics: [
            SummaryMetric('Average', '$avg%', Icons.school, Colors.blue),
            SummaryMetric('Records', '${list.length}', Icons.description, Colors.indigo),
            SummaryMetric('A+ Students', '${list.where((g) => ((g['score'] ?? 0) as num) >= 90).length}', Icons.star, Colors.amber),
          ],
          chartPoints: chartPoints,
          segments: segs,
          flowSteps: [
            InsightFlowStep(title: 'Assess', subtitle: 'Conduct exams and evaluate.', icon: Icons.assignment_outlined),
            InsightFlowStep(title: 'Grade', subtitle: 'Score and assign letter grades.', icon: Icons.grade_outlined),
            InsightFlowStep(title: 'Analyze', subtitle: 'Identify at-risk students.', icon: Icons.analytics_outlined),
            InsightFlowStep(title: 'Improve', subtitle: 'Tailor instruction accordingly.', icon: Icons.trending_up_outlined),
          ],
        );

      case ReportType.payments:
        final raw = await sb.from('payments').select().gte('date', since).order('date', ascending: false).limit(100);
        final list = List<Map<String, dynamic>>.from(raw);
        final total = list.fold<double>(0, (s, p) => s + ((p['amount'] ?? 0) as num).toDouble());
        final collected = list.where((p) => p['status']?.toString().toLowerCase() == 'paid').fold<double>(0, (s, p) => s + ((p['amount'] ?? 0) as num).toDouble());
        final overdue = list.where((p) => p['status']?.toString().toLowerCase() == 'overdue').fold<double>(0, (s, p) => s + ((p['amount'] ?? 0) as num).toDouble());
        _totalRecords = list.length;

        final paidCount = list.where((p) => p['status']?.toString().toLowerCase() == 'paid').length;
        final pendingCount = list.where((p) => p['status']?.toString().toLowerCase() == 'pending').length;
        final overdueCount = list.where((p) => p['status']?.toString().toLowerCase() == 'overdue').length;

        return ReportData(
          type: type,
          headers: ['Date', 'Student', 'Amount', 'Method', 'Status'],
          rows: list.map((r) => [
            (r['date']?.toString() ?? '').length >= 10 ? r['date'].toString().substring(0, 10) : '-',
            r['student_name']?.toString() ?? '-',
            'PKR ${r['amount'] ?? 0}',
            r['method']?.toString() ?? '-',
            r['status']?.toString() ?? '-',
          ]).toList(),
          metrics: [
            SummaryMetric('Total', 'PKR ${total.toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.blue),
            SummaryMetric('Collected', 'PKR ${collected.toStringAsFixed(0)}', Icons.check_circle, Colors.green),
            SummaryMetric('Overdue', 'PKR ${overdue.toStringAsFixed(0)}', Icons.warning, Colors.red),
            SummaryMetric('Transactions', '${list.length}', Icons.receipt, Colors.indigo),
          ],
          segments: [
            InsightSegment(label: 'Paid', value: paidCount.toDouble(), color: Colors.green),
            InsightSegment(label: 'Pending', value: pendingCount.toDouble(), color: Colors.orange),
            InsightSegment(label: 'Overdue', value: overdueCount.toDouble(), color: Colors.red),
          ],
          flowSteps: [
            InsightFlowStep(title: 'Issue', subtitle: 'Generate invoices for the cycle.', icon: Icons.receipt_long_outlined),
            InsightFlowStep(title: 'Remind', subtitle: 'Trigger due-date reminders.', icon: Icons.notifications_outlined),
            InsightFlowStep(title: 'Collect', subtitle: 'Record payment method & amount.', icon: Icons.payments_outlined),
            InsightFlowStep(title: 'Reconcile', subtitle: 'Match ledger and close exceptions.', icon: Icons.fact_check_outlined),
          ],
        );

      case ReportType.students:
        final raw = await sb.from('users').select().eq('role', 'student').gte('created_at', since).order('created_at', ascending: false).limit(100);
        final list = List<Map<String, dynamic>>.from(raw);
        final active = list.where((s) => s['is_active'] == true).length;
        _totalRecords = list.length;

        return ReportData(
          type: type,
          headers: ['Name', 'Email', 'Phone', 'Status', 'Created'],
          rows: list.map((r) => [
            r['full_name']?.toString() ?? '-',
            r['email']?.toString() ?? '-',
            r['phone']?.toString() ?? '-',
            r['is_active'] == true ? 'Active' : 'Inactive',
            (r['created_at']?.toString() ?? '').length >= 10 ? r['created_at'].toString().substring(0, 10) : '-',
          ]).toList(),
          metrics: [
            SummaryMetric('Total', '${list.length}', Icons.school, Colors.purple),
            SummaryMetric('Active', '$active', Icons.check_circle, Colors.green),
            SummaryMetric('Inactive', '${list.length - active}', Icons.cancel, Colors.grey),
          ],
          segments: [
            InsightSegment(label: 'Active', value: active.toDouble(), color: Colors.green),
            InsightSegment(label: 'Inactive', value: (list.length - active).toDouble(), color: Colors.grey),
          ],
        );

      case ReportType.teachers:
        final raw = await sb.from('users').select().eq('role', 'teacher').gte('created_at', since).order('created_at', ascending: false).limit(100);
        final list = List<Map<String, dynamic>>.from(raw);
        _totalRecords = list.length;
        final depts = <String, int>{};
        for (final t in list) {
          final d = t['department']?.toString() ?? 'Other';
          depts[d] = (depts[d] ?? 0) + 1;
        }
        final deptSegs = depts.entries.map((e) {
          return InsightSegment(label: e.key, value: e.value.toDouble(), color: Colors.primaries[e.key.hashCode % Colors.primaries.length]);
        }).toList();

        return ReportData(
          type: type,
          headers: ['Name', 'Email', 'Phone', 'Department', 'Status'],
          rows: list.map((r) => [
            r['full_name']?.toString() ?? '-',
            r['email']?.toString() ?? '-',
            r['phone']?.toString() ?? '-',
            r['department']?.toString() ?? '-',
            r['is_active'] == true ? 'Active' : 'Inactive',
          ]).toList(),
          metrics: [
            SummaryMetric('Total', '${list.length}', Icons.person, Colors.pink),
            SummaryMetric('Active', '${list.where((s) => s['is_active'] == true).length}', Icons.check_circle, Colors.green),
            SummaryMetric('Departments', '${depts.length}', Icons.business, Colors.blue),
          ],
          segments: deptSegs,
        );

      case ReportType.staff:
        final raw = await sb.from('users').select().not('role', 'in', '("student","teacher","guardian")').gte('created_at', since).order('created_at', ascending: false).limit(100);
        final list = List<Map<String, dynamic>>.from(raw);
        _totalRecords = list.length;
        final roles = <String, int>{};
        for (final s in list) {
          final r = s['role']?.toString() ?? 'unknown';
          roles[r] = (roles[r] ?? 0) + 1;
        }
        final roleSegs = roles.entries.map((e) {
          return InsightSegment(label: e.key.replaceAll('_', ' ').toUpperCase(), value: e.value.toDouble(), color: Colors.primaries[e.key.hashCode % Colors.primaries.length]);
        }).toList();

        return ReportData(
          type: type,
          headers: ['Name', 'Role', 'Email', 'Phone', 'Status'],
          rows: list.map((r) => [
            r['full_name']?.toString() ?? '-',
            (r['role'] as String? ?? '-').replaceAll('_', ' ').toUpperCase(),
            r['email']?.toString() ?? '-',
            r['phone']?.toString() ?? '-',
            r['is_active'] == true ? 'Active' : 'Inactive',
          ]).toList(),
          metrics: [
            SummaryMetric('Total', '${list.length}', Icons.groups, Colors.cyan),
            SummaryMetric('Roles', '${roles.length}', Icons.badge, Colors.blue),
            SummaryMetric('Active', '${list.where((s) => s['is_active'] == true).length}', Icons.check_circle, Colors.green),
          ],
          segments: roleSegs,
        );

      case ReportType.fee:
        final raw = await sb.from('fee_management').select().gte('created_at', since).order('created_at', ascending: false).limit(100);
        final list = List<Map<String, dynamic>>.from(raw);
        _totalRecords = list.length;
        return ReportData(
          type: type,
          headers: ['Student', 'Fee Type', 'Amount', 'Due Date', 'Status'],
          rows: list.map((r) => [
            r['student_name']?.toString() ?? '-',
            r['fee_type']?.toString() ?? '-',
            'PKR ${r['amount'] ?? 0}',
            (r['due_date']?.toString() ?? '').length >= 10 ? r['due_date'].toString().substring(0, 10) : '-',
            r['status']?.toString() ?? '-',
          ]).toList(),
          metrics: [
            SummaryMetric('Records', '${list.length}', Icons.receipt_long, Colors.orange),
            SummaryMetric('Due', '${list.where((f) => f['status']?.toString().toLowerCase() == 'due').length}', Icons.pending, Colors.red),
            SummaryMetric('Paid', '${list.where((f) => f['status']?.toString().toLowerCase() == 'paid').length}', Icons.check_circle, Colors.green),
          ],
          flowSteps: [
            InsightFlowStep(title: 'Define', subtitle: 'Set fee types and amounts.', icon: Icons.settings_outlined),
            InsightFlowStep(title: 'Assign', subtitle: 'Assign fees to students/classes.', icon: Icons.person_add_outlined),
            InsightFlowStep(title: 'Collect', subtitle: 'Track payment collection.', icon: Icons.payments_outlined),
            InsightFlowStep(title: 'Report', subtitle: 'Generate collection reports.', icon: Icons.bar_chart_outlined),
          ],
        );

      case ReportType.payroll:
        final raw = await sb.from('payroll').select().gte('created_at', since).order('created_at', ascending: false).limit(100);
        final list = List<Map<String, dynamic>>.from(raw);
        final totalSalary = list.fold<double>(0, (s, p) => s + ((p['amount'] ?? 0) as num).toDouble());
        _totalRecords = list.length;
        return ReportData(
          type: type,
          headers: ['Staff', 'Month', 'Amount', 'Status', 'Paid Date'],
          rows: list.map((r) => [
            r['staff_name']?.toString() ?? '-',
            r['month']?.toString() ?? '-',
            'PKR ${r['amount'] ?? 0}',
            r['status']?.toString() ?? '-',
            (r['paid_date']?.toString() ?? '').length >= 10 ? r['paid_date'].toString().substring(0, 10) : '-',
          ]).toList(),
          metrics: [
            SummaryMetric('Total Paid', 'PKR ${totalSalary.toStringAsFixed(0)}', Icons.money, Colors.teal),
            SummaryMetric('Records', '${list.length}', Icons.receipt, Colors.blue),
            SummaryMetric('Pending', '${list.where((p) => p['status']?.toString().toLowerCase() == 'pending').length}', Icons.pending, Colors.orange),
          ],
          flowSteps: [
            InsightFlowStep(title: 'Calculate', subtitle: 'Compute salaries and deductions.', icon: Icons.calculate_outlined),
            InsightFlowStep(title: 'Approve', subtitle: 'Review and approve payroll.', icon: Icons.rule_outlined),
            InsightFlowStep(title: 'Disburse', subtitle: 'Process payments to staff.', icon: Icons.payments_outlined),
            InsightFlowStep(title: 'Record', subtitle: 'Log transactions for audit.', icon: Icons.fact_check_outlined),
          ],
        );

      case ReportType.exams:
        final raw = await sb.from('exams').select().gte('date', since).order('date', ascending: false).limit(100);
        final list = List<Map<String, dynamic>>.from(raw);
        _totalRecords = list.length;
        return ReportData(
          type: type,
          headers: ['Title', 'Subject', 'Date', 'Type', 'Status'],
          rows: list.map((r) => [
            r['title']?.toString() ?? '-',
            r['subject']?.toString() ?? '-',
            (r['date']?.toString() ?? '').length >= 10 ? r['date'].toString().substring(0, 10) : '-',
            r['type']?.toString() ?? '-',
            r['status']?.toString() ?? '-',
          ]).toList(),
          metrics: [
            SummaryMetric('Total', '${list.length}', Icons.assignment, Colors.purple),
            SummaryMetric('Upcoming', '${list.where((e) => e['status']?.toString().toLowerCase() == 'upcoming').length}', Icons.schedule, Colors.blue),
            SummaryMetric('Completed', '${list.where((e) => e['status']?.toString().toLowerCase() == 'completed').length}', Icons.check_circle, Colors.green),
          ],
          flowSteps: [
            InsightFlowStep(title: 'Plan', subtitle: 'Schedule exams and allocate rooms.', icon: Icons.calendar_month_outlined),
            InsightFlowStep(title: 'Conduct', subtitle: 'Administer exams securely.', icon: Icons.menu_book_outlined),
            InsightFlowStep(title: 'Evaluate', subtitle: 'Grade and compute results.', icon: Icons.grade_outlined),
            InsightFlowStep(title: 'Release', subtitle: 'Publish results to students.', icon: Icons.publish_outlined),
          ],
        );

      case ReportType.leaves:
        final raw = await sb.from('employee_leaves').select().gte('created_at', since).order('created_at', ascending: false).limit(100);
        final list = List<Map<String, dynamic>>.from(raw);
        _totalRecords = list.length;
        return ReportData(
          type: type,
          headers: ['Employee', 'Type', 'From', 'To', 'Status'],
          rows: list.map((r) => [
            r['employee_name']?.toString() ?? '-',
            r['leave_type']?.toString() ?? '-',
            (r['start_date']?.toString() ?? '').length >= 10 ? r['start_date'].toString().substring(0, 10) : '-',
            (r['end_date']?.toString() ?? '').length >= 10 ? r['end_date'].toString().substring(0, 10) : '-',
            r['status']?.toString() ?? '-',
          ]).toList(),
          metrics: [
            SummaryMetric('Total', '${list.length}', Icons.event_busy, Colors.red),
            SummaryMetric('Approved', '${list.where((l) => l['status']?.toString().toLowerCase() == 'approved').length}', Icons.check_circle, Colors.green),
            SummaryMetric('Pending', '${list.where((l) => l['status']?.toString().toLowerCase() == 'pending').length}', Icons.pending, Colors.orange),
          ],
          flowSteps: [
            InsightFlowStep(title: 'Apply', subtitle: 'Employee submits leave request.', icon: Icons.edit_note_outlined),
            InsightFlowStep(title: 'Review', subtitle: 'Manager reviews the application.', icon: Icons.visibility_outlined),
            InsightFlowStep(title: 'Approve', subtitle: 'Approve or decline the leave.', icon: Icons.thumb_up_outlined),
            InsightFlowStep(title: 'Track', subtitle: 'Monitor leave balances & usage.', icon: Icons.track_changes_outlined),
          ],
        );

      case ReportType.tickets:
        final raw = await sb.from('support_tickets').select().gte('created_at', since).order('created_at', ascending: false).limit(100);
        final list = List<Map<String, dynamic>>.from(raw);
        _totalRecords = list.length;
        return ReportData(
          type: type,
          headers: ['Subject', 'Priority', 'Status', 'Assigned To', 'Created'],
          rows: list.map((r) => [
            r['subject']?.toString() ?? '-',
            r['priority']?.toString() ?? '-',
            r['status']?.toString() ?? '-',
            r['assigned_to']?.toString() ?? '-',
            (r['created_at']?.toString() ?? '').length >= 10 ? r['created_at'].toString().substring(0, 10) : '-',
          ]).toList(),
          metrics: [
            SummaryMetric('Total', '${list.length}', Icons.support_agent, Colors.blue),
            SummaryMetric('Open', '${list.where((t) => t['status']?.toString().toLowerCase() == 'open').length}', Icons.pending, Colors.orange),
            SummaryMetric('Resolved', '${list.where((t) => t['status']?.toString().toLowerCase() == 'resolved').length}', Icons.check_circle, Colors.green),
          ],
          flowSteps: [
            InsightFlowStep(title: 'Submit', subtitle: 'User reports an issue via the portal.', icon: Icons.add_circle_outline),
            InsightFlowStep(title: 'Assign', subtitle: 'Ticket is routed to the right team.', icon: Icons.person_search_outlined),
            InsightFlowStep(title: 'Resolve', subtitle: 'Technician works on resolution.', icon: Icons.build_outlined),
            InsightFlowStep(title: 'Verify', subtitle: 'User confirms issue is resolved.', icon: Icons.verified_outlined),
          ],
        );

      case ReportType.library:
        final raw = await sb.from('book_issues').select().gte('issue_date', since).order('issue_date', ascending: false).limit(100);
        final list = List<Map<String, dynamic>>.from(raw);
        _totalRecords = list.length;
        return ReportData(
          type: type,
          headers: ['Book', 'Member', 'Issue Date', 'Due Date', 'Status'],
          rows: list.map((r) => [
            r['book_title']?.toString() ?? '-',
            r['member_name']?.toString() ?? '-',
            (r['issue_date']?.toString() ?? '').length >= 10 ? r['issue_date'].toString().substring(0, 10) : '-',
            (r['due_date']?.toString() ?? '').length >= 10 ? r['due_date'].toString().substring(0, 10) : '-',
            r['status']?.toString() ?? '-',
          ]).toList(),
          metrics: [
            SummaryMetric('Issued', '${list.length}', Icons.menu_book, Colors.green),
            SummaryMetric('Overdue', '${list.where((b) => b['status']?.toString().toLowerCase() == 'overdue').length}', Icons.warning, Colors.red),
            SummaryMetric('Returned', '${list.where((b) => b['status']?.toString().toLowerCase() == 'returned').length}', Icons.check_circle, Colors.blue),
          ],
          flowSteps: [
            InsightFlowStep(title: 'Browse', subtitle: 'Member searches for books.', icon: Icons.search_outlined),
            InsightFlowStep(title: 'Issue', subtitle: 'Book is checked out to member.', icon: Icons.menu_book_outlined),
            InsightFlowStep(title: 'Track', subtitle: 'Monitor due dates and renewals.', icon: Icons.track_changes_outlined),
            InsightFlowStep(title: 'Return', subtitle: 'Book is returned and shelved.', icon: Icons.assignment_return_outlined),
          ],
        );
    }
  }

  // --- Export ---

  Future<void> _export(ExportFormat format) async {
    if (_reportData == null || _reportData!.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting as ${format.name.toUpperCase()}...'), duration: const Duration(seconds: 1)),
    );

    final file = await ExportService.exportData(
      format: format,
      title: _reportData!.type.label,
      data: _reportData!.rows,
      headers: _reportData!.headers,
      subtitle: 'Generated from EMIS Reports',
      organization: 'EMIS Course Team',
    );

    if (file != null && mounted) {
      Clipboard.setData(ClipboardData(text: file.path));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${format.name.toUpperCase()} exported: ${file.path.split('/').last}',
              style: const TextStyle(fontSize: 13)),
          action: SnackBarAction(label: 'Copy Path', onPressed: () => Clipboard.setData(ClipboardData(text: file.path))),
          duration: const Duration(seconds: 5),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export failed. Check permissions.')),
      );
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        title: const Text('Reports & Analytics'),
        elevation: 0,
        actions: [
          if (_reportData != null && !_reportData!.isEmpty) ...[
            _ExportMenuButton(onExport: _export),
            const SizedBox(width: 4),
          ],
        ],
      ),
      body: InsightBackground(
        child: Column(
          children: [
            // --- Report type selector ---
            _buildReportTypeBar(theme),

            // --- Period filter ---
            if (_selectedType != null) _buildPeriodFilter(theme),

            // --- Content ---
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _reportData != null
                      ? _buildReportContent(theme, isDark)
                      : _buildEmptyState(theme),
            ),
          ],
        ),
      ),
    );
  }

  // --- Report type selector ---

  Widget _buildReportTypeBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Report Type',
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600, color: Colors.grey[600])),
          const SizedBox(height: 10),
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ReportType.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final type = ReportType.values[index];
                final selected = _selectedType == type;
                return _ReportTypeCard(
                  type: type,
                  selected: selected,
                  onTap: () => _loadReport(type),
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Period filter ---

  Widget _buildPeriodFilter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.date_range, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          ...ReportPeriod.values.map((p) {
            final selected = _selectedPeriod == p;
            final label = switch (p) {
              ReportPeriod.daily => 'Daily',
              ReportPeriod.weekly => 'Weekly',
              ReportPeriod.monthly => 'Monthly',
              ReportPeriod.yearly => 'Yearly',
            };
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                selected: selected,
                onSelected: (_) {
                  if (_selectedType != null) {
                    _loadReport(_selectedType!, p);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- Report content ---

  Widget _buildReportContent(ThemeData theme, bool isDark) {
    final data = _reportData!;
    final accent = data.type.color;

    final filteredRows = _searchQuery.isNotEmpty
        ? data.rows.where((row) => row.any((cell) => cell.toLowerCase().contains(_searchQuery))).toList()
        : data.rows;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // --- Hero card ---
        _buildHeroCard(theme, data, accent),

        const SizedBox(height: 20),

        // --- Search bar ---
        ModernSearchBar(hint: 'Search in ${data.type.label}...', onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()), controller: _searchController)
            .animate()
            .fadeIn(duration: 400.ms, delay: 100.ms)
            .slideX(begin: 0.05, end: 0),

        const SizedBox(height: 20),

        // --- Metric KPI row ---
        if (data.metrics.isNotEmpty) ...[
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.metrics.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final m = data.metrics[index];
                return ScaleAnimation(
                  index: index,
                  child: EnhancedStatCard(
                    title: m.label,
                    value: m.value,
                    icon: m.icon,
                    color: m.color,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // --- Charts row ---
        if (data.chartPoints.isNotEmpty || data.segments.isNotEmpty) ...[
          // Line chart
          if (data.chartPoints.isNotEmpty)
            FadeSlideAnimation(
              index: 0,
              child: InsightLineChartCard(
                title: '${data.type.label} Trend',
                subtitle: 'Visual trend over recent records',
                points: data.chartPoints,
                accent: accent,
              ),
            ),
          const SizedBox(height: 16),

          // Segments / distribution
          if (data.segments.isNotEmpty)
            FadeSlideAnimation(
              index: 1,
              child: InsightSegmentsCard(
                title: '${data.type.label} Distribution',
                subtitle: 'Breakdown across categories',
                segments: data.segments,
              ),
            ),
          const SizedBox(height: 16),
        ],

        // --- Process flow diagram ---
        if (data.flowSteps.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FadeSlideAnimation(
              index: 2,
              child: GlassCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(4),
                child: InsightProcessDiagram(
                  title: 'Workflow',
                  subtitle: 'End-to-end process flow',
                  steps: data.flowSteps,
                  accent: accent,
                ),
              ),
            ),
          ),

        // --- Data table ---
        if (data.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('No ${data.type.label.toLowerCase()} data found.',
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ),
          )
        else ...[
          FadeSlideAnimation(
            index: 3,
            child: InsightTableCard(
              title: '${data.type.label} Records',
              subtitle: filteredRows.length < data.rows.length
                  ? 'Showing ${filteredRows.length} of ${data.rows.length} entries'
                  : 'All ${data.rows.length} entries',
              columns: data.headers,
              rows: filteredRows,
            ),
          ),
        ],
      ],
    );
  }

  // --- Hero card ---

  Widget _buildHeroCard(ThemeData theme, ReportData data, Color accent) {
    return InsightHeroCard(
      eyebrow: data.type.label,
      title: '${data.type.label} Overview',
      subtitle: data.type.description,
      accent: accent,
      chips: [
        InsightStatChip(label: 'Records', value: '${data.rows.length}'),
        InsightStatChip(label: 'Metrics', value: '${data.metrics.length}'),
        InsightStatChip(label: 'Charts', value: data.chartPoints.isNotEmpty || data.segments.isNotEmpty ? 'Yes' : 'No'),
        if (_totalRecords > 0) InsightStatChip(label: 'Total System', value: '$_totalRecords'),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Select a report type above',
              style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text(
            'Choose from attendance, grades, payments,\nstudents, teachers, staff, and more',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  Sub-widgets
// -----------------------------------------------------------------------------

class _ReportTypeCard extends StatelessWidget {
  final ReportType type;
  final bool selected;
  final VoidCallback onTap;
  final int index;

  const _ReportTypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget card = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeOutCubic,
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? type.color.withValues(alpha: 0.12)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? type.color.withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.2),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: type.color.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: selected ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(type.icon, size: 18, color: type.color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(type.label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selected ? type.color : null),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(type.description.split('&').first.trim(),
                      style: TextStyle(fontSize: 8, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return card
        .animate()
        .fadeIn(duration: 400.ms, delay: (index * 60).ms)
        .slideX(begin: 0.05, end: 0, curve: Curves.easeOutQuad);
  }
}

class _ExportMenuButton extends StatelessWidget {
  final Future<void> Function(ExportFormat) onExport;

  const _ExportMenuButton({required this.onExport});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ExportFormat>(
      icon: const Icon(Icons.download_rounded),
      tooltip: 'Export',
      onSelected: onExport,
      itemBuilder: (context) => [
        _exportItem(ExportFormat.pdf, Icons.picture_as_pdf, Colors.red, 'PDF', 'Formatted document'),
        _exportItem(ExportFormat.csv, Icons.table_chart, Colors.green, 'CSV', 'Open in Excel / Sheets'),
        _exportItem(ExportFormat.html, Icons.code, Colors.orange, 'HTML', 'Web-friendly format'),
        _exportItem(ExportFormat.docx, Icons.description, Colors.blue, 'DOCX', 'Word document'),
        _exportItem(ExportFormat.xlsx, Icons.grid_on, Colors.green, 'XLSX', 'Excel spreadsheet'),
        const PopupMenuDivider(),
        const PopupMenuItem(
          enabled: false,
          child: Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Select a format to export',
                style: TextStyle(fontSize: 10, color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<ExportFormat> _exportItem(
      ExportFormat format, IconData icon, Color color, String title, String subtitle) {
    return PopupMenuItem(
      value: format,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

