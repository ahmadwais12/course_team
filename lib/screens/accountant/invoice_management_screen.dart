import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/invoice_model.dart';
import '../../widgets/base_panel_layout.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

final invoicesProvider = StreamProvider<List<Invoice>>((ref) {
  final supabase = Supabase.instance.client;
  return supabase
      .from('invoices')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => Invoice.fromJson(json)).toList());
});

final invoiceStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase.from('invoices').select('status, amount');

  double totalPending = 0;
  double totalPaid = 0;
  double totalOverdue = 0;
  int countPending = 0;
  int countPaid = 0;
  int countOverdue = 0;

  for (final invoice in response) {
    final status = invoice['status'] as String?;
    final amount = (invoice['amount'] as num?)?.toDouble() ?? 0;

    switch (status) {
      case 'Pending':
        totalPending += amount;
        countPending++;
        break;
      case 'Paid':
        totalPaid += amount;
        countPaid++;
        break;
      case 'Overdue':
        totalOverdue += amount;
        countOverdue++;
        break;
    }
  }

  return {
    'totalPending': totalPending,
    'totalPaid': totalPaid,
    'totalOverdue': totalOverdue,
    'countPending': countPending,
    'countPaid': countPaid,
    'countOverdue': countOverdue,
  };
});

class InvoiceManagementScreen extends ConsumerStatefulWidget {
  const InvoiceManagementScreen({super.key});

  @override
  ConsumerState<InvoiceManagementScreen> createState() =>
      _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState
    extends ConsumerState<InvoiceManagementScreen> {
  final _invoiceNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _taxController = TextEditingController();

  String? _selectedStudentId;
  DateTime? _dueDate;
  bool _isCreating = false;

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _createInvoice() async {
    if (_invoiceNumberController.text.isEmpty ||
        _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(LCrud.fillRequiredFields, ref))),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final supabase = Supabase.instance.client;
      final amount = double.tryParse(_amountController.text) ?? 0;
      final discount = double.tryParse(_discountController.text) ?? 0;
      final tax = double.tryParse(_taxController.text) ?? 0;
      final total = amount - discount + tax;

      final invoiceData = {
        'invoice_number': _invoiceNumberController.text.trim(),
        'student_id': _selectedStudentId,
        'amount': amount,
        'description': _descriptionController.text.trim(),
        'discount_amount': discount,
        'tax_amount': tax,
        'total_amount': total,
        'due_date': _dueDate?.toIso8601String(),
        'status': 'Pending',
        'issue_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('invoices').insert(invoiceData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LPay2.invoiceCreated, ref))),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  void _clearForm() {
    _invoiceNumberController.clear();
    _amountController.clear();
    _descriptionController.clear();
    _discountController.clear();
    _taxController.clear();
    setState(() {
      _selectedStudentId = null;
      _dueDate = null;
    });
  }

  Future<void> _markAsPaid(Invoice invoice) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('invoices').update({
        'status': 'Paid',
        'paid_date': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', invoice.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LCrud.markAsPaid, ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _cancelInvoice(Invoice invoice) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('invoices').update({
        'status': 'Cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', invoice.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LPay2.invoiceCancelled, ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final statsAsync = ref.watch(invoiceStatsProvider);

    return BasePanelLayout(
      title: t(LTitle.invoiceManagement, ref),
      children: [
        // Stats Cards
        statsAsync.when(
          data: (stats) => Row(
            children: [
              _buildStatCard('Pending', '${stats['countPending']}',
                  stats['totalPending'], Colors.orange),
              SizedBox(width: 16.w),
              _buildStatCard('Paid', '${stats['countPaid']}',
                  stats['totalPaid'], Colors.blue),
              SizedBox(width: 16.w),
              _buildStatCard('Overdue', '${stats['countOverdue']}',
                  stats['totalOverdue'], Colors.red),
            ],
          ),
          loading: () => const PageSkeleton(type: 'list'),
          error: (_, __) => const SizedBox.shrink(),
        ),
        SizedBox(height: 24.h),

        // Create Invoice Section
        Card(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    t(LCrud.addInvoice, ref),
                    style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _invoiceNumberController,
                        label: t(LCrud.invoiceNumber, ref),
                        hint: 'INV-001',
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: CustomTextField(
                        controller: _amountController,
                        label: t(LPay2.amountLabel, ref),
                        keyboardType: TextInputType.number,
                        hint: '0.00',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _descriptionController,
                  label: t(LCrud.description, ref),
                  maxLines: 2,
                  hint: 'Invoice description',
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _discountController,
                        label: t(LPay2.discount, ref),
                        keyboardType: TextInputType.number,
                        hint: '0.00',
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: CustomTextField(
                        controller: _taxController,
                        label: t(LPay2.tax, ref),
                        keyboardType: TextInputType.number,
                        hint: '0.00',
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: InkWell(
                        onTap: _selectDueDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: t(LPay2.dueDate, ref),
                            border: const OutlineInputBorder(),
                          ),
                          child: Text(
                            _dueDate != null
                                ? DateFormat('MMM dd, yyyy').format(_dueDate!)
                                : 'Select Date',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                GradientButton(
                  onPressed: _isCreating ? () {} : _createInvoice,
                  text: _isCreating ? 'Creating...' : t(LCrud.addInvoice, ref),
                  isLoading: _isCreating,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.h),

        // Invoices List
        Card(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    t(LPay2.invoiceManagement, ref),
                    style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16.h),
                invoicesAsync.when(
                  data: (invoices) {
                    if (invoices.isEmpty) {
                      return Center(
                        child: Text(t(LPay2.noInvoices, ref)),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: invoices.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        return ListTile(
                          leading: Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              color: _getStatusColor(invoice.status)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.receipt,
                              color: _getStatusColor(invoice.status),
                            ),
                          ),
                          title: Text(invoice.invoiceNumber),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invoice.description ?? 'No description',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (invoice.dueDate != null)
                                Text(
                                  'Due: ${DateFormat('MMM dd, yyyy').format(invoice.dueDate!)}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: invoice.isOverdueCheck
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${invoice.totalAmount?.toStringAsFixed(2) ?? invoice.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  invoice.status,
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.white),
                                ),
                                backgroundColor:
                                    _getStatusColor(invoice.status),
                                padding: EdgeInsets.zero,
                                labelPadding:
                                    EdgeInsets.symmetric(horizontal: 8.w),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          onTap: () {
                            if (invoice.isPending) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(t(LCrud.invoiceActions, ref)),
                                  content:
                                      Text('Invoice #${invoice.invoiceNumber}'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _markAsPaid(invoice);
                                      },
                                      child: Text(t(LCrud.markAsPaid, ref)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _cancelInvoice(invoice);
                                      },
                                      child: Text(t(L.cancel, ref),
                                          style: const TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                  loading: () =>
                      const PageSkeleton(type: 'list'),
                  error: (error, _) => Text('Error: $error'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String count, double amount, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: color,
                  size: 20.w,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                count,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
