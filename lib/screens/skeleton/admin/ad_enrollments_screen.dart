import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdEnrollmentsScreen extends ConsumerWidget {
  const AdEnrollmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Enrollments',
      description: 'Manage student enrollments',
      category: 'Academic',
      icon: Icons.how_to_reg,
      accentColor: const Color(0xFF2563EB),
      tableName: 'enrollments',
    );
  }
}
