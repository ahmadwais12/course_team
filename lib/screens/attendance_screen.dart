import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/attendance.dart';
import 'package:course_emis/providers/attendance_provider.dart';
import 'package:course_emis/widgets/modern_ui.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(attendanceNotifierProvider);

    return Scaffold(
      appBar: ModernAppBar(title: t(LTitle.attendanceLabel, ref), hasGradient: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMarkDialog(context, ref),
        icon: const Icon(Icons.check_circle),
        label: Text(t(L.save, ref)),
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
            child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                children: [
                  _FilterChip('All', _filter == 'All',
                      () => setState(() => _filter = 'All')),
                  _FilterChip('Present', _filter == 'Present',
                      () => setState(() => _filter = 'Present')),
                  _FilterChip('Absent', _filter == 'Absent',
                      () => setState(() => _filter = 'Absent')),
                  _FilterChip('Late', _filter == 'Late',
                      () => setState(() => _filter = 'Late')),
                ],
              ),
            ),
            Expanded(
              child: attendanceAsync.when(
                data: (records) {
                  final filtered = _filter == 'All'
                      ? records
                      : records
                          .where((r) =>
                              r.status.name.toLowerCase() ==
                              _filter.toLowerCase())
                          .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available_outlined,
                              size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('No attendance records',
                              style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _EnhancedAttendanceCard(
                          record: filtered[index],
                          onEdit: () => _showMarkDialog(
                            context, ref, record: filtered[index]),
                          onDelete: () =>
                              _showDeleteDialog(context, ref, filtered[index]),
                        ),
                  );
                },
                loading: () => const AttendanceSkeleton(),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
  );
  }

  Future<void> _showMarkDialog(
      BuildContext context, WidgetRef ref,
      {Attendance? record}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AttendanceFormPage(record: record),
        fullscreenDialog: true,
      ),
    );
    if (result == true) setState(() {});
  }

  Future<void> _showDeleteDialog(
      BuildContext context, WidgetRef ref, Attendance record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: Colors.red, size: 48),
        title: Text(t(L.delete, ref)),
        content: Text(t(LCrud.confirmDeleteItem, ref)),
        actions: [
          ModernButton(
              label: t(L.cancel, ref),
              onPressed: () => Navigator.pop(context, false),
              isOutlined: true),
          ModernButton(
            label: t(L.delete, ref),
            icon: Icons.delete_outline,
            color: Colors.red,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ref
          .read(attendanceNotifierProvider.notifier)
          .deleteAttendance(record.id);
    }
  }
}

class _AttendanceFormPage extends ConsumerStatefulWidget {
  final Attendance? record;
  const _AttendanceFormPage({this.record});

  @override
  ConsumerState<_AttendanceFormPage> createState() => _AttendanceFormPageState();
}

class _AttendanceFormPageState extends ConsumerState<_AttendanceFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _studentIdCtl;
  late final TextEditingController _classIdCtl;
  late AttendanceStatus _status;

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    _studentIdCtl = TextEditingController(text: _isEditing ? widget.record!.studentId : '');
    _classIdCtl = TextEditingController(text: _isEditing ? widget.record!.classId : '');
    _status = _isEditing ? widget.record!.status : AttendanceStatus.present;
  }

  @override
  void dispose() {
    _studentIdCtl.dispose();
    _classIdCtl.dispose();
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
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_isEditing ? Icons.edit : Icons.check_circle, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Text(_isEditing ? t(L.edit, ref) : t(L.save, ref)),
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
              controller: _studentIdCtl,
              decoration: InputDecoration(
                labelText: t(LExtra.studentId, ref),
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _classIdCtl,
              decoration: InputDecoration(
                labelText: t(LCrud.className, ref),
                prefixIcon: const Icon(Icons.class_),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AttendanceStatus>(
initialValue: _status,
              decoration: InputDecoration(
                labelText: t(LCrud.status, ref),
                prefixIcon: const Icon(Icons.event_available),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: AttendanceStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
            const SizedBox(height: 24),
            ModernButton(
              label: t(_isEditing ? L.confirm : L.save, ref),
              icon: _isEditing ? Icons.save : Icons.check,
              onPressed: () { debugPrint('[attendance_screen] Save button CLICKED'); _save(); },
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
      final updated = widget.record!.copyWith(
        studentId: _studentIdCtl.text,
        classId: _classIdCtl.text,
        status: _status,
      );
      ref.read(attendanceNotifierProvider.notifier).updateAttendance(updated);
    } else {
      final now = DateTime.now();
      final attendance = Attendance(
        id: 'att_${now.millisecondsSinceEpoch}',
        studentId: _studentIdCtl.text,
        classId: _classIdCtl.text,
        date: now,
        status: _status,
        createdAt: now,
      );
      ref.read(attendanceNotifierProvider.notifier).addAttendance(attendance);
    }
    Navigator.pop(context, true);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip(this.label, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
    );
  }
}

class _EnhancedAttendanceCard extends ConsumerWidget {
  final Attendance record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EnhancedAttendanceCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = record.status == AttendanceStatus.present
        ? Colors.blue
        : record.status == AttendanceStatus.late
            ? Colors.orange
            : record.status == AttendanceStatus.leave
                ? Colors.blue
                : Colors.red;

    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    record.status == AttendanceStatus.present
                        ? Icons.check
                        : record.status == AttendanceStatus.late
                            ? Icons.schedule
                            : record.status == AttendanceStatus.leave
                                ? Icons.event_busy
                                : Icons.close,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student: ${record.studentId}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${record.date.day}/${record.date.month}/${record.date.year}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                ModernBadge(label: record.status.name.toUpperCase(), color: color),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.blue,
                    backgroundColor:
                        Colors.blue.withValues(alpha: 0.08),
                  ),
                  tooltip: t(L.edit, ref),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.red,
                    backgroundColor:
                        Colors.red.withValues(alpha: 0.08),
                  ),
                  tooltip: t(L.delete, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
