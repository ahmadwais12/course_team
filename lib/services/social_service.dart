import 'package:supabase_flutter/supabase_flutter.dart';

class SocialService {
  static final instance = SocialService._();
  SocialService._();

  final _supabase = Supabase.instance.client;

  // Forums
  Future<List<Map<String, dynamic>>> getForumPosts({String? category}) async {
    if (category != null) {
      final data = await _supabase
          .from('forum_posts')
          .select('*, author:students(name, avatar)')
          .eq('category', category)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    }

    final data = await _supabase
        .from('forum_posts')
        .select('*, author:students(name, avatar)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> createPost(String title, String content, String category) async {
    await _supabase.from('forum_posts').insert({
      'title': title,
      'content': content,
      'category': category,
      'author_id': _supabase.auth.currentUser!.id,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Study groups
  Future<List<Map<String, dynamic>>> getStudyGroups() async {
    return List<Map<String, dynamic>>.from(
      await _supabase
          .from('study_groups')
          .select('*, members:study_group_members(count)')
          .order('created_at', ascending: false),
    );
  }

  Future<void> joinGroup(String groupId) async {
    await _supabase.from('study_group_members').insert({
      'group_id': groupId,
      'student_id': _supabase.auth.currentUser!.id,
      'joined_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> leaveGroup(String groupId) async {
    await _supabase
        .from('study_group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('student_id', _supabase.auth.currentUser!.id);
  }

  // Peer messaging
  Future<List<Map<String, dynamic>>> getConversations() async {
    final userId = _supabase.auth.currentUser!.id;
    return List<Map<String, dynamic>>.from(
      await _supabase
          .from('conversations')
          .select('*, other_user:students!conversations_user2_id_fkey(name, avatar)')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('last_message_at', ascending: false),
    );
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    return List<Map<String, dynamic>>.from(
      await _supabase
          .from('messages')
          .select('*')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true),
    );
  }

  Future<void> sendMessage(String conversationId, String content) async {
    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': _supabase.auth.currentUser!.id,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });

    await _supabase.from('conversations').update({
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);
  }
}
