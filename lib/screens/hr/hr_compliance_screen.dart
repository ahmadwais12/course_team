import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class HRComplianceScreen extends StatelessWidget {
  const HRComplianceScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'HR Compliance',
        tableName: 'inspections',
        icon: Icons.gavel_rounded,
        accentColor: Colors.blueGrey,
        displayFields: ['title', 'status', 'scheduled_at', 'findings'],
      );
}
