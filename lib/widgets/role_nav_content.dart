import 'package:flutter/material.dart';

import 'package:course_emis/screens/settings_screen.dart';
import 'package:course_emis/screens/chat_screen.dart';
import 'package:course_emis/screens/attendance_screen.dart';
import 'package:course_emis/screens/notifications_screen.dart';
import 'package:course_emis/screens/students_screen.dart';
import 'package:course_emis/screens/teachers_screen.dart';
import 'package:course_emis/screens/staff/all_staff_screens.dart';

/// Builds navigation content based on user role and selected index
/// Used by the main navigation scaffold for role-based UI
class RoleNavContent {
  static Widget build(BuildContext context, String role, int index) {
    switch (role) {
      case 'super_admin':
        return _buildSuperAdminContent(context, index);
      case 'admin':
        return _buildAdminContent(context, index);
      case 'teacher':
        return _buildTeacherContent(context, index);

      case 'accountant':
        return _buildAccountantContent(context, index);
      case 'librarian':
        return _buildLibrarianContent(context, index);
      case 'receptionist':
        return _buildReceptionistContent(context, index);
      case 'hr_manager':
        return _buildHRManagerContent(context, index);
      case 'inventory_manager':
        return _buildInventoryManagerContent(context, index);
      case 'it_support':
        return _buildITSupportContent(context, index);
      case 'maintenance':
        return _buildMaintenanceContent(context, index);
      case 'event_manager':
        return _buildEventManagerContent(context, index);
      case 'complaint_manager':
        return _buildComplaintManagerContent(context, index);
      case 'staff':
        return _buildStaffContent(context, index);
      default:
        return _buildDefaultContent(context, index);
    }
  }

