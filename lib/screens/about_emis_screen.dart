import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class AboutEmisScreen extends ConsumerWidget {
  const AboutEmisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(LModule.aboutEmis, ref)),
      ),
      body: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          // Logo and Title
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF67E8F9)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'EMIS - Education Management',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Description
          Card(
            child: Padding(
              padding: AppSpacing.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About the Platform',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'EMIS is a comprehensive Education Management Information System designed to streamline educational institution operations. It provides tools for managing students, teachers, courses, attendance, grades, finances, and more.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Features
          Card(
            child: Padding(
              padding: AppSpacing.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Features',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildFeatureItem(Icons.people_rounded, 'Student Management'),
                  _buildFeatureItem(Icons.school_rounded, 'Teacher Portal'),
                  _buildFeatureItem(Icons.grade_rounded, 'Grade Management'),
                  _buildFeatureItem(
                      Icons.calendar_today_rounded, 'Attendance Tracking'),
                  _buildFeatureItem(Icons.payments_rounded, 'Fee Collection'),
                  _buildFeatureItem(
                      Icons.assessment_rounded, 'Reports & Analytics'),
                  _buildFeatureItem(
                      Icons.notifications_rounded, 'Notifications'),
                  _buildFeatureItem(
                      Icons.security_rounded, 'Role-based Access'),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Contact Info
          Card(
            child: Padding(
              padding: AppSpacing.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ListTile(
                    leading:
                        const Icon(Icons.email_rounded, color: Colors.blue),
                    title: Text(t(L.email, ref)),
                    subtitle: Text(t(LAll.all_contactemiscom, ref)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.phone_rounded, color: Colors.blue),
                    title: Text(t(LAuth.phoneNumber, ref)),
                    subtitle: Text(t(LAll.all_1234567890, ref)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.public_rounded, color: Colors.orange),
                    title: Text(t(LAll.all_website, ref)),
                    subtitle: Text(t(LAll.all_wwwemiscom, ref)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on_rounded,
                        color: Colors.red),
                    title: Text(t(LAll.all_address, ref)),
                    subtitle: Text(t(LAll.all_123_education_street_learning_city, ref)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Legal
          Card(
            child: Padding(
              padding: AppSpacing.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Legal',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ListTile(
                    title: Text(t(LAbout.termsOfService, ref)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.go('/help-support'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    title: Text(t(LAbout.privacyPolicy, ref)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.go('/help-support'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    title: Text(t(LAll.all_license_agreement, ref)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.go('/help-support'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Copyright
          Center(
            child: Text(
              '© 2026 EMIS. All rights reserved.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: AppSpacing.paddingSm,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 20, color: Colors.blue),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(text),
        ],
      ),
    );
  }
}
