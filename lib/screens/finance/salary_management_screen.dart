import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/salary_model.dart';
import '../../widgets/base_panel_layout.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

final salariesProvider =
    StreamProvider.family<List<Salary>, Map<String, dynamic>?>((ref, filters) {
  final supabase = Supabase.instance.client;
  var query = supabase.from('salaries').stream(primaryKey: ['id']);

  if (filters != null) {
    final month = filters['month'] as int?;
    final year = filters['year'] as int?;
    final status = filters['status'] as String?;

    return query.map((data) {
      var filtered = data;
      if (month != null) {
        filtered = filtered.where((s) => s['month'] == month).toList();
      }
      if (year != null) {
        filtered = filtered.where((s) => s['year'] == year).toList();
      }
      if (status != null) {
        filtered = filtered.where((s) => s['status'] == status).toList();
      }
      return filtered.map((json) => Salary.fromJson(json)).toList();
    });
  }

  return query
      .map((data) => data.map((json) => Salary.fromJson(json)).toList());
});

final salaryStatsProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, int>>(
        (ref, params) async {
  final supabase = Supabase.instance.client;
  final month = params['month'] ?? DateTime.now().month;
  final year = params['year'] ?? DateTime.now().year;

  final response = await supabase
      .from('salaries')
      .select('status, net_salary, gross_salary')
      .eq('month', month)
      .eq('year', year);

  double totalPending = 0;
  double totalProcessed = 0;
  double totalPaid = 0;
  int countPending = 0;
  int countProcessed = 0;
  int countPaid = 0;

  for (final salary in response) {
    final status = salary['status'] as String?;
    final netSalary = (salary['net_salary'] as num?)?.toDouble() ?? 0;

    switch (status) {
      case 'pending':
        totalPending += netSalary;
        countPending++;
        break;
      case 'processed':
        totalProcessed += netSalary;
        countProcessed++;
        break;
      case 'paid':
        totalPaid += netSalary;
        countPaid++;
        break;
    }
  }

  return {
    'totalPending': totalPending,
    'totalProcessed': totalProcessed,
    'totalPaid': totalPaid,
    'countPending': countPending,
    'countProcessed': countProcessed,
    'countPaid': countPaid,
    'totalEmployees': response.length,
  };
});

class SalaryManagementScreen extends ConsumerStatefulWidget {
  const SalaryManagementScreen({super.key});

  @override
  ConsumerState<SalaryManagementScreen> createState() =>
      _SalaryManagementScreenState();
}