  // Super Admin
  static Widget _buildSuperAdminContent(BuildContext context, int index) {
    switch (index) {
      case 1:
        return _buildPlaceholder(
            context, 'Messages', Icons.chat_bubble_outline);
      case 2:
        return _buildPlaceholder(
            context, 'User Management', Icons.people_rounded);
      case 3:
        return _buildPlaceholder(
            context, 'Courses Management', Icons.business_rounded);
      case 4:
        return const SettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  // Admin
  static Widget _buildAdminContent(BuildContext context, int index) {
    switch (index) {
      case 1:
        return const StudentsScreen();
      case 2:
        return const TeachersScreen();
      case 3:
        return _buildPlaceholder(
            context, 'Payment Management', Icons.payments_rounded);
      case 4:
        return _buildPlaceholder(
            context, 'Reports & Analytics', Icons.bar_chart_rounded);
      default:
        return const SizedBox.shrink();
    }
  }

  // Teacher
  static Widget _buildTeacherContent(BuildContext context, int index) {
    switch (index) {
      case 1:
        return AttendanceScreen();
      case 2:
        return _buildPlaceholder(
            context, 'Homework Management', Icons.assignment_rounded);
      case 3:
        return _buildPlaceholder(context, 'Exam Results', Icons.grade_rounded);
      case 4:
        return _buildPlaceholder(
            context, 'Student Groups', Icons.groups_rounded);
      default:
        return const SizedBox.shrink();
    }
  }

  // Accountant
  static Widget _buildAccountantContent(BuildContext context, int index) {
    switch (index) {
      case 1:
        return const StaffAccountantScreen();
      case 2:
        return _buildPlaceholder(
            context, 'Invoices', Icons.receipt_long_rounded);
      case 3:
        return _buildPlaceholder(
            context, 'Accounts', Icons.account_balance_rounded);
      case 4:
        return _buildPlaceholder(
            context, 'Financial Reports', Icons.bar_chart_rounded);
      default:
        return const SizedBox.shrink();
    }
  }

  // Librarian
  static Widget _buildLibrarianContent(BuildContext context, int index) {
    switch (index) {
      case 1:
        return const StaffLibrarianScreen();
      case 2:
        return _buildPlaceholder(
            context, 'Issue/Return Books', Icons.swap_horiz_rounded);
      case 3:
        return _buildPlaceholder(
            context, 'Borrowing History', Icons.history_rounded);
      case 4:
        return _buildPlaceholder(context, 'Book Catalog', Icons.search_rounded);
      default:
        return const SizedBox.shrink();
    }
  }

  // Receptionist
  static Widget _buildReceptionistContent(BuildContext context, int index) {
    switch (index) {
      case 1:
        return const StaffFrontDeskScreen();
      case 2:
        return _buildPlaceholder(
            context, 'Visitor Logs', Icons.assignment_ind_rounded);
      case 3:
        return _buildPlaceholder(
            context, 'Call Management', Icons.phone_rounded);
      case 4:
        return _buildPlaceholder(
            context, 'Appointments', Icons.schedule_rounded);
      default:
        return const SizedBox.shrink();
    }
  }

  // HR Manager
  static Widget _buildHRManagerContent(BuildContext context, int index) {
    switch (index) {
      case 1:
        return const StaffHRScreen();
      case 2:
        return _buildPlaceholder(context, 'Recruitment', Icons.work_rounded);
      case 3:
        return _buildPlaceholder(
            context, 'Leave Management', Icons.event_available_rounded);
      case 4:
        return _buildPlaceholder(
            context, 'Performance Reviews', Icons.assessment_rounded);
      default:
        return const SizedBox.shrink();
    }
  }

  // Inventory Manager
  static Widget _buildInventoryManagerContent(BuildContext context, int index) {
    switch (index) {
      case 1:
        return const StaffInventoryManagerScreen();
      case 2:
        return _buildPlaceholder(
            context, 'Purchase Orders', Icons.add_shopping_cart_rounded);
      case 3:
        return _buildPlaceholder(
            context, 'Issue Items', Icons.remove_shopping_cart_rounded);
      case 4:
        return _buildPlaceholder(
            context, 'Inventory Reports', Icons.assessment_rounded);
      default:
        return const SizedBox.shrink();
    }
  }

  // IT Support
  static Widget _buildITSupportContent(BuildContext context, int index) {
    switch (index) {
      case 1:
        return const StaffITSupportScreen();
      case 2:
        return _buildPlaceholder(
            context, 'Device Management', Icons.computer_rounded);
      case 3:
        return _buildPlaceholder(
            context, 'Network Status', Icons.network_check_rounded);
      case 4:
        return _buildPlaceholder(
            context, 'Server Management', Icons.storage_rounded);
      default:
        return const SizedBox.shrink();
    }
  }

  // Maintenance
  static Widget _buildMaintenanceContent(BuildContext context, int index) {
    switch (index) {
      case 1:
        return const StaffMaintenanceScreen();
      case 2:
        return _buildPlaceholder(
            context, 'Maintenance Tasks', Icons.task_alt_rounded);
      case 3:
        return _buildPlaceholder(
            context, 'Work Schedule', Icons.schedule_rounded);
      case 4:
        return _buildPlaceholder(
            context, 'Completed Jobs', Icons.assignment_turned_in_rounded);
      default:
        return const SizedBox.shrink();
    }
  }

  // Event Manager
  static Widget _buildEventManagerContent(BuildContext context, int index) {
    switch (index) {
      case 1:
        return const StaffEventCoordinatorScreen();
      case 2:
        return _buildPlaceholder(
            context, 'Event Calendar', Icons.calendar_month_rounded);
      case 3:
        return _buildPlaceholder(
            context, 'Attendee List', Icons.people_rounded);
      case 4:
        return _buildPlaceholder(
            context, 'Venue Management', Icons.location_city_rounded);
      default:
        return const SizedBox.shrink();
    }
  }

  // Complaint Manager
  static Widget _buildComplaintManagerContent(BuildContext context, int index) {
    switch (index) {
      case 1:
        return const StaffComplaintManagerScreen();
      case 2:
        return _buildPlaceholder(
            context, 'Pending Complaints', Icons.pending_rounded);
      case 3:
        return _buildPlaceholder(
            context, 'Resolved Complaints', Icons.check_circle_rounded);
      case 4:
        return _buildPlaceholder(
            context, 'Complaint Analytics', Icons.analytics_rounded);
      default:
        return const SizedBox.shrink();
    }
  }

  // Staff (Generic)
  static Widget _buildStaffContent(BuildContext context, int index) {
    switch (index) {
      case 1:
        return AttendanceScreen();
      case 2:
        return _buildPlaceholder(context, 'My Tasks', Icons.task_rounded);
      case 3:
        return const ChatScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  // Default
  static Widget _buildDefaultContent(BuildContext context, int index) {
    switch (index) {
      case 1:
        return _buildPlaceholder(context, 'Profile', Icons.person_rounded);
      case 2:
        return NotificationsScreen();
      case 3:
        return const SettingsScreen();
      case 4:
        return _buildPlaceholder(context, 'Help & Support', Icons.help_rounded);
      default:
        return const SizedBox.shrink();
    }
  }

  // Helper
  static Widget _buildPlaceholder(
      BuildContext context, String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
