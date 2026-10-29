import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================
// SUPER ADMIN PANEL PROVIDERS
// ============================================

final superAdminStatsProvider = FutureProvider<SuperAdminStats>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    final tenants = await supabase.from('tenants').select('id');
    final users = await supabase.from('users').select('id');
    final activeTenants =
        await supabase.from('tenants').select('id').eq('is_active', true);

    return SuperAdminStats(
      totalSchools: tenants.length,
      totalUsers: users.length,
      activeSchools: activeTenants.length,
    );
  } catch (e) {
    return SuperAdminStats(totalSchools: 0, totalUsers: 0, activeSchools: 0);
  }
});

class SuperAdminStats {
  final int totalSchools;
  final int totalUsers;
  final int activeSchools;

  SuperAdminStats({
    required this.totalSchools,
    required this.totalUsers,
    required this.activeSchools,
  });
}

// ============================================
// ADMIN PANEL PROVIDERS
// ============================================

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    final students = await supabase.from('students').select('id');
    final teachers = await supabase.from('teachers').select('id');
    final classes = await supabase.from('classes').select('id');
    final departments = await supabase.from('departments').select('id');

    return AdminStats(
      totalStudents: students.length,
      totalTeachers: teachers.length,
      totalClasses: classes.length,
      totalDepartments: departments.length,
    );
  } catch (e) {
    return AdminStats(
      totalStudents: 0,
      totalTeachers: 0,
      totalClasses: 0,
      totalDepartments: 0,
    );
  }
});

class AdminStats {
  final int totalStudents;
  final int totalTeachers;
  final int totalClasses;
  final int totalDepartments;

  AdminStats({
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalClasses,
    required this.totalDepartments,
  });
}

// ============================================
// TEACHER PANEL PROVIDERS
// ============================================

final teacherStatsProvider = FutureProvider<TeacherStats>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  try {
    final lessonPlans = await supabase
        .from('lesson_plans')
        .select('id')
        .eq('teacher_id', userId ?? '');

    final homework = await supabase
        .from('homework')
        .select('id')
        .eq('teacher_id', userId ?? '');

    final studentGroups = await supabase
        .from('student_groups')
        .select('id')
        .eq('teacher_id', userId ?? '');

    return TeacherStats(
      totalLessonPlans: lessonPlans.length,
      totalHomework: homework.length,
      totalGroups: studentGroups.length,
    );
  } catch (e) {
    return TeacherStats(
      totalLessonPlans: 0,
      totalHomework: 0,
      totalGroups: 0,
    );
  }
});

class TeacherStats {
  final int totalLessonPlans;
  final int totalHomework;
  final int totalGroups;

  TeacherStats({
    required this.totalLessonPlans,
    required this.totalHomework,
    required this.totalGroups,
  });
}



// ============================================
// ACCOUNTANT PANEL PROVIDERS
// ============================================

final accountantStatsProvider = FutureProvider<AccountantStats>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    final invoices = await supabase.from('invoices').select('id');
    final pendingInvoices = await supabase
        .from('invoices')
        .select('amount')
        .eq('status', 'Pending');

    final totalPending = (pendingInvoices as List).fold<double>(
      0,
      (sum, item) => sum + ((item['amount'] ?? 0) as num).toDouble(),
    );

    final discounts = await supabase.from('discounts').select('id');

    return AccountantStats(
      totalInvoices: invoices.length,
      pendingAmount: totalPending,
      totalDiscounts: discounts.length,
    );
  } catch (e) {
    return AccountantStats(
      totalInvoices: 0,
      pendingAmount: 0,
      totalDiscounts: 0,
    );
  }
});

class AccountantStats {
  final int totalInvoices;
  final double pendingAmount;
  final int totalDiscounts;

  AccountantStats({
    required this.totalInvoices,
    required this.pendingAmount,
    required this.totalDiscounts,
  });
}

// ============================================
// LIBRARIAN PANEL PROVIDERS
// ============================================

final librarianStatsProvider = FutureProvider<LibrarianStats>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    final books = await supabase.from('library_books').select('id');
    final members = await supabase.from('library_members').select('id');
    final issued =
        await supabase.from('book_issues').select('id').eq('status', 'Issued');

    return LibrarianStats(
      totalBooks: books.length,
      totalMembers: members.length,
      totalIssued: issued.length,
    );
  } catch (e) {
    return LibrarianStats(
      totalBooks: 0,
      totalMembers: 0,
      totalIssued: 0,
    );
  }
});

