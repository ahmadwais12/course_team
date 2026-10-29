import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/lms_content.dart' as models;
import 'package:course_emis/repositories/feedback_repository.dart';

final feedbackRepositoryProvider = Provider((ref) => FeedbackRepository());

final feedbackNotifierProvider = StateNotifierProvider<FeedbackNotifier,
    AsyncValue<List<models.Feedback>>>((ref) {
  return FeedbackNotifier(ref.read(feedbackRepositoryProvider));
});

class FeedbackNotifier extends StateNotifier<AsyncValue<List<models.Feedback>>> {
  final FeedbackRepository _repository;

  FeedbackNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadFeedback();
  }

  Future<void> loadFeedback() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getAll();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFeedback(models.Feedback feedback) async {
    await _repository.create(feedback);
    await loadFeedback();
  }

  Future<void> updateFeedback(models.Feedback feedback) async {
    await _repository.update(feedback);
    await loadFeedback();
  }

  Future<void> deleteFeedback(String id) async {
    await _repository.delete(id);
    await loadFeedback();
  }
}
