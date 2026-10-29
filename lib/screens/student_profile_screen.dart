import 'package:flutter/material.dart';
import 'package:course_emis/theme.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: const Text('View Only',
                  style: TextStyle(fontSize: 11, color: Colors.white)),
              backgroundColor: Colors.grey[600],
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: AppSpacing.paddingXl,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF67E8F9)],
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child:
                        Icon(Icons.person, size: 50, color: Color(0xFF38BDF8)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Ahmad Khan',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const Text('Student ID: STU-2024-001',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                children: [
                  _InfoCard(
                    title: 'Contact Information',
                    items: [
                      _InfoItem(
                          icon: Icons.email,
                          label: 'Email',
                          value: 'ahmad@example.com'),
                      _InfoItem(
                          icon: Icons.phone,
                          label: 'Phone',
                          value: '+93 700 123 456'),
                      _InfoItem(
                          icon: Icons.location_on,
                          label: 'Address',
                          value: 'Kabul, Afghanistan'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InfoCard(
                    title: 'Academic Information',
                    items: [
                      _InfoItem(
                          icon: Icons.school,
                          label: 'Program',
                          value: 'IELTS Preparation'),
                      _InfoItem(
                          icon: Icons.calendar_today,
                          label: 'Enrolled',
                          value: 'Jan 15, 2024'),
                      _InfoItem(
                          icon: Icons.class_,
                          label: 'Class',
                          value: 'IELTS-A1'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InfoCard(
                    title: 'Payment Summary',
                    items: [
                      _InfoItem(
                          icon: Icons.payment,
                          label: 'Total Fees',
                          value: 'PKR 60,000'),
                      _InfoItem(
                          icon: Icons.check_circle,
                          label: 'Paid',
                          value: 'PKR 40,000'),
                      _InfoItem(
                          icon: Icons.pending,
                          label: 'Outstanding',
                          value: 'PKR 20,000',
                          valueColor: Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          ...items,
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF38BDF8)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                Text(value,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: valueColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
