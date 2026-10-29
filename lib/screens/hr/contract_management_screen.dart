import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class ContractManagementScreen extends StatelessWidget {
  const ContractManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Contract Management',
        tableName: 'hr_records',
        icon: Icons.description_rounded,
        accentColor: Colors.indigo,
        displayFields: ['title', 'record_type', 'effective_date', 'employee_id'],
      );
}
