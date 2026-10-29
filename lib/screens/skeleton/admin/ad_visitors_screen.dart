import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdVisitorsScreen extends ConsumerWidget {
  const AdVisitorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Visitors',
      description: 'Track visitor records',
      category: 'Organization',
      icon: Icons.people_outline,
      accentColor: const Color(0xFF6B7280),
      tableName: 'visitors',
    );
  }
}
