import 'package:course_emis/repositories/base_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SalariesRepository extends BaseRepository {
  SalariesRepository() : super('salaries');

  Future<List<Map<String, dynamic>>> getAllSalaries({
    String? employeeId,
    int? month,
    int? year,
    String? status,
  }) async {
    var query = Supabase.instance.client.from('salaries').select();

    if (employeeId != null) {
      query = query.eq('employee_id', employeeId);
    }
    if (month != null) {
      query = query.eq('month', month);
    }
    if (year != null) {
      query = query.eq('year', year);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('year', ascending: false)
        .order('month', ascending: false);
    return response;
  }

  Stream<List<Map<String, dynamic>>> streamSalaries({
    String? employeeId,
    String? status,
  }) async* {
    await for (final data in Supabase.instance.client
        .from('salaries')
        .stream(primaryKey: ['id'])) {
      var filtered = data;
      if (employeeId != null) {
        filtered = filtered.where((s) => s['employee_id'] == employeeId).toList();
      }
      if (status != null) {
        filtered = filtered.where((s) => s['status'] == status).toList();
      }
      yield filtered;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingSalaries() async {
    final response = await Supabase.instance.client
        .from('salaries')
        .select()
        .eq('status', 'pending')
        .order('year', ascending: false)
        .order('month', ascending: false);
    return response;
  }

  Future<Map<String, dynamic>?> getEmployeeSalaryForMonth(
    String employeeId,
    int month,
    int year,
  ) async {
    final response = await Supabase.instance.client
        .from('salaries')
        .select()
        .eq('employee_id', employeeId)
        .eq('month', month)
        .eq('year', year)
        .maybeSingle();
    return response;
  }

  Future<void> processSalary(String salaryId) async {
    await Supabase.instance.client.from('salaries').update({
      'status': 'processed',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', salaryId);
  }

  Future<void> markAsPaid(
    String salaryId, {
    String? paymentMethod,
    DateTime? paymentDate,
    String? payslipUrl,
  }) async {
    await Supabase.instance.client.from('salaries').update({
      'status': 'paid',
      'payment_date': (paymentDate ?? DateTime.now()).toIso8601String(),
      'payment_method': paymentMethod,
      'payslip_url': payslipUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', salaryId);
  }

  Future<void> cancelSalary(String salaryId) async {
    await Supabase.instance.client.from('salaries').update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', salaryId);
  }

  Future<Map<String, dynamic>> getSalaryStats(int month, int year) async {
    final response = await Supabase.instance.client
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
  }

  @override
  Future<void> create(Map<String, dynamic> data) async {
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    if (data['status'] == null) {
      data['status'] = 'pending';
    }
    // Calculate gross and net if not provided
    if (data['gross_salary'] == null && data['basic_salary'] != null) {
      double basic = (data['basic_salary'] as num).toDouble();
      double bonus = (data['bonus'] as num?)?.toDouble() ?? 0;
      double overtimePay = (data['overtime_pay'] as num?)?.toDouble() ?? 0;
      
      double totalAllowances = 0;
      if (data['allowances'] != null) {
        (data['allowances'] as Map<String, dynamic>).forEach((key, value) {
          totalAllowances += (value as num).toDouble();
        });
      }
      
      data['gross_salary'] = basic + totalAllowances + bonus + overtimePay;
    }
    
    if (data['net_salary'] == null && data['gross_salary'] != null) {
      double gross = (data['gross_salary'] as num).toDouble();
      
      double totalDeductions = 0;
      if (data['deductions'] != null) {
        (data['deductions'] as Map<String, dynamic>).forEach((key, value) {
          totalDeductions += (value as num).toDouble();
        });
      }
      
      data['net_salary'] = gross - totalDeductions;
    }
    
    await super.create(data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await super.update(id, data);
  }
}
