// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleModel _$VehicleModelFromJson(Map<String, dynamic> json) => VehicleModel(
      id: json['id'] as String,
      vehicleNumber: json['vehicleNumber'] as String,
      type: json['type'] as String?,
      model: json['model'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
      status: json['status'] as String?,
      active: json['active'] as bool?,
      fuelLevel: (json['fuelLevel'] as num?)?.toInt(),
      fuelEfficiency: (json['fuelEfficiency'] as num?)?.toDouble(),
      totalTrips: (json['totalTrips'] as num?)?.toInt(),
      totalDistance: (json['totalDistance'] as num?)?.toDouble(),
      fuelConsumed: (json['fuelConsumed'] as num?)?.toDouble(),
      maintenanceCost: (json['maintenanceCost'] as num?)?.toDouble(),
      avgEfficiency: (json['avgEfficiency'] as num?)?.toDouble(),
      tankCapacity: (json['tankCapacity'] as num?)?.toInt(),
      lastService: VehicleModel._dateFromJson(json['lastService']),
      nextService: VehicleModel._dateFromJson(json['nextService']),
      maintenanceStatus: json['maintenanceStatus'] as String?,
      lastRefuel: VehicleModel._dateFromJson(json['lastRefuel']),
      allocatedRoute: json['allocatedRoute'] as String?,
      allocatedDriver: json['allocatedDriver'] as String?,
      allocationStatus: json['allocationStatus'] as String?,
      createdAt: VehicleModel._dateTimeFromJson(json['createdAt']),
      updatedAt: VehicleModel._dateTimeFromJson(json['updatedAt']),
    );

Map<String, dynamic> _$VehicleModelToJson(VehicleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehicleNumber': instance.vehicleNumber,
      'type': instance.type,
      'model': instance.model,
      'capacity': instance.capacity,
      'status': instance.status,
      'active': instance.active,
      'fuelLevel': instance.fuelLevel,
      'fuelEfficiency': instance.fuelEfficiency,
      'totalTrips': instance.totalTrips,
      'totalDistance': instance.totalDistance,
      'fuelConsumed': instance.fuelConsumed,
      'maintenanceCost': instance.maintenanceCost,
      'avgEfficiency': instance.avgEfficiency,
      'tankCapacity': instance.tankCapacity,
      'lastService': VehicleModel._dateToJson(instance.lastService),
      'nextService': VehicleModel._dateToJson(instance.nextService),
      'maintenanceStatus': instance.maintenanceStatus,
      'lastRefuel': VehicleModel._dateToJson(instance.lastRefuel),
      'allocatedRoute': instance.allocatedRoute,
      'allocatedDriver': instance.allocatedDriver,
      'allocationStatus': instance.allocationStatus,
      'createdAt': VehicleModel._dateTimeToJson(instance.createdAt),
      'updatedAt': VehicleModel._dateTimeToJson(instance.updatedAt),
    };
