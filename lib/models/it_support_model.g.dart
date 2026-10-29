// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'it_support_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ITSupportTicket _$ITSupportTicketFromJson(Map<String, dynamic> json) =>
    ITSupportTicket(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String? ?? 'open',
      category: json['category'] as String?,
      requesterId: json['requester_id'] as String,
      assignedTo: json['assigned_to'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      resolvedBy: json['resolved_by'] as String?,
      resolvedAt: json['resolved_at'] == null
          ? null
          : DateTime.parse(json['resolved_at'] as String),
    );

Map<String, dynamic> _$ITSupportTicketToJson(ITSupportTicket instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'priority': instance.priority,
      'status': instance.status,
      'category': instance.category,
      'requester_id': instance.requesterId,
      'assigned_to': instance.assignedTo,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'resolved_by': instance.resolvedBy,
      'resolved_at': instance.resolvedAt?.toIso8601String(),
    };
