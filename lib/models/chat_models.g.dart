// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatGroup _$ChatGroupFromJson(Map<String, dynamic> json) => ChatGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      createdBy: json['createdBy'] as String?,
      classId: json['classId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => ChatGroupMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastMessage: json['lastMessage'] == null
          ? null
          : ChatMessage.fromJson(json['lastMessage'] as Map<String, dynamic>),
      unreadCount: (json['unreadCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ChatGroupToJson(ChatGroup instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': instance.type,
      'createdBy': instance.createdBy,
      'classId': instance.classId,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'members': instance.members,
      'lastMessage': instance.lastMessage,
      'unreadCount': instance.unreadCount,
    };

ChatGroupMember _$ChatGroupMemberFromJson(Map<String, dynamic> json) =>
    ChatGroupMember(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      userId: json['userId'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      userName: json['userName'] as String?,
      userAvatar: json['userAvatar'] as String?,
    );

Map<String, dynamic> _$ChatGroupMemberToJson(ChatGroupMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'userId': instance.userId,
      'role': instance.role,
      'joinedAt': instance.joinedAt.toIso8601String(),
      'userName': instance.userName,
      'userAvatar': instance.userAvatar,
    };

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      senderId: json['senderId'] as String,
      messageType: json['messageType'] as String,
      content: json['content'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      replyTo: json['replyTo'] as String?,
      isEdited: json['isEdited'] as bool? ?? false,
      editedAt: json['editedAt'] == null
          ? null
          : DateTime.parse(json['editedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      senderName: json['senderName'] as String?,
      senderAvatar: json['senderAvatar'] as String?,
      reactions: (json['reactions'] as List<dynamic>?)
          ?.map((e) => ChatMessageReaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      isRead: json['isRead'] as bool?,
    );

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'senderId': instance.senderId,
      'messageType': instance.messageType,
      'content': instance.content,
      'fileUrl': instance.fileUrl,
      'fileName': instance.fileName,
      'fileSize': instance.fileSize,
      'replyTo': instance.replyTo,
      'isEdited': instance.isEdited,
      'editedAt': instance.editedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'senderName': instance.senderName,
      'senderAvatar': instance.senderAvatar,
      'reactions': instance.reactions,
      'isRead': instance.isRead,
    };

ChatMessageReaction _$ChatMessageReactionFromJson(Map<String, dynamic> json) =>
    ChatMessageReaction(
      id: json['id'] as String,
      messageId: json['messageId'] as String,
      userId: json['userId'] as String,
      reaction: json['reaction'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      userName: json['userName'] as String?,
    );

Map<String, dynamic> _$ChatMessageReactionToJson(
        ChatMessageReaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'messageId': instance.messageId,
      'userId': instance.userId,
      'reaction': instance.reaction,
      'createdAt': instance.createdAt.toIso8601String(),
      'userName': instance.userName,
    };

CallLog _$CallLogFromJson(Map<String, dynamic> json) => CallLog(
      id: json['id'] as String,
      groupId: json['groupId'] as String?,
      callerId: json['callerId'] as String,
      callType: json['callType'] as String,
      status: json['status'] as String,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      participants: (json['participants'] as List<dynamic>?)
          ?.map((e) => CallParticipant.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CallLogToJson(CallLog instance) => <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'callerId': instance.callerId,
      'callType': instance.callType,
      'status': instance.status,
      'duration': instance.duration,
      'startedAt': instance.startedAt?.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'participants': instance.participants,
    };

CallParticipant _$CallParticipantFromJson(Map<String, dynamic> json) =>
    CallParticipant(
      id: json['id'] as String,
      callId: json['callId'] as String,
      userId: json['userId'] as String,
      joinedAt: json['joinedAt'] == null
          ? null
          : DateTime.parse(json['joinedAt'] as String),
      leftAt: json['leftAt'] == null
          ? null
          : DateTime.parse(json['leftAt'] as String),
      status: json['status'] as String,
      userName: json['userName'] as String?,
      userAvatar: json['userAvatar'] as String?,
    );

Map<String, dynamic> _$CallParticipantToJson(CallParticipant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'callId': instance.callId,
      'userId': instance.userId,
      'joinedAt': instance.joinedAt?.toIso8601String(),
      'leftAt': instance.leftAt?.toIso8601String(),
      'status': instance.status,
      'userName': instance.userName,
      'userAvatar': instance.userAvatar,
    };
