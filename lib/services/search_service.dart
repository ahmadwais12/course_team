import 'package:supabase_flutter/supabase_flutter.dart';

class SearchService {
  static final supabase = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> searchStudents(String query) async {
    if (query.isEmpty) return [];
    
    final response = await supabase
        .from('students')
        .select()
        .or('name.ilike.%$query%,email.ilike.%$query%,phone.ilike.%$query%')
        .limit(20);
    
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> searchTeachers(String query) async {
    if (query.isEmpty) return [];
    
    final response = await supabase
        .from('teachers')
        .select()
        .or('name.ilike.%$query%,email.ilike.%$query%,subject.ilike.%$query%')
        .limit(20);
    
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> searchCourses(String query) async {
    if (query.isEmpty) return [];
    
    final response = await supabase
        .from('programs')
        .select()
        .or('name.ilike.%$query%,description.ilike.%$query%')
        .limit(20);
    
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, List<Map<String, dynamic>>>> globalSearch(String query) async {
    if (query.isEmpty) return {};

    final results = await Future.wait([
      searchStudents(query),
      searchTeachers(query),
      searchCourses(query),
    ]);

    return {
      'students': results[0],
      'teachers': results[1],
      'courses': results[2],
    };
  }
}
