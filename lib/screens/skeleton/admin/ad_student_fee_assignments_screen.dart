import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdStudentFeeAssignmentsScreen extends ConsumerWidget {
  const AdStudentFeeAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Student Fee Assignments',
      description: 'Assign fees to individual students',
      category: 'Financial',
      icon: Icons.attach_money,
      accentColor: const Color(0xFFF59E0B),
      tableName: 'student_fee_assignments',
    );
  }
}
