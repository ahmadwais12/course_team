import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/providers/admin_providers.dart';
import 'package:course_emis/widgets/common_state_widgets.dart';
import 'package:course_emis/widgets/crud_dialogs.dart';

class DepartmentsScreenRealtime extends ConsumerStatefulWidget {
  const DepartmentsScreenRealtime({super.key});

  @override
  ConsumerState<DepartmentsScreenRealtime> createState() =>
      _DepartmentsScreenRealtimeState();
}

class _DepartmentsScreenRealtimeState
    extends ConsumerState<DepartmentsScreenRealtime> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(departmentsStreamProvider);

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()), title: const Text('Departments')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: t(LCrud.searchHintGeneric, ref),
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child: departmentsAsync.when(
              data: (departments) {
                var filtered = departments.where((d) {
                  final name = d['name']?.toString().toLowerCase() ?? '';
                  final description =
                      d['description']?.toString().toLowerCase() ?? '';
                  return name.contains(searchQuery.toLowerCase()) ||
                      description.contains(searchQuery.toLowerCase());
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.business_outlined,
                    title: t(LCrud.noDepartmentsFound, ref),
                    subtitle: t(LCrud.tryAdjustSearch, ref),
                    onRefresh: () => ref.invalidate(departmentsStreamProvider),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final dept = filtered[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _showDetails(dept),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.cyan[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.business,
                                  color: Colors.cyan[700],
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dept['name']?.toString() ?? 'Untitled',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dept['description']?.toString() ??
                                          'No description',
                                      style: TextStyle(color: Colors.grey[600]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Chip(
                                          label: Text(
                                            '${dept['program_count'] ?? 0} Programs',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white),
                                          ),
                                          backgroundColor: Colors.blue,
                                          padding: EdgeInsets.zero,
                                        ),
                                        if (dept['active'] == true)
                                          Chip(
                                            label: Text(
                                              t(LCrud.active, ref),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white),
                                            ),
                                            backgroundColor: Colors.blue,
                                            padding: EdgeInsets.zero,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditDialog(context, ref, dept);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmation(context, ref, dept);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text(t(L.edit, ref)),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(t(L.delete, ref)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  LoadingWidget(message: t(L.loading, ref)),
              error: (error, stack) => CustomErrorWidget(
                error: error,
                onRetry: () => ref.invalidate(departmentsStreamProvider),
                customMessage: t(LGen.somethingWentWrong, ref),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(t(LCrud.addDepartment, ref)),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> dept) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dept['name']?.toString() ?? 'Unknown',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDetailRow(
                  t(LCrud.description, ref), dept['description']?.toString() ?? 'N/A'),
              _buildDetailRow(t(LNav.programs, ref), '${dept['program_count'] ?? 0}'),
              _buildDetailRow(
                  t(LCrud.status, ref), (dept['active'] == true) ? t(LCrud.active, ref) : t(LCrud.inactive, ref)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t(LCrud.viewDetails, ref))),
                  );
                },
                icon: const Icon(Icons.visibility),
                label: Text(t(LCrud.viewDetails, ref)),
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
        children: [
          SizedBox(
              width: 100,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Show Add Dialog with CRUD functionality
  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await CrudDialogs.showCrudDialog(
      context: context,
      ref: ref,
      title: t(LCrud.addDepartment, ref),
      fields: [
        FormFieldData(
          key: 'name',
          label: t(LCrud.departmentName, ref),
          validator: FormFieldData.required,
        ),
        FormFieldData(
          key: 'description',
          label: t(LCrud.description, ref),
          type: FormFieldType.multiline,
        ),
      ],
    );

    if (result != null) {
      try {
        // Add timestamps and default values
        result['created_at'] = DateTime.now().toIso8601String();
        result['updated_at'] = DateTime.now().toIso8601String();
        result['active'] = true;
        result['program_count'] = 0;

        // Call repository to create
        final repository = ref.read(departmentsRepositoryProvider);
        await repository.create(result);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t(LCrud.departmentSaved, ref)),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${t(L.error, ref)}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Show Edit Dialog with CRUD functionality
  Future<void> _showEditDialog(
      BuildContext context, WidgetRef ref, Map<String, dynamic> dept) async {
    final result = await CrudDialogs.showCrudDialog(
      context: context,
      ref: ref,
      title: t(LCrud.editDepartment, ref),
      fields: [
        FormFieldData(
          key: 'name',
          label: t(LCrud.departmentName, ref),
          initialValue: dept['name']?.toString(),
          validator: FormFieldData.required,
        ),
        FormFieldData(
          key: 'description',
          label: t(LCrud.description, ref),
          type: FormFieldType.multiline,
          initialValue: dept['description']?.toString(),
        ),
      ],
      existingData: dept,
    );

    if (result != null) {
      try {
        // Add updated timestamp
        result['updated_at'] = DateTime.now().toIso8601String();

        // Call repository to update
        final repository = ref.read(departmentsRepositoryProvider);
        await repository.update(dept['id'] as String, result);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t(LCrud.updatedSuccessfully, ref)),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${t(L.error, ref)}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Show Delete Confirmation
  Future<void> _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, Map<String, dynamic> dept) async {
    final confirmed = await CrudDialogs.showDeleteConfirmation(
      context: context,
      ref: ref,
      title: t(LCrud.confirmDelete, ref),
      message: t(LCrud.confirmDeleteItem, ref),
    );

    if (confirmed && context.mounted) {
      try {
        // Call repository to delete
        final repository = ref.read(departmentsRepositoryProvider);
        await repository.delete(dept['id'] as String);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t(LCrud.departmentDeleted, ref)),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${t(L.error, ref)}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

