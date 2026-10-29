import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class TpVehiclesScreen extends ConsumerWidget {
  const TpVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'All Vehicles',
      description: 'Manage transport vehicles',
      category: 'Transport',
      icon: Icons.directions_bus,
      accentColor: const Color(0xFFF59E0B),
      tableName: 'vehicles',
    );
  }
}
