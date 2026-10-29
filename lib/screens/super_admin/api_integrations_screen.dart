import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class APIIntegrationsScreen extends ConsumerStatefulWidget {
  const APIIntegrationsScreen({super.key});

  @override
  ConsumerState<APIIntegrationsScreen> createState() =>
      _APIIntegrationsScreenState();
}

class _APIIntegrationsScreenState extends ConsumerState<APIIntegrationsScreen> {
  List<Map<String, dynamic>> _apis = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAPIs();
  }

  Future<void> _loadAPIs() async {
    try {
      final data = await Supabase.instance.client
          .from('api_integrations')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _apis = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(tt(LAll.all_failed_to_load_api_integrations_x, ref,
                      [e.toString()]))),
        );
      }
    }
  }

  DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    return DateTime.parse(date.toString());
  }

  Future<void> _toggleAPI(Map<String, dynamic> api, bool newValue) async {
    try {
      await Supabase.instance.client
          .from('api_integrations')
          .update({
            'status': newValue ? 'Active' : 'Inactive',
            'last_sync': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', api['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${api['name']} ${newValue ? 'activated' : 'deactivated'}'),
          ),
        );
      }
      _loadAPIs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  tt(LAll.all_failed_to_update_api_x, ref, [e.toString()]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _apis.isEmpty
                    ? Center(
                        child:
                            Text(t(LAll.all_no_api_integrations_found, ref)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _apis.length,
                        itemBuilder: (context, index) {
                          final api = _apis[index];
                          final isActive =
                              api['status']?.toString() == 'Active';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isActive
                                    ? Colors.blue[100]
                                    : Colors.grey[300],
                                child: Icon(Icons.api,
                                    color: isActive
                                        ? Colors.blue
                                        : Colors.grey),
                              ),
                              title: Text(api['name'] ?? ''),
                              subtitle: Text(
                                  '${api['provider'] ?? 'N/A'} • Last sync: ${_formatLastSync(_parseDate(api['last_sync'] ?? api['lastSync'] ?? api['created_at']))}'),
                              trailing: Switch(
                                value: isActive,
                                onChanged: (value) =>
                                    _toggleAPI(api, value),
                              ),
                              onTap: () => _showDetails(api),
                            ),
                          );
                        },
                      ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAPIDialog(),
        icon: const Icon(Icons.add),
        label: Text(t(LAll.all_add_api, ref)),
      ),
    );
  }

  Future<void> _showAddAPIDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _APIIntegrationFormPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) _loadAPIs();
  }

  String _formatLastSync(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showDetails(Map<String, dynamic> api) {
    final isActive = api['status']?.toString() == 'Active';

    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(api['name'] ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildDetailRow('Provider', api['provider'] ?? ''),
              _buildDetailRow('Status', api['status'] ?? ''),
              _buildDetailRow('Last Sync',
                  _formatLastSync(_parseDate(api['last_sync'] ?? api['lastSync'] ?? api['created_at']))),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          await Supabase.instance.client
                              .from('api_integrations')
                              .update({
                                'status': isActive ? 'Inactive' : 'Active',
                                'last_sync':
                                    DateTime.now().toIso8601String(),
                                'updated_at':
                                    DateTime.now().toIso8601String(),
                              })
                              .eq('id', api['id']);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${api['name']} ${isActive ? 'disabled' : 'enabled'}'),
                              ),
                            );
                          }
                          _loadAPIs();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      tt(LAll.all_failed_to_configure_api_x,
                                          ref, [e.toString()]))),
                            );
                          }
                        }
                      },
                      icon: Icon(isActive
                          ? Icons.toggle_off
                          : Icons.toggle_on),
                      label: Text(isActive
                          ? 'Disable'
                          : 'Enable'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text(tt(LAll.all_s560, ref, [label]),
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _APIIntegrationFormPage extends ConsumerStatefulWidget {
  const _APIIntegrationFormPage();

  @override
  ConsumerState<_APIIntegrationFormPage> createState() =>
      _APIIntegrationFormPageState();
}

class _APIIntegrationFormPageState
    extends ConsumerState<_APIIntegrationFormPage> {
  final _nameCtrl = TextEditingController();
  final _providerCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _providerCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    try {
      await Supabase.instance.client.from('api_integrations').insert({
        'name': _nameCtrl.text.trim(),
        'provider': _providerCtrl.text.trim(),
        'status': 'Active',
        'last_sync': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(t(LAll.all_api_integration_added_successfully, ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  tt(LAll.all_failed_to_add_api_x, ref, [e.toString()]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () { if (context.canPop()) { context.pop(); } else { context.go(AppRoutes.superAdmin); } }),
        title: Text(t(LAll.all_add_api_integration, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(L.cancel, ref)),
          ),
          ElevatedButton(
            onPressed: () { debugPrint('[api_integrations_screen] Save button CLICKED'); _save(); },
            child: Text(t(L.add, ref)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'API Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _providerCtrl,
              decoration: const InputDecoration(
                labelText: 'Provider',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

