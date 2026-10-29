import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:course_emis/models/placement_test.dart';

class PlacementTestService {
  static final PlacementTestService _instance = PlacementTestService._internal();
  factory PlacementTestService() => _instance;
  PlacementTestService._internal();

  final _sb = Supabase.instance.client;

  Future<List<PlacementTest>> getAvailableTests(String languageCode) async {
    try {
      final data = await _sb
          .from('placement_tests')
          .select()
          .eq('language_code', languageCode)
          .inFilter('status', ['active', 'published'])
          .order('created_at', ascending: false);

      return data.map<PlacementTest>((row) => _mapTest(row)).toList();
    } catch (e) {
      debugPrint('Error getting placement tests: $e');
      return [];
    }
  }

  Future<PlacementTest?> getTestById(String testId) async {
    try {
      final data = await _sb
          .from('placement_tests')
          .select()
          .eq('id', testId)
          .maybeSingle();

      if (data == null) return null;
      return _mapTest(data);
    } catch (e) {
      debugPrint('Error getting test by ID: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getTestQuestions(String testId) async {
    try {
      final data = await _sb
          .from('test_questions')
          .select()
          .eq('test_id', testId)
          .order('order', ascending: true);

      return data.map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();
    } catch (e) {
      debugPrint('Error getting test questions: $e');
      return [];
    }
  }

  Future<TestAttempt> startTestAttempt(String testId, String userId) async {
    try {
      final attempt = {
        'test_id': testId,
        'user_id': userId,
        'started_at': DateTime.now().toIso8601String(),
        'time_spent': 0,
        'score': 0,
        'max_score': 0,
        'percentage': 0.0,
        'result_level': '',
        'status': 'active',
        'answers': [],
      };

      final result = await _sb.from('test_attempts').insert(attempt).select().single();
      return _mapAttempt(result);
    } catch (e) {
      debugPrint('Error starting test attempt: $e');
      rethrow;
    }
  }

  Future<void> submitAnswer(String attemptId, QuestionAnswer answer) async {
    try {
      final attempt = await _sb
          .from('test_attempts')
          .select('answers')
          .eq('id', attemptId)
          .maybeSingle();

      final answers = (attempt != null && attempt['answers'] != null)
          ? List<Map<String, dynamic>>.from(attempt['answers'] as List)
          : <Map<String, dynamic>>[];

      answers.add({
        'question_id': answer.questionId,
        'user_answer': answer.userAnswer,
        'correct_answer': answer.correctAnswer,
        'is_correct': answer.isCorrect,
        'points': answer.points,
        'answered_at': answer.answeredAt.toIso8601String(),
      });

      await _sb.from('test_attempts').update({'answers': answers}).eq('id', attemptId);
    } catch (e) {
      debugPrint('Error submitting answer: $e');
    }
  }

  Future<TestAttempt> completeTestAttempt(String attemptId) async {
    try {
      final data = await _sb
          .from('test_attempts')
          .select('*, placement_tests!inner(passing_score)')
          .eq('id', attemptId)
          .maybeSingle();

      if (data == null) throw Exception('Attempt not found');

      final answers = data['answers'] as List? ?? [];
      int score = 0;
      int maxScore = 0;
      for (final a in answers) {
        final aMap = a as Map<String, dynamic>;
        score += (aMap['is_correct'] == true ? (aMap['points'] as int? ?? 1) : 0);
        maxScore += (aMap['points'] as int? ?? 1);
      }

      final percentage = maxScore > 0 ? (score / maxScore) * 100 : 0.0;
      final timeSpent = DateTime.now().difference(DateTime.parse(data['started_at'] as String));

      await _sb.from('test_attempts').update({
        'completed_at': DateTime.now().toIso8601String(),
        'time_spent': timeSpent.inSeconds,
        'score': score,
        'max_score': maxScore,
        'percentage': percentage,
        'result_level': percentage >= 80 ? 'Advanced' : (percentage >= 60 ? 'Intermediate' : 'Beginner'),
        'status': 'completed',
      }).eq('id', attemptId);

      final updated = await _sb.from('test_attempts').select().eq('id', attemptId).single();
      return _mapAttempt(updated);
    } catch (e) {
      debugPrint('Error completing test attempt: $e');
      rethrow;
    }
  }

  Future<List<TestAttempt>> getUserAttempts(String userId, {String? testId}) async {
    try {
      var query = _sb.from('test_attempts').select().eq('user_id', userId);
      if (testId != null) {
        query = query.eq('test_id', testId);
      }
      final data = await query.order('started_at', ascending: false);
      return data.map<TestAttempt>((row) => _mapAttempt(row)).toList();
    } catch (e) {
      debugPrint('Error getting user attempts: $e');
      return [];
    }
  }

  Future<ProgressTracking?> getProgressTracking(String userId, String languageCode) async {
    try {
      final data = await _sb
          .from('progress_tracking')
          .select()
          .eq('user_id', userId)
          .eq('language_code', languageCode)
          .maybeSingle();

      if (data == null) return null;

      final attempts = await getUserAttempts(userId);
      return ProgressTracking(
        id: data['id'] as String,
        userId: data['user_id'] as String,
        languageCode: data['language_code'] as String,
        currentLevel: data['current_level'] as String? ?? 'Beginner',
        startedAt: DateTime.parse(data['started_at'] as String),
        lastActivityAt: data['last_activity_at'] != null
            ? DateTime.parse(data['last_activity_at'] as String)
            : DateTime.now(),
        totalStudyTime: data['total_study_time'] as int? ?? 0,
        studyStreak: data['study_streak'] as int? ?? 0,
        completedLessons: (data['completed_lessons'] as List?)?.map((e) => e.toString()).toList() ?? [],
        testAttempts: attempts,
      );
    } catch (e) {
      debugPrint('Error getting progress tracking: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getTestAnalytics(String testId) async {
    try {
      final attempts = await _sb
          .from('test_attempts')
          .select('score, max_score, percentage')
          .eq('test_id', testId)
          .eq('status', 'completed');

      final total = attempts.length;
      if (total == 0) return {'total_attempts': 0, 'average_score': 0.0, 'pass_rate': 0.0};

      double totalScore = 0;
      int passed = 0;
      for (final a in attempts) {
        totalScore += (a['percentage'] as num?)?.toDouble() ?? 0.0;
        if (((a['percentage'] as num?)?.toDouble() ?? 0.0) >= 60) passed++;
      }

      return {
        'total_attempts': total,
        'average_score': totalScore / total,
        'pass_rate': total > 0 ? passed / total : 0.0,
      };
    } catch (e) {
      debugPrint('Error getting test analytics: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getUserAnalytics(String userId, String languageCode) async {
    try {
      final progress = await getProgressTracking(userId, languageCode);
      if (progress == null) return {};

      return {
        'current_level': progress.currentLevel,
        'total_study_time': progress.totalStudyTime,
        'study_streak': progress.studyStreak,
        'completed_lessons': progress.completedLessons.length,
        'test_attempts': progress.testAttempts.length,
        'average_test_score': progress.testAverageScore,
      };
    } catch (e) {
      debugPrint('Error getting user analytics: $e');
      return {};
    }
  }

  PlacementTest _mapTest(Map<String, dynamic> row) {
    return PlacementTest(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String? ?? '',
      type: _parseTestType(row['type'] as String? ?? 'placement'),
      status: _parseTestStatus(row['status'] as String? ?? 'active'),
      languageCode: row['language_code'] as String? ?? 'en',
      totalQuestions: row['total_questions'] as int? ?? 0,
      passingScore: row['passing_score'] as int? ?? 0,
      createdAt: DateTime.parse(row['created_at'] as String),
      expiresAt: row['expires_at'] != null ? DateTime.parse(row['expires_at'] as String) : null,
      isAdaptive: row['is_adaptive'] as bool? ?? false,
      maxAttempts: row['max_attempts'] as int? ?? 3,
    );
  }

  TestAttempt _mapAttempt(Map<String, dynamic> row) {
    final answersList = (row['answers'] as List?)?.map((a) {
      final m = a as Map<String, dynamic>;
      return QuestionAnswer(
        questionId: m['question_id'] as String? ?? '',
        userAnswer: m['user_answer'] as String? ?? '',
        correctAnswer: m['correct_answer'] as String?,
        isCorrect: m['is_correct'] as bool? ?? false,
        points: m['points'] as int? ?? 0,
        answeredAt: m['answered_at'] != null
            ? DateTime.parse(m['answered_at'] as String)
            : DateTime.now(),
      );
    }).toList() ?? [];

    return TestAttempt(
      id: row['id'] as String,
      testId: row['test_id'] as String,
      userId: row['user_id'] as String,
      startedAt: DateTime.parse(row['started_at'] as String),
      completedAt: row['completed_at'] != null ? DateTime.parse(row['completed_at'] as String) : null,
      timeSpent: Duration(seconds: row['time_spent'] as int? ?? 0),
      score: row['score'] as int? ?? 0,
      maxScore: row['max_score'] as int? ?? 0,
      percentage: (row['percentage'] as num?)?.toDouble() ?? 0.0,
      resultLevel: row['result_level'] as String? ?? '',
      status: _parseTestStatus(row['status'] as String? ?? 'active'),
      answers: answersList,
    );
  }

  TestType _parseTestType(String value) {
    return TestType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TestType.placement,
    );
  }

  TestStatus _parseTestStatus(String value) {
    return TestStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TestStatus.active,
    );
  }
}
