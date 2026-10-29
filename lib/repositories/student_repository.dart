import 'package:course_emis/models/student.dart';
import 'package:course_emis/services/supabase_service.dart';

class StudentRepository {
  final SupabaseService _service = SupabaseService();
  
  Future<List<Student>> getAll() async {
    final data = await _service.getStudents();
    return data.map((e) => Student.fromJson(e)).toList();
  }
  
  Future<void> create(Student student) async {
    await _service.createStudent(student.toJson());
  }
  
  Future<void> update(Student student) async {
    await _service.updateStudent(student.id, student.toJson());
  }
  
  Future<void> delete(String id) async {
    await _service.deleteStudent(id);
  }
}
