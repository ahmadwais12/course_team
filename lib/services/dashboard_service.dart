import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides realtime dashboard metrics via Supabase streams.
/// Each panel gets live-updating counts and recent activity.
class DashboardService {
  DashboardService._();
  static final instance = DashboardService._();

  final _sb = Supabase.instance.client;

  // --- HELPERS ---

  Future<int> _count(String table, {String? tenantId, Map<String, dynamic>? filters}) async {
    try {
      dynamic query = _sb.from(table).select('id');
      if (tenantId != null) query = query.eq('tenant_id', tenantId);
      if (filters != null) {
        for (final f in filters.entries) {
          query = query.eq(f.key, f.value);
        }
      }
      final data = await query;
      return (data as List).length;
    } catch (e) {
      debugPrint('[DashboardService] count($table) error: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> _recent(
    String table, {
    int limit = 5,
    String? tenantId,
    String orderBy = 'created_at',
    bool ascending = false,
    String? select,
  }) async {
    try {
      dynamic query = _sb.from(table).select(select ?? '*');
      if (tenantId != null) query = query.eq('tenant_id', tenantId);
      query = query.order(orderBy, ascending: ascending).limit(limit);
      final data = await query;
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[DashboardService] recent($table) error: $e');
      return [];
    }
  }

  // -----------------------------------------------------------
  //  PANEL-SPECIFIC DATA FETCHERS
  // -----------------------------------------------------------

  // --- SUPER ADMIN ---
  Future<Map<String, dynamic>> fetchSuperAdminMetrics() async {
    final tenants = await _count('tenants');
    final activeTenants = await _count('tenants', filters: {'is_active': true});
    final users = await _count('users');
    final students = await _count('users', filters: {'role': 'student'});
    final teachers = await _count('users', filters: {'role': 'teacher'});
    final staff = await _count('users', filters: {'role': 'staff'});
    return {
      'totalTenants': tenants,
      'activeTenants': activeTenants,
      'totalUsers': users,
      'totalStudents': students,
      'totalTeachers': teachers,
      'totalStaff': staff,
    };
  }

  Future<List<Map<String, dynamic>>> fetchSuperAdminActivity() async {
    final tenants = await _recent('tenants', orderBy: 'created_at', select: 'name, slug, created_at, is_active');
    return tenants;
  }

  // --- ADMIN ---
  Future<Map<String, dynamic>> fetchAdminMetrics() async {
    final students = await _count('students');
    final teachers = await _count('teachers');
    final classes = await _count('classes');
    final departments = await _count('departments');
    final programs = await _count('programs');
    // Recent payments
    double collected = 0;
    try {
      final payments = await _sb.from('payments').select('amount').eq('status', 'paid');
      for (final p in payments) {
        collected += (p['amount'] as num?)?.toDouble() ?? 0;
      }
    } catch (_) {}
    return {
      'totalStudents': students,
      'totalTeachers': teachers,
      'totalClasses': classes,
      'totalDepartments': departments,
      'totalPrograms': programs,
      'collectedRevenue': collected,
    };
  }

  Future<List<Map<String, dynamic>>> fetchAdminRecentClasses() async {
    return _recent('classes', orderBy: 'created_at', select: 'name, created_at, student_count, active');
  }

  // --- TEACHER ---
  Future<Map<String, dynamic>> fetchTeacherMetrics(String? userId) async {
    if (userId == null) return {};
    final lessonPlans = await _count('lesson_plans', filters: {'teacher_id': userId});
    final homework = await _count('homework', filters: {'teacher_id': userId});
    final groups = await _count('student_groups', filters: {'teacher_id': userId});
    // Today's attendance for teacher's classes
    int present = 0, total = 0;
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final records = await _sb.from('attendance').select('status').eq('date', today);
      total = (records as List).length;
      for (final r in records) {
        if (r['status'] == 'present') present++;
      }
    } catch (_) {}
    return {
      'totalLessonPlans': lessonPlans,
      'totalHomework': homework,
      'totalGroups': groups,
      'attendanceRate': total > 0 ? ((present / total) * 100).round() : 0,
      'presentToday': present,
      'totalToday': total,
    };
  }

  Future<List<Map<String, dynamic>>> fetchTeacherSchedule(String? userId) async {
    if (userId == null) return [];
    final now = DateTime.now();
    final dayOfWeek = now.weekday - 1; // Monday=0
    try {
      final data = await _sb
          .from('schedules')
          .select('*, classes(name)')
          .eq('teacher_id', userId)
          .eq('day_of_week', dayOfWeek)
          .order('start_time', ascending: true)
          .limit(5);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[DashboardService] teacher schedule: $e');
      return [];
    }
  }

  // --- HR ---
  Future<Map<String, dynamic>> fetchHRMetrics() async {
    final staff = await _count('users', filters: {'role': 'staff'});
    final teachers = await _count('users', filters: {'role': 'teacher'});
    final totalEmployees = staff + teachers;
    // Today's attendance
    int present = 0;
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final records = await _sb.from('staff_attendance').select('id').eq('date', today).eq('status', 'Present');
      present = (records as List).length;
    } catch (_) {
      try {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final records = await _sb.from('attendance').select('id').eq('date', today).eq('status', 'Present');
        present = (records as List).length;
      } catch (_) {}
    }
    final onLeave = await _count('leave_requests', filters: {'status': 'Approved'});
    final openings = await _count('job_postings', filters: {'status': 'open'});
    return {
      'totalStaff': totalEmployees,
      'activeToday': present,
      'onLeave': onLeave,
      'totalOpenings': openings,
    };
  }

