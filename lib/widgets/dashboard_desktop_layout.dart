import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/theme/dashboard_theme.dart';

class DashboardDesktopLayout extends StatefulWidget {
  const DashboardDesktopLayout({super.key});

  @override
  State<DashboardDesktopLayout> createState() => _DashboardDesktopLayoutState();
}

class _DashboardDesktopLayoutState extends State<DashboardDesktopLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dtBgColor,
      body: Row(
        children: [
          const _Sidebar(),
          Expanded(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _MainContent(entranceCtrl: _entranceController),
                      ),
                      const _RightPanel(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar ──────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: dtSurfaceColor,
        border: Border(right: BorderSide(color: dtBorderColor)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: dtPrimaryColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 32),
          _SidebarItem(icon: Icons.dashboard_rounded, label: 'Dashboard', active: true, onTap: () {}),
          _SidebarItem(icon: Icons.chat_bubble_outline_rounded, label: 'Messages', onTap: () => context.go('/messages')),
          _SidebarItem(icon: Icons.assessment_outlined, label: 'Reports', onTap: () => context.go('/reports')),
          _SidebarItem(icon: Icons.analytics_outlined, label: 'Analytics', onTap: () {}),
          const Spacer(),
          Divider(color: dtBorderColor, height: 1, thickness: 1),
          _SidebarItem(icon: Icons.settings_outlined, label: 'Settings', onTap: () => context.go('/settings')),
          _SidebarItem(icon: Icons.help_outline_rounded, label: 'Support', onTap: () => context.go('/help-support')),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Tooltip(
        message: label,
        child: Material(
          color: active ? dtPrimaryColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              width: 56, height: 48,
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: active ? dtPrimaryColor : dtSecondaryColor,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top Bar ──────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: dtSurfaceColor,
        border: Border(bottom: BorderSide(color: dtBorderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          SizedBox(
            width: 320,
            height: 44,
            child: TextField(
              style: const TextStyle(color: dtTextColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search anything...',
                hintStyle: const TextStyle(color: dtSecondaryColor),
                prefixIcon: const Icon(Icons.search_rounded, color: dtSecondaryColor, size: 20),
                filled: true,
                fillColor: dtCardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const Spacer(),
          _IconButton(icon: Icons.notifications_outlined, onTap: () => context.go('/notifications')),
          const SizedBox(width: 8),
          _IconButton(icon: Icons.chat_bubble_outline_rounded, onTap: () => context.go('/messages')),
          const SizedBox(width: 8),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [dtPrimaryColor, dtPrimaryLight]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(t(LAll.all_aw, ref), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dtCardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: dtSecondaryColor, size: 22),
        ),
      ),
    );
  }
}

// ── Main Content (animated) ──────────────────────────────────────────────

class _MainContent extends StatefulWidget {
  final AnimationController entranceCtrl;
  const _MainContent({required this.entranceCtrl});

  @override
  State<_MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<_MainContent>
    with SingleTickerProviderStateMixin {
  late PageController _carouselCtrl;
  late Timer _carouselTimer;
  int _carouselIndex = 0;

  final List<_CarouselSlide> _slides = const [
    _CarouselSlide(
      icon: Icons.people_rounded,
      label: 'Total Students',
      value: '2,486',
      color: dtPrimaryColor,
      subtitle: 'Across all programs & batches',
    ),
    _CarouselSlide(
      icon: Icons.payments_rounded,
      label: 'Revenue This Month',
      value: '\$48,290',
      color: dtSuccessColor,
      subtitle: '82% of monthly target achieved',
    ),
    _CarouselSlide(
      icon: Icons.school_rounded,
      label: 'Active Courses',
      value: '24',
      color: Color(0xFF3B82F6),
      subtitle: 'Running in 6 departments',
    ),
    _CarouselSlide(
      icon: Icons.emoji_events_rounded,
      label: 'Completion Rate',
      value: '78.5%',
      color: Color(0xFFF59E0B),
      subtitle: '+5.3% vs last semester',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _carouselCtrl = PageController(viewportFraction: 0.48, initialPage: 0);
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_carouselIndex + 1) % _slides.length;
      _carouselCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _carouselIndex = next);
    });
  }

  @override
  void dispose() {
    _carouselTimer.cancel();
    _carouselCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          FadeTransition(
            opacity: widget.entranceCtrl.drive(
              CurveTween(curve: const Interval(0.0, 0.3, curve: Curves.easeOut)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Welcome back, Admin',
                        style: TextStyle(
                          color: dtTextColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _QuickDateChip(),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "Here's what's happening with your institution today.",
                  style: TextStyle(color: dtSecondaryColor, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Carousel
          FadeTransition(
            opacity: widget.entranceCtrl.drive(
              CurveTween(curve: const Interval(0.1, 0.4, curve: Curves.easeOut)),
            ),
            child: SizedBox(
              height: 110,
              child: PageView.builder(
                controller: _carouselCtrl,
                onPageChanged: (i) => setState(() => _carouselIndex = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _buildCarouselCard(_slides[i]),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // KPI Cards Row
          FadeTransition(
            opacity: widget.entranceCtrl.drive(
              CurveTween(curve: const Interval(0.2, 0.5, curve: Curves.easeOut)),
            ),
            child: const Row(
              children: [
                Expanded(child: _KPICard(label: 'Total Students', value: '2,486', trend: '+12.5%', trendUp: true, spots: [10, 25, 18, 35, 28, 42, 38])),
                SizedBox(width: 16),
                Expanded(child: _KPICard(label: 'Revenue', value: '\$48,290', trend: '+8.2%', trendUp: true, spots: [30, 28, 35, 40, 38, 45, 50])),
                SizedBox(width: 16),
                Expanded(child: _KPICard(label: 'Active Courses', value: '24', trend: '-3.1%', trendUp: false, spots: [20, 18, 22, 20, 16, 19, 18])),
                SizedBox(width: 16),
                Expanded(child: _KPICard(label: 'Completion Rate', value: '78.5%', trend: '+5.3%', trendUp: true, spots: [60, 65, 70, 68, 72, 75, 78])),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Charts Row
          FadeTransition(
            opacity: widget.entranceCtrl.drive(
              CurveTween(curve: const Interval(0.3, 0.6, curve: Curves.easeOut)),
            ),
            child: const SizedBox(
              height: 320,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 2, child: _SessionChartCard()),
                  SizedBox(width: 16),
                  Expanded(flex: 1, child: _RadarChartCard()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bottom Row: Quick Actions + Recent Activity
          FadeTransition(
            opacity: widget.entranceCtrl.drive(
              CurveTween(curve: const Interval(0.4, 0.7, curve: Curves.easeOut)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _QuickActionsCard()),
                SizedBox(width: 16),
                Expanded(flex: 2, child: _RecentActivityCard()),
                SizedBox(width: 16),
                Expanded(child: _BottomInfoCard(label: 'Top Source', value: 'Direct', detail: '38.7%', icon: Icons.link_rounded)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bottom Info Row
          FadeTransition(
            opacity: widget.entranceCtrl.drive(
              CurveTween(curve: const Interval(0.5, 0.8, curve: Curves.easeOut)),
            ),
            child: const Row(
              children: [
                Expanded(child: _BottomInfoCard(label: 'Browser Usage', value: 'Chrome', detail: '64.3%', icon: Icons.language_rounded)),
                SizedBox(width: 16),
                Expanded(child: _BottomInfoCard(label: 'Platform', value: 'iOS', detail: '52.1%', icon: Icons.phone_android_rounded)),
                SizedBox(width: 16),
                Expanded(child: _BottomInfoCard(label: 'Revenue Goal', value: '\$92K', detail: '68% of \$135K', icon: Icons.trending_up_rounded)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard(_CarouselSlide slide) {
    final isCenter = _carouselIndex == _slides.indexOf(slide);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCenter ? slide.color.withValues(alpha: 0.15) : dtCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCenter ? slide.color.withValues(alpha: 0.4) : dtBorderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: slide.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(slide.icon, color: slide.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(slide.label, style: const TextStyle(color: dtSecondaryColor, fontSize: 11)),
                const SizedBox(height: 2),
                Text(slide.value, style: const TextStyle(color: dtTextColor, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(slide.subtitle, style: TextStyle(color: slide.color.withValues(alpha: 0.8), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselSlide {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String subtitle;
  const _CarouselSlide({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.subtitle,
  });
}

class _QuickDateChip extends StatelessWidget {
  const _QuickDateChip();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final label = '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: dtCardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded, size: 14, color: dtPrimaryColor),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: dtSecondaryColor, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Quick Actions Card ────────────────────────────────────────────────────

class _QuickActionsCard extends ConsumerWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      _QuickAction(icon: Icons.person_add_rounded, label: 'Add Student', color: dtPrimaryColor),
      _QuickAction(icon: Icons.payments_rounded, label: 'New Payment', color: dtSuccessColor),
      _QuickAction(icon: Icons.school_rounded, label: 'Create Course', color: const Color(0xFF3B82F6)),
      _QuickAction(icon: Icons.assessment_rounded, label: 'Generate Report', color: const Color(0xFFF59E0B)),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dtCardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t(LDash.quickActions, ref), style: const TextStyle(color: dtTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(t(LAll.all_common_tasks, ref), style: const TextStyle(color: dtSecondaryColor, fontSize: 12)),
          const SizedBox(height: 16),
          ...actions.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: a.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(a.icon, color: a.color, size: 18),
                      const SizedBox(width: 10),
                      Text(a.label, style: const TextStyle(color: dtTextColor, fontSize: 13)),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: a.color.withValues(alpha: 0.6), size: 16),
                    ],
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickAction({required this.icon, required this.label, required this.color});
}

// ── Recent Activity ───────────────────────────────────────────────────────

class _RecentActivityCard extends ConsumerWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = [
      _ActivityItem(icon: Icons.person_add_rounded, text: 'New student enrolled: Ahmad Karimi', time: '2 min ago', color: dtPrimaryColor),
      _ActivityItem(icon: Icons.payments_rounded, text: 'Payment of \$340 received', time: '15 min ago', color: dtSuccessColor),
      _ActivityItem(icon: Icons.feedback_rounded, text: 'New feedback submitted by Teacher', time: '1 hr ago', color: const Color(0xFF3B82F6)),
      _ActivityItem(icon: Icons.warning_amber_rounded, text: 'Low attendance alert: Class B2', time: '2 hrs ago', color: const Color(0xFFF59E0B)),
      _ActivityItem(icon: Icons.check_circle_rounded, text: 'Course "Math 101" marked complete', time: '3 hrs ago', color: dtSuccessColor),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dtCardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(t(LDash.recentActivity, ref), style: const TextStyle(color: dtTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: dtPrimaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(t(LAll.all_live, ref), style: const TextStyle(color: dtPrimaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(t(LAll.all_latest_updates_across_the_institute, ref), style: const TextStyle(color: dtSecondaryColor, fontSize: 12)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: activities.length,
              separatorBuilder: (_, __) => const Divider(color: dtBorderColor, height: 1),
              itemBuilder: (_, i) {
                final a = activities[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: a.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(a.icon, color: a.color, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.text, style: const TextStyle(color: dtTextColor, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(a.time, style: const TextStyle(color: dtSecondaryColor, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final IconData icon;
  final String text;
  final String time;
  final Color color;
  const _ActivityItem({required this.icon, required this.text, required this.time, required this.color});
}

// ── KPI Card ──────────────────────────────────────────────────────────────

class _KPICard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final bool trendUp;
  final List<double> spots;

  const _KPICard({
    required this.label,
    required this.value,
    required this.trend,
    required this.trendUp,
    required this.spots,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dtCardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(color: dtSecondaryColor, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (trendUp ? dtSuccessColor : dtDangerColor).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendUp ? Icons.trending_up : Icons.trending_down, size: 14, color: trendUp ? dtSuccessColor : dtDangerColor),
                    const SizedBox(width: 2),
                    Text(trend, style: TextStyle(color: trendUp ? dtSuccessColor : dtDangerColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: dtTextColor, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: trendUp ? dtSuccessColor : dtDangerColor,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: (trendUp ? dtSuccessColor : dtDangerColor).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Session Chart Card ────────────────────────────────────────────────────

class _SessionChartCard extends ConsumerWidget {
  const _SessionChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: dtCardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t(LAll.all_session_overview, ref), style: const TextStyle(color: dtTextColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(t(LAll.all_daily_active_sessions_this_week, ref), style: const TextStyle(color: dtSecondaryColor, fontSize: 13)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: dtBorderColor.withValues(alpha: 0.5), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(labels[v.toInt()], style: const TextStyle(color: dtSecondaryColor, fontSize: 11)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, reservedSize: 44,
                      getTitlesWidget: (v, _) => Text(tt(LAll.all_s392, ref, ['${v.toInt()}']), style: const TextStyle(color: dtSecondaryColor, fontSize: 11)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 120), FlSpot(1, 200), FlSpot(2, 150),
                      FlSpot(3, 280), FlSpot(4, 350), FlSpot(5, 240), FlSpot(6, 300),
                    ],
                    isCurved: true, curveSmoothness: 0.35,
                    color: dtPrimaryColor, barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 5, color: dtPrimaryColor,
                        strokeWidth: 2, strokeColor: dtCardColor,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: dtPrimaryColor.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Radar / Browser Usage Card ────────────────────────────────────────────

class _RadarChartCard extends ConsumerWidget {
  const _RadarChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: dtCardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t(LAll.all_browser_usage, ref), style: const TextStyle(color: dtTextColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(t(LAll.all_sessions_by_browser, ref), style: const TextStyle(color: dtSecondaryColor, fontSize: 13)),
          const SizedBox(height: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BrowserBar(label: 'Chrome', percent: 64, color: dtPrimaryColor),
                const SizedBox(height: 12),
                _BrowserBar(label: 'Safari', percent: 52, color: dtSuccessColor),
                const SizedBox(height: 12),
                _BrowserBar(label: 'Firefox', percent: 38, color: const Color(0xFFF59E0B)),
                const SizedBox(height: 12),
                _BrowserBar(label: 'Edge', percent: 28, color: const Color(0xFF3B82F6)),
                const SizedBox(height: 12),
                _BrowserBar(label: 'Other', percent: 18, color: dtSecondaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowserBar extends ConsumerWidget {
  final String label;
  final double percent;
  final Color color;

  const _BrowserBar({required this.label, required this.percent, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        SizedBox(width: 56, child: Text(label, style: const TextStyle(color: dtSecondaryColor, fontSize: 11))),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: dtBorderColor,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 32, child: Text(tt(LAll.all_s3, ref, ['${percent.toInt()}']), style: const TextStyle(color: dtTextColor, fontSize: 11, fontWeight: FontWeight.bold))),
      ],
    );
  }
}

// ── Bottom Info Card ──────────────────────────────────────────────────────

class _BottomInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final IconData icon;

  const _BottomInfoCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dtCardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: dtPrimaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: dtPrimaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: dtSecondaryColor, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: dtTextColor, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(detail, style: const TextStyle(color: dtPrimaryLight, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Right Panel ───────────────────────────────────────────────────────────

class _RightPanel extends ConsumerWidget {
  const _RightPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: dtSurfaceColor,
        border: Border(left: BorderSide(color: dtBorderColor)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t(LAll.all_analytics_overview, ref), style: const TextStyle(color: dtTextColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _ProgressIndicatorCard(label: 'Overall Performance', progress: 0.78, value: '78%', color: dtPrimaryColor),
          const SizedBox(height: 16),
          _ProgressIndicatorCard(label: 'Student Satisfaction', progress: 0.85, value: '85%', color: dtSuccessColor),
          const SizedBox(height: 16),
          _ProgressIndicatorCard(label: 'Task Completion', progress: 0.62, value: '62%', color: const Color(0xFFF59E0B)),
          const SizedBox(height: 16),
          _ProgressIndicatorCard(label: 'Attendance Rate', progress: 0.91, value: '91%', color: const Color(0xFF3B82F6)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dtCardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t(LAll.all_quick_stats, ref), style: const TextStyle(color: dtTextColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _StatRow(label: 'Active Users', value: '1,284'),
                _StatRow(label: 'New Today', value: '+48'),
                _StatRow(label: 'Pending Tasks', value: '23'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressIndicatorCard extends StatelessWidget {
  final String label;
  final double progress;
  final String value;
  final Color color;

  const _ProgressIndicatorCard({
    required this.label,
    required this.progress,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dtCardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52, height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: dtBorderColor,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: const TextStyle(color: dtTextColor, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: dtSecondaryColor, fontSize: 13)),
          Text(value, style: const TextStyle(color: dtTextColor, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
