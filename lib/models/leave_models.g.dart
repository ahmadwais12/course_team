// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaveType _$LeaveTypeFromJson(Map<String, dynamic> json) => LeaveType(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      maxDaysPerMonth: (json['maxDaysPerMonth'] as num).toInt(),
      maxDaysPerYear: (json['maxDaysPerYear'] as num).toInt(),
      requiresApproval: json['requiresApproval'] as bool,
      applicableTo: (json['applicableTo'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$LeaveTypeToJson(LeaveType instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'maxDaysPerMonth': instance.maxDaysPerMonth,
      'maxDaysPerYear': instance.maxDaysPerYear,
      'requiresApproval': instance.requiresApproval,
      'applicableTo': instance.applicableTo,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
    };

LeaveApplication _$LeaveApplicationFromJson(Map<String, dynamic> json) =>
    LeaveApplication(
      id: json['id'] as String,
      applicantId: json['applicantId'] as String,
      applicantType: json['applicantType'] as String,
      leaveTypeId: json['leaveTypeId'] as String,
      leaveCategory: json['leaveCategory'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      totalDays: (json['totalDays'] as num).toDouble(),
      reason: json['reason'] as String,
      status: json['status'] as String,
      approvedBy: json['approvedBy'] as String?,
      approvedAt: json['approvedAt'] == null
          ? null
          : DateTime.parse(json['approvedAt'] as String),
      rejectionReason: json['rejectionReason'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
      supportingDocuments: (json['supportingDocuments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      applicantName: json['applicantName'] as String?,
      leaveTypeName: json['leaveTypeName'] as String?,
      approverName: json['approverName'] as String?,
    );

Map<String, dynamic> _$LeaveApplicationToJson(LeaveApplication instance) =>
    <String, dynamic>{
      'id': instance.id,
      'applicantId': instance.applicantId,
      'applicantType': instance.applicantType,
      'leaveTypeId': instance.leaveTypeId,
      'leaveCategory': instance.leaveCategory,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'totalDays': instance.totalDays,
      'reason': instance.reason,
      'status': instance.status,
      'approvedBy': instance.approvedBy,
      'approvedAt': instance.approvedAt?.toIso8601String(),
      'rejectionReason': instance.rejectionReason,
      'emergencyContact': instance.emergencyContact,
      'supportingDocuments': instance.supportingDocuments,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'applicantName': instance.applicantName,
      'leaveTypeName': instance.leaveTypeName,
      'approverName': instance.approverName,
    };

StudentLeaveTracking _$StudentLeaveTrackingFromJson(
        Map<String, dynamic> json) =>
    StudentLeaveTracking(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      month: (json['month'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      daysUsed: (json['daysUsed'] as num).toDouble(),
      daysRemaining: (json['daysRemaining'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$StudentLeaveTrackingToJson(
        StudentLeaveTracking instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studentId': instance.studentId,
      'month': instance.month,
      'year': instance.year,
      'daysUsed': instance.daysUsed,
      'daysRemaining': instance.daysRemaining,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