class LibrarianStats {
  final int totalBooks;
  final int totalMembers;
  final int totalIssued;

  LibrarianStats({
    required this.totalBooks,
    required this.totalMembers,
    required this.totalIssued,
  });
}

// ============================================
// RECEPTIONIST PANEL PROVIDERS
// ============================================

final receptionistStatsProvider =
    FutureProvider<ReceptionistStats>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    final visitors = await supabase.from('visitors').select('id');
    final leads = await supabase.from('leads').select('id');
    final events = await supabase.from('reception_events').select('id');
    final calls = await supabase.from('phone_logs').select('id');
    final newLeads =
        await supabase.from('leads').select('id').eq('status', 'New');
    final upcomingEvents = await supabase
        .from('reception_events')
        .select('id')
        .gte('event_date', DateTime.now().toIso8601String());

    return ReceptionistStats(
      totalVisitors: visitors.length,
      totalLeads: leads.length,
      totalEvents: events.length,
      totalCalls: calls.length,
      newLeads: newLeads.length,
      upcomingEvents: upcomingEvents.length,
    );
  } catch (e) {
    return ReceptionistStats(
      totalVisitors: 0,
      totalLeads: 0,
      totalEvents: 0,
      totalCalls: 0,
      newLeads: 0,
      upcomingEvents: 0,
    );
  }
});

class ReceptionistStats {
  final int totalVisitors;
  final int totalLeads;
  final int totalEvents;
  final int totalCalls;
  final int newLeads;
  final int upcomingEvents;

  ReceptionistStats({
    required this.totalVisitors,
    required this.totalLeads,
    required this.totalEvents,
    required this.totalCalls,
    required this.newLeads,
    required this.upcomingEvents,
  });
}

// ============================================
// ACADEMIC SUPPORT PANEL PROVIDERS
// ============================================

final academicSupportStatsProvider =
    FutureProvider<AcademicSupportStats>((ref) async {
  final supabase = Supabase.instance.client;

  Future<int> safeCount(
    String table, {
    String? filterColumn,
    dynamic filterValue,
  }) async {
    try {
      dynamic query = supabase.from(table).select('id');
      if (filterColumn != null) {
        query = query.eq(filterColumn, filterValue);
      }
      final response = await query;
      return response.length as int;
    } catch (_) {
      return 0;
    }
  }

  final totalStudents = await safeCount('students');
  final activeStudents = await safeCount('students',
      filterColumn: 'status', filterValue: 'Active');
  final classes = await safeCount('classes');
  final programs = await safeCount('programs');
  final exams = await safeCount('exams');
  final attendanceRecords = await safeCount('attendance');
  final placementTests = await safeCount('placement_tests');

  return AcademicSupportStats(
    totalStudents: totalStudents,
    activeStudents: activeStudents == 0 ? totalStudents : activeStudents,
    totalClasses: classes,
    totalPrograms: programs,
    scheduledExams: exams,
    attendanceRecords: attendanceRecords,
    placementTests: placementTests,
  );
});

class AcademicSupportStats {
  final int totalStudents;
  final int activeStudents;
  final int totalClasses;
  final int totalPrograms;
  final int scheduledExams;
  final int attendanceRecords;
  final int placementTests;

  AcademicSupportStats({
    required this.totalStudents,
    required this.activeStudents,
    required this.totalClasses,
    required this.totalPrograms,
    required this.scheduledExams,
    required this.attendanceRecords,
    required this.placementTests,
  });
}

// ============================================
// HR MANAGER PANEL PROVIDERS
// ============================================

final hrStatsProvider = FutureProvider<HRStats>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    final staff = await supabase.from('staff').select('id');
    final attendance = await supabase
        .from('attendance')
        .select('id')
        .eq('status', 'Present')
        .eq('date', DateTime.now().toIso8601String().split('T')[0]);
    final onLeave = await supabase
        .from('leave_requests')
        .select('id')
        .eq('status', 'Approved');
    final openPositions =
        await supabase.from('recruitment').select('id').eq('status', 'Open');

    return HRStats(
      totalStaff: staff.length,
      activeToday: attendance.length,
      onLeave: onLeave.length,
      totalOpenings: openPositions.length,
    );
  } catch (e) {
    return HRStats(
      totalStaff: 0,
      activeToday: 0,
      onLeave: 0,
      totalOpenings: 0,
    );
  }
});

