import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/attendance.dart';
import 'package:course_emis/repositories/grade_repository.dart';

final gradeRepositoryProvider = Provider((ref) => GradeRepository());

final gradeNotifierProvider = StateNotifierProvider<GradeNotifier, AsyncValue<List<Grade>>>((ref) {
  return GradeNotifier(ref.read(gradeRepositoryProvider));
});

class GradeNotifier extends StateNotifier<AsyncValue<List<Grade>>> {
  final GradeRepository _repository;

  GradeNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGrades();
  }

  Future<void> loadGrades() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getAll();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGrade(Grade grade) async {
    await _repository.create(grade);
    await loadGrades();
  }

  Future<void> updateGrade(Grade grade) async {
    await _repository.update(grade);
    await loadGrades();
  }

  Future<void> deleteGrade(String id) async {
    await _repository.delete(id);
    await loadGrades();
  }
}
