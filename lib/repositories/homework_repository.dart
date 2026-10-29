import 'package:course_emis/repositories/base_repository.dart';

class HomeworkRepository extends BaseRepository {
  HomeworkRepository() : super('homework');

  Future<List<Map<String, dynamic>>> getAllHomework({String? teacherId}) async {
    if (teacherId != null) {
      return await getAll(
          filters: {'teacher_id': teacherId},
          orderBy: 'due_date',
          ascending: false);
    }
    return await getAll(orderBy: 'due_date', ascending: false);
  }

  Stream<List<Map<String, dynamic>>> streamHomework(
      {String? teacherId}) async* {
    final filters = teacherId != null ? {'teacher_id': teacherId} : null;
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
