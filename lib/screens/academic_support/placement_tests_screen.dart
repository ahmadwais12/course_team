import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class PlacementTestsScreen extends StatelessWidget {
  const PlacementTestsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Placement Tests',
        tableName: 'test_attempts',
        icon: Icons.quiz_rounded,
        accentColor: Colors.blue,
        displayFields: ['student_id', 'score', 'status', 'started_at'],
      );
}
