import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/utils/storage_buckets.dart';
import 'package:course_emis/utils/app_logger.dart';

class BranchInfoScreen extends ConsumerStatefulWidget {
  const BranchInfoScreen({super.key});

  @override
  ConsumerState<BranchInfoScreen> createState() => _BranchInfoScreenState();
}

class _BranchInfoScreenState extends ConsumerState<BranchInfoScreen> {
  List<Map<String, dynamic>> _branches = [];
  bool _loading = true;
  bool _isSuperAdmin = false;

  String _searchQuery = '';
  String _statusFilter = 'all';
  bool? _hqFilter;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = v);
        _load();
      }
    });
  }

  void _setFilter(String key, dynamic value) {
    setState(() {
      if (key == 'status') _statusFilter = value as String;
      if (key == 'hq') _hqFilter = value as bool?;
    });
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final profile = await Supabase.instance.client
          .from('users')
          .select('role, tenant_id')
          .eq('id', user!.id)
          .maybeSingle();

      final role = profile?['role']?.toString() ?? '';
      final tenantId = profile?['tenant_id']?.toString();
      _isSuperAdmin = role == 'super_admin';

      final query = Supabase.instance.client
          .from('branches')
          .select('*, manager:manager_id(id, full_name, email, phone)');

      if (!_isSuperAdmin && tenantId != null) {
        query.eq('tenant_id', tenantId);
      }

      if (_statusFilter == 'active') query.eq('is_active', true);
      if (_statusFilter == 'inactive') query.eq('is_active', false);
      final hq = _hqFilter;
      if (hq != null) query.eq('is_headquarters', hq);

      if (_searchQuery.isNotEmpty) {
        query.or(
          'name.ilike.%$_searchQuery%,'
          'code.ilike.%$_searchQuery%,'
          'city.ilike.%$_searchQuery%,'
          'phone.ilike.%$_searchQuery%',
        );
      }

      final data = await query.order('name');
      if (mounted) {
        setState(() {
          _branches = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () { if (context.canPop()) { context.pop(); } else { context.go(AppRoutes.superAdmin); } },
        ),
        title: const Text('Branches & App Info'),
      ),
      floatingActionButton: _isSuperAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(context),
              icon: const Icon(Icons.add_business_rounded),
              label: Text(t(L.add, ref)),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: TextField(
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search by name, code, city...',
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          _buildFilterChip('All', _statusFilter == 'all',
                              () => _setFilter('status', 'all')),
                          const SizedBox(width: 6),
                          _buildFilterChip('Active', _statusFilter == 'active',
                              () => _setFilter('status', 'active')),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                              'Inactive', _statusFilter == 'inactive',
                              () => _setFilter('status', 'inactive')),
                          const SizedBox(width: 6),
                          _buildFilterChip('★ HQ', _hqFilter == true,
                              () => _setFilter('hq', _hqFilter == true ? null : true)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Text('${_branches.length} branches',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _branches.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.business_outlined,
                                      size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text('No branches found',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16)),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: _branches.length,
                              itemBuilder: (context, index) {
                                final branch = _branches[index];
                                return _BranchCard(
                                  branch: branch,
                                  isSuperAdmin: _isSuperAdmin,
                                  onEdit: () =>
                                      _showForm(context, branch: branch),
                                  onDelete: () => _delete(branch),
                                  onViewDetails: () =>
                                      _showDetails(context, branch),
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

  Future<void> _showForm(BuildContext context,
      {Map<String, dynamic>? branch}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _BranchFormPage(
          branch: branch,
          isSuperAdmin: _isSuperAdmin,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result == true) _load();
  }

  Future<void> _showDetails(BuildContext context,
      Map<String, dynamic> branch) async {
    await showDialog(
      context: context,
      builder: (ctx) => _BranchDetailsDialog(branch: branch),
    );
  }

  Future<void> _delete(Map<String, dynamic> branch) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Branch'),
        content: Text(
            'Delete "${branch['name']}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client
          .from('branches')
          .delete()
          .eq('id', branch['id']);
      _load();
    }
  }
}

class _BranchCard extends StatelessWidget {
  final Map<String, dynamic> branch;
  final bool isSuperAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;

  const _BranchCard({
    required this.branch,
    required this.isSuperAdmin,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final name = branch['name']?.toString() ?? '';
    final code = branch['code']?.toString();
    final city = branch['city']?.toString();
    final isActive = branch['is_active'] as bool? ?? true;
    final isHQ = branch['is_headquarters'] as bool? ?? false;
    final manager = branch['manager'] as Map<String, dynamic>?;
    final logoUrl = branch['logo_url']?.toString();
    final nid = branch['nid']?.toString();
    final openingTime = branch['opening_time']?.toString();
    final closingTime = branch['closing_time']?.toString();

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          InkWell(
            onTap: onViewDetails,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (isActive
                                ? Colors.blue
                                : Colors.grey)
                            .withValues(alpha: 0.15),
                        (isActive
                                ? Colors.blue.shade200
                                : Colors.grey.shade300)
                            .withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: logoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(logoUrl,
                                    width: 52, height: 52, fit: BoxFit.cover),
                              )
                            : Icon(Icons.business_rounded,
                                size: 40, color: Colors.blue.shade300),
                      ),
                      if (isHQ)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('HQ',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      if (!isActive)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('INACTIVE',
                                style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        if (code != null || city != null)
                          Text(
                            [code, city].where((x) => x != null).join(' · '),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const Spacer(),
                        if (manager != null)
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 12, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(manager['full_name'] ?? '',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey[500]),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        if (nid != null)
                          Text('NID #$nid',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[400])),
                        if (openingTime != null || closingTime != null)
                          Text(
                            '${openingTime != null ? openingTime.substring(0, 5) : '--'}-${closingTime != null ? closingTime.substring(0, 5) : '--'}',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[400]),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: isActive
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Icon(Icons.chevron_right_rounded,
                                size: 16, color: Colors.grey[400]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isSuperAdmin)
            Positioned(
              top: 4,
              right: 4,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 18,
                icon: Icon(Icons.more_vert_rounded,
                    color: Colors.grey[600]),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit')])),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete',
                                style: TextStyle(color: Colors.red))])),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BranchDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> branch;

  const _BranchDetailsDialog({required this.branch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = branch['name']?.toString() ?? '';
    final logoUrl = branch['logo_url']?.toString();
    final manager = branch['manager'] as Map<String, dynamic>?;
    final workingDays = branch['working_days'] as List<dynamic>?;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  image: logoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(logoUrl),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: logoUrl == null
                    ? const Icon(Icons.business_rounded,
                        size: 36, color: Colors.blue)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(name,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            if (branch['code'] != null)
              Center(
                child: Text('Code: ${branch['code']}',
                    style: TextStyle(color: Colors.grey[600])),
              ),
            const Divider(height: 24),
            _detailRow(Icons.badge_outlined, 'NID',
                '#${branch['nid']}'),
            _detailRow(
                Icons.location_on_outlined, 'Address', branch['address']),
            _detailRow(Icons.location_city_rounded, 'City', branch['city']),
            _detailRow(Icons.map_rounded, 'Province', branch['province']),
            _detailRow(Icons.public_rounded, 'Country', branch['country']),
            _detailRow(
                Icons.phone_outlined, 'Phone', branch['phone']),
            _detailRow(
                Icons.email_outlined, 'Email', branch['email']),
            _detailRow(Icons.language_outlined, 'Website', branch['website']),
            _detailRow(Icons.explore_outlined, 'Latitude',
                branch['latitude']?.toString()),
            _detailRow(Icons.explore_outlined, 'Longitude',
                branch['longitude']?.toString()),
            _detailRow(Icons.access_time_rounded, 'Opening Time',
                branch['opening_time']?.toString().substring(0, 5) ?? ''),
            _detailRow(Icons.access_time_rounded, 'Closing Time',
                branch['closing_time']?.toString().substring(0, 5) ?? ''),
            if (workingDays != null && workingDays.isNotEmpty)
              _detailRow(Icons.calendar_view_week_rounded, 'Working Days',
                  workingDays.join(', ')),
            _detailRow(Icons.calendar_today_rounded, 'Established',
                branch['established_date']?.toString()),
            _detailRow(Icons.person_rounded, 'Manager',
                manager?['full_name']?.toString()),
            _detailRow(Icons.check_circle_rounded, 'Status',
                branch['is_active'] == true ? 'Active' : 'Inactive'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _BranchFormPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? branch;
  final bool isSuperAdmin;

  const _BranchFormPage({
    this.branch,
    required this.isSuperAdmin,
  });

  @override
  ConsumerState<_BranchFormPage> createState() => _BranchFormPageState();
}

class _BranchFormPageState extends ConsumerState<_BranchFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtl;
  late final TextEditingController _nameArCtl;
  late final TextEditingController _nameDrCtl;
  late final TextEditingController _namePsCtl;
  late final TextEditingController _codeCtl;
  late final TextEditingController _addressCtl;
  late final TextEditingController _addressArCtl;
  late final TextEditingController _cityCtl;
  late final TextEditingController _cityArCtl;
  late final TextEditingController _provinceCtl;
  late final TextEditingController _countryCtl;
  late final TextEditingController _phoneCtl;
  late final TextEditingController _emailCtl;
  late final TextEditingController _websiteCtl;
  late final TextEditingController _latitudeCtl;
  late final TextEditingController _longitudeCtl;
  late final TextEditingController _openingTimeCtl;
  late final TextEditingController _closingTimeCtl;
  late final TextEditingController _establishedDateCtl;
  late bool _isActive;
  late bool _isHeadquarters;
  String? _selectedManagerId;
  List<Map<String, dynamic>> _profiles = [];
  List<String> _selectedWorkingDays = [];
  String? _logoUrl;
  bool _isUploadingLogo = false;
  bool _saving = false;

  static const _allDays = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];


  bool get _isEdit => widget.branch != null;

  @override
  void initState() {
    super.initState();
    final b = widget.branch;
    _nameCtl = TextEditingController(text: b?['name'] ?? '');
    _nameArCtl = TextEditingController(text: b?['name_ar'] ?? '');
    _nameDrCtl = TextEditingController(text: b?['name_dr'] ?? '');
    _namePsCtl = TextEditingController(text: b?['name_ps'] ?? '');
    _codeCtl = TextEditingController(text: b?['code'] ?? '');
    _addressCtl = TextEditingController(text: b?['address'] ?? '');
    _addressArCtl = TextEditingController(text: b?['address_ar'] ?? '');
    _cityCtl = TextEditingController(text: b?['city'] ?? '');
    _cityArCtl = TextEditingController(text: b?['city_ar'] ?? '');
    _provinceCtl = TextEditingController(text: b?['province'] ?? '');
    _countryCtl =
        TextEditingController(text: b?['country'] ?? 'Afghanistan');
    _phoneCtl = TextEditingController(text: b?['phone'] ?? '');
    _emailCtl = TextEditingController(text: b?['email'] ?? '');
    _websiteCtl = TextEditingController(text: b?['website'] ?? '');
    _latitudeCtl =
        TextEditingController(text: b?['latitude']?.toString() ?? '');
    _longitudeCtl =
        TextEditingController(text: b?['longitude']?.toString() ?? '');
    _openingTimeCtl =
        TextEditingController(text: b?['opening_time']?.toString() ?? '');
    _closingTimeCtl =
        TextEditingController(text: b?['closing_time']?.toString() ?? '');
    _establishedDateCtl = TextEditingController(
        text: b?['established_date']?.toString() ?? '');
    _isActive = b?['is_active'] as bool? ?? true;
    _isHeadquarters = b?['is_headquarters'] as bool? ?? false;
    _selectedManagerId = b?['manager']?['id']?.toString();
    _logoUrl = b?['logo_url']?.toString();
    final rawDays = b?['working_days'];
    if (rawDays is List) {
      _selectedWorkingDays = rawDays.cast<String>();
    } else {
      _selectedWorkingDays = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed'];
    }
    _loadManagers();
  }

  Future<void> _loadManagers() async {
    final data = await Supabase.instance.client
        .from('users')
        .select('id, full_name, role')
        .inFilter('role', [
      'admin', 'super_admin', 'ceo', 'manager',
      'staff', 'academic_support'
    ])
        .order('full_name');
    if (mounted) {
      setState(
          () => _profiles = List<Map<String, dynamic>>.from(data));
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _nameArCtl.dispose();
    _nameDrCtl.dispose();
    _namePsCtl.dispose();
    _codeCtl.dispose();
    _addressCtl.dispose();
    _addressArCtl.dispose();
    _cityCtl.dispose();
    _cityArCtl.dispose();
    _provinceCtl.dispose();
    _countryCtl.dispose();
    _phoneCtl.dispose();
    _emailCtl.dispose();
    _websiteCtl.dispose();
    _latitudeCtl.dispose();
    _longitudeCtl.dispose();
    _openingTimeCtl.dispose();
    _closingTimeCtl.dispose();
    _establishedDateCtl.dispose();
    super.dispose();
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
    setState(() => _isUploadingLogo = true);
    final oldUrl = _logoUrl;
    AppLogger.log('[BranchInfo] _pickLogo start — source=$source',
        tag: 'BranchInfo');
    try {
      final XFile? image =
          await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (image == null) {
        if (mounted) setState(() => _isUploadingLogo = false);
        return;
      }
      final bytes = await File(image.path).readAsBytes();
      final ext =
          image.name.contains('.') ? '.${image.name.split('.').last}' : '.jpg';
      final storagePath = 'branches/${DateTime.now().millisecondsSinceEpoch}$ext';
      await Supabase.instance.client.storage
          .from(StorageBuckets.branding)
          .uploadBinary(storagePath, bytes,
              fileOptions: const FileOptions(upsert: true));
      final url = Supabase.instance.client.storage
          .from(StorageBuckets.branding)
          .getPublicUrl(storagePath);
      AppLogger.log(
          '[BranchInfo] logo uploaded to branding/branches — $url',
          tag: 'BranchInfo');
      if (mounted) setState(() => _logoUrl = url);
    } catch (e) {
      // Restore the previous URL but do NOT keep a stale local preview: let
      // the UI fall back to the network image (or placeholder) of oldUrl.
      if (mounted) {
        setState(() => _logoUrl = oldUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logo upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      String? tenantId;
      if (widget.isSuperAdmin && _isEdit) {
        tenantId = widget.branch?['tenant_id']?.toString();
      } else if (!widget.isSuperAdmin) {
        final profile = await Supabase.instance.client
            .from('users')
            .select('tenant_id')
            .eq('id', user!.id)
            .maybeSingle();
        tenantId = profile?['tenant_id']?.toString();
      }

      String? opt(String? v) =>
          v == null || v.trim().isEmpty ? null : v.trim();

      final payload = <String, dynamic>{
        'name': _nameCtl.text.trim(),
        'name_ar': opt(_nameArCtl.text),
        'name_dr': opt(_nameDrCtl.text),
        'name_ps': opt(_namePsCtl.text),
        'code': opt(_codeCtl.text),
        'address': opt(_addressCtl.text),
        'address_ar': opt(_addressArCtl.text),
        'city': opt(_cityCtl.text),
        'city_ar': opt(_cityArCtl.text),
        'province': opt(_provinceCtl.text),
        'country': opt(_countryCtl.text) ?? 'Afghanistan',
        'phone': opt(_phoneCtl.text),
        'email': opt(_emailCtl.text),
        'website': opt(_websiteCtl.text),
        'latitude': opt(_latitudeCtl.text),
        'longitude': opt(_longitudeCtl.text),
        'opening_time': opt(_openingTimeCtl.text),
        'closing_time': opt(_closingTimeCtl.text),
        'working_days': _selectedWorkingDays.isEmpty
            ? ['Sat', 'Sun', 'Mon', 'Tue', 'Wed']
            : _selectedWorkingDays,
        'established_date': opt(_establishedDateCtl.text),
        'is_active': _isActive,
        'is_headquarters': _isHeadquarters,
        'manager_id': _selectedManagerId,
         'logo_url': _logoUrl,
       };

      AppLogger.log('[BranchInfo] persisting — logo_url=$_logoUrl',
          tag: 'BranchInfo');

      if (tenantId != null) payload['tenant_id'] = tenantId;

      if (_isEdit) {
        await Supabase.instance.client
            .from('branches')
            .update(payload)
            .eq('id', widget.branch!['id']);
      } else {
        await Supabase.instance.client
            .from('branches')
            .insert(payload);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () { if (context.canPop()) { context.pop(); } else { context.go(AppRoutes.superAdmin); } },
        ),
        title: Text(_isEdit ? 'Edit Branch' : 'Add Branch'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            onPressed: _saving ? null : () { debugPrint('[branch_info_screen] Save button CLICKED'); _save(); },
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(_isEdit ? t(L.save, ref) : t(L.add, ref)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isSuperAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Super Admin: Full access to all branches',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              _sectionTitle(theme, 'Branch Logo'),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: _isUploadingLogo ? null : _pickLogoSource,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.grey[300]!),
                        image: _logoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(_logoUrl!),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: _isUploadingLogo
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            )
                          : Center(
                              child: Icon(Icons.add_photo_alternate_outlined,
                                  color: Colors.grey[400], size: 28),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Upload branch logo. PNG, JPEG, WebP up to 5MB',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle(theme, 'Basic Information'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(
                    labelText: 'Branch Name *',
                    border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameArCtl,
                      decoration: const InputDecoration(
                          labelText: 'Name (Arabic/Dari)',
                          border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _codeCtl,
                      decoration: const InputDecoration(
                          labelText: 'Branch Code',
                          border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameDrCtl,
                      decoration: const InputDecoration(
                          labelText: 'Name (Dari)',
                          border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _namePsCtl,
                      decoration: const InputDecoration(
                          labelText: 'Name (Pashto)',
                          border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle(theme, 'Contact Information'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtl,
                decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtl,
                decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _websiteCtl,
                decoration: const InputDecoration(
                    labelText: 'Website',
                    prefixIcon: Icon(Icons.language_outlined),
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 20),
              _sectionTitle(theme, 'Location'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeCtl,
                      decoration: const InputDecoration(
                          labelText: 'Latitude',
                          prefixIcon: Icon(Icons.explore_outlined),
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeCtl,
                      decoration: const InputDecoration(
                          labelText: 'Longitude',
                          prefixIcon: Icon(Icons.explore_outlined),
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtl,
                decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressArCtl,
                decoration: const InputDecoration(
                    labelText: 'Address (Arabic/Dari)',
                    border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtl,
                      decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cityArCtl,
                      decoration: const InputDecoration(
                          labelText: 'City (Arabic/Dari)',
                          border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _provinceCtl,
                      decoration: const InputDecoration(
                          labelText: 'Province',
                          border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _countryCtl,
                      decoration: const InputDecoration(
                          labelText: 'Country',
                          border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle(theme, 'Hours & Schedule'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _openingTimeCtl,
                      decoration: const InputDecoration(
                          labelText: 'Opening Time (HH:MM)',
                          prefixIcon: Icon(Icons.access_time_rounded),
                          border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _closingTimeCtl,
                      decoration: const InputDecoration(
                          labelText: 'Closing Time (HH:MM)',
                          prefixIcon: Icon(Icons.access_time_rounded),
                          border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Working Days',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _allDays.map((day) {
                  final selected = _selectedWorkingDays.contains(day);
                  return FilterChip(
                    label: Text(day,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal)),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedWorkingDays.add(day);
                        } else {
                          _selectedWorkingDays.remove(day);
                        }
                      });
                    },
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _sectionTitle(theme, 'Management'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedManagerId,
                decoration: const InputDecoration(
                    labelText: 'Branch Manager',
                    border: OutlineInputBorder()),
                items: _profiles
                    .map((p) => DropdownMenuItem(
                          value: p['id']?.toString(),
                          child: Text(
                              '${p['full_name'] ?? ''} (${p['role'] ?? ''})'),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedManagerId = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _establishedDateCtl,
                decoration: const InputDecoration(
                    labelText: 'Established Date (YYYY-MM-DD)',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                subtitle: const Text('Enable or disable this branch'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Headquarters'),
                subtitle: const Text(
                    'Mark as the main headquarters branch'),
                value: _isHeadquarters,
                onChanged: (v) =>
                    setState(() => _isHeadquarters = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Text(title,
        style: theme.textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w600));
  }
}
