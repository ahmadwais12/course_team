import 'package:json_annotation/json_annotation.dart';

part 'complaint_model.g.dart';

@JsonSerializable()
class Complaint {
  final String id;
  final String title;
  final String description;
  @JsonKey(name: 'complainant_id')
  final String complainantId;
  @JsonKey(name: 'complainant_type')
  final String complainantType;
  final String category;
  final String priority;
  final String status;
  @JsonKey(name: 'created_date')
  final DateTime createdDate;
  @JsonKey(name: 'resolved_date')
  final DateTime? resolvedDate;
  @JsonKey(name: 'assigned_to')
  final String? assignedTo;
  final String? resolution;
  final String? notes;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.complainantId,
    required this.complainantType,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdDate,
    this.resolvedDate,
    this.assignedTo,
    this.resolution,
    this.notes,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) => _$ComplaintFromJson(json);
  Map<String, dynamic> toJson() => _$ComplaintToJson(this);
}

@JsonSerializable()
class ComplaintComment {
  final String id;
  @JsonKey(name: 'complaint_id')
  final String complaintId;
  @JsonKey(name: 'author_id')
  final String authorId;
  @JsonKey(name: 'author_type')
  final String authorType;
  final String comment;
  final DateTime date;

  ComplaintComment({
    required this.id,
    required this.complaintId,
    required this.authorId,
    required this.authorType,
    required this.comment,
    required this.date,
  });

  factory ComplaintComment.fromJson(Map<String, dynamic> json) => _$ComplaintCommentFromJson(json);
  Map<String, dynamic> toJson() => _$ComplaintCommentToJson(this);
}
