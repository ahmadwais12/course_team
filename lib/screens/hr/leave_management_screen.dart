import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/leave_models.dart';
import '../../widgets/base_panel_layout.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

final leaveApplicationsProvider = StreamProvider.family<List<LeaveApplication>, Map<String, dynamic>?>((ref, filters) {
  final supabase = Supabase.instance.client;
  var query = supabase.from('leave_applications').stream(primaryKey: ['id']);
  
  if (filters != null) {
    final status = filters['status'] as String?;
    final applicantType = filters['applicant_type'] as String?;
    
    return query.map((data) {
      var filtered = data;
      if (status != null) {
        filtered = filtered.where((l) => l['status'] == status).toList();
      }
      if (applicantType != null) {
        filtered = filtered.where((l) => l['applicant_type'] == applicantType).toList();
      }
      return filtered.map((json) => LeaveApplication.fromJson(json)).toList();
    });
  }
  
  return query.map((data) => data.map((json) => LeaveApplication.fromJson(json)).toList());
});

final pendingLeavesProvider = FutureProvider<List<LeaveApplication>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('leave_applications')
      .select()
      .eq('status', 'pending')
      .order('created_at', ascending: false);
  return (response as List).map((json) => LeaveApplication.fromJson(json)).toList();
});

class LeaveManagementScreen extends ConsumerStatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  ConsumerState<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends ConsumerState<LeaveManagementScreen> {
  final _reasonController = TextEditingController();
  final _rejectionReasonController = TextEditingController();
  
  String? _selectedApplicantId;
  String? _selectedApplicantType;
  String? _selectedLeaveTypeId;
  String? _selectedLeaveCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedStatus;
  bool _isCreating = false;

  final List<String> _applicantTypes = ['student', 'teacher', 'staff'];
  final List<String> _leaveCategories = ['full_day', 'half_day', 'hourly'];
  final List<String> _statuses = ['pending', 'approved', 'rejected', 'cancelled'];

  @override
  void dispose() {
    _reasonController.dispose();
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _createLeaveApplication() async {
    if (_selectedApplicantId == null || _reasonController.text.isEmpty || _startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(LCrud.fillRequiredFields, ref))),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final supabase = Supabase.instance.client;
      
      // Calculate total days
      double totalDays = 0;
      if (_endDate != null) {
        totalDays = _endDate!.difference(_startDate!).inDays + 1;
      } else {
        totalDays = 1; // Single day leave
      }
      
      // Adjust for half day
      if (_selectedLeaveCategory == 'half_day') {
        totalDays = totalDays * 0.5;
      }

      final leaveData = {
        'applicant_id': _selectedApplicantId,
        'applicant_type': _selectedApplicantType ?? 'staff',
        'leave_type_id': _selectedLeaveTypeId,
        'leave_category': _selectedLeaveCategory ?? 'full_day',
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
        'total_days': totalDays,
        'reason': _reasonController.text.trim(),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('leave_applications').insert(leaveData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaff.leaveApplied, ref))),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  void _clearForm() {
    _reasonController.clear();
    setState(() {
      _selectedApplicantId = null;
      _selectedApplicantType = null;
      _selectedLeaveTypeId = null;
      _selectedLeaveCategory = null;
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _approveLeave(LeaveApplication leave) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('leave_applications').update({
        'status': 'approved',
        'approved_by': supabase.auth.currentUser?.id,
        'approved_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', leave.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaff.leaveApproved, ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    }
  }

  Future<void> _rejectLeave(LeaveApplication leave) async {
    if (_rejectionReasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(LCrud.rejectReason, ref))),
      );
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('leave_applications').update({
        'status': 'rejected',
        'approved_by': supabase.auth.currentUser?.id,
        'approved_at': DateTime.now().toIso8601String(),
        'rejection_reason': _rejectionReasonController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', leave.id);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaff.leaveRejected, ref))),
        );
        _rejectionReasonController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    }
  }

  Future<void> _cancelLeave(LeaveApplication leave) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('leave_applications').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', leave.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LAll.all_leave_application_cancelled, ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    }
  }

  void _showRejectDialog(LeaveApplication leave) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _RejectLeaveFormPage(leave: leave, onReject: _rejectLeave),
        fullscreenDialog: true,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final filters = {
      'status': _selectedStatus,
      'applicant_type': _selectedApplicantType,
    };
    final leavesAsync = ref.watch(leaveApplicationsProvider(filters));
    final pendingAsync = ref.watch(pendingLeavesProvider);

