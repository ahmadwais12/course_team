import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class CmComplaintMessagesScreen extends ConsumerWidget {
  const CmComplaintMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Complaint Messages',
      description: 'View complaint conversation threads',
      category: 'Complaints',
      icon: Icons.forum,
      accentColor: const Color(0xFF06B6D4),
      tableName: 'complaint_messages',
    );
  }
}
