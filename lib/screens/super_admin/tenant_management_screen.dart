import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/providers/tenant_provider.dart';
import 'package:course_emis/utils/app_logger.dart';
import 'package:course_emis/utils/storage_buckets.dart';

class TenantManagementScreen extends ConsumerStatefulWidget {
  const TenantManagementScreen({super.key});

  @override
  ConsumerState<TenantManagementScreen> createState() =>
      _TenantManagementScreenState();
}

class _TenantManagementScreenState
    extends ConsumerState<TenantManagementScreen> {
  static const _pageSize = 10;

  String _searchQuery = '';
  String _filter = 'All';

  final _scrollCtl = ScrollController();
  int _visibleCount = _pageSize;
  bool _loadingMore = false;
  bool _initialLoading = true;

  List<Tenant> _filtered(List<Tenant> tenants) {
    return tenants.where((t) {
      final matchesSearch = _searchQuery.isEmpty ||
          t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.slug.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
      final matchesFilter = _filter == 'All' ||
          (_filter == 'Central' && t.isCentral) ||
          (_filter == 'Branch' && t.isBranch) ||
          (_filter == 'Active' && t.isActive) ||
          (_filter == 'Inactive' && !t.isActive);
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _scrollCtl.addListener(_onScroll);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _initialLoading = false);
    });
  }

  @override
  void dispose() {
    _scrollCtl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtl.hasClients) return;
    final position = _scrollCtl.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _initialLoading) return;
    final filtered = _filtered(ref.read(tenantProvider));
    if (_visibleCount >= filtered.length) return;
    setState(() => _loadingMore = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _visibleCount += _pageSize;
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tenants = ref.watch(tenantProvider);
    final filtered = _filtered(tenants);
    final visible = filtered.take(_visibleCount).toList();

    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.superAdmin);
                }
              }),
          title: Text(t(LModule.tenantManagement, ref))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTenantDialog(context),
        icon: const Icon(Icons.add_business_rounded),
        label: Text(t(L.add, ref)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() {
                          _searchQuery = v;
                          _visibleCount = _pageSize;
                        }),
                        decoration: InputDecoration(
                          hintText: 'Search tenants...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _filter,
                      items: ['All', 'Central', 'Branch', 'Active', 'Inactive']
                          .map((f) => DropdownMenuItem(
                                value: f,
                                child: Text(f),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _filter = v ?? 'All';
                        _visibleCount = _pageSize;
                      }),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(tt(LAll.all_x_tenants, ref, ['${filtered.length}']),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600])),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tenants.where((t) => t.isActive).length} active',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _initialLoading
                    ? ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pageSize,
                        itemBuilder: (_, __) => const _TenantSkeletonCard(),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.business_outlined,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(t(LAll.all_no_tenants_found, ref),
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 16)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollCtl,
                            padding: const EdgeInsets.all(16),
                            itemCount: visible.length + (_loadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= visible.length) {
                                return const _TenantSkeletonCard();
                              }
                              final tenant = visible[index];
                              return _TenantCard(
                                tenant: tenant,
                                onView: () =>
                                    _showTenantDetail(context, tenant),
                                onEdit: () =>
                                    _showTenantDialog(context, tenant: tenant),
                                onDelete: () => _deleteTenant(tenant),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTenantDialog(BuildContext context, {Tenant? tenant}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _TenantFormPage(tenant: tenant),
        fullscreenDialog: true,
      ),
    );
    if (result == true) setState(() {});
  }

  Future<void> _showTenantDetail(BuildContext context, Tenant tenant) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _TenantDetailPage(tenant: tenant),
      ),
    );
  }

  Future<void> _deleteTenant(Tenant tenant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(LAll.all_delete_tenant, ref)),
        content: Text('Delete "${tenant.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t(L.delete, ref)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(tenantProvider.notifier).deleteTenant(tenant.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${tenant.name}" deleted')),
          );
        }
      } catch (error, stackTrace) {
        if (!mounted) return;
        _showErrorDialog(
            'Failed to delete tenant', error, stackTrace,
            tenant: tenant.name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete tenant: $error')),
        );
      }
    }
  }

  void _showErrorDialog(String title, Object error, StackTrace? stackTrace,
      {String? tenant}) {
    AppLogger.e('$title — $error',
        error: error, stackTrace: stackTrace, tag: 'TenantMgmt');
    debugPrint('[$title] $error\n$stackTrace');
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tenant == null ? title : '$title ("$tenant")'),
        content: SingleChildScrollView(
          child: SelectableText('$error'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t(L.cancel, ref)),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  late final Animation<double> _opacity = Tween(begin: 0.35, end: 0.95).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class _TenantSkeletonCard extends StatelessWidget {
  const _TenantSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _ShimmerBox(width: 40, height: 40, radius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ShimmerBox(width: 160, height: 14),
                      const SizedBox(height: 8),
                      const _ShimmerBox(width: 100, height: 10),
                    ],
                  ),
                ),
                const _ShimmerBox(width: 56, height: 20, radius: 10),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const _ShimmerBox(width: 70, height: 18),
                const SizedBox(width: 8),
                const _ShimmerBox(width: 80, height: 18),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const _ShimmerBox(width: 28, height: 28, radius: 14),
                const SizedBox(width: 8),
                const _ShimmerBox(width: 28, height: 28, radius: 14),
                const SizedBox(width: 8),
                const _ShimmerBox(width: 28, height: 28, radius: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TenantLogo extends StatelessWidget {
  const _TenantLogo(
      {required this.tenant, required this.color, required this.radius});

  final Tenant tenant;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = tenant.logoUrl?.trim();
    final fallback =
        Icon(Icons.business_rounded, color: color, size: radius * 0.8);
    if (url == null || url.isEmpty) {
      return CircleAvatar(
          radius: radius,
          backgroundColor: color.withValues(alpha: 0.15),
          child: fallback);
    }
    return ClipOval(
      child: Image.network(
        url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(
          radius: radius,
          backgroundColor: color.withValues(alpha: 0.15),
          child: fallback,
        ),
      ),
    );
  }
}

