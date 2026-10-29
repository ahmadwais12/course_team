import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../nav.dart';
import 'deep_link_parser.dart';
import 'deep_link_routes.dart';
import 'models/deep_link_data.dart';

/// Provider for DeepLinkService
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService();
});

/// Service responsible for handling all deep links
class DeepLinkService {
  DeepLinkService({GlobalKey<NavigatorState>? navigatorKey})
      : _navigatorKey = navigatorKey ?? rootNavigatorKey;

  final GlobalKey<NavigatorState> _navigatorKey;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  DeepLinkData? _pendingDeepLink;
  bool _isPendingNavigationScheduled = false;

  /// Pending link to handle after auth check
  DeepLinkData? get pendingDeepLink => _pendingDeepLink;

  /// Initialize the service
  Future<void> init() async {
    _appLinks = AppLinks();
    _listenToAuthChanges();

    // Handle cold start (app launched via deep link)
    await _handleColdStart();

    // Listen to deep links while app is running
    _listenToDeepLinks();
  }

  /// Handle cold start scenario
  Future<void> _handleColdStart() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();

      if (initialUri != null) {
        debugPrint('Cold start deep link: $initialUri');

        final data = DeepLinkParser.parse(
          initialUri.toString(),
          DeepLinkSource.coldStart,
        );

        _processDeepLink(data);
      }
    } catch (e) {
      debugPrint('Error handling cold start: $e');
    }
  }

  /// Listen to deep links while app is running
  void _listenToDeepLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          debugPrint('Deep link received: $uri');

          final data = DeepLinkParser.parse(
            uri.toString(),
            DeepLinkSource.foreground,
          );

          _processDeepLink(data);
        }
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }

  /// Process the parsed deep link data
  void _processDeepLink(DeepLinkData data) {
    // Validate the link
    if (data.type == DeepLinkType.unknown) {
      _handleInvalidLink(data.rawUrl);
      return;
    }

    // Check if URL is from trusted domain
    if (!_isTrustedDomain(data.rawUrl)) {
      debugPrint('Untrusted domain: ${data.rawUrl}');
      return;
    }

    // Check authentication
    final session = Supabase.instance.client.auth.currentSession;
    final isAuthenticated = session != null;

    if (!isAuthenticated) {
      // Store for later processing after login
      _pendingDeepLink = data;
      return;
    }

    _pendingDeepLink = data;
    _schedulePendingNavigation();
  }

  void _listenToAuthChanges() {
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((authState) {
      if (authState.session == null) {
        return;
      }

      _schedulePendingNavigation();
    });
  }

  void _schedulePendingNavigation() {
    if (_pendingDeepLink == null || _isPendingNavigationScheduled) {
      return;
    }

    _isPendingNavigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isPendingNavigationScheduled = false;
      processPendingLink();
    });
  }

  /// Handle invalid/unknown links
  void _handleInvalidLink(String url) {
    debugPrint('Invalid deep link: $url');
  }

  /// Check if domain is trusted
  bool _isTrustedDomain(String url) {
    final trustedDomains = [
      'emis.example.com',
      'emis-staging.example.com',
      'emis.app',
    ];

    try {
      final uri = Uri.parse(url);
      return trustedDomains
          .any((domain) => uri.host == domain || uri.host.endsWith('.$domain'));
    } catch (e) {
      return false;
    }
  }

  /// Process pending link after authentication (call this after login)
  void processPendingLink() {
    final pendingDeepLink = _pendingDeepLink;
    final context = _navigatorKey.currentContext;

    if (pendingDeepLink == null) {
      return;
    }

    if (context == null) {
      _schedulePendingNavigation();
      return;
    }

    _pendingDeepLink = null;
    DeepLinkRoutes.navigateWithContext(context, pendingDeepLink);
  }

  /// Clear pending link (e.g., on logout)
  void clearPendingLink() {
    _pendingDeepLink = null;
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
  }
}
