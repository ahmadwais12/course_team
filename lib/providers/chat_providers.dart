import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:course_emis/models/chat_models.dart';
import 'package:course_emis/services/chat_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  final service = ChatService();
  ref.onDispose(() => service.dispose());
  return service;
});

final chatGroupsProvider = StreamProvider<List<ChatGroup>>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Stream.value([]);
  final service = ref.watch(chatServiceProvider);
  return service.streamChatGroups(userId);
});

final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>(
    (ref, groupId) {
  final service = ref.watch(chatServiceProvider);
  return service.streamMessages(groupId);
});

final currentUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

final chatProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) {
  final service = ref.watch(chatServiceProvider);
  return service.fetchProfile(userId);
});

final chatPresenceProvider =
    StreamProvider.family<bool, String>((ref, userId) {
  final service = ref.watch(chatServiceProvider);
  return service.streamPresence(userId);
});

final chatPartnerIdProvider =
    FutureProvider.family<String?, String>((ref, groupId) {
  final service = ref.watch(chatServiceProvider);
  return service.getDirectChatPartner(groupId);
});
