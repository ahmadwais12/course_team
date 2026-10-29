import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/models/chat_models.dart';

class ChatService {
  static final ChatService _instance = ChatService._();
  ChatService._();
  factory ChatService() => _instance;

  final _client = Supabase.instance.client;
  final _channels = <String, RealtimeChannel>{};

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    return DateTime.now();
  }

  ChatGroup _buildGroup(Map<String, dynamic> json, {ChatMessage? lastMessage}) {
    return ChatGroup(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Chat',
      type: json['type'] as String? ?? 'direct',
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      description: json['description'] as String?,
      createdBy: json['created_by'] as String?,
      classId: json['class_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastMessage: lastMessage,
    );
  }

  ChatMessage _buildMessage(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      groupId: json['group_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      messageType: json['message_type'] as String? ?? 'text',
      content: json['content'] as String?,
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: (json['file_size'] as num?)?.toInt(),
      createdAt: _parseDate(json['created_at']),
      senderName: json['sender_name'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
      replyTo: json['reply_to'] as String?,
    );
  }

  Future<List<ChatGroup>> _fetchGroups(String userId) async {
    try {
      final memberships = await _client
          .from('chat_group_members')
          .select('group_id')
          .eq('user_id', userId);

      final groupIds = (memberships as List)
          .map((m) => (m as Map)['group_id'] as String)
          .toList();

      if (groupIds.isEmpty) return [];

      final groupsData = await _client
          .from('chat_groups')
          .select()
          .inFilter('id', groupIds)
          .order('updated_at', ascending: false);

      final groups = <ChatGroup>[];
      for (final g in (groupsData as List)) {
        final gMap = g as Map<String, dynamic>;

        final msgs = await _client
            .from('chat_messages')
            .select(
                'id, sender_id, content, message_type, file_url, file_name, file_size, created_at, sender_name')
            .eq('group_id', gMap['id'] as String)
            .order('created_at', ascending: false)
            .limit(1);

        ChatMessage? lastMsg;
        if ((msgs).isNotEmpty) {
          lastMsg = _buildMessage(msgs[0]);
        }

        groups.add(_buildGroup(gMap, lastMessage: lastMsg));
      }

      return groups;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ChatGroup>> fetchGroups(String userId) => _fetchGroups(userId);

  Future<void> setPresence(bool online) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('users').update({
      'is_online': online,
      'last_seen_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Stream<bool> streamPresence(String userId) {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
      final list = data as List;
      if (list.isEmpty) return false;
      return (list.first['is_online'] as bool?) ?? false;
    });
  }

  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    return await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  Future<String?> getDirectChatPartner(String groupId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final group = await _client
        .from('chat_groups')
        .select('type')
        .eq('id', groupId)
        .maybeSingle();
    if (group != null && (group['type'] as String? ?? 'direct') != 'direct') {
      return null;
    }
    final members = await _client
        .from('chat_group_members')
        .select('user_id')
        .eq('group_id', groupId)
        .neq('user_id', userId);
    if (members.isEmpty) return null;
    final ids = (members as List)
        .map((m) => m['user_id'] as String?)
        .whereType<String>()
        .toList();
    if (ids.length != 1) return null;
    return ids.first;
  }

  Future<Map<String, dynamic>?> fetchChatInfo(String groupId) async {
    return await _client
        .from('chat_groups')
        .select('id, name, type, avatar_url, description')
        .eq('id', groupId)
        .maybeSingle();
  }

  Stream<List<ChatGroup>> streamChatGroups(String userId) {
    final controller = StreamController<List<ChatGroup>>();

    _fetchGroups(userId).then((groups) {
      if (!controller.isClosed) controller.add(groups);
    }).catchError((e) {
      if (!controller.isClosed) controller.addError(e);
    });
    final channel = _client.channel('chat_groups:$userId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_group_members',
          callback: (_) async {
            final g = await _fetchGroups(userId);
            if (!controller.isClosed) controller.add(g);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (_) async {
            final g = await _fetchGroups(userId);
            if (!controller.isClosed) controller.add(g);
          },
        )
        .subscribe();
    _channels['chat_groups:$userId'] = channel;

    return controller.stream;
  }

  Stream<List<ChatMessage>> streamMessages(String groupId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at', ascending: true)
        .map((data) => (data as List)
            .map((m) => _buildMessage(m as Map<String, dynamic>))
            .toList());
  }

  Future<String> sendTextMessage({
    required String groupId,
    required String content,
    String? replyTo,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final result = await _client.from('chat_messages').insert({
      'group_id': groupId,
      'sender_id': userId,
      'content': content,
      'message_type': 'text',
      if (replyTo != null) 'reply_to': replyTo,
    }).select('id').single();

    await _client.from('chat_groups').update({
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', groupId);

    return result['id'] as String;
  }

  Future<String> createGroup({
    required String name,
    required String type,
    String? description,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client.from('chat_groups').insert({
      'name': name,
      'type': type,
      'description': description,
      'created_by': userId,
    }).select('id').single();

    final groupId = response['id'] as String;

    await _client.from('chat_group_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'role': 'admin',
    });

    return groupId;
  }

  Future<void> addGroupMembers(String groupId, List<String> userIds) async {
    final inserts = userIds.map((uid) => {
      'group_id': groupId,
      'user_id': uid,
    }).toList();
    if (inserts.isNotEmpty) {
      await _client.from('chat_group_members').insert(inserts);
    }
  }

  Future<void> leaveGroup(String groupId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    await _client
        .from('chat_group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  Future<void> fetchAndStoreUsers({
    required String groupId,
    required List<String> userIds,
  }) async {
    final users = await _client
        .from('users')
        .select('id, full_name, avatar_url')
        .inFilter('id', userIds);

    final updates = (users as List).map((u) => {
      'group_id': groupId,
      'user_id': u['id'],
      'role': 'member',
      'user_name': u['full_name'],
    }).toList();

    if (updates.isNotEmpty) {
      await _client.from('chat_group_members').upsert(updates);
    }
  }

  void dispose() {
    for (final channel in _channels.values) {
      _client.removeChannel(channel);
    }
    _channels.clear();
  }
}
