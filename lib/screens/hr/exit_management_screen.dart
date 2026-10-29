import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class ExitManagementScreen extends StatelessWidget {
  const ExitManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Exit Management',
        tableName: 'hr_records',
        icon: Icons.exit_to_app_rounded,
        accentColor: Colors.brown,
        displayFields: ['title', 'record_type', 'effective_date', 'details'],
      );
}
