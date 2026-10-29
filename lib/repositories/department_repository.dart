import 'package:course_emis/repositories/base_repository.dart';
import 'package:course_emis/models/department.dart';

class DepartmentRepository extends BaseRepository {
  DepartmentRepository() : super('departments');

  Future<List<Department>> getAllDepartments() async {
    final data = await getAll();
    return data.map((e) => Department.fromJson(e)).toList();
  }

  Stream<List<Department>> streamDepartments() async* {
    await for (final data in stream()) {
      yield data.map((e) => Department.fromJson(e)).toList();
    }
  }

  Future<void> createDepartment(Department department) async {
    await create(department.toJson());
  }

  Future<void> updateDepartment(Department department) async {
    await update(department.id, department.toJson());
  }

  @override
  Future<void> create(Map<String, dynamic> data) async {
    // Add timestamps
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    await super.create(data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await super.update(id, data);
  }
}
