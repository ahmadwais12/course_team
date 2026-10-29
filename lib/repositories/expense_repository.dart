import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final String tableName = 'expenses';

  Future<List<ExpenseModel>> getExpensesByTenant(String tenantId) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('tenant_id', tenantId)
        .order('expense_date', ascending: false);
    return (response as List)
        .map((json) => ExpenseModel.fromJson(json))
        .toList();
  }

  Future<List<ExpenseModel>> getExpensesByDateRange(
      DateTime start, DateTime end) async {
    final response = await _client
        .from(tableName)
        .select()
        .gte('expense_date', start.toIso8601String())
        .lte('expense_date', end.toIso8601String())
        .order('expense_date', ascending: false);
    return (response as List)
        .map((json) => ExpenseModel.fromJson(json))
        .toList();
  }

  Future<List<ExpenseModel>> getExpensesByCategory(String category) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('category', category)
        .order('expense_date', ascending: false);
    return (response as List)
        .map((json) => ExpenseModel.fromJson(json))
        .toList();
  }

  Future<List<ExpenseModel>> getPendingExpenses() async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (response as List)
        .map((json) => ExpenseModel.fromJson(json))
        .toList();
  }

  Future<Map<String, double>> getExpenseSummaryByCategory(
      DateTime start, DateTime end) async {
    final response = await _client
        .from(tableName)
        .select('category, amount')
        .gte('expense_date', start.toIso8601String())
        .lte('expense_date', end.toIso8601String())
        .eq('status', 'approved');

    Map<String, double> summary = {};
    for (var item in response) {
      String category = item['category'] ?? 'Other';
      double amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
      summary[category] = (summary[category] ?? 0.0) + amount;
    }
    return summary;
  }

  Future<void> create(ExpenseModel expense) async {
    await _client.from(tableName).insert(expense.toJson());
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _client.from(tableName).update(data).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from(tableName).delete().eq('id', id);
  }

  Future<void> approveExpense(String id, String approvedBy) async {
    await _client.from(tableName).update({
      'status': 'approved',
      'approved_by': approvedBy,
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> rejectExpense(String id) async {
    await _client.from(tableName).update({
      'status': 'rejected',
    }).eq('id', id);
  }
}
