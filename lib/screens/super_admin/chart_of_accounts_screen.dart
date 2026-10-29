import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class ChartOfAccountsScreen extends ConsumerStatefulWidget {
  const ChartOfAccountsScreen({super.key});

  @override
  ConsumerState<ChartOfAccountsScreen> createState() =>
      _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState
    extends ConsumerState<ChartOfAccountsScreen> {
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final data = await Supabase.instance.client
          .from('accounts')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _accounts = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tt(LAll.all_failed_to_load_accounts_x, ref,
                  [e.toString()]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () { if (context.canPop()) { context.pop(); } else { context.go(AppRoutes.superAdmin); } }), title: Text(t(LAll.all_chart_of_accounts, ref))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _accounts.isEmpty
                    ? Center(
                        child: Text(t(LAll.all_no_accounts_found, ref)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _accounts.length,
                        itemBuilder: (context, index) {
                          final account = _accounts[index];
                          final type = (account['type'] ??
                                      account['account_type'])
                                  ?.toString() ??
                              'N/A';
                          final isActive =
                              account['status']?.toString() != 'inactive' &&
                                  account['is_active'] != false;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isActive
                                    ? Colors.grey[300]
                                    : Colors.grey[100],
                                child: Icon(
                                  Icons.account_balance,
                                  color: isActive
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                              title: Text(account['name'] ?? ''),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Code: ${account['code'] ?? account['account_code'] ?? 'N/A'}'),
                                  Text(tt(LAll.all_type_x, ref, [type])),
                                  if (account['description'] != null)
                                    Text(account['description']),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.grey[200]
                                      : Colors.red[50],
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isActive
                                        ? Colors.black
                                        : Colors.red,
                                  ),
                                ),
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
        label: Text(t(LAll.all_add_account, ref)),
      ),
    );
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedType = 'asset';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(LAll.all_add_account, ref)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Account Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                    labelText: 'Account Code', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
initialValue: selectedType,
                decoration: const InputDecoration(
                    labelText: 'Type', border: OutlineInputBorder()),
                items: ['asset', 'liability', 'equity', 'income', 'expense']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => selectedType = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Description', border: OutlineInputBorder()),
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
                await Supabase.instance.client.from('accounts').insert({
                  'name': nameCtrl.text.trim(),
                  'code': codeCtrl.text.trim(),
                  'account_code': codeCtrl.text.trim(),
                  'type': selectedType,
                  'account_type': selectedType,
                  'normal_balance':
                      ['asset', 'expense'].contains(selectedType)
                          ? 'debit'
                          : 'credit',
                  'description': descCtrl.text.trim(),
                  'status': 'active',
                  'is_active': true,
                  'created_at': DateTime.now().toIso8601String(),
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            t(LAll.all_account_added_successfully, ref))),
                  );
                }
                _loadAccounts();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(tt(LAll.all_failed_to_add_account_x, ref,
                            [e.toString()]))),
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
}


