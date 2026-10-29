import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/widgets/insight_ui.dart';

// â”€â”€â”€ Providers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final leaveRequestsProvider =
    StateNotifierProvider<_LeaveNotifier, List<LeaveRequest>>(
        (ref) => _LeaveNotifier());

class _LeaveNotifier extends StateNotifier<List<LeaveRequest>> {
  _LeaveNotifier() : super([]) {
    _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    try {
      final data = await Supabase.instance.client
          .from('leave_applications')
          .select()
          .order('created_at', ascending: false);
      state = (data as List).map((json) => LeaveRequest.fromJson(json)).toList();
    } catch (e) {
      state = [];
    }
  }

  Future<void> add(LeaveRequest req) async {
    try {
      await Supabase.instance.client.from('leave_applications').insert({
        'applicant_id': req.applicantId,
        'applicant_name': req.applicantName,
        'applicant_role': req.applicantRole,
        'leave_type': req.type.name,
        'date': req.date.toIso8601String(),
        'start_time': req.startTime != null
            ? '${req.startTime!.hour.toString().padLeft(2, '0')}:${req.startTime!.minute.toString().padLeft(2, '0')}'
            : null,
        'end_time': req.endTime != null
            ? '${req.endTime!.hour.toString().padLeft(2, '0')}:${req.endTime!.minute.toString().padLeft(2, '0')}'
            : null,
        'reason': req.reason,
        'status': req.status.name,
        'created_at': DateTime.now().toIso8601String(),
      });
      await _loadLeaves();
    } catch (e) {
      // Error handled by UI
    }
  }

