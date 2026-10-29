import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class LbBookCopiesScreen extends ConsumerWidget {
  const LbBookCopiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Book Copies',
      description: 'Manage individual book copies',
      category: 'Library',
      icon: Icons.copy_all,
      accentColor: const Color(0xFF8B5CF6),
      tableName: 'book_copies',
    );
  }
}
