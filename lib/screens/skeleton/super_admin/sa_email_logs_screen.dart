import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaEmailLogsScreen extends ConsumerWidget {
  const SaEmailLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Email Logs',
      description: 'View sent email history',
      category: 'Monitoring',
      icon: Icons.email_outlined,
      accentColor: const Color(0xFF3B82F6),
      tableName: 'email_logs',
    );
  }
}
