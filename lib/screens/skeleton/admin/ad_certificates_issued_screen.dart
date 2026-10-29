import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdCertificatesIssuedScreen extends ConsumerWidget {
  const AdCertificatesIssuedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Issued Certificates',
      description: 'View issued certificates',
      category: 'Academic',
      icon: Icons.verified,
      accentColor: const Color(0xFFA855F7),
      tableName: 'certificates_issued',
    );
  }
}
