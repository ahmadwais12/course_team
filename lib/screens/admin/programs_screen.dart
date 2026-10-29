import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/models/program.dart';
import 'package:course_emis/providers/program_provider.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class ProgramsScreen extends ConsumerStatefulWidget {
  const ProgramsScreen({super.key});

  @override
  ConsumerState<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends ConsumerState<ProgramsScreen> {
  String searchQuery = '';
  ProgramType? selectedType;

  @override
  Widget build(BuildContext context) {
    final programsAsync = ref.watch(programsProvider);

    return programsAsync.when(
      data: (programs) {
        final filtered = programs.where((p) {
          final matchesSearch =
              p.name.toLowerCase().contains(searchQuery.toLowerCase());
          final matchesType = selectedType == null || p.type == selectedType;
          return matchesSearch && matchesType;
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
              onPressed: () => ref.invalidate(programsProvider),
              icon: const Icon(Icons.refresh),
              label: Text(t(L.retry, ref)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Program> programs) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
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
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(t(LFilter.all, ref)),
                      selected: selectedType == null,
                      onSelected: (selected) =>
                          setState(() => selectedType = null),
                    ),
                    ...ProgramType.values.map((type) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChip(
                            label: Text(type.name),
                            selected: selectedType == type,
                            onSelected: (selected) => setState(
                                () => selectedType = selected ? type : null),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: programs.map((program) {
              return Card(
                elevation: 3,
                child: InkWell(
                  onTap: () => _showDetails(program),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: program.isActive
                                    ? Colors.blue[100]
                                    : Colors.red[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                program.type.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: program.isActive
                                      ? Colors.blue[800]
                                      : Colors.red[800],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert, size: 20),
                              onPressed: () => _showOptions(program),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          program.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          program.description,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(Icons.people,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('${program.enrolledStudents} students'),
                            const SizedBox(width: 12),
                            Icon(Icons.attach_money,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                                'From \$${program.pricing.values.reduce((a, b) => a < b ? a : b)}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        FloatingActionButton.extended(
          onPressed: () => _showAddEditDialog(null),
          icon: const Icon(Icons.add),
          label: Text(t(LCrud.addProgram, ref)),
        ),
      ],
    );
  }

  void _showDetails(Program program) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                program.name,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(t(LColumn.cType, ref), program.type.name),
              _buildDetailRow(t(LCrud.description, ref), program.description),
              _buildDetailRow(t(LCourse.duration, ref),
                  '${program.allowedDurations.join(', ')} months'),
              _buildDetailRow(
                  t(LCourse.price, ref),
                  program.pricing.entries
                      .map((e) => '${e.key}mo: \$${e.value}')
                      .join(', ')),
              _buildDetailRow(
                  t(LDash2.enrollments, ref), '${program.enrolledStudents}'),
              _buildDetailRow(
                  t(LCrud.status, ref), program.isActive ? t(LCrud.active, ref) : t(LCrud.inactive, ref)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddEditDialog(program);
                },
                icon: const Icon(Icons.edit),
                label: Text(t(LCrud.editProgram, ref)),
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
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showOptions(Program program) {
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
                _showAddEditDialog(program);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(t(L.delete, ref), style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(program.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditDialog(Program? program) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AddProgramPage(existingProgram: program),
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
              child: Text(t(L.cancel, ref))),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(programsNotifierProvider.notifier).deleteProgram(id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(t(LCrud.programDeleted, ref)),
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

class _AddProgramPage extends ConsumerStatefulWidget {
  final Program? existingProgram;

  const _AddProgramPage({this.existingProgram});

  @override
  ConsumerState<_AddProgramPage> createState() => _AddProgramPageState();
}

class _AddProgramPageState extends ConsumerState<_AddProgramPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _departmentIdController;

  @override
  void initState() {
    super.initState();
    final program = widget.existingProgram;
    _nameController = TextEditingController(text: program?.name ?? '');
    _descriptionController =
        TextEditingController(text: program?.description ?? '');
    _departmentIdController =
        TextEditingController(text: program?.departmentId ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _departmentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final program = widget.existingProgram;
    return Scaffold(
      appBar: AppBar(
        title: Text(program == null
            ? t(LCrud.addProgram, ref)
            : t(LCrud.editProgram, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t(L.cancel, ref)),
          ),
          TextButton(
            onPressed: () { debugPrint('[programs_screen] Save button CLICKED'); _save(); },
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
              decoration: InputDecoration(labelText: t(LCrud.programName, ref)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _departmentIdController,
              decoration: InputDecoration(labelText: t(LColumn.name, ref)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: t(LCrud.description, ref)),
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
    final departmentId = _departmentIdController.text.trim();
    if (name.isEmpty || departmentId.isEmpty) return;

    try {
      final now = DateTime.now();
      final program = widget.existingProgram;
      if (program == null) {
        final newProgram = Program(
          id: now.millisecondsSinceEpoch.toString(),
          name: name,
          code: '',
          type: ProgramType.CL,
          departmentId: departmentId,
          allowedDurations: [3],
          pricing: {3: 0.0},
          description: description,
          isActive: true,
          enrolledStudents: 0,
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(programsNotifierProvider.notifier).addProgram(newProgram);
      } else {
        final updated = program.copyWith(
          name: name,
          description: description,
          departmentId: departmentId,
          updatedAt: now,
        );
        await ref.read(programsNotifierProvider.notifier).updateProgram(updated);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(t(LCrud.programSaved, ref)),
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
