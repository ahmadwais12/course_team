import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/models/lms_content.dart';

class FeedbackRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Feedback>> getAll() async {
    try {
      final response = await supabase
          .from('feedback')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => Feedback.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch feedback: $e');
    }
  }

  Future<Feedback?> getById(String id) async {
    try {
      final response = await supabase
          .from('feedback')
          .select()
          .eq('id', id)
          .single();
      return Feedback.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      return null;
    }
  }

  Future<List<Feedback>> getByStudent(String studentId) async {
    try {
      final response = await supabase
          .from('feedback')
          .select()
          .eq('studentId', studentId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => Feedback.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch feedback for student: $e');
    }
  }

  Future<void> create(Feedback feedback) async {
    try {
      await supabase.from('feedback').insert(feedback.toJson());
    } catch (e) {
      throw Exception('Failed to create feedback: $e');
    }
  }

  Future<void> update(Feedback feedback) async {
    try {
      await supabase.from('feedback').update(feedback.toJson()).eq('id', feedback.id);
    } catch (e) {
      throw Exception('Failed to update feedback: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await supabase.from('feedback').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete feedback: $e');
    }
  }

  Stream<List<Feedback>> streamAll() {
    return supabase
        .from('feedback')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) =>
            data.map((json) => Feedback.fromJson(json)).toList());
  }
}
