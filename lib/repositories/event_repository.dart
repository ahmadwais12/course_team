import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';

class EventRepository {
  final _client = Supabase.instance.client;

  Future<List<Event>> getEvents() async {
    final response = await _client.from('events').select();
    return (response as List).map((e) => Event.fromJson(e)).toList();
  }

  Future<void> addEvent(Event event) async {
    await _client.from('events').insert(event.toJson());
  }

  Future<void> updateEvent(Event event) async {
    await _client.from('events').update(event.toJson()).eq('id', event.id);
  }
}
