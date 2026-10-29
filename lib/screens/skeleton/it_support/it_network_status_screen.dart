import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItNetworkStatusScreen extends ConsumerStatefulWidget {
  const ItNetworkStatusScreen({super.key});

  @override
  ConsumerState<ItNetworkStatusScreen> createState() => _ItNetworkStatusScreenState();
}

class _ItNetworkStatusScreenState extends ConsumerState<ItNetworkStatusScreen> {
  List<Map<String, dynamic>> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      final data = await Supabase.instance.client
          .from('it_devices')
          .select()
          .inFilter('device_type', ['router', 'switch', 'server', 'other'])
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _devices = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'retired':
        return Colors.grey;
      case 'lost':
        return Colors.red;
      default:
        return Colors.teal;
    }
  }

  String _statusLabel(String? status) => status ?? 'unknown';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Status'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                final status = device['status']?.toString();
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _statusColor(status).withValues(alpha: 0.12),
                      child: Icon(Icons.router, color: _statusColor(status)),
                    ),
                    title: Text(device['name']?.toString() ?? 'Device'),
                    subtitle: Text(
                      '${device['device_type'] ?? '—'} · '
                      '${device['brand'] ?? ''} ${device['model'] ?? ''}'.trim(),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(status).toUpperCase(),
                        style: TextStyle(
                          color: _statusColor(status),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${device['name']} — ${device['location'] ?? 'no location'}',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
        onPressed: () {
          setState(() => _isLoading = true);
          _loadDevices();
        },
      ),
    );
  }
}
