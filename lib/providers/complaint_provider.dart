import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/complaint_model.dart';
import '../repositories/complaint_repository.dart';

final complaintRepositoryProvider = Provider((ref) => ComplaintRepository());

final complaintListProvider = StateNotifierProvider<ComplaintNotifier, List<Complaint>>((ref) {
  final repository = ref.watch(complaintRepositoryProvider);
  return ComplaintNotifier(repository);
});

class ComplaintNotifier extends StateNotifier<List<Complaint>> {
  final ComplaintRepository _repository;

  ComplaintNotifier(this._repository) : super([]) {
    loadComplaints();
  }

  Future<void> loadComplaints() async {
    try {
      state = await _repository.getComplaints();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> addComplaint(Complaint complaint) async {
    await _repository.addComplaint(complaint);
    await loadComplaints();
  }

  Future<void> updateComplaint(Complaint complaint) async {
    await _repository.updateComplaint(complaint);
    await loadComplaints();
  }
}
