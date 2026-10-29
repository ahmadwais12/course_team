import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      final data = await Supabase.instance.client
          .from('invoices')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _invoices = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load invoices: $e')),
        );
      }
    }
  }

  DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    return DateTime.parse(date.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()), title: const Text('Invoices')),
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
                  child: _invoices.isEmpty
                      ? Center(child: Text(t(LPay2.noInvoices, ref)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _invoices.length,
                          itemBuilder: (context, index) {
                            final invoice = _invoices[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(
                                          invoice['status'])
                                      .withValues(alpha: 0.1),
                                  child: Icon(Icons.receipt_long,
                                      color: _getStatusColor(
                                          invoice['status'])),
                                ),
                                title:
                                    Text(invoice['invoice_number'] ?? invoice['id']?.toString() ?? ''),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Student: ${invoice['student_name'] ?? invoice['student_id'] ?? 'N/A'}'),
                                    Text(
                                        'Due: ${_formatDate(_parseDate(invoice['due_date']))}'),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${invoice['amount'] ?? 0}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                                invoice['status'])
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        invoice['status'] ?? '',
                                        style: TextStyle(
                                          color: _getStatusColor(
                                              invoice['status']),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () =>
                                    _showInvoiceDetails(invoice),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateInvoiceDialog(),
        icon: const Icon(Icons.add),
        label: Text(t(LCrud.addInvoice, ref)),
      ),
    );
  }

  Future<void> _showCreateInvoiceDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _CreateInvoicePage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) _loadInvoices();
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase() ?? '') {
      case 'paid':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff < 0) return '${-diff} days ago';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'In $diff days';
  }

  void _showInvoiceDetails(Map<String, dynamic> invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invoice['invoice_number'] ?? invoice['id']?.toString() ?? '',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Student',
                  invoice['student_name'] ?? invoice['student_id'] ?? 'N/A'),
              _buildDetailRow('Amount', '\$${invoice['amount'] ?? 0}'),
              _buildDetailRow('Due Date',
                  _formatDate(_parseDate(invoice['due_date']))),
              _buildDetailRow('Status', invoice['status'] ?? ''),
              const SizedBox(height: 24),
              if (invoice['status'] != 'Paid')
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await Supabase.instance.client
                          .from('invoices')
                          .update({
                            'status': 'Paid',
                            'paid_date':
                                DateTime.now().toIso8601String(),
                            'updated_at':
                                DateTime.now().toIso8601String(),
                          })
                          .eq('id', invoice['id']);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Payment recorded successfully')),
                        );
                      }
                      _loadInvoices();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Failed to record payment: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.payment),
                  label: Text(t(LCrud.recordPayment, ref)),
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Receipt download started')),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: Text(t(LCrud.downloadReceipt, ref)),
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
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _CreateInvoicePage extends ConsumerStatefulWidget {
  const _CreateInvoicePage();

  @override
  ConsumerState<_CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends ConsumerState<_CreateInvoicePage> {
  final _studentCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _studentCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  Future<void> _save() async {
    if (_studentCtrl.text.trim().isEmpty) return;
    try {
      await Supabase.instance.client.from('invoices').insert({
        'student_name': _studentCtrl.text.trim(),
        'amount': double.tryParse(_amountCtrl.text) ?? 0,
        'due_date': _selectedDueDate.toIso8601String(),
        'status': 'Pending',
        'issue_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LPay2.invoiceCreated, ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create invoice: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LCrud.addInvoice, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(L.cancel, ref)),
          ),
          ElevatedButton(
            onPressed: () { debugPrint('[invoices_screen] Save button CLICKED'); _save(); },
            child: Text(t(LCrud.createdSuccessfully, ref)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _studentCtrl,
              decoration: InputDecoration(
                labelText: t(LPay2.studentName, ref),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              decoration: InputDecoration(
                labelText: t(LPay2.amountLabel, ref),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                '${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}',
              ),
              subtitle: const Text('Tap to change due date'),
              onTap: _pickDate,
            ),
          ],
        ),
      ),
    );
  }
}


