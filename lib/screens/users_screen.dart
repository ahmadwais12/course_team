import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/utils/storage_buckets.dart';
import 'package:course_emis/services/secure_storage_service.dart';
import 'package:course_emis/services/impersonation_service.dart';
import 'package:course_emis/providers/impersonation_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:course_emis/widgets/shimmer_loading.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  static const _pageSize = 10;

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _roleFilter = 'All';
  String _statusFilter = 'All';
  String _tenantFilter = 'All';
  List<Map<String, dynamic>> _tenants = [];
  bool _showFilters = false;
  RealtimeChannel? _channel;

  final _scrollCtl = ScrollController();
  int _visibleCount = _pageSize;
  bool _loadingMore = false;
  String? _impersonatingId;

  @override
  void initState() {
    super.initState();
    _scrollCtl.addListener(_onScroll);
    _loadUsers();
    _loadTenants();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
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
    if (_loadingMore || _isLoading) return;
    final filtered = _filteredUsers;
    if (_visibleCount >= filtered.length) return;
    setState(() => _loadingMore = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _visibleCount += _pageSize;
      _loadingMore = false;
    });
  }

  void _subscribeRealtime() {
    _channel = Supabase.instance.client
        .channel('profiles-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          table: 'users',
          schema: 'public',
          callback: (payload) {
            if (!mounted) return;
            setState(() {
              switch (payload.eventType) {
                case PostgresChangeEvent.insert:
                  _users.insert(0, payload.newRecord);
                  break;
                case PostgresChangeEvent.update:
                  final index = _users.indexWhere((u) =>
                      u['id']?.toString() ==
                      payload.newRecord['id']?.toString());
                  if (index != -1) {
                    _users[index] = payload.newRecord;
                  }
                  break;
                case PostgresChangeEvent.delete:
                  _users.removeWhere((u) =>
                      u['id']?.toString() ==
                      payload.oldRecord['id']?.toString());
                  break;
                default:
                  break;
              }
            });
          },
        )
        .subscribe();
  }

  Future<void> _loadTenants() async {
    try {
      final data = await Supabase.instance.client
          .from('tenants')
          .select('id, name')
          .order('name');
      if (mounted) {
        setState(() => _tenants = List<Map<String, dynamic>>.from(data));
      }
    } catch (_) {}
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
          _visibleCount = _pageSize;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    var list = _users;
    if (_roleFilter != 'All') {
      list = list
          .where((u) =>
              u['role']?.toString().toLowerCase() == _roleFilter.toLowerCase())
          .toList();
    }
    if (_statusFilter != 'All') {
      final active = _statusFilter == 'Active';
      list = list.where((u) => u['is_active'] == active).toList();
    }
    if (_tenantFilter != 'All') {
      list = list
          .where((u) => u['tenant_id']?.toString() == _tenantFilter)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((u) {
        return (u['full_name']?.toString().toLowerCase().contains(q) ??
                false) ||
            (u['email']?.toString().toLowerCase().contains(q) ?? false) ||
            (u['nid']?.toString().contains(q) ?? false) ||
            (u['phone']?.toString().contains(q) ?? false);
      }).toList();
    }
    return list;
  }

  List<String> get _roles {
    final roles = _users
        .map((u) => u['role']?.toString() ?? '')
        .where((r) => r.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...roles];
  }

  @override
  Widget build(BuildContext context) {
    final canImpersonate = resolveEffectiveRole(ref) == 'super_admin';
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          if (canImpersonate)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              tooltip: 'Impersonation Log',
              onPressed: () => _showImpersonationLog(context),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToUserPage(context),
        icon: const Icon(Icons.person_add),
        label: Text(t(L.add, ref)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: _isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pageSize,
                  itemBuilder: (_, __) => const _UserSkeletonCard(),
                )
              : Column(
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
                                hintText: 'Search name, email, NID, phone...',
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
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                                _showFilters
                                    ? Icons.filter_alt_off
                                    : Icons.filter_alt,
                                color: _showFilters
                                    ? Colors.black
                                    : Colors.grey[600]),
                            tooltip: 'Toggle filters',
                            onPressed: () =>
                                setState(() => _showFilters = !_showFilters),
                          ),
                        ],
                      ),
                    ),
                    if (_showFilters) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            // Role filter
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _roleFilter,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Role',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(12))),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  isDense: true,
                                ),
                                items: _roles
                                    .map((r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(r,
                                            overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: (v) => setState(() {
                                  _roleFilter = v ?? 'All';
                                  _visibleCount = _pageSize;
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status filter
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _statusFilter,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(12))),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  isDense: true,
                                ),
                                items: ['All', 'Active', 'Inactive']
                                    .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s,
                                            overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: (v) => setState(() {
                                  _statusFilter = v ?? 'All';
                                  _visibleCount = _pageSize;
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Tenant filter
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _tenantFilter,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Tenant',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(12))),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  isDense: true,
                                ),
                                items: [
                                  const DropdownMenuItem(
                                      value: 'All', child: Text('All')),
                                  ..._tenants.map((t) => DropdownMenuItem(
                                      value: t['id'].toString(),
                                      child: Text(t['name']?.toString() ?? '',
                                          overflow: TextOverflow.ellipsis))),
                                ],
                                onChanged: (v) => setState(() {
                                  _tenantFilter = v ?? 'All';
                                  _visibleCount = _pageSize;
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            '${_filteredUsers.length} users',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          if (_roleFilter != 'All' ||
                              _statusFilter != 'All' ||
                              _tenantFilter != 'All')
                            TextButton.icon(
                              icon: const Icon(Icons.clear_all, size: 16),
                              label: const Text('Clear filters'),
                              onPressed: () => setState(() {
                                _roleFilter = 'All';
                                _statusFilter = 'All';
                                _tenantFilter = 'All';
                                _searchQuery = '';
                                _visibleCount = _pageSize;
                              }),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filteredUsers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text('No users found',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16)),
                                ],
                              ),
                            )
                          : Builder(
                              builder: (context) {
                                final filtered = _filteredUsers;
                                final visible =
                                    filtered.take(_visibleCount).toList();
                                return ListView.builder(
                                  controller: _scrollCtl,
                                  padding: const EdgeInsets.all(16),
                                  itemCount:
                                      visible.length + (_loadingMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index >= visible.length) {
                                      return const _UserSkeletonCard();
                                    }
                                    final user = visible[index];
                                    final selfId = Supabase.instance.client
                                        .auth.currentUser?.id;
                                    final canLoginAs = canImpersonate &&
                                        user['id']?.toString() !=
                                            selfId?.toString() &&
                                        user['role'] != 'super_admin';
                                    return _UserCard(
                                      user: user,
                                      isLoading:
                                          _impersonatingId == user['id'],
                                      onView: () => _viewUser(user),
                                      onEdit: () => _navigateToUserPage(context,
                                          user: user),
                                      onDelete: () => _deleteUser(user),
                                      onLoginAs: canLoginAs
                                          ? () => _startImpersonation(user)
                                          : null,
                                    );
                                  },
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

  Future<void> _navigateToUserPage(BuildContext context,
      {Map<String, dynamic>? user}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _UserFormPage(user: user),
        fullscreenDialog: true,
      ),
    );
    if (result == true) _loadUsers();
  }

  void _viewUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user['full_name']?.toString() ?? 'User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: user['avatar_url'] != null &&
                          user['avatar_url'].toString().isNotEmpty
                      ? NetworkImage(user['avatar_url'].toString())
                      : null,
                  child: user['avatar_url'] == null ||
                          user['avatar_url'].toString().isEmpty
                      ? Icon(Icons.person, size: 40, color: Colors.grey[400])
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              _detailRow('Name', user['full_name']?.toString()),
              _detailRow('NID', '#${user['nid']?.toString() ?? '?'}'),
              _detailRow('Email', user['email']?.toString()),
              _detailRow('Role', user['role']?.toString()),
              _detailRow('Phone', user['phone']?.toString()),
              _detailRow(
                  'Status', user['is_active'] == true ? 'Active' : 'Inactive'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Delete ${user['full_name'] ?? 'this user'}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client
          .from('users')
          .delete()
          .eq('id', user['id']);
      _loadUsers();
    }
  }

  Future<void> _startImpersonation(Map<String, dynamic> user) async {
    final name = user['full_name']?.toString() ?? 'this user';
    final role = user['role']?.toString().replaceAll('_', ' ') ?? 'user';
    final reasonCtl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login As User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You are about to impersonate $name ($role).'),
              const SizedBox(height: 8),
              Text(
                'You will act as this user for 30 minutes. Every action is '
                'logged with your identity as the originator.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonCtl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Reason (required)',
                  hintText: 'e.g. Support request, debugging, review',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.admin_panel_settings, size: 18),
            label: const Text('Login As'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final reason = reasonCtl.text.trim();
    if (reason.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reason is required for impersonation')),
      );
      return;
    }

    setState(() => _impersonatingId = user['id']?.toString());
    try {
      await ref.read(impersonationProvider.notifier).start(
            targetUserId: user['id'].toString(),
            reason: reason,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Now impersonating $name as $role')),
      );
      context.go(homeRouteForRole(user['role']?.toString().toLowerCase()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Login As failed: ${e.toString().replaceAll('\n', ' ')}')),
      );
    } finally {
      if (mounted) setState(() => _impersonatingId = null);
    }
  }

  Future<void> _showImpersonationLog(BuildContext context) async {
    final service = ref.read(impersonationServiceProvider);
    showDialog(
      context: context,
      builder: (ctx) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: service.getHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AlertDialog(
                content: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final rows = snapshot.data ?? [];
            return AlertDialog(
              title: const Text('Impersonation Log'),
              content: SizedBox(
                width: 520,
                child: rows.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No impersonation activity yet.'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          final r = rows[index];
                          final action = r['action']?.toString() ?? 'n/a';
                          final targetRole = r['target_role']?.toString() ?? 'unknown';
                          final actorName = r['actor'] is Map
                              ? (r['actor'] as Map)['full_name']?.toString() ??
                                  'Admin'
                              : 'Admin';
                          final targetName = r['target'] is Map
                              ? (r['target'] as Map)['full_name']?.toString() ??
                                  r['target_user_id']?.toString()
                              : r['target_user_id']?.toString();
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              action == 'login_as'
                                  ? Icons.login
                                  : Icons.logout,
                              color: action == 'login_as'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            title: Text(
                                '$actorName ? $targetName ($targetRole)'),
                            subtitle: Text(
                              '${_formatLogTime(r['created_at'])} · '
                              '${r['details'] is Map && (r['details'] as Map)['reason'] != null ? 'Reason: ${(r['details'] as Map)['reason']}' : action}',
                            ),
                            isThreeLine: false,
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(t(L.close, ref)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatLogTime(dynamic value) {
    if (value == null) return '—';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.toString();
    }
  }
}

class _UserFormPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? user;
  const _UserFormPage({this.user});

  @override
  ConsumerState<_UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends ConsumerState<_UserFormPage> {
  int _currentStep = 0;
  final _pageCtl = PageController();
  bool _isSaving = false;

  late final TextEditingController _nameCtl;
  late final TextEditingController _nameArCtl;
  late final TextEditingController _firstNameArCtl;
  late final TextEditingController _lastNameArCtl;
  late final TextEditingController _emailCtl;
  late final TextEditingController _phoneCtl;
  late final TextEditingController _addressCtl;
  late final TextEditingController _tazkiraCtl;
  late final TextEditingController _passportCtl;
  late final TextEditingController _nationalityCtl;
  late final TextEditingController _religionCtl;
  late final TextEditingController _fatherNameCtl;
  late final TextEditingController _fatherNameArCtl;
  late final TextEditingController _emergencyNameCtl;
  late final TextEditingController _emergencyPhoneCtl;
  late final TextEditingController _emergencyRelationCtl;
  late final TextEditingController _passwordCtl;
  late final TextEditingController _guardianNameCtl;
  late final TextEditingController _guardianEmailCtl;
  late final TextEditingController _guardianPhoneCtl;
  late final TextEditingController _guardianPasswordCtl;

  String _selectedRole = 'admin';
  String? _selectedBloodGroup;
  String? _selectedMaritalStatus;
  String? _selectedGuardianRelationship;
  bool _isActive = true;
  String? _avatarUrl;
  Uint8List? _avatarBytes;
  bool _isUploadingAvatar = false;
  String? _guardianAvatarUrl;
  Uint8List? _guardianAvatarBytes;
  bool _isUploadingGuardianAvatar = false;
  List<Map<String, dynamic>> _tenants = [];
  bool _loadingTenants = true;
  Map<String, dynamic>? _selectedTenant;

  bool get _isEdit => widget.user != null;

  bool get _requiresTenant => _selectedRole != 'super_admin';

  static const _roles = [
    'super_admin',
    'admin',
    'teacher',
    'student',
    'guardian',
    'staff',
    'academic_support',
    'accountant',
    'librarian',
    'receptionist',
    'hr_manager',
    'inventory_manager',
    'it_support',
    'maintenance',
    'event_manager',
    'complaint_manager',
  ];
  static const _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];
  static const _maritalStatuses = ['single', 'married', 'divorced', 'widowed'];
  static const _guardianRelationships = [
    'father',
    'mother',
    'guardian',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtl = TextEditingController(text: u?['full_name']?.toString() ?? '');
    _nameArCtl =
        TextEditingController(text: u?['full_name_ar']?.toString() ?? '');
    _firstNameArCtl =
        TextEditingController(text: u?['first_name_ar']?.toString() ?? '');
    _lastNameArCtl =
        TextEditingController(text: u?['last_name_ar']?.toString() ?? '');
    _emailCtl = TextEditingController(text: u?['email']?.toString() ?? '');
    _phoneCtl = TextEditingController(text: u?['phone']?.toString() ?? '');
    _addressCtl = TextEditingController(text: u?['address']?.toString() ?? '');
    _tazkiraCtl =
        TextEditingController(text: u?['tazkira_number']?.toString() ?? '');
    _passportCtl =
        TextEditingController(text: u?['passport_id']?.toString() ?? '');
    _nationalityCtl =
        TextEditingController(text: u?['nationality']?.toString() ?? '');
    _religionCtl =
        TextEditingController(text: u?['religion']?.toString() ?? '');
    _fatherNameCtl =
        TextEditingController(text: u?['father_name']?.toString() ?? '');
    _fatherNameArCtl =
        TextEditingController(text: u?['father_name_ar']?.toString() ?? '');
    _emergencyNameCtl = TextEditingController(
        text: u?['emergency_contact_name']?.toString() ?? '');
    _emergencyPhoneCtl = TextEditingController(
        text: u?['emergency_contact_phone']?.toString() ?? '');
    _emergencyRelationCtl = TextEditingController(
        text: u?['emergency_contact_relation']?.toString() ?? '');
    _passwordCtl = TextEditingController();
    _guardianNameCtl = TextEditingController();
    _guardianEmailCtl = TextEditingController();
    _guardianPhoneCtl = TextEditingController();
    _guardianPasswordCtl = TextEditingController();
    _selectedRole = u?['role']?.toString() ?? 'admin';
    _selectedBloodGroup = u?['blood_group']?.toString();
    _selectedMaritalStatus = u?['marital_status']?.toString();
    _isActive = u?['is_active'] != false;
    _avatarUrl = u?['avatar_url']?.toString();
    _selectedTenant = u?['tenant_id'] != null ? {'id': u!['tenant_id']} : null;
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    try {
      final data = await Supabase.instance.client
          .from('tenants')
          .select('id, name, slug')
          .eq('is_active', true)
          .order('name');
      if (mounted) {
        setState(() {
          _tenants = List<Map<String, dynamic>>.from(data);
          _loadingTenants = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTenants = false);
    }
  }

  @override
  void dispose() {
    _pageCtl.dispose();
    _nameCtl.dispose();
    _nameArCtl.dispose();
    _firstNameArCtl.dispose();
    _lastNameArCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _addressCtl.dispose();
    _tazkiraCtl.dispose();
    _passportCtl.dispose();
    _nationalityCtl.dispose();
    _religionCtl.dispose();
    _fatherNameCtl.dispose();
    _fatherNameArCtl.dispose();
    _emergencyNameCtl.dispose();
    _emergencyPhoneCtl.dispose();
    _emergencyRelationCtl.dispose();
    _passwordCtl.dispose();
    _guardianNameCtl.dispose();
    _guardianEmailCtl.dispose();
    _guardianPhoneCtl.dispose();
    _guardianPasswordCtl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageCtl.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageCtl.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _pickAvatarSource() async {
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
    if (source != null) _pickAvatar(source);
  }

  Future<void> _pickGuardianAvatarSource() async {
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
    if (source != null) _pickGuardianAvatar(source);
  }

  Future<void> _pickGuardianAvatar(ImageSource source) async {
    setState(() => _isUploadingGuardianAvatar = true);
    final oldUrl = _guardianAvatarUrl;
    try {
      final XFile? image =
          await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (image == null) {
        if (mounted) setState(() => _isUploadingGuardianAvatar = false);
        return;
      }
      final bytes = await File(image.path).readAsBytes();
      final ext =
          image.name.contains('.') ? '.${image.name.split('.').last}' : '.jpg';
      final safeName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final storagePath = 'profiles/$safeName';

      setState(() => _guardianAvatarBytes = bytes);

      await Supabase.instance.client.storage
          .from(StorageBuckets.avatars)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = Supabase.instance.client.storage
          .from(StorageBuckets.avatars)
          .getPublicUrl(storagePath);
      setState(() => _guardianAvatarUrl = url);
    } catch (e) {
      setState(() {
        _guardianAvatarBytes = null;
        _guardianAvatarUrl = oldUrl;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Guardian avatar upload failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isUploadingGuardianAvatar = false);
  }

  Future<void> _pickAvatar(ImageSource source) async {
    setState(() => _isUploadingAvatar = true);
    final oldAvatarUrl = _avatarUrl;
    try {
      final XFile? image =
          await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (image == null) {
        if (mounted) setState(() => _isUploadingAvatar = false);
        return;
      }
      final bytes = await File(image.path).readAsBytes();

      final ext =
          image.name.contains('.') ? '.${image.name.split('.').last}' : '.jpg';
      final safeName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final storagePath = 'profiles/$safeName';

      debugPrint(
          '[UsersScreen] _pickAvatar file=${image.name} size=${bytes.length} path=$storagePath');

      setState(() => _avatarBytes = bytes);

      await Supabase.instance.client.storage
          .from(StorageBuckets.avatars)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = Supabase.instance.client.storage
          .from(StorageBuckets.avatars)
          .getPublicUrl(storagePath);
      debugPrint('[UsersScreen] _pickAvatar url=$url');
      setState(() => _avatarUrl = url);
    } catch (e) {
      debugPrint('[UsersScreen] _pickAvatar error: $e');
      debugPrint('[UsersScreen] oldAvatarUrl=${oldAvatarUrl ?? "null"}');
      setState(() {
        _avatarBytes = null;
        _avatarUrl = oldAvatarUrl;
      });
      if (mounted) {
        final msg = e.toString().contains('policy') ||
                e.toString().contains('Unauthorized')
            ? 'Storage RLS policy blocks upload. Run this SQL in Supabase SQL Editor:\n'
                'CREATE POLICY "avatars_all" ON storage.objects FOR ALL TO authenticated USING (bucket_id = \'avatars\');'
            : e.toString().contains('bucket')
                ? 'Storage bucket "avatars" not found. Create it in Supabase Dashboard → Storage.'
                : 'Avatar upload failed: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(msg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 8)),
        );
      }
    }
    if (mounted) setState(() => _isUploadingAvatar = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final steps = [
      'Basic Info',
      'Personal',
      'Family',
      'Emergency',
      'Settings',
    ];
    final stepIcons = [
      Icons.person,
      Icons.badge,
      Icons.family_restroom,
      Icons.emergency,
      Icons.settings,
    ];

    return Scaffold(
      appBar: AppBar(
        title:
            Text(_isEdit ? 'Edit User [#${widget.user!['nid']}]' : 'Add User'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: List.generate(5, (i) {
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
                              child: Icon(stepIcons[i],
                                  size: 16,
                                  color: isActive
                                      ? cs.onPrimary
                                      : cs.onSurfaceVariant),
                            ),
                            if (i < 4)
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
                        Text(steps[i],
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
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
                _buildStep4(),
                _buildStep5(),
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
                if (_currentStep < 4)
                  FilledButton(onPressed: _nextStep, child: const Text('Next'))
                else
                  FilledButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () {
                            debugPrint('[UsersScreen] Save button CLICKED');
                            _save();
                          },
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check),
                    label: Text(_isSaving ? 'Saving...' : t(L.save, ref)),
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

  Widget _field(TextEditingController ctl, String label,
      {int maxLines = 1,
      IconData? icon,
      bool enabled = true,
      bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: obscureText
          ? _PasswordField(
              ctl: ctl,
              label: label,
              icon: icon,
              enabled: enabled,
              decoration: _dec,
            )
          : TextField(
              controller: ctl,
              maxLines: maxLines,
              enabled: enabled,
              obscureText: false,
              decoration: _dec(label, icon: icon),
            ),
    );
  }

  Widget _drop<T>(String label, T? value, List<DropdownMenuItem<T>> items,
      ValueChanged<T?> onChanged,
      {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: _dec(label, icon: icon),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary)),
      );

  Widget _buildAvatarRow({
    required Uint8List? bytes,
    required String? url,
    required bool isUploading,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.grey[200],
                backgroundImage: bytes != null
                    ? MemoryImage(bytes)
                    : (url != null ? NetworkImage(url) : null),
                child: bytes == null && url == null
                    ? Icon(Icons.person, size: 36, color: Colors.grey[400])
                    : null,
              ),
              if (isUploading)
                const Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.camera_alt,
                          size: 11, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('Tap to upload photo',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: Basic Info
  Widget _buildStep1() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('Basic Information'),
        Center(
          child: GestureDetector(
            onTap: _isUploadingAvatar ? null : _pickAvatarSource,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _avatarBytes != null
                      ? MemoryImage(_avatarBytes!)
                      : (_avatarUrl != null ? NetworkImage(_avatarUrl!) : null),
                  child: _avatarBytes == null && _avatarUrl == null
                      ? Icon(Icons.person, size: 48, color: Colors.grey[400])
                      : null,
                ),
                if (_isUploadingAvatar)
                  const Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: _isUploadingAvatar
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.camera_alt,
                            size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text('Tap to change photo',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ),
        const SizedBox(height: 20),
        _field(_nameCtl, 'Full Name *', icon: Icons.person_outline),
        _field(_nameArCtl, 'Full Name (Arabic/Dari)', icon: Icons.translate),
        _field(_emailCtl, 'Email *',
            icon: Icons.email_outlined, enabled: !_isEdit),
        if (!_isEdit)
          _field(_passwordCtl, 'Password *',
              icon: Icons.lock_outlined, obscureText: true),
        _field(_phoneCtl, 'Phone', icon: Icons.phone_outlined),
        _field(_addressCtl, 'Address',
            icon: Icons.location_on_outlined, maxLines: 2),
        _drop<String>(
            'Role',
            _selectedRole,
            _roles
                .map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r.replaceAll('_', ' ').toUpperCase())))
                .toList(),
            (v) => setState(() => _selectedRole = v ?? _selectedRole),
            icon: Icons.admin_panel_settings_outlined),
        if (_requiresTenant)
          _loadingTenants
              ? const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: LinearProgressIndicator())
              : _drop<Map<String, dynamic>>(
                  'Tenant',
                  _selectedTenant,
                  _tenants
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(t['name'] ?? '')))
                      .toList(),
                  (v) => setState(() => _selectedTenant = v),
                  icon: Icons.business_outlined),
      ],
    );
  }

  // Step 2: Personal
  Widget _buildStep2() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('Personal Details'),
        _field(_firstNameArCtl, 'First Name (Arabic/Dari)',
            icon: Icons.badge_outlined),
        _field(_lastNameArCtl, 'Last Name (Arabic/Dari)',
            icon: Icons.badge_outlined),
        _field(_tazkiraCtl, 'Tazkira Number', icon: Icons.credit_card_outlined),
        _field(_passportCtl, 'Passport ID', icon: Icons.flight_outlined),
        _field(_nationalityCtl, 'Nationality', icon: Icons.flag_outlined),
        _field(_religionCtl, 'Religion', icon: Icons.mosque_outlined),
        _drop<String>(
            'Blood Group',
            _selectedBloodGroup,
            _bloodGroups
                .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                .toList(),
            (v) => setState(() => _selectedBloodGroup = v),
            icon: Icons.bloodtype_outlined),
        _drop<String>(
            'Marital Status',
            _selectedMaritalStatus,
            _maritalStatuses
                .map((ms) => DropdownMenuItem(
                    value: ms,
                    child: Text(ms[0].toUpperCase() + ms.substring(1))))
                .toList(),
            (v) => setState(() => _selectedMaritalStatus = v),
            icon: Icons.favorite_outline),
      ],
    );
  }

  // Step 3: Family
  Widget _buildStep3() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('Family Information'),
        _field(_fatherNameCtl, 'Father Name', icon: Icons.man_outlined),
        _field(_fatherNameArCtl, 'Father Name (Arabic/Dari)',
            icon: Icons.man_outlined),
      ],
    );
  }

  // Step 4: Emergency
  Widget _buildStep4() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('Emergency Contact'),
        _field(_emergencyNameCtl, 'Contact Name', icon: Icons.person_outline),
        _field(_emergencyPhoneCtl, 'Contact Phone', icon: Icons.phone_outlined),
        _field(_emergencyRelationCtl, 'Relation (e.g. Father, Mother, Spouse)',
            icon: Icons.group_outlined),
      ],
    );
  }

  // Step 5: Settings
  Widget _buildStep5() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('Account Settings'),
        SwitchListTile(
          title: const Text('Active Account'),
          subtitle:
              Text(_isActive ? 'User can log in' : 'User account is disabled'),
          value: _isActive,
          onChanged: (v) => setState(() => _isActive = v),
          secondary: Icon(_isActive ? Icons.check_circle : Icons.cancel,
              color: _isActive ? Colors.green : Colors.red),
        ),
        if (_selectedRole == 'student' && !_isEdit) ...[
          const SizedBox(height: 24),
          _sectionTitle('Guardian Account'),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.amber.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'A separate guardian account with role "guardian" will be created and linked to this student.',
                    style:
                        TextStyle(fontSize: 12, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),
          _field(_guardianNameCtl, 'Guardian Full Name *',
              icon: Icons.person_outline),
          const SizedBox(height: 12),
          _buildAvatarRow(
            bytes: _guardianAvatarBytes,
            url: _guardianAvatarUrl,
            isUploading: _isUploadingGuardianAvatar,
            label: 'Guardian Profile Photo',
            onTap: _pickGuardianAvatarSource,
          ),
          const SizedBox(height: 12),
          _field(_guardianEmailCtl, 'Guardian Email *',
              icon: Icons.email_outlined),
          _field(_guardianPhoneCtl, 'Guardian Phone',
              icon: Icons.phone_outlined),
          _field(_guardianPasswordCtl, 'Guardian Password *',
              icon: Icons.lock_outlined, obscureText: true),
          _drop<String>(
              'Relationship',
              _selectedGuardianRelationship,
              _guardianRelationships
                  .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r[0].toUpperCase() + r.substring(1))))
                  .toList(),
              (v) => setState(() => _selectedGuardianRelationship = v),
              icon: Icons.people_outline),
        ],
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User Summary',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary)),
                const Divider(),
                _summaryRow(
                    'Name', _nameCtl.text.isEmpty ? '-' : _nameCtl.text),
                _summaryRow(
                    'Email', _emailCtl.text.isEmpty ? '-' : _emailCtl.text),
                _summaryRow(
                    'Role', _selectedRole.replaceAll('_', ' ').toUpperCase()),
                _summaryRow('Status', _isActive ? 'Active' : 'Inactive'),
                if (_selectedRole == 'student' && !_isEdit) ...[
                  _summaryRow(
                      'Guardian',
                      _guardianNameCtl.text.isEmpty
                          ? '-'
                          : _guardianNameCtl.text),
                  _summaryRow(
                      'Guardian Email',
                      _guardianEmailCtl.text.isEmpty
                          ? '-'
                          : _guardianEmailCtl.text),
                  _summaryRow(
                      'Relationship',
                      _selectedGuardianRelationship != null
                          ? _selectedGuardianRelationship![0].toUpperCase() +
                              _selectedGuardianRelationship!.substring(1)
                          : '-'),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
                width: 80,
                child: Text(label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13))),
            Expanded(
                child: Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      );

  Future<void> _save() async {
    debugPrint(
        '[UsersScreen] _save called | isEdit=$_isEdit role=$_selectedRole');

    if (_nameCtl.text.trim().isEmpty || _emailCtl.text.trim().isEmpty) {
      debugPrint(
          '[UsersScreen] Validation failed | name="${_nameCtl.text}" email="${_emailCtl.text}"');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Name and Email are required'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    // Student-specific validation
    if (_selectedRole == 'student' && !_isEdit) {
      if (_passwordCtl.text.trim().isEmpty ||
          _passwordCtl.text.trim().length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Student password is required (min 6 characters)'),
              backgroundColor: Colors.orange),
        );
        return;
      }
      if (_guardianNameCtl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Guardian name is required'),
              backgroundColor: Colors.orange),
        );
        return;
      }
      if (_guardianEmailCtl.text.trim().isEmpty ||
          !_guardianEmailCtl.text.trim().contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Valid guardian email is required'),
              backgroundColor: Colors.orange),
        );
        return;
      }
      if (_guardianPasswordCtl.text.trim().isEmpty ||
          _guardianPasswordCtl.text.trim().length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Guardian password is required (min 6 characters)'),
              backgroundColor: Colors.orange),
        );
        return;
      }
    }

    // Student, guardian, parent, and relationship records are tenant-scoped.
    // Validate this before creating auth accounts so a missing tenant cannot
    // leave partially-created student/guardian accounts behind.
    if (_requiresTenant && _selectedTenant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a tenant before saving this user'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final tenantId = _selectedTenant?['id'];

    setState(() => _isSaving = true);

    final profilePayload = <String, dynamic>{
      'full_name': _nameCtl.text.trim(),
      'full_name_ar':
          _nameArCtl.text.trim().isEmpty ? null : _nameArCtl.text.trim(),
      'first_name_ar': _firstNameArCtl.text.trim().isEmpty
          ? null
          : _firstNameArCtl.text.trim(),
      'last_name_ar': _lastNameArCtl.text.trim().isEmpty
          ? null
          : _lastNameArCtl.text.trim(),
      'phone': _phoneCtl.text.trim().isEmpty ? null : _phoneCtl.text.trim(),
      'address':
          _addressCtl.text.trim().isEmpty ? null : _addressCtl.text.trim(),
      'tazkira_number':
          _tazkiraCtl.text.trim().isEmpty ? null : _tazkiraCtl.text.trim(),
      'passport_id':
          _passportCtl.text.trim().isEmpty ? null : _passportCtl.text.trim(),
      'nationality': _nationalityCtl.text.trim().isEmpty
          ? null
          : _nationalityCtl.text.trim(),
      'religion':
          _religionCtl.text.trim().isEmpty ? null : _religionCtl.text.trim(),
      'father_name': _fatherNameCtl.text.trim().isEmpty
          ? null
          : _fatherNameCtl.text.trim(),
      'father_name_ar': _fatherNameArCtl.text.trim().isEmpty
          ? null
          : _fatherNameArCtl.text.trim(),
      'emergency_contact_name': _emergencyNameCtl.text.trim().isEmpty
          ? null
          : _emergencyNameCtl.text.trim(),
      'emergency_contact_phone': _emergencyPhoneCtl.text.trim().isEmpty
          ? null
          : _emergencyPhoneCtl.text.trim(),
      'emergency_contact_relation': _emergencyRelationCtl.text.trim().isEmpty
          ? null
          : _emergencyRelationCtl.text.trim(),
      'role': _selectedRole,
      'blood_group': _selectedBloodGroup,
      'marital_status': _selectedMaritalStatus,
      'is_active': _isActive,
      'avatar_url': _avatarUrl,
      'tenant_id': _requiresTenant ? tenantId : null,
    };

    // Ensure admin session is active — restore from secure storage if needed
    var adminSession = Supabase.instance.client.auth.currentSession;
    if (adminSession == null) {
      debugPrint(
          '[UsersScreen] Admin session null, attempting restore from secure storage...');
      final secureStorage = SecureStorageService(const FlutterSecureStorage());
      final at = await secureStorage.getAccessToken();
      final rt = await secureStorage.getRefreshToken();
      if (at != null && at.isNotEmpty) {
        try {
          final json = rt != null && rt.isNotEmpty
              ? "{\"access_token\":\"$at\",\"refresh_token\":\"$rt\"}"
              : "{\"access_token\":\"$at\"}";
          await Supabase.instance.client.auth
              .setSession(json)
              .timeout(const Duration(seconds: 15));
          adminSession = Supabase.instance.client.auth.currentSession;
          debugPrint(
              '[UsersScreen] Admin session restored from secure storage');
        } catch (e) {
          debugPrint('[UsersScreen] Session restore failed: $e');
        }
      }
    }

    // Save admin session tokens before signUp — signUp replaces the current session
    final adminAccessToken = adminSession?.accessToken;
    final adminRefreshToken = adminSession?.refreshToken;
    // Do not print token contents (or assume a minimum token length) in logs.
    debugPrint(
        '[UsersScreen] Admin access token before signUp: ${adminAccessToken == null ? "missing" : "available"}');
    debugPrint(
        '[UsersScreen] Admin refresh token before signUp: ${adminRefreshToken == null ? "missing" : "available"}');

    if (adminAccessToken == null || adminRefreshToken == null) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your session has expired. Please sign in again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    Future<AuthResponse> restoreAdminSession() => Supabase.instance.client.auth
        .setSession(
            "{\"access_token\":\"$adminAccessToken\",\"refresh_token\":\"$adminRefreshToken\"}")
        .timeout(const Duration(seconds: 15));

    try {
      if (_isEdit) {
        // Edit mode: just update profile (no signUp, admin stays logged in)
        final userId = widget.user!['id'];
        debugPrint('[UsersScreen] Updating profile id=$userId');
        await Supabase.instance.client
            .from('users')
            .update(profilePayload)
            .eq('id', userId);
        debugPrint('[UsersScreen] Update successful');
        if (mounted) Navigator.pop(context, true);
        return;
      }

      if (_selectedRole == 'student') {
        debugPrint('[UsersScreen] Creating student + guardian accounts...');

        // 1. Create student auth user
        final studentSignUp = await Supabase.instance.client.auth.signUp(
          email: _emailCtl.text.trim(),
          password: _passwordCtl.text.trim(),
          data: {'full_name': _nameCtl.text.trim(), 'role': 'student'},
        ).timeout(const Duration(seconds: 30));
        final studentUser = studentSignUp.user;
        if (studentUser == null) {
          throw Exception('Failed to create student auth user');
        }
        debugPrint(
            '[UsersScreen] Student auth user created: ${studentUser.id}');

        // 2. Insert student profile
        profilePayload['id'] = studentUser.id;
        profilePayload['email'] = _emailCtl.text.trim();
        await Supabase.instance.client.from('users').insert(profilePayload);
        debugPrint('[UsersScreen] Student profile inserted');

        // 3. Create guardian auth user
        final guardianSignUp = await Supabase.instance.client.auth.signUp(
          email: _guardianEmailCtl.text.trim(),
          password: _guardianPasswordCtl.text.trim(),
          data: {'full_name': _guardianNameCtl.text.trim(), 'role': 'guardian'},
        ).timeout(const Duration(seconds: 30));
        final guardianUser = guardianSignUp.user;
        if (guardianUser == null) {
          throw Exception('Failed to create guardian auth user');
        }
        debugPrint(
            '[UsersScreen] Guardian auth user created: ${guardianUser.id}');

        // 4. Insert guardian profile
        await Supabase.instance.client.from('users').insert({
          'id': guardianUser.id,
          'full_name': _guardianNameCtl.text.trim(),
          'phone': _guardianPhoneCtl.text.trim().isEmpty
              ? null
              : _guardianPhoneCtl.text.trim(),
          'email': _guardianEmailCtl.text.trim(),
          'role': 'guardian',
          'avatar_url': _guardianAvatarUrl,
          'tenant_id': tenantId,
          'is_active': true,
        });
        debugPrint('[UsersScreen] Guardian profile inserted');

        // The guardian profile has the same tenant, so the tenant-scoped
        // policies permit these inserts with the active guardian session.
        // Do not restore here: a second signUp may have rotated the original
        // administrator refresh token.

        // 5. Insert student record
        final studentCode =
            'STU-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
        final studentResult =
            await Supabase.instance.client.from('students').insert({
          'profile_id': studentUser.id,
          'tenant_id': tenantId,
          'student_code': studentCode,
          'full_name': _nameCtl.text.trim(),
          'first_name': _nameCtl.text.trim().split(' ').first,
          'last_name': _nameCtl.text.trim().split(' ').last,
          'email': _emailCtl.text.trim(),
          'phone': _phoneCtl.text.trim().isEmpty ? null : _phoneCtl.text.trim(),
          'address':
              _addressCtl.text.trim().isEmpty ? null : _addressCtl.text.trim(),
          'guardian_name': _guardianNameCtl.text.trim(),
          'guardian_phone': _guardianPhoneCtl.text.trim().isEmpty
              ? null
              : _guardianPhoneCtl.text.trim(),
          'guardian_email': _guardianEmailCtl.text.trim(),
          'guardian_relationship': _selectedGuardianRelationship,
          'status': 'active',
        }).select();
        final studentId = studentResult[0]['id'];
        debugPrint('[UsersScreen] Student record inserted: $studentId');

        // 6. Insert parent record
        final parentResult =
            await Supabase.instance.client.from('parents').insert({
          'profile_id': guardianUser.id,
          'tenant_id': tenantId,
          'full_name': _guardianNameCtl.text.trim(),
          'phone': _guardianPhoneCtl.text.trim().isEmpty
              ? null
              : _guardianPhoneCtl.text.trim(),
          'email': _guardianEmailCtl.text.trim(),
          'is_guardian': true,
        }).select();
        final parentId = parentResult[0]['id'];
        debugPrint('[UsersScreen] Parent record inserted: $parentId');

        // 7. Link parent to student
        await Supabase.instance.client.from('parent_students').insert({
          'tenant_id': tenantId,
          'parent_id': parentId,
          'student_id': studentId,
          'relationship': _selectedGuardianRelationship ?? 'guardian',
          'is_primary': true,
        });
        debugPrint('[UsersScreen] Parent-student link created');
      } else {
        // Create auth user for non-student roles
        debugPrint('[UsersScreen] Creating auth user for role=$_selectedRole');
        final signUp = await Supabase.instance.client.auth.signUp(
          email: _emailCtl.text.trim(),
          password: _passwordCtl.text.trim(),
          data: {'full_name': _nameCtl.text.trim(), 'role': _selectedRole},
        ).timeout(const Duration(seconds: 30));
        final user = signUp.user;
        if (user == null) throw Exception('Failed to create auth user');
        debugPrint('[UsersScreen] Auth user created: ${user.id}');

        // Insert profile
        profilePayload['id'] = user.id;
        profilePayload['email'] = _emailCtl.text.trim();
        debugPrint('[UsersScreen] Inserting new profile...');
        await Supabase.instance.client.from('users').insert(profilePayload);
        debugPrint('[UsersScreen] Insert successful');
      }

      // Restore admin session BEFORE navigating back, otherwise the router
      // still sees the newly-created user's session and redirects to login.
      debugPrint('[UsersScreen] Restoring admin session (awaited)...');
      try {
        final restored = await restoreAdminSession();
        final session = restored.session;
        if (session != null) {
          final secureStorage =
              SecureStorageService(const FlutterSecureStorage());
          await secureStorage.saveAccessToken(session.accessToken);
          final rt = session.refreshToken;
          if (rt != null && rt.isNotEmpty) {
            await secureStorage.saveRefreshToken(rt);
          }
          debugPrint('[UsersScreen] Admin session restored + tokens re-saved');
        } else {
          // Fall back to re-reading tokens from secure storage.
          final secureStorage =
              SecureStorageService(const FlutterSecureStorage());
          final at = await secureStorage.getAccessToken();
          final rt = await secureStorage.getRefreshToken();
          if (at != null && at.isNotEmpty) {
            final json = rt != null && rt.isNotEmpty
                ? "{\"access_token\":\"$at\",\"refresh_token\":\"$rt\"}"
                : "{\"access_token\":\"$at\"}";
            await Supabase.instance.client.auth
                .setSession(json)
                .timeout(const Duration(seconds: 15));
          }
        }
      } catch (e, st) {
        debugPrint('[UsersScreen] Session restore failed: $e');
        debugPrint('[UsersScreen] Restore stack: $st');
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e, st) {
      debugPrint('[UsersScreen] ERROR: $e');
      debugPrint('[UsersScreen] STACK: $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController ctl;
  final String label;
  final IconData? icon;
  final bool enabled;
  final InputDecoration Function(String label, {IconData? icon}) decoration;

  const _PasswordField({
    required this.ctl,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.decoration,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.ctl,
      enabled: widget.enabled,
      obscureText: _hidden,
      decoration: widget
          .decoration(widget.label, icon: widget.icon)
          .copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _hidden
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _hidden = !_hidden),
            ),
          ),
    );
  }
}

