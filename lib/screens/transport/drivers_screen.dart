import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class DriversScreen extends StatelessWidget {
  const DriversScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Drivers',
        tableName: 'drivers',
        icon: Icons.person_pin_circle_rounded,
        accentColor: Colors.teal,
        displayFields: ['full_name', 'phone', 'license_number', 'available'],
      );
}
