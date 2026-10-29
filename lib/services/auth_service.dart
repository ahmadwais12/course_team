import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/models/user.dart' as app_user;
import 'package:course_emis/services/secure_storage_service.dart';

class AuthService {
  final _client = Supabase.instance.client;
  final SecureStorageService _secureStorage;

  AuthService(this._secureStorage);

  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.session?.accessToken != null) {
      await _secureStorage.saveAccessToken(response.session!.accessToken);
      final rt = response.session!.refreshToken;
      if (rt != null && rt.isNotEmpty) {
        await _secureStorage.saveRefreshToken(rt);
      }
    }
    return response;
  }

  Future<bool> hasSavedSession() async {
    return await _secureStorage.hasTokens();
  }

  Future<void> restoreSession() async {
    final at = await _secureStorage.getAccessToken();
    final rt = await _secureStorage.getRefreshToken();
    if (at != null && at.isNotEmpty) {
      try {
        final currentSession = _client.auth.currentSession;
        if (currentSession == null) {
          final json = rt != null && rt.isNotEmpty
              ? "{\"access_token\":\"$at\",\"refresh_token\":\"$rt\"}"
              : "{\"access_token\":\"$at\"}";
          await _client.auth.setSession(json);
        }
      } catch (_) {
        await _secureStorage.clearTokens();
      }
    }
  }

  Future<AuthResponse> signUp(String email, String password, {
    required String fullName,
    required String phoneNumber,
    required app_user.UserRole role,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone_number': phoneNumber,
        'role': role.name,
      },
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    await _secureStorage.clearTokens();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}

final authServiceProvider = Provider((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return AuthService(secureStorage);
});
