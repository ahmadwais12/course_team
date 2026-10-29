import 'package:course_emis/models/program.dart';
import 'package:course_emis/services/supabase_service.dart';

class ProgramRepository {
  final SupabaseService _service = SupabaseService();
  
  Future<List<Program>> getAll() async {
    final data = await _service.getPrograms();
    return data.map((e) => Program.fromJson(e)).toList();
  }
  
  Future<void> create(Program program) async {
    await _service.createProgram(program.toJson());
  }
  
  Future<void> update(Program program) async {
    await _service.updateProgram(program.id, program.toJson());
  }
  
  Future<void> delete(String id) async {
    await _service.deleteProgram(id);
  }
}
