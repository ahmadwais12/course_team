import 'package:json_annotation/json_annotation.dart';

part 'it_support_model.g.dart';

@JsonSerializable()
class ITSupportTicket {
  final String id;
  final String title;
  final String description;
  final String priority; // 'low', 'medium', 'high', 'critical'
  final String status; // 'open', 'in_progress', 'resolved', 'closed'
  @JsonKey(name: 'category')
  final String? category;
  @JsonKey(name: 'requester_id')
  final String requesterId;
  @JsonKey(name: 'assigned_to')
  final String? assignedTo;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'resolved_by')
  final String? resolvedBy;
  @JsonKey(name: 'resolved_at')
  final DateTime? resolvedAt;

  ITSupportTicket({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    this.status = 'open',
    this.category,
    required this.requesterId,
    this.assignedTo,
    required this.createdAt,
    this.updatedAt,
    this.resolvedBy,
    this.resolvedAt,
  });

  factory ITSupportTicket.fromJson(Map<String, dynamic> json) =>
      _$ITSupportTicketFromJson(json);
  Map<String, dynamic> toJson() => _$ITSupportTicketToJson(this);
}
