import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hr_model.dart';
import '../repositories/hr_repository.dart';

final hrRepositoryProvider = Provider((ref) => HRRepository());

final hrListProvider = StateNotifierProvider<HRNotifier, List<HRRecord>>((ref) {
  final repository = ref.watch(hrRepositoryProvider);
  return HRNotifier(repository);
});

class HRNotifier extends StateNotifier<List<HRRecord>> {
  final HRRepository _repository;

  HRNotifier(this._repository) : super([]) {
    loadHRRecords();
  }

  Future<void> loadHRRecords() async {
    try {
      state = await _repository.getHRRecords();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> addHRRecord(HRRecord record) async {
    await _repository.addHRRecord(record);
    await loadHRRecords();
  }

  Future<void> updateHRRecord(HRRecord record) async {
    await _repository.updateHRRecord(record);
    await loadHRRecords();
  }
}
