import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class AcFeesScreen extends ConsumerWidget {
  const AcFeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const AdaptiveDataPage(
        title: 'Fees',
        tableName: 'student_fee_assignments',
        icon: Icons.school,
        accentColor: Color(0xFFF59E0B),
        displayFields: [
          'amount',
          'status',
          'due_date',
          'paid_amount',
          'currency',
        ],
      );
}
