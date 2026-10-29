import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/it_support_model.dart';

class ITSupportRepository {
  final _client = Supabase.instance.client;

  Future<List<ITSupportTicket>> getTickets() async {
    final response = await _client.from('it_tickets').select();
    return (response as List).map((e) => ITSupportTicket.fromJson(e)).toList();
  }

  Future<void> addTicket(ITSupportTicket ticket) async {
    await _client.from('it_tickets').insert(ticket.toJson());
  }

  Future<void> updateTicket(ITSupportTicket ticket) async {
    await _client.from('it_tickets').update(ticket.toJson()).eq('id', ticket.id);
  }
}
