import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/repositories/department_repository.dart';
import 'package:course_emis/repositories/homework_repository.dart';
import 'package:course_emis/repositories/invoices_repository.dart';
import 'package:course_emis/repositories/inventory_repository.dart';

// Departments Provider
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

// Homework Provider
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

// Invoices Provider
final invoicesRepositoryProvider = Provider<InvoicesRepository>((ref) {
  return InvoicesRepository();
});

final invoicesStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(invoicesRepositoryProvider);
  return repository.streamInvoices();
});

final invoicesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(invoicesRepositoryProvider);
  return await repository.getAllInvoices();
});

// Inventory Provider
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository();
});

final inventoryStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.streamInventory();
});

final inventoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return await repository.getAllInventory();
});
