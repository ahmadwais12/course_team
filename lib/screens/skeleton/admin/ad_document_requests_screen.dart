import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdDocumentRequestsScreen extends ConsumerWidget {
  const AdDocumentRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Document Requests',
      description: 'Manage document requests',
      category: 'Organization',
      icon: Icons.request_page,
      accentColor: const Color(0xFF06B6D4),
      tableName: 'document_requests',
    );
  }
}
