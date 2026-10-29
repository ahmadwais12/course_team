import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/parent_model.dart';
import '../repositories/parent_repository.dart';

final parentRepositoryProvider = Provider((ref) => ParentRepository());

final parentListProvider = StateNotifierProvider<ParentNotifier, List<Parent>>((ref) {
  final repository = ref.watch(parentRepositoryProvider);
  return ParentNotifier(repository);
});

class ParentNotifier extends StateNotifier<List<Parent>> {
  final ParentRepository _repository;

  ParentNotifier(this._repository) : super([]) {
    loadParents();
  }

  Future<void> loadParents() async {
    try {
      state = await _repository.getParents();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> addParent(Parent parent) async {
    await _repository.addParent(parent);
    await loadParents();
  }

  Future<void> updateParent(Parent parent) async {
    await _repository.updateParent(parent);
    await loadParents();
  }
}
