import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaUserDevicesScreen extends ConsumerWidget {
  const SaUserDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'User Devices',
      description: 'Manage registered user devices',
      category: 'Security',
      icon: Icons.devices,
      accentColor: const Color(0xFF6B7280),
      tableName: 'user_devices',
    );
  }
}
