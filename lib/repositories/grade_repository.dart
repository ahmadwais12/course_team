import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/models/attendance.dart';

class GradeRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Grade>> getAll() async {
    try {
      final response = await supabase
          .from('grades')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => Grade.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch grades: $e');
    }
  }

  Future<Grade?> getById(String id) async {
    try {
      final response = await supabase
          .from('grades')
          .select()
          .eq('id', id)
          .single();
      return Grade.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      return null;
    }
  }

  Future<List<Grade>> getByStudent(String studentId) async {
    try {
      final response = await supabase
          .from('grades')
          .select()
          .eq('studentId', studentId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => Grade.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch grades for student: $e');
    }
  }

  Future<void> create(Grade grade) async {
    try {
      await supabase.from('grades').insert(grade.toJson());
    } catch (e) {
      throw Exception('Failed to create grade: $e');
    }
  }

  Future<void> update(Grade grade) async {
    try {
      await supabase.from('grades').update(grade.toJson()).eq('id', grade.id);
    } catch (e) {
      throw Exception('Failed to update grade: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await supabase.from('grades').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete grade: $e');
    }
  }

  Stream<List<Grade>> streamAll() {
    return supabase
        .from('grades')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) =>
            data.map((json) => Grade.fromJson(json)).toList());
  }
}
