import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'announcement_model.g.dart';

@JsonSerializable()
class Announcement {
  final String id;
  final String title;
  final String content;
  final String?
      audience; // 'all', 'students', 'teachers', 'staff', 'parents', 'custom'
  @JsonKey(name: 'target_ids')
  final List<String>? targetIds;
  final String? priority; // 'low', 'normal', 'high', 'urgent'
  @JsonKey(name: 'start_date')
  final DateTime? startDate;
  @JsonKey(name: 'end_date')
  final DateTime? endDate;
  @JsonKey(name: 'is_pinned')
  final bool isPinned;
  final int views;
  final String? status; // 'draft', 'scheduled', 'published', 'archived'
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.audience = 'all',
    this.targetIds,
    this.priority = 'normal',
    this.startDate,
    this.endDate,
    this.isPinned = false,
    this.views = 0,
    this.status = 'draft',
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementFromJson(json);
  Map<String, dynamic> toJson() => _$AnnouncementToJson(this);

  bool get isDraft => status == 'draft';
  bool get isPublished => status == 'published';
  bool get isScheduled => status == 'scheduled';
  bool get isArchived => status == 'archived';

  bool get isUrgent => priority == 'urgent';
  bool get isHighPriority => priority == 'high';

  bool get isActive {
    if (status != 'published') return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  Color get priorityColor {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'normal':
        return Colors.blue;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
