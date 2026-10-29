// Test models for placement test functionality
enum TestType { initial, progress, finalExam, placement }

enum TestStatus { draft, published, active, completed, archived }

enum QuestionType {
  multipleChoice,
  trueFalse,
  fillInBlank,
  listening,
  speaking,
  writing
}

class PlacementTest {
  final String id;
  final String title;
  final String description;
  final TestType type;
  final TestStatus status;
  final String languageCode;
  final int totalQuestions;
  final int passingScore;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isAdaptive;
  final int maxAttempts;

  const PlacementTest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.languageCode,
    required this.totalQuestions,
    required this.passingScore,
    required this.createdAt,
    this.expiresAt,
    this.isAdaptive = false,
    this.maxAttempts = 3,
  });

  bool get isActive => status == TestStatus.active;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

class TestAttempt {
  final String id;
  final String testId;
  final String userId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Duration timeSpent;
  final int score;
  final int maxScore;
  final double percentage;
  final String resultLevel;
  final TestStatus status;
  final List<QuestionAnswer> answers;
  final Map<String, dynamic> metadata;

  const TestAttempt({
    required this.id,
    required this.testId,
    required this.userId,
    required this.startedAt,
    this.completedAt,
    required this.timeSpent,
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.resultLevel,
    required this.status,
    required this.answers,
    this.metadata = const {},
  });

  bool get isCompleted => status == TestStatus.completed;
}

class QuestionAnswer {
  final String questionId;
  final String userAnswer;
  final String? correctAnswer;
  final bool isCorrect;
  final int points;
  final DateTime answeredAt;

  const QuestionAnswer({
    required this.questionId,
    required this.userAnswer,
    this.correctAnswer,
    required this.isCorrect,
    required this.points,
    required this.answeredAt,
  });
}

class ProgressTracking {
  final String id;
  final String userId;
  final String languageCode;
  final String currentLevel;
  final DateTime startedAt;
  final DateTime lastActivityAt;
  final int totalStudyTime;
  final int studyStreak;
  final List<String> completedLessons;
  final List<TestAttempt> testAttempts;

  const ProgressTracking({
    required this.id,
    required this.userId,
    required this.languageCode,
    required this.currentLevel,
    required this.startedAt,
    required this.lastActivityAt,
    required this.totalStudyTime,
    required this.studyStreak,
    required this.completedLessons,
    required this.testAttempts,
  });

  double get testAverageScore {
    final completed = testAttempts.where((t) => t.isCompleted).toList();
    if (completed.isEmpty) return 0.0;
    return completed.map((t) => t.percentage).reduce((a, b) => a + b) /
        completed.length;
  }
}
