import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaAuditLogsScreen extends ConsumerWidget {
  const SaAuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Audit Trail',
      description: 'Immutable audit trail of all changes',
      category: 'Compliance',
      icon: Icons.receipt_long,
      accentColor: const Color(0xFFF59E0B),
      tableName: 'audit_logs',
    );
  }
}
