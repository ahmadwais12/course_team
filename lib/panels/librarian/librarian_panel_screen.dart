import 'package:flutter/material.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/widgets/realtime_watcher.dart';
import 'package:course_emis/providers/panel_stats_provider.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/base_panel_layout.dart';
import 'package:course_emis/core/responsive/responsive.dart';
import 'package:course_emis/widgets/insight_ui.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class LibrarianPanelScreen extends ConsumerWidget {
  const LibrarianPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryStatsAsync = ref.watch(libraryStatsProvider);
    final supabase = Supabase.instance.client;

    return BasePanelLayout(
      title: t(LPanel.librarianPanel, ref),
      children: [
        RealtimeDashboardWatcher(
          channelName: 'library-dashboard',
          tables: ['library_books', 'book_issues', 'library_members', 'reservations'],
          onChange: () => ref.invalidate(libraryStatsProvider),
        ),

        // Hero Card
        libraryStatsAsync
            .when(
              data: (stats) {
                return InsightHeroCard(
                  eyebrow: 'LIBRARY & KNOWLEDGE',
                  title: 'Library Resource Center',
                  subtitle:
                      'Manage the book catalog, member registrations, reservations, and circulation from one dedicated librarian console.',
                  accent: Colors.teal,
                  chips: [
                    InsightStatChip(
                      label: 'Total Books',
                      value: stats.totalBooks.toString(),
                    ),
                    InsightStatChip(
                      label: 'Issued',
                      value: stats.issuedBooks.toString(),
                    ),
                    InsightStatChip(
                      label: 'Members',
                      value: stats.totalMembers.toString(),
                    ),
                    InsightStatChip(
                      label: 'Overdue',
                      value: stats.overdueBooks.toString(),
                    ),
                  ],
                  actions: [
                    _GradientButton(
                      onPressed: () => context.go(AppRoutes.digitalLibrary),
                      icon: Icons.menu_book_rounded,
                      label: 'Catalog',
                      gradient: AppGradients.skyCyanHorizontal,
                    ),
                    _GradientButton(
                      onPressed: () => context.go(AppRoutes.issueBook),
                      icon: Icons.assignment_returned_rounded,
                      label: 'Issue Book',
                      gradient: AppGradients.blueHorizontal,
                      isOutlined: true,
                    ),
                  ],
                );
              },
              loading: () => const PageSkeleton(type: 'dashboard'),
              error: (_, __) => const SizedBox.shrink(),
            )
            .animate()
            .fadeIn(duration: 800.ms)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
        const SizedBox(height: 24),

        // Circulation Workflow
        InsightSectionTitle(
          title: 'Circulation Workflow',
          subtitle: 'From acquisition to return - complete book lifecycle',
        ),
        const SizedBox(height: 12),
        InsightProcessDiagram(
          title: '',
          subtitle: '',
          accent: Colors.teal,
          steps: const [
            InsightFlowStep(
              title: 'Acquire',
              subtitle: 'Catalog new books',
              icon: Icons.add_business_rounded,
            ),
            InsightFlowStep(
              title: 'Register',
              subtitle: 'Enroll members',
              icon: Icons.person_add_alt_1_rounded,
            ),
            InsightFlowStep(
              title: 'Issue',
              subtitle: 'Check out books',
              icon: Icons.assignment_returned_rounded,
            ),
            InsightFlowStep(
              title: 'Track',
              subtitle: 'Monitor due dates',
              icon: Icons.track_changes_rounded,
            ),
            InsightFlowStep(
              title: 'Return',
              subtitle: 'Handle returns & fines',
              icon: Icons.assignment_turned_in_rounded,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Library Modules
        InsightSectionTitle(
          title: 'Library Modules',
          subtitle: 'Comprehensive tools for library management',
        ),
        const SizedBox(height: 12),
        _buildModulesGrid(context),
        const SizedBox(height: 24),

        // Analytics Row
        libraryStatsAsync.when(
          data: (stats) {
            return ResponsiveMetricRow(
              children: [
                InsightMetricCard(
                  label: 'Catalog Size',
                  value: stats.totalBooks.toString(),
                  trend: 'Available titles',
                  icon: Icons.local_library_rounded,
                  accent: Colors.teal,
                ),
                InsightMetricCard(
                  label: 'Active Loans',
                  value: stats.issuedBooks.toString(),
                  trend: 'Currently out',
                  icon: Icons.book_rounded,
                  accent: Colors.blue,
                ),
                InsightMetricCard(
                  label: 'Members',
                  value: stats.totalMembers.toString(),
                  trend: 'Registered users',
                  icon: Icons.badge_rounded,
                  accent: Colors.indigo,
                ),
                InsightMetricCard(
                  label: 'Overdue',
                  value: stats.overdueBooks.toString(),
                  trend: 'Needs follow-up',
                  icon: Icons.warning_amber_rounded,
                  accent: Colors.orange,
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
        const SizedBox(height: 24),

        // Circulation Analytics
        InsightSectionTitle(
          title: 'Circulation Analytics',
          subtitle: 'Book status breakdown and weekly issue trend',
        ),
        const SizedBox(height: 12),
        ResponsiveBuilder(
          builder: (context, isMobile, isTablet, isDesktop) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final chartWidth = constraints.maxWidth;
                final twoCol = chartWidth >= 900;
                final charts = <Widget>[
                  libraryStatsAsync.when(
                    data: (stats) => InsightSegmentsCard(
                      title: 'Collection Status',
                      subtitle: 'Proportion of books by circulation state',
                      segments: [
                        InsightSegment(
                          label: 'Available',
                          value: (stats.totalBooks - stats.issuedBooks)
                              .toDouble(),
                          color: Colors.teal,
                        ),
                        InsightSegment(
                          label: 'Issued',
                          value: stats.issuedBooks.toDouble(),
                          color: Colors.blue,
                        ),
                        InsightSegment(
                          label: 'Overdue',
                          value: stats.overdueBooks.toDouble(),
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    loading: () => const PageSkeleton(type: 'card'),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const InsightLineChartCard(
                    title: 'Weekly Issues',
                    subtitle: 'Books checked out over the last week',
                    accent: Colors.teal,
                    points: [
                      InsightPoint('Mon', 12),
                      InsightPoint('Tue', 18),
                      InsightPoint('Wed', 15),
                      InsightPoint('Thu', 22),
                      InsightPoint('Fri', 26),
                      InsightPoint('Sat', 14),
                      InsightPoint('Sun', 9),
                    ],
                  ),
                ];
                if (twoCol) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: charts[0]),
                      const SizedBox(width: 16),
                      Expanded(child: charts[1]),
                    ],
                  );
                }
                return Column(
                  children: [
                    charts[0],
                    const SizedBox(height: 16),
                    charts[1],
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),

        // Coverage Matrix
        InsightSectionTitle(
          title: 'Library Coverage Matrix',
          subtitle: 'Complete overview of responsibilities',
        ),
        const SizedBox(height: 12),
        const InsightTableCard(
          title: '',
          subtitle: '',
          columns: ['Area', 'Responsibility', 'Primary Tool', 'Target'],
          rows: [
            [
              'Catalog',
              'Add, edit & organize books',
              'Digital Library',
              'Readers'
            ],
            [
              'Circulation',
              'Issue & return books',
              'Issue/Return Book',
              'Members'
            ],
            [
              'Memberships',
              'Register & manage members',
              'Members',
              'Students/Staff'
            ],
            [
              'Reservations',
              'Hold books for members',
              'Reservations',
              'Members'
            ],
            [
              'Fines',
              'Track overdue fees',
              'Fine Management',
              'Borrowers'
            ],
          ],
        ),
        const SizedBox(height: 24),

        // Recent Activity
        FutureBuilder(
          future: Future.wait([
            supabase
                .from('book_issues')
                .select('book_id, due_date, status, created_at')
                .order('created_at', ascending: false)
                .limit(2),
            supabase
                .from('library_members')
                .select('membership_number, student_id, teacher_id, created_at')
                .order('created_at', ascending: false)
                .limit(2),
          ]),
          builder: (context, AsyncSnapshot<List<Object?>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const PageSkeleton(type: 'list', itemCount: 4);
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final issues = snapshot.data![0] as List;
            final members = snapshot.data![1] as List;

            final List<List<String>> rows = [];

            for (var issue in issues) {
              rows.add([
                'Book Issue',
                issue['book_id']?.toString().substring(0, 8) ?? '-',
                'Due ${issue['due_date']?.toString().split('T')[0] ?? '-'}',
                _timeAgo(issue['created_at']),
                issue['status']?.toString() ?? 'Issued',
              ]);
            }

            for (var member in members) {
              final memberNo = member['membership_number']?.toString() ?? '-';
              final person = (member['student_id'] ?? member['teacher_id'])
                  ?.toString()
                  .substring(0, 8);
              rows.add([
                'Member',
                memberNo,
                person ?? 'Staff',
                _timeAgo(member['created_at']),
                'Active',
              ]);
            }

            return Column(
              children: [
                InsightSectionTitle(
                  title: t(LDash.recentActivity, ref),
                  subtitle: 'Latest book issues and new members',
                  trailing: TextButton(
                    onPressed: () => context.go(AppRoutes.digitalLibrary),
                    child: Text(t(LDash.viewAll, ref)),
                  ),
                ),
                const SizedBox(height: 12),
                InsightTableCard(
                  title: '',
                  subtitle: '',
                  columns: const ['Item', 'Ref', 'Detail', 'Time', 'Status'],
                  rows: rows.isEmpty
                      ? [
                          [t(L.noData, ref), '-', '-', '-', '-'],
                        ]
                      : rows,
                ),
              ],
            );
          },
        ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
      ],
    );
  }

  Widget _buildModulesGrid(BuildContext context) {
    final modules = [
      (
        'Digital Library',
        Icons.menu_book_rounded,
        Colors.teal,
        AppRoutes.digitalLibrary,
        'Browse the full book catalog',
      ),
      (
        'Issue Book',
        Icons.assignment_returned_rounded,
        Colors.blue,
        AppRoutes.issueBook,
        'Check out books to members',
      ),
      (
        'Return Book',
        Icons.assignment_turned_in_rounded,
        Colors.green,
        AppRoutes.returnBook,
        'Process returns & renewals',
      ),
      (
        'Members',
        Icons.badge_rounded,
        Colors.indigo,
        AppRoutes.members,
        'Manage library members',
      ),
      (
        'Memberships',
        Icons.card_membership_rounded,
        Colors.orange,
        AppRoutes.memberships,
        'Plan types & renewals',
      ),
      (
        'Reservations',
        Icons.bookmark_added_rounded,
        Colors.purple,
        AppRoutes.reservations,
        'Hold books for members',
      ),
      (
        'Fine Management',
        Icons.currency_exchange_rounded,
        Colors.pink,
        AppRoutes.fineManagement,
        'Track overdue fines',
      ),
      (
        'Books',
        Icons.auto_stories_rounded,
        Colors.brown,
        AppRoutes.books,
        'Full book records',
      ),
    ];

    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 2 : 3,
            childAspectRatio: isMobile ? 1.2 : 1.1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final module = modules[index];
            return _buildModuleCard(
              context,
              module.$1,
              module.$2,
              module.$3,
              module.$4,
              module.$5,
            ).animate().fadeIn(delay: (index * 50).ms).scale(
                begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
          },
        );
      },
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
    String subtitle,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        color: Colors.grey[500],
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(dynamic date) {
    if (date == null) return 'Recently';
    try {
      final dt = DateTime.parse(date.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (e) {
      return 'Recently';
    }
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Gradient gradient;
  final bool isOutlined;

  const _GradientButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.gradient,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isOutlined) {
      return Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        padding: const EdgeInsets.all(2),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}
