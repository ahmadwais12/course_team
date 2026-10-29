import 'package:json_annotation/json_annotation.dart';

part 'hr_model.g.dart';

@JsonSerializable()
class Staff {
  final String id;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String department;
  @JsonKey(name: 'join_date')
  final DateTime joinDate;
  final String status;
  @JsonKey(name: 'photo_url')
  final String? photoUrl;
  final double salary;
  @JsonKey(name: 'contract_type')
  final String? contractType;
  @JsonKey(name: 'contract_end_date')
  final DateTime? contractEndDate;

  Staff({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.department,
    required this.joinDate,
    required this.status,
    this.photoUrl,
    this.salary = 0.0,
    this.contractType,
    this.contractEndDate,
  });

  String get fullName => '$firstName $lastName';

  factory Staff.fromJson(Map<String, dynamic> json) => _$StaffFromJson(json);
  Map<String, dynamic> toJson() => _$StaffToJson(this);
}

@JsonSerializable()
class LeaveRequest {
  final String id;
  @JsonKey(name: 'staff_id')
  final String staffId;
  @JsonKey(name: 'leave_type')
  final String leaveType;
  @JsonKey(name: 'from_date')
  final DateTime fromDate;
  @JsonKey(name: 'to_date')
  final DateTime toDate;
  final String reason;
  final String status;
  @JsonKey(name: 'request_date')
  final DateTime? requestDate;
  @JsonKey(name: 'approved_by')
  final String? approvedBy;
  final int days;

  LeaveRequest({
    required this.id,
    required this.staffId,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
    this.requestDate,
    this.approvedBy,
    this.days = 0,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) => _$LeaveRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LeaveRequestToJson(this);
}

@JsonSerializable()
class PerformanceReview {
  final String id;
  @JsonKey(name: 'staff_id')
  final String staffId;
  @JsonKey(name: 'reviewer_id')
  final String reviewerId;
  @JsonKey(name: 'review_date')
  final DateTime reviewDate;
  final String period;
  final double rating;
  final String? strengths;
  final String? improvements;
  final String? goals;
  final String? comments;

  PerformanceReview({
    required this.id,
    required this.staffId,
    required this.reviewerId,
    required this.reviewDate,
    required this.period,
    this.rating = 0.0,
    this.strengths,
    this.improvements,
    this.goals,
    this.comments,
  });

  factory PerformanceReview.fromJson(Map<String, dynamic> json) => _$PerformanceReviewFromJson(json);
  Map<String, dynamic> toJson() => _$PerformanceReviewToJson(this);
}

@JsonSerializable()
class HRRecord {
  final List<Staff> staff;
  final List<LeaveRequest> leaveRequests;
  final List<PerformanceReview> performanceReviews;

  HRRecord({
    required this.staff,
    required this.leaveRequests,
    required this.performanceReviews,
  });

  factory HRRecord.fromJson(Map<String, dynamic> json) => _$HRRecordFromJson(json);
  Map<String, dynamic> toJson() => _$HRRecordToJson(this);
}
