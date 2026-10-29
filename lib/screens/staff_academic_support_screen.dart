import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:go_router/go_router.dart';

import 'package:course_emis/nav.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/ui_helpers.dart';

class StaffAcademicSupportScreen extends StatefulWidget {
  const StaffAcademicSupportScreen({super.key});
  @override
  State<StaffAcademicSupportScreen> createState() =>
      _StaffAcademicSupportScreenState();
}

class _StaffAcademicSupportScreenState
    extends State<StaffAcademicSupportScreen> {
  final _sb = Supabase.instance.client;
  bool _loading = true;
  int _studentsCount = 0;
  int _attendanceToday = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final students = await _sb.from('students').select('id');
      final attendance = await _sb
          .from('attendance')
          .select('id')
          .eq('date', today)
          .eq('status', 'present');
      setState(() {
        _studentsCount = students.length;
        _attendanceToday = attendance.length;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: AppSpacing.paddingLg,
            children: [
              StatCard(
                title: 'Total Students',
                value: '$_studentsCount',
                icon: Icons.people_rounded,
              ),
              const VSpace(AppSpacing.md),
              StatCard(
                title: 'Present Today',
                value: '$_attendanceToday',
                icon: Icons.check_circle_rounded,
              ),
              const VSpace(AppSpacing.lg),
              const _ModuleCard(
                title: 'Student Registration & Onboarding',
                subtitle:
                    'Admissions, student IDs, document collection, and first setup.',
                icon: Icons.app_registration_rounded,
                route: AppRoutes.admissions,
              ),
              const _ModuleCard(
                title: 'Student Accounts & Profiles',
                subtitle:
                    'Login access, profile corrections, status management, and account support.',
                icon: Icons.manage_accounts_rounded,
                route: AppRoutes.students,
              ),
              const _ModuleCard(
                title: 'Academic Operations',
                subtitle:
                    'Classes, attendance, grades, exams, promotions, and report generation.',
                icon: Icons.school_rounded,
                route: AppRoutes.classes,
              ),
              const _ModuleCard(
                title: 'Course & Learning Setup',
                subtitle:
                    'Programs, levels, durations, books, and course materials.',
                icon: Icons.menu_book_rounded,
                route: AppRoutes.programs,
              ),
              const _ModuleCard(
                title: 'Progress, Feedback & Reports',
                subtitle:
                    'Performance tracking, feedback resolution, placement tests, and academic reporting.',
                icon: Icons.insights_rounded,
                route: AppRoutes.reports,
              ),
            ],
          );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        contentPadding: AppSpacing.paddingMd,
        leading: CircleAvatar(
          radius: 24,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () => context.go(route),
      ),
    );
  }
}
