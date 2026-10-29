import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdHolidaysScreen extends ConsumerWidget {
  const AdHolidaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Holidays',
      description: 'Manage holiday calendar',
      category: 'Academic',
      icon: Icons.celebration,
      accentColor: const Color(0xFFF97316),
      tableName: 'holidays',
    );
  }
}
