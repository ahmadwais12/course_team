import 'package:course_emis/repositories/base_repository.dart';

class ProgramsRepository extends BaseRepository {
  ProgramsRepository() : super('programs');

  Future<List<Map<String, dynamic>>> getAllPrograms(
      {String? departmentId}) async {
    if (departmentId != null) {
      return await getAll(
        filters: {'department_id': departmentId},
        orderBy: 'name',
        ascending: true,
      );
    }
    return await getAll(orderBy: 'created_at', ascending: false);
  }

  Stream<List<Map<String, dynamic>>> streamPrograms(
      {String? departmentId}) async* {
    final filters =
        departmentId != null ? {'department_id': departmentId} : null;
    await for (final data in stream(filters: filters)) {
      yield data;
    }
  }

  @override
  Future<void> create(Map<String, dynamic> data) async {
    data['created_at'] = DateTime.now().toIso8601String();
    await super.create(data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await super.update(id, data);
  }
}
