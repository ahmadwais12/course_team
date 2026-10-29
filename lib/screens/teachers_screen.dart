import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/models/teacher.dart';
import 'package:course_emis/providers/teacher_provider.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class TeachersScreen extends ConsumerWidget {
  const TeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachersAsync = ref.watch(teacherNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t(LNav.teachers, ref))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTeacherDialog(context, ref),
        icon: const Icon(Icons.person_add),
        label: Text(t(L.add, ref)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: teachersAsync.when(
              data: (teachers) => teachers.isEmpty
                  ? Center(
                      child: Text(t(LCrud.noResultsFound, ref),
                          style: Theme.of(context).textTheme.bodyLarge))
                  : ListView.separated(
                      itemCount: teachers.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final teacher = teachers[index];
                        return _TeacherCard(
                          teacher: teacher,
                          onEdit: () => _showTeacherDialog(context, ref, teacher: teacher),
                          onDelete: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Teacher'),
                                content: Text('Delete teacher ${teacher.userId}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t(L.cancel, ref))),
                                  FilledButton(
                                    style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              ref.read(teacherNotifierProvider.notifier).deleteTeacher(teacher.id);
                            }
                          },
                        );
                      },
                    ),
              loading: () => const ListSkeleton(itemCount: 6),
              error: (err, stack) => Center(child: Text('${t(LGen.errorDetails, ref)}: $err')),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTeacherDialog(BuildContext context, WidgetRef ref, {Teacher? teacher}) async {
    final isEdit = teacher != null;
    final formKey = GlobalKey<FormState>();
    final userIdCtl = TextEditingController(text: teacher?.userId ?? '');
    final deptIdCtl = TextEditingController(text: teacher?.departmentId ?? '');
    final salaryCtl = TextEditingController(text: teacher?.salaryAmount.toString() ?? '');
    SalaryType salaryType = teacher?.salaryType ?? SalaryType.fixed;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? t(L.edit, ref) : t(L.add, ref)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: userIdCtl,
                  decoration: const InputDecoration(labelText: 'User ID'),
                  validator: (v) => v == null || v.isEmpty ? t(L.required, ref) : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: deptIdCtl,
                  decoration: const InputDecoration(labelText: 'Department ID'),
                  validator: (v) => v == null || v.isEmpty ? t(L.required, ref) : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<SalaryType>(
initialValue: salaryType,
                  items: SalaryType.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => salaryType = v);
                  },
                  decoration: const InputDecoration(labelText: 'Salary Type'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: salaryCtl,
                  decoration: InputDecoration(
                    labelText: t(LPayment.amount, ref),
                    prefixText: 'PKR ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? t(L.required, ref) : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t(L.cancel, ref))),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final now = DateTime.now();
                if (isEdit) {
                  final updated = teacher.copyWith(
                    userId: userIdCtl.text,
                    departmentId: deptIdCtl.text,
                    salaryType: salaryType,
                    salaryAmount: double.parse(salaryCtl.text),
                  );
                  ref.read(teacherNotifierProvider.notifier).updateTeacher(updated);
                } else {
                  final newTeacher = Teacher(
                    id: 'teacher_${now.millisecondsSinceEpoch}',
                    userId: userIdCtl.text,
                    departmentId: deptIdCtl.text,
                    classIds: [],
                    salaryType: salaryType,
                    salaryAmount: double.parse(salaryCtl.text),
                    isActive: true,
                    createdAt: now,
                  );
                  ref.read(teacherNotifierProvider.notifier).addTeacher(newTeacher);
                }
                Navigator.pop(context);
              },
              child: Text(isEdit ? t(L.save, ref) : t(L.add, ref)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherCard extends ConsumerWidget {
  final Teacher teacher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeacherCard({required this.teacher, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: teacher.isActive
                    ? Colors.blue.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.2),
                child: Icon(
                  Icons.person,
                  color: teacher.isActive ? Colors.blue : Colors.grey,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User: ${teacher.userId}',
                        style: theme.textTheme.titleMedium),
                    Text(
                        '${teacher.salaryType.name} â€¢ PKR ${teacher.salaryAmount.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (!teacher.isActive)
                Chip(
                    label: Text(t(LCrud.inactive, ref)),
                    labelStyle: const TextStyle(fontSize: 10)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.outlined(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                color: theme.colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
