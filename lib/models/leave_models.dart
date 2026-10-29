import 'package:json_annotation/json_annotation.dart';

part 'leave_models.g.dart';

@JsonSerializable()
class LeaveType {
  final String id;
  final String name;
  final String? description;
  final int maxDaysPerMonth;
  final int maxDaysPerYear;
  final bool requiresApproval;
  final List<String> applicableTo;
  final bool isActive;
  final DateTime createdAt;

  LeaveType({
    required this.id,
    required this.name,
    this.description,
    required this.maxDaysPerMonth,
    required this.maxDaysPerYear,
    required this.requiresApproval,
    required this.applicableTo,
    this.isActive = true,
    required this.createdAt,
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) => _$LeaveTypeFromJson(json);
  Map<String, dynamic> toJson() => _$LeaveTypeToJson(this);
}

@JsonSerializable()
class LeaveApplication {
  final String id;
  final String applicantId;
  final String applicantType; // 'student', 'teacher', 'staff'
  final String leaveTypeId;
  final String leaveCategory; // 'full_day', 'half_day', 'hourly'
  final DateTime startDate;
  final DateTime? endDate;
  final String? startTime; // for hourly leaves
  final String? endTime; // for hourly leaves
  final double totalDays;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected', 'cancelled'
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? emergencyContact;
  final List<String>? supportingDocuments;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional fields for display
  final String? applicantName;
  final String? leaveTypeName;
  final String? approverName;

  LeaveApplication({
    required this.id,
    required this.applicantId,
    required this.applicantType,
    required this.leaveTypeId,
    required this.leaveCategory,
    required this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    required this.totalDays,
    required this.reason,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.emergencyContact,
    this.supportingDocuments,
    required this.createdAt,
    required this.updatedAt,
    this.applicantName,
    this.leaveTypeName,
    this.approverName,
  });

  factory LeaveApplication.fromJson(Map<String, dynamic> json) => _$LeaveApplicationFromJson(json);
  Map<String, dynamic> toJson() => _$LeaveApplicationToJson(this);
}

@JsonSerializable()
class StudentLeaveTracking {
  final String id;
  final String studentId;
  final int month;
  final int year;
  final double daysUsed;
  final double daysRemaining;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudentLeaveTracking({
    required this.id,
    required this.studentId,
    required this.month,
    required this.year,
    required this.daysUsed,
    required this.daysRemaining,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentLeaveTracking.fromJson(Map<String, dynamic> json) => _$StudentLeaveTrackingFromJson(json);
  Map<String, dynamic> toJson() => _$StudentLeaveTrackingToJson(this);
}
