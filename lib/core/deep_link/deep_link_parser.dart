import 'models/deep_link_data.dart';

/// Parses deep link URLs into structured data
class DeepLinkParser {
  
  /// Main parse method
  static DeepLinkData parse(String url, DeepLinkSource source) {
    try {
      // Handle custom scheme (emis://)
      if (url.startsWith('emis://')) {
        url = url.replaceFirst('emis://', 'https://emis.example.com/');
      }

      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.isEmpty) {
        return _createUnknown(url, source);
      }

      final type = _parseType(pathSegments);
      final id = _extractId(pathSegments);
      final queryParams = Map<String, String>.from(uri.queryParameters);

      return DeepLinkData(
        type: type,
        id: id,
        queryParams: queryParams,
        rawUrl: url,
        source: source,
      );
    } catch (e) {
      return _createUnknown(url, source);
    }
  }

  static DeepLinkType _parseType(List<String> segments) {
    if (segments.isEmpty) return DeepLinkType.unknown;
    
    switch (segments.first.toLowerCase()) {
      case 'student':
        return DeepLinkType.student;
      case 'teacher':
        return DeepLinkType.teacher;
      case 'staff':
        return DeepLinkType.staff;
      case 'payment':
        return DeepLinkType.payment;
      case 'invoice':
        return DeepLinkType.invoice;
      case 'receipt':
        return DeepLinkType.receipt;
      case 'announcement':
      case 'notice':
        return DeepLinkType.announcement;
      case 'event':
        return DeepLinkType.event;
      case 'attendance':
        return DeepLinkType.attendance;
      case 'grade':
      case 'grades':
        return DeepLinkType.grade;
      case 'course':
      case 'program':
        return DeepLinkType.course;
      case 'class':
        return DeepLinkType.classInfo;
      case 'notification':
        return DeepLinkType.notification;
      case 'profile':
        return DeepLinkType.profile;
      case 'settings':
        return DeepLinkType.settings;
      default:
        return DeepLinkType.unknown;
    }
  }

  static String? _extractId(List<String> segments) {
    // URL pattern: /student/123 or /payment/invoice-456
    if (segments.length >= 2) {
      return segments[1];
    }
    return null;
  }

  static DeepLinkData _createUnknown(String url, DeepLinkSource source) {
    return DeepLinkData(
      type: DeepLinkType.unknown,
      rawUrl: url,
      source: source,
    );
  }

  /// Extracts tab from query params for initial tab selection
  static String? getTab(Map<String, String> queryParams) {
    return queryParams['tab'] ?? queryParams['section'];
  }

  /// Extracts action from query params
  static String? getAction(Map<String, String> queryParams) {
    return queryParams['action'];
  }
}
