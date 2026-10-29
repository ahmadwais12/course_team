import 'package:course_emis/repositories/base_repository.dart';

class ClassesRepository extends BaseRepository {
  ClassesRepository() : super('classes');

  Future<List<Map<String, dynamic>>> getAllClasses({String? programId}) async {
    if (programId != null) {
      return await getAll(
        filters: {'program_id': programId},
        orderBy: 'name',
        ascending: true,
      );
    }
    return await getAll(orderBy: 'created_at', ascending: false);
  }

  Stream<List<Map<String, dynamic>>> streamClasses({String? programId}) async* {
    final filters = programId != null ? {'program_id': programId} : null;
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
