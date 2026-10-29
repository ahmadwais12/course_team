import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/department.dart';
import 'package:course_emis/repositories/department_repository.dart';

final departmentRepositoryProvider = Provider<DepartmentRepository>(
  (ref) => DepartmentRepository(),
);

final departmentsProvider = FutureProvider<List<Department>>((ref) async {
  final repo = ref.watch(departmentRepositoryProvider);
  return await repo.getAllDepartments();
});

final departmentsNotifierProvider =
    StateNotifierProvider<DepartmentsNotifier, AsyncValue<List<Department>>>(
  (ref) => DepartmentsNotifier(ref.watch(departmentRepositoryProvider)),
);

class DepartmentsNotifier extends StateNotifier<AsyncValue<List<Department>>> {
  final DepartmentRepository _repository;

  DepartmentsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadDepartments();
  }

  Future<void> loadDepartments() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getAllDepartments());
  }

  Future<void> addDepartment(Department department) async {
    await _repository.createDepartment(department);
    await loadDepartments();
  }

  Future<void> updateDepartment(Department department) async {
    await _repository.updateDepartment(department);
    await loadDepartments();
  }

  Future<void> deleteDepartment(String id) async {
    await _repository.delete(id);
    await loadDepartments();
  }
}
