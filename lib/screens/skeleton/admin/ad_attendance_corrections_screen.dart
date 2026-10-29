import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdAttendanceCorrectionsScreen extends ConsumerWidget {
  const AdAttendanceCorrectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Attendance Corrections',
      description: 'Manage attendance correction requests',
      category: 'Academic',
      icon: Icons.edit_calendar,
      accentColor: const Color(0xFFD946EF),
      tableName: 'attendance_corrections',
    );
  }
}
