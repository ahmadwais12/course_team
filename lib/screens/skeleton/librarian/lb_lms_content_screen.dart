import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class LbLmsContentScreen extends ConsumerWidget {
  const LbLmsContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'LMS Content',
      description: 'Manage LMS content',
      category: 'Library',
      icon: Icons.computer,
      accentColor: const Color(0xFF7C3AED),
      tableName: 'lms_content',
    );
  }
}
