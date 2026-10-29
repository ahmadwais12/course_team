import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/ui_helpers.dart';

class StaffComplaintManagerScreen extends ConsumerWidget {
  const StaffComplaintManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: AppSpacing.paddingLg,
      children: const [
        SectionHeader(
          title: 'Complaint Manager',
          subtitle: 'Grievance redressal and feedback',
          icon: Icons.feedback_outlined,
        ),
        VSpace(AppSpacing.lg),
        StatCard(
          title: 'Unresolved Cases',
          value: '4',
          icon: Icons.pending_outlined,
        ),
      ],
    );
  }
}

