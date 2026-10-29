// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complaint_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Complaint _$ComplaintFromJson(Map<String, dynamic> json) => Complaint(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      complainantId: json['complainant_id'] as String,
      complainantType: json['complainant_type'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      createdDate: DateTime.parse(json['created_date'] as String),
      resolvedDate: json['resolved_date'] == null
          ? null
          : DateTime.parse(json['resolved_date'] as String),
      assignedTo: json['assigned_to'] as String?,
      resolution: json['resolution'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$ComplaintToJson(Complaint instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'complainant_id': instance.complainantId,
      'complainant_type': instance.complainantType,
      'category': instance.category,
      'priority': instance.priority,
      'status': instance.status,
      'created_date': instance.createdDate.toIso8601String(),
      'resolved_date': instance.resolvedDate?.toIso8601String(),
      'assigned_to': instance.assignedTo,
      'resolution': instance.resolution,
      'notes': instance.notes,
    };

ComplaintComment _$ComplaintCommentFromJson(Map<String, dynamic> json) =>
    ComplaintComment(
      id: json['id'] as String,
      complaintId: json['complaint_id'] as String,
      authorId: json['author_id'] as String,
      authorType: json['author_type'] as String,
      comment: json['comment'] as String,
      date: DateTime.parse(json['date'] as String),
    );

Map<String, dynamic> _$ComplaintCommentToJson(ComplaintComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'complaint_id': instance.complaintId,
      'author_id': instance.authorId,
      'author_type': instance.authorType,
      'comment': instance.comment,
      'date': instance.date.toIso8601String(),
    };
