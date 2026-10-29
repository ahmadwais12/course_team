import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdSemestersScreen extends ConsumerWidget {
  const AdSemestersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Semesters',
      description: 'Manage semesters within academic years',
      category: 'Academic',
      icon: Icons.calendar_view_month,
      accentColor: const Color(0xFF6366F1),
      tableName: 'semesters',
    );
  }
}
