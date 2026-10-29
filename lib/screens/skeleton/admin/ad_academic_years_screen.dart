import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdAcademicYearsScreen extends ConsumerWidget {
  const AdAcademicYearsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Academic Years',
      description: 'Manage academic years',
      category: 'Academic',
      icon: Icons.calendar_today,
      accentColor: const Color(0xFF3B82F6),
      tableName: 'academic_years',
    );
  }
}