  Future<void> updateStatus(String id, LeaveStatus status) async {
    try {
      await Supabase.instance.client
          .from('leave_applications')
          .update({
            'status': status.name,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      await _loadLeaves();
    } catch (e) {
      // Error handled by UI
    }
  }
}

// â”€â”€â”€ Model â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

enum LeaveType { fullDay, halfDay, hourly }

enum LeaveStatus { pending, approved, rejected }

class LeaveRequest {
  final String id;
  final String applicantId;
  final String applicantName;
  final String applicantRole;
  final LeaveType type;
  final DateTime date;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String reason;
  final LeaveStatus status;
  final DateTime createdAt;

  const LeaveRequest({
    required this.id,
    required this.applicantId,
    required this.applicantName,
    required this.applicantRole,
    required this.type,
    required this.date,
    this.startTime,
    this.endTime,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTime(String? time) {
      if (time == null) return null;
      final parts = time.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0);
      }
      return null;
    }

    return LeaveRequest(
      id: json['id']?.toString() ?? '',
      applicantId: json['applicant_id']?.toString() ?? '',
      applicantName: json['applicant_name']?.toString() ?? '',
      applicantRole: json['applicant_role']?.toString() ?? '',
      type: _parseLeaveType(json['leave_type']?.toString()),
      date: json['date'] is DateTime
          ? json['date'] as DateTime
          : DateTime.parse(json['date']?.toString() ?? DateTime.now().toIso8601String()),
      startTime: parseTime(json['start_time']?.toString()),
      endTime: parseTime(json['end_time']?.toString()),
      reason: json['reason']?.toString() ?? '',
      status: _parseLeaveStatus(json['status']?.toString()),
      createdAt: json['created_at'] is DateTime
          ? json['created_at'] as DateTime
          : DateTime.parse(json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }

  static LeaveType _parseLeaveType(String? type) {
    switch (type) {
      case 'fullDay':
        return LeaveType.fullDay;
      case 'halfDay':
        return LeaveType.halfDay;
      case 'hourly':
        return LeaveType.hourly;
      default:
        return LeaveType.fullDay;
    }
  }

  static LeaveStatus _parseLeaveStatus(String? status) {
    switch (status) {
      case 'pending':
        return LeaveStatus.pending;
      case 'approved':
        return LeaveStatus.approved;
      case 'rejected':
        return LeaveStatus.rejected;
      default:
        return LeaveStatus.pending;
    }
  }

  LeaveRequest copyWith({LeaveStatus? status}) => LeaveRequest(
        id: id,
        applicantId: applicantId,
        applicantName: applicantName,
        applicantRole: applicantRole,
        type: type,
        date: date,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  String get typeLabel {
    switch (type) {
      case LeaveType.fullDay:
        return 'Full Day';
      case LeaveType.halfDay:
        return 'Half Day';
      case LeaveType.hourly:
        return 'Hourly';
    }
  }

  Color get statusColor {
    switch (status) {
      case LeaveStatus.pending:
        return Colors.orange;
      case LeaveStatus.approved:
        return Colors.blue;
      case LeaveStatus.rejected:
        return Colors.red;
    }
  }

  String get statusLabel {
    switch (status) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
    }
  }
}

// â”€â”€â”€ Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class LeaveManagementScreen extends ConsumerStatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  ConsumerState<LeaveManagementScreen> createState() =>
      _LeaveManagementScreenState();
}

class _LeaveManagementScreenState
    extends ConsumerState<LeaveManagementScreen> {
  String _filter = 'All';

  String get _currentRole {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['role']?.toString().toLowerCase() ?? 'student';
  }

  bool get _isManager =>
      ['admin', 'super_admin', 'hr_manager'].contains(_currentRole);

  String get _currentApplicantId =>
      Supabase.instance.client.auth.currentUser?.id ?? 'current-user';

  String get _currentApplicantName {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['full_name']?.toString() ??
        user?.userMetadata?['name']?.toString() ??
        'Current User';
  }

  @override
  Widget build(BuildContext context) {
    final leaves = ref.watch(leaveRequestsProvider);
    final theme = Theme.of(context);
    final scopedLeaves = _isManager
        ? leaves
        : leaves.where((l) => l.applicantId == _currentApplicantId).toList();

    final filtered = _filter == 'All'
        ? scopedLeaves
        : _filter == 'Pending'
            ? scopedLeaves
                .where((l) => l.status == LeaveStatus.pending)
                .toList()
            : _filter == 'Approved'
                ? scopedLeaves
                    .where((l) => l.status == LeaveStatus.approved)
                    .toList()
                : scopedLeaves
                    .where((l) => l.status == LeaveStatus.rejected)
                    .toList();

    // Student monthly leave count
    final studentLeavesThisMonth = leaves
        .where((l) =>
            l.applicantId == _currentApplicantId &&
            l.applicantRole == 'student' &&
            l.status == LeaveStatus.approved &&
            l.date.month == DateTime.now().month)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(t(LTitle.leaveManagement, ref)),
        actions: [
          if (!_isManager)
            TextButton.icon(
              onPressed: () => _showApplyDialog(context),
              icon: const Icon(Icons.add),
              label: Text(t(L.apply, ref)),
            ),
        ],
      ),
      floatingActionButton: _isManager
          ? FloatingActionButton.extended(
              onPressed: () => _showApplyDialog(context),
              icon: const Icon(Icons.add),
              label: Text(t(LAll.all_new_leave, ref)),
            )
          : null,
      body: InsightBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // Summary cards
              _buildSummaryRow(scopedLeaves, studentLeavesThisMonth),
              const SizedBox(height: 16),

              // Student leave policy notice
              if (_currentRole == 'student')
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Students are allowed a maximum of 3 leave days per month. '
                          'Used this month: $studentLeavesThisMonth / 3',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Leave type legend
              _buildLeaveTypeLegend(theme),
              const SizedBox(height: 16),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [t(LFilter.all, ref), t(LStatus.pendingStatus, ref), t(LStatus.approved, ref), t(LCrud.reject, ref)]
                      .map((f) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(f),
                              selected: _filter == f,
                              onSelected: (_) =>
                                  setState(() => _filter = f),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Leave list
              if (filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(t(LAll.all_no_leave_requests_found, ref)),
                  ),
                )
              else
                ...filtered.map((leave) => _LeaveCard(
                      leave: leave,
                      isManager: _isManager,
                      onApprove: () async {
                        final studentApprovedCount = leaves
                            .where((l) =>
                                l.applicantId == leave.applicantId &&
                                l.applicantRole == 'student' &&
                                l.status == LeaveStatus.approved &&
                                l.date.month == leave.date.month &&
                                l.date.year == leave.date.year)
                            .length;
                        if (leave.applicantRole == 'student' &&
                            studentApprovedCount >= 3) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'This student has already used the 3 allowed leave days for this month.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }
                        await ref
                            .read(leaveRequestsProvider.notifier)
                            .updateStatus(leave.id, LeaveStatus.approved);
                      },
                      onReject: () async => await ref
                          .read(leaveRequestsProvider.notifier)
                          .updateStatus(leave.id, LeaveStatus.rejected),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(List<LeaveRequest> leaves, int studentUsed) {
    final pending =
        leaves.where((l) => l.status == LeaveStatus.pending).length;
    final approved =
        leaves.where((l) => l.status == LeaveStatus.approved).length;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: t(LStatus.pendingStatus, ref),
            value: '$pending',
            color: Colors.orange,
            icon: Icons.hourglass_empty_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: t(LStatus.approved, ref),
            value: '$approved',
            color: Colors.blue,
            icon: Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: t(LNav.students, ref),
            value: '$studentUsed/3',
            color: studentUsed >= 3 ? Colors.red : Colors.blue,
            icon: Icons.school_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveTypeLegend(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t(LAll.all_leave_types, ref),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              _TypeBadge(
                  label: 'Full Day',
                  color: Colors.blue,
                  icon: Icons.wb_sunny_rounded),
              const SizedBox(width: 12),
              _TypeBadge(
                  label: 'Half Day',
                  color: Colors.purple,
                  icon: Icons.wb_twilight_rounded),
              const SizedBox(width: 12),
              _TypeBadge(
                  label: 'Hourly',
                  color: Colors.teal,
                  icon: Icons.access_time_rounded),
            ],
          ),
        ],
      ),
    );
  }

