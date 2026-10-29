import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Transport Vehicles',
        tableName: 'vehicles',
        icon: Icons.directions_bus_filled_rounded,
        accentColor: Colors.blue,
        displayFields: ['plate_number', 'model', 'status', 'capacity'],
      );
}
