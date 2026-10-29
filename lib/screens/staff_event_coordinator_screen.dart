import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/ui_helpers.dart';

class StaffEventCoordinatorScreen extends ConsumerStatefulWidget {
  const StaffEventCoordinatorScreen({super.key});
  @override
  ConsumerState<StaffEventCoordinatorScreen> createState() =>
      _StaffEventCoordinatorScreenState();
}

class _StaffEventCoordinatorScreenState
    extends ConsumerState<StaffEventCoordinatorScreen> {
  final _sb = Supabase.instance.client;
  bool _loading = true;
  int _upcomingEvents = 0;
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final upcoming = await _sb
          .from('events')
          .select('id')
          .gte('start_date', today);
      final allEvents = await _sb
          .from('events')
          .select()
          .order('start_date', ascending: true);
      setState(() {
        _upcomingEvents = upcoming.length;
        _events = List<Map<String, dynamic>>.from(allEvents);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? record}) {
    final isEditing = record != null;
    final titleCtrl =
        TextEditingController(text: isEditing ? record['title'] ?? '' : '');
    final descCtrl = TextEditingController(
        text: isEditing ? record['description'] ?? '' : '');
    final startDateCtrl = TextEditingController(
        text: isEditing ? record['start_date'] ?? '' : '');
    final endDateCtrl = TextEditingController(
        text: isEditing ? record['end_date'] ?? '' : '');
    String eventType =
        isEditing ? (record['event_type'] ?? 'other') : 'other';

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
                      isEditing ? 'Edit Event' : 'New Event',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const VSpace(AppSpacing.lg),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Event title',
                      ),
                    ),
                    const VSpace(AppSpacing.md),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Event description',
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
initialValue: eventType,
                      items: const [
                        DropdownMenuItem(value: 'holiday', child: Text('Holiday')),
                        DropdownMenuItem(value: 'workshop', child: Text('Workshop')),
                        DropdownMenuItem(value: 'meeting', child: Text('Meeting')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) {
                        if (v != null) setSheetState(() => eventType = v);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Event Type',
                      ),
                    ),
                    const VSpace(AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final data = {
                            'title': titleCtrl.text.trim(),
                            'description': descCtrl.text.trim(),
                            'start_date': startDateCtrl.text.trim(),
                            'end_date': endDateCtrl.text.trim(),
                            'event_type': eventType,
                          };
                          if (data['title']!.isEmpty ||
                              data['start_date']!.isEmpty) {
                            return;
                          }
                          try {
                            if (isEditing) {
                              await _sb
                                  .from('events')
                                  .update(data)
                                  .eq('id', record['id']);
                            } else {
                              await _sb.from('events').insert(data);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _loadData();
                          } catch (_) {}
                        },
                        child: Text(isEditing ? 'Update' : 'Create'),
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
        title: const Text('Delete Event'),
        content: Text('Delete "${record['title'] ?? 'Untitled'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              try {
                await _sb.from('events').delete().eq('id', record['id']);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              } catch (_) {}
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'holiday':
        return Colors.red;
      case 'workshop':
        return Colors.blue;
      case 'meeting':
        return Colors.green;
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
            title: 'Event Coordinator',
            subtitle: 'Course events, holidays, and workshops',
            icon: Icons.event_note_outlined,
          ),
          const VSpace(AppSpacing.lg),
          StatCard(
            title: 'Upcoming Events',
            value: '$_upcomingEvents',
            icon: Icons.calendar_month_outlined,
          ),
          const VSpace(AppSpacing.lg),
          SectionHeader(
            title: 'All Events',
            subtitle: '${_events.length} total',
            icon: Icons.event_outlined,
          ),
          const VSpace(AppSpacing.md),
          if (_events.isEmpty)
            EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No events yet',
              message: 'Tap + to create a new event.',
            )
          else
            ..._events.map((ev) => _EventCard(
                  record: ev,
                  onEdit: () => _showAddEditDialog(record: ev),
                  onDelete: () => _confirmDelete(ev),
                  typeColor: _typeColor(ev['event_type'] ?? 'other'),
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

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color typeColor;

  const _EventCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
    required this.typeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = (record['event_type'] ?? 'other') as String;
    return AppCard(
      pressable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, size: 16, color: theme.colorScheme.tertiary),
              const HSpace(AppSpacing.sm),
              Expanded(
                child: Text(
                  record['title'] ?? 'Untitled',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  type[0].toUpperCase() + type.substring(1),
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if ((record['description'] ?? '').toString().isNotEmpty) ...[
            const VSpace(AppSpacing.sm),
            Text(
              record['description'] ?? '',
              style: theme.textTheme.bodyMedium,
            ),
          ],
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
