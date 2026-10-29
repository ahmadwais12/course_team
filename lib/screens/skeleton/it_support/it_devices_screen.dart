import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class ItDevicesScreen extends ConsumerWidget {
  const ItDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'IT Devices',
      description: 'Manage IT devices and equipment',
      category: 'IT Support',
      icon: Icons.devices,
      accentColor: const Color(0xFFA855F7),
      tableName: 'it_devices',
    );
  }
}
