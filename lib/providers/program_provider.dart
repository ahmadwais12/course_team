import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/program.dart';
import 'package:course_emis/repositories/program_repository.dart';

final programRepositoryProvider = Provider((ref) => ProgramRepository());

final programsProvider = FutureProvider<List<Program>>((ref) async {
  final repo = ref.watch(programRepositoryProvider);
  return await repo.getAll();
});

final programsNotifierProvider = StateNotifierProvider<ProgramsNotifier, AsyncValue<List<Program>>>((ref) {
  return ProgramsNotifier(ref.watch(programRepositoryProvider));
});

class ProgramsNotifier extends StateNotifier<AsyncValue<List<Program>>> {
  final ProgramRepository _repository;
  
  ProgramsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPrograms();
  }
  
  Future<void> loadPrograms() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getAll());
  }
  
  Future<void> addProgram(Program program) async {
    await _repository.create(program);
    await loadPrograms();
  }
  
  Future<void> updateProgram(Program program) async {
    await _repository.update(program);
    await loadPrograms();
  }
  
  Future<void> deleteProgram(String id) async {
    await _repository.delete(id);
    await loadPrograms();
  }
}
