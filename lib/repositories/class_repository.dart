import 'package:course_emis/models/class.dart';
import 'package:course_emis/services/supabase_service.dart';

class ClassRepository {
  final SupabaseService _service = SupabaseService();
  
  Future<List<Class>> getAll() async {
    final data = await _service.getClasses();
    return data.map((e) => Class.fromJson(e)).toList();
  }
  
  Future<void> create(Class classItem) async {
    await _service.createClass(classItem.toJson());
  }
  
  Future<void> update(Class classItem) async {
    await _service.updateClass(classItem.id, classItem.toJson());
  }
  
  Future<void> delete(String id) async {
    await _service.deleteClass(id);
  }
}
