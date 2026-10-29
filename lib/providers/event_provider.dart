import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../repositories/event_repository.dart';

final eventRepositoryProvider = Provider((ref) => EventRepository());

final eventListProvider = StateNotifierProvider<EventNotifier, List<Event>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return EventNotifier(repository);
});

class EventNotifier extends StateNotifier<List<Event>> {
  final EventRepository _repository;

  EventNotifier(this._repository) : super([]) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    try {
      state = await _repository.getEvents();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> addEvent(Event event) async {
    await _repository.addEvent(event);
    await loadEvents();
  }

  Future<void> updateEvent(Event event) async {
    await _repository.updateEvent(event);
    await loadEvents();
  }
}
