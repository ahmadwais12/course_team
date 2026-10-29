import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaBusinessReportsScreen extends ConsumerWidget {
  const SaBusinessReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Business Reports',
      description: 'Platform business reports',
      category: 'Reports',
      icon: Icons.assessment,
      accentColor: const Color(0xFF10B981),
      tableName: 'business_reports',
    );
  }
}
