import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class GnPlacementTestQuestionsScreen extends ConsumerWidget {
  const GnPlacementTestQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Placement Test Questions',
      description: 'Manage placement test questions',
      category: 'Assessment',
      icon: Icons.help,
      accentColor: const Color(0xFF7C3AED),
      tableName: 'placement_test_questions',
    );
  }
}
