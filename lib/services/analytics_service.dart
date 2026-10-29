import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  static final supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final students = await supabase.from('students').select('id');
    final teachers = await supabase.from('teachers').select('id');
    final classes = await supabase.from('classes').select('id');
    final payments = await supabase.from('payments').select('amount').eq('status', 'pending');

    final pendingPayments = (payments as List).fold<double>(
      0,
      (sum, item) => sum + ((item['amount'] ?? 0) as num).toDouble(),
    );

    return {
      'totalStudents': students.length,
      'totalTeachers': teachers.length,
      'totalClasses': classes.length,
      'pendingPayments': pendingPayments,
    };
  }

  static Future<List<Map<String, dynamic>>> getRevenueData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await supabase
        .from('payments')
        .select('amount, created_at')
        .eq('status', 'completed')
        .gte('created_at', startDate.toIso8601String())
        .lte('created_at', endDate.toIso8601String())
        .order('created_at');

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> getAttendanceStats() async {
    final today = DateTime.now();
    final response = await supabase
        .from('attendance')
        .select('status')
        .eq('date', today.toIso8601String().split('T')[0]);

    final total = response.length;
    final present = response.where((r) => r['status'] == 'present').length;
    final absent = response.where((r) => r['status'] == 'absent').length;
    final late = response.where((r) => r['status'] == 'late').length;

    return {
      'total': total,
      'present': present,
      'absent': absent,
      'late': late,
      'percentage': total > 0 ? (present / total * 100).toStringAsFixed(1) : '0',
    };
  }

  static Future<List<Map<String, dynamic>>> getTopPerformers({int limit = 10}) async {
    final response = await supabase
        .from('grades')
        .select('student_id, students(name), grade')
        .order('grade', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }
}
