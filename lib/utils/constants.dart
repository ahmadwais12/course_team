class AppConstants {
  static const String appName = 'Ahmad Wais Sarwari';
  static const String appVersion = '1.0.0';
  static const int pageSize = 20;
  static const int minPasswordLength = 6;
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration debounceDelay = Duration(milliseconds: 300);
  static const int maxFileSize = 10 * 1024 * 1024;
  static const String networkError = 'Network error. Please check your connection.';
  static const String saveSuccess = 'Saved successfully!';
}

class AppConfig {
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static String get apiUrl => isProduction ? 'https://api.dreamflow.com' : 'http://localhost:3000';
}
