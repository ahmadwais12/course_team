// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hr_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Staff _$StaffFromJson(Map<String, dynamic> json) => Staff(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      department: json['department'] as String,
      joinDate: DateTime.parse(json['join_date'] as String),
      status: json['status'] as String,
      photoUrl: json['photo_url'] as String?,
      salary: (json['salary'] as num?)?.toDouble() ?? 0.0,
      contractType: json['contract_type'] as String?,
      contractEndDate: json['contract_end_date'] == null
          ? null
          : DateTime.parse(json['contract_end_date'] as String),
    );

Map<String, dynamic> _$StaffToJson(Staff instance) => <String, dynamic>{
      'id': instance.id,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'phone': instance.phone,
      'role': instance.role,
      'department': instance.department,
      'join_date': instance.joinDate.toIso8601String(),
      'status': instance.status,
      'photo_url': instance.photoUrl,
      'salary': instance.salary,
      'contract_type': instance.contractType,
      'contract_end_date': instance.contractEndDate?.toIso8601String(),
    };

LeaveRequest _$LeaveRequestFromJson(Map<String, dynamic> json) => LeaveRequest(
      id: json['id'] as String,
      staffId: json['staff_id'] as String,
      leaveType: json['leave_type'] as String,
      fromDate: DateTime.parse(json['from_date'] as String),
      toDate: DateTime.parse(json['to_date'] as String),
      reason: json['reason'] as String,
      status: json['status'] as String,
      requestDate: json['request_date'] == null
          ? null
          : DateTime.parse(json['request_date'] as String),
      approvedBy: json['approved_by'] as String?,
      days: (json['days'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$LeaveRequestToJson(LeaveRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'staff_id': instance.staffId,
      'leave_type': instance.leaveType,
      'from_date': instance.fromDate.toIso8601String(),
      'to_date': instance.toDate.toIso8601String(),
      'reason': instance.reason,
      'status': instance.status,
      'request_date': instance.requestDate?.toIso8601String(),
      'approved_by': instance.approvedBy,
      'days': instance.days,
    };

PerformanceReview _$PerformanceReviewFromJson(Map<String, dynamic> json) =>
    PerformanceReview(
      id: json['id'] as String,
      staffId: json['staff_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      reviewDate: DateTime.parse(json['review_date'] as String),
      period: json['period'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      strengths: json['strengths'] as String?,
      improvements: json['improvements'] as String?,
      goals: json['goals'] as String?,
      comments: json['comments'] as String?,
    );

Map<String, dynamic> _$PerformanceReviewToJson(PerformanceReview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'staff_id': instance.staffId,
      'reviewer_id': instance.reviewerId,
      'review_date': instance.reviewDate.toIso8601String(),
      'period': instance.period,
      'rating': instance.rating,
      'strengths': instance.strengths,
      'improvements': instance.improvements,
      'goals': instance.goals,
      'comments': instance.comments,
    };

HRRecord _$HRRecordFromJson(Map<String, dynamic> json) => HRRecord(
      staff: (json['staff'] as List<dynamic>)
          .map((e) => Staff.fromJson(e as Map<String, dynamic>))
          .toList(),
      leaveRequests: (json['leaveRequests'] as List<dynamic>)
          .map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
      performanceReviews: (json['performanceReviews'] as List<dynamic>)
          .map((e) => PerformanceReview.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$HRRecordToJson(HRRecord instance) => <String, dynamic>{
      'staff': instance.staff,
      'leaveRequests': instance.leaveRequests,
      'performanceReviews': instance.performanceReviews,
    };
