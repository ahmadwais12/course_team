import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaErrorLogsScreen extends ConsumerWidget {
  const SaErrorLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Error Logs',
      description: 'View system error logs',
      category: 'Monitoring',
      icon: Icons.error_outline,
      accentColor: const Color(0xFFE11D48),
      tableName: 'error_logs',
    );
  }
}
