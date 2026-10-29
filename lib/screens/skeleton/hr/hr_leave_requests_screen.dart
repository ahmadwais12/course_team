import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class HrLeaveRequestsScreen extends ConsumerWidget {
  const HrLeaveRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Leave Requests',
      description: 'Review and manage leave requests',
      category: 'HR',
      icon: Icons.request_page,
      accentColor: const Color(0xFFDC2626),
      tableName: 'leave_requests',
    );
  }
}
