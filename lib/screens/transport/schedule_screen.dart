import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Transport Schedule',
        tableName: 'trips',
        icon: Icons.schedule_rounded,
        accentColor: Colors.deepOrange,
        displayFields: ['title', 'destination', 'departure_at', 'status'],
      );
}
