import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class ScVisitorsScreen extends ConsumerWidget {
  const ScVisitorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Visitor Management',
      description: 'Track and manage visitors',
      category: 'Security',
      icon: Icons.people_outline,
      accentColor: const Color(0xFF3B82F6),
      tableName: 'visitors',
    );
  }
}
