import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/student.dart';
import 'package:course_emis/repositories/student_repository.dart';

final studentRepositoryProvider = Provider((ref) => StudentRepository());

final studentsProvider = FutureProvider<List<Student>>((ref) async {
  final repo = ref.watch(studentRepositoryProvider);
  return await repo.getAll();
});

final studentsNotifierProvider = StateNotifierProvider<StudentsNotifier, AsyncValue<List<Student>>>((ref) {
  return StudentsNotifier(ref.watch(studentRepositoryProvider));
});

class StudentsNotifier extends StateNotifier<AsyncValue<List<Student>>> {
  final StudentRepository _repository;
  
  StudentsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadStudents();
  }
  
  Future<void> loadStudents() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getAll());
  }
  
  Future<void> addStudent(Student student) async {
    await _repository.create(student);
    await loadStudents();
  }
  
  Future<void> updateStudent(Student student) async {
    await _repository.update(student);
    await loadStudents();
  }
  
  Future<void> deleteStudent(String id) async {
    await _repository.delete(id);
    await loadStudents();
  }
}
