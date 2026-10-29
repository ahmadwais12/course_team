import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/maintenance_model.dart';
import '../repositories/maintenance_repository.dart';

final maintenanceRepositoryProvider = Provider((ref) => MaintenanceRepository());

final maintenanceTaskListProvider = StateNotifierProvider<MaintenanceNotifier, List<MaintenanceTask>>((ref) {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return MaintenanceNotifier(repository);
});

class MaintenanceNotifier extends StateNotifier<List<MaintenanceTask>> {
  final MaintenanceRepository _repository;

  MaintenanceNotifier(this._repository) : super([]) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      state = await _repository.getTasks();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> addTask(MaintenanceTask task) async {
    await _repository.addTask(task);
    await loadTasks();
  }

  Future<void> updateTask(MaintenanceTask task) async {
    await _repository.updateTask(task);
    await loadTasks();
  }
}
