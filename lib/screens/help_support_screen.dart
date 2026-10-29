import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/theme.dart';
import 'package:go_router/go_router.dart';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  List<Map<String, dynamic>> _faqs = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFaqs() async {
    try {
      final data = await Supabase.instance.client
          .from('faq')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: true);
      if (mounted) setState(() => _faqs = List<Map<String, dynamic>>.from(data));
    } catch (_) {
      if (mounted) setState(() => _faqs = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredFaqs {
    final query = _searchCtrl.text.toLowerCase();
    if (query.isEmpty) return _faqs;
    return _faqs.where((f) {
      final q = f['question']?.toString().toLowerCase() ?? '';
      final a = f['answer']?.toString().toLowerCase() ?? '';
      return q.contains(query) || a.contains(query);
    }).toList();
  }

  void _submitTicket(String subject, String message) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('support_tickets').insert({
        'user_id': user?.id,
        'subject': subject,
        'message': message,
        'status': 'open',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaff.ticketCreated, ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_failed_to_submit_ticket_x, ref, [e.toString()]))),
        );
      }
    }
  }

  void _showTicketDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SubmitTicketPage(onSubmit: _submitTicket),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(LTitle.helpSupport, ref)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFaqs,
              child: ListView(
                padding: AppSpacing.paddingLg,
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: t(LCrud.searchHintGeneric, ref),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                      filled: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Frequently Asked Questions',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_filteredFaqs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(t(LAll.all_no_faq_entries_found, ref), style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    )
                  else
                    ..._filteredFaqs.map((f) => _buildFAQItem(
                      context,
                      f['question']?.toString() ?? '',
                      f['answer']?.toString() ?? '',
                    )),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Contact Support',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    child: Padding(
                      padding: AppSpacing.paddingMd,
                      child: Column(
                        children: [
                          ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.email_rounded)),
                            title: Text(t(LAll.all_email_support, ref)),
                            subtitle: Text(t(LAll.all_supportemiscom, ref)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => context.go('/messages'),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.phone_rounded)),
                            title: Text(t(LAll.all_phone_support, ref)),
                            subtitle: Text(t(LAll.all_1234567890, ref)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => context.go('/messages'),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.chat_rounded)),
                            title: Text(t(LAll.all_live_chat, ref)),
                            subtitle: Text(t(LAll.all_available_9_am_5_pm, ref)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => context.go('/messages'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Card(
                    child: InkWell(
                      onTap: _showTicketDialog,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Padding(
                        padding: AppSpacing.paddingMd,
                        child: Row(
                          children: [
                            Container(
                              padding: AppSpacing.paddingSm,
                              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
                              child: const Icon(Icons.confirmation_number_rounded, color: Colors.blue),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t(LAll.all_submit_a_ticket, ref), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                  Text(t(LAll.all_report_an_issue_or_request_assistance, ref), style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: AppSpacing.paddingMd,
            child: Text(answer),
          ),
        ],
      ),
    );
  }
}

class _SubmitTicketPage extends ConsumerStatefulWidget {
  final void Function(String subject, String message) onSubmit;
  const _SubmitTicketPage({required this.onSubmit});

  @override
  ConsumerState<_SubmitTicketPage> createState() => _SubmitTicketPageState();
}

class _SubmitTicketPageState extends ConsumerState<_SubmitTicketPage> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LAll.all_submit_a_ticket, ref)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t(L.cancel, ref))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: 'Subject')),
          const SizedBox(height: 12),
          TextField(controller: _messageCtrl, decoration: const InputDecoration(labelText: 'Message'), maxLines: 4),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () { debugPrint('[help_support_screen] Save button CLICKED'); _save(); },
            child: Text(t(L.submit, ref)),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_subjectCtrl.text.isEmpty || _messageCtrl.text.isEmpty) return;
    widget.onSubmit(_subjectCtrl.text, _messageCtrl.text);
    Navigator.pop(context);
  }
}
