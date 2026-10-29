import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/models/teacher.dart';

class TeacherRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Teacher>> getAll() async {
    try {
      final response = await supabase
          .from('teachers')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => Teacher.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch teachers: $e');
    }
  }

  Future<Teacher?> getById(String id) async {
    try {
      final response = await supabase
          .from('teachers')
          .select()
          .eq('id', id)
          .single();
      return Teacher.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      return null;
    }
  }

  Future<void> create(Teacher teacher) async {
    try {
      await supabase.from('teachers').insert(teacher.toJson());
    } catch (e) {
      throw Exception('Failed to create teacher: $e');
    }
  }

  Future<void> update(Teacher teacher) async {
    try {
      await supabase.from('teachers').update(teacher.toJson()).eq('id', teacher.id);
    } catch (e) {
      throw Exception('Failed to update teacher: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await supabase.from('teachers').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete teacher: $e');
    }
  }

  Stream<List<Teacher>> streamAll() {
    return supabase
        .from('teachers')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) =>
            data.map((json) => Teacher.fromJson(json)).toList());
  }
}
