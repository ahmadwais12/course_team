import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaSecurityLogsScreen extends ConsumerWidget {
  const SaSecurityLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Security Logs',
      description: 'View security event logs',
      category: 'Security',
      icon: Icons.shield,
      accentColor: const Color(0xFFDC2626),
      tableName: 'security_logs',
    );
  }
}