class HRStats {
  final int totalStaff;
  final int activeToday;
  final int onLeave;
  final int totalOpenings;

  HRStats({
    required this.totalStaff,
    required this.activeToday,
    required this.onLeave,
    required this.totalOpenings,
  });
}

// ============================================
// IT SUPPORT PANEL PROVIDERS
// ============================================

final itStatsProvider = FutureProvider<ITStats>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    final total = await supabase.from('support_tickets').select('id');
    final open = await supabase
        .from('support_tickets')
        .select('id')
        .eq('status', 'Open');
    final inProgress = await supabase
        .from('support_tickets')
        .select('id')
        .eq('status', 'In Progress');
    final resolved = await supabase
        .from('support_tickets')
        .select('id')
        .eq('status', 'Resolved');
    final devices =
        await supabase.from('devices').select('id').eq('status', 'Active');

    return ITStats(
      totalTickets: total.length,
      openTickets: open.length,
      inProgressTickets: inProgress.length,
      resolvedTickets: resolved.length,
      totalDevices: devices.length,
      systemUptime: '99.9%',
    );
  } catch (e) {
    return ITStats(
        totalTickets: 0,
        openTickets: 0,
        inProgressTickets: 0,
        resolvedTickets: 0,
        totalDevices: 0,
        systemUptime: '0%');
  }
});

class ITStats {
  final int totalTickets;
  final int openTickets;
  final int inProgressTickets;
  final int resolvedTickets;
  final int totalDevices;
  final String systemUptime;

  ITStats({
    required this.totalTickets,
    required this.openTickets,
    required this.inProgressTickets,
    required this.resolvedTickets,
    required this.totalDevices,
    required this.systemUptime,
  });
}

// ============================================
// LIBRARIAN PANEL PROVIDERS
// ============================================

final libraryStatsProvider = FutureProvider<LibraryStats>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    final books = await supabase.from('library_books').select('id');
    final issued =
        await supabase.from('book_issues').select('id').eq('status', 'Issued');
    final members = await supabase.from('library_members').select('id');
    final overdue =
        await supabase.from('book_issues').select('id').eq('status', 'Overdue');

    return LibraryStats(
      totalBooks: books.length,
      issuedBooks: issued.length,
      totalMembers: members.length,
      overdueBooks: overdue.length,
    );
  } catch (e) {
    return LibraryStats(
        totalBooks: 0, issuedBooks: 0, totalMembers: 0, overdueBooks: 0);
  }
});

class LibraryStats {
  final int totalBooks;
  final int issuedBooks;
  final int totalMembers;
  final int overdueBooks;

  LibraryStats({
    required this.totalBooks,
    required this.issuedBooks,
    required this.totalMembers,
    required this.overdueBooks,
  });
}

// ============================================
// INVENTORY MANAGER PANEL PROVIDERS
// ============================================

final inventoryStatsProvider = FutureProvider<InventoryStats>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    final items = await supabase.from('inventory_items').select('id');
    final suppliers = await supabase.from('suppliers').select('id');
    final purchaseOrders = await supabase.from('purchase_orders').select('id');
    final lowStock = await supabase.from('inventory_items').select('id').lte(
        'current_stock',
        supabase.from('inventory_items').select('minimum_stock').limit(1));
    final openPOs = await supabase
        .from('purchase_orders')
        .select('id')
        .eq('status', 'Open');

    return InventoryStats(
      totalItems: items.length,
      lowStockItems: lowStock.length,
      openOrders: openPOs.length,
      totalSuppliers: suppliers.length,
      totalPurchaseOrders: purchaseOrders.length,
    );
  } catch (e) {
    return InventoryStats(
      totalItems: 0,
      lowStockItems: 0,
      openOrders: 0,
      totalSuppliers: 0,
      totalPurchaseOrders: 0,
    );
  }
});

class InventoryStats {
  final int totalItems;
  final int lowStockItems;
  final int openOrders;
  final int totalSuppliers;
  final int totalPurchaseOrders;

  InventoryStats({
    required this.totalItems,
    required this.lowStockItems,
    required this.openOrders,
    required this.totalSuppliers,
    required this.totalPurchaseOrders,
  });
}

