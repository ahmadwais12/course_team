import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/ui_helpers.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class StaffHRScreen extends ConsumerStatefulWidget {
  const StaffHRScreen({super.key});
  @override
  ConsumerState<StaffHRScreen> createState() => _StaffHRScreenState();
}

class _StaffHRScreenState extends ConsumerState<StaffHRScreen> {
  final _sb = Supabase.instance.client;
  bool _loading = true;
  int _totalStaff = 0;
  int _pendingLeave = 0;
  List<Map<String, dynamic>> _leaveApps = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final staff =
          await _sb.from('staff').select('id').eq('status', 'active');
      final leave = await _sb
          .from('leave_applications')
          .select('id')
          .eq('status', 'pending');
      final allLeave = await _sb
          .from('leave_applications')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _totalStaff = staff.length;
        _pendingLeave = leave.length;
        _leaveApps = List<Map<String, dynamic>>.from(allLeave);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? record}) {
    final isEditing = record != null;
    final staffIdCtrl = TextEditingController(
        text: isEditing ? (record['staff_id'] ?? '').toString() : '');
    final reasonCtrl =
        TextEditingController(text: isEditing ? record['reason'] ?? '' : '');
    final startDateCtrl = TextEditingController(
        text: isEditing ? record['start_date'] ?? '' : '');
    final endDateCtrl = TextEditingController(
        text: isEditing ? record['end_date'] ?? '' : '');
    String status = isEditing ? (record['status'] ?? 'pending') : 'pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const VSpace(AppSpacing.md),
                    Text(
                      isEditing ? 'Edit Leave Application' : 'New Leave Application',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const VSpace(AppSpacing.lg),
                    TextField(
                      controller: staffIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Staff ID',
                        hintText: 'e.g. uuid or numeric id',
                      ),
                    ),
                    const VSpace(AppSpacing.md),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        hintText: 'Reason for leave',
                      ),
                    ),
                    const VSpace(AppSpacing.md),
                    TextField(
                      controller: startDateCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        hintText: 'YYYY-MM-DD',
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setSheetState(() {
                            startDateCtrl.text =
                                picked.toIso8601String().substring(0, 10);
                          });
                        }
                      },
                    ),
                    const VSpace(AppSpacing.md),
                    TextField(
                      controller: endDateCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        hintText: 'YYYY-MM-DD',
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setSheetState(() {
                            endDateCtrl.text =
                                picked.toIso8601String().substring(0, 10);
                          });
                        }
                      },
                    ),
                    const VSpace(AppSpacing.md),
                    DropdownButtonFormField<String>(
initialValue: status,
                      items: [
                        DropdownMenuItem(
                            value: 'pending', child: Text(t(LStatus.pendingStatus, ref))),
                        DropdownMenuItem(
                            value: 'approved', child: Text(t(LStatus.approved, ref))),
                        DropdownMenuItem(
                            value: 'rejected', child: Text(t(LAll.all_rejected, ref))),
                      ],
                      onChanged: (v) {
                        if (v != null) setSheetState(() => status = v);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Status',
                      ),
                    ),
                    const VSpace(AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final data = {
                            'staff_id': staffIdCtrl.text.trim(),
                            'reason': reasonCtrl.text.trim(),
                            'start_date': startDateCtrl.text.trim(),
                            'end_date': endDateCtrl.text.trim(),
                            'status': status,
                          };
                          if (data['staff_id']!.isEmpty ||
                              data['reason']!.isEmpty) {
                            return;
                          }
                          try {
                            if (isEditing) {
                              await _sb
                                  .from('leave_applications')
                                  .update(data)
                                  .eq('id', record['id']);
                            } else {
                              await _sb.from('leave_applications').insert(data);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _loadData();
                          } catch (_) {}
                        },
                        child: Text(isEditing ? 'Update' : 'Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(LAll.all_delete_leave_application, ref)),
        content: Text(
          'Delete leave request for staff ${record['staff_id']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              try {
                await _sb
                    .from('leave_applications')
                    .delete()
                    .eq('id', record['id']);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              } catch (_) {}
            },
            child: Text(t(L.delete, ref)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      body: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          const SectionHeader(
            title: 'HR Manager',
            subtitle: 'Staff management, recruitment, and leave',
            icon: Icons.badge_outlined,
          ),
          const VSpace(AppSpacing.lg),
          StatCard(
            title: 'Active Staff',
            value: '$_totalStaff',
            icon: Icons.people_outline_rounded,
          ),
          const VSpace(AppSpacing.md),
          StatCard(
            title: 'Pending Leave Requests',
            value: '$_pendingLeave',
            icon: Icons.time_to_leave_outlined,
          ),
          const VSpace(AppSpacing.lg),
          SectionHeader(
            title: 'Leave Applications',
            subtitle: '${_leaveApps.length} total',
            icon: Icons.event_note_outlined,
          ),
          const VSpace(AppSpacing.md),
          if (_leaveApps.isEmpty)
            EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No leave applications',
              message: 'Tap + to create a new leave request.',
            )
          else
            ..._leaveApps.map((app) => _LeaveCard(
                  record: app,
                  onEdit: () => _showAddEditDialog(record: app),
                  onDelete: () => _confirmDelete(app),
                  statusColor: _statusColor(app['status'] ?? 'pending'),
                )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color statusColor;

  const _LeaveCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = (record['status'] ?? 'pending') as String;
    return AppCard(
      pressable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: theme.colorScheme.tertiary),
              const HSpace(AppSpacing.sm),
              Expanded(
                child: Text(
                  'Staff: ${record['staff_id'] ?? 'N/A'}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const VSpace(AppSpacing.sm),
          Text(
            record['reason'] ?? '',
            style: theme.textTheme.bodyMedium,
          ),
          const VSpace(AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.tertiary),
              const SizedBox(width: 6),
              Text(
                '${record['start_date'] ?? '?'}  â†’  ${record['end_date'] ?? '?'}',
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
