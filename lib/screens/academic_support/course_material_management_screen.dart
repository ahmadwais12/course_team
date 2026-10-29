import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class CourseMaterialManagementScreen extends StatelessWidget {
  const CourseMaterialManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Course Materials',
        tableName: 'course_content',
        icon: Icons.folder_shared_rounded,
        accentColor: Colors.indigo,
        displayFields: ['title', 'content_type', 'is_published', 'created_at'],
      );
}
