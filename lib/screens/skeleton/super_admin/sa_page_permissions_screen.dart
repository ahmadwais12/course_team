import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaPagePermissionsScreen extends ConsumerWidget {
  const SaPagePermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Page Permissions',
      description: 'Configure page-level access permissions',
      category: 'Security',
      icon: Icons.lock_outline,
      accentColor: const Color(0xFFDC2626),
      tableName: 'page_permissions',
    );
  }
}
