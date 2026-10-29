import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/teacher.dart';
import 'package:course_emis/repositories/teacher_repository.dart';

final teacherRepositoryProvider = Provider((ref) => TeacherRepository());

final teacherNotifierProvider = StateNotifierProvider<TeacherNotifier, AsyncValue<List<Teacher>>>((ref) {
  return TeacherNotifier(ref.read(teacherRepositoryProvider));
});

class TeacherNotifier extends StateNotifier<AsyncValue<List<Teacher>>> {
  final TeacherRepository _repository;

  TeacherNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTeachers();
  }

  Future<void> loadTeachers() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getAll();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTeacher(Teacher teacher) async {
    await _repository.create(teacher);
    await loadTeachers();
  }

  Future<void> updateTeacher(Teacher teacher) async {
    await _repository.update(teacher);
    await loadTeachers();
  }

  Future<void> deleteTeacher(String id) async {
    await _repository.delete(id);
    await loadTeachers();
  }
}
