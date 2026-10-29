import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/models/department.dart';
import 'package:course_emis/providers/department_provider.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class DepartmentsScreen extends ConsumerStatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  ConsumerState<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends ConsumerState<DepartmentsScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(departmentsProvider);

    return departmentsAsync.when(
      data: (departments) {
        final filtered = departments
            .where(
                (d) => d.name.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

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
              onPressed: () => ref.invalidate(departmentsProvider),
              icon: const Icon(Icons.refresh),
              label: Text(t(L.retry, ref)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Department> departments) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: t(LCrud.searchHintGeneric, ref),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) => setState(() => searchQuery = value),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: departments.length,
            itemBuilder: (context, index) {
              final dept = departments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      dept.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    dept.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(dept.description),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showAddEditDialog(dept),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(dept.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        FloatingActionButton.extended(
          onPressed: () => _showAddEditDialog(null),
          icon: const Icon(Icons.add),
          label: Text(t(LCrud.addDepartment, ref)),
        ),
      ],
    );
  }

  void _showAddEditDialog(Department? department) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AddDepartmentPage(existingDepartment: department),
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
        title: Text(t(LCrud.confirmDelete, ref)),
        content: Text(t(LCrud.confirmDeleteItem, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t(L.cancel, ref)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(departmentsNotifierProvider.notifier)
                    .deleteDepartment(id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(t(LCrud.departmentDeleted, ref)),
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

class _AddDepartmentPage extends ConsumerStatefulWidget {
  final Department? existingDepartment;

  const _AddDepartmentPage({this.existingDepartment});

  @override
  ConsumerState<_AddDepartmentPage> createState() => _AddDepartmentPageState();
}

class _AddDepartmentPageState extends ConsumerState<_AddDepartmentPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final dept = widget.existingDepartment;
    _nameController = TextEditingController(text: dept?.name ?? '');
    _descriptionController = TextEditingController(text: dept?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dept = widget.existingDepartment;
    return Scaffold(
      appBar: AppBar(
        title: Text(dept == null
            ? t(LCrud.addDepartment, ref)
            : t(LCrud.editDepartment, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t(L.cancel, ref)),
          ),
          TextButton(
            onPressed: () { debugPrint('[departments_screen] Save button CLICKED'); _save(); },
            child: Text(t(L.save, ref)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: t(LCrud.departmentName, ref)),
              controller: _nameController,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: t(LCrud.description, ref)),
              controller: _descriptionController,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    if (name.isEmpty) return;

    try {
      final now = DateTime.now();
      final dept = widget.existingDepartment;
      if (dept == null) {
        final newDept = Department(
          id: now.millisecondsSinceEpoch.toString(),
          name: name,
          description: description,
          programIds: [],
          teacherIds: [],
          createdAt: now,
          updatedAt: now,
        );
        await ref
            .read(departmentsNotifierProvider.notifier)
            .addDepartment(newDept);
      } else {
        final updated = dept.copyWith(
          name: name,
          description: description,
          updatedAt: now,
        );
        await ref
            .read(departmentsNotifierProvider.notifier)
            .updateDepartment(updated);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(t(LCrud.departmentSaved, ref)),
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
