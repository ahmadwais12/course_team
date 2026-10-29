// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    AppNotification(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String,
      isRead: json['isRead'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      actionUrl: json['actionUrl'] as String?,
      actionData: json['actionData'] as Map<String, dynamic>?,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
    );

Map<String, dynamic> _$AppNotificationToJson(AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'title': instance.title,
      'message': instance.message,
      'type': instance.type,
      'category': instance.category,
      'priority': instance.priority,
      'isRead': instance.isRead,
      'isArchived': instance.isArchived,
      'actionUrl': instance.actionUrl,
      'actionData': instance.actionData,
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'readAt': instance.readAt?.toIso8601String(),
    };

NotificationPreferences _$NotificationPreferencesFromJson(
        Map<String, dynamic> json) =>
    NotificationPreferences(
      id: json['id'] as String,
      userId: json['userId'] as String,
      emailNotifications: json['emailNotifications'] as bool? ?? true,
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      smsNotifications: json['smsNotifications'] as bool? ?? false,
      chatNotifications: json['chatNotifications'] as bool? ?? true,
      academicNotifications: json['academicNotifications'] as bool? ?? true,
      paymentNotifications: json['paymentNotifications'] as bool? ?? true,
      systemNotifications: json['systemNotifications'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$NotificationPreferencesToJson(
        NotificationPreferences instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'emailNotifications': instance.emailNotifications,
      'pushNotifications': instance.pushNotifications,
      'smsNotifications': instance.smsNotifications,
      'chatNotifications': instance.chatNotifications,
      'academicNotifications': instance.academicNotifications,
      'paymentNotifications': instance.paymentNotifications,
      'systemNotifications': instance.systemNotifications,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

AppUpdate _$AppUpdateFromJson(Map<String, dynamic> json) => AppUpdate(
      id: json['id'] as String,
      version: json['version'] as String,
      buildNumber: (json['buildNumber'] as num).toInt(),
      platform: json['platform'] as String,
      updateType: json['updateType'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      features: (json['features'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      bugFixes: (json['bugFixes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      downloadUrl: json['downloadUrl'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
      releaseDate: DateTime.parse(json['releaseDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AppUpdateToJson(AppUpdate instance) => <String, dynamic>{
      'id': instance.id,
      'version': instance.version,
      'buildNumber': instance.buildNumber,
      'platform': instance.platform,
      'updateType': instance.updateType,
      'title': instance.title,
      'description': instance.description,
      'features': instance.features,
      'bugFixes': instance.bugFixes,
      'downloadUrl': instance.downloadUrl,
      'fileSize': instance.fileSize,
      'isActive': instance.isActive,
      'releaseDate': instance.releaseDate.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

UserDevice _$UserDeviceFromJson(Map<String, dynamic> json) => UserDevice(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String?,
      deviceType: json['deviceType'] as String?,
      platform: json['platform'] as String?,
      appVersion: json['appVersion'] as String?,
      fcmToken: json['fcmToken'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      lastActive: DateTime.parse(json['lastActive'] as String),
      ipAddress: json['ipAddress'] as String?,
      location: json['location'] as String?,
      userAgent: json['userAgent'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserDeviceToJson(UserDevice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'deviceType': instance.deviceType,
      'platform': instance.platform,
      'appVersion': instance.appVersion,
      'fcmToken': instance.fcmToken,
      'isActive': instance.isActive,
      'lastActive': instance.lastActive.toIso8601String(),
      'ipAddress': instance.ipAddress,
      'location': instance.location,
      'userAgent': instance.userAgent,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
