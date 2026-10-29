import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:course_emis/l10n/locale_keys.dart';

class EnglishTestScreen extends ConsumerStatefulWidget {
  const EnglishTestScreen({super.key});

  @override
  ConsumerState<EnglishTestScreen> createState() => _EnglishTestScreenState();
}

class _EnglishTestScreenState extends ConsumerState<EnglishTestScreen> {
  List<Map<String, dynamic>> _tests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    try {
      final data = await Supabase.instance.client
          .from('placement_tests')
          .select()
          .eq('is_active', true)
          .order('level_order', ascending: true);
      if (mounted) setState(() => _tests = List<Map<String, dynamic>>.from(data));
    } catch (_) {
      if (mounted) setState(() => _tests = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _colorForLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'basic':
      case 'beginner':
        return Colors.blue;
      case 'intermediate':
        return Colors.blue;
      case 'advanced':
        return Colors.purple;
      default:
        return Colors.teal;
    }
  }

  IconData _iconForLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'basic':
      case 'beginner':
        return Icons.star;
      case 'intermediate':
        return Icons.star_half;
      case 'advanced':
        return Icons.workspace_premium;
      default:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(LLearning.placementTest, ref)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadTests,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(t(LCrud.noResultsFound, ref), style: theme.textTheme.bodyLarge),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTests,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          t(LCourse.level, ref),
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t(LLearning.placementTest, ref),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Expanded(
                          child: ListView(
                            children: _tests.map((t) {
                              final level = t['level_name']?.toString() ?? t['title']?.toString() ?? 'Unknown';
                              final description = t['description']?.toString() ?? '';
                              final color = _colorForLevel(level);
                              final icon = _iconForLevel(level);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _LevelCard(
                                  level: level,
                                  description: description,
                                  icon: icon,
                                  color: color,
                                  onTap: () => _startTest(context, level),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  void _startTest(BuildContext context, String level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestQuestionScreen(level: level),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final String level;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(level, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

class TestQuestionScreen extends ConsumerStatefulWidget {
  final String level;

  const TestQuestionScreen({super.key, required this.level});

  @override
  ConsumerState<TestQuestionScreen> createState() => _TestQuestionScreenState();
}

class _TestQuestionScreenState extends ConsumerState<TestQuestionScreen> {
  List<Map<String, dynamic>> _questions = [];
  bool _loading = true;
  int _currentQuestion = 0;
  int _score = 0;
  int? _selectedAnswer;
  final List<Map<String, dynamic>> _userAnswers = [];
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final data = await Supabase.instance.client
          .from('test_questions')
          .select()
          .eq('level', widget.level)
          .order('question_order', ascending: true);
      if (mounted) {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectAnswer(int selected, int correct) {
    if (_selectedAnswer != null) return;
    setState(() {
      _selectedAnswer = selected;
      if (selected == correct) _score++;
      _userAnswers.add({
        'question_id': _questions[_currentQuestion]['id'],
        'selected': selected,
        'correct': correct,
        'is_correct': selected == correct,
      });
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestion++;
      _selectedAnswer = null;
    });
  }

  Future<void> _showResults() async {
    final percentage = _questions.isEmpty ? 0 : (_score / _questions.length * 100).round();
    final percentageStr = _questions.isEmpty ? '0.0' : (_score / _questions.length * 100).toStringAsFixed(1);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id ?? '';
      final testId = _questions.isNotEmpty ? _questions.first['test_id'] : null;

      if (userId.isNotEmpty) {
        await Supabase.instance.client.from('test_attempts').insert({
          'user_id': userId,
          if (testId != null) 'test_id': testId,
          'level': widget.level,
          'score': _score,
          'total_questions': _questions.length,
          'percentage': percentageStr,
          'answers': _userAnswers.map((a) => {
            'question_id': a['question_id'],
            'selected': a['selected'],
            'correct': a['correct'],
            'is_correct': a['is_correct'],
          }).toList(),
          'status': 'completed',
          'started_at': _startTime?.toIso8601String(),
          'completed_at': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t(LCrud.savedSuccessfully, ref))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save results: $e')),
        );
      }
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(LExam.examSubmitted, ref)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You scored $_score out of ${_questions.length}'),
            const SizedBox(height: 8),
            Text(
              '$percentage%',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: percentage >= 70 ? Colors.blue : Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(t(L.close, ref)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.level} Test')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.level} Test')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(t(LCrud.noResultsFound, ref), style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    final question = _questions[_currentQuestion];
    final options = question['options'] as List<dynamic>? ?? [];
    final correctIndex = (question['correct_answer'] ?? question['correct']) is int
        ? (question['correct_answer'] ?? question['correct']) as int
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.level} Test'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_currentQuestion + 1) / _questions.length,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              '${t(LExam.question, ref)} ${_currentQuestion + 1} / ${_questions.length}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 32),
            Text(
              question['question']?.toString() ?? '',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ...List.generate(
              options.length,
              (index) {
                final isSelected = _selectedAnswer == index;
                final isCorrect = index == correctIndex;
                final showResult = _selectedAnswer != null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: showResult ? null : () => _selectAnswer(index, correctIndex),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: !showResult
                            ? theme.colorScheme.surface
                            : isCorrect
                                ? Colors.blue.withValues(alpha: 0.1)
                                : isSelected
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !showResult
                              ? theme.dividerColor
                              : isCorrect
                                  ? Colors.blue
                                  : isSelected
                                      ? Colors.red
                                      : theme.dividerColor,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? Colors.blue
                                  : isSelected
                                      ? Colors.red
                                      : theme.colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index),
                                style: TextStyle(
                                  color: isCorrect || isSelected ? Colors.white : theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              options[index]?.toString() ?? '',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const Spacer(),
            if (_selectedAnswer != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _currentQuestion < _questions.length - 1
                      ? _nextQuestion
                      : _showResults,
                  child: Text(
                    _currentQuestion < _questions.length - 1
                        ? t(LExam.question, ref)
                        : t(LExam.examResults, ref),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