// ============================================
// IT SUPPORT PANEL PROVIDERS
// ============================================

final itSupportStatsProvider = FutureProvider<ITSupportStats>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    final tickets = await supabase.from('it_tickets').select('id');
    final devices = await supabase.from('it_devices').select('id');
    final openTickets =
        await supabase.from('it_tickets').select('id').eq('status', 'Open');

    return ITSupportStats(
      totalTickets: tickets.length,
      totalDevices: devices.length,
      openTickets: openTickets.length,
    );
  } catch (e) {
    return ITSupportStats(
      totalTickets: 0,
      totalDevices: 0,
      openTickets: 0,
    );
  }
});

class ITSupportStats {
  final int totalTickets;
  final int totalDevices;
  final int openTickets;

  ITSupportStats({
    required this.totalTickets,
    required this.totalDevices,
    required this.openTickets,
  });
}

// ============================================
// MAINTENANCE PANEL PROVIDERS
// ============================================

final maintenanceStatsProvider = FutureProvider<MaintenanceStats>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    final workOrders = await supabase.from('work_orders').select('id');
    final pendingTasks =
        await supabase.from('work_orders').select('id').eq('status', 'Pending');
    final inProgress = await supabase
        .from('work_orders')
        .select('id')
        .eq('status', 'In Progress');
    final completed = await supabase
        .from('work_orders')
        .select('id')
        .eq('status', 'Completed');

    return MaintenanceStats(
      totalWorkOrders: workOrders.length,
      pendingTasks: pendingTasks.length,
      inProgressTasks: inProgress.length,
      completedTasks: completed.length,
      avgResolutionTime: '4.2h',
    );
  } catch (e) {
    return MaintenanceStats(
      totalWorkOrders: 0,
      pendingTasks: 0,
      inProgressTasks: 0,
      completedTasks: 0,
      avgResolutionTime: '0h',
    );
  }
});

class MaintenanceStats {
  final int totalWorkOrders;
  final int pendingTasks;
  final int inProgressTasks;
  final int completedTasks;
  final String avgResolutionTime;

  MaintenanceStats({
    required this.totalWorkOrders,
    required this.pendingTasks,
    required this.inProgressTasks,
    required this.completedTasks,
    required this.avgResolutionTime,
  });
}

// ============================================
// EVENT MANAGER PANEL PROVIDERS
// ============================================

final eventManagerStatsProvider =
    FutureProvider<EventManagerStats>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    final events = await supabase.from('events').select('id');
    final venues = await supabase.from('event_venues').select('id');
    final upcomingEvents = await supabase
        .from('events')
        .select('id')
        .gte('event_date', DateTime.now().toIso8601String());

    return EventManagerStats(
      totalEvents: events.length,
      totalVenues: venues.length,
      upcomingEvents: upcomingEvents.length,
    );
  } catch (e) {
    return EventManagerStats(
      totalEvents: 0,
      totalVenues: 0,
      upcomingEvents: 0,
    );
  }
});

class EventManagerStats {
  final int totalEvents;
  final int totalVenues;
  final int upcomingEvents;

  EventManagerStats({
    required this.totalEvents,
    required this.totalVenues,
    required this.upcomingEvents,
  });
}

// ============================================
// COMPLAINT MANAGER PANEL PROVIDERS
// ============================================

final complaintManagerStatsProvider =
    FutureProvider<ComplaintManagerStats>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    final complaints = await supabase.from('complaints').select('id');
    final pending =
        await supabase.from('complaints').select('id').eq('status', 'Pending');

    final resolved =
        await supabase.from('complaints').select('id').eq('status', 'Resolved');

    return ComplaintManagerStats(
      totalComplaints: complaints.length,
      pendingComplaints: pending.length,
      resolvedComplaints: resolved.length,
    );
  } catch (e) {
    return ComplaintManagerStats(
      totalComplaints: 0,
      pendingComplaints: 0,
      resolvedComplaints: 0,
    );
  }
});

class ComplaintManagerStats {
  final int totalComplaints;
  final int pendingComplaints;
  final int resolvedComplaints;

  ComplaintManagerStats({
    required this.totalComplaints,
    required this.pendingComplaints,
    required this.resolvedComplaints,
  });
}

// ============================================
// STAFF PANEL PROVIDERS
// ============================================

