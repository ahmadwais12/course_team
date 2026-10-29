import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdSubjectsScreen extends ConsumerWidget {
  const AdSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Subjects',
      description: 'Manage subjects catalog',
      category: 'Academic',
      icon: Icons.bookmark,
      accentColor: const Color(0xFF14B8A6),
      tableName: 'subjects',
    );
  }
}
