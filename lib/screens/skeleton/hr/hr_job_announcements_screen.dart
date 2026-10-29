import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class HrJobAnnouncementsScreen extends ConsumerWidget {
  const HrJobAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Job Announcements',
      description: 'Post job announcements',
      category: 'Recruitment',
      icon: Icons.campaign,
      accentColor: const Color(0xFF8B5CF6),
      tableName: 'job_announcements',
    );
  }
}
