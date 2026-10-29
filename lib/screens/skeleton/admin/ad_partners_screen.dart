import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdPartnersScreen extends ConsumerWidget {
  const AdPartnersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Partners',
      description: 'Manage partner organizations',
      category: 'Organization',
      icon: Icons.handshake,
      accentColor: const Color(0xFF10B981),
      tableName: 'partners',
    );
  }
}
