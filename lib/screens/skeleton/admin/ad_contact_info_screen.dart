import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdContactInfoScreen extends ConsumerWidget {
  const AdContactInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Contact Information',
      description: 'Manage contact information records',
      category: 'Communication',
      icon: Icons.contact_phone,
      accentColor: const Color(0xFF6366F1),
      tableName: 'contact_info',
    );
  }
}
