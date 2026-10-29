import 'package:course_emis/repositories/base_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExamResultsRepository extends BaseRepository {
  ExamResultsRepository() : super('exam_results');

  Future<List<Map<String, dynamic>>> getAllExamResults({
    String? studentId,
    String? classId,
    String? subject,
    String? examName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = Supabase.instance.client.from('exam_results').select();

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (classId != null) {
      query = query.eq('class_id', classId);
    }
    if (subject != null) {
      query = query.eq('subject', subject);
    }
    if (examName != null) {
      query = query.eq('exam_name', examName);
    }
    if (startDate != null) {
      query = query.gte('exam_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('exam_date', endDate.toIso8601String());
    }

    final response = await query.order('exam_date', ascending: false);
    return response;
  }

  Stream<List<Map<String, dynamic>>> streamExamResults({
    String? studentId,
    String? classId,
    String? subject,
  }) async* {
    await for (final data in Supabase.instance.client
        .from('exam_results')
        .stream(primaryKey: ['id'])) {
      var filtered = data;
      if (studentId != null) {
        filtered = filtered.where((r) => r['student_id'] == studentId).toList();
      }
      if (classId != null) {
        filtered = filtered.where((r) => r['class_id'] == classId).toList();
      }
      if (subject != null) {
        filtered = filtered.where((r) => r['subject'] == subject).toList();
      }
      yield filtered;
    }
  }

  Future<List<Map<String, dynamic>>> getStudentResults(String studentId) async {
    final response = await Supabase.instance.client
        .from('exam_results')
        .select()
        .eq('student_id', studentId)
        .order('exam_date', ascending: false);
    return response;
  }

  Future<List<Map<String, dynamic>>> getClassResults(
    String classId, {
    String? subject,
  }) async {
    var query = Supabase.instance.client
        .from('exam_results')
        .select()
        .eq('class_id', classId);

    if (subject != null) {
      query = query.eq('subject', subject);
    }

    final response = await query.order('exam_date', ascending: false);
    return response;
  }

  Future<Map<String, dynamic>> getExamStatistics(
    String examName, {
    String? classId,
  }) async {
    var query = Supabase.instance.client
        .from('exam_results')
        .select('score, max_score, percentage')
        .eq('exam_name', examName);

    if (classId != null) {
      query = query.eq('class_id', classId);
    }

    final response = await query;

    if (response.isEmpty) {
      return {
        'totalStudents': 0,
        'averageScore': 0.0,
        'highestScore': 0.0,
        'lowestScore': 0.0,
        'passCount': 0,
        'failCount': 0,
        'passRate': 0.0,
      };
    }

    double totalScore = 0;
    double highestScore = double.negativeInfinity;
    double lowestScore = double.infinity;
    int passCount = 0;
    int failCount = 0;

    for (final result in response) {
      final score = (result['score'] as num?)?.toDouble() ?? 0;
      final maxScore = (result['max_score'] as num?)?.toDouble() ?? 100;
      final percentage = (score / maxScore) * 100;

      totalScore += score;
      if (score > highestScore) highestScore = score;
      if (score < lowestScore) lowestScore = score;

      if (percentage >= 50) {
        passCount++;
      } else {
        failCount++;
      }
    }

    final totalStudents = response.length;
    final averageScore = totalScore / totalStudents;
    final passRate = (passCount / totalStudents) * 100;

    return {
      'totalStudents': totalStudents,
      'averageScore': averageScore,
      'highestScore': highestScore,
      'lowestScore': lowestScore,
      'passCount': passCount,
      'failCount': failCount,
      'passRate': passRate,
    };
  }

  Future<List<String>> getDistinctSubjects() async {
    final response = await Supabase.instance.client
        .from('exam_results')
        .select('subject')
        .not('subject', 'is', null);

    final subjects = response
        .map((r) => r['subject'] as String?)
        .where((s) => s != null)
        .toSet()
        .toList();
    subjects.sort();
    return subjects.cast<String>();
  }

  Future<List<String>> getDistinctExamNames() async {
    final response =
        await Supabase.instance.client.from('exam_results').select('exam_name');

    final examNames = response
        .map((r) => r['exam_name'] as String?)
        .where((n) => n != null)
        .toSet()
        .toList();
    examNames.sort();
    return examNames.cast<String>();
  }

  Future<void> updateGrade(
      String resultId, String grade, double percentage) async {
    await Supabase.instance.client.from('exam_results').update({
      'grade': grade,
      'percentage': percentage,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', resultId);
  }

  Future<void> batchCreate(List<Map<String, dynamic>> results) async {
    final supabase = Supabase.instance.client;
    final now = DateTime.now().toIso8601String();

    for (final result in results) {
      result['created_at'] = now;
      result['updated_at'] = now;
    }

    await supabase.from('exam_results').insert(results);
  }

  @override
  Future<void> create(Map<String, dynamic> data) async {
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    await super.create(data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await super.update(id, data);
  }
}
