import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/teacher.dart';
import 'package:course_emis/repositories/payroll_repository.dart';

final payrollRepositoryProvider = Provider((ref) => PayrollRepository());

final payrollNotifierProvider = StateNotifierProvider<PayrollNotifier, AsyncValue<List<Payroll>>>((ref) {
  return PayrollNotifier(ref.read(payrollRepositoryProvider));
});

class PayrollNotifier extends StateNotifier<AsyncValue<List<Payroll>>> {
  final PayrollRepository _repository;

  PayrollNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPayrolls();
  }

  Future<void> loadPayrolls() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getAll();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addPayroll(Payroll payroll) async {
    await _repository.create(payroll);
    await loadPayrolls();
  }

  Future<void> updatePayroll(Payroll payroll) async {
    await _repository.update(payroll);
    await loadPayrolls();
  }

  Future<void> deletePayroll(String id) async {
    await _repository.delete(id);
    await loadPayrolls();
  }
}
