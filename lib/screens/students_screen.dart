import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/models/program.dart';
import 'package:course_emis/models/student.dart';
import 'package:course_emis/providers/student_provider.dart';
import 'package:course_emis/widgets/insight_ui.dart';
import 'package:course_emis/widgets/modern_ui.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(LNav.students, ref)),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.file_download_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegistrationDialog(context, ref),
        icon: const Icon(Icons.person_add_rounded),
        label: Text(t(L.add, ref)),
      ),
      body: InsightBackground(
        maxWidth: 1200,
        child: studentsAsync.when(
          data: (students) {
            final filtered = students
                .where(
                  (student) => student.id
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()),
                )
                .toList();

            final activeCount = students
                .where((student) => student.status == StudentStatus.active)
                .length;
            final outstandingCount = students
                .where((student) => student.hasOutstandingBalance)
                .length;
            final excellenceCount = students
                .where((student) => student.hasExcellenceDiscount)
                .length;

            return SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  const InsightHeroCard(
                    eyebrow: 'Student operations',
                    title: 'Student lifecycle and enrollment health',
                    subtitle:
                        'Monitor admissions, fee position, and academic readiness through a cleaner overview before diving into individual records.',
                    accent: Color(0xFF2563EB),
                    chips: [
                      InsightStatChip(label: 'Retention', value: '92%'),
                      InsightStatChip(label: 'Attendance', value: '89%'),
                      InsightStatChip(label: 'Risk alerts', value: '07'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: 240,
                        child: InsightMetricCard(
                          label: 'Active students',
                          value: '$activeCount',
                          trend: '+11%',
                          icon: Icons.groups_rounded,
                          accent: Colors.blue,
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: InsightMetricCard(
                          label: 'Outstanding balances',
                          value: '$outstandingCount',
                          trend: outstandingCount > 0 ? 'Watch' : 'Clear',
                          icon: Icons.warning_amber_rounded,
                          accent: Colors.orange,
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: InsightMetricCard(
                          label: 'Scholarship holders',
                          value: '$excellenceCount',
                          trend: '+3%',
                          icon: Icons.workspace_premium_outlined,
                          accent: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 840;
                      final lineCard = InsightLineChartCard(
                        title: 'Enrollment flow',
                        subtitle: 'Recent weekly student intake pacing.',
                        points: _buildEnrollmentPoints(students),
                        accent: Colors.blue,
                      );
                      final segmentsCard = InsightSegmentsCard(
                        title: 'Student mix',
                        subtitle:
                            'A quick split of active, pending fees, and scholarship students.',
                        segments: [
                          InsightSegment(
                            label: 'Active',
                            value: activeCount
                                .toDouble()
                                .clamp(1, double.infinity),
                            color: Colors.blue,
                          ),
                          InsightSegment(
                            label: 'Outstanding',
                            value: outstandingCount
                                .toDouble()
                                .clamp(1, double.infinity),
                            color: Colors.orange,
                          ),
                          InsightSegment(
                            label: 'Scholarship',
                            value: excellenceCount
                                .toDouble()
                                .clamp(1, double.infinity),
                            color: Colors.blue,
                          ),
                        ],
                      );

                      if (narrow) {
                        return Column(
                          children: [
                            lineCard,
                            const SizedBox(height: 16),
                            segmentsCard,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: lineCard),
                          const SizedBox(width: 16),
                          Expanded(child: segmentsCard),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const InsightProcessDiagram(
                    title: 'Student journey diagram',
                    subtitle:
                        'A clear path from lead registration to long-term retention.',
                    accent: Color(0xFF2563EB),
                    steps: [
                      InsightFlowStep(
                        title: 'Lead',
                        subtitle: 'Capture inquiry and qualification details.',
                        icon: Icons.person_search_outlined,
                      ),
                      InsightFlowStep(
                        title: 'Enroll',
                        subtitle: 'Confirm program, duration, and fee plan.',
                        icon: Icons.assignment_ind_outlined,
                      ),
                      InsightFlowStep(
                        title: 'Support',
                        subtitle: 'Track attendance, grades, and follow-up.',
                        icon: Icons.support_agent_outlined,
                      ),
                      InsightFlowStep(
                        title: 'Retain',
                        subtitle:
                            'Renew or move the student into the next offer.',
                        icon: Icons.favorite_outline_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InsightTableCard(
                    title: 'Student table',
                    subtitle:
                        'Key account and academic details for the latest students.',
                    columns: const ['Student', 'Program', 'Status', 'Balance'],
                    rows: _buildStudentRows(filtered),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    child: TextField(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: t(LCrud.searchHintGeneric, ref),
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 72,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t(LCrud.noStudentsFound, ref),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    )
                  else
                    ...filtered.map(
                      (student) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _EnhancedStudentCard(
                          student: student,
                          onEdit: () => _showRegistrationDialog(
                              context, ref, student: student),
                          onDelete: () => ref
                              .read(studentsNotifierProvider.notifier)
                              .deleteStudent(student.id),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () => const ListSkeleton(itemCount: 8),
          error: (err, stack) => Center(
            child: Text('${t(LGen.errorDetails, ref)}: $err', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  List<InsightPoint> _buildEnrollmentPoints(List<Student> students) {
    final base = students.isEmpty ? 8 : students.length.toDouble();
    return [
      InsightPoint('Mon', base + 4),
      InsightPoint('Tue', base + 6),
      InsightPoint('Wed', base + 8),
      InsightPoint('Thu', base + 12),
      InsightPoint('Fri', base + 10),
      InsightPoint('Sat', base + 14),
    ];
  }

  List<List<String>> _buildStudentRows(List<Student> students) {
    if (students.isEmpty) {
      return [
        [t(L.noData, ref), '-', '-', '-'],
      ];
    }

    return students.take(4).map((student) {
      return [
        student.id.substring(0, student.id.length.clamp(0, 14)),
        student.programId.replaceFirst('prog_', '').toUpperCase(),
        student.status.name.toUpperCase(),
        'PKR ${student.remainingBalance.toStringAsFixed(0)}',
      ];
    }).toList();
  }

  Future<void> _showRegistrationDialog(
      BuildContext context, WidgetRef ref, {Student? student}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _StudentRegistrationPage(student: student),
        fullscreenDialog: true,
      ),
    );
    if (result == true) setState(() {});
  }
}

class _StudentRegistrationPage extends ConsumerStatefulWidget {
  final Student? student;
  const _StudentRegistrationPage({this.student});

  @override
  ConsumerState<_StudentRegistrationPage> createState() => _StudentRegistrationPageState();
}

class _StudentRegistrationPageState extends ConsumerState<_StudentRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _durations = {
    ProgramType.CL: [4],
    ProgramType.DEL: [6, 12],
    ProgramType.TOEFL: [6, 12],
    ProgramType.IELTS: [6, 12],
  };
  final _pricing = {4: 40000.0, 6: 60000.0, 12: 120000.0};

  late ProgramType _selectedProgram;
  late int _selectedDuration;
  late double _discount;

  bool get _isEditing => widget.student != null;

  @override
  void initState() {
    super.initState();
    _selectedProgram = _isEditing
        ? ProgramType.values.firstWhere(
            (p) => 'prog_${p.name}' == widget.student!.programId,
            orElse: () => ProgramType.CL,
          )
        : ProgramType.CL;
    _selectedDuration = _isEditing ? widget.student!.duration : 4;
    _discount = _isEditing ? widget.student!.discount : 0;
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final totalFees = _pricing[_selectedDuration]! * (1 - _discount / 100);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Student' : t(LPanelUI.studentRegistration, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t(L.cancel, ref)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<ProgramType>(
              initialValue: _selectedProgram,
              decoration: InputDecoration(
                labelText: t(LNav.programs, ref),
                prefixIcon: Icon(Icons.school),
              ),
              items: ProgramType.values
                  .take(4)
                  .map((program) => DropdownMenuItem(value: program, child: Text(program.name)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedProgram = value;
                    _selectedDuration = _durations[value]!.first;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _selectedDuration,
              decoration: InputDecoration(
                labelText: t(LCourse.duration, ref),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              items: _durations[_selectedProgram]!
                  .map((duration) => DropdownMenuItem(value: duration, child: Text('$duration months')))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedDuration = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _discount.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Discount',
                prefixIcon: Icon(Icons.discount),
                suffixText: '%',
              ),
              onChanged: (value) {
                final parsed = double.tryParse(value) ?? 0;
                setState(() => _discount = parsed.clamp(0, 100));
              },
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              ),
              child: Column(
                children: [
                  _FeeRow('Base Fee', 'PKR ${_pricing[_selectedDuration]!.toStringAsFixed(0)}'),
                  if (_discount > 0) ...[
                    const SizedBox(height: 8),
                    _FeeRow(
                      'Discount',
                      '-PKR ${(_pricing[_selectedDuration]! * _discount / 100).toStringAsFixed(0)}',
                      color: Colors.blue,
                    ),
                  ],
                  const Divider(height: 24),
                  _FeeRow('Total', 'PKR ${totalFees.toStringAsFixed(0)}', isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () { debugPrint('[students_screen] Save button CLICKED'); _save(); },
              child: Text(_isEditing ? t(L.save, ref) : t(LFlow.register, ref)),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final ref = this.ref;
    final now = DateTime.now();
    final totalFees = _pricing[_selectedDuration]! * (1 - _discount / 100);
    final notifier = ref.read(studentsNotifierProvider.notifier);
    if (_isEditing) {
      final updated = widget.student!.copyWith(
        programId: 'prog_${_selectedProgram.name}',
        duration: _selectedDuration,
        discount: _discount,
        totalFees: totalFees,
        updatedAt: now,
      );
      notifier.updateStudent(updated);
    } else {
      final newStudent = Student(
        id: 'student_${now.millisecondsSinceEpoch}',
        userId: 'user_${now.millisecondsSinceEpoch}',
        programId: 'prog_${_selectedProgram.name}',
        duration: _selectedDuration,
        classId: 'class_default',
        status: StudentStatus.active,
        totalFees: totalFees,
        paidAmount: 0,
        discount: _discount,
        enrollmentDate: now,
        attendancePercentage: 0,
        averageGrade: 0,
        hasExcellenceDiscount: false,
        createdAt: now,
        updatedAt: now,
      );
      notifier.addStudent(newStudent);
    }
    Navigator.pop(context, true);
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool isBold;

  const _FeeRow(this.label, this.value, {this.color, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.bold : null,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: isBold ? FontWeight.bold : null,
              ),
        ),
      ],
    );
  }
}

class _EnhancedStudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EnhancedStudentCard(
      {required this.student, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.withValues(alpha: 0.8), Colors.blue],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.person, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student ${student.id.substring(8, 20)}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        '${student.duration} months program',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                ModernBadge(
                  label: student.status.name.toUpperCase(),
                  color: student.status == StudentStatus.active
                      ? Colors.blue
                      : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _InfoColumn(
                    'Total Fees',
                    'PKR ${student.totalFees.toStringAsFixed(0)}',
                    Icons.attach_money,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _InfoColumn(
                    'Paid',
                    'PKR ${student.paidAmount.toStringAsFixed(0)}',
                    Icons.check_circle,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _InfoColumn(
                    'Balance',
                    'PKR ${student.remainingBalance.toStringAsFixed(0)}',
                    Icons.pending,
                    student.hasOutstandingBalance ? Colors.red : Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton.outlined(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoColumn(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
