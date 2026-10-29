import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdPhoneLogsScreen extends ConsumerWidget {
  const AdPhoneLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Phone Logs',
      description: 'View phone call logs',
      category: 'Communication',
      icon: Icons.phone,
      accentColor: const Color(0xFF3B82F6),
      tableName: 'phone_logs',
    );
  }
}
