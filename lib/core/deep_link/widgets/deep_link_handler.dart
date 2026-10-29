import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../deep_link_service.dart';

/// Widget that handles deep link processing after authentication
class DeepLinkHandler extends ConsumerStatefulWidget {
  final Widget child;

  const DeepLinkHandler({required this.child, super.key});

  @override
  ConsumerState<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends ConsumerState<DeepLinkHandler> {
  @override
  void initState() {
    super.initState();
    _processPendingDeepLink();
  }

  void _processPendingDeepLink() {
    // Wait for widget to be mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deepLinkService = ref.read(deepLinkServiceProvider);
      if (deepLinkService.pendingDeepLink != null) {
        deepLinkService.processPendingLink();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Mixin for screens that need to handle deep link parameters
mixin DeepLinkScreenMixin<T extends StatefulWidget> on State<T> {
  
  /// Get deep link parameter from route arguments
  String? getDeepLinkParam(String key) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      return args[key]?.toString();
    }
    return null;
  }

  /// Check if screen was opened from deep link
  bool get isFromDeepLink {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      return args['fromDeepLink'] == true;
    }
    return false;
  }

  /// Get initial tab from deep link
  String? get initialTab => getDeepLinkParam('tab');
}
