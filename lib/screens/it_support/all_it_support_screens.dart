import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class ITAssetsScreen extends StatelessWidget {
  const ITAssetsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'IT Assets',
        tableName: 'it_devices',
        icon: Icons.devices_rounded,
        accentColor: Colors.blueGrey,
        displayFields: ['name', 'device_type', 'status', 'serial_number'],
      );
}

class SystemStatusScreen extends StatelessWidget {
  const SystemStatusScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'System Status',
        tableName: 'alerts',
        icon: Icons.dns_rounded,
        accentColor: Colors.blue,
        displayFields: ['title', 'severity', 'is_active', 'message'],
      );
}

class NetworkMonitoringScreen extends StatelessWidget {
  const NetworkMonitoringScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Network Monitoring',
        tableName: 'alerts',
        icon: Icons.wifi_tethering_rounded,
        accentColor: Colors.indigo,
        displayFields: ['title', 'severity', 'message', 'created_at'],
      );
}

class HelpdeskScreen extends StatelessWidget {
  const HelpdeskScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Help Desk',
        tableName: 'it_tickets',
        icon: Icons.support_agent_rounded,
        accentColor: Colors.orange,
        displayFields: ['subject', 'status', 'priority', 'created_at'],
      );
}

class IncidentLogsScreen extends StatelessWidget {
  const IncidentLogsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Incident Logs',
        tableName: 'it_tickets',
        icon: Icons.bug_report_rounded,
        accentColor: Colors.red,
        displayFields: ['subject', 'status', 'priority', 'description'],
      );
}

class SoftwareLicensesScreen extends StatelessWidget {
  const SoftwareLicensesScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Software Licenses',
        tableName: 'api_integrations',
        icon: Icons.verified_rounded,
        accentColor: Colors.purple,
        displayFields: ['name', 'provider', 'is_active', 'created_at'],
      );
}

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'User Management',
        tableName: 'users',
        icon: Icons.people_alt_rounded,
        accentColor: Colors.blue,
        displayFields: ['full_name', 'email', 'role', 'is_active'],
      );
}

class RolePermissionManagementScreen extends StatelessWidget {
  const RolePermissionManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Role & Permission Management',
        tableName: 'roles',
        icon: Icons.admin_panel_settings_rounded,
        accentColor: Colors.orange,
        displayFields: ['name', 'description', 'is_active'],
      );
}

class DatabaseBackupRestoreScreen extends StatelessWidget {
  const DatabaseBackupRestoreScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Database Backup & Restore',
        tableName: 'backups',
        icon: Icons.backup_rounded,
        accentColor: Colors.blue,
        displayFields: ['backup_type', 'status', 'created_at'],
      );
}

class SecurityAuditScreen extends StatelessWidget {
  const SecurityAuditScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Security Audit',
        tableName: 'security_logs',
        icon: Icons.security_rounded,
        accentColor: Colors.red,
        displayFields: ['log_type', 'user_id', 'ip_address', 'created_at'],
      );
}
