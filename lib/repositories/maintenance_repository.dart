import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maintenance_model.dart';

class MaintenanceRepository {
  final _client = Supabase.instance.client;

  Future<List<MaintenanceTask>> getTasks() async {
    final response = await _client.from('maintenance_tasks').select();
    return (response as List).map((e) => MaintenanceTask.fromJson(e)).toList();
  }

  Future<void> addTask(MaintenanceTask task) async {
    await _client.from('maintenance_tasks').insert(task.toJson());
  }

  Future<void> updateTask(MaintenanceTask task) async {
    await _client.from('maintenance_tasks').update(task.toJson()).eq('id', task.id);
  }
}
