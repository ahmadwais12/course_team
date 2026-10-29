import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class RpPhoneLogsScreen extends ConsumerWidget {
  const RpPhoneLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Phone Call Log',
      description: 'Log incoming and outgoing calls',
      category: 'Front Desk',
      icon: Icons.phone,
      accentColor: const Color(0xFF6366F1),
      tableName: 'phone_logs',
    );
  }
}
