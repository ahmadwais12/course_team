import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdSocialMediaLinksScreen extends ConsumerWidget {
  const AdSocialMediaLinksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Social Media Links',
      description: 'Manage social media links',
      category: 'Website',
      icon: Icons.share,
      accentColor: const Color(0xFF0EA5E9),
      tableName: 'social_media_links',
    );
  }
}
