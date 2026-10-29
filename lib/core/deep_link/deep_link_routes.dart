import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_routes_all.dart';
import 'models/deep_link_data.dart';

/// Handles navigation based on deep link data
class DeepLinkRoutes {
  /// Navigate using GoRouter (preferred)
  static void navigate(DeepLinkData data) {
    // This is a placeholder - actual navigation requires context
    // Use navigateWithContext in widgets
    debugPrint('Navigate to: ${data.type} with id: ${data.id}');
  }

  /// Navigate with BuildContext
  static void navigateWithContext(BuildContext context, DeepLinkData data) {
    switch (data.type) {
      case DeepLinkType.student:
        _navigateToUnknown(context, data);
        break;
      case DeepLinkType.teacher:
        _navigateToTeacher(context, data);
        break;
      case DeepLinkType.staff:
        _navigateToStaff(context, data);
        break;
      case DeepLinkType.payment:
      case DeepLinkType.invoice:
      case DeepLinkType.receipt:
        _navigateToPayment(context, data);
        break;
      case DeepLinkType.announcement:
        _navigateToAnnouncement(context, data);
        break;
      case DeepLinkType.event:
        _navigateToEvent(context, data);
        break;
      case DeepLinkType.attendance:
        _navigateToAttendance(context, data);
        break;
      case DeepLinkType.grade:
        _navigateToGrade(context, data);
        break;
      case DeepLinkType.course:
        _navigateToCourse(context, data);
        break;
      case DeepLinkType.classInfo:
        _navigateToClass(context, data);
        break;
      case DeepLinkType.profile:
        _navigateToProfile(context, data);
        break;
      case DeepLinkType.settings:
        _navigateToSettings(context, data);
        break;
      case DeepLinkType.notification:
        _navigateToNotifications(context, data);
        break;
      case DeepLinkType.unknown:
        _navigateToUnknown(context, data);
        break;
    }
  }

  static void _navigateToTeacher(BuildContext context, DeepLinkData data) {
    if (!data.hasValidId) {
      context.go(AppRoutesAll.teacherPanel);
      return;
    }
    context.go('${AppRoutesAll.teacherPanel}?teacherId=${data.id}');
  }

  static void _navigateToStaff(BuildContext context, DeepLinkData data) {
    if (!data.hasValidId) {
      context.go(AppRoutesAll.staffPanel);
      return;
    }
    context.go('${AppRoutesAll.staffPanel}?staffId=${data.id}');
  }

  static void _navigateToPayment(BuildContext context, DeepLinkData data) {
    if (!data.hasValidId) {
      context.go(AppRoutesAll.payments);
      return;
    }

    // Check for specific payment types
    final isInvoice = data.id!.toUpperCase().startsWith('INV-') ||
        data.type == DeepLinkType.invoice;
    final isReceipt = data.id!.toUpperCase().startsWith('REC-') ||
        data.type == DeepLinkType.receipt;

    if (isInvoice) {
      context.go('${AppRoutesAll.payments}?invoiceId=${data.id}');
    } else if (isReceipt) {
      context.go('${AppRoutesAll.payments}?receiptId=${data.id}');
    } else {
      context.go('${AppRoutesAll.payments}?paymentId=${data.id}');
    }
  }

  static void _navigateToAnnouncement(BuildContext context, DeepLinkData data) {
    if (!data.hasValidId) {
      context.go(AppRoutesAll.noticeBoard);
      return;
    }
    context.go('${AppRoutesAll.noticeBoard}?announcementId=${data.id}');
  }

  static void _navigateToEvent(BuildContext context, DeepLinkData data) {
    if (!data.hasValidId) {
      context.go(AppRoutesAll.eventCalendar);
      return;
    }
    context.go('${AppRoutesAll.eventCalendar}?eventId=${data.id}');
  }

  static void _navigateToAttendance(BuildContext context, DeepLinkData data) {
    final date = data.queryParams['date'];
    final classId = data.queryParams['classId'] ?? data.id;

    if (classId != null) {
      context.go(
          '${AppRoutesAll.attendance}?classId=$classId${date != null ? '&date=$date' : ''}');
    } else {
      context.go(AppRoutesAll.attendance);
    }
  }

  static void _navigateToGrade(BuildContext context, DeepLinkData data) {
    final examId = data.queryParams['examId'];
    final classId = data.queryParams['classId'];

    if (data.hasValidId) {
      context.go(
          '${AppRoutesAll.grades}?studentId=${data.id}${examId != null ? '&examId=$examId' : ''}${classId != null ? '&classId=$classId' : ''}');
    } else {
      context.go(AppRoutesAll.grades);
    }
  }

  static void _navigateToCourse(BuildContext context, DeepLinkData data) {
    if (!data.hasValidId) {
      context.go(AppRoutesAll.students);
      return;
    }
    context.go('${AppRoutesAll.students}?courseId=${data.id}');
  }

  static void _navigateToClass(BuildContext context, DeepLinkData data) {
    if (!data.hasValidId) {
      context.go(AppRoutesAll.classes);
      return;
    }
    context.go('${AppRoutesAll.classes}?classId=${data.id}');
  }

  static void _navigateToProfile(BuildContext context, DeepLinkData data) {
    context.go(AppRoutesAll.profile);
  }

  static void _navigateToSettings(BuildContext context, DeepLinkData data) {
    final section = data.queryParams['section'];
    if (section != null) {
      context.go('${AppRoutesAll.settings}?section=$section');
    } else {
      context.go(AppRoutesAll.settings);
    }
  }

  static void _navigateToNotifications(
      BuildContext context, DeepLinkData data) {
    context.go(AppRoutesAll.notifications);
  }

  static void _navigateToUnknown(BuildContext context, DeepLinkData data) {
    debugPrint('Unknown deep link: ${data.rawUrl}');
    // Could show a toast or redirect to home
    context.go(AppRoutesAll.home);
  }
}
