import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class TcTeacherQualificationsScreen extends ConsumerWidget {
  const TcTeacherQualificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'My Qualifications',
      description: 'Manage teacher qualifications and credentials',
      category: 'Professional',
      icon: Icons.school,
      accentColor: const Color(0xFF6366F1),
      tableName: 'teacher_qualifications',
    );
  }
}
