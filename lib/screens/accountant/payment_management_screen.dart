import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/base_panel_layout.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

final studentsForPaymentProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await Supabase.instance.client
      .from('students')
      .select()
      .eq('status', 'active')
      .order('full_name');
  return response;
});

final studentPaymentsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, studentId) async {
  final response = await Supabase.instance.client
      .from('payments')
      .select()
      .eq('student_id', studentId)
      .order('payment_date', ascending: false);
  return response;
});

class PaymentManagementScreen extends ConsumerStatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  ConsumerState<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends ConsumerState<PaymentManagementScreen> {
  String? _selectedStudentId;
  String? _selectedStudentName;
  bool _isLoading = false;

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  String? _selectedPaymentMethod;
  String? _selectedPaymentType;
  DateTime? _paymentDate;

  final List<String> _paymentMethods = ['Cash', 'Card', 'Bank Transfer', 'Check', 'Online'];
  final List<String> _paymentTypes = ['Tuition Fee', 'Registration Fee', 'Exam Fee', 'Library Fee', 'Other'];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _invoiceNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _recordPayment() async {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student')),
      );
      return;
    }

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      
      // Generate invoice number if not provided
      final invoiceNumber = _invoiceNumberController.text.isEmpty
          ? 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
          : _invoiceNumberController.text;

      final paymentData = {
        'student_id': _selectedStudentId,
        'amount': double.parse(_amountController.text),
        'payment_type': _selectedPaymentType ?? 'Tuition Fee',
        'payment_method': _selectedPaymentMethod ?? 'Cash',
        'payment_date': _paymentDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'invoice_number': invoiceNumber,
        'description': _descriptionController.text.trim(),
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
        'created_by': supabase.auth.currentUser?.id,
      };

      await supabase.from('payments').insert(paymentData);

      // Update student's paid amount
      final studentResponse = await supabase
          .from('students')
          .select('paid_amount')
          .eq('id', _selectedStudentId!)
          .single();
      
      final currentPaid = (studentResponse['paid_amount'] as num?)?.toDouble() ?? 0.0;
      final newAmount = double.parse(_amountController.text);
      
      await supabase.from('students').update({
        'paid_amount': currentPaid + newAmount,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _selectedStudentId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully')),
        );
        _clearForm();
        ref.invalidate(studentPaymentsProvider(_selectedStudentId!));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _amountController.clear();
    _descriptionController.clear();
    _invoiceNumberController.clear();
    setState(() {
      _selectedPaymentMethod = null;
      _selectedPaymentType = null;
      _paymentDate = null;
    });
  }

  Future<void> _generateInvoice(String paymentId) async {
    // Navigate to invoice screen or generate PDF
    context.push('/invoice/$paymentId');
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsForPaymentProvider);

    return BasePanelLayout(
      title: t(LTitle.paymentManagement, ref),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Payment Form
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t(LCrud.recordPayment, ref),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 24.h),
                      studentsAsync.when(
                        data: (students) {
                          return DropdownButtonFormField<String>(
initialValue: _selectedStudentId,
                            decoration: InputDecoration(
                              labelText: t(LCrud.selectStudent, ref),
                              border: const OutlineInputBorder(),
                            ),
                            items: students.map((student) {
                              return DropdownMenuItem(
                                value: student['id'] as String,
                                child: Text(student['full_name'] as String? ?? 'Unknown'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              final selected = students.firstWhere(
                                (s) => s['id'] == value,
                                orElse: () => {},
                              );
                              setState(() {
                                _selectedStudentId = value;
                                _selectedStudentName = selected['full_name'] as String?;
                              });
                            },
                          );
                        },
                        loading: () => const PageSkeleton(type: 'list'),
                        error: (_, __) => const Text('Error loading students'),
                      ),
                      SizedBox(height: 16.h),
                      if (_selectedStudentId != null) ...[
                        FutureBuilder<Map<String, dynamic>>(
                          future: _getStudentBalance(_selectedStudentId!),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox.shrink();
                            final data = snapshot.data!;
                            return Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Student: ${_selectedStudentName ?? ''}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text('Total Fees: \$${data['total_fees']?.toStringAsFixed(2) ?? '0.00'}'),
                                  Text('Paid: \$${data['paid_amount']?.toStringAsFixed(2) ?? '0.00'}'),
                                  Text(
                                    'Balance: \$${data['remaining_balance']?.toStringAsFixed(2) ?? '0.00'}',
                                    style: TextStyle(
                                      color: (data['remaining_balance'] ?? 0) > 0 
                                          ? Colors.red 
                                          : Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _amountController,
                                label: t(LPay2.amountLabel, ref),
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                    value?.isEmpty ?? true ? 'Required' : null,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: InkWell(
                                onTap: _selectDate,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: t(LPayment.paymentDate, ref),
                                    border: const OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    _paymentDate != null
                                        ? DateFormat('MMM dd, yyyy').format(_paymentDate!)
                                        : 'Select Date',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
initialValue: _selectedPaymentType,
                                decoration: InputDecoration(
                                  labelText: t(LPay2.paymentType, ref),
                                  border: const OutlineInputBorder(),
                                ),
                                items: _paymentTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedPaymentType = value);
                                },
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: DropdownButtonFormField<String>(
initialValue: _selectedPaymentMethod,
                                decoration: InputDecoration(
                                  labelText: t(LPay2.paymentMethod, ref),
                                  border: const OutlineInputBorder(),
                                ),
                                items: _paymentMethods.map((method) {
                                  return DropdownMenuItem(
                                    value: method,
                                    child: Text(method),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedPaymentMethod = value);
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        CustomTextField(
                          controller: _invoiceNumberController,
                          label: 'Invoice Number (Optional)',
                          hint: 'Auto-generated if empty',
                        ),
                        SizedBox(height: 16.h),
                        CustomTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          maxLines: 2,
                          hint: 'Additional notes about this payment',
                        ),
                        SizedBox(height: 24.h),
                        GradientButton(
                          onPressed: _isLoading ? () {} : _recordPayment,
                          text: _isLoading ? 'Processing...' : 'Record Payment',
                          isLoading: _isLoading,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 24.w),
            // Right side - Payment History
            Expanded(
              flex: 3,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Payments',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 16.h),
                      if (_selectedStudentId != null)
                        Consumer(
                          builder: (context, ref, child) {
                            final paymentsAsync = ref.watch(studentPaymentsProvider(_selectedStudentId!));
                            return paymentsAsync.when(
                              data: (payments) {
                                if (payments.isEmpty) {
                                  return Center(
                                    child: Text(t(LPay2.noPayments, ref)),
                                  );
                                }
                                return ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: payments.length,
                                  itemBuilder: (context, index) {
                                    final payment = payments[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: _getPaymentMethodColor(
                                          payment['payment_method'] as String?,
                                        ),
                                        child: Icon(
                                          _getPaymentMethodIcon(
                                            payment['payment_method'] as String?,
                                          ),
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        '\$${(payment['amount'] as num).toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        '${payment['payment_type'] ?? 'Payment'} â€¢ ${DateFormat('MMM dd, yyyy').format(DateTime.parse(payment['payment_date'] as String))}',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Chip(
                                            label: Text(
                                              payment['status'] as String? ?? 'pending',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            backgroundColor: _getStatusColor(
                                              payment['status'] as String?,
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          IconButton(
                                            icon: const Icon(Icons.receipt),
                                            onPressed: () => _generateInvoice(payment['id'] as String),
                                            tooltip: 'View Invoice',
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              loading: () => const PageSkeleton(type: 'list'),
                              error: (_, __) => const Text('Error loading payments'),
                            );
                          },
                        )
                      else
                        Center(
                          child: Text(t(LPay2.selectStudentForHistory, ref)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getStudentBalance(String studentId) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('students')
        .select('total_fees, paid_amount')
        .eq('id', studentId)
        .single();
    
    final totalFees = (response['total_fees'] as num?)?.toDouble() ?? 0.0;
    final paidAmount = (response['paid_amount'] as num?)?.toDouble() ?? 0.0;
    
    return {
      'total_fees': totalFees,
      'paid_amount': paidAmount,
      'remaining_balance': totalFees - paidAmount,
    };
  }

  Color _getPaymentMethodColor(String? method) {
    switch (method?.toLowerCase()) {
      case 'cash':
        return Colors.blue;
      case 'card':
        return Colors.blue;
      case 'bank transfer':
        return Colors.purple;
      case 'check':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentMethodIcon(String? method) {
    switch (method?.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'bank transfer':
        return Icons.account_balance;
      case 'check':
        return Icons.check_circle;
      default:
        return Icons.payment;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.blue.shade100;
      case 'pending':
        return Colors.orange.shade100;
      case 'failed':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}
