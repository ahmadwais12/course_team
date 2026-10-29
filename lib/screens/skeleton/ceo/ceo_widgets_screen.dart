import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class CeoWidgetsScreen extends ConsumerWidget {
  const CeoWidgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'CEO Widgets',
      description: 'Configure CEO dashboard widgets',
      category: 'Executive',
      icon: Icons.widgets,
      accentColor: const Color(0xFF8B5CF6),
      tableName: 'ceo_dashboard_widgets',
    );
  }
}
