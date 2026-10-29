import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class TwoFactorService {
  static final instance = TwoFactorService._();
  TwoFactorService._();

  final _supabase = Supabase.instance.client;
  final _otpCache = <String, OTPData>{};

  // Enable 2FA for user
  Future<String> enable2FA() async {
    final userId = _supabase.auth.currentUser!.id;
    final secret = _generateSecret();

    await _supabase.from('user_2fa').upsert({
      'user_id': userId,
      'secret': secret,
      'enabled': true,
      'created_at': DateTime.now().toIso8601String(),
    });

    return secret;
  }

  // Disable 2FA
  Future<void> disable2FA() async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('user_2fa').update({'enabled': false}).eq('user_id', userId);
  }

  // Generate OTP
  Future<String> generateOTP(String userId) async {
    final otp = _generateOTPCode();
    _otpCache[userId] = OTPData(otp, DateTime.now().add(const Duration(minutes: 5)));

    // In production, send via SMS/Email
    return otp;
  }

  // Verify OTP
  Future<bool> verifyOTP(String userId, String otp) async {
    final cached = _otpCache[userId];
    if (cached == null || cached.isExpired) {
      return false;
    }

    if (cached.code == otp) {
      _otpCache.remove(userId);
      return true;
    }

    return false;
  }

  // Check if 2FA is enabled
  Future<bool> is2FAEnabled(String userId) async {
    final data = await _supabase
        .from('user_2fa')
        .select('enabled')
        .eq('user_id', userId)
        .maybeSingle();

    return data?['enabled'] ?? false;
  }

  String _generateSecret() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  String _generateOTPCode() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }
}

class OTPData {
  final String code;
  final DateTime expiresAt;

  OTPData(this.code, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
