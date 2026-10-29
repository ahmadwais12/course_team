import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/attendance.dart';
import 'package:course_emis/repositories/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepository(),
);

final attendanceNotifierProvider =
    StateNotifierProvider<AttendanceNotifier, AsyncValue<List<Attendance>>>(
  (ref) => AttendanceNotifier(ref.read(attendanceRepositoryProvider)),
);

class AttendanceNotifier extends StateNotifier<AsyncValue<List<Attendance>>> {
  final AttendanceRepository _repository;

  AttendanceNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getAllAttendance();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addAttendance(Attendance attendance) async {
    await _repository.createAttendance(attendance);
    await loadAttendance();
  }

  Future<void> updateAttendance(Attendance attendance) async {
    await _repository.updateAttendance(attendance);
    await loadAttendance();
  }

  Future<void> deleteAttendance(String id) async {
    await _repository.delete(id);
    await loadAttendance();
  }
}
