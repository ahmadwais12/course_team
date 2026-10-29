import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class AcSalariesScreen extends ConsumerWidget {
  const AcSalariesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const AdaptiveDataPage(
        title: 'Salaries',
        tableName: 'salaries',
        icon: Icons.payments_rounded,
        accentColor: Colors.deepPurple,
        displayFields: [
          'month',
          'year',
          'basic_salary',
          'net_salary',
          'status',
        ],
      );
}