  Future<List<Map<String, dynamic>>> fetchHRRecentLeaves() async {
    try {
      final data = await _sb
          .from('leave_requests')
          .select('*, profiles:applicant_id(full_name)')
          .order('created_at', ascending: false)
          .limit(5);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[DashboardService] HR leaves: $e');
      return [];
    }
  }

  // --- ACADEMIC SUPPORT ---
  Future<Map<String, dynamic>> fetchAcademicMetrics() async {
    final students = await _count('students');
    final classes = await _count('classes');
    final programs = await _count('programs');
    final exams = await _count('exams');
    final attendance = await _count('attendance');
    final placements = await _count('placement_tests');
    return {
      'totalStudents': students,
      'totalClasses': classes,
      'totalPrograms': programs,
      'scheduledExams': exams,
      'attendanceRecords': attendance,
      'placementTests': placements,
    };
  }

  Future<List<Map<String, dynamic>>> fetchAcademicRecentStudents() async {
    try {
      final data = await _sb
          .from('students')
          .select('*, profiles:profile_id(full_name)')
          .order('created_at', ascending: false)
          .limit(5);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[DashboardService] academic students: $e');
      return [];
    }
  }

  // --- ACCOUNTANT ---
  Future<Map<String, dynamic>> fetchAccountantMetrics() async {
    final invoices = await _count('invoices');
    final payments = await _count('payments');
    final expenses = await _count('expenses');
    double pendingAmount = 0;
    try {
      final pending = await _sb.from('invoices').select('amount').eq('status', 'Pending');
      for (final p in pending) {
        pendingAmount += (p['amount'] as num?)?.toDouble() ?? 0;
      }
    } catch (_) {}
    double collectedAmount = 0;
    try {
      final paid = await _sb.from('payments').select('amount').eq('status', 'paid');
      for (final p in paid) {
        collectedAmount += (p['amount'] as num?)?.toDouble() ?? 0;
      }
    } catch (_) {}
    return {
      'totalInvoices': invoices,
      'totalPayments': payments,
      'totalExpenses': expenses,
      'pendingAmount': pendingAmount,
      'collectedAmount': collectedAmount,
    };
  }

  Future<List<Map<String, dynamic>>> fetchAccountantRecentTransactions() async {
    try {
      final data = await _sb
          .from('invoices')
          .select()
          .order('created_at', ascending: false)
          .limit(5);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[DashboardService] accountant transactions: $e');
      return [];
    }
  }

  // --- IT SUPPORT ---
  Future<Map<String, dynamic>> fetchITMetrics() async {
    final tickets = await _count('support_tickets');
    final open = await _count('support_tickets', filters: {'status': 'Open'});
    final inProgress = await _count('support_tickets', filters: {'status': 'In Progress'});
    final resolved = await _count('support_tickets', filters: {'status': 'Resolved'});
    int deviceCount = 0;
    try { final d = await _sb.from('it_devices').select('id').eq('status', 'Active'); deviceCount = (d as List).length; } catch (_) {}
    try { final d = await _sb.from('devices').select('id').eq('status', 'Active'); deviceCount = (d as List).length; } catch (_) {}
    return {
      'totalTickets': tickets,
      'openTickets': open,
      'inProgressTickets': inProgress,
      'resolvedTickets': resolved,
      'totalDevices': deviceCount,
    };
  }

  // --- COMMUNICATION ---
  Future<Map<String, dynamic>> fetchCommunicationMetrics() async {
    final announcements = await _count('announcements');
    final events = await _count('events');
    final feedbacks = await _count('feedback');
    final notifications = await _count('notifications');
    return {
      'totalAnnouncements': announcements,
      'totalEvents': events,
      'totalFeedbacks': feedbacks,
      'totalNotifications': notifications,
    };
  }
}