class _TenantCard extends StatelessWidget {
  final Tenant tenant;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TenantCard({
    required this.tenant,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = tenant.isCentral ? Colors.purple : Colors.blue;
    final planColor = switch (tenant.plan) {
      'enterprise' => Colors.red,
      'premium' => Colors.orange,
      'standard' => Colors.blue,
      _ => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onView,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TenantLogo(tenant: tenant, color: color, radius: 25),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tenant.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(tenant.slug,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tenant.isActive
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tenant.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: tenant.isActive ? Colors.green : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _infoChip(Icons.category_rounded,
                      tenant.organizationType.toUpperCase(), color),
                  _infoChip(Icons.card_membership_rounded,
                      tenant.plan.toUpperCase(), planColor),
                  if (tenant.email != null)
                    _infoChip(Icons.email_outlined, tenant.email!, Colors.grey),
                  if (tenant.location != null)
                    _infoChip(Icons.location_on_outlined, tenant.location!,
                        Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'View',
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    onPressed: onView,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 20, color: Theme.of(context).colorScheme.error),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TenantDetailPage extends StatelessWidget {
  final Tenant tenant;
  const _TenantDetailPage({required this.tenant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tenant.isCentral ? Colors.purple : Colors.blue;
    final planColor = switch (tenant.plan) {
      'enterprise' => Colors.red,
      'premium' => Colors.orange,
      'standard' => Colors.blue,
      _ => Colors.grey,
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.superAdmin);
              }
            }),
        title: const Text('Tenant Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.15), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                _TenantLogo(tenant: tenant, color: color, radius: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tenant.name,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(tenant.slug,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _detailBadge(
                              tenant.organizationType.toUpperCase(), color),
                          _detailBadge(tenant.plan.toUpperCase(), planColor),
                          _detailBadge(tenant.isActive ? 'Active' : 'Inactive',
                              tenant.isActive ? Colors.green : Colors.red),
                          if (tenant.featured)
                            _detailBadge('Featured', Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _detailSection(context, 'Organization', [
            _detailRow(Icons.tag, 'Tenant Code', tenant.tenantCode ?? '�'),
            _detailRow(Icons.category_rounded, 'Organization Type',
                tenant.organizationType.toUpperCase()),
            _detailRow(Icons.hub_outlined, 'Parent Organization',
                tenant.parentName ?? '�'),
            _detailRow(Icons.link, 'Slug', tenant.slug),
            _detailRow(Icons.verified_outlined, 'Status',
                tenant.isActive ? 'Active' : 'Inactive'),
          ]),
          const SizedBox(height: 20),
          _detailSection(context, 'Contact', [
            _detailRow(Icons.email_outlined, 'Email', tenant.email ?? '�'),
            _detailRow(Icons.phone_outlined, 'Phone', tenant.phone ?? '�'),
            _detailRow(
                Icons.location_on_outlined, 'Address', tenant.location ?? '�'),
            _detailRow(Icons.language, 'Website', tenant.website ?? '�'),
            if (tenant.ownerEmail != null)
              _detailRow(
                  Icons.person_outline, 'Owner Email', tenant.ownerEmail!),
            if (tenant.contactPhone != null)
              _detailRow(Icons.contact_phone_outlined, 'Contact Phone',
                  tenant.contactPhone!),
            if (tenant.latitude != null)
              _detailRow(
                  Icons.map_outlined, 'Latitude', tenant.latitude!.toString()),
            if (tenant.longitude != null)
              _detailRow(Icons.explore_outlined, 'Longitude',
                  tenant.longitude!.toString()),
          ]),
          const SizedBox(height: 20),
          _detailSection(context, 'Services & Hours', [
            _detailRow(Icons.handyman_outlined, 'Services',
                tenant.services.isEmpty ? '—' : tenant.services.join(', ')),
            _detailRow(
                Icons.schedule,
                'Working Hours',
                tenant.workingHours?['open'] != null ||
                        tenant.workingHours?['close'] != null
                    ? '${tenant.workingHours?['open'] ?? '—'} – ${tenant.workingHours?['close'] ?? '—'}'
                    : '—'),
          ]),
          const SizedBox(height: 20),
          _detailSection(context, 'Plan & Limits', [
            _detailRow(Icons.card_membership_rounded, 'Plan',
                tenant.plan.toUpperCase()),
            _detailRow(Icons.group_outlined, 'Max Users', '${tenant.maxUsers}'),
            _detailRow(Icons.storage_outlined, 'Max Storage',
                '${tenant.maxStorageMB} MB'),
            if (tenant.activeUsersCount != null)
              _detailRow(
                  Icons.group, 'Active Users', '${tenant.activeUsersCount}'),
            if (tenant.totalStudentsCount != null)
              _detailRow(Icons.school_outlined, 'Total Students',
                  '${tenant.totalStudentsCount}'),
            if (tenant.totalBranchesCount != null)
              _detailRow(Icons.account_tree_outlined, 'Total Branches',
                  '${tenant.totalBranchesCount}'),
          ]),
          const SizedBox(height: 20),
          _detailSection(context, 'Other', [
            _detailRow(Icons.notes, 'Description', tenant.description ?? '—'),
            _detailRow(Icons.event_outlined, 'Created At',
                _formatDate(tenant.createdAt)),
            if (tenant.expiryDate != null)
              _detailRow(Icons.event_busy_outlined, 'Expiry Date',
                  _formatDate(tenant.expiryDate!)),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd';
  }

  Widget _detailBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _detailSection(BuildContext context, String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantFormPage extends ConsumerStatefulWidget {
  final Tenant? tenant;
  const _TenantFormPage({this.tenant});

  @override
  ConsumerState<_TenantFormPage> createState() => _TenantFormPageState();
}

class _TenantFormPageState extends ConsumerState<_TenantFormPage> {
  late final TextEditingController _nameCtl;
  late final TextEditingController _slugCtl;
  late final TextEditingController _tenantCodeCtl;
  late final TextEditingController _emailCtl;
  late final TextEditingController _phoneCtl;
  late final TextEditingController _addressCtl;
  late final TextEditingController _websiteCtl;
  late final TextEditingController _descriptionCtl;
  late final TextEditingController _latitudeCtl;
  late final TextEditingController _longitudeCtl;
  late final TextEditingController _openTimeCtl;
  late final TextEditingController _closeTimeCtl;
  late final TextEditingController _serviceCtl;
  late final TextEditingController _maxUsersCtl;
  late final TextEditingController _maxStorageCtl;
  late String _selectedPlan;
  late String _selectedType;
  String? _parentTenantId;
  late bool _isActive;
  late bool _featured;
  final List<String> _services = [];
  String? _logoUrl;
  Uint8List? _selectedLogoBytes;
  bool _uploadingLogo = false;

  int _currentStep = 0;
  final _pageCtl = PageController();

  bool get _isEdit => widget.tenant != null;

  static const _steps = ['Organization', 'Contact', 'Details', 'Limits'];
  static const _stepIcons = [
    Icons.business,
    Icons.contact_mail,
    Icons.description,
    Icons.storage,
  ];

  @override
  void initState() {
    super.initState();
    final tenant = widget.tenant;
    AppLogger.log('[TenantForm] initState — mode=${_isEdit ? 'edit' : 'add'}',
        tag: 'TenantForm');
    if (tenant != null) {
      AppLogger.log(
          '[TenantForm] loading existing tenant: id=${tenant.id}, name=${tenant.name}, slug=${tenant.slug}, tenantCode=${tenant.tenantCode}, type=${tenant.organizationType}, parent=${tenant.parentTenantId}',
          tag: 'TenantForm');
    }
    _nameCtl = TextEditingController(text: tenant?.name ?? '');
    _slugCtl = TextEditingController(text: tenant?.slug ?? '');
    _tenantCodeCtl = TextEditingController(text: tenant?.tenantCode ?? '');
    _emailCtl = TextEditingController(text: tenant?.email ?? '');
    _phoneCtl = TextEditingController(text: tenant?.phone ?? '');
    _addressCtl = TextEditingController(text: tenant?.location ?? '');
    _websiteCtl = TextEditingController(text: tenant?.website ?? '');
    _descriptionCtl = TextEditingController(text: tenant?.description ?? '');
    _latitudeCtl =
        TextEditingController(text: tenant?.latitude?.toString() ?? '');
    _longitudeCtl =
        TextEditingController(text: tenant?.longitude?.toString() ?? '');
    _openTimeCtl = TextEditingController(
        text: tenant?.workingHours?['open']?.toString() ?? '');
    _closeTimeCtl = TextEditingController(
        text: tenant?.workingHours?['close']?.toString() ?? '');
    _serviceCtl = TextEditingController();
    _maxUsersCtl = TextEditingController(text: '${tenant?.maxUsers ?? 100}');
    _maxStorageCtl =
        TextEditingController(text: '${tenant?.maxStorageMB ?? 1024}');
    _selectedPlan = tenant?.plan ?? 'standard';
    _selectedType = tenant?.organizationType ?? 'branch';
    _parentTenantId = tenant?.parentTenantId;
    _isActive = tenant?.isActive ?? true;
    _featured = tenant?.featured ?? false;
    _logoUrl = tenant?.logoUrl;
    _services.addAll(tenant?.services ?? const []);
    AppLogger.log(
        '[TenantForm] initState loaded — featured=$_featured, services=${_services.length}, workingHours=${tenant?.workingHours}',
        tag: 'TenantForm');
  }

  @override
  void dispose() {
    _pageCtl.dispose();
    _nameCtl.dispose();
    _slugCtl.dispose();
    _tenantCodeCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _addressCtl.dispose();
    _websiteCtl.dispose();
    _descriptionCtl.dispose();
    _latitudeCtl.dispose();
    _longitudeCtl.dispose();
    _openTimeCtl.dispose();
    _closeTimeCtl.dispose();
    _serviceCtl.dispose();
    _maxUsersCtl.dispose();
    _maxStorageCtl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      AppLogger.log(
          '[TenantForm] Next — ${_steps[_currentStep]} -> ${_steps[_currentStep + 1]}',
          tag: 'TenantForm');
      setState(() => _currentStep++);
      _pageCtl.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      AppLogger.log(
          '[TenantForm] Back — ${_steps[_currentStep]} -> ${_steps[_currentStep - 1]}',
          tag: 'TenantForm');
      setState(() => _currentStep--);
      _pageCtl.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _save() async {
    final name = _nameCtl.text.trim();
    final slug = _slugCtl.text.trim();
    AppLogger.log(
        '[TenantForm] _save() called — mode=${_isEdit ? 'edit' : 'add'}',
        tag: 'TenantForm');
    AppLogger.log(
        '[TenantForm] Step1 Organization — name="$name", slug="$slug", tenantCode="${_tenantCodeCtl.text.trim()}", type=$_selectedType, parentId=$_parentTenantId, isActive=$_isActive',
        tag: 'TenantForm');
    AppLogger.log(
        '[TenantForm] Step2 Contact — email="${_emailCtl.text.trim()}", phone="${_phoneCtl.text.trim()}", address="${_addressCtl.text.trim()}", website="${_websiteCtl.text.trim()}"',
        tag: 'TenantForm');
    AppLogger.log(
        '[TenantForm] Step3 Details — description="${_descriptionCtl.text.trim()}", logoUrl="$_logoUrl", featured=$_featured, services=${_services.join(', ')}',
        tag: 'TenantForm');
    AppLogger.log(
        '[TenantForm] Extra — latitude="${_latitudeCtl.text.trim()}", longitude="${_longitudeCtl.text.trim()}", workingHours={open: "${_openTimeCtl.text.trim()}", close: "${_closeTimeCtl.text.trim()}"}',
        tag: 'TenantForm');
    AppLogger.log(
        '[TenantForm] Step4 Limits — plan=$_selectedPlan, maxUsers="${_maxUsersCtl.text.trim()}", maxStorageMB="${_maxStorageCtl.text.trim()}"',
        tag: 'TenantForm');
    if (name.isEmpty || slug.isEmpty) {
      AppLogger.w(
          '[TenantForm] SAVE BLOCKED — name/slug empty (name="$name", slug="$slug")',
          tag: 'TenantForm');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and slug are required')),
      );
      return;
    }
    debugPrint('[tenant_management_screen] Save button CLICKED');
    final centrals =
        ref.read(tenantProvider).where((t) => t.isCentral).toList();
    final parentId = _selectedType == 'branch' ? _parentTenantId : null;
    String? parentName;
    if (parentId != null) {
      for (final c in centrals) {
        if (c.id == parentId) {
          parentName = c.name;
          break;
        }
      }
    }
    AppLogger.log(
        '[TenantForm] parent resolved — parentId=$parentId, parentName=$parentName',
        tag: 'TenantForm');

    // If the picker upload failed earlier, retry it here so a picked logo is
    // still persisted with the tenant instead of being silently dropped.
    if (_selectedLogoBytes != null && _logoUrl == null) {
      try {
        final url = await _uploadLogoToBucket(_selectedLogoBytes!, '.jpg');
        AppLogger.log(
            '[TenantForm] logo uploaded at save (retry) — $url',
            tag: 'TenantForm');
        if (mounted) setState(() => _logoUrl = url);
      } catch (error, stackTrace) {
        AppLogger.e('Retry logo upload at save failed.',
            error: error, stackTrace: stackTrace, tag: 'TenantForm');
      }
    }

    final tenant = Tenant(
      id: widget.tenant?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      slug: slug,
      tenantCode: _tenantCodeCtl.text.trim().isEmpty
          ? null
          : _tenantCodeCtl.text.trim(),
      organizationType: _selectedType,
      parentTenantId: parentId,
      parentName: parentName,
      description: _descriptionCtl.text.trim().isEmpty
          ? null
          : _descriptionCtl.text.trim(),
      logoUrl: _logoUrl,
      featured: _featured,
      latitude: double.tryParse(_latitudeCtl.text.trim()),
      longitude: double.tryParse(_longitudeCtl.text.trim()),
      website: _websiteCtl.text.trim().isEmpty ? null : _websiteCtl.text.trim(),
      location:
          _addressCtl.text.trim().isEmpty ? null : _addressCtl.text.trim(),
      phone: _phoneCtl.text.trim().isEmpty ? null : _phoneCtl.text.trim(),
      email: _emailCtl.text.trim().isEmpty ? null : _emailCtl.text.trim(),
      services: List<String>.from(_services),
      workingHours: {
        'open': _openTimeCtl.text.trim(),
        'close': _closeTimeCtl.text.trim(),
      },
      plan: _selectedPlan,
      maxUsers: int.tryParse(_maxUsersCtl.text.trim()) ?? 100,
      maxStorageMB: int.tryParse(_maxStorageCtl.text.trim()) ?? 1024,
      isActive: _isActive,
      createdAt: widget.tenant?.createdAt ?? DateTime.now(),
    );

    if (_isEdit) {
      AppLogger.log(
          '[TenantForm] calling updateTenant(id=${tenant.id}, name=${tenant.name})',
          tag: 'TenantForm');
      try {
        await ref.read(tenantProvider.notifier).updateTenant(tenant);
      } catch (error, stackTrace) {
        if (!mounted) return;
        _showErrorDialog(
            'Failed to update tenant', error, stackTrace,
            tenant: tenant.name);
        return;
      }
    } else {
      AppLogger.log(
          '[TenantForm] calling addTenant(id=${tenant.id}, name=${tenant.name})',
          tag: 'TenantForm');
      try {
        await ref.read(tenantProvider.notifier).addTenant(tenant);
      } catch (error, stackTrace) {
        if (!mounted) return;
        _showErrorDialog(
            'Failed to create tenant', error, stackTrace,
            tenant: tenant.name);
        return;
      }
    }
    if (!mounted) return;
    AppLogger.log('[TenantForm] Tenant saved to Supabase — closing form.',
        tag: 'TenantForm');
    Navigator.pop(context, true);
  }

  void _showErrorDialog(String title, Object error, StackTrace? stackTrace,
      {String? tenant}) {
    AppLogger.e('$title — $error',
        error: error, stackTrace: stackTrace, tag: 'TenantForm');
    debugPrint('[$title] $error\n$stackTrace');
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tenant == null ? title : '$title ("$tenant")'),
        content: SingleChildScrollView(
          child: SelectableText('$error'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t(L.cancel, ref)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLogoSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) _pickLogo(source);
  }

  Future<void> _pickLogo(ImageSource source) async {
    setState(() => _uploadingLogo = true);
    try {
      final XFile? image =
          await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (image == null) {
        if (mounted) setState(() => _uploadingLogo = false);
        return;
      }
      final bytes = await image.readAsBytes();
      // Show the picked image immediately. This does not depend on a network
      // request or the bucket being public, so the user gets instant feedback.
      if (mounted) setState(() => _selectedLogoBytes = bytes);
      final ext =
          image.name.contains('.') ? '.${image.name.split('.').last}' : '.jpg';
      final url = await _uploadLogoToBucket(bytes, ext,
          contentType: image.mimeType ?? 'image/jpeg');
      AppLogger.log('[TenantForm] logo uploaded to branding bucket — $url',
          tag: 'TenantForm');
      if (mounted) setState(() => _logoUrl = url);
    } catch (error, stackTrace) {
      // Keep the local preview so the selected image still displays even if
      // the bucket upload fails. _save() will retry the upload if needed.
      AppLogger.e('Logo upload failed.',
          error: error, stackTrace: stackTrace, tag: 'TenantForm');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logo upload failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<String> _uploadLogoToBucket(Uint8List bytes, String ext,
      {String? contentType}) async {
    final storagePath =
        'tenants/${DateTime.now().millisecondsSinceEpoch}$ext';
    await Supabase.instance.client.storage
        .from(StorageBuckets.branding)
        .uploadBinary(storagePath, bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType ?? 'image/jpeg',
            ));
    return Supabase.instance.client.storage
        .from(StorageBuckets.branding)
        .getPublicUrl(storagePath);
  }

  Future<void> _pickTime(TextEditingController ctl) async {
    final now = TimeOfDay.now();
    final t = await showTimePicker(context: context, initialTime: now);
    if (t != null && mounted) ctl.text = t.format(context);
  }

  void _addService() {
    final v = _serviceCtl.text.trim();
    if (v.isEmpty || _services.contains(v)) return;
    setState(() => _services.add(v));
    _serviceCtl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.superAdmin);
              }
            }),
        title: Text(_isEdit ? 'Edit Tenant' : 'Add Tenant'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(L.cancel, ref)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: List.generate(_steps.length, (i) {
                final isActive = i <= _currentStep;
                final isCurrent = i == _currentStep;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _currentStep = i);
                      _pageCtl.animateToPage(i,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? cs.primary
                                    : cs.surfaceContainerHighest,
                              ),
                              child: Icon(_stepIcons[i],
                                  size: 16,
                                  color: isActive
                                      ? cs.onPrimary
                                      : cs.onSurfaceVariant),
                            ),
                            if (i < _steps.length - 1)
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: i < _currentStep
                                      ? cs.primary
                                      : cs.surfaceContainerHighest,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(_steps[i],
                            style: TextStyle(
                                fontSize: 10,
                                color: isCurrent
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: PageView(
              controller: _pageCtl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(context),
                _buildStep2(context),
                _buildStep3(context),
                _buildStep4(context),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  OutlinedButton(
                      onPressed: _prevStep, child: const Text('Back')),
                const Spacer(),
                if (_currentStep < _steps.length - 1)
                  FilledButton(onPressed: _nextStep, child: const Text('Next'))
                else
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: Text(_isEdit ? t(L.save, ref) : t(L.add, ref)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label, {IconData? icon}) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      );

  Widget _buildStep1(BuildContext context) {
    final centrals =
        ref.watch(tenantProvider).where((t) => t.isCentral).toList();
    AppLogger.log(
        '[TenantForm] Step1 build — name="${_nameCtl.text}", slug="${_slugCtl.text}", tenantCode="${_tenantCodeCtl.text}", type=$_selectedType, parentId=$_parentTenantId, active=$_isActive, centrals=${centrals.length}',
        tag: 'TenantForm');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _nameCtl,
            decoration: _dec('Name', icon: Icons.business),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _slugCtl,
            enabled: !_isEdit,
            decoration: _dec('Slug', icon: Icons.link),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tenantCodeCtl,
            decoration: _dec('Tenant Code', icon: Icons.tag),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Organization Type',
              border: OutlineInputBorder(),
            ),
            items: ['central', 'branch']
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.toUpperCase()),
                    ))
                .toList(),
            onChanged: (v) => setState(() {
              _selectedType = v ?? _selectedType;
              if (_selectedType == 'central') _parentTenantId = null;
            }),
          ),
          if (_selectedType == 'branch') ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _parentTenantId,
              decoration: const InputDecoration(
                labelText: 'Parent Organization',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('None')),
                ...centrals.map((c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(c.name),
                    )),
              ],
              onChanged: (v) => setState(() => _parentTenantId = v),
            ),
          ],
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t(LStatus.activeStatus, ref)),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context) {
    AppLogger.log(
        '[TenantForm] Step2 build — email="${_emailCtl.text}", phone="${_phoneCtl.text}", address="${_addressCtl.text}", website="${_websiteCtl.text}", lat="${_latitudeCtl.text}", lng="${_longitudeCtl.text}"',
        tag: 'TenantForm');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _emailCtl,
            keyboardType: TextInputType.emailAddress,
            decoration: _dec('Email', icon: Icons.email_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtl,
            keyboardType: TextInputType.phone,
            decoration: _dec('Phone', icon: Icons.phone_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressCtl,
            decoration: _dec('Address', icon: Icons.location_on_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _latitudeCtl,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            decoration: _dec('Latitude', icon: Icons.map_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _longitudeCtl,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            decoration: _dec('Longitude', icon: Icons.explore_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _websiteCtl,
            keyboardType: TextInputType.url,
            decoration: _dec('Website', icon: Icons.language),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(BuildContext context) {
    AppLogger.log(
        '[TenantForm] Step3 build — description="${_descriptionCtl.text}", logoUrl="$_logoUrl", featured=$_featured, services=${_services.join(', ')}',
        tag: 'TenantForm');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Logo (uploaded to branding bucket)',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 8),
          InkWell(
            onTap: _uploadingLogo ? null : _pickLogoSource,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: _selectedLogoBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child:
                          Image.memory(_selectedLogoBytes!, fit: BoxFit.cover),
                    )
                  : _logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            _logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 32, color: Colors.grey[600]),
                            const SizedBox(height: 8),
                            Text(
                                _uploadingLogo
                                    ? 'Uploading...'
                                    : 'Tap to upload logo',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
            ),
          ),
          if (_logoUrl != null)
            TextButton.icon(
              onPressed: () => setState(() {
                _logoUrl = null;
                _selectedLogoBytes = null;
              }),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Remove logo'),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionCtl,
            maxLines: 4,
            decoration: _dec('Description', icon: Icons.notes),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Featured'),
            subtitle: const Text('Show this tenant on the public site'),
            value: _featured,
            onChanged: (v) => setState(() => _featured = v),
          ),
          const SizedBox(height: 12),
          Text('Services',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _services)
                InputChip(
                  label: Text(s),
                  onDeleted: () => setState(() => _services.remove(s)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _serviceCtl,
                  decoration: _dec('Add a service', icon: Icons.add),
                  onSubmitted: (_) => _addService(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addService,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Working Hours',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickTime(_openTimeCtl),
                  child: InputDecorator(
                    decoration: _dec('Opening Time', icon: Icons.schedule),
                    child: Text(
                      _openTimeCtl.text.isEmpty
                          ? 'Set time'
                          : _openTimeCtl.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _pickTime(_closeTimeCtl),
                  child: InputDecorator(
                    decoration: _dec('Closing Time', icon: Icons.schedule),
                    child: Text(
                      _closeTimeCtl.text.isEmpty
                          ? 'Set time'
                          : _closeTimeCtl.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep4(BuildContext context) {
    AppLogger.log(
        '[TenantForm] Step4 build — plan=$_selectedPlan, maxUsers="${_maxUsersCtl.text}", maxStorageMB="${_maxStorageCtl.text}"',
        tag: 'TenantForm');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedPlan,
            decoration: const InputDecoration(
              labelText: 'Plan',
              border: OutlineInputBorder(),
            ),
            items: ['basic', 'standard', 'premium', 'enterprise']
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.toUpperCase()),
                    ))
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedPlan = v ?? _selectedPlan),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxUsersCtl,
            keyboardType: TextInputType.number,
            decoration: _dec('Max Users', icon: Icons.group_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxStorageCtl,
            keyboardType: TextInputType.number,
            decoration: _dec('Max Storage (MB)', icon: Icons.storage_outlined),
          ),
        ],
      ),
    );
  }
}
