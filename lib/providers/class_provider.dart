import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/class.dart';
import 'package:course_emis/repositories/class_repository.dart';

final classRepositoryProvider = Provider((ref) => ClassRepository());

final classesProvider = FutureProvider<List<Class>>((ref) async {
  final repo = ref.watch(classRepositoryProvider);
  return await repo.getAll();
});

final classesNotifierProvider = StateNotifierProvider<ClassesNotifier, AsyncValue<List<Class>>>((ref) {
  return ClassesNotifier(ref.watch(classRepositoryProvider));
});

class ClassesNotifier extends StateNotifier<AsyncValue<List<Class>>> {
  final ClassRepository _repository;
  
  ClassesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadClasses();
  }
  
  Future<void> loadClasses() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getAll());
  }
  
  Future<void> addClass(Class classItem) async {
    await _repository.create(classItem);
    await loadClasses();
  }
  
  Future<void> updateClass(Class classItem) async {
    await _repository.update(classItem);
    await loadClasses();
  }
  
  Future<void> deleteClass(String id) async {
    await _repository.delete(id);
    await loadClasses();
  }
}
