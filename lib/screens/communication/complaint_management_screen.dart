import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class ComplaintManagementScreen extends StatelessWidget {
  const ComplaintManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Complaint Management',
        tableName: 'complaints',
        icon: Icons.report_problem_rounded,
        accentColor: Colors.red,
        displayFields: ['subject', 'status', 'priority', 'created_at'],
      );
}
