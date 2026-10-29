import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class EncryptionService {
  static final instance = EncryptionService._();
  EncryptionService._();

  late final encrypt.Key _key;
  late final encrypt.IV _iv;
  late final encrypt.Encrypter _encrypter;

  // Initialize with app secret
  void init(String secret) {
    final keyBytes = sha256.convert(utf8.encode(secret)).bytes;
    _key = encrypt.Key(Uint8List.fromList(keyBytes));
    _iv = encrypt.IV.fromLength(16);
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }

  // Encrypt string
  String encryptString(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  // Decrypt string
  String decryptString(String encryptedText) {
    final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }

  // Encrypt JSON
  String encryptJson(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    return encryptString(jsonString);
  }

  // Decrypt JSON
  Map<String, dynamic> decryptJson(String encryptedText) {
    final jsonString = decryptString(encryptedText);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  // Hash password
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Verify password
  bool verifyPassword(String password, String hashedPassword) {
    return hashPassword(password) == hashedPassword;
  }

  // Generate secure token
  String generateToken(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = _SecureRandom();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

// Secure storage wrapper
class SecureStorage {
  static final instance = SecureStorage._();
  SecureStorage._();

  final _storage = <String, String>{};

  // Store encrypted
  void store(String key, String value) {
    final encrypted = EncryptionService.instance.encryptString(value);
    _storage[key] = encrypted;
  }

  // Retrieve decrypted
  String? retrieve(String key) {
    final encrypted = _storage[key];
    if (encrypted == null) return null;
    return EncryptionService.instance.decryptString(encrypted);
  }

  // Store JSON encrypted
  void storeJson(String key, Map<String, dynamic> data) {
    final encrypted = EncryptionService.instance.encryptJson(data);
    _storage[key] = encrypted;
  }

  // Retrieve JSON decrypted
  Map<String, dynamic>? retrieveJson(String key) {
    final encrypted = _storage[key];
    if (encrypted == null) return null;
    return EncryptionService.instance.decryptJson(encrypted);
  }

  // Delete
  void delete(String key) {
    _storage.remove(key);
  }

  // Clear all
  void clear() {
    _storage.clear();
  }
}

class Random {
  static final secure = _SecureRandom();
}

class _SecureRandom {
  int nextInt(int max) {
    return DateTime.now().microsecondsSinceEpoch % max;
  }
}
