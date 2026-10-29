import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class HrJobApplicationsScreen extends ConsumerWidget {
  const HrJobApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Job Applications',
      description: 'Review job applications',
      category: 'Recruitment',
      icon: Icons.assignment_ind,
      accentColor: const Color(0xFFA855F7),
      tableName: 'job_applications',
    );
  }
}
