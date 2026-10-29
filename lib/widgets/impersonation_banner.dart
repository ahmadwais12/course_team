import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:course_emis/providers/impersonation_provider.dart';
import 'package:course_emis/services/impersonation_service.dart';

/// Global host widget. When an impersonation session is active it renders the
/// sticky warning banner above the application Navigator; otherwise it simply
/// returns [child] unchanged so the layout is untouched.
class ImpersonationBannerHost extends ConsumerWidget {
  final Widget child;
  const ImpersonationBannerHost({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imp = ref.watch(impersonationProvider);
    final session = imp.session;
    // Double-check expiry so a stale session can never keep the banner alive.
    if (!imp.isImpersonating || session == null) return child;
    return Column(
      children: [
        ImpersonationBanner(session: session),
        Expanded(child: child),
      ],
    );
  }
}

/// Persistent high-contrast warning banner shown while impersonating.
/// Mirrors the "WARNING: Impersonating [User] ..." UI guideline — includes a
/// live countdown and an "Exit" action that ends the session and returns the
/// origin super admin to their own panel.
class ImpersonationBanner extends ConsumerStatefulWidget {
  final ImpersonationSession session;
  const ImpersonationBanner({super.key, required this.session});

  @override
  ConsumerState<ImpersonationBanner> createState() => _ImpersonationBannerState();
}

class _ImpersonationBannerState extends ConsumerState<ImpersonationBanner> {
  Timer? _ticker;
  int _secondsLeft = 1800;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.session.remainingSeconds.clamp(0, 1800);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft = widget.session.remainingSeconds.clamp(0, 1800);
      });
      if (_secondsLeft <= 0) {
        _ticker?.cancel();
        _autoExit();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ImpersonationBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _secondsLeft = widget.session.remainingSeconds.clamp(0, 1800);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _exit() async {
    _ticker?.cancel();
    await ref.read(impersonationProvider.notifier).exit();
    if (!mounted) return;
    context.go(AppRoutesAll.superAdmin);
  }

  Future<void> _autoExit() async {
    await _exit();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final name = session.targetName ?? 'User';
    final role = (session.targetRole ?? 'role').replaceAll('_', ' ');

    return Material(
      color: Colors.red.shade700,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Impersonating $name as $role',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Actions reflect the impersonated user. Time left: ${_format(_secondsLeft)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _format(_secondsLeft),
                style: const TextStyle(
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade700,
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => _exit(),
                icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                label: const Text('Exit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}