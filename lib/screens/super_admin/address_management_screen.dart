import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class AddressManagementScreen extends ConsumerStatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  ConsumerState<AddressManagementScreen> createState() =>
      _AddressManagementScreenState();
}

class _AddressManagementScreenState
    extends ConsumerState<AddressManagementScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final data = await Supabase.instance.client
          .from('addresses')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      if (mounted) {
        setState(() {
          _addresses = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_failed_to_load_addresses_x, ref, [e.toString()]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () { if (context.canPop()) { context.pop(); } else { context.go(AppRoutes.superAdmin); } }), title: Text(t(LAll.all_address_management, ref))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _addresses.isEmpty
                    ? Center(child: Text(t(LAll.all_no_addresses_found, ref)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _addresses.length,
                        itemBuilder: (context, index) {
                          final addr = _addresses[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[200],
                                child: const Icon(Icons.location_on,
                                    color: Colors.black),
                              ),
                              title: Text(
                                  addr['address_line1'] ?? 'No address'),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (addr['address_line2'] != null)
                                    Text(addr['address_line2']),
                                  Text(
                                      '${addr['city'] ?? ''}, ${addr['state'] ?? ''} ${addr['postal_code'] ?? ''}'),
                                  Text(
                                      'Country: ${addr['country'] ?? 'N/A'}'),
                                  if (addr['label'] != null)
                                    Text('Label: ${addr['label']}'),
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
                                  if (value == 'delete') {
                                    _deleteAddress(addr['id']);
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
        label: Text(t(LAll.all_add_address, ref)),
      ),
    );
  }

  void _showAddDialog() {
    final line1Ctrl = TextEditingController();
    final line2Ctrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final zipCtrl = TextEditingController();
    final countryCtrl = TextEditingController();
    final labelCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(LAll.all_add_address, ref)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: line1Ctrl,
                decoration: const InputDecoration(
                    labelText: 'Address Line 1',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: line2Ctrl,
                decoration: const InputDecoration(
                    labelText: 'Address Line 2',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityCtrl,
                decoration: const InputDecoration(
                    labelText: 'City', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stateCtrl,
                decoration: const InputDecoration(
                    labelText: 'State/Province',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: zipCtrl,
                decoration: const InputDecoration(
                    labelText: 'Postal Code',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: countryCtrl,
                decoration: const InputDecoration(
                    labelText: 'Country', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                    labelText: 'Label (e.g. Home, Work)',
                    border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(L.cancel, ref)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (line1Ctrl.text.trim().isEmpty) return;
              try {
                await Supabase.instance.client.from('addresses').insert({
                  'address_line1': line1Ctrl.text.trim(),
                  'address_line2': line2Ctrl.text.trim(),
                  'city': cityCtrl.text.trim(),
                  'state': stateCtrl.text.trim(),
                  'postal_code': zipCtrl.text.trim(),
                  'country': countryCtrl.text.trim(),
                  'label': labelCtrl.text.trim(),
                  'created_at': DateTime.now().toIso8601String(),
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t(LAll.all_address_added_successfully, ref))),
                  );
                }
                _loadAddresses();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tt(LAll.all_failed_to_add_address_x, ref, [e.toString()]))),
                  );
                }
              }
            },
            child: Text(t(L.add, ref)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAddress(dynamic id) async {
    try {
      await Supabase.instance.client
          .from('addresses')
          .delete()
          .eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LAll.all_address_deleted, ref))),
        );
      }
      _loadAddresses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_failed_to_delete_address_x, ref, [e.toString()]))),
        );
      }
    }
  }
}


