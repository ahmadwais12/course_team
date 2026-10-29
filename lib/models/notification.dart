enum NotificationType {
  grade,
  discount,
  payment,
  salary,
  announcement,
  academic,
  attendance,
  hr,
  system,
  general,
}

enum NotificationPriority { low, normal, high, urgent }

class AppNotification {
  final String id;
  final String userId;
  final String? tenantId;
  final NotificationType type;
  final String title;
  final String message;
  final String? body;
  final NotificationPriority priority;
  final String? actionUrl;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    this.tenantId,
    this.type = NotificationType.general,
    required this.title,
    required this.message,
    this.body,
    this.priority = NotificationPriority.normal,
    this.actionUrl,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    if (tenantId != null) 'tenant_id': tenantId,
    'type': type.name,
    'title': title,
    'message': message,
    if (body != null) 'body': body,
    'priority': priority.name,
    if (actionUrl != null) 'action_url': actionUrl,
    if (data != null) 'data': data,
    'isRead': isRead,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    userId: json['userId'] as String,
    tenantId: json['tenant_id'] as String?,
    type: NotificationType.values.firstWhere(
      (e) => e.name == (json['type'] as String? ?? 'general'),
      orElse: () => NotificationType.general,
    ),
    title: (json['title'] as String?) ?? '',
    message: (json['message'] as String?) ?? (json['body'] as String?) ?? '',
    body: json['body'] as String?,
    priority: NotificationPriority.values.firstWhere(
      (e) => e.name == (json['priority'] as String? ?? 'normal'),
      orElse: () => NotificationPriority.normal,
    ),
    actionUrl: json['action_url'] as String?,
    data: json['data'] as Map<String, dynamic>?,
    isRead: json['isRead'] as bool? ?? json['is_read'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String),
  );

  AppNotification copyWith({
    String? id,
    String? userId,
    String? tenantId,
    NotificationType? type,
    String? title,
    String? message,
    String? body,
    NotificationPriority? priority,
    String? actionUrl,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) => AppNotification(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    tenantId: tenantId ?? this.tenantId,
    type: type ?? this.type,
    title: title ?? this.title,
    message: message ?? this.message,
    body: body ?? this.body,
    priority: priority ?? this.priority,
    actionUrl: actionUrl ?? this.actionUrl,
    data: data ?? this.data,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt ?? this.createdAt,
  );
}
