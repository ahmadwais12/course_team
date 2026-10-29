import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class RpVisitorsScreen extends ConsumerWidget {
  const RpVisitorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Visitor Log',
      description: 'Log and manage visitors',
      category: 'Front Desk',
      icon: Icons.person_pin,
      accentColor: const Color(0xFF3B82F6),
      tableName: 'visitors',
    );
  }
}
