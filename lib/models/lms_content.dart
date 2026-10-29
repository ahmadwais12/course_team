enum FeedbackType { teacher, classType, general }
enum FeedbackStatus { pending, reviewed, resolved }

class Feedback {
  final String id;
  final String studentId;
  final FeedbackType type;
  final String message;
  final FeedbackStatus status;
  final String? response;
  final bool isAnonymous;
  final DateTime createdAt;

  Feedback({
    required this.id,
    required this.studentId,
    required this.type,
    required this.message,
    required this.status,
    this.response,
    required this.isAnonymous,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'type': type.name,
    'message': message,
    'status': status.name,
    'response': response,
    'isAnonymous': isAnonymous,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Feedback.fromJson(Map<String, dynamic> json) => Feedback(
    id: json['id'] as String,
    studentId: json['studentId'] as String,
    type: FeedbackType.values.firstWhere((e) => e.name == json['type']),
    message: json['message'] as String,
    status: FeedbackStatus.values.firstWhere((e) => e.name == json['status']),
    response: json['response'] as String?,
    isAnonymous: json['isAnonymous'] as bool,
    createdAt: DateTime.parse(json['createdAt']),
  );

  Feedback copyWith({
    String? id,
    String? studentId,
    FeedbackType? type,
    String? message,
    FeedbackStatus? status,
    String? response,
    bool? isAnonymous,
    DateTime? createdAt,
  }) => Feedback(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    type: type ?? this.type,
    message: message ?? this.message,
    status: status ?? this.status,
    response: response ?? this.response,
    isAnonymous: isAnonymous ?? this.isAnonymous,
    createdAt: createdAt ?? this.createdAt,
  );
}

enum ContentType { lesson, video, pdf, assignment, quiz }

class LMSContent {
  final String id;
  final String classId;
  final ContentType type;
  final String title;
  final String? url;
  final String? content;
  final int order;
  final bool isPublished;
  final DateTime createdAt;

  LMSContent({
    required this.id,
    required this.classId,
    required this.type,
    required this.title,
    this.url,
    this.content,
    required this.order,
    required this.isPublished,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'classId': classId,
    'type': type.name,
    'title': title,
    'url': url,
    'content': content,
    'order': order,
    'isPublished': isPublished,
    'createdAt': createdAt.toIso8601String(),
  };

  factory LMSContent.fromJson(Map<String, dynamic> json) => LMSContent(
    id: json['id'] as String,
    classId: json['classId'] as String,
    type: ContentType.values.firstWhere((e) => e.name == json['type']),
    title: json['title'] as String,
    url: json['url'] as String?,
    content: json['content'] as String?,
    order: json['order'] as int,
    isPublished: json['isPublished'] as bool,
    createdAt: DateTime.parse(json['createdAt']),
  );

  LMSContent copyWith({
    String? id,
    String? classId,
    ContentType? type,
    String? title,
    String? url,
    String? content,
    int? order,
    bool? isPublished,
    DateTime? createdAt,
  }) => LMSContent(
    id: id ?? this.id,
    classId: classId ?? this.classId,
    type: type ?? this.type,
    title: title ?? this.title,
    url: url ?? this.url,
    content: content ?? this.content,
    order: order ?? this.order,
    isPublished: isPublished ?? this.isPublished,
    createdAt: createdAt ?? this.createdAt,
  );
}
