import 'package:supabase_flutter/supabase_flutter.dart';

class GamificationService {
  static final instance = GamificationService._();
  GamificationService._();

  final _supabase = Supabase.instance.client;

  // Achievement badges
  Future<List<Map<String, dynamic>>> getBadges(String studentId) async {
    final badges = <Map<String, dynamic>>[];
    
    final attendance = await _supabase
        .from('attendance')
        .select('status')
        .eq('student_id', studentId)
        .eq('status', 'present');
    
    if (attendance.length >= 30) {
      badges.add({
        'id': 'perfect_attendance',
        'name': 'Perfect Attendance',
        'icon': '🎯',
        'description': '30 days present',
        'earned': true,
      });
    }

    final grades = await _supabase
        .from('grades')
        .select('score')
        .eq('student_id', studentId)
        .gte('score', 90);
    
    if (grades.length >= 5) {
      badges.add({
        'id': 'top_performer',
        'name': 'Top Performer',
        'icon': '⭐',
        'description': '5+ grades above 90',
        'earned': true,
      });
    }

    return badges;
  }

  // Leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard({String? classId}) async {
    if (classId != null) {
      final data = await _supabase
          .from('students')
          .select('id, name, avatar, points')
          .eq('class_id', classId)
          .order('points', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(data);
    }

    final data = await _supabase
        .from('students')
        .select('id, name, avatar, points')
        .order('points', ascending: false)
        .limit(10);

    return List<Map<String, dynamic>>.from(data);
  }

  // Add points
  Future<void> addPoints(String studentId, int points, String reason) async {
    final current = await _supabase
        .from('students')
        .select('points')
        .eq('id', studentId)
        .single();

    await _supabase.from('students').update({
      'points': (current['points'] ?? 0) + points,
    }).eq('id', studentId);

    await _supabase.from('point_history').insert({
      'student_id': studentId,
      'points': points,
      'reason': reason,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Progress tracking
  Future<Map<String, dynamic>> getProgress(String studentId) async {
    final grades = await _supabase
        .from('grades')
        .select('score')
        .eq('student_id', studentId);

    final attendance = await _supabase
        .from('attendance')
        .select('status')
        .eq('student_id', studentId);

    final present = attendance.where((e) => e['status'] == 'present').length;
    final attendanceRate = attendance.isEmpty ? 0 : (present / attendance.length * 100);

    final avgGrade = grades.isEmpty ? 0 : grades.map((e) => e['score'] as num).reduce((a, b) => a + b) / grades.length;

    return {
      'attendance_progress': attendanceRate,
      'grade_progress': avgGrade,
      'level': (attendanceRate + avgGrade) ~/ 20,
      'next_level_points': 100 - ((attendanceRate + avgGrade) % 100).toInt(),
    };
  }
}
