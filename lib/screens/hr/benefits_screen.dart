import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class BenefitsScreen extends StatelessWidget {
  const BenefitsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Employee Benefits',
        tableName: 'hr_records',
        icon: Icons.card_giftcard_rounded,
        accentColor: Colors.purple,
        displayFields: ['title', 'record_type', 'effective_date', 'details'],
      );
}
