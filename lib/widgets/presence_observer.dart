import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/services/chat_service.dart';

class PresenceObserver extends StatefulWidget {
  final Widget child;

  const PresenceObserver({super.key, required this.child});

  @override
  State<PresenceObserver> createState() => _PresenceObserverState();
}

class _PresenceObserverState extends State<PresenceObserver>
    with WidgetsBindingObserver {
  final _service = ChatService();
  Timer? _heartbeat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setPresence(true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setPresence(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _setPresence(false);
        break;
    }
  }

  void _setPresence(bool online) {
    final hasUser = Supabase.instance.client.auth.currentUser != null;
    if (!hasUser) return;
    if (online) {
      _heartbeat ??= Timer.periodic(
        const Duration(seconds: 30),
        (_) => _updatePresence(true),
      );
    } else {
      _heartbeat?.cancel();
      _heartbeat = null;
    }
    _updatePresence(online);
  }

  Future<void> _updatePresence(bool online) async {
    try {
      await _service.setPresence(online);
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeat?.cancel();
    _updatePresence(false);
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
