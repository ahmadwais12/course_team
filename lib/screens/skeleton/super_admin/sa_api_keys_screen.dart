import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaApiKeysScreen extends ConsumerWidget {
  const SaApiKeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'API Keys',
      description: 'Manage API keys and tokens',
      category: 'Integration',
      icon: Icons.vpn_key,
      accentColor: const Color(0xFFEC4899),
      tableName: 'api_keys',
    );
  }
}
