import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class PlatformManagementScreen extends ConsumerStatefulWidget {
  const PlatformManagementScreen({super.key});

  @override
  ConsumerState<PlatformManagementScreen> createState() =>
      _PlatformManagementScreenState();
}

class _PlatformManagementScreenState
    extends ConsumerState<PlatformManagementScreen> {
  List<Map<String, dynamic>> _platforms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlatforms();
  }

  Future<void> _loadPlatforms() async {
    try {
      final data = await Supabase.instance.client
          .from('platforms')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _platforms = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tt(LAll.all_failed_to_load_platforms_x, ref,
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

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _platforms.isEmpty
                    ? Center(
                        child: Text(t(LAll.all_no_platforms_found, ref)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _platforms.length,
                        itemBuilder: (context, index) {
                          final platform = _platforms[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[200],
                                child: const Icon(Icons.cloud, color: Colors.black),
                              ),
                              title: Text(platform['name'] ?? ''),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Code: ${platform['code'] ?? 'N/A'}'),
                                  if (platform['description'] != null)
                                    Text(platform['description']),
                                  Text(
                                      'Created: ${_formatDate(_parseDate(platform['created_at']))}'),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: Text(t(L.edit, ref))),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: Text(t(L.delete, ref))),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditDialog(platform);
                                  } else if (value == 'delete') {
                                    _deletePlatform(platform['id']);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: Text(t(LAll.all_add_platform, ref)),
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _PlatformFormPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) _loadPlatforms();
  }

  Future<void> _showEditDialog(Map<String, dynamic> platform) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _PlatformFormPage(platform: platform),
        fullscreenDialog: true,
      ),
    );
    if (result == true) _loadPlatforms();
  }

  Future<void> _deletePlatform(dynamic id) async {
    try {
      await Supabase.instance.client
          .from('platforms')
          .delete()
          .eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LAll.all_platform_deleted, ref))),
        );
      }
      _loadPlatforms();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tt(LAll.all_failed_to_delete_platform_x, ref,
                  [e.toString()]))),
        );
      }
    }
  }
}

class _PlatformFormPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? platform;
  const _PlatformFormPage({this.platform});

  @override
  ConsumerState<_PlatformFormPage> createState() => _PlatformFormPageState();
}

class _PlatformFormPageState extends ConsumerState<_PlatformFormPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _descCtrl;

  bool get _isEdit => widget.platform != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.platform?['name'] ?? '');
    _codeCtrl = TextEditingController(text: widget.platform?['code'] ?? '');
    _descCtrl = TextEditingController(text: widget.platform?['description'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    try {
      if (_isEdit) {
        await Supabase.instance.client
            .from('platforms')
            .update({
              'name': _nameCtrl.text.trim(),
              'code': _codeCtrl.text.trim(),
              'description': _descCtrl.text.trim(),
            })
            .eq('id', widget.platform!['id']);
      } else {
        await Supabase.instance.client.from('platforms').insert({
          'name': _nameCtrl.text.trim(),
          'code': _codeCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Platform updated successfully' : 'Platform added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(tt(LAll.all_failed_x, ref, [e.toString()]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () { if (context.canPop()) { context.pop(); } else { context.go(AppRoutes.superAdmin); } }),
        title: Text(_isEdit ? 'Edit Platform' : 'Add Platform'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(L.cancel, ref)),
          ),
          ElevatedButton(
            onPressed: () { debugPrint('[platform_management_screen] Save button CLICKED'); _save(); },
            child: Text(_isEdit ? 'Save' : 'Add'),
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
                  labelText: 'Platform Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeCtrl,
              decoration: const InputDecoration(
                  labelText: 'Code', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Description', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }
}

