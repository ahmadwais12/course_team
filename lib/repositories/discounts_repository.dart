import 'package:course_emis/repositories/base_repository.dart';

class DiscountsRepository extends BaseRepository {
  DiscountsRepository() : super('discounts');

  Future<List<Map<String, dynamic>>> getAllDiscounts({String? category}) async {
    if (category != null) {
      return await getAll(
        filters: {'category': category},
        orderBy: 'percentage',
        ascending: false,
      );
    }
    return await getAll(orderBy: 'created_at', ascending: false);
  }

  Stream<List<Map<String, dynamic>>> streamDiscounts(
      {String? category}) async* {
    final filters = category != null ? {'category': category} : null;
    await for (final data in stream(filters: filters)) {
      yield data;
    }
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
