import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hr_model.dart';

class StaffRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final String tableName = 'staff';

  Future<List<Staff>> getStaffByTenant(String tenantId) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false);
    return (response as List).map((json) => Staff.fromJson(json)).toList();
  }

  Future<List<Staff>> getStaffByStatus(String status) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('status', status)
        .order('full_name');
    return (response as List).map((json) => Staff.fromJson(json)).toList();
  }

  Future<List<Staff>> getStaffByRole(String role) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('role', role)
        .order('full_name');
    return (response as List).map((json) => Staff.fromJson(json)).toList();
  }

  Future<Staff?> getStaffByEmployeeCode(String code) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('employee_code', code)
        .maybeSingle();
    return response != null ? Staff.fromJson(response) : null;
  }

  Future<List<Staff>> searchStaff(String query) async {
    final response = await _client
        .from(tableName)
        .select()
        .or('full_name.ilike.%$query%,email.ilike.%$query%,employee_code.ilike.%$query%')
        .order('full_name');
    return (response as List).map((json) => Staff.fromJson(json)).toList();
  }

  Future<void> create(Staff staff) async {
    await _client.from(tableName).insert(staff.toJson());
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _client.from(tableName).update(data).eq('id', id);
  }

  Future<void> updateStatus(String id, String status) async {
    await _client.from(tableName).update({'status': status}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from(tableName).delete().eq('id', id);
  }

  Future<List<Staff>> getStaffOnLeave() async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('status', 'on_leave')
        .order('full_name');
    return (response as List).map((json) => Staff.fromJson(json)).toList();
  }

  Future<List<Staff>> getAll() async {
    final response = await _client.from(tableName).select().order('created_at');
    return (response as List).map((json) => Staff.fromJson(json)).toList();
  }
}