    return BasePanelLayout(
      title: 'Leave Management',
      children: [
        // Pending Approvals Section
        pendingAsync.when(
          data: (pending) {
            if (pending.isEmpty) return const SizedBox.shrink();
            return Card(
              color: Colors.orange.withValues(alpha: 0.1),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications_active, color: Colors.orange),
                        SizedBox(width: 8.w),
                        Text(
                          'Pending Approvals (${pending.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pending.length > 3 ? 3 : pending.length,
                      itemBuilder: (context, index) {
                        final leave = pending[index];
                        return ListTile(
                          dense: true,
                          title: Text(tt(LAll.all_x_x_days, ref, [leave.applicantType.toUpperCase(), leave.totalDays.toString()])),
                          subtitle: Text(tt(LAll.all_s62, ref, [_formatDate(leave.startDate), leave.reason])),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.blue),
                                onPressed: () => _approveLeave(leave),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _showRejectDialog(leave),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        SizedBox(height: 16.h),

        // Filters
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
initialValue: _selectedApplicantType,
                    decoration: const InputDecoration(
                      labelText: 'Applicant Type',
                      border: OutlineInputBorder(),
                    ),
                    items: ['All', ..._applicantTypes].map((type) {
                      return DropdownMenuItem(
                        value: type == 'All' ? null : type,
                        child: Text(type.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedApplicantType = value);
                    },
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: DropdownButtonFormField<String>(
initialValue: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: ['All', ..._statuses].map((status) {
                      return DropdownMenuItem(
                        value: status == 'All' ? null : status,
                        child: Text(status.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedStatus = value);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // Create Leave Section
        Card(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submit Leave Application',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
initialValue: _selectedApplicantType,
                        decoration: const InputDecoration(
                          labelText: 'Applicant Type *',
                          border: OutlineInputBorder(),
                        ),
                        items: _applicantTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedApplicantType = value);
                        },
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: DropdownButtonFormField<String>(
initialValue: _selectedLeaveCategory,
                        decoration: const InputDecoration(
                          labelText: 'Leave Category',
                          border: OutlineInputBorder(),
                        ),
                        items: _leaveCategories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category.replaceAll('_', ' ').toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedLeaveCategory = value);
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectStartDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date *',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _startDate != null
                                ? _formatDate(_startDate!)
                                : 'Select Date',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: InkWell(
                        onTap: _selectEndDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _endDate != null
                                ? _formatDate(_endDate!)
                                : 'Select Date',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _reasonController,
                  label: 'Reason *',
                  maxLines: 3,
                  hint: 'Enter reason for leave...',
                ),
                SizedBox(height: 24.h),
                GradientButton(
                  onPressed: _isCreating ? () {} : _createLeaveApplication,
                  text: _isCreating ? 'Submitting...' : 'Submit Leave Application',
                  isLoading: _isCreating,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.h),

        // Leave Applications List
        Card(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leave Applications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16.h),
                leavesAsync.when(
                  data: (leaves) {
                    if (leaves.isEmpty) {
                      return Center(
                        child: Text(t(LStaff.noLeaves, ref)),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: leaves.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final leave = leaves[index];
                        return ListTile(
                          leading: Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              color: _getStatusColor(leave.status).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.event_busy,
                              color: _getStatusColor(leave.status),
                            ),
                          ),
                          title: Text(
                            '${leave.applicantType.toUpperCase()} - ${leave.totalDays} day(s) (${leave.leaveCategory.replaceAll('_', ' ')})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(leave.endDate != null
                                  ? tt(LAll.all_s62, ref, [_formatDate(leave.startDate), _formatDate(leave.endDate!)])
                                  : _formatDate(leave.startDate)),
                              Text(leave.reason, maxLines: 2, overflow: TextOverflow.ellipsis),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(
                                      leave.status,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor: _getStatusColor(leave.status).withValues(alpha: 0.2),
                                    side: BorderSide.none,
                                    padding: EdgeInsets.zero,
                                    labelPadding: EdgeInsets.symmetric(horizontal: 8.w),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: leave.status == 'pending'
                              ? PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'approve':
                                        _approveLeave(leave);
                                        break;
                                      case 'reject':
                                        _showRejectDialog(leave);
                                        break;
                                      case 'cancel':
                                        _cancelLeave(leave);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'approve',
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text(t(LCrud.approve, ref)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'reject',
                                      child: Row(
                                        children: [
                                          Icon(Icons.cancel, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text(t(LCrud.reject, ref)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'cancel',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.grey),
                                          SizedBox(width: 8),
                                          Text(t(L.cancel, ref)),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        );
                      },
                    );
                  },
                  loading: () => const PageSkeleton(type: 'list'),
                  error: (error, _) => Text(tt(LAll.all_error_x, ref, [error.toString()])),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RejectLeaveFormPage extends ConsumerStatefulWidget {
  final LeaveApplication leave;
  final Future<void> Function(LeaveApplication) onReject;

  const _RejectLeaveFormPage({required this.leave, required this.onReject});

  @override
  ConsumerState<_RejectLeaveFormPage> createState() => _RejectLeaveFormPageState();
}

class _RejectLeaveFormPageState extends ConsumerState<_RejectLeaveFormPage> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(LCrud.rejectReason, ref))),
      );
      return;
    }
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('leave_applications').update({
        'status': 'rejected',
        'approved_by': supabase.auth.currentUser?.id,
        'approved_at': DateTime.now().toIso8601String(),
        'rejection_reason': _reasonController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.leave.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaff.leaveRejected, ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LAll.all_reject_leave_application, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(L.cancel, ref)),
          ),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t(LCrud.reject, ref)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomTextField(
          controller: _reasonController,
          label: 'Rejection Reason',
          maxLines: 3,
          hint: 'Enter reason for rejection...',
        ),
      ),
    );
  }
}
