import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/models/department.dart';
import 'package:course_emis/providers/department_provider.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/motion.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class DepartmentsScreen extends ConsumerWidget {
  const DepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentsAsync = ref.watch(departmentsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t(LNav.departments, ref))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(t(LCrud.addDepartment, ref)),
      ),
      body: Padding(
        padding: AppSpacing.paddingLg,
        child: departmentsAsync.when(
          data: (departments) => departments.isEmpty
              ? Center(
                  child: Text('No departments found',
                      style: Theme.of(context).textTheme.bodyLarge))
              : ListView.separated(
                  itemCount: departments.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final dept = departments[index];
                    return AnimatedListItem(
                      index: index,
                      child: _DepartmentCard(
                        department: dept,
                        onEdit: () => _showEditDialog(context, ref, dept),
                        onDelete: () => ref
                            .read(departmentsNotifierProvider.notifier)
                            .deleteDepartment(dept.id),
                      ),
                    );
                  },
                ),
          loading: () => const ListSkeleton(itemCount: 5),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _DepartmentFormPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) ref.invalidate(departmentsNotifierProvider);
  }

  Future<void> _showEditDialog(
      BuildContext context, WidgetRef ref, Department dept) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _DepartmentFormPage(department: dept),
        fullscreenDialog: true,
      ),
    );
    if (result == true) ref.invalidate(departmentsNotifierProvider);
  }
}

class _DepartmentFormPage extends ConsumerStatefulWidget {
  final Department? department;
  const _DepartmentFormPage({this.department});

  @override
  ConsumerState<_DepartmentFormPage> createState() => _DepartmentFormPageState();
}

class _DepartmentFormPageState extends ConsumerState<_DepartmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtl;
  late final TextEditingController _descCtl;

  bool get _isEditing => widget.department != null;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.department?.name ?? '');
    _descCtl = TextEditingController(text: widget.department?.description ?? '');
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _descCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? t(LCrud.editDepartment, ref) : t(LCrud.addDepartment, ref)),
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
              controller: _nameCtl,
              decoration: InputDecoration(labelText: t(LCrud.departmentName, ref)),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _descCtl,
              decoration: InputDecoration(labelText: t(LCrud.description, ref)),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () { debugPrint('[departments_screen] Save button CLICKED'); _save(); },
              child: Text(_isEditing ? t(L.save, ref) : t(L.add, ref)),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final ref = this.ref;
    if (_isEditing) {
      final updated = widget.department!.copyWith(
        name: _nameCtl.text.trim(),
        description: _descCtl.text.trim(),
        updatedAt: DateTime.now(),
      );
      ref.read(departmentsNotifierProvider.notifier).updateDepartment(updated);
    } else {
      final now = DateTime.now();
      final dept = Department(
        id: 'dept_${now.millisecondsSinceEpoch}',
        name: _nameCtl.text.trim(),
        description: _descCtl.text.trim(),
        programIds: [],
        teacherIds: [],
        createdAt: now,
        updatedAt: now,
      );
      ref.read(departmentsNotifierProvider.notifier).addDepartment(dept);
    }
    Navigator.pop(context, true);
  }
}

class _DepartmentCard extends StatelessWidget {
  final Department department;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DepartmentCard({
    required this.department,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: AppSpacing.paddingLg,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.account_tree_rounded)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(department.name, style: theme.textTheme.titleLarge),
                      Text(department.description,
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                Chip(label: Text('${department.programIds.length} Programs')),
                Chip(label: Text('${department.teacherIds.length} Teachers')),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.outlined(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: theme.colorScheme.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
