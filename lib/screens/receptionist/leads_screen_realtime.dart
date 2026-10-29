import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/providers/receptionist_providers.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class LeadsScreenRealtime extends ConsumerStatefulWidget {
  const LeadsScreenRealtime({super.key});

  @override
  ConsumerState<LeadsScreenRealtime> createState() =>
      _LeadsScreenRealtimeState();
}

class _LeadsScreenRealtimeState extends ConsumerState<LeadsScreenRealtime> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final leadsAsync = ref.watch(leadsStreamProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: t(LCrud.searchHintGeneric, ref),
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child: leadsAsync.when(
              data: (leads) {
                // Filter by search query
                final filtered = leads.where((lead) {
                  final name = lead['name']?.toString().toLowerCase() ?? '';
                  final email = lead['email']?.toString().toLowerCase() ?? '';
                  final searchLower = searchQuery.toLowerCase();
                  return name.contains(searchLower) ||
                      email.contains(searchLower);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          t(LCrud.noItemsFound, ref),
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final lead = filtered[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _getStatusColor(lead['status']).withValues(alpha: 0.1),
                          child: Icon(Icons.person,
                              color: _getStatusColor(lead['status'])),
                        ),
                        title: Text(lead['name']?.toString() ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tt(LAll.all_s392, ref,
                                [lead['interest']?.toString() ?? ''])),
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            lead['status']?.toString() ?? 'Unknown',
                            style: TextStyle(
                              color: _getStatusColor(lead['status']),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        onTap: () => _showDetails(lead),
                      ),
                    );
                  },
                );
              },
              loading: () => const PageSkeleton(type: 'list'),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(tt(LAll.all_error_loading_leads_x, ref,
                        [error.toString()]),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(leadsStreamProvider),
                      child: Text(t(L.retry, ref)),
                    ),
                  ],
                ),
              ),
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

  Color _getStatusColor(dynamic status) {
    switch (status.toString().toLowerCase()) {
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
              Text(
                lead['name']?.toString() ?? 'Unknown',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Email', lead['email']?.toString() ?? 'N/A'),
              _buildDetailRow('Phone', lead['phone']?.toString() ?? 'N/A'),
              _buildDetailRow(
                  'Interest', lead['interest']?.toString() ?? 'N/A'),
              _buildDetailRow('Status', lead['status']?.toString() ?? 'N/A'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text(t(LAll.all_contacting_lead, ref))),
                        );
                      },
                      icon: const Icon(Icons.phone),
                      label: Text(t(LAll.all_contact, ref)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text(t(LAll.all_edit_lead_feature, ref))),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: Text(t(L.edit, ref)),
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

  Future<void> _showAddLeadDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _AddLeadRealtimeFormPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) {
      ref.invalidate(leadsStreamProvider);
    }
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

class _AddLeadRealtimeFormPage extends ConsumerStatefulWidget {
  const _AddLeadRealtimeFormPage();

  @override
  ConsumerState<_AddLeadRealtimeFormPage> createState() => _AddLeadRealtimeFormPageState();
}

class _AddLeadRealtimeFormPageState extends ConsumerState<_AddLeadRealtimeFormPage> {
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
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    try {
      await Supabase.instance.client.from('leads').insert({
        'name': name,
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
          SnackBar(
              content: Text(
                  tt(LAll.all_failed_to_add_lead_x, ref, [e.toString()]))),
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
            onPressed: () { debugPrint('[leads_screen_realtime] Save button CLICKED'); _save(); },
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
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
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
              items: ['New', 'Contacted', 'Follow-up']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedStatus = v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
