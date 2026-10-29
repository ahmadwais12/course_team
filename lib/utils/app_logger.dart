import 'package:flutter/foundation.dart';
import 'dart:developer' as dev;

/// Lightweight app-wide logging helper.
///
/// Prefixes every message with a tag, so chat / upload / call issues can be
/// filtered in Logcat / console. Use [log], [w] and [e] consistently in
/// service and screen code paths that touch the network or the database.
///
/// Every call also prints via [debugPrint] so messages appear in raw
/// `adb logcat` output (dart:developer log() alone is VM-service only).
class AppLogger {
  AppLogger._();

  static const String defaultTag = 'EMIS';

  static void log(String message, {String tag = defaultTag}) {
    debugPrint('[$tag] $message');
    dev.log(message, name: tag);
  }

  static void w(String message, {String tag = defaultTag}) {
    debugPrint('[WARN] [$tag] $message');
    dev.log('[WARN] $message', name: tag);
  }

  static void e(String message,
      {Object? error, StackTrace? stackTrace, String tag = defaultTag}) {
    debugPrint('[ERROR] [$tag] $message${error == null ? '' : ' | $error'}');
    dev.log('[ERROR] $message${error == null ? '' : ' | $error'}',
        name: tag, error: error, stackTrace: stackTrace);
  }

  /// Logs an exception that was caught while performing a storage upload.
  static void uploadFailed(String label, Object error,
      [StackTrace? stackTrace]) {
    e('$label upload failed',
        error: error, stackTrace: stackTrace, tag: 'ChatUpload');
  }
}
