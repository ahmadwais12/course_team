import 'package:json_annotation/json_annotation.dart';

part 'vehicle_model.g.dart';

@JsonSerializable()
class VehicleModel {
  final String id;
  final String vehicleNumber;
  final String? type;
  final String? model;
  final int? capacity;
  final String? status;
  final bool? active;
  final int? fuelLevel;
  final double? fuelEfficiency;
  final int? totalTrips;
  final double? totalDistance;
  final double? fuelConsumed;
  final double? maintenanceCost;
  final double? avgEfficiency;
  final int? tankCapacity;
  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime? lastService;
  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime? nextService;
  final String? maintenanceStatus;
  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime? lastRefuel;
  final String? allocatedRoute;
  final String? allocatedDriver;
  final String? allocationStatus;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updatedAt;

  VehicleModel({
    required this.id,
    required this.vehicleNumber,
    this.type,
    this.model,
    this.capacity,
    this.status,
    this.active,
    this.fuelLevel,
    this.fuelEfficiency,
    this.totalTrips,
    this.totalDistance,
    this.fuelConsumed,
    this.maintenanceCost,
    this.avgEfficiency,
    this.tankCapacity,
    this.lastService,
    this.nextService,
    this.maintenanceStatus,
    this.lastRefuel,
    this.allocatedRoute,
    this.allocatedDriver,
    this.allocationStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) =>
      _$VehicleModelFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleModelToJson(this);

  // Helper getters
  bool get isActive => active ?? false;
  bool get isAvailable => allocationStatus?.toLowerCase() == 'available';
  bool get needsMaintenance {
    if (nextService == null) return false;
    return DateTime.now().isAfter(nextService!);
  }

  double? get fuelPercentage {
    if (fuelLevel == null || tankCapacity == null) return null;
    return (fuelLevel! / tankCapacity!) * 100;
  }

  // DateTime helpers
  static DateTime? _dateFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.parse(value);
    return null;
  }

  static String? _dateToJson(DateTime? value) => value?.toIso8601String();

  static DateTime _dateTimeFromJson(dynamic value) {
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static String? _dateTimeToJson(DateTime? value) => value?.toIso8601String();

  VehicleModel copyWith({
    String? id,
    String? vehicleNumber,
    String? type,
    String? model,
    int? capacity,
    String? status,
    bool? active,
    int? fuelLevel,
    double? fuelEfficiency,
    int? totalTrips,
    double? totalDistance,
    double? fuelConsumed,
    double? maintenanceCost,
    double? avgEfficiency,
    int? tankCapacity,
    DateTime? lastService,
    DateTime? nextService,
    String? maintenanceStatus,
    DateTime? lastRefuel,
    String? allocatedRoute,
    String? allocatedDriver,
    String? allocationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      type: type ?? this.type,
      model: model ?? this.model,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      active: active ?? this.active,
      fuelLevel: fuelLevel ?? this.fuelLevel,
      fuelEfficiency: fuelEfficiency ?? this.fuelEfficiency,
      totalTrips: totalTrips ?? this.totalTrips,
      totalDistance: totalDistance ?? this.totalDistance,
      fuelConsumed: fuelConsumed ?? this.fuelConsumed,
      maintenanceCost: maintenanceCost ?? this.maintenanceCost,
      avgEfficiency: avgEfficiency ?? this.avgEfficiency,
      tankCapacity: tankCapacity ?? this.tankCapacity,
      lastService: lastService ?? this.lastService,
      nextService: nextService ?? this.nextService,
      maintenanceStatus: maintenanceStatus ?? this.maintenanceStatus,
      lastRefuel: lastRefuel ?? this.lastRefuel,
      allocatedRoute: allocatedRoute ?? this.allocatedRoute,
      allocatedDriver: allocatedDriver ?? this.allocatedDriver,
      allocationStatus: allocationStatus ?? this.allocationStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
