import 'package:course_emis/repositories/base_repository.dart';

class MessageParentsRepository extends BaseRepository {
  MessageParentsRepository() : super('messages_parents');

  Future<List<Map<String, dynamic>>> getAllMessages({String? teacherId}) async {
    if (teacherId != null) {
      return await getAll(
        filters: {'teacher_id': teacherId},
        orderBy: 'created_at',
        ascending: false,
      );
    }
    return await getAll(orderBy: 'created_at', ascending: false);
  }

  Stream<List<Map<String, dynamic>>> streamMessages(
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
}
