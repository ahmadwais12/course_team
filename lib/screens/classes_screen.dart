import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/models/class.dart';
import 'package:course_emis/providers/class_provider.dart';
import 'package:course_emis/widgets/modern_ui.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesNotifierProvider);

    return Scaffold(
      appBar: ModernAppBar(title: t(LNav.classes, ref), hasGradient: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
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
            child: classesAsync.when(
          data: (classes) => classes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.class_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No classes found',
                          style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: classes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final cls = classes[index];
                    return _EnhancedClassCard(
                      classItem: cls,
                      onDelete: () => ref
                          .read(classesNotifierProvider.notifier)
                          .deleteClass(cls.id),
                    );
                  },
                ),
          loading: () => const ListSkeleton(itemCount: 5),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
      ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _AddClassPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) ref.invalidate(classesNotifierProvider);
  }
}

class _AddClassPage extends ConsumerStatefulWidget {
  const _AddClassPage();

  @override
  ConsumerState<_AddClassPage> createState() => _AddClassPageState();
}

class _AddClassPageState extends ConsumerState<_AddClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _capacityCtl = TextEditingController(text: '30');

  @override
  void dispose() {
    _nameCtl.dispose();
    _capacityCtl.dispose();
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
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.class_, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Text(t(L.add, ref)),
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
              controller: _nameCtl,
              decoration: InputDecoration(
                labelText: t(LCrud.className, ref),
                prefixIcon: const Icon(Icons.label),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _capacityCtl,
              decoration: InputDecoration(
                labelText: t(LCrud.capacity, ref),
                prefixIcon: const Icon(Icons.people),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            ModernButton(
              label: t(L.add, ref),
              icon: Icons.check,
              onPressed: () { debugPrint('[classes_screen] Save button CLICKED'); _save(); },
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
    final cls = Class(
      id: 'class_${now.millisecondsSinceEpoch}',
      name: _nameCtl.text,
      programId: 'prog_default',
      teacherId: 'teacher_default',
      capacity: int.parse(_capacityCtl.text),
      enrolledCount: 0,
      schedule: {'Mon': '9:00 AM', 'Wed': '9:00 AM', 'Fri': '9:00 AM'},
      startDate: now,
      endDate: now.add(const Duration(days: 120)),
      status: 'active',
      createdAt: now,
      updatedAt: now,
    );
    ref.read(classesNotifierProvider.notifier).addClass(cls);
    Navigator.pop(context, true);
  }
}

class _EnhancedClassCard extends StatelessWidget {
  final Class classItem;
  final VoidCallback onDelete;

  const _EnhancedClassCard({required this.classItem, required this.onDelete});

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
                      colors: [
                        Colors.orange.withValues(alpha: 0.8),
                        Colors.orange
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.class_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class ${classItem.id.substring(6, 14)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${classItem.enrolledCount}/${classItem.capacity} students',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                ModernBadge(
                    label: classItem.status.toUpperCase(), color: Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: classItem.schedule.entries
                  .map((e) => Chip(
                        label: Text('${e.key}: ${e.value}',
                            style: const TextStyle(fontSize: 11)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
