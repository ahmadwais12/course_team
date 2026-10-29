import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class ComplaintDetailsScreen extends StatelessWidget {
  const ComplaintDetailsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Complaint Details',
        tableName: 'complaints',
        icon: Icons.report_rounded,
        accentColor: Colors.red,
        displayFields: ['subject', 'status', 'priority', 'created_at'],
      );
}

class ResolvedComplaintsScreen extends StatelessWidget {
  const ResolvedComplaintsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Resolved Complaints',
        tableName: 'complaints',
        icon: Icons.check_circle_rounded,
        accentColor: Colors.blue,
        displayFields: ['subject', 'status', 'resolved_at', 'resolution_notes'],
      );
}

class PendingReviewScreen extends StatelessWidget {
  const PendingReviewScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Pending Review',
        tableName: 'complaints',
        icon: Icons.hourglass_empty_rounded,
        accentColor: Colors.orange,
        displayFields: ['subject', 'status', 'priority', 'created_at'],
      );
}

class InvestigationScreen extends StatelessWidget {
  const InvestigationScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Investigation',
        tableName: 'complaints',
        icon: Icons.search_rounded,
        accentColor: Colors.blue,
        displayFields: ['subject', 'status', 'description', 'assigned_to'],
      );
}

class ComplaintFeedbackScreen extends StatelessWidget {
  const ComplaintFeedbackScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Feedback',
        tableName: 'feedback',
        icon: Icons.feedback_rounded,
        accentColor: Colors.purple,
        displayFields: ['title', 'rating', 'comment', 'created_at'],
      );
}
