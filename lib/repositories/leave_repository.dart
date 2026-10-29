import 'package:course_emis/repositories/base_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaveRepository extends BaseRepository {
  LeaveRepository() : super('leave_applications');

  Future<List<Map<String, dynamic>>> getAllLeaveApplications({
    String? applicantId,
    String? applicantType,
    String? status,
    String? leaveTypeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = Supabase.instance.client.from('leave_applications').select();

    if (applicantId != null) {
      query = query.eq('applicant_id', applicantId);
    }
    if (applicantType != null) {
      query = query.eq('applicant_type', applicantType);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (leaveTypeId != null) {
      query = query.eq('leave_type_id', leaveTypeId);
    }
    if (startDate != null) {
      query = query.gte('start_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('end_date', endDate.toIso8601String());
    }

    final response = await query.order('created_at', ascending: false);
    return response;
  }

  Stream<List<Map<String, dynamic>>> streamLeaveApplications({
    String? applicantId,
    String? status,
  }) async* {
    await for (final data in Supabase.instance.client
        .from('leave_applications')
        .stream(primaryKey: ['id'])) {
      var filtered = data;
      if (applicantId != null) {
        filtered =
            filtered.where((l) => l['applicant_id'] == applicantId).toList();
      }
      if (status != null) {
        filtered = filtered.where((l) => l['status'] == status).toList();
      }
      yield filtered;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingApprovals() async {
    final response = await Supabase.instance.client
        .from('leave_applications')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return response;
  }

  Future<List<Map<String, dynamic>>> getMyLeaveHistory(
      String applicantId) async {
    final response = await Supabase.instance.client
        .from('leave_applications')
        .select()
        .eq('applicant_id', applicantId)
        .order('created_at', ascending: false);
    return response;
  }

  Future<void> approveLeave(
    String leaveId,
    String approverId, {
    String? notes,
  }) async {
    await Supabase.instance.client.from('leave_applications').update({
      'status': 'approved',
      'approved_by': approverId,
      'approved_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', leaveId);
  }

  Future<void> rejectLeave(
    String leaveId,
    String approverId,
    String reason,
  ) async {
    await Supabase.instance.client.from('leave_applications').update({
      'status': 'rejected',
      'approved_by': approverId,
      'approved_at': DateTime.now().toIso8601String(),
      'rejection_reason': reason,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', leaveId);
  }

  Future<void> cancelLeave(String leaveId) async {
    await Supabase.instance.client.from('leave_applications').update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', leaveId);
  }

  Future<Map<String, dynamic>> getLeaveStats(String applicantId) async {
    final response = await Supabase.instance.client
        .from('leave_applications')
        .select('status, total_days')
        .eq('applicant_id', applicantId);

    int approved = 0;
    int pending = 0;
    int rejected = 0;
    int cancelled = 0;
    double totalDaysApproved = 0;
    double totalDaysPending = 0;

    for (final leave in response) {
      final status = leave['status'] as String?;
      final days = (leave['total_days'] as num?)?.toDouble() ?? 0;

      switch (status) {
        case 'approved':
          approved++;
          totalDaysApproved += days;
          break;
        case 'pending':
          pending++;
          totalDaysPending += days;
          break;
        case 'rejected':
          rejected++;
          break;
        case 'cancelled':
          cancelled++;
          break;
      }
    }

    return {
      'approved': approved,
      'pending': pending,
      'rejected': rejected,
      'cancelled': cancelled,
      'totalDaysApproved': totalDaysApproved,
      'totalDaysPending': totalDaysPending,
      'total': response.length,
    };
  }

  Future<List<Map<String, dynamic>>> getLeaveTypes() async {
    final response = await Supabase.instance.client
        .from('leave_types')
        .select()
        .eq('is_active', true)
        .order('name');
    return response;
  }

  @override
  Future<void> create(Map<String, dynamic> data) async {
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    if (data['status'] == null) {
      data['status'] = 'pending';
    }
    await super.create(data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await super.update(id, data);
  }
}
