export 'app_localizations.dart';
export 'keys.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_localizations.dart';

/// Helper to translate with locale from ref
String t(String key, WidgetRef ref) {
  final locale = ref.watch(localeProvider);
  return AppLocalizations.translate(key, locale);
}

/// Helper to translate with `{x}` placeholder substitution
String tt(String key, WidgetRef ref, [List<String>? args]) {
  final locale = ref.watch(localeProvider);
  return AppLocalizations.translateWith(key, locale, args);
}
