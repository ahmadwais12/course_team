import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class LbLibraryBooksScreen extends ConsumerWidget {
  const LbLibraryBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Library Books',
      description: 'Manage library book catalog',
      category: 'Library',
      icon: Icons.library_books,
      accentColor: const Color(0xFF6366F1),
      tableName: 'library_books',
    );
  }
}
