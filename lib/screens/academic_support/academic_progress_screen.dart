import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class AcademicProgressScreen extends StatelessWidget {
  const AcademicProgressScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Academic Progress',
        tableName: 'student_progress',
        icon: Icons.trending_up_rounded,
        accentColor: Colors.green,
        displayFields: ['student_id', 'subject', 'average_score', 'performance_trend'],
      );
}
