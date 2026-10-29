import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaBackupsScreen extends ConsumerWidget {
  const SaBackupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Backups',
      description: 'View and manage backup history',
      category: 'System',
      icon: Icons.backup,
      accentColor: const Color(0xFF059669),
      tableName: 'backups',
    );
  }
}
