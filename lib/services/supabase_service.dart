import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final client = Supabase.instance.client;
  
  User? get currentUser => client.auth.currentUser;
  
  Future<AuthResponse> signIn(String email, String password) =>
    client.auth.signInWithPassword(email: email, password: password);
  
  Future<void> signOut() => client.auth.signOut();
  
  Future<List<Map<String, dynamic>>> getPrograms() =>
    client.from('programs').select();
  
  Future<void> createProgram(Map<String, dynamic> data) =>
    client.from('programs').insert(data);
  
  Future<void> updateProgram(String id, Map<String, dynamic> data) =>
    client.from('programs').update(data).eq('id', id);
  
  Future<void> deleteProgram(String id) =>
    client.from('programs').delete().eq('id', id);
  
  Future<List<Map<String, dynamic>>> getDepartments() =>
    client.from('departments').select();
  
  Future<void> createDepartment(Map<String, dynamic> data) =>
    client.from('departments').insert(data);
  
  Future<void> updateDepartment(String id, Map<String, dynamic> data) =>
    client.from('departments').update(data).eq('id', id);
  
  Future<void> deleteDepartment(String id) =>
    client.from('departments').delete().eq('id', id);
  
  Future<List<Map<String, dynamic>>> getClasses() =>
    client.from('classes').select();
  
  Future<void> createClass(Map<String, dynamic> data) =>
    client.from('classes').insert(data);
  
  Future<void> updateClass(String id, Map<String, dynamic> data) =>
    client.from('classes').update(data).eq('id', id);
  
  Future<void> deleteClass(String id) =>
    client.from('classes').delete().eq('id', id);
  
  Future<List<Map<String, dynamic>>> getStudents() =>
    client.from('students').select();
  
  Future<void> createStudent(Map<String, dynamic> data) =>
    client.from('students').insert(data);
  
  Future<void> updateStudent(String id, Map<String, dynamic> data) =>
    client.from('students').update(data).eq('id', id);
  
  Future<void> deleteStudent(String id) =>
    client.from('students').delete().eq('id', id);
}
