import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class FeeTypeTemplatesScreen extends ConsumerStatefulWidget {
  const FeeTypeTemplatesScreen({super.key});

  @override
  ConsumerState<FeeTypeTemplatesScreen> createState() =>
      _FeeTypeTemplatesScreenState();
}

class _FeeTypeTemplatesScreenState
    extends ConsumerState<FeeTypeTemplatesScreen> {
  List<Map<String, dynamic>> _feeTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeeTypes();
  }

  Future<void> _loadFeeTypes() async {
    try {
      final data = await Supabase.instance.client
          .from('fee_types')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _feeTypes = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_failed_to_load_fee_types_x, ref, [e.toString()]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () { if (context.canPop()) { context.pop(); } else { context.go(AppRoutes.superAdmin); } }), title: Text(t(LAll.all_fee_type_templates, ref))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _feeTypes.isEmpty
                    ? Center(child: Text(t(LAll.all_no_fee_types_found, ref)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _feeTypes.length,
                        itemBuilder: (context, index) {
                          final feeType = _feeTypes[index];
                          final isMandatory =
                              feeType['is_mandatory'] == true;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[200],
                                child: const Icon(Icons.receipt_long,
                                    color: Colors.black),
                              ),
                              title: Text(feeType['name'] ?? ''),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (feeType['description'] != null)
                                    Text(feeType['description']),
                                  if (feeType['amount'] != null)
                                    Text(
                                        'Amount: \$${feeType['amount']}'),
                                  Text(
                                      'Category: ${feeType['category'] ?? 'General'}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isMandatory
                                          ? Colors.grey[200]
                                          : Colors.grey[100],
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isMandatory
                                          ? 'Mandatory'
                                          : 'Optional',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isMandatory
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton(
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
                                        _deleteFeeType(feeType['id']);
                                      }
                                    },
                                  ),
                                ],
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
        label: Text(t(LAll.all_add_fee_type, ref)),
      ),
    );
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    bool isMandatory = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(t(LAll.all_add_fee_type, ref)),
            content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Fee Type Name',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Amount', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: Text(t(LAll.all_mandatory, ref)),
                  value: isMandatory,
                  onChanged: (v) =>
                      setState(() => isMandatory = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
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
                if (nameCtrl.text.trim().isEmpty) return;
                try {
                  await Supabase.instance.client.from('fee_types').insert({
                    'name': nameCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'amount': double.tryParse(amountCtrl.text.trim()) ?? 0,
                    'is_mandatory': isMandatory,
                    'created_at': DateTime.now().toIso8601String(),
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t(LAll.all_fee_type_added_successfully, ref))),
                    );
                  }
                  _loadFeeTypes();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tt(LAll.all_failed_to_add_fee_type_x, ref, [e.toString()]))),
                    );
                  }
                }
              },
              child: Text(t(L.add, ref)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteFeeType(dynamic id) async {
    try {
      await Supabase.instance.client
          .from('fee_types')
          .delete()
          .eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LAll.all_fee_type_deleted, ref))),
        );
      }
      _loadFeeTypes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_failed_to_delete_fee_type_x, ref, [e.toString()]))),
        );
      }
    }
  }
}


