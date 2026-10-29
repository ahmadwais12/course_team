import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class GnPlacementTestAttemptsScreen extends ConsumerWidget {
  const GnPlacementTestAttemptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Placement Test Attempts',
      description: 'View placement test attempts',
      category: 'Assessment',
      icon: Icons.quiz,
      accentColor: const Color(0xFFA855F7),
      tableName: 'placement_test_attempts',
    );
  }
}
