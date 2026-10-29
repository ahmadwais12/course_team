import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  SecureStorageService(this._storage);

  static const _accessTokenKey = 'supabase_access_token';
  static const _refreshTokenKey = 'supabase_refresh_token';
  static const _impersonationSessionKey = 'impersonation_session';

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<bool> hasTokens() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  // --- Impersonation session (dual identity) ---
  Future<void> writeSession(Map<String, dynamic> json) async {
    await _storage.write(
        key: _impersonationSessionKey, value: jsonEncode(json));
  }

  Future<String?> readSession() async {
    return await _storage.read(key: _impersonationSessionKey);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _impersonationSessionKey);
  }
}

final secureStorageServiceProvider = Provider((ref) {
  return SecureStorageService(const FlutterSecureStorage());
});
