import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import '../../models/expense_model.dart';
import '../../widgets/base_panel_layout.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

final expensesProvider = StreamProvider.family<List<ExpenseModel>, Map<String, dynamic>?>((ref, filters) {
  final supabase = Supabase.instance.client;
  var query = supabase.from('expenses').stream(primaryKey: ['id']);
  
  if (filters != null) {
    final category = filters['category'] as String?;
    final status = filters['status'] as String?;
    
    return query.map((data) {
      var filtered = data;
      if (category != null) {
        filtered = filtered.where((e) => e['category'] == category).toList();
      }
      if (status != null) {
        filtered = filtered.where((e) => e['status'] == status).toList();
      }
      return filtered.map((json) => ExpenseModel.fromJson(json)).toList();
    });
  }
  
  return query.map((data) => data.map((json) => ExpenseModel.fromJson(json)).toList());
});

final expenseStatsProvider = FutureProvider.family<Map<String, dynamic>, Map<String, DateTime?>>((ref, params) async {
  final supabase = Supabase.instance.client;
  final startDate = params['startDate'];
  final endDate = params['endDate'];
  
  var query = supabase.from('expenses').select('status, amount, category');

  if (startDate != null) {
    query = query.gte('expense_date', startDate.toIso8601String());
  }
  if (endDate != null) {
    query = query.lte('expense_date', endDate.toIso8601String());
  }

  final response = await query;

  double totalPending = 0;
  double totalApproved = 0;
  double totalPaid = 0;
  int countPending = 0;
  int countApproved = 0;
  int countPaid = 0;
  Map<String, double> categoryTotals = {};

  for (final expense in response) {
    final status = expense['status'] as String?;
    final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
    final category = expense['category'] as String? ?? 'Other';

    switch (status) {
      case 'pending':
        totalPending += amount;
        countPending++;
        break;
      case 'approved':
        totalApproved += amount;
        countApproved++;
        break;
      case 'paid':
        totalPaid += amount;
        countPaid++;
        break;
    }

    categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
  }

  return {
    'totalPending': totalPending,
    'totalApproved': totalApproved,
    'totalPaid': totalPaid,
    'countPending': countPending,
    'countApproved': countApproved,
    'countPaid': countPaid,
    'categoryTotals': categoryTotals,
    'total': totalPending + totalApproved + totalPaid,
  };
});

class ExpensesTrackingScreen extends ConsumerStatefulWidget {
  const ExpensesTrackingScreen({super.key});

  @override
  ConsumerState<ExpensesTrackingScreen> createState() => _ExpensesTrackingScreenState();
}

class _ExpensesTrackingScreenState extends ConsumerState<ExpensesTrackingScreen> {
  final _categoryController = TextEditingController();
  final _subcategoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _vendorController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedStatus;
  String? _selectedPaymentMethod;
  DateTime? _expenseDate;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  bool _isCreating = false;

  final List<String> _categories = [
    'Utilities', 'Rent', 'Salaries', 'Supplies', 'Maintenance', 
    'Marketing', 'Transportation', 'Equipment', 'Insurance', 'Other'
  ];
  final List<String> _statuses = ['All', 'pending', 'approved', 'paid', 'rejected'];
  final List<String> _paymentMethods = ['Cash', 'Bank Transfer', 'Check', 'Credit Card', 'Debit Card'];

