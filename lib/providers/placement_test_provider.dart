import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/placement_test.dart';
import 'package:course_emis/services/placement_test_service.dart';

final placementTestServiceProvider = Provider<PlacementTestService>((ref) {
  return PlacementTestService();
});

final availableTestsProvider =
    FutureProvider.family<List<PlacementTest>, String>(
        (ref, languageCode) async {
  final service = ref.read(placementTestServiceProvider);
  return service.getAvailableTests(languageCode);
});

final testProvider =
    FutureProvider.family<PlacementTest?, String>((ref, testId) async {
  final service = ref.read(placementTestServiceProvider);
  return service.getTestById(testId);
});

final currentAttemptProvider =
    StateNotifierProvider<AttemptNotifier, TestAttempt?>((ref) {
  return AttemptNotifier();
});

class AttemptNotifier extends StateNotifier<TestAttempt?> {
  AttemptNotifier() : super(null);

  void startAttempt(TestAttempt attempt) {
    state = attempt;
  }

  void updateAnswer(QuestionAnswer answer) {
    if (state == null) return;

    final existingAnswers = List<QuestionAnswer>.from(state!.answers);
    final index =
        existingAnswers.indexWhere((a) => a.questionId == answer.questionId);

    if (index != -1) {
      existingAnswers[index] = answer;
    } else {
      existingAnswers.add(answer);
    }

    state = TestAttempt(
      id: state!.id,
      testId: state!.testId,
      userId: state!.userId,
      startedAt: state!.startedAt,
      completedAt: state!.completedAt,
      timeSpent: DateTime.now().difference(state!.startedAt),
      score: existingAnswers.where((a) => a.isCorrect).length,
      maxScore: state!.maxScore,
      percentage: state!.percentage,
      resultLevel: state!.resultLevel,
      status: state!.status,
      answers: existingAnswers,
      metadata: state!.metadata,
    );
  }

  void completeAttempt(TestAttempt attempt) {
    state = attempt;
  }

  void clearAttempt() {
    state = null;
  }
}

final progressTrackingProvider =
    FutureProvider.family<ProgressTracking?, (String, String)>(
        (ref, params) async {
  final (userId, languageCode) = params;
  final service = ref.read(placementTestServiceProvider);
  return service.getProgressTracking(userId, languageCode);
});

final testAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, testId) async {
  final service = ref.read(placementTestServiceProvider);
  return service.getTestAnalytics(testId);
});

final userAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, (String, String)>(
        (ref, params) async {
  final (userId, languageCode) = params;
  final service = ref.read(placementTestServiceProvider);
  return service.getUserAnalytics(userId, languageCode);
});
