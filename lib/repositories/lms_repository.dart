import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/models/lms_content.dart';

class LMSRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<LMSContent>> getAll() async {
    try {
      final response = await supabase
          .from('lms_content')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => LMSContent.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch LMS content: $e');
    }
  }

  Future<LMSContent?> getById(String id) async {
    try {
      final response = await supabase
          .from('lms_content')
          .select()
          .eq('id', id)
          .single();
      return LMSContent.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      return null;
    }
  }

  Future<List<LMSContent>> getByClass(String classId) async {
    try {
      final response = await supabase
          .from('lms_content')
          .select()
          .eq('classId', classId)
          .eq('isPublished', true)
          .order('order', ascending: true);
      return (response as List)
          .map((e) => LMSContent.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch LMS content by class: $e');
    }
  }

  Future<void> create(LMSContent content) async {
    try {
      await supabase.from('lms_content').insert(content.toJson());
    } catch (e) {
      throw Exception('Failed to create LMS content: $e');
    }
  }

  Future<void> update(LMSContent content) async {
    try {
      await supabase.from('lms_content').update(content.toJson()).eq('id', content.id);
    } catch (e) {
      throw Exception('Failed to update LMS content: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await supabase.from('lms_content').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete LMS content: $e');
    }
  }

  Stream<List<LMSContent>> streamAll() {
    return supabase
        .from('lms_content')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) =>
            data.map((json) => LMSContent.fromJson(json)).toList());
  }
}
