import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/ui_helpers.dart';

class StaffFrontDeskScreen extends ConsumerStatefulWidget {
  const StaffFrontDeskScreen({super.key});
  @override
  ConsumerState<StaffFrontDeskScreen> createState() =>
      _StaffFrontDeskScreenState();
}

class _StaffFrontDeskScreenState extends ConsumerState<StaffFrontDeskScreen> {
  final _sb = Supabase.instance.client;
  bool _loading = true;
  int _todayVisitors = 0;
  int _newLeads = 0;
  List<Map<String, dynamic>> _leads = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final visitors = await _sb
          .from('visitors')
          .select('id')
          .eq('visit_date', today);
      final leadsData = await _sb
          .from('leads')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _todayVisitors = visitors.length;
        _leads = List<Map<String, dynamic>>.from(leadsData);
        _newLeads = _leads.length;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? lead}) {
    final isEdit = lead != null;
    final nameCtrl = TextEditingController(text: lead?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: lead?['phone'] ?? '');
    final emailCtrl = TextEditingController(text: lead?['email'] ?? '');
    String source = lead?['source'] ?? 'walk_in';
    String status = lead?['status'] ?? 'new';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const VSpace(AppSpacing.md),
                    Text(
                      isEdit ? 'Edit Lead' : 'New Lead',
                      style: theme.textTheme.titleLarge,
                    ),
                    const VSpace(AppSpacing.lg),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Name is required' : null,
                    ),
                    const VSpace(AppSpacing.md),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    const VSpace(AppSpacing.md),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const VSpace(AppSpacing.md),
                    DropdownButtonFormField<String>(
initialValue: source,
                      decoration:
                          const InputDecoration(labelText: 'Source'),
                      items: [
                        DropdownMenuItem(
                            value: 'walk_in',
                            child: Text(t(LAll.all_walkin, ref))),
                        DropdownMenuItem(
                            value: 'referral',
                            child: Text(t(LAll.all_referral, ref))),
                        DropdownMenuItem(
                            value: 'online', child: Text(t(LAll.all_online, ref))),
                        DropdownMenuItem(
                            value: 'social', child: Text(t(LAll.all_social, ref))),
                      ],
                      onChanged: (v) {
                        if (v != null) setSheetState(() => source = v);
                      },
                    ),
                    const VSpace(AppSpacing.md),
                    DropdownButtonFormField<String>(
initialValue: status,
                      decoration:
                          const InputDecoration(labelText: 'Status'),
                      items: [
                        DropdownMenuItem(
                            value: 'new', child: Text(t(LStatus.cNew, ref))),
                        DropdownMenuItem(
                            value: 'contacted',
                            child: Text(t(LAll.all_contacted, ref))),
                        DropdownMenuItem(
                            value: 'converted',
                            child: Text(t(LAll.all_converted, ref))),
                        DropdownMenuItem(
                            value: 'lost', child: Text(t(LAll.all_lost, ref))),
                      ],
                      onChanged: (v) {
                        if (v != null) setSheetState(() => status = v);
                      },
                    ),
                    const VSpace(AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final payload = {
                            'name': nameCtrl.text.trim(),
                            'phone': phoneCtrl.text.trim(),
                            'email': emailCtrl.text.trim(),
                            'source': source,
                            'status': status,
                          };
                          try {
                            if (isEdit) {
                              await _sb
                                  .from('leads')
                                  .update(payload)
                                  .eq('id', lead['id']);
                            } else {
                              await _sb.from('leads').insert(payload);
                            }
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            _loadData();
                          } catch (_) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text(t(LAll.all_failed_to_save_lead, ref))),
                              );                            }
                          }
                        },
                        child: Text(isEdit ? 'Update' : 'Create'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Map<String, dynamic> lead) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(LAll.all_delete_lead, ref)),
        content: Text('Delete "${lead['name']}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () async {
              try {
                await _sb.from('leads').delete().eq('id', lead['id']);
                if (ctx.mounted) Navigator.of(ctx).pop();
                _loadData();
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t(LAll.all_failed_to_delete_lead, ref))),
                  );
                }
              }
            },
            child: Text(t(L.delete, ref)),
          ),
        ],
      ),
    );
  }

  Color _sourceColor(String source, BuildContext context) {
    switch (source) {
      case 'walk_in':
        return Colors.blue;
      case 'referral':
        return Colors.green;
      case 'online':
        return Colors.purple;
      case 'social':
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _statusColor(String status, BuildContext context) {
    switch (status) {
      case 'new':
        return Colors.teal;
      case 'contacted':
        return Colors.blue;
      case 'converted':
        return Colors.green;
      case 'lost':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).replaceAll('_', ' ')}';

  Widget _buildLeadCard(Map<String, dynamic> lead) {
    final theme = Theme.of(context);
    final source = (lead['source'] ?? '') as String;
    final status = (lead['status'] ?? '') as String;
    return AppCard(
      pressable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lead['name'] ?? '',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit',
                onPressed: () => _showAddEditDialog(lead: lead),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: theme.colorScheme.error),
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(lead),
              ),
            ],
          ),
          if (lead['phone'] != null &&
              (lead['phone'] as String).isNotEmpty) ...[
            const VSpace(4),
            Row(
              children: [
                Icon(Icons.phone_outlined,
                    size: 14, color: theme.textTheme.bodySmall?.color),
                const HSpace(6),
                Text(lead['phone'], style: theme.textTheme.bodySmall),
              ],
            ),
          ],
          if (lead['email'] != null &&
              (lead['email'] as String).isNotEmpty) ...[
            const VSpace(4),
            Row(
              children: [
                Icon(Icons.email_outlined,
                    size: 14, color: theme.textTheme.bodySmall?.color),
                const HSpace(6),
                Text(lead['email'], style: theme.textTheme.bodySmall),
              ],
            ),
          ],
          const VSpace(AppSpacing.sm),
          Row(
            children: [
              InfoBadge(
                label: _capitalize(source),
                color: _sourceColor(source, context),
              ),
              const HSpace(AppSpacing.sm),
              InfoBadge(
                label: _capitalize(status),
                color: _statusColor(status, context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          const SectionHeader(
            title: 'Receptionist',
            subtitle: 'Admissions, leads, and inquiries',
            icon: Icons.support_agent_outlined,
          ),
          const VSpace(AppSpacing.lg),
          StatCard(
            title: 'Today\'s Visitors',
            value: '$_todayVisitors',
            icon: Icons.person_pin_rounded,
          ),
          const VSpace(AppSpacing.md),
          StatCard(
            title: 'New Leads',
            value: '$_newLeads',
            icon: Icons.contact_mail_outlined,
          ),
          const VSpace(AppSpacing.lg),
          const SectionHeader(
            title: 'Leads',
            subtitle: 'Manage and track leads',
            icon: Icons.leaderboard_outlined,
          ),
          const VSpace(AppSpacing.md),
          if (_leads.isEmpty)
            EmptyState(
              icon: Icons.contact_mail_outlined,
              title: 'No leads yet',
              message: 'Tap the + button to add your first lead.',
              actionText: 'Add Lead',
              onAction: () => _showAddEditDialog(),
            )
          else
            ..._leads.map((lead) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _buildLeadCard(lead),
                )),
          const VSpace(80),
        ],
      ),
    );
  }
}
