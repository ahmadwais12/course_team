enum MessageType { text, image, file, announcement }

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String receiverId;
  final String receiverName;
  final MessageType type;
  final String content;
  final String? fileUrl;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.receiverId,
    required this.receiverName,
    required this.type,
    required this.content,
    this.fileUrl,
    required this.isRead,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'senderRole': senderRole,
    'receiverId': receiverId,
    'receiverName': receiverName,
    'type': type.name,
    'content': content,
    'fileUrl': fileUrl,
    'isRead': isRead,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    senderId: json['senderId'] as String,
    senderName: json['senderName'] as String,
    senderRole: json['senderRole'] as String,
    receiverId: json['receiverId'] as String,
    receiverName: json['receiverName'] as String,
    type: MessageType.values.firstWhere((e) => e.name == json['type']),
    content: json['content'] as String,
    fileUrl: json['fileUrl'] as String?,
    isRead: json['isRead'] as bool,
    createdAt: DateTime.parse(json['createdAt']),
  );

  Message copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? receiverId,
    String? receiverName,
    MessageType? type,
    String? content,
    String? fileUrl,
    bool? isRead,
    DateTime? createdAt,
  }) => Message(
    id: id ?? this.id,
    senderId: senderId ?? this.senderId,
    senderName: senderName ?? this.senderName,
    senderRole: senderRole ?? this.senderRole,
    receiverId: receiverId ?? this.receiverId,
    receiverName: receiverName ?? this.receiverName,
    type: type ?? this.type,
    content: content ?? this.content,
    fileUrl: fileUrl ?? this.fileUrl,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt ?? this.createdAt,
  );
}
