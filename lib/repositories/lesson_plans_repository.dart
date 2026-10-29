import 'package:course_emis/repositories/base_repository.dart';

class LessonPlansRepository extends BaseRepository {
  LessonPlansRepository() : super('lesson_plans');

  Future<List<Map<String, dynamic>>> getAllLessonPlans(
      {String? teacherId}) async {
    if (teacherId != null) {
      return await getAll(
        filters: {'teacher_id': teacherId},
        orderBy: 'created_at',
        ascending: false,
      );
    }
    return await getAll(orderBy: 'created_at', ascending: false);
  }

  Stream<List<Map<String, dynamic>>> streamLessonPlans(
      {String? teacherId}) async* {
    final filters = teacherId != null ? {'teacher_id': teacherId} : null;
    await for (final data in stream(filters: filters)) {
      yield data;
    }
  }

  @override
  Future<void> create(Map<String, dynamic> data) async {
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
