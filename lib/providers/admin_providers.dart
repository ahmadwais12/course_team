import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/repositories/department_repository.dart';
import 'package:course_emis/repositories/programs_repository.dart';
import 'package:course_emis/repositories/classes_repository.dart';
import 'package:course_emis/repositories/discounts_repository.dart';

// Departments Provider (already exists in main_providers, re-exporting)
final departmentsRepositoryProvider = Provider<DepartmentRepository>((ref) {
  return DepartmentRepository();
});

final departmentsStreamProvider = StreamProvider<List>((ref) {
  final repository = ref.watch(departmentsRepositoryProvider);
  return repository.streamDepartments();
});

final departmentsProvider = FutureProvider<List>((ref) async {
  final repository = ref.watch(departmentsRepositoryProvider);
  return await repository.getAllDepartments();
});

// Programs Provider
final programsRepositoryProvider = Provider<ProgramsRepository>((ref) {
  return ProgramsRepository();
});

final programsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(programsRepositoryProvider);
  return repository.streamPrograms();
});

final programsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(programsRepositoryProvider);
  return await repository.getAllPrograms();
});

// Classes Provider
final classesRepositoryProvider = Provider<ClassesRepository>((ref) {
  return ClassesRepository();
});

final classesStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(classesRepositoryProvider);
  return repository.streamClasses();
});

final classesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(classesRepositoryProvider);
  return await repository.getAllClasses();
});

// Discounts Provider
final discountsRepositoryProvider = Provider<DiscountsRepository>((ref) {
  return DiscountsRepository();
});

final discountsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(discountsRepositoryProvider);
  return repository.streamDiscounts();
});

final discountsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(discountsRepositoryProvider);
  return await repository.getAllDiscounts();
});
