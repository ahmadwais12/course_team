import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/library_model.dart';

class LibraryRepository {
  final _client = Supabase.instance.client;

  Future<List<LibraryRecord>> getLibraryRecords() async {
    final response = await _client.from('library').select();
    return (response as List).map((e) => LibraryRecord.fromJson(e)).toList();
  }

  Future<void> addLibraryRecord(LibraryRecord record) async {
    await _client.from('library').insert(record.toJson());
  }

  Future<void> updateLibraryRecord(LibraryRecord record) async {
    // Update logic
  }
}
