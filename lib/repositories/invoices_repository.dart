import 'package:course_emis/repositories/base_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvoicesRepository extends BaseRepository {
  InvoicesRepository() : super('invoices');

  Future<List<Map<String, dynamic>>> getAllInvoices({
    String? studentId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = Supabase.instance.client.from('invoices').select();

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (startDate != null) {
      query = query.gte('issue_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('issue_date', endDate.toIso8601String());
    }

    final response = await query.order('due_date', ascending: false);
    return response;
  }

  Stream<List<Map<String, dynamic>>> streamInvoices({
    String? studentId,
    String? status,
  }) async* {
    await for (final data in Supabase.instance.client
        .from('invoices')
        .stream(primaryKey: ['id'])) {
      // Filter in memory since stream builder has limited filter support
      var filtered = data;
      if (studentId != null) {
        filtered = filtered.where((i) => i['student_id'] == studentId).toList();
      }
      if (status != null) {
        filtered = filtered.where((i) => i['status'] == status).toList();
      }
      yield filtered;
    }
  }

  Future<List<Map<String, dynamic>>> getOverdueInvoices() async {
    final response = await Supabase.instance.client
        .from('invoices')
        .select()
        .eq('status', 'Pending')
        .lt('due_date', DateTime.now().toIso8601String())
        .order('due_date');
    return response;
  }

  Future<Map<String, dynamic>> getInvoiceStats() async {
    final response = await Supabase.instance.client
        .from('invoices')
        .select('status, amount');

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
  }

  Future<void> markAsPaid(
    String invoiceId, {
    String? paymentMethod,
    String? transactionId,
  }) async {
    await Supabase.instance.client.from('invoices').update({
      'status': 'Paid',
      'paid_date': DateTime.now().toIso8601String(),
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', invoiceId);
  }

  Future<void> cancelInvoice(String invoiceId) async {
    await Supabase.instance.client.from('invoices').update({
      'status': 'Cancelled',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', invoiceId);
  }

  @override
  Future<void> create(Map<String, dynamic> data) async {
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    if (data['status'] == null) {
      data['status'] = 'Pending';
    }
    await super.create(data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await super.update(id, data);
  }
}
