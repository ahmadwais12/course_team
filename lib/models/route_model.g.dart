// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RouteModel _$RouteModelFromJson(Map<String, dynamic> json) => RouteModel(
      id: json['id'] as String,
      name: json['name'] as String,
      origin: json['origin'] as String?,
      destination: json['destination'] as String?,
      distance: (json['distance'] as num?)?.toDouble(),
      duration: (json['duration'] as num?)?.toInt(),
      stops: (json['stops'] as num?)?.toInt(),
      assignedDriver: json['assignedDriver'] as String?,
      assignedVehicle: json['assignedVehicle'] as String?,
      status: json['status'] as String?,
      startTime: json['startTime'] as String?,
      vehicleId: json['vehicleId'] as String?,
      createdAt: RouteModel._dateTimeFromJson(json['createdAt']),
      updatedAt: RouteModel._dateTimeFromJson(json['updatedAt']),
    );

Map<String, dynamic> _$RouteModelToJson(RouteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'origin': instance.origin,
      'destination': instance.destination,
      'distance': instance.distance,
      'duration': instance.duration,
      'stops': instance.stops,
      'assignedDriver': instance.assignedDriver,
      'assignedVehicle': instance.assignedVehicle,
      'status': instance.status,
      'startTime': instance.startTime,
      'vehicleId': instance.vehicleId,
      'createdAt': RouteModel._dateTimeToJson(instance.createdAt),
      'updatedAt': RouteModel._dateTimeToJson(instance.updatedAt),
    };
