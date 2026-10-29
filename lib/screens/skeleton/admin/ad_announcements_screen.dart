import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdAnnouncementsScreen extends ConsumerWidget {
  const AdAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Announcements',
      description: 'Create and manage announcements',
      category: 'Communication',
      icon: Icons.campaign,
      accentColor: const Color(0xFF0EA5E9),
      tableName: 'announcements',
    );
  }
}
