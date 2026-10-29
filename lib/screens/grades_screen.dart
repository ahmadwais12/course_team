import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/models/attendance.dart';
import 'package:course_emis/providers/grade_provider.dart';
import 'package:course_emis/widgets/modern_ui.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class GradesScreen extends ConsumerWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(gradeNotifierProvider);

    return Scaffold(
      appBar: ModernAppBar(title: t(LNav.grades, ref), hasGradient: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGradeDialog(context, ref),
        icon: const Icon(Icons.grade),
        label: Text(t(L.add, ref)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
            child: gradesAsync.when(
          data: (grades) => grades.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.grade_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(t(LCrud.noResultsFound, ref),
                          style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: grades.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _EnhancedGradeCard(
                        grade: grades[index],
                        onEdit: () => _showGradeDialog(context, ref,
                            grade: grades[index]),
                        onDelete: () => _confirmDelete(context, ref, grades[index]),
                      ),
                ),
          loading: () => const ExamsSkeleton(),
          error: (err, stack) => Center(child: Text('${t(LGen.errorDetails, ref)}: $err')),
        ),
      ),
      ),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Grade grade) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
        title: Text(t(LCrud.confirmDelete, ref)),
        content: Text(
          'Delete grade for Student: ${grade.studentId} in Class: ${grade.classId}?',
        ),
        actions: [
          ModernButton(
            label: t(L.cancel, ref),
            onPressed: () => Navigator.pop(ctx, false),
            isOutlined: true,
          ),
          ModernButton(
            label: t(L.delete, ref),
            icon: Icons.delete,
            color: Colors.red,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(gradeNotifierProvider.notifier).deleteGrade(grade.id);
    }
  }

  Future<void> _showGradeDialog(BuildContext context, WidgetRef ref,
      {Grade? grade}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _GradeFormPage(grade: grade),
        fullscreenDialog: true,
      ),
    );
    if (result == true) ref.invalidate(gradeNotifierProvider);
  }
}

class _GradeFormPage extends ConsumerStatefulWidget {
  final Grade? grade;
  const _GradeFormPage({this.grade});

  @override
  ConsumerState<_GradeFormPage> createState() => _GradeFormPageState();
}

class _GradeFormPageState extends ConsumerState<_GradeFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _studentIdCtl;
  late final TextEditingController _classIdCtl;
  late final TextEditingController _midtermCtl;
  late final TextEditingController _finalCtl;
  late final TextEditingController _attendanceCtl;

  bool get _isEditing => widget.grade != null;

  @override
  void initState() {
    super.initState();
    _studentIdCtl = TextEditingController(text: widget.grade?.studentId ?? '');
    _classIdCtl = TextEditingController(text: widget.grade?.classId ?? '');
    _midtermCtl = TextEditingController(text: widget.grade?.midterm?.toString() ?? '');
    _finalCtl = TextEditingController(text: widget.grade?.finalExam?.toString() ?? '');
    _attendanceCtl = TextEditingController(text: widget.grade?.attendanceScore.toString() ?? '0');
  }

  @override
  void dispose() {
    _studentIdCtl.dispose();
    _classIdCtl.dispose();
    _midtermCtl.dispose();
    _finalCtl.dispose();
    _attendanceCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.grade, color: Colors.purple),
            ),
            const SizedBox(width: 12),
            Text(_isEditing ? t(L.edit, ref) : t(L.add, ref)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t(L.cancel, ref))),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _studentIdCtl,
              decoration: InputDecoration(
                labelText: t(LExtra.studentId, ref),
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.isEmpty ? t(L.required, ref) : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _classIdCtl,
              decoration: InputDecoration(
                labelText: t(LCrud.className, ref),
                prefixIcon: const Icon(Icons.class_),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.isEmpty ? t(L.required, ref) : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _midtermCtl,
              decoration: InputDecoration(
                labelText: t(LCrud.grade, ref),
                prefixIcon: const Icon(Icons.quiz),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _finalCtl,
              decoration: InputDecoration(
                labelText: t(LExam.score, ref),
                prefixIcon: const Icon(Icons.assignment),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _attendanceCtl,
              decoration: InputDecoration(
                labelText: '${t(LNav.attendance, ref)} ${t(LExam.score, ref)}',
                prefixIcon: const Icon(Icons.event_available),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? t(L.required, ref) : null,
            ),
            const SizedBox(height: 24),
            ModernButton(
              label: _isEditing ? t(L.save, ref) : t(L.add, ref),
              icon: Icons.check,
              onPressed: () { debugPrint('[grades_screen] Save button CLICKED'); _save(); },
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final ref = this.ref;
    final now = DateTime.now();
    final midterm = _midtermCtl.text.isEmpty ? null : double.parse(_midtermCtl.text);
    final finalExam = _finalCtl.text.isEmpty ? null : double.parse(_finalCtl.text);
    final attendance = double.parse(_attendanceCtl.text);
    final total = ((midterm ?? 0) + (finalExam ?? 0) + attendance) / 3;

    if (_isEditing) {
      final updated = widget.grade!.copyWith(
        studentId: _studentIdCtl.text,
        classId: _classIdCtl.text,
        midterm: midterm,
        finalExam: finalExam,
        attendanceScore: attendance,
        totalScore: total,
        updatedAt: now,
      );
      ref.read(gradeNotifierProvider.notifier).updateGrade(updated);
    } else {
      final newGrade = Grade(
        id: 'grade_${now.millisecondsSinceEpoch}',
        studentId: _studentIdCtl.text,
        classId: _classIdCtl.text,
        quizzes: [],
        homework: [],
        midterm: midterm,
        finalExam: finalExam,
        attendanceScore: attendance,
        totalScore: total,
        createdAt: now,
        updatedAt: now,
      );
      ref.read(gradeNotifierProvider.notifier).addGrade(newGrade);
    }
    Navigator.pop(context, true);
  }
}

class _EnhancedGradeCard extends StatelessWidget {
  final Grade grade;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EnhancedGradeCard({
    required this.grade,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = grade.totalScore >= 90
        ? Colors.blue
        : grade.totalScore >= 70
            ? Colors.blue
            : grade.totalScore >= 50
                ? Colors.orange
                : Colors.red;

    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.8), color],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${grade.totalScore.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student: ${grade.studentId}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Class: ${grade.classId}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                ModernBadge(
                  label: grade.totalScore >= 90
                      ? 'A'
                      : grade.totalScore >= 70
                          ? 'B'
                          : grade.totalScore >= 50
                              ? 'C'
                              : 'F',
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (grade.midterm != null)
                  _ScoreColumn(
                      'Midterm', grade.midterm!, Icons.quiz, Colors.blue),
                if (grade.finalExam != null)
                  _ScoreColumn('Final', grade.finalExam!, Icons.assignment,
                      Colors.purple),
                _ScoreColumn('Attendance', grade.attendanceScore,
                    Icons.event_available, Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit',
                  onPressed: onEdit,
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Delete',
                  color: Colors.red,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
      ),
      ),
    );
  }
}

class _ScoreColumn extends StatelessWidget {
  final String label;
  final double score;
  final IconData icon;
  final Color color;

  const _ScoreColumn(this.label, this.score, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          score.toStringAsFixed(0),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
