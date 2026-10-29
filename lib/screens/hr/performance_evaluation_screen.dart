import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class PerformanceEvaluationScreen extends StatelessWidget {
  const PerformanceEvaluationScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Performance Evaluation',
        tableName: 'performance_reviews',
        icon: Icons.insights_rounded,
        accentColor: Colors.pink,
        displayFields: ['review_period', 'rating', 'status', 'incentive_type'],
      );
}
