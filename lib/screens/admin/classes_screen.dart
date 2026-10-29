import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/models/class.dart';
import 'package:course_emis/providers/class_provider.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key});

  @override
  ConsumerState<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends ConsumerState<ClassesScreen> {
  String searchQuery = '';
  String? statusFilter;

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);

    return classesAsync.when(
      data: (classes) {
        final filtered = classes.where((c) {
          final matchesSearch =
              c.id.toLowerCase().contains(searchQuery.toLowerCase());
          final matchesStatus =
              statusFilter == null || c.status == statusFilter;
          return matchesSearch && matchesStatus;
        }).toList();

        return _buildContent(filtered);
      },
      loading: () => const PageSkeleton(type: 'list'),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(t(L.error, ref),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(error.toString(), style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(classesProvider),
              icon: const Icon(Icons.refresh),
              label: Text(t(L.retry, ref)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Class> classes) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: t(LCrud.searchHintGeneric, ref),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: statusFilter,
                hint: Text(t(LCrud.status, ref)),
                items: ['All', 'Active', 'Full', 'Upcoming', 'Completed']
                    .where((s) => s != 'All')
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => setState(() => statusFilter = value),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final cls = classes[index];
              final progress = cls.enrolledCount / cls.capacity;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: InkWell(
                  onTap: () => _showDetails(cls),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(cls.status)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _getStatusColor(cls.status)),
                              ),
                              child: Text(
                                cls.status,
                                style: TextStyle(
                                  color: _getStatusColor(cls.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () => _showOptions(cls),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Class ${cls.id}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 4),
                            Text(
                                '${_formatDate(cls.startDate)} - ${_formatDate(cls.endDate)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 16),
                            const SizedBox(width: 4),
                            Text(cls.schedule.entries
                                .map((e) => '${e.key}: ${e.value}')
                                .join(', ')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${cls.enrolledCount}/${cls.capacity} students',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text('${(progress * 100).toInt()}% full'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress >= 1 ? Colors.red : Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        FloatingActionButton.extended(
          onPressed: () => _showAddEditDialog(null),
          icon: const Icon(Icons.add),
          label: Text(t(LCrud.addClass, ref)),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.blue;
      case 'full':
        return Colors.orange;
      case 'upcoming':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDetails(Class cls) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Class ${cls.id}',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDetailRow(t(LNav.programs, ref), cls.programId),
              _buildDetailRow(t(LAuth.cTeacher, ref), cls.teacherId),
              _buildDetailRow(
                  t(LCrud.capacity, ref), '${cls.enrolledCount}/${cls.capacity}'),
              _buildDetailRow(
                  t(LCourse.schedule, ref),
                  cls.schedule.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join(', ')),
              _buildDetailRow(t(LTime.startTime, ref), _formatDate(cls.startDate)),
              _buildDetailRow(t(LTime.endTime, ref), _formatDate(cls.endDate)),
              _buildDetailRow(t(LCrud.status, ref), cls.status),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddEditDialog(cls);
                },
                icon: const Icon(Icons.edit),
                label: Text(t(LCrud.editClass, ref)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showOptions(Class cls) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(t(L.edit, ref)),
              onTap: () {
                Navigator.pop(context);
                _showAddEditDialog(cls);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(t(L.delete, ref), style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(cls.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditDialog(Class? cls) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AddClassPage(existingClass: cls),
        fullscreenDialog: true,
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t(LCrud.deleteClass, ref)),
        content: Text(t(LCrud.confirmDeleteItem, ref)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t(L.cancel, ref))),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(classesNotifierProvider.notifier).deleteClass(id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(t(LCrud.classDeleted, ref)),
                        backgroundColor: Colors.blue),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${t(L.error, ref)}: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t(L.delete, ref)),
          ),
        ],
      ),
    );
  }
}

class _AddClassPage extends ConsumerStatefulWidget {
  final Class? existingClass;

  const _AddClassPage({this.existingClass});

  @override
  ConsumerState<_AddClassPage> createState() => _AddClassPageState();
}

class _AddClassPageState extends ConsumerState<_AddClassPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _programIdController;
  late final TextEditingController _teacherIdController;
  late final TextEditingController _capacityController;

  @override
  void initState() {
    super.initState();
    final cls = widget.existingClass;
    _nameController = TextEditingController(text: cls?.name ?? '');
    _programIdController = TextEditingController(text: cls?.programId ?? '');
    _teacherIdController = TextEditingController(text: cls?.teacherId ?? '');
    _capacityController =
        TextEditingController(text: cls?.capacity.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _programIdController.dispose();
    _teacherIdController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cls = widget.existingClass;
    return Scaffold(
      appBar: AppBar(
        title: Text(cls == null ? t(LCrud.addClass, ref) : t(LCrud.editClass, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t(L.cancel, ref)),
          ),
          TextButton(
            onPressed: () { debugPrint('[classes_screen] Save button CLICKED'); _save(); },
            child: Text(t(L.save, ref)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: t(LCrud.className, ref)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _programIdController,
              decoration: InputDecoration(labelText: t(LNav.programs, ref)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _teacherIdController,
              decoration: InputDecoration(labelText: t(LAuth.cTeacher, ref)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _capacityController,
              decoration: InputDecoration(labelText: t(LCrud.capacity, ref)),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final programId = _programIdController.text.trim();
    final teacherId = _teacherIdController.text.trim();
    final capacity = int.tryParse(_capacityController.text.trim()) ?? 0;
    if (name.isEmpty || programId.isEmpty) return;

    try {
      final now = DateTime.now();
      final cls = widget.existingClass;
      if (cls == null) {
        final newClass = Class(
          id: now.millisecondsSinceEpoch.toString(),
          name: name,
          programId: programId,
          teacherId: teacherId,
          capacity: capacity,
          enrolledCount: 0,
          schedule: {},
          startDate: now,
          endDate: now.add(const Duration(days: 90)),
          status: 'Active',
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(classesNotifierProvider.notifier).addClass(newClass);
      } else {
        final updated = cls.copyWith(
          name: name,
          programId: programId,
          teacherId: teacherId,
          capacity: capacity,
          updatedAt: now,
        );
        await ref.read(classesNotifierProvider.notifier).updateClass(updated);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(t(LCrud.classSaved, ref)),
              backgroundColor: Colors.blue),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${t(L.error, ref)}: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}
