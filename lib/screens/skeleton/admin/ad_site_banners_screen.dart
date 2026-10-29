import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdSiteBannersScreen extends ConsumerWidget {
  const AdSiteBannersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Site Banners',
      description: 'Manage website banners',
      category: 'Website',
      icon: Icons.view_carousel,
      accentColor: const Color(0xFF8B5CF6),
      tableName: 'site_banners',
    );
  }
}
