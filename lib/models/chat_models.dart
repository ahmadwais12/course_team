import 'package:json_annotation/json_annotation.dart';

part 'chat_models.g.dart';

@JsonSerializable()
class ChatGroup {
  final String id;
  final String name;
  final String? description;
  final String type; // 'group' or 'direct'
  final String? createdBy;
  final String? classId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatGroupMember>? members;
  final ChatMessage? lastMessage;
  final int? unreadCount;

  ChatGroup({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.createdBy,
    this.classId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.members,
    this.lastMessage,
    this.unreadCount,
  });

  factory ChatGroup.fromJson(Map<String, dynamic> json) => _$ChatGroupFromJson(json);
  Map<String, dynamic> toJson() => _$ChatGroupToJson(this);
}

@JsonSerializable()
class ChatGroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String role; // 'admin' or 'member'
  final DateTime joinedAt;
  final String? userName;
  final String? userAvatar;

  ChatGroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.userName,
    this.userAvatar,
  });

  factory ChatGroupMember.fromJson(Map<String, dynamic> json) => _$ChatGroupMemberFromJson(json);
  Map<String, dynamic> toJson() => _$ChatGroupMemberToJson(this);
}

@JsonSerializable()
class ChatMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String messageType; // 'text', 'file', 'image', 'video', 'audio'
  final String? content;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? replyTo;
  final bool isEdited;
  final DateTime? editedAt;
  final DateTime createdAt;
  final String? senderName;
  final String? senderAvatar;
  final List<ChatMessageReaction>? reactions;
  final bool? isRead;

  ChatMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.messageType,
    this.content,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.replyTo,
    this.isEdited = false,
    this.editedAt,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
    this.reactions,
    this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}

@JsonSerializable()
class ChatMessageReaction {
  final String id;
  final String messageId;
  final String userId;
  final String reaction;
  final DateTime createdAt;
  final String? userName;

  ChatMessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.reaction,
    required this.createdAt,
    this.userName,
  });

  factory ChatMessageReaction.fromJson(Map<String, dynamic> json) => _$ChatMessageReactionFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageReactionToJson(this);
}

@JsonSerializable()
class CallLog {
  final String id;
  final String? groupId;
  final String callerId;
  final String callType; // 'video' or 'voice'
  final String status; // 'initiated', 'answered', 'missed', 'ended'
  final int duration; // in seconds
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final List<CallParticipant>? participants;

  CallLog({
    required this.id,
    this.groupId,
    required this.callerId,
    required this.callType,
    required this.status,
    this.duration = 0,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
    this.participants,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) => _$CallLogFromJson(json);
  Map<String, dynamic> toJson() => _$CallLogToJson(this);
}

@JsonSerializable()
class CallParticipant {
  final String id;
  final String callId;
  final String userId;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final String status; // 'invited', 'joined', 'left', 'declined'
  final String? userName;
  final String? userAvatar;

  CallParticipant({
    required this.id,
    required this.callId,
    required this.userId,
    this.joinedAt,
    this.leftAt,
    required this.status,
    this.userName,
    this.userAvatar,
  });

  factory CallParticipant.fromJson(Map<String, dynamic> json) => _$CallParticipantFromJson(json);
  Map<String, dynamic> toJson() => _$CallParticipantToJson(this);
}
