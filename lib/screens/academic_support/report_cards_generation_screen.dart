import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class ReportCardsGenerationScreen extends StatelessWidget {
  const ReportCardsGenerationScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Report Cards',
        tableName: 'transcripts',
        icon: Icons.card_membership_rounded,
        accentColor: Colors.deepPurple,
        displayFields: ['student_id', 'generated_date', 'is_official'],
      );
}