  void _showApplyDialog(BuildContext context) {
    final isStudent = _currentRole == 'student';

    // Check student quota
    final leaves = ref.read(leaveRequestsProvider);
    final studentUsed = leaves
        .where((l) =>
            l.applicantId == _currentApplicantId &&
            l.applicantRole == 'student' &&
            l.status == LeaveStatus.approved &&
            l.date.month == DateTime.now().month)
        .length;

    if (isStudent && studentUsed >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(LAll.all_you_have_used_all_3_leave_days_for_this_month, ref)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ApplyLeavePage(
          currentRole: _currentRole,
          currentApplicantId: _currentApplicantId,
          currentApplicantName: _currentApplicantName,
        ),
        fullscreenDialog: true,
      ),
    );
  }
}

class _ApplyLeavePage extends ConsumerStatefulWidget {
  final String currentRole;
  final String currentApplicantId;
  final String currentApplicantName;

  const _ApplyLeavePage({
    required this.currentRole,
    required this.currentApplicantId,
    required this.currentApplicantName,
  });

  @override
  ConsumerState<_ApplyLeavePage> createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends ConsumerState<_ApplyLeavePage> {
  final _reasonCtrl = TextEditingController();
  LeaveType _selectedType = LeaveType.fullDay;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);

  bool get _isStudent => widget.currentRole == 'student';

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  String _leaveTypeLabel(LeaveType type) {
    switch (type) {
      case LeaveType.fullDay:
        return 'Full Day';
      case LeaveType.halfDay:
        return 'Half Day';
      case LeaveType.hourly:
        return 'Hourly';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LAll.all_apply_for_leave, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(L.cancel, ref)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t(LAll.all_leave_type, ref), style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: LeaveType.values.map((type) {
              final disabled = _isStudent && type != LeaveType.fullDay;
              return ChoiceChip(
                label: Text(_leaveTypeLabel(type)),
                selected: _selectedType == type,
                onSelected: disabled ? null : (_) => setState(() => _selectedType = type),
              );
            }).toList(),
          ),
          if (_isStudent)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Students can only apply for full day leave.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange),
              ),
            ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_rounded),
            title: Text(tt(LAll.all_xxx, ref, [_selectedDate.day.toString(), _selectedDate.month.toString(), _selectedDate.year.toString()])),
            subtitle: Text(t(LAll.all_tap_to_change_date, ref)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          if (_selectedType == LeaveType.hourly) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time_rounded),
                    title: Text(_startTime.format(context)),
                    subtitle: Text(t(LAll.all_start, ref)),
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: _startTime);
                      if (t != null) setState(() => _startTime = t);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time_filled_rounded),
                    title: Text(_endTime.format(context)),
                    subtitle: Text(t(LAll.all_end, ref)),
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: _endTime);
                      if (t != null) setState(() => _endTime = t);
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _reasonCtrl,
            decoration: InputDecoration(
              labelText: t(LCrud.leaveReason, ref),
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () { debugPrint('[leave_management_screen] Save button CLICKED'); _save(); },
            child: Text(t(L.submit, ref)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_reasonCtrl.text.trim().isEmpty) return;
    final ref = this.ref;
    final user = Supabase.instance.client.auth.currentUser;
    final notifier = ref.read(leaveRequestsProvider.notifier);
    await notifier.add(
      LeaveRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        applicantId: user?.id ?? widget.currentApplicantId,
        applicantName: user?.userMetadata?['full_name'] ??
            user?.userMetadata?['name'] ??
            widget.currentApplicantName,
        applicantRole: widget.currentRole,
        type: _selectedType,
        date: _selectedDate,
        startTime: _selectedType == LeaveType.hourly ? _startTime : null,
        endTime: _selectedType == LeaveType.hourly ? _endTime : null,
        reason: _reasonCtrl.text.trim(),
        status: LeaveStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(LStaff.leaveApplied, ref))),
      );
    }
  }
}

// â”€â”€â”€ Leave Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LeaveCard extends ConsumerWidget {
  final LeaveRequest leave;
  final bool isManager;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _LeaveCard({
    required this.leave,
    required this.isManager,
    required this.onApprove,
    required this.onReject,
  });

  Color get _typeColor {
    switch (leave.type) {
      case LeaveType.fullDay:
        return Colors.blue;
      case LeaveType.halfDay:
        return Colors.purple;
      case LeaveType.hourly:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: leave.statusColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _typeColor.withValues(alpha: 0.12),
                child: Icon(Icons.person_rounded, color: _typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(leave.applicantName,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      leave.applicantRole.replaceAll('_', ' ').toUpperCase(),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: leave.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  leave.statusLabel,
                  style: TextStyle(
                    color: leave.statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                icon: Icons.calendar_today_rounded,
                label:
                    '${leave.date.day}/${leave.date.month}/${leave.date.year}',
                color: _typeColor,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.access_time_rounded,
                label: leave.typeLabel,
                color: _typeColor,
              ),
              if (leave.type == LeaveType.hourly &&
                  leave.startTime != null) ...[
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.schedule_rounded,
                  label:
                      '${leave.startTime!.format(context)} - ${leave.endTime!.format(context)}',
                  color: Colors.teal,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            leave.reason,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (isManager && leave.status == LeaveStatus.pending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(t(LCrud.reject, ref)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(t(LCrud.approve, ref)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// â”€â”€â”€ Helper Widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _TypeBadge(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
