import 'package:json_annotation/json_annotation.dart';

part 'route_model.g.dart';

@JsonSerializable()
class RouteModel {
  final String id;
  final String name;
  final String? origin;
  final String? destination;
  final double? distance;
  final int? duration;
  final int? stops;
  final String? assignedDriver;
  final String? assignedVehicle;
  final String? status;
  final String? startTime;
  final String? vehicleId;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updatedAt;

  RouteModel({
    required this.id,
    required this.name,
    this.origin,
    this.destination,
    this.distance,
    this.duration,
    this.stops,
    this.assignedDriver,
    this.assignedVehicle,
    this.status,
    this.startTime,
    this.vehicleId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) =>
      _$RouteModelFromJson(json);

  Map<String, dynamic> toJson() => _$RouteModelToJson(this);

  // Helper getters
  bool get isActive => status?.toLowerCase() == 'active';
  bool get isPending => status?.toLowerCase() == 'pending';
  bool get isCompleted => status?.toLowerCase() == 'completed';
  bool get isAssigned => assignedDriver != null || assignedVehicle != null;

  String get formattedDuration {
    if (duration == null) return 'N/A';
    final hours = duration! ~/ 60;
    final minutes = duration! % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get routeDisplay => '${origin ?? 'Unknown'} → ${destination ?? 'Unknown'}';

  // DateTime helpers
  static DateTime _dateTimeFromJson(dynamic value) {
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static String? _dateTimeToJson(DateTime? value) => value?.toIso8601String();

  RouteModel copyWith({
    String? id,
    String? name,
    String? origin,
    String? destination,
    double? distance,
    int? duration,
    int? stops,
    String? assignedDriver,
    String? assignedVehicle,
    String? status,
    String? startTime,
    String? vehicleId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RouteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      stops: stops ?? this.stops,
      assignedDriver: assignedDriver ?? this.assignedDriver,
      assignedVehicle: assignedVehicle ?? this.assignedVehicle,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      vehicleId: vehicleId ?? this.vehicleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
