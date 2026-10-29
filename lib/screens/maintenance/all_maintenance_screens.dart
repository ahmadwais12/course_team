import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class MaintenanceScheduleScreen extends StatelessWidget {
  const MaintenanceScheduleScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Maintenance Schedule',
        tableName: 'maintenance_tasks',
        icon: Icons.calendar_month_rounded,
        accentColor: Colors.blue,
        displayFields: ['title', 'status', 'scheduled_date', 'assigned_to'],
      );
}

class WorkOrdersScreen extends StatelessWidget {
  const WorkOrdersScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Work Orders',
        tableName: 'work_orders',
        icon: Icons.assignment_rounded,
        accentColor: Colors.orange,
        displayFields: ['title', 'status', 'priority', 'created_at'],
      );
}

class EquipmentStatusScreen extends StatelessWidget {
  const EquipmentStatusScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Equipment Status',
        tableName: 'inspections',
        icon: Icons.engineering_rounded,
        accentColor: Colors.teal,
        displayFields: ['title', 'status', 'location', 'score'],
      );
}

class MaintenanceLogsScreen extends StatelessWidget {
  const MaintenanceLogsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Maintenance Logs',
        tableName: 'maintenance_requests',
        icon: Icons.history_edu_rounded,
        accentColor: Colors.brown,
        displayFields: ['title', 'status', 'description', 'created_at'],
      );
}

class VendorsScreen extends StatelessWidget {
  const VendorsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Vendors',
        tableName: 'suppliers',
        icon: Icons.business_center_rounded,
        accentColor: Colors.deepPurple,
        displayFields: ['name', 'phone', 'email', 'is_active'],
      );
}
