import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class StaffAttendanceScreen extends StatelessWidget {
  const StaffAttendanceScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Staff Attendance',
        tableName: 'staff_attendance',
        icon: Icons.fingerprint_rounded,
        accentColor: Colors.orange,
        displayFields: ['staff_id', 'date', 'status', 'check_in', 'check_out'],
      );
}

class ContractsScreen extends StatelessWidget {
  const ContractsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Contracts',
        tableName: 'hr_records',
        icon: Icons.description_rounded,
        accentColor: Colors.indigo,
        displayFields: ['title', 'record_type', 'effective_date', 'details'],
      );
}

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Performance',
        tableName: 'performance_reviews',
        icon: Icons.trending_up_rounded,
        accentColor: Colors.pink,
        displayFields: ['review_period', 'rating', 'status', 'comments'],
      );
}

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Training',
        tableName: 'trainings',
        icon: Icons.school_rounded,
        accentColor: Colors.red,
        displayFields: ['title', 'start_date', 'end_date', 'status'],
      );
}

class OnboardingStaffScreen extends StatelessWidget {
  const OnboardingStaffScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Onboarding',
        tableName: 'job_applications',
        icon: Icons.person_add_alt_1_rounded,
        accentColor: Colors.cyan,
        displayFields: ['applicant_name', 'status', 'applied_date', 'email'],
      );
}
