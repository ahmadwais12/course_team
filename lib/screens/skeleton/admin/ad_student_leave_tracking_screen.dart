import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdStudentLeaveTrackingScreen extends ConsumerWidget {
  const AdStudentLeaveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Student Leave Tracking',
      description: 'Track student leave records',
      category: 'Academic',
      icon: Icons.event_busy,
      accentColor: const Color(0xFFF97316),
      tableName: 'student_leave_tracking',
    );
  }
}
