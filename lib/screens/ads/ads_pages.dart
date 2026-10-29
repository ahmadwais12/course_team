import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:course_emis/widgets/insight_ui.dart';

class AdsHubScreen extends StatefulWidget {
  const AdsHubScreen({super.key});

  @override
  State<AdsHubScreen> createState() => _AdsHubScreenState();
}

class _AdsHubScreenState extends State<AdsHubScreen> {
  List<Map<String, dynamic>> _campaigns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    try {
      final data = await Supabase.instance.client
          .from('ads_campaigns')
          .select()
          .order('created_at', ascending: false);
      if (mounted) setState(() => _campaigns = List<Map<String, dynamic>>.from(data));
    } catch (_) {
      if (mounted) setState(() => _campaigns = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalReach = _campaigns.fold<int>(0, (s, c) => s + ((c['reach'] ?? 0) as num).toInt());
    final totalClicks = _campaigns.fold<int>(0, (s, c) => s + ((c['clicks'] ?? 0) as num).toInt());
    final totalImpressions = _campaigns.fold<int>(0, (s, c) => s + ((c['impressions'] ?? 0) as num).toInt());
    final leads = _campaigns.fold<int>(0, (s, c) => s + ((c['leads'] ?? 0) as num).toInt());
    final ctr = totalImpressions > 0 ? (totalClicks / totalImpressions * 100).toStringAsFixed(1) : '0.0';
    final activeCreatives = _campaigns.where((c) => (c['status']?.toString() ?? '').toLowerCase() == 'active').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ads Hub'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadCampaigns,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => context.go('/ads/campaigns'),
            icon: const Icon(Icons.auto_graph_rounded),
          ),
          IconButton(
            onPressed: () => context.go('/ads/google'),
            icon: const Icon(Icons.public_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : InsightBackground(
              child: SafeArea(
                top: false,
                child: RefreshIndicator(
                  onRefresh: _loadCampaigns,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    children: [
                      InsightHeroCard(
                        eyebrow: 'Advertising workspace',
                        title: 'In-app ads and campaign control',
                        subtitle: 'Create promotional slots for admissions, courses, events, and offers with built-in analytics and creative previews.',
                        accent: const Color(0xFFDB2777),
                        chips: _campaigns.isNotEmpty
                            ? [
                                InsightStatChip(label: 'Campaigns', value: '$_campaigns.length'),
                                InsightStatChip(label: 'Reach', value: _formatNumber(totalReach)),
                                InsightStatChip(label: 'CTR', value: '$ctr%'),
                              ]
                            : const [
                                InsightStatChip(label: 'Status', value: 'No data'),
                              ],
                        actions: [
                          FilledButton.icon(
                            onPressed: () => context.go('/ads/campaigns'),
                            icon: const Icon(Icons.campaign_rounded),
                            label: const Text('Manage Campaigns'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/ads/creative-studio'),
                            icon: const Icon(Icons.brush_outlined),
                            label: const Text('Creative Studio'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                            ),
                          ),
                        ],
                      ),
                      if (_campaigns.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: 240,
                              child: InsightMetricCard(
                                label: 'Paid impressions',
                                value: _formatNumber(totalImpressions),
                                trend: '+12%',
                                icon: Icons.visibility_outlined,
                                accent: const Color(0xFFDB2777),
                              ),
                            ),
                            SizedBox(
                              width: 240,
                              child: InsightMetricCard(
                                label: 'Qualified leads',
                                value: _formatNumber(leads),
                                trend: '+18%',
                                icon: Icons.person_search_outlined,
                                accent: Colors.teal,
                              ),
                            ),
                            SizedBox(
                              width: 240,
                              child: InsightMetricCard(
                                label: 'Active creatives',
                                value: _formatNumber(activeCreatives),
                                trend: '+5%',
                                icon: Icons.collections_outlined,
                                accent: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cards = [
                            _HubLinkCard(
                              title: 'Google Ads',
                              subtitle: 'Search, display, remarketing, and conversion performance.',
                              icon: Icons.public_rounded,
                              accent: const Color(0xFF2563EB),
                              onTap: () => context.go('/ads/google'),
                            ),
                            _HubLinkCard(
                              title: 'Course Ads',
                              subtitle: 'Promote IELTS, TOEFL, CL, and special course offers.',
                              icon: Icons.menu_book_rounded,
                              accent: const Color(0xFFF97316),
                              onTap: () => context.go('/ads/courses'),
                            ),
                          ];

                          if (constraints.maxWidth < 840) {
                            return Column(
                              children: [
                                cards[0],
                                const SizedBox(height: 16),
                                cards[1],
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: 16),
                              Expanded(child: cards[1]),
                            ],
                          );
                        },
                      ),
                      if (_campaigns.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final narrow = constraints.maxWidth < 840;
                            final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                            final points = weekDays.asMap().entries.map((e) {
                              final count = _campaigns.where((c) {
                                final d = c['created_at']?.toString() ?? '';
                                return d.length >= 10 && DateTime.tryParse(d)?.weekday == e.key + 1;
                              }).length;
                              return InsightPoint(e.value, count.toDouble());
                            }).toList();

                            final line = InsightLineChartCard(
                              title: 'Weekly performance',
                              subtitle: 'Lead generation from promoted pages.',
                              points: points,
                              accent: const Color(0xFFDB2777),
                            );
                            final segments = InsightSegmentsCard(
                              title: 'Spend distribution',
                              subtitle: 'Budget allocation across the funnel.',
                              segments: const [
                                InsightSegment(label: 'Top of funnel', value: 42, color: Color(0xFFDB2777)),
                                InsightSegment(label: 'Retargeting', value: 34, color: Colors.orange),
                                InsightSegment(label: 'Conversion push', value: 24, color: Colors.teal),
                              ],
                            );

                            if (narrow) {
                              return Column(children: [line, const SizedBox(height: 16), segments]);
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: line),
                                const SizedBox(width: 16),
                                Expanded(child: segments),
                              ],
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      const InsightProcessDiagram(
                        title: 'Ad delivery diagram',
                        subtitle: 'A simple path from audience selection to conversion tracking.',
                        accent: Color(0xFFDB2777),
                        steps: [
                          InsightFlowStep(title: 'Audience', subtitle: 'Choose students, parents, or public traffic.', icon: Icons.groups_2_outlined),
                          InsightFlowStep(title: 'Creative', subtitle: 'Attach image, copy, and CTA destination.', icon: Icons.draw_outlined),
                          InsightFlowStep(title: 'Placement', subtitle: 'Deploy to banners, cards, or pop-up slots.', icon: Icons.splitscreen_outlined),
                          InsightFlowStep(title: 'Conversion', subtitle: 'Track clicks, leads, and enrollments.', icon: Icons.trending_up_outlined),
                        ],
                      ),
                      if (_campaigns.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        InsightTableCard(
                          title: 'Campaign table',
                          subtitle: 'Live promotion activity across ad placements.',
                          columns: ['Campaign', 'Placement', 'Budget', 'Status'],
                          rows: _campaigns.map((c) => [
                            c['name']?.toString() ?? '',
                            c['placement']?.toString() ?? '',
                            'PKR ${_formatNumber(((c['budget'] ?? 0) as num).toInt())}',
                            c['status']?.toString() ?? '',
                          ]).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      InsightPromoBanner(
                        title: 'Need a full campaign build?',
                        subtitle: 'Launch creative packs for upcoming admissions and seasonal promos in minutes.',
                        ctaLabel: 'Build Creative',
                        accent: const Color(0xFF7C3AED),
                        icon: Icons.auto_awesome_rounded,
                        onTap: () => context.go('/ads/creative-studio'),
                      ),
                      if (_campaigns.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(48),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text('No campaign data yet. Create your first campaign to get started.',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class AdCampaignsScreen extends StatefulWidget {
  const AdCampaignsScreen({super.key});

  @override
  State<AdCampaignsScreen> createState() => _AdCampaignsScreenState();
}

class _AdCampaignsScreenState extends State<AdCampaignsScreen> {
  List<Map<String, dynamic>> _campaigns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await Supabase.instance.client
          .from('ads_campaigns')
          .select()
          .order('created_at', ascending: false);
      if (mounted) setState(() => _campaigns = List<Map<String, dynamic>>.from(data));
    } catch (_) {
      if (mounted) setState(() => _campaigns = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final live = _campaigns.where((c) => (c['status']?.toString() ?? '').toLowerCase() == 'active').length;
    final budgetUsed = _campaigns.fold<double>(0, (s, c) => s + ((c['budget_used'] ?? 0) as num).toDouble());
    final budgetTotal = _campaigns.fold<double>(0, (s, c) => s + ((c['budget'] ?? 0) as num).toDouble());
    final goalPct = budgetTotal > 0 ? (budgetUsed / budgetTotal * 100).round() : 0;

    return _buildDetailScreen(
      context,
      title: 'Campaign Manager',
      subtitle: 'Plan budgets, schedule placements, and monitor campaign pacing.',
      accent: const Color(0xFF0EA5E9),
      heroLabel: 'Campaign orchestration',
      metrics: _campaigns.isNotEmpty
          ? [
              _MetricSeed('Live campaigns', '$live', '+3', Icons.campaign_outlined, const Color(0xFF0EA5E9)),
              _MetricSeed('Budget used', '$goalPct%', '+9%', Icons.account_balance_wallet_outlined, Colors.orange),
              _MetricSeed('Goal completion', '$goalPct%', '+6%', Icons.flag_outlined, Colors.blue),
            ]
          : [],
      points: _campaigns.asMap().entries.map((e) => InsightPoint('W${e.key + 1}', ((e.value['reach'] ?? 0) as num).toDouble())).toList(),
      rows: _campaigns.map((c) => [
        c['name']?.toString() ?? '',
        c['start_date']?.toString() ?? '',
        'PKR ${((c['budget'] ?? 0) as num).toInt()}',
        c['status']?.toString() ?? '',
      ]).toList(),
    );
  }

  Widget _buildDetailScreen(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color accent,
    required String heroLabel,
    required List<_MetricSeed> metrics,
    required List<InsightPoint> points,
    required List<List<String>> rows,
  }) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: InsightBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              InsightHeroCard(
                eyebrow: heroLabel,
                title: title,
                subtitle: subtitle,
                accent: accent,
                chips: const [
                  InsightStatChip(label: 'Workspace', value: 'Ready'),
                  InsightStatChip(label: 'Sync', value: 'Live'),
                ],
              ),
              if (metrics.isNotEmpty) ...[
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: metrics
                      .map((m) => SizedBox(
                            width: 240,
                            child: InsightMetricCard(
                              label: m.label,
                              value: m.value,
                              trend: m.trend,
                              icon: m.icon,
                              accent: m.accent,
                            ),
                          ))
                      .toList(),
                ),
              ],
              if (points.isNotEmpty) ...[
                const SizedBox(height: 16),
                InsightLineChartCard(title: 'Momentum', subtitle: 'Recent output and performance cadence.', points: points, accent: accent),
              ],
              if (rows.isNotEmpty) ...[
                const SizedBox(height: 16),
                InsightTableCard(
                  title: 'Queue',
                  subtitle: 'The current production and review workload.',
                  columns: const ['Item', 'Owner', 'State', 'Priority'],
                  rows: rows,
                ),
              ],
              if (_campaigns.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No campaign data.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreativeStudioScreen extends StatefulWidget {
  const CreativeStudioScreen({super.key});

  @override
  State<CreativeStudioScreen> createState() => _CreativeStudioScreenState();
}

class _CreativeStudioScreenState extends State<CreativeStudioScreen> {
  List<Map<String, dynamic>> _creatives = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await Supabase.instance.client
          .from('ad_creatives')
          .select()
          .order('created_at', ascending: false);
      if (mounted) setState(() => _creatives = List<Map<String, dynamic>>.from(data));
    } catch (_) {
      if (mounted) setState(() => _creatives = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final drafts = _creatives.where((c) => (c['status']?.toString() ?? '').toLowerCase() == 'draft').length;
    final approved = _creatives.where((c) => (c['status']?.toString() ?? '').toLowerCase() == 'approved').length;

    return _buildDetailScreen(
      context,
      title: 'Creative Studio',
      subtitle: 'Prepare creative variations, copy blocks, and brand-safe ad compositions.',
      accent: const Color(0xFFF97316),
      heroLabel: 'Creative production',
      metrics: _creatives.isNotEmpty
          ? [
              _MetricSeed('Drafts ready', '$drafts', '+5', Icons.design_services_outlined, const Color(0xFFF97316)),
              _MetricSeed('Approved sets', '$approved', '+2', Icons.verified_outlined, Colors.blue),
              _MetricSeed('A/B variants', '${_creatives.length}', '+1', Icons.alt_route_outlined, Colors.pink),
            ]
          : [],
      points: _creatives.asMap().entries.map((e) => InsightPoint('${e.key + 1}', ((e.value['version'] ?? 0) as num).toDouble())).toList(),
      rows: _creatives.map((c) => [
        c['title']?.toString() ?? '',
        c['owner']?.toString() ?? '',
        c['status']?.toString() ?? '',
        c['priority']?.toString() ?? '',
      ]).toList(),
    );
  }

  Widget _buildDetailScreen(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color accent,
    required String heroLabel,
    required List<_MetricSeed> metrics,
    required List<InsightPoint> points,
    required List<List<String>> rows,
  }) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: InsightBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              InsightHeroCard(
                eyebrow: heroLabel,
                title: title,
                subtitle: subtitle,
                accent: accent,
                chips: const [
                  InsightStatChip(label: 'Workspace', value: 'Ready'),
                  InsightStatChip(label: 'Sync', value: 'Live'),
                ],
              ),
              if (metrics.isNotEmpty) ...[
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: metrics
                      .map((m) => SizedBox(
                            width: 240,
                            child: InsightMetricCard(
                              label: m.label,
                              value: m.value,
                              trend: m.trend,
                              icon: m.icon,
                              accent: m.accent,
                            ),
                          ))
                      .toList(),
                ),
              ],
              if (points.isNotEmpty) ...[
                const SizedBox(height: 16),
                InsightLineChartCard(title: 'Momentum', subtitle: 'Recent output and performance cadence.', points: points, accent: accent),
              ],
              if (rows.isNotEmpty) ...[
                const SizedBox(height: 16),
                InsightTableCard(
                  title: 'Queue',
                  subtitle: 'The current production and review workload.',
                  columns: const ['Item', 'Owner', 'State', 'Priority'],
                  rows: rows,
                ),
              ],
              if (_creatives.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.brush_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No creative data.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class GoogleAdsScreen extends StatefulWidget {
  const GoogleAdsScreen({super.key});

  @override
  State<GoogleAdsScreen> createState() => _GoogleAdsScreenState();
}

class _GoogleAdsScreenState extends State<GoogleAdsScreen> {
  List<Map<String, dynamic>> _googleCampaigns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await Supabase.instance.client
          .from('google_ads_campaigns')
          .select()
          .order('created_at', ascending: false);
      if (mounted) setState(() => _googleCampaigns = List<Map<String, dynamic>>.from(data));
    } catch (_) {
      if (mounted) setState(() => _googleCampaigns = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return _buildDetailScreen(
      context,
      title: 'Google Ads',
      subtitle: 'Manage search campaigns, display retargeting, and keyword-driven enrollment funnels.',
      accent: const Color(0xFF2563EB),
      heroLabel: 'Google campaign desk',
      metrics: _googleCampaigns.isNotEmpty
          ? [
              _MetricSeed('Search CTR', '6.4%', '+0.9%', Icons.search_rounded, const Color(0xFF2563EB)),
              _MetricSeed('Cost / lead', 'PKR 420', '-8%', Icons.paid_outlined, Colors.blue),
              _MetricSeed('Remarketing pool', '5.2k', '+12%', Icons.refresh_rounded, Colors.orange),
            ]
          : [],
      points: _googleCampaigns.asMap().entries.map((e) => InsightPoint('${e.key + 1}', ((e.value['clicks'] ?? 0) as num).toDouble())).toList(),
      rows: _googleCampaigns.map((c) => [
        c['campaign_name']?.toString() ?? '',
        c['keywords']?.toString() ?? '',
        c['status']?.toString() ?? '',
        c['intent']?.toString() ?? '',
      ]).toList(),
    );
  }

  Widget _buildDetailScreen(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color accent,
    required String heroLabel,
    required List<_MetricSeed> metrics,
    required List<InsightPoint> points,
    required List<List<String>> rows,
  }) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: InsightBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              InsightHeroCard(
                eyebrow: heroLabel,
                title: title,
                subtitle: subtitle,
                accent: accent,
                chips: const [
                  InsightStatChip(label: 'Workspace', value: 'Ready'),
                  InsightStatChip(label: 'Sync', value: 'Live'),
                ],
              ),
              if (metrics.isNotEmpty) ...[
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: metrics
                      .map((m) => SizedBox(
                            width: 240,
                            child: InsightMetricCard(
                              label: m.label,
                              value: m.value,
                              trend: m.trend,
                              icon: m.icon,
                              accent: m.accent,
                            ),
                          ))
                      .toList(),
                ),
              ],
              if (points.isNotEmpty) ...[
                const SizedBox(height: 16),
                InsightLineChartCard(title: 'Momentum', subtitle: 'Recent output and performance cadence.', points: points, accent: accent),
              ],
              if (rows.isNotEmpty) ...[
                const SizedBox(height: 16),
                InsightTableCard(
                  title: 'Queue',
                  subtitle: 'The current production and review workload.',
                  columns: const ['Item', 'Owner', 'State', 'Priority'],
                  rows: rows,
                ),
              ],
              if (_googleCampaigns.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.public_off_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No Google Ads campaign data.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CourseAdsScreen extends StatefulWidget {
  const CourseAdsScreen({super.key});

  @override
  State<CourseAdsScreen> createState() => _CourseAdsScreenState();
}

class _CourseAdsScreenState extends State<CourseAdsScreen> {
  List<Map<String, dynamic>> _courseAds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await Supabase.instance.client
          .from('course_ads')
          .select()
          .order('created_at', ascending: false);
      if (mounted) setState(() => _courseAds = List<Map<String, dynamic>>.from(data));
    } catch (_) {
      if (mounted) setState(() => _courseAds = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return _buildDetailScreen(
      context,
      title: 'Course Ads',
      subtitle: 'Build promotions for individual courses, batch openings, and scholarship offers.',
      accent: const Color(0xFFF97316),
      heroLabel: 'Course promotion studio',
      metrics: _courseAds.isNotEmpty
          ? [
              _MetricSeed('Featured courses', '${_courseAds.length}', '+2', Icons.menu_book_rounded, const Color(0xFFF97316)),
              _MetricSeed('Lead conversion', '12.8%', '+1.6%', Icons.trending_up_rounded, Colors.blue),
              _MetricSeed('Scholarship promos', '3', '+1', Icons.workspace_premium_outlined, Colors.pink),
            ]
          : [],
      points: _courseAds.asMap().entries.map((e) => InsightPoint(e.value['course']?.toString() ?? '', ((e.value['leads'] ?? 0) as num).toDouble())).toList(),
      rows: _courseAds.map((c) => [
        c['title']?.toString() ?? '',
        c['slot']?.toString() ?? '',
        c['status']?.toString() ?? '',
        c['performance']?.toString() ?? '',
      ]).toList(),
    );
  }

  Widget _buildDetailScreen(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color accent,
    required String heroLabel,
    required List<_MetricSeed> metrics,
    required List<InsightPoint> points,
    required List<List<String>> rows,
  }) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: InsightBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              InsightHeroCard(
                eyebrow: heroLabel,
                title: title,
                subtitle: subtitle,
                accent: accent,
                chips: const [
                  InsightStatChip(label: 'Workspace', value: 'Ready'),
                  InsightStatChip(label: 'Sync', value: 'Live'),
                ],
              ),
              if (metrics.isNotEmpty) ...[
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: metrics
                      .map((m) => SizedBox(
                            width: 240,
                            child: InsightMetricCard(
                              label: m.label,
                              value: m.value,
                              trend: m.trend,
                              icon: m.icon,
                              accent: m.accent,
                            ),
                          ))
                      .toList(),
                ),
              ],
              if (points.isNotEmpty) ...[
                const SizedBox(height: 16),
                InsightLineChartCard(title: 'Momentum', subtitle: 'Recent output and performance cadence.', points: points, accent: accent),
              ],
              if (rows.isNotEmpty) ...[
                const SizedBox(height: 16),
                InsightTableCard(
                  title: 'Queue',
                  subtitle: 'The current production and review workload.',
                  columns: const ['Item', 'Owner', 'State', 'Priority'],
                  rows: rows,
                ),
              ],
              if (_courseAds.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No course ad data.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubLinkCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _HubLinkCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: accent),
          ],
        ),
      ),
    );
  }
}

class _MetricSeed {
  final String label;
  final String value;
  final String trend;
  final IconData icon;
  final Color accent;

  const _MetricSeed(this.label, this.value, this.trend, this.icon, this.accent);
}
