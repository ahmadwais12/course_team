import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdHomeTestimonialsScreen extends ConsumerWidget {
  const AdHomeTestimonialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Testimonials',
      description: 'Manage testimonials on homepage',
      category: 'Website',
      icon: Icons.format_quote,
      accentColor: const Color(0xFF6366F1),
      tableName: 'home_testimonials',
    );
  }
}