final staffStatsProvider = FutureProvider<StaffStats>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  try {
    final attendance = await supabase
        .from('staff_attendance')
        .select('id')
        .eq('staff_id', userId ?? '');

    final tasks = await supabase
        .from('staff_tasks')
        .select('id')
        .eq('assigned_to', userId ?? '');

    final leaves = await supabase
        .from('employee_leaves')
        .select('id')
        .eq('employee_id', userId ?? '');

    return StaffStats(
      attendanceDays: attendance.length,
      totalTasks: tasks.length,
      totalLeaves: leaves.length,
    );
  } catch (e) {
    return StaffStats(
      attendanceDays: 0,
      totalTasks: 0,
      totalLeaves: 0,
    );
  }
});

class StaffStats {
  final int attendanceDays;
  final int totalTasks;
  final int totalLeaves;

  StaffStats({
    required this.attendanceDays,
    required this.totalTasks,
    required this.totalLeaves,
  });
}

// ============================================
// ============================================
// COMPLAINT MANAGER PROVIDERS
// ============================================

final complaintStatsProvider = FutureProvider<ComplaintStats>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    final openTickets =
        await supabase.from('complaints').select('id').eq('status', 'Open');

    final inProgressTickets = await supabase
        .from('complaints')
        .select('id')
        .eq('status', 'In Progress');

    final resolvedTickets =
        await supabase.from('complaints').select('id').eq('status', 'Resolved');

    return ComplaintStats(
      openTickets: openTickets.length,
      inProgressTickets: inProgressTickets.length,
      resolvedTickets: resolvedTickets.length,
      avgResponseTime: '2.5h',
    );
  } catch (e) {
    return ComplaintStats(
      openTickets: 0,
      inProgressTickets: 0,
      resolvedTickets: 0,
      avgResponseTime: '0h',
    );
  }
});

class ComplaintStats {
  final int openTickets;
  final int inProgressTickets;
  final int resolvedTickets;
  final String avgResponseTime;

  ComplaintStats({
    required this.openTickets,
    required this.inProgressTickets,
    required this.resolvedTickets,
    required this.avgResponseTime,
  });
}

// ============================================
// COMMUNICATION & EVENTS PANEL PROVIDERS
// ============================================

final communicationStatsProvider =
    FutureProvider<CommunicationStats>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    final announcements = await supabase.from('announcements').select('id');
    final upcomingEvents = await supabase
        .from('events')
        .select('id')
        .gte('event_date', DateTime.now().toIso8601String());
    final activeEvents =
        await supabase.from('events').select('id').eq('status', 'Active');
    final totalRegistrations =
        await supabase.from('event_registrations').select('id');
    final openTickets =
        await supabase.from('complaints').select('id').eq('status', 'Open');
    final inProgressTickets = await supabase
        .from('complaints')
        .select('id')
        .eq('status', 'In Progress');
    final resolvedToday = await supabase
        .from('complaints')
        .select('id')
        .eq('status', 'Resolved')
        .gte('resolved_at', DateTime.now().toIso8601String().split('T')[0]);
    final pendingNotifications = await supabase
        .from('notifications')
        .select('id')
        .eq('status', 'Pending');

    return CommunicationStats(
      announcements: announcements.length,
      upcomingEvents: upcomingEvents.length,
      activeEvents: activeEvents.length,
      totalRegistrations: totalRegistrations.length,
      openTickets: openTickets.length,
      inProgressTickets: inProgressTickets.length,
      resolvedToday: resolvedToday.length,
      pendingNotifications: pendingNotifications.length,
    );
  } catch (e) {
    return CommunicationStats(
      announcements: 0,
      upcomingEvents: 0,
      activeEvents: 0,
      totalRegistrations: 0,
      openTickets: 0,
      inProgressTickets: 0,
      resolvedToday: 0,
      pendingNotifications: 0,
    );
  }
});

class CommunicationStats {
  final int announcements;
  final int upcomingEvents;
  final int activeEvents;
  final int totalRegistrations;
  final int openTickets;
  final int inProgressTickets;
  final int resolvedToday;
  final int pendingNotifications;

  CommunicationStats({
    required this.announcements,
    required this.upcomingEvents,
    required this.activeEvents,
    required this.totalRegistrations,
    required this.openTickets,
    required this.inProgressTickets,
    required this.resolvedToday,
    required this.pendingNotifications,
  });
}
