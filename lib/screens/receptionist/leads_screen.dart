import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class LeadsScreen extends ConsumerStatefulWidget {
  const LeadsScreen({super.key});

  @override
  ConsumerState<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends ConsumerState<LeadsScreen> {
  List<Map<String, dynamic>> _leads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  Future<void> _loadLeads() async {
    try {
      final data = await Supabase.instance.client
          .from('leads')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _leads = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load leads: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: t(LCrud.searchHintGeneric, ref),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                Expanded(
                  child: _leads.isEmpty
                      ? Center(child: Text(t(LCrud.noItemsFound, ref)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _leads.length,
                          itemBuilder: (context, index) {
                            final lead = _leads[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(
                                          lead['status'])
                                      .withValues(alpha: 0.1),
                                  child: Icon(Icons.person,
                                      color: _getStatusColor(
                                          lead['status'])),
                                ),
                                title: Text(lead['name'] ?? ''),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('${lead['interest'] ?? ''}'),
                                    Text(
                                        '${lead['email'] ?? ''} â€¢ ${lead['phone'] ?? ''}'),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(lead['status'])
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    lead['status'] ?? '',
                                    style: TextStyle(
                                      color: _getStatusColor(
                                          lead['status']),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                onTap: () => _showDetails(lead),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLeadDialog(),
        icon: const Icon(Icons.add),
        label: Text(t(LCrud.addLead, ref)),
      ),
    );
  }

  Future<void> _showAddLeadDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _AddLeadFormPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) _loadLeads();
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase() ?? '') {
      case 'new':
        return Colors.blue;
      case 'contacted':
        return Colors.orange;
      case 'follow-up':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showDetails(Map<String, dynamic> lead) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lead['name'] ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildDetailRow('Email', lead['email'] ?? ''),
              _buildDetailRow('Phone', lead['phone'] ?? ''),
              _buildDetailRow('Interest', lead['interest'] ?? ''),
              _buildDetailRow('Status', lead['status'] ?? ''),
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
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _AddLeadFormPage extends ConsumerStatefulWidget {
  const _AddLeadFormPage();

  @override
  ConsumerState<_AddLeadFormPage> createState() => _AddLeadFormPageState();
}

class _AddLeadFormPageState extends ConsumerState<_AddLeadFormPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _interestCtrl = TextEditingController();
  String _selectedStatus = 'New';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _interestCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    try {
      await Supabase.instance.client.from('leads').insert({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'interest': _interestCtrl.text.trim(),
        'status': _selectedStatus,
        'date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaff.leadAdded, ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add lead: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LCrud.addLead, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(L.cancel, ref)),
          ),
          ElevatedButton(
            onPressed: () { debugPrint('[leads_screen] Save button CLICKED'); _save(); },
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
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _interestCtrl,
              decoration: const InputDecoration(
                labelText: 'Interest',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const ['New', 'Contacted', 'Follow-up']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedStatus = v!),
            ),
          ],
        ),
      ),
    );
  }
}
