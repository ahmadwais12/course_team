import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdPageSectionsScreen extends ConsumerWidget {
  const AdPageSectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Page Sections',
      description: 'Manage website page sections',
      category: 'Website',
      icon: Icons.layers,
      accentColor: const Color(0xFF14B8A6),
      tableName: 'page_sections',
    );
  }
}
