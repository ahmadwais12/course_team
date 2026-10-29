import 'package:course_emis/repositories/base_repository.dart';

class ScheduleRepository extends BaseRepository {
  ScheduleRepository() : super('schedule');

  Future<List<Map<String, dynamic>>> getAllSchedule({String? classId}) async {
    if (classId != null) {
      return await getAll(
        filters: {'class_id': classId},
        orderBy: 'day_of_week',
        ascending: true,
      );
    }
    return await getAll(orderBy: 'day_of_week', ascending: true);
  }

  Stream<List<Map<String, dynamic>>> streamSchedule({String? classId}) async* {
    final filters = classId != null ? {'class_id': classId} : null;
    await for (final data in stream(filters: filters)) {
      yield data;
    }
  }

  @override
  Future<void> create(Map<String, dynamic> data) async {
    data['created_at'] = DateTime.now().toIso8601String();
    await super.create(data);
  }
}
