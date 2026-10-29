import 'package:json_annotation/json_annotation.dart';

part 'driver_model.g.dart';

@JsonSerializable()
class DriverModel {
  final String id;
  final String name;
  final String? licenseNumber;
  final String? phone;
  final String? email;
  final int? experienceYears;
  final bool? available;
  final String? currentRoute;
  final String? shiftTiming;
  final String? vehicleType;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updatedAt;

  DriverModel({
    required this.id,
    required this.name,
    this.licenseNumber,
    this.phone,
    this.email,
    this.experienceYears,
    this.available,
    this.currentRoute,
    this.shiftTiming,
    this.vehicleType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) =>
      _$DriverModelFromJson(json);

  Map<String, dynamic> toJson() => _$DriverModelToJson(this);

  // Helper getters
  bool get isAvailable => available ?? false;
  bool get isAssigned => currentRoute != null && currentRoute!.isNotEmpty;

  String get experienceLevel {
    final years = experienceYears ?? 0;
    if (years >= 10) return 'Expert';
    if (years >= 5) return 'Experienced';
    if (years >= 2) return 'Intermediate';
    return 'Beginner';
  }

  // DateTime helpers
  static DateTime _dateTimeFromJson(dynamic value) {
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static String? _dateTimeToJson(DateTime? value) => value?.toIso8601String();

  DriverModel copyWith({
    String? id,
    String? name,
    String? licenseNumber,
    String? phone,
    String? email,
    int? experienceYears,
    bool? available,
    String? currentRoute,
    String? shiftTiming,
    String? vehicleType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      experienceYears: experienceYears ?? this.experienceYears,
      available: available ?? this.available,
      currentRoute: currentRoute ?? this.currentRoute,
      shiftTiming: shiftTiming ?? this.shiftTiming,
      vehicleType: vehicleType ?? this.vehicleType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
