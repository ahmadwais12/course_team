// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceTask _$MaintenanceTaskFromJson(Map<String, dynamic> json) =>
    MaintenanceTask(
      id: json['id'] as String,
      taskName: json['taskName'] as String,
      location: json['location'] as String,
      description: json['description'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String? ?? 'pending',
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
    );

Map<String, dynamic> _$MaintenanceTaskToJson(MaintenanceTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'taskName': instance.taskName,
      'location': instance.location,
      'description': instance.description,
      'priority': instance.priority,
      'status': instance.status,
      'scheduledAt': instance.scheduledAt.toIso8601String(),
    };
