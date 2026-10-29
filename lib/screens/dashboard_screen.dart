import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/providers/impersonation_provider.dart';
import 'package:course_emis/services/secure_storage_service.dart';
import 'package:course_emis/widgets/dashboard_desktop_layout.dart';
import 'package:course_emis/widgets/insight_ui.dart';
import 'package:course_emis/widgets/sign_out_dialog.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = resolveEffectiveRole(ref);
    if (role != 'dashboard' && role.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(homeRouteForRole(role));
      });
    }

    final firstName =
        user?.userMetadata?['full_name']?.toString().split(' ').first ?? 'User';

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return const DashboardDesktopLayout();
        }
        return _buildMobileLayout(context, ref, firstName);
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref, String firstName) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LNav.dashboard, ref)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.go('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              final shouldSignOut = await showSignOutDialog(context, ref);
              if (!shouldSignOut) return;
              await ref.read(impersonationProvider.notifier).exit();
              await SecureStorageService(const FlutterSecureStorage()).clearTokens();
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: InsightBackground(
        maxWidth: 1200,
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              InsightHeroCard(
                eyebrow: 'Executive command center',
                title: '${t(LDash.welcomeBack, ref)}, $firstName',
                subtitle:
                    'Track academics, finance, operations, and promotional activity from one dashboard with a cleaner visual hierarchy.',
                accent: const Color(0xFF0F766E),
                chips: [
                  InsightStatChip(label: t(LNav.students, ref), value: '1,248'),
                  InsightStatChip(label: t(LDash2.collectionRate, ref), value: '91%'),
                  InsightStatChip(label: t(LDash2.activeCampaigns, ref), value: '12'),
                ],
                actions: [
                  FilledButton.icon(
                    onPressed: () => context.go('/students'),
                    icon: const Icon(Icons.groups_rounded),
                    label: const Text('Open Students'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => context.go('/reports'),
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('View Reports'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: 240,
                    child: InsightMetricCard(
                      label: t(LDash2.newEnrollments, ref),
                      value: '84',
                      trend: '+12%',
                      icon: Icons.person_add_alt_1_rounded,
                      accent: Colors.blue,
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: InsightMetricCard(
                      label: t(LDash2.revenueCollected, ref),
                      value: 'PKR 2.4M',
                      trend: '+9%',
                      icon: Icons.payments_rounded,
                      accent: Colors.blue,
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: InsightMetricCard(
                      label: t(LDash2.courseCompletion, ref),
                      value: '78%',
                      trend: '+5%',
                      icon: Icons.school_rounded,
                      accent: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 840;
                  final lineCard = InsightLineChartCard(
                    title: t(LDash2.enrollmentMomentum, ref),
                    subtitle:
                        'Seven-day growth across the admissions pipeline.',
                    points: [
                      InsightPoint('Mon', 12),
                      InsightPoint('Tue', 18),
                      InsightPoint('Wed', 22),
                      InsightPoint('Thu', 27),
                      InsightPoint('Fri', 30),
                      InsightPoint('Sat', 26),
                    ],
                    accent: Colors.blue,
                  );
                  final segmentCard = InsightSegmentsCard(
                    title: t(LDash2.operationalSplit, ref),
                    subtitle: 'Where the team is spending focus this week.',
                    segments: [
                      InsightSegment(
                          label: t(LDash2.academics, ref),
                          value: 40,
                          color: Color(0xFF0F766E)),
                      InsightSegment(
                          label: t(LDash2.finance, ref), value: 32, color: Colors.orange),
                      InsightSegment(
                          label: t(LDash2.support, ref), value: 18, color: Colors.blue),
                      InsightSegment(
                          label: 'Ads', value: 10, color: Colors.pink),
                    ],
                  );

                  if (narrow) {
                    return Column(
                      children: [
                        lineCard,
                        const SizedBox(height: 16),
                        segmentCard,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: lineCard),
                      const SizedBox(width: 16),
                      Expanded(child: segmentCard),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              const InsightProcessDiagram(
                title: 'Institute workflow diagram',
                subtitle:
                    'The redesigned dashboard ties together intake, learning, payment, and promotion.',
                accent: Color(0xFF0F766E),
                steps: [
                  InsightFlowStep(
                    title: 'Lead capture',
                    subtitle: 'Collect admissions and ad-driven inquiries.',
                    icon: Icons.ads_click_outlined,
                  ),
                  InsightFlowStep(
                    title: 'Enrollment',
                    subtitle: 'Register students and place them into programs.',
                    icon: Icons.assignment_ind_outlined,
                  ),
                  InsightFlowStep(
                    title: 'Delivery',
                    subtitle: 'Run classes, attendance, and support follow-up.',
                    icon: Icons.cast_for_education_outlined,
                  ),
                  InsightFlowStep(
                    title: 'Retention',
                    subtitle:
                        'Track renewals, upsell offers, and campaign response.',
                    icon: Icons.trending_up_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const InsightTableCard(
                title: 'Priority watchlist',
                subtitle:
                    'A compact table for the items leadership usually checks first.',
                columns: ['Area', 'Owner', 'Status', 'Next action'],
                rows: [
                  ['Admissions', 'Front Desk', 'Healthy', 'Follow up 14 leads'],
                  ['Finance', 'Accounts', 'Watch', 'Clear 7 overdue invoices'],
                  ['Programs', 'Academic', 'Stable', 'Open 2 new batches'],
                  ['Ads', 'Marketing', 'Active', 'Launch spring campaign'],
                ],
              ),
              const SizedBox(height: 16),
              InsightPromoBanner(
                title: 'Promote your next intake directly in the app',
                subtitle:
                    'Use the new ads pages to run course promotions, scholarship campaigns, and event announcements from the same platform.',
                ctaLabel: 'Launch Ads',
                accent: const Color(0xFFDB2777),
                icon: Icons.campaign_rounded,
                onTap: () => context.go('/ads'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
