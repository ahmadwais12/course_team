import 'package:json_annotation/json_annotation.dart';

part 'notification_models.g.dart';

@JsonSerializable()
class AppNotification {
  final String id;
  final String? userId;
  final String title;
  final String message;
  final String type; // 'info', 'warning', 'error', 'success', 'announcement'
  final String category; // 'general', 'academic', 'payment', 'attendance', 'exam', 'chat', 'system'
  final String priority; // 'low', 'normal', 'high', 'urgent'
  final bool isRead;
  final bool isArchived;
  final String? actionUrl;
  final Map<String, dynamic>? actionData;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    required this.priority,
    this.isRead = false,
    this.isArchived = false,
    this.actionUrl,
    this.actionData,
    this.expiresAt,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);
  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);
}

@JsonSerializable()
class NotificationPreferences {
  final String id;
  final String userId;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  final bool chatNotifications;
  final bool academicNotifications;
  final bool paymentNotifications;
  final bool systemNotifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationPreferences({
    required this.id,
    required this.userId,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsNotifications = false,
    this.chatNotifications = true,
    this.academicNotifications = true,
    this.paymentNotifications = true,
    this.systemNotifications = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) => _$NotificationPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationPreferencesToJson(this);
}

@JsonSerializable()
class AppUpdate {
  final String id;
  final String version;
  final int buildNumber;
  final String platform; // 'android', 'ios', 'web', 'all'
  final String updateType; // 'optional', 'recommended', 'forced'
  final String title;
  final String? description;
  final List<String>? features;
  final List<String>? bugFixes;
  final String? downloadUrl;
  final int? fileSize;
  final bool isActive;
  final DateTime releaseDate;
  final DateTime createdAt;

  AppUpdate({
    required this.id,
    required this.version,
    required this.buildNumber,
    required this.platform,
    required this.updateType,
    required this.title,
    this.description,
    this.features,
    this.bugFixes,
    this.downloadUrl,
    this.fileSize,
    this.isActive = true,
    required this.releaseDate,
    required this.createdAt,
  });

  factory AppUpdate.fromJson(Map<String, dynamic> json) => _$AppUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$AppUpdateToJson(this);
}

@JsonSerializable()
class UserDevice {
  final String id;
  final String? userId;
  final String deviceId;
  final String? deviceName;
  final String? deviceType; // 'mobile', 'tablet', 'desktop', 'web'
  final String? platform; // 'android', 'ios', 'windows', 'macos', 'linux', 'web'
  final String? appVersion;
  final String? fcmToken;
  final bool isActive;
  final DateTime lastActive;
  final String? ipAddress;
  final String? location;
  final String? userAgent;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserDevice({
    required this.id,
    this.userId,
    required this.deviceId,
    this.deviceName,
    this.deviceType,
    this.platform,
    this.appVersion,
    this.fcmToken,
    this.isActive = true,
    required this.lastActive,
    this.ipAddress,
    this.location,
    this.userAgent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserDevice.fromJson(Map<String, dynamic> json) => _$UserDeviceFromJson(json);
  Map<String, dynamic> toJson() => _$UserDeviceToJson(this);
}
