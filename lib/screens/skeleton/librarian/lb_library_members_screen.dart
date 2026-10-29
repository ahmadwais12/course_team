import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class LbLibraryMembersScreen extends ConsumerWidget {
  const LbLibraryMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Library Members',
      description: 'Manage library memberships',
      category: 'Library',
      icon: Icons.card_membership,
      accentColor: const Color(0xFFA855F7),
      tableName: 'library_members',
    );
  }
}
