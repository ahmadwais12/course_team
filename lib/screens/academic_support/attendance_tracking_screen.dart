import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../widgets/base_panel_layout.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

final attendanceDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final classesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await Supabase.instance.client.from('classes').select();
  return response;
});

final attendanceProvider =
    FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>(
        (ref, params) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('attendance')
      .select()
      .eq('class_id', params['class_id'])
      .eq('date', params['date'])
      .order('created_at');
  return response;
});

class AttendanceTrackingScreen extends ConsumerStatefulWidget {
  const AttendanceTrackingScreen({super.key});

  @override
  ConsumerState<AttendanceTrackingScreen> createState() =>
      _AttendanceTrackingScreenState();
}

class _AttendanceTrackingScreenState
    extends ConsumerState<AttendanceTrackingScreen> {
  String? _selectedClassId;
  String? _selectedClassName;
  bool _isLoading = false;
  Map<String, String> _attendanceStatus = {};

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: ref.read(attendanceDateProvider),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(attendanceDateProvider.notifier).state = picked;
    }
  }

  Future<List<Map<String, dynamic>>> _getStudentsForClass(
      String classId) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('students')
        .select()
        .eq('class_id', classId)
        .eq('status', 'active')
        .order('full_name');
    return response;
  }

  void _setAttendanceStatus(String studentId, String status) {
    setState(() {
      _attendanceStatus[studentId] = status;
    });
  }

  Future<void> _saveAttendance() async {
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(LAll.all_please_select_a_class, ref))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final date = ref.read(attendanceDateProvider);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      // Delete existing attendance records for this class and date
      await supabase
          .from('attendance')
          .delete()
          .eq('class_id', _selectedClassId!)
          .eq('date', dateStr);

      // Insert new attendance records
      final records = _attendanceStatus.entries
          .map((entry) => {
                'student_id': entry.key,
                'class_id': _selectedClassId,
                'date': dateStr,
                'status': entry.value,
                'created_at': DateTime.now().toIso8601String(),
                'marked_by': supabase.auth.currentUser?.id,
              })
          .toList();

      if (records.isNotEmpty) {
        await supabase.from('attendance').insert(records);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LAll.all_attendance_saved_successfully, ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, ['$e']))),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExistingAttendance() async {
    if (_selectedClassId == null) return;

    final supabase = Supabase.instance.client;
    final date = ref.read(attendanceDateProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    final response = await supabase
        .from('attendance')
        .select()
        .eq('class_id', _selectedClassId!)
        .eq('date', dateStr);

    setState(() {
      _attendanceStatus = {
        for (var record in response)
          record['student_id'] as String: record['status'] as String
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(attendanceDateProvider);
    final classesAsync = ref.watch(classesProvider);

    return BasePanelLayout(
      title: 'Attendance Tracking',
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: classesAsync.when(
                        data: (classes) {
                          return DropdownButtonFormField<String>(
initialValue: _selectedClassId,
                            decoration: const InputDecoration(
                              labelText: 'Select Class',
                              border: OutlineInputBorder(),
                            ),
                            items: classes.map((cls) {
                              return DropdownMenuItem(
                                value: cls['id'] as String,
                                child: Text(cls['name'] as String),
                              );
                            }).toList(),
                            onChanged: (value) async {
                              final selectedClass = classes.firstWhere(
                                (c) => c['id'] == value,
                                orElse: () => {'name': ''},
                              );
                              setState(() {
                                _selectedClassId = value;
                                _selectedClassName =
                                    selectedClass['name'] as String?;
                                _attendanceStatus = {};
                              });
                              await _loadExistingAttendance();
                            },
                          );
                        },
                        loading: () => const PageSkeleton(type: 'attendance'),
                        error: (_, __) => Text(t(LAll.all_error_loading_classes, ref)),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    ElevatedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today),
                      label:
                          Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                if (_selectedClassId != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Students - ${_selectedClassName ?? ''}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Row(
                        children: [
                          _buildStatusLegend('Present', Colors.blue),
                          SizedBox(width: 8.w),
                          _buildStatusLegend('Absent', Colors.red),
                          SizedBox(width: 8.w),
                          _buildStatusLegend('Late', Colors.orange),
                          SizedBox(width: 8.w),
                          _buildStatusLegend('Excused', Colors.blue),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getStudentsForClass(_selectedClassId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const PageSkeleton(type: 'attendance');
                      }

                      if (snapshot.hasError) {
                        return Text(tt(LAll.all_error_x, ref, ['${snapshot.error}']));
                      }

                      final students = snapshot.data ?? [];

                      if (students.isEmpty) {
                        return Center(
                          child: Text(t(LStaff.noActiveStudents, ref)),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final studentId = student['id'] as String;
                          final currentStatus =
                              _attendanceStatus[studentId] ?? 'present';

                          return Card(
                            margin: EdgeInsets.only(bottom: 8.h),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  (student['full_name'] as String? ?? '')[0]
                                      .toUpperCase(),
                                ),
                              ),
                              title: Text(
                                  student['full_name'] as String? ?? 'Unknown'),
                              subtitle: Text(
                                  'ID: ${student['student_code'] ?? 'N/A'}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildStatusButton(
                                    studentId,
                                    'present',
                                    Icons.check_circle,
                                    Colors.blue,
                                    currentStatus,
                                  ),
                                  SizedBox(width: 4.w),
                                  _buildStatusButton(
                                    studentId,
                                    'absent',
                                    Icons.cancel,
                                    Colors.red,
                                    currentStatus,
                                  ),
                                  SizedBox(width: 4.w),
                                  _buildStatusButton(
                                    studentId,
                                    'late',
                                    Icons.access_time,
                                    Colors.orange,
                                    currentStatus,
                                  ),
                                  SizedBox(width: 4.w),
                                  _buildStatusButton(
                                    studentId,
                                    'excused',
                                    Icons.medical_services,
                                    Colors.blue,
                                    currentStatus,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () { debugPrint('[attendance_tracking_screen] Save button CLICKED'); _saveAttendance(); },
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isLoading ? 'Saving...' : 'Save Attendance'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                    ),
                  ),
                ] else ...[
                  Center(
                    child: Text(t(LAll.all_please_select_a_class_to_view_students, ref)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4.w),
        Text(label, style: TextStyle(fontSize: 12.sp)),
      ],
    );
  }

  Widget _buildStatusButton(
    String studentId,
    String status,
    IconData icon,
    Color color,
    String currentStatus,
  ) {
    final isSelected = currentStatus == status;
    return InkWell(
      onTap: () => _setAttendanceStatus(studentId, status),
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? color : Colors.grey,
          size: 20.w,
        ),
      ),
    );
  }
}
