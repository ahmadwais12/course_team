import 'package:course_emis/repositories/base_repository.dart';

class EventsRepository extends BaseRepository {
  EventsRepository() : super('events');

  Future<List<Map<String, dynamic>>> getAllEvents() async {
    return await getAll(orderBy: 'date', ascending: true);
  }

  Stream<List<Map<String, dynamic>>> streamEvents() async* {
    await for (final data in stream()) {
      yield data;
    }
  }

  @override
  Future<void> create(Map<String, dynamic> data) async {
    data['created_at'] = DateTime.now().toIso8601String();
    await super.create(data);
  }
}
