import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/repositories/lesson_plans_repository.dart';
import 'package:course_emis/repositories/homework_repository.dart';
import 'package:course_emis/repositories/exam_results_repository.dart';
import 'package:course_emis/repositories/student_progress_repository.dart';
import 'package:course_emis/repositories/message_parents_repository.dart';

// Lesson Plans Provider
final lessonPlansRepositoryProvider = Provider<LessonPlansRepository>((ref) {
  return LessonPlansRepository();
});

final lessonPlansStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(lessonPlansRepositoryProvider);
  return repository.streamLessonPlans();
});

final lessonPlansProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(lessonPlansRepositoryProvider);
  return await repository.getAllLessonPlans();
});

// Homework Provider (already exists in main_providers, re-exporting here for convenience)
final homeworkRepositoryProvider = Provider<HomeworkRepository>((ref) {
  return HomeworkRepository();
});

final homeworkStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(homeworkRepositoryProvider);
  return repository.streamHomework();
});

final homeworkProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(homeworkRepositoryProvider);
  return await repository.getAllHomework();
});

// Exam Results Provider
final examResultsRepositoryProvider = Provider<ExamResultsRepository>((ref) {
  return ExamResultsRepository();
});

final examResultsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(examResultsRepositoryProvider);
  return repository.streamExamResults();
});

final examResultsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(examResultsRepositoryProvider);
  return await repository.getAllExamResults();
});

// Student Progress Provider
final studentProgressRepositoryProvider =
    Provider<StudentProgressRepository>((ref) {
  return StudentProgressRepository();
});

final studentProgressStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(studentProgressRepositoryProvider);
  return repository.streamStudentProgress();
});

final studentProgressProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(studentProgressRepositoryProvider);
  return await repository.getAllStudentProgress();
});

// Message Parents Provider
final messageParentsRepositoryProvider =
    Provider<MessageParentsRepository>((ref) {
  return MessageParentsRepository();
});

final messageParentsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(messageParentsRepositoryProvider);
  return repository.streamMessages();
});

final messageParentsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(messageParentsRepositoryProvider);
  return await repository.getAllMessages();
});
