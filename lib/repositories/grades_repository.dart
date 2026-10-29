import 'package:course_emis/repositories/base_repository.dart';

class GradesRepository extends BaseRepository {
  GradesRepository() : super('grades');

  Future<List<Map<String, dynamic>>> getAllGrades({String? studentId}) async {
    if (studentId != null) {
      return await getAll(
        filters: {'student_id': studentId},
        orderBy: 'created_at',
        ascending: false,
      );
    }
    return await getAll(orderBy: 'created_at', ascending: false);
  }

  Stream<List<Map<String, dynamic>>> streamGrades({String? studentId}) async* {
    final filters = studentId != null ? {'student_id': studentId} : null;
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
