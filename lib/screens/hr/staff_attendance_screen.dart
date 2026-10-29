import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../widgets/base_panel_layout.dart';
import '../../widgets/gradient_button.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

final staffAttendanceDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final staffListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('staff')
      .select('id, name, department_id, role')
      .eq('status', 'active')
      .order('name');
  return response;
});

final staffAttendanceProvider = FutureProvider.family<List<Map<String, dynamic>>, DateTime>((ref, date) async {
  final supabase = Supabase.instance.client;
  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  
  final response = await supabase
      .from('attendance')
      .select()
      .eq('type', 'staff')
      .gte('date', startOfDay.toIso8601String())
      .lt('date', endOfDay.toIso8601String())
      .order('created_at');
  return response;
});

class StaffAttendanceScreen extends ConsumerStatefulWidget {
  const StaffAttendanceScreen({super.key});

  @override
  ConsumerState<StaffAttendanceScreen> createState() => _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends ConsumerState<StaffAttendanceScreen> {
  final Map<String, String> _attendanceStatus = {}; // staffId -> status
  final Map<String, String> _remarks = {}; // staffId -> remarks
  bool _isSaving = false;

  final List<String> _statusOptions = ['present', 'absent', 'late', 'half_day', 'on_leave'];

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: ref.read(staffAttendanceDateProvider),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(staffAttendanceDateProvider.notifier).state = picked;
    }
  }

  Future<void> _loadExistingAttendance() async {
    final date = ref.read(staffAttendanceDateProvider);
    final supabase = Supabase.instance.client;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final response = await supabase
          .from('attendance')
          .select()
          .eq('type', 'staff')
          .gte('date', startOfDay.toIso8601String())
          .lt('date', endOfDay.toIso8601String());

      for (final record in response) {
        final staffId = record['student_id'] as String?; // Using student_id field for staff_id
        if (staffId != null) {
          _attendanceStatus[staffId] = record['status'] as String? ?? 'present';
          if (record['notes'] != null) {
            _remarks[staffId] = record['notes'] as String;
          }
        }
      }
      setState(() {});
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final date = ref.read(staffAttendanceDateProvider);
      final currentUser = supabase.auth.currentUser;

      for (final entry in _attendanceStatus.entries) {
        final staffId = entry.key;
        final status = entry.value;
        final remarks = _remarks[staffId] ?? '';

        // Check if attendance record already exists
        final existing = await supabase
            .from('attendance')
            .select('id')
            .eq('student_id', staffId)
            .eq('type', 'staff')
            .eq('date', DateTime(date.year, date.month, date.day).toIso8601String())
            .maybeSingle();

        final attendanceData = {
          'student_id': staffId,
          'type': 'staff',
          'date': DateTime(date.year, date.month, date.day).toIso8601String(),
          'status': status,
          'notes': remarks,
          'marked_by': currentUser?.id,
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (existing != null) {
          // Update existing record
          await supabase
              .from('attendance')
              .update(attendanceData)
              .eq('id', existing['id']);
        } else {
          // Create new record
          attendanceData['created_at'] = DateTime.now().toIso8601String();
          await supabase.from('attendance').insert(attendanceData);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaff.attendanceSaved, ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving attendance: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _markAll(String status) async {
    final staffAsync = ref.read(staffListProvider);
    staffAsync.whenData((staff) {
      setState(() {
        for (final member in staff) {
          _attendanceStatus[member['id']] = status;
        }
      });
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.blue;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'half_day':
        return Colors.yellow;
      case 'on_leave':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      case 'half_day':
        return Icons.timelapse;
      case 'on_leave':
        return Icons.event_busy;
      default:
        return Icons.help;
    }
  }

  Widget _buildStatusDropdown(String staffId) {
    final currentStatus = _attendanceStatus[staffId] ?? 'present';
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: _getStatusColor(currentStatus).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: _getStatusColor(currentStatus).withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentStatus,
          isDense: true,
          icon: Icon(
            _getStatusIcon(currentStatus),
            color: _getStatusColor(currentStatus),
            size: 20.w,
          ),
          items: _statusOptions.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 16.w,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _attendanceStatus[staffId] = value;
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(staffAttendanceDateProvider);
    final staffAsync = ref.watch(staffListProvider);
    final attendanceAsync = ref.watch(staffAttendanceProvider(selectedDate));

    // Load existing attendance when data is available
    attendanceAsync.whenData((data) {
      if (_attendanceStatus.isEmpty) {
        for (final record in data) {
          final staffId = record['student_id'] as String?;
          if (staffId != null) {
            _attendanceStatus[staffId] = record['status'] as String? ?? 'present';
            if (record['notes'] != null) {
              _remarks[staffId] = record['notes'] as String;
            }
          }
        }
      }
    });

    return BasePanelLayout(
      title: 'Staff Attendance',
      children: [
        // Date Selector and Quick Actions
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Attendance Date',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat('EEEE, MMM dd, yyyy').format(selectedDate),
                            style: TextStyle(fontSize: 16.sp),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _markAll('present'),
                        icon: const Icon(Icons.check_circle, color: Colors.blue),
                        label: Text(t(LCrud.markAllPresent, ref)),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _markAll('absent'),
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: Text(t(LCrud.markAllAbsent, ref)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.h),

        // Staff List
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Staff Members',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton.icon(
                      onPressed: _loadExistingAttendance,
                      icon: const Icon(Icons.refresh),
                      label: Text(t(LGen.refresh, ref)),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                staffAsync.when(
                  data: (staff) {
                    if (staff.isEmpty) {
                      return const Center(
                        child: Text('No active staff members found'),
                      );
                    }
                    
                    // Initialize attendance status for new staff members
                    for (final member in staff) {
                      if (!_attendanceStatus.containsKey(member['id'])) {
                        _attendanceStatus[member['id']] = 'present';
                      }
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: staff.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final member = staff[index];
                        final staffId = member['id'] as String;
                        final name = member['name'] as String? ?? 'Unknown';
                        final department = member['department_id'] as String? ?? 'N/A';
                        final role = member['role'] as String? ?? 'Staff';

                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withValues(alpha: 0.2),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 18.sp,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$role â€¢ Dept: $department'),
                              SizedBox(height: 4.h),
                              SizedBox(
                                width: 200.w,
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Remarks (optional)',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                                    border: const OutlineInputBorder(),
                                  ),
                                  style: TextStyle(fontSize: 12.sp),
                                  onChanged: (value) {
                                    _remarks[staffId] = value;
                                  },
                                  controller: TextEditingController(text: _remarks[staffId] ?? ''),
                                ),
                              ),
                            ],
                          ),
                          trailing: _buildStatusDropdown(staffId),
                        );
                      },
                    );
                  },
                  loading: () => const PageSkeleton(type: 'attendance'),
                  error: (error, _) => Text('Error: $error'),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.h),

        // Save Button
        GradientButton(
          onPressed: _isSaving ? () {} : () { debugPrint('[staff_attendance_screen] Save button CLICKED'); _saveAttendance(); },
          text: _isSaving ? 'Saving...' : 'Save Attendance',
          isLoading: _isSaving,
        ),
      ],
    );
  }
}
