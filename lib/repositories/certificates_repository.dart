import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/certificate_model.dart';

class CertificatesRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final String tableName = 'certificates';

  Future<List<CertificateModel>> getCertificatesByStudent(String studentId) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('student_id', studentId)
        .order('issue_date', ascending: false);
    return (response as List).map((json) => CertificateModel.fromJson(json)).toList();
  }

  Future<List<CertificateModel>> getCertificatesByTenant(String tenantId) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('tenant_id', tenantId)
        .order('issue_date', ascending: false);
    return (response as List).map((json) => CertificateModel.fromJson(json)).toList();
  }

  Future<CertificateModel?> getCertificateByNumber(String number) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('certificate_number', number)
        .maybeSingle();
    return response != null ? CertificateModel.fromJson(response) : null;
  }

  Future<List<CertificateModel>> getCertificatesByType(String type) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('certificate_type', type)
        .order('issue_date', ascending: false);
    return (response as List).map((json) => CertificateModel.fromJson(json)).toList();
  }

  Future<void> create(CertificateModel certificate) async {
    await _client.from(tableName).insert(certificate.toJson());
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _client.from(tableName).update(data).eq('id', id);
  }

  Future<void> revokeCertificate(String id) async {
    await _client.from(tableName).update({'status': 'revoked'}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from(tableName).delete().eq('id', id);
  }
}
