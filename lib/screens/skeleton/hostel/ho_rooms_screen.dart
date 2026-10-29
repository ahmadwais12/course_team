import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class HoRoomsScreen extends ConsumerWidget {
  const HoRoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Rooms',
      description: 'Manage hostel rooms',
      category: 'Hostel',
      icon: Icons.meeting_room,
      accentColor: const Color(0xFF8B5CF6),
      tableName: 'rooms',
    );
  }
}
