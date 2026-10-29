import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class HoAllocationsScreen extends ConsumerWidget {
  const HoAllocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Hostel Allocations',
      description: 'Manage hostel room allocations',
      category: 'Hostel',
      icon: Icons.assignment,
      accentColor: const Color(0xFF6D28D9),
      tableName: 'hostel_allocations',
    );
  }
}
