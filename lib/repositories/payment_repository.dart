import 'package:course_emis/models/payment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Payment>> getAll() async {
    final data = await _supabase.from('payments').select().order('created_at', ascending: false);
    return (data as List).map((json) => Payment.fromJson(json)).toList();
  }
  
  Future<void> create(Payment payment) async {
    await _supabase.from('payments').insert(payment.toJson());
  }
  
  Future<void> update(Payment payment) async {
    await _supabase.from('payments').update(payment.toJson()).eq('id', payment.id);
  }
  
  Future<void> delete(String id) async {
    await _supabase.from('payments').delete().eq('id', id);
  }

  Stream<List<Payment>> watchAll() {
    return _supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Payment.fromJson(json)).toList());
  }
}
