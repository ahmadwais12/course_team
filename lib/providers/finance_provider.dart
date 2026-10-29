import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/finance_model.dart';
import '../repositories/finance_repository.dart';

final financeRepositoryProvider = Provider((ref) => FinanceRepository());

final financeListProvider = StateNotifierProvider<FinanceNotifier, List<Finance>>((ref) {
  final repository = ref.watch(financeRepositoryProvider);
  return FinanceNotifier(repository);
});

class FinanceNotifier extends StateNotifier<List<Finance>> {
  final FinanceRepository _repository;

  FinanceNotifier(this._repository) : super([]) {
    loadFinanceRecords();
  }

  Future<void> loadFinanceRecords() async {
    try {
      state = await _repository.getFinanceRecords();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> addFinanceRecord(Finance finance) async {
    await _repository.addFinanceRecord(finance);
    await loadFinanceRecords();
  }

  Future<void> updateFinanceRecord(Finance finance) async {
    await _repository.updateFinanceRecord(finance);
    await loadFinanceRecords();
  }
}
