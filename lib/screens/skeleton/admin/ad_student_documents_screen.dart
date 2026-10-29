import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdStudentDocumentsScreen extends ConsumerWidget {
  const AdStudentDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Student Documents',
      description: 'Manage student document uploads',
      category: 'Academic',
      icon: Icons.description,
      accentColor: const Color(0xFFEC4899),
      tableName: 'student_documents',
    );
  }
}
