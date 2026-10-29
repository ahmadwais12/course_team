import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/parent_model.dart';

class ParentRepository {
  final _client = Supabase.instance.client;

  Future<List<Parent>> getParents() async {
    final response = await _client.from('parents').select();
    return (response as List).map((e) => Parent.fromJson(e)).toList();
  }

  Future<void> addParent(Parent parent) async {
    await _client.from('parents').insert(parent.toJson());
  }

  Future<void> updateParent(Parent parent) async {
    await _client.from('parents').update(parent.toJson()).eq('id', parent.id);
  }
}
