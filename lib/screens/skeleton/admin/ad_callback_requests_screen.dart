import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdCallbackRequestsScreen extends ConsumerWidget {
  const AdCallbackRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Callback Requests',
      description: 'Manage callback requests',
      category: 'Communication',
      icon: Icons.call,
      accentColor: const Color(0xFF059669),
      tableName: 'callback_requests',
    );
  }
}
