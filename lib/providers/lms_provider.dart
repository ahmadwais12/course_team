import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/lms_content.dart';
import 'package:course_emis/repositories/lms_repository.dart';

final lmsRepositoryProvider = Provider((ref) => LMSRepository());

final lmsNotifierProvider = StateNotifierProvider<LMSNotifier, AsyncValue<List<LMSContent>>>((ref) {
  return LMSNotifier(ref.read(lmsRepositoryProvider));
});

class LMSNotifier extends StateNotifier<AsyncValue<List<LMSContent>>> {
  final LMSRepository _repository;

  LMSNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadContent();
  }

  Future<void> loadContent() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getAll();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addContent(LMSContent content) async {
    await _repository.create(content);
    await loadContent();
  }

  Future<void> updateContent(LMSContent content) async {
    await _repository.update(content);
    await loadContent();
  }

  Future<void> deleteContent(String id) async {
    await _repository.delete(id);
    await loadContent();
  }
}
