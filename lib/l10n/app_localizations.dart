import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations_en.dart';
import 'app_localizations_prs.dart';
import 'app_localizations_ps.dart';

final localeProvider =
    StateNotifierProvider<LocaleNotifier, String>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<String> {
  LocaleNotifier([String? initial]) : super(initial ?? 'en') {
    // Only auto-load from storage when no initial value was supplied
    // (main() pre-seeds the saved value via provider overrides).
    if (initial == null) {
      _loadSavedLocale();
    }
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('app_locale');
      if (saved != null && _supportedLocales.contains(saved)) {
        state = saved;
      }
    } catch (e) {
      debugPrint('[LocaleNotifier] _loadSavedLocale error: $e');
    }
  }

  Future<void> setLocale(String locale) async {
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_locale', locale);
    } catch (e) {
      debugPrint('[LocaleNotifier] setLocale save error: $e');
    }
  }
}

const _supportedLocales = {'en', 'fa', 'prs', 'ps'};

/// RTL locale codes
const _rtlLocales = {'ps', 'fa', 'prs'};

/// Whether the current locale is RTL
final isRtlProvider = Provider<bool>((ref) {
  final locale = ref.watch(localeProvider);
  return _rtlLocales.contains(locale);
});

/// TextDirection for the current locale
final textDirectionProvider = Provider<TextDirection>((ref) {
  final locale = ref.watch(localeProvider);
  return _rtlLocales.contains(locale) ? TextDirection.rtl : TextDirection.ltr;
});

/// Helper to translate with locale from ref for non-WidgetRef contexts
String translate(String key, String locale) {
  return AppLocalizations.translate(key, locale);
}

class AppLocalizations {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': AppLocalizationsEn.values,
    'fa': AppLocalizationsPrs.values,
    'prs': AppLocalizationsPrs.values,
    'ps': AppLocalizationsPs.values,
  };

  static String translate(String key, String locale) {
    return _localizedValues[locale]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  /// Translates a key and replaces `{x}` placeholders with the given values in order.
  static String translateWith(String key, String locale, [List<String>? args]) {
    var result = translate(key, locale);
    if (args != null) {
      for (var i = 0; i < args.length; i++) {
        result = result.replaceFirst('{x}', args[i]);
      }
    }
    return result;
  }
}
