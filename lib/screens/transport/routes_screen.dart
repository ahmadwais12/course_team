import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Routes',
        tableName: 'routes',
        icon: Icons.alt_route_rounded,
        accentColor: Colors.indigo,
        displayFields: ['name', 'start_location', 'end_location', 'status'],
      );
}
