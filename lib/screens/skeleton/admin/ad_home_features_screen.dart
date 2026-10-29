import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdHomeFeaturesScreen extends ConsumerWidget {
  const AdHomeFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Home Features',
      description: 'Manage homepage features',
      category: 'Website',
      icon: Icons.star,
      accentColor: const Color(0xFFF59E0B),
      tableName: 'home_features',
    );
  }
}
