// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverModel _$DriverModelFromJson(Map<String, dynamic> json) => DriverModel(
      id: json['id'] as String,
      name: json['name'] as String,
      licenseNumber: json['licenseNumber'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      experienceYears: (json['experienceYears'] as num?)?.toInt(),
      available: json['available'] as bool?,
      currentRoute: json['currentRoute'] as String?,
      shiftTiming: json['shiftTiming'] as String?,
      vehicleType: json['vehicleType'] as String?,
      createdAt: DriverModel._dateTimeFromJson(json['createdAt']),
      updatedAt: DriverModel._dateTimeFromJson(json['updatedAt']),
    );

Map<String, dynamic> _$DriverModelToJson(DriverModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'licenseNumber': instance.licenseNumber,
      'phone': instance.phone,
      'email': instance.email,
      'experienceYears': instance.experienceYears,
      'available': instance.available,
      'currentRoute': instance.currentRoute,
      'shiftTiming': instance.shiftTiming,
      'vehicleType': instance.vehicleType,
      'createdAt': DriverModel._dateTimeToJson(instance.createdAt),
      'updatedAt': DriverModel._dateTimeToJson(instance.updatedAt),
    };
