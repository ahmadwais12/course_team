import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/finance_model.dart';

class FinanceRepository {
  final _client = Supabase.instance.client;

  Future<List<Finance>> getFinanceRecords() async {
    final payments = await _client.from('payments').select('amount, payment_date, status, payment_type, notes');
    final expenses = await _client.from('expenses').select('amount, expense_date, description, category, status');

    final transactions = <Transaction>[];
    for (final p in payments) {
      transactions.add(Transaction(
        id: p['id']?.toString() ?? '',
        type: p['payment_type'] as String? ?? 'payment',
        amount: ((p['amount'] as num?) ?? 0).toDouble(),
        description: p['notes'] as String? ?? '',
        date: DateTime.tryParse(p['payment_date'] as String? ?? '') ?? DateTime.now(),
        category: 'payment',
        status: p['status'] as String? ?? 'completed',
      ));
    }
    for (final e in expenses) {
      transactions.add(Transaction(
        id: e['id']?.toString() ?? '',
        type: 'expense',
        amount: -((e['amount'] as num?) ?? 0).toDouble(),
        description: e['description'] as String? ?? '',
        date: DateTime.tryParse(e['expense_date'] as String? ?? '') ?? DateTime.now(),
        category: e['category'] as String? ?? 'other',
        status: e['status'] as String? ?? 'pending',
      ));
    }

    transactions.sort((a, b) => b.date.compareTo(a.date));
    final totalIncome = transactions.where((t) => t.amount > 0).fold<double>(0, (s, t) => s + t.amount);
    final totalExpense = transactions.where((t) => t.amount < 0).fold<double>(0, (s, t) => s + t.amount.abs());

    return [Finance(
      transactions: transactions,
      fees: [],
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: totalIncome - totalExpense,
    )];
  }

  Future<void> addFinanceRecord(Finance finance) async {
    for (final transaction in finance.transactions) {
      if (transaction.type == 'expense') {
        await _client.from('expenses').insert({
          'amount': transaction.amount.abs(),
          'expense_date': transaction.date.toIso8601String(),
          'description': transaction.description,
          'category': transaction.category,
          'notes': transaction.notes,
        });
      } else {
        await _client.from('payments').insert({
          'amount': transaction.amount,
          'payment_date': transaction.date.toIso8601String(),
          'payment_type': transaction.category,
          'notes': transaction.notes,
          'status': transaction.status,
        });
      }
    }
  }

  Future<void> updateFinanceRecord(Finance finance) async {
    for (final transaction in finance.transactions) {
      if (transaction.type == 'expense') {
        await _client.from('expenses').update({
          'amount': transaction.amount.abs(),
          'description': transaction.description,
          'category': transaction.category,
        }).eq('id', transaction.id);
      } else {
        await _client.from('payments').update({
          'amount': transaction.amount,
          'payment_type': transaction.category,
          'notes': transaction.notes,
        }).eq('id', transaction.id);
      }
    }
  }
}
