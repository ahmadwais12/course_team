import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_model.dart';
import '../repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(),
);

final inventoryListProvider =
    StateNotifierProvider<InventoryNotifier, List<InventoryItem>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return InventoryNotifier(repository);
});

class InventoryNotifier extends StateNotifier<List<InventoryItem>> {
  final InventoryRepository _repository;

  InventoryNotifier(this._repository) : super([]) {
    loadInventoryItems();
  }

  Future<void> loadInventoryItems() async {
    try {
      state = await _repository.getAllInventoryItems();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    await _repository.createInventoryItem(item);
    await loadInventoryItems();
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    await _repository.updateInventoryItem(item);
    await loadInventoryItems();
  }
}
