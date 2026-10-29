import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class GdParentsScreen extends ConsumerWidget {
  const GdParentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Parent Records',
      description: 'Manage parent/guardian records',
      category: 'Family',
      icon: Icons.family_restroom,
      accentColor: const Color(0xFFEC4899),
      tableName: 'parents',
    );
  }
}
