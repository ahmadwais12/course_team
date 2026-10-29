import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class ScDeviceSessionsScreen extends ConsumerWidget {
  const ScDeviceSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Active Sessions',
      description: 'Monitor active device sessions',
      category: 'Security',
      icon: Icons.devices,
      accentColor: const Color(0xFF6B7280),
      tableName: 'device_sessions',
    );
  }
}
