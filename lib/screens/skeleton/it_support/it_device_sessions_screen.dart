import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class ItDeviceSessionsScreen extends ConsumerWidget {
  const ItDeviceSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Device Sessions',
      description: 'View active device sessions',
      category: 'IT Support',
      icon: Icons.sensors,
      accentColor: const Color(0xFF7C3AED),
      tableName: 'device_sessions',
    );
  }
}
