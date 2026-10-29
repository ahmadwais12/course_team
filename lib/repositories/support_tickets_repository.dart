import 'package:course_emis/repositories/base_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupportTicketsRepository extends BaseRepository {
  SupportTicketsRepository() : super('support_tickets');

  Future<List<Map<String, dynamic>>> getAllTickets({
    String? status,
    String? priority,
    String? category,
    String? assignedTo,
  }) async {
    var query = Supabase.instance.client.from('support_tickets').select();

    if (status != null) {
      query = query.eq('status', status);
    }
    if (priority != null) {
      query = query.eq('priority', priority);
    }
    if (category != null) {
      query = query.eq('category', category);
    }
    if (assignedTo != null) {
      query = query.eq('assigned_to', assignedTo);
    }

    final response = await query.order('created_at', ascending: false);
    return response;
  }

  Stream<List<Map<String, dynamic>>> streamTickets({
    String? status,
    String? priority,
  }) async* {
    await for (final data in Supabase.instance.client
        .from('support_tickets')
        .stream(primaryKey: ['id'])) {
      var filtered = data;
      if (status != null) {
        filtered = filtered.where((t) => t['status'] == status).toList();
      }
      if (priority != null) {
        filtered = filtered.where((t) => t['priority'] == priority).toList();
      }
      yield filtered;
    }
  }

  Future<List<Map<String, dynamic>>> getOpenTickets() async {
    final response = await Supabase.instance.client
        .from('support_tickets')
        .select()
        .inFilter('status', ['open', 'in_progress'])
        .order('priority')
        .order('created_at');
    return response;
  }

  Future<List<Map<String, dynamic>>> getMyTickets(String userId) async {
    final response = await Supabase.instance.client
        .from('support_tickets')
        .select()
        .eq('assigned_to', userId)
        .order('created_at', ascending: false);
    return response;
  }

  Future<void> assignTicket(String ticketId, String assigneeId) async {
    await Supabase.instance.client.from('support_tickets').update({
      'assigned_to': assigneeId,
      'status': 'in_progress',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', ticketId);
  }

  Future<void> resolveTicket(String ticketId, String resolutionNotes) async {
    await Supabase.instance.client.from('support_tickets').update({
      'status': 'resolved',
      'resolution_notes': resolutionNotes,
      'resolved_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', ticketId);
  }

  Future<void> closeTicket(String ticketId) async {
    await Supabase.instance.client.from('support_tickets').update({
      'status': 'closed',
      'closed_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', ticketId);
  }

  Future<void> rejectTicket(String ticketId, String reason) async {
    await Supabase.instance.client.from('support_tickets').update({
      'status': 'rejected',
      'resolution_notes': reason,
      'closed_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', ticketId);
  }

  Future<Map<String, dynamic>> getTicketStats() async {
    final response = await Supabase.instance.client
        .from('support_tickets')
        .select('status, priority');

    int open = 0;
    int inProgress = 0;
    int resolved = 0;
    int closed = 0;
    int urgent = 0;
    int high = 0;

    for (final ticket in response) {
      final status = ticket['status'] as String?;
      final priority = ticket['priority'] as String?;

      switch (status) {
        case 'open':
          open++;
          break;
        case 'in_progress':
          inProgress++;
          break;
        case 'resolved':
          resolved++;
          break;
        case 'closed':
          closed++;
          break;
      }

      switch (priority) {
        case 'urgent':
          urgent++;
          break;
        case 'high':
          high++;
          break;
      }
    }

    return {
      'open': open,
      'inProgress': inProgress,
      'resolved': resolved,
      'closed': closed,
      'urgent': urgent,
      'high': high,
      'total': response.length,
    };
  }

  @override
  Future<void> create(Map<String, dynamic> data) async {
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    if (data['status'] == null) {
      data['status'] = 'open';
    }
    if (data['priority'] == null) {
      data['priority'] = 'medium';
    }
    await super.create(data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await super.update(id, data);
  }
}
