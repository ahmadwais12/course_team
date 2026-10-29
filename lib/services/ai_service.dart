import 'package:supabase_flutter/supabase_flutter.dart';

class AIService {
  static final instance = AIService._();
  AIService._();

  final _supabase = Supabase.instance.client;

  // Smart attendance prediction
  Future<Map<String, dynamic>> predictAttendance(String studentId) async {
    final data = await _supabase
        .from('attendance')
        .select('status, date')
        .eq('student_id', studentId)
        .order('date', ascending: false)
        .limit(30);

    final total = data.length;
    final present = data.where((e) => e['status'] == 'present').length;
    final rate = total > 0 ? (present / total * 100) : 0;

    return {
      'attendance_rate': rate,
      'prediction': rate >= 75 ? 'good' : rate >= 50 ? 'average' : 'poor',
      'risk_level': rate < 50 ? 'high' : rate < 75 ? 'medium' : 'low',
      'recommendation': rate < 75 ? 'Needs improvement' : 'Keep it up!',
    };
  }

  // Grade analytics
  Future<Map<String, dynamic>> analyzeGrades(String studentId) async {
    final data = await _supabase
        .from('grades')
        .select('score, subject')
        .eq('student_id', studentId);

    if (data.isEmpty) return {'average': 0, 'trend': 'no_data'};

    final scores = data.map((e) => e['score'] as num).toList();
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    final recent = scores.take(5).toList();
    final old = scores.skip(5).take(5).toList();
    
    final recentAvg = recent.isEmpty ? 0 : recent.reduce((a, b) => a + b) / recent.length;
    final oldAvg = old.isEmpty ? 0 : old.reduce((a, b) => a + b) / old.length;
    
    return {
      'average': avg.toStringAsFixed(1),
      'trend': recentAvg > oldAvg ? 'improving' : recentAvg < oldAvg ? 'declining' : 'stable',
      'highest': scores.reduce((a, b) => a > b ? a : b),
      'lowest': scores.reduce((a, b) => a < b ? a : b),
      'grade': avg >= 90 ? 'A' : avg >= 80 ? 'B' : avg >= 70 ? 'C' : avg >= 60 ? 'D' : 'F',
    };
  }

  // Performance insights
  Future<List<Map<String, dynamic>>> getPerformanceInsights(String studentId) async {
    final attendance = await predictAttendance(studentId);
    final grades = await analyzeGrades(studentId);
    
    final insights = <Map<String, dynamic>>[];

    if (attendance['risk_level'] == 'high') {
      insights.add({
        'type': 'warning',
        'title': 'Low Attendance',
        'message': 'Attendance is below 50%. Immediate action required.',
        'priority': 'high',
      });
    }

    if (grades['trend'] == 'declining') {
      insights.add({
        'type': 'warning',
        'title': 'Declining Grades',
        'message': 'Recent grades are lower than previous performance.',
        'priority': 'medium',
      });
    }

    if (grades['trend'] == 'improving') {
      insights.add({
        'type': 'success',
        'title': 'Improving Performance',
        'message': 'Keep up the great work! Grades are trending upward.',
        'priority': 'low',
      });
    }

    return insights;
  }
}
