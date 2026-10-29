import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/models/teacher.dart';

class PayrollRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Payroll>> getAll() async {
    try {
      final response = await supabase
          .from('payroll')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => Payroll.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch payroll records: $e');
    }
  }

  Future<Payroll?> getById(String id) async {
    try {
      final response = await supabase
          .from('payroll')
          .select()
          .eq('id', id)
          .single();
      return Payroll.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      return null;
    }
  }

  Future<List<Payroll>> getByTeacher(String teacherId) async {
    try {
      final response = await supabase
          .from('payroll')
          .select()
          .eq('teacher_id', teacherId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => Payroll.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch payroll for teacher: $e');
    }
  }

  Future<void> create(Payroll payroll) async {
    try {
      await supabase.from('payroll').insert(payroll.toJson());
    } catch (e) {
      throw Exception('Failed to create payroll record: $e');
    }
  }

  Future<void> update(Payroll payroll) async {
    try {
      await supabase.from('payroll').update(payroll.toJson()).eq('id', payroll.id);
    } catch (e) {
      throw Exception('Failed to update payroll record: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await supabase.from('payroll').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete payroll record: $e');
    }
  }

  Stream<List<Payroll>> streamAll() {
    return supabase
        .from('payroll')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) =>
            data.map((json) => Payroll.fromJson(json)).toList());
  }
}
