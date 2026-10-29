import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A reusable realtime watcher widget.
/// Subscribes to PostgresChanges on the given tables and calls [onChange]
/// whenever any INSERT/UPDATE/DELETE occurs. Place one at the top of any
/// panel dashboard to auto-refresh providers when underlying data changes.
class RealtimeDashboardWatcher extends ConsumerStatefulWidget {
  final String channelName;
  final List<String> tables;
  final VoidCallback onChange;

  const RealtimeDashboardWatcher({
    super.key,
    required this.channelName,
    required this.tables,
    required this.onChange,
  });

  @override
  ConsumerState<RealtimeDashboardWatcher> createState() => _RealtimeDashboardWatcherState();
}

class _RealtimeDashboardWatcherState extends ConsumerState<RealtimeDashboardWatcher> {
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    var channel = Supabase.instance.client.channel(widget.channelName);
    for (final table in widget.tables) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => widget.onChange(),
      );
    }
    _channel = channel.subscribe();
  }

  @override
  void dispose() {
    if (_channel != null) Supabase.instance.client.removeChannel(_channel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
