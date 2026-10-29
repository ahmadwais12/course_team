import 'package:course_emis/repositories/base_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpensesRepository extends BaseRepository {
  ExpensesRepository() : super('expenses');

  Future<List<Map<String, dynamic>>> getAllExpenses({
    String? category,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? vendor,
  }) async {
    var query = Supabase.instance.client.from('expenses').select();

    if (category != null) {
      query = query.eq('category', category);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (startDate != null) {
      query = query.gte('expense_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('expense_date', endDate.toIso8601String());
    }
    if (vendor != null) {
      query = query.ilike('vendor', '%$vendor%');
    }

    final response = await query.order('expense_date', ascending: false);
    return response;
  }

  Stream<List<Map<String, dynamic>>> streamExpenses({
    String? category,
    String? status,
  }) async* {
    await for (final data in Supabase.instance.client
        .from('expenses')
        .stream(primaryKey: ['id'])) {
      var filtered = data;
      if (category != null) {
        filtered = filtered.where((e) => e['category'] == category).toList();
      }
      if (status != null) {
        filtered = filtered.where((e) => e['status'] == status).toList();
      }
      yield filtered;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingExpenses() async {
    final response = await Supabase.instance.client
        .from('expenses')
        .select()
        .eq('status', 'pending')
        .order('expense_date', ascending: false);
    return response;
  }

  Future<List<Map<String, dynamic>>> getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await Supabase.instance.client
        .from('expenses')
        .select()
        .gte('expense_date', startDate.toIso8601String())
        .lte('expense_date', endDate.toIso8601String())
        .order('expense_date', ascending: false);
    return response;
  }

  Future<Map<String, dynamic>> getExpenseStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = Supabase.instance.client.from('expenses').select('status, amount, category');

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
    double totalRejected = 0;
    int countPending = 0;
    int countApproved = 0;
    int countPaid = 0;
    int countRejected = 0;

    // Category breakdown
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
        case 'rejected':
          totalRejected += amount;
          countRejected++;
          break;
      }

      // Category totals
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
    }

    return {
      'totalPending': totalPending,
      'totalApproved': totalApproved,
      'totalPaid': totalPaid,
      'totalRejected': totalRejected,
      'countPending': countPending,
      'countApproved': countApproved,
      'countPaid': countPaid,
      'countRejected': countRejected,
      'totalAmount': totalPending + totalApproved + totalPaid,
      'categoryTotals': categoryTotals,
    };
  }

  Future<void> approveExpense(String expenseId, String approverId) async {
    await Supabase.instance.client.from('expenses').update({
      'status': 'approved',
      'approved_by': approverId,
      'approved_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', expenseId);
  }

  Future<void> rejectExpense(String expenseId, String approverId) async {
    await Supabase.instance.client.from('expenses').update({
      'status': 'rejected',
      'approved_by': approverId,
      'approved_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', expenseId);
  }

  Future<void> markAsPaid(
    String expenseId, {
    String? paymentMethod,
  }) async {
    await Supabase.instance.client.from('expenses').update({
      'status': 'paid',
      'payment_method': paymentMethod,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', expenseId);
  }

  @override
  Future<void> create(Map<String, dynamic> data) async {
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    if (data['status'] == null) {
      data['status'] = 'pending';
    }
    await super.create(data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await super.update(id, data);
  }
}
