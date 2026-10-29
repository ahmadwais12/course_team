import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdNoticesScreen extends ConsumerWidget {
  const AdNoticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Notices',
      description: 'Manage notice board items',
      category: 'Communication',
      icon: Icons.notifications,
      accentColor: const Color(0xFF3B82F6),
      tableName: 'notices',
    );
  }
}
