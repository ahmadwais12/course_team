import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdDocumentsScreen extends ConsumerWidget {
  const AdDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Documents',
      description: 'Manage documents and files',
      category: 'Organization',
      icon: Icons.folder_open,
      accentColor: const Color(0xFF14B8A6),
      tableName: 'documents',
    );
  }
}
