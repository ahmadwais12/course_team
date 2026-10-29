import 'package:supabase_flutter/supabase_flutter.dart';

class EventRegistration {
  final String id;
  final String eventId;
  final String userId;
  final DateTime registrationDate;
  final String status;
  final String? notes;

  EventRegistration({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.registrationDate,
    this.status = 'registered',
    this.notes,
  });

  factory EventRegistration.fromJson(Map<String, dynamic> json) {
    return EventRegistration(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      registrationDate: DateTime.parse(json['registration_date'] as String),
      status: json['status'] as String? ?? 'registered',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'registration_date': registrationDate.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }
}

class EventRegistrationsRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final String tableName = 'event_registrations';

  Future<List<EventRegistration>> getRegistrationsByEvent(String eventId) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('event_id', eventId)
        .order('registration_date', ascending: false);
    return (response as List).map((json) => EventRegistration.fromJson(json)).toList();
  }

  Future<List<EventRegistration>> getRegistrationsByUser(String userId) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('user_id', userId)
        .order('registration_date', ascending: false);
    return (response as List).map((json) => EventRegistration.fromJson(json)).toList();
  }

  Future<EventRegistration?> getRegistration(String eventId, String userId) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('event_id', eventId)
        .eq('user_id', userId)
        .maybeSingle();
    return response != null ? EventRegistration.fromJson(response) : null;
  }

  Future<void> register(EventRegistration registration) async {
    await _client.from(tableName).insert(registration.toJson());
  }

  Future<void> updateStatus(String id, String status) async {
    await _client.from(tableName).update({'status': status}).eq('id', id);
  }

  Future<void> cancelRegistration(String id) async {
    await _client.from(tableName).update({'status': 'cancelled'}).eq('id', id);
  }

  Future<void> markAttended(String id) async {
    await _client.from(tableName).update({'status': 'attended'}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from(tableName).delete().eq('id', id);
  }
}
