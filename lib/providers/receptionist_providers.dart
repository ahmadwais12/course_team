import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/repositories/leads_repository.dart';
import 'package:course_emis/repositories/events_repository.dart';

// Leads Provider
final leadsRepositoryProvider = Provider<LeadsRepository>((ref) {
  return LeadsRepository();
});

final leadsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(leadsRepositoryProvider);
  return repository.streamLeads();
});

final leadsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(leadsRepositoryProvider);
  return await repository.getAllLeads();
});

// Events Provider
final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository();
});

final eventsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(eventsRepositoryProvider);
  return repository.streamEvents();
});

final eventsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(eventsRepositoryProvider);
  return await repository.getAllEvents();
});
