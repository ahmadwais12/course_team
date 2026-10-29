import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdTranscriptsScreen extends ConsumerWidget {
  const AdTranscriptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Transcripts',
      description: 'Manage student transcripts',
      category: 'Academic',
      icon: Icons.description,
      accentColor: const Color(0xFF7C3AED),
      tableName: 'transcripts',
    );
  }
}
