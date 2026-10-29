import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdParentStudentsScreen extends ConsumerWidget {
  const AdParentStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Parent-Student Links',
      description: 'Manage parent/guardian to student relationships',
      category: 'Students',
      icon: Icons.family_restroom,
      accentColor: const Color(0xFFF59E0B),
      tableName: 'parent_students',
    );
  }
}
