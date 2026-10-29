import 'package:course_emis/repositories/base_repository.dart';

class LeadsRepository extends BaseRepository {
  LeadsRepository() : super('leads');

  Future<List<Map<String, dynamic>>> getAllLeads() async {
    return await getAll(orderBy: 'created_at', ascending: false);
  }

  Stream<List<Map<String, dynamic>>> streamLeads() async* {
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
