import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class LoggedInDevicesScreen extends StatefulWidget {
  const LoggedInDevicesScreen({super.key});

  @override
  State<LoggedInDevicesScreen> createState() => _LoggedInDevicesScreenState();
}

class _LoggedInDevicesScreenState extends State<LoggedInDevicesScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await _supabase
          .from('user_devices')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('last_seen_at', ascending: false);
      setState(() {
        _devices = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _signOutDevice(String deviceId, bool isCurrent) async {
    if (isCurrent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot sign out current device here')),
      );
      return;
    }
    await _supabase
        .from('user_devices')
        .update({'is_active': false, 'logged_out_at': DateTime.now().toIso8601String()})
        .eq('id', deviceId);
    _loadDevices();
  }

  Future<void> _signOutAll() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('user_devices')
        .update({'is_active': false, 'logged_out_at': DateTime.now().toIso8601String()})
        .eq('user_id', userId)
        .eq('is_current', false);
    _loadDevices();
  }

  IconData _platformIcon(String? platform) {
    switch (platform?.toLowerCase()) {
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.phone_iphone;
      case 'windows':
        return Icons.laptop_windows;
      case 'web':
        return Icons.web;
      default:
        return Icons.devices;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logged-in Devices'),
        actions: [
          if (_devices.length > 1)
            TextButton(
              onPressed: _signOutAll,
              child: const Text('Sign out others'),
            ),
        ],
      ),
      body: _loading
          ? const PageSkeleton(type: 'settings')
          : _devices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.devices_other, size: 64,
                          color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      Text('No active sessions found',
                          style: theme.textTheme.bodyLarge),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _devices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final d = _devices[i];
                    final isCurrent = d['is_current'] == true;
                    final lastSeen = d['last_seen_at'] != null
                        ? DateTime.tryParse(d['last_seen_at'])
                        : null;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCurrent
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            _platformIcon(d['platform']),
                            color: isCurrent
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                d['device_name'] ?? 'Unknown Device',
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'This device',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (d['platform'] != null)
                              Text(
                                '${d['platform']} • v${d['app_version'] ?? 'N/A'}',
                                style: theme.textTheme.bodySmall,
                              ),
                            if (lastSeen != null)
                              Text(
                                'Last seen: ${lastSeen.toLocal().toString().substring(0, 16)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            if (d['ip_address'] != null)
                              Text(
                                'IP: ${d['ip_address']}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                          ],
                        ),
                        trailing: isCurrent
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.logout),
                                tooltip: 'Sign out',
                                onPressed: () =>
                                    _signOutDevice(d['id'], isCurrent),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