  @override
  void dispose() {
    _categoryController.dispose();
    _subcategoryController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _vendorController.dispose();
    _invoiceNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectExpenseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _expenseDate = picked);
    }
  }

  Future<void> _selectFilterStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _filterStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _filterStartDate = picked);
    }
  }

  Future<void> _selectFilterEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _filterEndDate ?? DateTime.now(),
      firstDate: _filterStartDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _filterEndDate = picked);
    }
  }

  Future<void> _createExpense() async {
    if (_selectedCategory == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(LAll.all_please_fill_in_category_and_amount, ref))),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final supabase = Supabase.instance.client;
      final expenseData = {
        'category': _selectedCategory,
        'subcategory': _subcategoryController.text.trim(),
        'amount': double.tryParse(_amountController.text) ?? 0,
        'expense_date': (_expenseDate ?? DateTime.now()).toIso8601String(),
        'description': _descriptionController.text.trim(),
        'vendor': _vendorController.text.trim(),
        'invoice_number': _invoiceNumberController.text.trim(),
        'payment_method': _selectedPaymentMethod,
        'notes': _notesController.text.trim(),
        'status': 'pending',
        'created_by': supabase.auth.currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('expenses').insert(expenseData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LPay2.expenseRecorded, ref))),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  void _clearForm() {
    _categoryController.clear();
    _subcategoryController.clear();
    _amountController.clear();
    _descriptionController.clear();
    _vendorController.clear();
    _invoiceNumberController.clear();
    _notesController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedPaymentMethod = null;
      _expenseDate = null;
    });
  }

  Future<void> _approveExpense(ExpenseModel expense) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('expenses').update({
        'status': 'approved',
        'approved_by': supabase.auth.currentUser?.id,
        'approved_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', expense.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LPay2.expenseApproved, ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    }
  }

  Future<void> _markAsPaid(ExpenseModel expense) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('expenses').update({
        'status': 'paid',
        'payment_method': expense.paymentMethod ?? 'Bank Transfer',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', expense.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LPay2.expensePaid, ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    }
  }

  Future<void> _rejectExpense(ExpenseModel expense) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('expenses').update({
        'status': 'rejected',
        'approved_by': supabase.auth.currentUser?.id,
        'approved_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', expense.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LPay2.expenseRejected, ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'paid':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32.w),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 4.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = {
      'category': _selectedCategory,
      'status': _selectedStatus == 'All' ? null : _selectedStatus,
    };
    final expensesAsync = ref.watch(expensesProvider(filters));
    final statsParams = {
      'startDate': _filterStartDate,
      'endDate': _filterEndDate,
    };
    final statsAsync = ref.watch(expenseStatsProvider(statsParams));

    return BasePanelLayout(
      title: 'Expenses Tracking',
      children: [
        // Stats Cards
        statsAsync.when(
          data: (stats) {
            return Wrap(
              spacing: 16.w,
              runSpacing: 16.h,
              children: [
                SizedBox(
                  width: 200.w,
                  child: _buildStatCard(
                    'Total',
                    NumberFormat.currency(symbol: '\$').format(stats['total']),
                    Colors.purple,
                    Icons.account_balance_wallet,
                  ),
                ),
                SizedBox(
                  width: 150.w,
                  child: _buildStatCard(
                    'Pending',
                    NumberFormat.currency(symbol: '\$').format(stats['totalPending']),
                    Colors.orange,
                    Icons.pending,
                  ),
                ),
                SizedBox(
                  width: 150.w,
                  child: _buildStatCard(
                    'Approved',
                    NumberFormat.currency(symbol: '\$').format(stats['totalApproved']),
                    Colors.blue,
                    Icons.thumb_up,
                  ),
                ),
                SizedBox(
                  width: 150.w,
                  child: _buildStatCard(
                    'Paid',
                    NumberFormat.currency(symbol: '\$').format(stats['totalPaid']),
                    Colors.blue,
                    Icons.paid,
                  ),
                ),
              ],
            );
          },
          loading: () => const PageSkeleton(type: 'list'),
          error: (_, __) => const SizedBox.shrink(),
        ),
        SizedBox(height: 24.h),

        // Filters
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t(LFilter.cFilters, ref), style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: ['All', ..._categories].map((cat) {
                          return DropdownMenuItem(
                            value: cat == 'All' ? null : cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategory = value);
                        },
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: DropdownButtonFormField<String>(
initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: _statuses.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status == 'All' ? 'All' : status.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedStatus = value);
                        },
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: InkWell(
                        onTap: _selectFilterStartDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'From Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _filterStartDate != null
                                ? DateFormat('MMM dd').format(_filterStartDate!)
                                : 'Select',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: InkWell(
                        onTap: _selectFilterEndDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'To Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _filterEndDate != null
                                ? DateFormat('MMM dd').format(_filterEndDate!)
                                : 'Select',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.h),

        // Create Expense Section
        Card(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record New Expense',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategory = value);
                        },
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: CustomTextField(
                        controller: _subcategoryController,
                        label: 'Subcategory',
                        hint: 'e.g., Electricity',
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: CustomTextField(
                        controller: _amountController,
                        label: 'Amount *',
                        keyboardType: TextInputType.number,
                        hint: '0.00',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectExpenseDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Expense Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _expenseDate != null
                                ? DateFormat('MMM dd, yyyy').format(_expenseDate!)
                                : 'Select Date',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: CustomTextField(
                        controller: _vendorController,
                        label: 'Vendor',
                        hint: 'Vendor name',
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: DropdownButtonFormField<String>(
initialValue: _selectedPaymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                          border: OutlineInputBorder(),
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
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Expense description',
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: CustomTextField(
                        controller: _invoiceNumberController,
                        label: 'Invoice Number',
                        hint: 'INV-001',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _notesController,
                  label: 'Notes',
                  maxLines: 2,
                  hint: 'Additional notes...',
                ),
                SizedBox(height: 24.h),
                GradientButton(
                  onPressed: _isCreating ? () {} : _createExpense,
                  text: _isCreating ? 'Recording...' : 'Record Expense',
                  isLoading: _isCreating,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.h),

        // Expenses List
        Card(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expense Records',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16.h),
                expensesAsync.when(
                  data: (expenses) {
                    if (expenses.isEmpty) {
                      return Center(
                        child: Text(t(LAll.all_no_expenses_found, ref)),
                      );                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: expenses.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        return ListTile(
                          leading: Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              color: _getStatusColor(expense.status).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.receipt,
                              color: _getStatusColor(expense.status),
                            ),
                          ),
                          title: Text(
                            '${expense.category}${expense.subcategory != null ? ' - ${expense.subcategory}' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(expense.description ?? 'No description'),
                              Text(
                                '${DateFormat('MMM dd, yyyy').format(expense.expenseDate)} • ${expense.vendor ?? 'No vendor'}',
                                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                              ),
                              if (expense.invoiceNumber != null)
                                Text(
                                  'Invoice: ${expense.invoiceNumber}',
                                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                NumberFormat.currency(symbol: '\$').format(expense.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                  color: _getStatusColor(expense.status),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Chip(
                                label: Text(
                                  expense.status.toUpperCase(),
                                  style: const TextStyle(fontSize: 10),
                                ),
                                backgroundColor: _getStatusColor(expense.status).withValues(alpha: 0.2),
                                side: BorderSide.none,
                                padding: EdgeInsets.zero,
                                labelPadding: EdgeInsets.symmetric(horizontal: 8.w),
                                visualDensity: VisualDensity.compact,
                              ),
                              if (expense.status == 'pending')
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'approve':
                                        _approveExpense(expense);
                                        break;
                                      case 'reject':
                                        _rejectExpense(expense);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'approve',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.blue),
                                          const SizedBox(width: 8),
                                          Text(t(LCrud.approve, ref)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'reject',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.cancel, color: Colors.red),
                                          const SizedBox(width: 8),
                                          Text(t(LCrud.reject, ref)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              if (expense.status == 'approved')
                                IconButton(
                                  icon: const Icon(Icons.payment, color: Colors.blue),
                                  onPressed: () => _markAsPaid(expense),
                                  tooltip: 'Mark as Paid',
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const PageSkeleton(type: 'list'),
                  error: (error, _) => Text(tt(LAll.all_error_x, ref, [error.toString()])),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
