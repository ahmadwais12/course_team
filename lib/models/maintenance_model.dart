import 'package:json_annotation/json_annotation.dart';

part 'maintenance_model.g.dart';

@JsonSerializable()
class MaintenanceTask {
  final String id;
  final String taskName;
  final String location;
  final String description;
  final String priority; // 'low', 'medium', 'high'
  final String status; // 'pending', 'in_progress', 'completed'
  final DateTime scheduledAt;

  MaintenanceTask({
    required this.id,
    required this.taskName,
    required this.location,
    required this.description,
    required this.priority,
    this.status = 'pending',
    required this.scheduledAt,
  });

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) => _$MaintenanceTaskFromJson(json);
  Map<String, dynamic> toJson() => _$MaintenanceTaskToJson(this);
}
