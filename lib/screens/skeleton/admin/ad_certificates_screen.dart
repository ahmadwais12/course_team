import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdCertificatesScreen extends ConsumerWidget {
  const AdCertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Certificates',
      description: 'Manage certificate templates',
      category: 'Academic',
      icon: Icons.card_membership,
      accentColor: const Color(0xFFD946EF),
      tableName: 'certificates',
    );
  }
}
