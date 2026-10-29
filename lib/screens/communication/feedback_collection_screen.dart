import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class FeedbackCollectionScreen extends StatelessWidget {
  const FeedbackCollectionScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Feedback Collection',
        tableName: 'feedback',
        icon: Icons.feedback_outlined,
        accentColor: Colors.teal,
        displayFields: ['title', 'rating', 'comment', 'created_at'],
      );
}
