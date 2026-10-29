import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class EmEventCalendarScreen extends ConsumerWidget {
  const EmEventCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Event Calendar',
      description: 'View all events on calendar',
      category: 'Events',
      icon: Icons.calendar_month,
      accentColor: const Color(0xFF8B5CF6),
      tableName: 'events',
    );
  }
}
