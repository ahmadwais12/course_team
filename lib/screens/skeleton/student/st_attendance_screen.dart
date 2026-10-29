import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class StAttendanceScreen extends ConsumerWidget {
  const StAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'My Attendance',
      description: 'View personal attendance records',
      category: 'Academic',
      icon: Icons.check_circle,
      accentColor: const Color(0xFF10B981),
      tableName: 'student_attendance',
    );
  }
}
