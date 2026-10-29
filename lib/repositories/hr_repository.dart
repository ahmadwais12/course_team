import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hr_model.dart';

class HRRepository {
  final _client = Supabase.instance.client;

  Future<List<HRRecord>> getHRRecords() async {
    final response = await _client.from('hr_records').select();
    return (response as List).map((e) => HRRecord.fromJson(e)).toList();
  }

  Future<void> addHRRecord(HRRecord record) async {
    await _client.from('hr_records').insert(record.toJson());
  }

  Future<void> updateHRRecord(HRRecord record) async {
    // Update logic
  }
}
