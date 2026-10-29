import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdHomeHeroSectionsScreen extends ConsumerWidget {
  const AdHomeHeroSectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Hero Sections',
      description: 'Manage homepage hero content',
      category: 'Website',
      icon: Icons.web,
      accentColor: const Color(0xFFEC4899),
      tableName: 'home_hero_sections',
    );
  }
}
