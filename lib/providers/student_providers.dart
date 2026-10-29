import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/attendance.dart';
import 'package:course_emis/repositories/courses_repository.dart';
import 'package:course_emis/repositories/homework_repository.dart';
import 'package:course_emis/repositories/grades_repository.dart';
import 'package:course_emis/repositories/attendance_repository.dart';
import 'package:course_emis/repositories/schedule_repository.dart';
import 'package:course_emis/repositories/resources_repository.dart';

// Courses Provider
final coursesRepositoryProvider = Provider<CoursesRepository>((ref) {
  return CoursesRepository();
});

final coursesStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(coursesRepositoryProvider);
  return repository.streamCourses();
});

final coursesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(coursesRepositoryProvider);
  return await repository.getAllCourses();
});

// Assignments Provider (using Homework repository)
final assignmentsRepositoryProvider = Provider<HomeworkRepository>((ref) {
  return HomeworkRepository();
});

final assignmentsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(assignmentsRepositoryProvider);
  return repository.streamHomework();
});

final assignmentsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(assignmentsRepositoryProvider);
  return await repository.getAllHomework();
});

// Grades Provider
final gradesRepositoryProvider = Provider<GradesRepository>((ref) {
  return GradesRepository();
});

final gradesStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(gradesRepositoryProvider);
  return repository.streamGrades();
});

final gradesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(gradesRepositoryProvider);
  return await repository.getAllGrades();
});

// Attendance Provider
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

final attendanceStreamProvider = StreamProvider<List<Attendance>>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.streamAttendance();
});

final attendanceProvider = FutureProvider<List<Attendance>>((ref) async {
  final repository = ref.watch(attendanceRepositoryProvider);
  return await repository.getAllAttendance();
});

// Schedule Provider
final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository();
});

final scheduleStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(scheduleRepositoryProvider);
  return repository.streamSchedule();
});

final scheduleProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(scheduleRepositoryProvider);
  return await repository.getAllSchedule();
});

// Resources Provider
final resourcesRepositoryProvider = Provider<ResourcesRepository>((ref) {
  return ResourcesRepository();
});

final resourcesStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(resourcesRepositoryProvider);
  return repository.streamResources();
});

final resourcesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(resourcesRepositoryProvider);
  return await repository.getAllResources();
});
