import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exam.dart';

class ExamsRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final String tableName = 'exams';

  Future<List<Exam>> getExamsByTenant(String tenantId) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('tenant_id', tenantId)
        .order('exam_date', ascending: false);
    return (response as List).map((json) => Exam.fromJson(json)).toList();
  }

  Future<List<Exam>> getExamsByClass(String classId) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('class_id', classId)
        .order('exam_date', ascending: false);
    return (response as List).map((json) => Exam.fromJson(json)).toList();
  }

  Future<List<Exam>> getUpcomingExams() async {
    final response = await _client
        .from(tableName)
        .select()
        .gte('exam_date', DateTime.now().toIso8601String())
        .eq('status', 'scheduled')
        .order('exam_date');
    return (response as List).map((json) => Exam.fromJson(json)).toList();
  }

  Future<List<Exam>> getExamsByDateRange(DateTime start, DateTime end) async {
    final response = await _client
        .from(tableName)
        .select()
        .gte('exam_date', start.toIso8601String())
        .lte('exam_date', end.toIso8601String())
        .order('exam_date');
    return (response as List).map((json) => Exam.fromJson(json)).toList();
  }

  Future<Exam?> getExamById(String id) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('id', id)
        .maybeSingle();
    return response != null ? Exam.fromJson(response) : null;
  }

  Future<void> create(Exam exam) async {
    await _client.from(tableName).insert(exam.toJson());
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _client.from(tableName).update(data).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from(tableName).delete().eq('id', id);
  }

  Future<void> updateStatus(String id, String status) async {
    await _client.from(tableName).update({'status': status}).eq('id', id);
  }
}