class _SalaryManagementScreenState
    extends ConsumerState<SalaryManagementScreen> {
  final _basicSalaryController = TextEditingController();
  final _bonusController = TextEditingController();
  final _overtimeHoursController = TextEditingController();
  final _overtimePayController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedEmployeeId;
  String? _selectedEmployeeType;
  String? _selectedStatus;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isCreating = false;

  final List<String> _employeeTypes = ['teacher', 'staff'];
  final List<String> _statuses = ['pending', 'processed', 'paid', 'cancelled'];
  final List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void dispose() {
    _basicSalaryController.dispose();
    _bonusController.dispose();
    _overtimeHoursController.dispose();
    _overtimePayController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _createSalary() async {
    if (_selectedEmployeeId == null || _basicSalaryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(t(LAll.all_please_select_employee_and_enter_basic_salary, ref))),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final supabase = Supabase.instance.client;

      final basicSalary = double.tryParse(_basicSalaryController.text) ?? 0;
      final bonus = double.tryParse(_bonusController.text) ?? 0;
      final overtimeHours = int.tryParse(_overtimeHoursController.text) ?? 0;
      final overtimePay = double.tryParse(_overtimePayController.text) ?? 0;
      final grossSalary = basicSalary + bonus + overtimePay;

      final salaryData = {
        'employee_id': _selectedEmployeeId,
        'employee_type': _selectedEmployeeType ?? 'staff',
        'month': _selectedMonth,
        'year': _selectedYear,
        'basic_salary': basicSalary,
        'bonus': bonus,
        'overtime_hours': overtimeHours,
        'overtime_pay': overtimePay,
        'gross_salary': grossSalary,
        'net_salary': grossSalary, // Will be calculated with deductions
        'status': _selectedStatus ?? 'pending',
        'notes': _notesController.text.trim(),
        'created_by': supabase.auth.currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('salaries').insert(salaryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaff.salaryCreated, ref))),
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
    _basicSalaryController.clear();
    _bonusController.clear();
    _overtimeHoursController.clear();
    _overtimePayController.clear();
    _notesController.clear();
    setState(() {
      _selectedEmployeeId = null;
      _selectedEmployeeType = null;
      _selectedStatus = null;
    });
  }

  Future<void> _processSalary(Salary salary) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('salaries').update({
        'status': 'processed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', salary.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaff.salaryProcessed, ref))),
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

  Future<void> _markAsPaid(Salary salary) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('salaries').update({
        'status': 'paid',
        'payment_date': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', salary.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaff.salaryPaid, ref))),
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

  Future<void> _cancelSalary(Salary salary) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('salaries').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', salary.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaff.salaryCancelled, ref))),
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
      case 'processed':
        return Colors.blue;
      case 'paid':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 8.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
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
      'month': _selectedMonth,
      'year': _selectedYear,
    };
    final salariesAsync = ref.watch(salariesProvider(filters));
    final statsAsync = ref.watch(
        salaryStatsProvider({'month': _selectedMonth, 'year': _selectedYear}));

    return BasePanelLayout(
      title: 'Salary Management',
      children: [
        // Stats Cards
        statsAsync.when(
          data: (stats) {
            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Pending',
                    '${stats['countPending']} (${NumberFormat.currency(symbol: '\$').format(stats['totalPending'])})',
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildStatCard(
                    'Processed',
                    '${stats['countProcessed']} (${NumberFormat.currency(symbol: '\$').format(stats['totalProcessed'])})',
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildStatCard(
                    'Paid',
                    '${stats['countPaid']} (${NumberFormat.currency(symbol: '\$').format(stats['totalPaid'])})',
                    Colors.blue,
                  ),
                ),
              ],
            );
          },
          loading: () => const PageSkeleton(type: 'list'),
          error: (_, __) => const SizedBox.shrink(),
        ),
        SizedBox(height: 24.h),

        // Month/Year Filter
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(12, (index) => index + 1).map((month) {
                      return DropdownMenuItem(
                        value: month,
                        child: Text(_monthNames[month - 1]),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedMonth = value);
                      }
                    },
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                            5, (index) => DateTime.now().year - 2 + index)
                        .map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedYear = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.h),

        // Create Salary Section
        Card(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Salary Record',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedEmployeeType,
                        decoration: const InputDecoration(
                          labelText: 'Employee Type',
                          border: OutlineInputBorder(),
                        ),
                        items: _employeeTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedEmployeeType = value);
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
                            child: Text(status.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedStatus = value);
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
                        controller: _basicSalaryController,
                        label: 'Basic Salary',
                        keyboardType: TextInputType.number,
                        hint: '0.00',
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: CustomTextField(
                        controller: _bonusController,
                        label: 'Bonus',
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
                      child: CustomTextField(
                        controller: _overtimeHoursController,
                        label: 'Overtime Hours',
                        keyboardType: TextInputType.number,
                        hint: '0',
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: CustomTextField(
                        controller: _overtimePayController,
                        label: 'Overtime Pay',
                        keyboardType: TextInputType.number,
                        hint: '0.00',
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
                  onPressed: _isCreating ? () {} : _createSalary,
                  text: _isCreating ? 'Creating...' : 'Create Salary Record',
                  isLoading: _isCreating,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.h),

        // Salaries List
        Card(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salary Records - ${_monthNames[_selectedMonth - 1]} $_selectedYear',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16.h),
                salariesAsync.when(
                  data: (salaries) {
                    if (salaries.isEmpty) {
                      return const Center(
                        child: Text(
                            'No salary records found for selected month/year'),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: salaries.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final salary = salaries[index];
                        return ListTile(
                          leading: Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              color: _getStatusColor(salary.status ?? 'pending')
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.payments,
                              color:
                                  _getStatusColor(salary.status ?? 'pending'),
                            ),
                          ),
                          title: Text(
                            '${salary.employeeType?.toUpperCase() ?? 'STAFF'} - ${salary.monthName} ${salary.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Basic: ${NumberFormat.currency(symbol: '\$').format(salary.basicSalary)} | '
                                'Gross: ${NumberFormat.currency(symbol: '\$').format(salary.grossSalary ?? salary.calculatedGross)}',
                              ),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(
                                      salary.status ?? 'pending',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor: _getStatusColor(
                                            salary.status ?? 'pending')
                                        .withValues(alpha: 0.2),
                                    side: BorderSide.none,
                                    padding: EdgeInsets.zero,
                                    labelPadding:
                                        EdgeInsets.symmetric(horizontal: 8.w),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Net: ${NumberFormat.currency(symbol: '\$').format(salary.netSalary ?? salary.calculatedNet)}',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'process':
                                  _processSalary(salary);
                                  break;
                                case 'pay':
                                  _markAsPaid(salary);
                                  break;
                                case 'cancel':
                                  _cancelSalary(salary);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              if (salary.isPending)
                                PopupMenuItem(
                                  value: 'process',
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text(t(LAll.all_process, ref)),
                                    ],
                                  ),
                                ),
                              if (salary.isPending || salary.isProcessed)
                                PopupMenuItem(
                                  value: 'pay',
                                  child: Row(
                                    children: [
                                      Icon(Icons.payment, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text(t(LCrud.markAsPaid, ref)),
                                    ],
                                  ),
                                ),
                              if (!salary.isCancelled)
                                PopupMenuItem(
                                  value: 'cancel',
                                  child: Row(
                                    children: [
                                      Icon(Icons.cancel, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text(t(L.cancel, ref)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const PageSkeleton(type: 'list'),
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
