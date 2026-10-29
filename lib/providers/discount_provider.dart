import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/discount.dart';
import 'package:course_emis/repositories/discount_repository.dart';

final discountRepositoryProvider = Provider((ref) => DiscountRepository());

final discountsNotifierProvider = StateNotifierProvider<DiscountsNotifier, AsyncValue<List<Discount>>>((ref) {
  return DiscountsNotifier(ref.read(discountRepositoryProvider));
});

class DiscountsNotifier extends StateNotifier<AsyncValue<List<Discount>>> {
  final DiscountRepository _repository;
  
  DiscountsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadDiscounts();
  }
  
  Future<void> loadDiscounts() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getAll();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> addDiscount(Discount discount) async {
    await _repository.create(discount);
    await loadDiscounts();
  }

  Future<void> updateDiscount(Discount discount) async {
    await _repository.update(discount);
    await loadDiscounts();
  }

  Future<void> deleteDiscount(String id) async {
    await _repository.delete(id);
    await loadDiscounts();
  }
}
