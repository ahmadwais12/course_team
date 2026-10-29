// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Announcement _$AnnouncementFromJson(Map<String, dynamic> json) => Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      audience: json['audience'] as String? ?? 'all',
      targetIds: (json['target_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      priority: json['priority'] as String? ?? 'normal',
      startDate: json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      isPinned: json['is_pinned'] as bool? ?? false,
      views: (json['views'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'draft',
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$AnnouncementToJson(Announcement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'audience': instance.audience,
      'target_ids': instance.targetIds,
      'priority': instance.priority,
      'start_date': instance.startDate?.toIso8601String(),
      'end_date': instance.endDate?.toIso8601String(),
      'is_pinned': instance.isPinned,
      'views': instance.views,
      'status': instance.status,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
