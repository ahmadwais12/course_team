import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class HoWardensScreen extends ConsumerWidget {
  const HoWardensScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Wardens',
      description: 'Manage hostel wardens',
      category: 'Hostel',
      icon: Icons.badge,
      accentColor: const Color(0xFF7C3AED),
      tableName: 'wardens',
    );
  }
}