class _UserSkeletonCard extends StatelessWidget {
  const _UserSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 180,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 90,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onLoginAs;
  final bool isLoading;

  const _UserCard({
    required this.user,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    this.onLoginAs,
    this.isLoading = false,
  });

  Color _roleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.red;
      case 'admin':
        return Colors.blue;
      case 'teacher':
        return Colors.green;
      case 'accountant':
        return Colors.orange;
      case 'librarian':
        return Colors.purple;
      case 'hr_manager':
        return Colors.teal;
      case 'it_support':
        return Colors.indigo;
      case 'student':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = user['full_name']?.toString() ?? 'Unknown';
    final role = user['role']?.toString() ?? 'N/A';
    final color = _roleColor(role);
    final avatarUrl = user['avatar_url']?.toString();
    final isActive = user['is_active'] != false;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left color strip
            Container(width: 4, color: color),
            // Avatar
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: color.withValues(alpha: 0.15),
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? Text(
                              name.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            )
                          : null,
                    ),
                    if (!isActive)
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black26,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.block,
                              color: Colors.white, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Name + Role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      role.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onLoginAs != null)
                    isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 20),
                            tooltip: 'Login As',
                            onPressed: onLoginAs,
                          ),
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    tooltip: 'View',
                    onPressed: onView,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 20, color: Theme.of(context).colorScheme.error),
                    tooltip: 'Delete',
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
