import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_ticket_model.g.dart';

@JsonSerializable()
class SupportTicket {
  final String id;
  final String title;
  final String? description;
  final String? category; // 'hardware', 'software', 'network', 'account', 'access', 'bug', 'feature_request', 'other'
  final String? priority; // 'low', 'medium', 'high', 'urgent'
  final String? status; // 'open', 'in_progress', 'resolved', 'closed', 'rejected'
  @JsonKey(name: 'assigned_to')
  final String? assignedTo;
  @JsonKey(name: 'reported_by')
  final String? reportedBy;
  final String? location;
  @JsonKey(name: 'resolution_notes')
  final String? resolutionNotes;
  @JsonKey(name: 'resolved_at')
  final DateTime? resolvedAt;
  @JsonKey(name: 'closed_at')
  final DateTime? closedAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  SupportTicket({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.priority = 'medium',
    this.status = 'open',
    this.assignedTo,
    this.reportedBy,
    this.location,
    this.resolutionNotes,
    this.resolvedAt,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) => _$SupportTicketFromJson(json);
  Map<String, dynamic> toJson() => _$SupportTicketToJson(this);

  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved';
  bool get isClosed => status == 'closed';
  bool get isRejected => status == 'rejected';

  bool get isUrgent => priority == 'urgent';
  bool get isHighPriority => priority == 'high';

  Color get priorityColor {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
