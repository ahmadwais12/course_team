import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/services/auth_service.dart';
import 'package:course_emis/services/secure_storage_service.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isAuthenticated;
});

final hasSavedSessionProvider = FutureProvider<bool>((ref) async {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return await secureStorage.hasTokens();
});

final currentUserAvatarUrlProvider = FutureProvider.autoDispose<String?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  final data = await Supabase.instance.client
      .from('users')
      .select('avatar_url')
      .eq('id', user.id)
      .maybeSingle();
  return data?['avatar_url']?.toString();
});
