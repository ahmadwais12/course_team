import 'package:course_emis/repositories/base_repository.dart';
import 'package:course_emis/models/attendance.dart';

class AttendanceRepository extends BaseRepository {
  AttendanceRepository() : super('attendance');

  Future<List<Attendance>> getAllAttendance({String? studentId}) async {
    final data = studentId != null
        ? await getAll(
            filters: {'student_id': studentId},
            orderBy: 'date',
            ascending: false,
          )
        : await getAll(orderBy: 'date', ascending: false);

    return data.map(_mapAttendance).toList();
  }

  Stream<List<Attendance>> streamAttendance({String? studentId}) async* {
    final filters = studentId != null ? {'student_id': studentId} : null;
    await for (final data in stream(filters: filters)) {
      yield data.map(_mapAttendance).toList();
    }
  }

  Future<void> createAttendance(Attendance attendance) async {
    await create(_toRepositoryJson(attendance));
  }

  Future<void> updateAttendance(Attendance attendance) async {
    await update(attendance.id, _toRepositoryJson(attendance));
  }

  Attendance _mapAttendance(Map<String, dynamic> data) {
    return Attendance.fromJson({
      'id': data['id'],
      'studentId': data['studentId'] ?? data['student_id'],
      'classId': data['classId'] ?? data['class_id'],
      'date': data['date'],
      'status': data['status'],
      'notes': data['notes'],
      'createdAt': data['createdAt'] ?? data['created_at'],
    });
  }

  Map<String, dynamic> _toRepositoryJson(Attendance attendance) {
    return {
      'id': attendance.id,
      'student_id': attendance.studentId,
      'class_id': attendance.classId,
      'date': attendance.date.toIso8601String(),
      'status': attendance.status.name,
      'notes': attendance.notes,
      'created_at': attendance.createdAt.toIso8601String(),
    };
  }

  @override
  Future<void> create(Map<String, dynamic> data) async {
    data['created_at'] = DateTime.now().toIso8601String();
    await super.create(data);
  }
}
