import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class HrTrainingsScreen extends ConsumerWidget {
  const HrTrainingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Training Programs',
      description: 'Manage staff training programs',
      category: 'HR',
      icon: Icons.school,
      accentColor: const Color(0xFF14B8A6),
      tableName: 'trainings',
    );
  }
}
