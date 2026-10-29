import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class ShiftManagementScreen extends StatelessWidget {
  const ShiftManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Shift Management',
        tableName: 'schedules',
        icon: Icons.schedule_rounded,
        accentColor: Colors.cyan,
        displayFields: ['title', 'day_of_week', 'start_time', 'end_time', 'status'],
      );
}
