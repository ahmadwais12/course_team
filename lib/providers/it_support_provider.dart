import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/it_support_model.dart';
import '../repositories/it_support_repository.dart';

final itSupportRepositoryProvider = Provider((ref) => ITSupportRepository());

final itTicketListProvider = StateNotifierProvider<ITSupportNotifier, List<ITSupportTicket>>((ref) {
  final repository = ref.watch(itSupportRepositoryProvider);
  return ITSupportNotifier(repository);
});

class ITSupportNotifier extends StateNotifier<List<ITSupportTicket>> {
  final ITSupportRepository _repository;

  ITSupportNotifier(this._repository) : super([]) {
    loadTickets();
  }

  Future<void> loadTickets() async {
    try {
      state = await _repository.getTickets();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> addTicket(ITSupportTicket ticket) async {
    await _repository.addTicket(ticket);
    await loadTickets();
  }

  Future<void> updateTicket(ITSupportTicket ticket) async {
    await _repository.updateTicket(ticket);
    await loadTickets();
  }
}
