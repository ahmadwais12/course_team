import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/complaint_model.dart';

class ComplaintRepository {
  final _client = Supabase.instance.client;

  Future<List<Complaint>> getComplaints() async {
    final response = await _client.from('complaints').select();
    return (response as List).map((e) => Complaint.fromJson(e)).toList();
  }

  Future<void> addComplaint(Complaint complaint) async {
    await _client.from('complaints').insert(complaint.toJson());
  }

  Future<void> updateComplaint(Complaint complaint) async {
    await _client.from('complaints').update(complaint.toJson()).eq('id', complaint.id);
  }
}
