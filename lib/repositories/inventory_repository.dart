import 'package:course_emis/repositories/base_repository.dart';
import 'package:course_emis/models/inventory_model.dart';

class InventoryRepository extends BaseRepository {
  InventoryRepository() : super('inventory');

  Future<List<Map<String, dynamic>>> getAllInventory() async {
    return await getAll(orderBy: 'name', ascending: true);
  }

  Future<List<InventoryItem>> getAllInventoryItems() async {
    final data = await getAllInventory();
    return data.map((item) => InventoryItem.fromJson(item)).toList();
  }

  Stream<List<Map<String, dynamic>>> streamInventory() async* {
    await for (final data in stream()) {
      yield data;
    }
  }

  Future<void> createInventoryItem(InventoryItem item) async {
    await create(item.toJson());
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    await update(item.id, item.toJson());
  }

  @override
  Future<void> create(Map<String, dynamic> data) async {
    data['created_at'] = DateTime.now().toIso8601String();
    await super.create(data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await super.update(id, data);
  }
}
