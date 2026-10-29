import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/providers/chat_providers.dart';
import 'package:course_emis/screens/chat_profile_screen.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  List<_Thread> _threads = [];
  bool _loading = true;
  String _searchQuery = '';
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadThreads();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeRealtime() {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    _realtimeChannel = supabase
        .channel('messages_threads:$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (_) => _loadThreads(showLoading: false),
        )
        .subscribe();
  }

  Future<void> _loadThreads({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    try {
      final threads = await _fetchThreadsForUser();
      if (mounted) {
        setState(() {
          _threads = threads;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _threads = [];
          _loading = false;
        });
      }
    }
  }

  List<_Thread> get _filteredThreads {
    if (_searchQuery.isEmpty) return _threads;
    final q = _searchQuery.toLowerCase();
    return _threads.where((t) {
      return t.name.toLowerCase().contains(q) ||
          t.partnerRole.toLowerCase().contains(q) ||
          t.lastMessage.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () => _showNewChatOptions(context),
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Select Account'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              width: double.infinity,
              height: double.infinity,
              constraints: const BoxConstraints(maxWidth: 1200),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Search conversations...',
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
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            '${_filteredThreads.length} conversations',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filteredThreads.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline,
                                      size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text('No conversations yet',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16)),
                                  const SizedBox(height: 8),
                                  FilledButton.tonalIcon(
                                    onPressed: () =>
                                        _showNewChatOptions(context),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Start a chat'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 100),
                              itemCount: _filteredThreads.length,
                              itemBuilder: (context, index) {
                                final thread = _filteredThreads[index];
                                return _MessageCard(
                                  thread: thread,
                                  onTap: () => _openChat(thread),
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

  void _showNewChatOptions(BuildContext context) async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => const _NewChatScreen(),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      _openDirectChat(
        targetUserId: result['id']?.toString() ?? '',
        targetName: result['full_name']?.toString() ??
            result['name']?.toString() ??
            'Unknown',
        targetRole: result['role']?.toString() ?? '',
        targetAvatarUrl: result['avatar_url']?.toString(),
      );
    }
  }

  void _openDirectChat({
    required String targetUserId,
    required String targetName,
    required String targetRole,
    String? targetAvatarUrl,
  }) {
    final now = TimeOfDay.now();
    final timeLabel =
        '${now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod}:${now.minute.toString().padLeft(2, '0')} ${now.period == DayPeriod.am ? 'AM' : 'PM'}';

    final thread = _Thread(
      name: targetName,
      avatarUrl: targetAvatarUrl,
      partnerRole: targetRole,
      lastMessage: '',
      time: timeLabel,
      unread: false,
      isGroup: false,
      initialMessages: [],
      targetUserId: targetUserId,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ChatScreen(
          thread: thread,
        ),
      ),
    );
  }

  void _openChat(_Thread thread) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ChatScreen(
          thread: thread,
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Map<String, dynamic> account;
  final VoidCallback onTap;

  const _AccountCard({required this.account, required this.onTap});

  Color _roleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.red;
      case 'admin':
        return Colors.blue;
      case 'teacher':
        return Colors.green;
      case 'student':
        return Colors.cyan;
      case 'guardian':
        return Colors.orange;
      case 'accountant':
        return Colors.deepOrange;
      case 'librarian':
        return Colors.purple;
      case 'hr_manager':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = account['full_name']?.toString() ?? 'Unknown';
    final email = account['email']?.toString() ?? '';
    final role = account['role']?.toString() ?? 'N/A';
    final avatarUrl = account['avatar_url']?.toString();
    final color = _roleColor(role);
    final isActive = account['is_active'] != false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircleAvatar(
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
                              fontSize: 18),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    if (email.isNotEmpty)
                      Text(email,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            role.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isActive ? Icons.check_circle : Icons.cancel,
                          size: 14,
                          color: isActive ? Colors.green : Colors.red[300],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          isActive ? 'Active' : 'Inactive',
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// --- New Chat Screen (full page: group creation + DM account list) ---
class _NewChatScreen extends ConsumerStatefulWidget {
  const _NewChatScreen();

  @override
  ConsumerState<_NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<_NewChatScreen> {
  List<Map<String, dynamic>> _allAccounts = [];
  bool _loading = true;
  String _searchQuery = '';
  String _roleFilter = 'All';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('id, full_name, email, role, avatar_url, nid, phone, is_active')
          .order('full_name', ascending: true);
      if (mounted) {
        setState(() {
          _allAccounts = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredAccounts {
    var list = _allAccounts;
    if (_roleFilter != 'All') {
      list = list
          .where((a) =>
              a['role']?.toString().toLowerCase() == _roleFilter.toLowerCase())
          .toList();
    }
    if (_statusFilter != 'All') {
      final active = _statusFilter == 'Active';
      list = list.where((a) => a['is_active'] == active).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((a) =>
              (a['full_name']?.toString().toLowerCase().contains(q) ?? false) ||
              (a['email']?.toString().toLowerCase().contains(q) ?? false) ||
              (a['nid']?.toString().contains(q) ?? false) ||
              (a['phone']?.toString().contains(q) ?? false))
          .toList();
    }
    return list;
  }

  Set<String> get _roles {
    return _allAccounts
        .map((a) => a['role']?.toString() ?? '')
        .where((r) => r.isNotEmpty)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final roles = _roles.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Chat'),
      ),
      body: Column(
        children: [
          // Create Group card at top
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Card(
              color: Colors.green.withValues(alpha: 0.06),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.groups, color: Colors.green),
                ),
                title: const Text('Create Group',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Start a group conversation with multiple people'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _CreateGroupScreen(),
                      fullscreenDialog: true,
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(indent: 72, endIndent: 16),
          // Direct Message header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text('Direct Message',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.grey[800])),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search name, email, NID, phone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          // Filters row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('role_$_roleFilter'),
                    initialValue: _roleFilter,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                    items: ['All', ...roles]
                        .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() => _roleFilter = v ?? 'All'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('status_$_statusFilter'),
                    initialValue: _statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                    items: ['All', 'Active', 'Inactive']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() => _statusFilter = v ?? 'All'),
                  ),
                ),
                if (_roleFilter != 'All' || _statusFilter != 'All' || _searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_all, size: 20),
                    tooltip: 'Clear filters',
                    onPressed: () => setState(() {
                      _roleFilter = 'All';
                      _statusFilter = 'All';
                      _searchQuery = '';
                    }),
                  ),
              ],
            ),
          ),
          // Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                Text('${_filteredAccounts.length} accounts',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          // Account list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAccounts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_off, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('No accounts found', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: _filteredAccounts.length,
                        itemBuilder: (context, index) {
                          final account = _filteredAccounts[index];
                          return _AccountCard(
                            account: account,
                            onTap: () => Navigator.pop(context, account),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// --- Create Group Screen ---
class _CreateGroupScreen extends ConsumerStatefulWidget {
  const _CreateGroupScreen();

  @override
  ConsumerState<_CreateGroupScreen> createState() =>
      _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<_CreateGroupScreen> {
  final _groupNameCtrl = TextEditingController();
  List<Map<String, dynamic>> _allAccounts = [];
  final Set<String> _selectedIds = {};
  bool _loading = true;
  bool _creating = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final currentId = Supabase.instance.client.auth.currentUser?.id;
      final data = await Supabase.instance.client
          .from('users')
          .select('id, full_name, email, role, avatar_url')
          .neq('id', currentId ?? '')
          .order('full_name', ascending: true);
      if (mounted) {
        setState(() {
          _allAccounts = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredAccounts {
    if (_searchQuery.isEmpty) return _allAccounts;
    final q = _searchQuery.toLowerCase();
    return _allAccounts
        .where((a) =>
            (a['full_name']?.toString().toLowerCase().contains(q) ?? false) ||
            (a['email']?.toString().toLowerCase().contains(q) ?? false))
        .toList();
  }

  Future<void> _createGroup() async {
    final name = _groupNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a group name')));
      return;
    }
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least one member')));
      return;
    }

    setState(() => _creating = true);
    try {
      final supabase = Supabase.instance.client;
      final currentId = supabase.auth.currentUser?.id;

      await supabase.from('chat_groups').insert({
        'name': name,
        'created_by': currentId,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group created')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e')));
        setState(() => _creating = false);
      }
    }
  }

  @override
  void dispose() {
    _groupNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _creating ? null : _createGroup,
              child: _creating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Create'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _groupNameCtrl,
              decoration: InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.group),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search members...',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text('${_selectedIds.length} selected',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _filteredAccounts.length,
                    itemBuilder: (context, index) {
                      final account = _filteredAccounts[index];
                      final id = account['id']?.toString() ?? '';
                      final selected = _selectedIds.contains(id);
                      return CheckboxListTile(
                        value: selected,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedIds.add(id);
                            } else {
                              _selectedIds.remove(id);
                            }
                          });
                        },
                        secondary: CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              account['avatar_url']?.toString() != null &&
                                      account['avatar_url'].toString().isNotEmpty
                                  ? CachedNetworkImageProvider(
                                      account['avatar_url'].toString())
                                  : null,
                          child: account['avatar_url']?.toString() == null ||
                                  account['avatar_url'].toString().isEmpty
                              ? Text(
                                  (account['full_name']?.toString() ?? '?')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        title: Text(
                            account['full_name']?.toString() ?? 'Unknown'),
                        subtitle: Text(account['role']?.toString() ?? ''),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- Message Card ---
class _MessageCard extends StatelessWidget {
  final _Thread thread;
  final VoidCallback onTap;

  const _MessageCard({required this.thread, required this.onTap});

  Color get _accent => thread.isGroup ? Colors.indigo : Colors.teal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: thread.unread
                ? _accent.withValues(alpha: 0.34)
                : theme.dividerColor.withValues(alpha: 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircleAvatar(
                backgroundColor: _accent.withValues(alpha: 0.14),
                backgroundImage: thread.avatarUrl != null &&
                        thread.avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(thread.avatarUrl!)
                    : null,
                child: thread.avatarUrl == null || thread.avatarUrl!.isEmpty
                    ? Icon(thread.isGroup
                        ? Icons.groups_rounded
                        : Icons.person_outline, color: _accent)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: thread.unread
                                ? FontWeight.w800
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(thread.time,
                          style: theme.textTheme.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    thread.partnerRole.replaceAll('_', ' '),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: _accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    thread.lastMessage.isEmpty
                        ? 'Tap to start chatting'
                        : thread.lastMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ),
            ),
            if (thread.unread) ...[
              const SizedBox(width: 12),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- Full-Screen Chat Screen ---
class _ChatScreen extends ConsumerStatefulWidget {
  final _Thread thread;

  const _ChatScreen({required this.thread});

  @override
  ConsumerState<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<_ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late List<_ChatEntry> _messages;
  bool _loadingHistory = true;
  _ChatEntry? _replyingTo;

  @override
  void initState() {
    super.initState();
    _messages = [...widget.thread.initialMessages];
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;
    final targetUserId = widget.thread.targetUserId;
    if (currentUserId == null || targetUserId == null) {
      if (mounted) setState(() => _loadingHistory = false);
      return;
    }

    try {
      final data = await supabase
          .from('messages')
          .select()
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .order('created_at', ascending: true);

      final entries = <_ChatEntry>[];
      for (final row in data) {
        final senderId = row['sender_id']?.toString();
        final receiverId = row['receiver_id']?.toString();
        if (!((senderId == currentUserId && receiverId == targetUserId) ||
            (senderId == targetUserId && receiverId == currentUserId))) {
          continue;
        }
        final isSender = senderId == currentUserId;
        final createdAt = row['created_at']?.toString() ?? '';
        final time = _formatHistoryTime(createdAt);
        entries.add(_ChatEntry(
          id: row['id']?.toString() ?? '',
          text: row['body']?.toString() ?? '',
          isSender: isSender,
          time: time,
          senderId: senderId,
          replyToId: row['parent_message_id']?.toString(),
        ));
      }

      if (mounted) {
        setState(() {
          _messages = entries;
          _loadingHistory = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  String _formatHistoryTime(String createdAt) {
    if (createdAt.length < 16) return createdAt;
    final date = DateTime.tryParse(createdAt);
    if (date != null) {
      final time = TimeOfDay.fromDateTime(date);
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final min = time.minute.toString().padLeft(2, '0');
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:$min $period';
    }
    return createdAt.substring(11, 16);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;

    final now = TimeOfDay.now();
    final timeLabel =
        '${now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod}:${now.minute.toString().padLeft(2, '0')} ${now.period == DayPeriod.am ? 'AM' : 'PM'}';

    final replyToId = _replyingTo?.id;

    try {
      if (currentUserId != null && widget.thread.targetUserId != null) {
        await supabase.from('messages').insert({
          'sender_id': currentUserId,
          'receiver_id': widget.thread.targetUserId,
          'body': text,
          if (replyToId != null && replyToId.isNotEmpty)
            'parent_message_id': replyToId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (!mounted) return;
      setState(() {
        _messages.add(_ChatEntry(
          text: text,
          isSender: true,
          time: timeLabel,
          senderId: currentUserId,
          replyToId: replyToId,
        ));
        _messageController.clear();
        _replyingTo = null;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(LGen.somethingWentWrong, ref))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.thread.isGroup ? Colors.indigo : Colors.teal;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 8,
        title: Row(
          children: [
            InkWell(
              onTap: () {
                final userId = widget.thread.targetUserId;
                if (userId != null && !widget.thread.isGroup) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatProfileScreen(userId: userId),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    backgroundImage: widget.thread.avatarUrl != null &&
                            widget.thread.avatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(widget.thread.avatarUrl!)
                        : null,
                    child: widget.thread.avatarUrl == null ||
                            widget.thread.avatarUrl!.isEmpty
                        ? Icon(
                            widget.thread.isGroup
                                ? Icons.groups_rounded
                                : Icons.person_outline,
                            color: accent,
                            size: 22)
                        : null,
                  ),
                  if (!widget.thread.isGroup)
                    _PresenceDot(userId: widget.thread.targetUserId!),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.thread.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  _buildSubtitle(accent),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, size: 28),
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loadingHistory
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _ChatBubble(
                        message: message.text,
                        isSender: message.isSender,
                        time: message.time,
                        accent: accent,
                        replyPreview: _replyPreviewFor(message),
                        onLongPress: () =>
                            _showMessageActions(context, message),
                      );
                    },
                  ),
          ),
          if (_replyingTo != null) _buildReplyBanner(accent),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                  top:
                      BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _replyPreviewFor(_ChatEntry message) {
    if (message.replyToId == null || message.replyToId!.isEmpty) return null;
    for (final m in _messages) {
      if (m.id == message.replyToId) return m.text;
    }
    return 'Replied message';
  }

  Widget _buildReplyBanner(Color accent) {
    final theme = Theme.of(context);
    final reply = _replyingTo!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Container(width: 4, height: 40, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reply.isSender ? 'Replying to yourself' : 'Replying to ${widget.thread.name}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accent,
                      fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  reply.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel reply',
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  void _showMessageActions(BuildContext context, _ChatEntry message) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.reply),
            title: const Text('Reply'),
            onTap: () {
              Navigator.pop(ctx);
              setState(() => _replyingTo = message);
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy'),
            onTap: () {
              Navigator.pop(ctx);
              Clipboard.setData(ClipboardData(text: message.text));
            },
          ),
          ListTile(
            leading: const Icon(Icons.forward),
            title: const Text('Forward'),
            onTap: () {
              Navigator.pop(ctx);
              _forwardMessage(message);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _forwardMessage(_ChatEntry message) async {
    if (message.text.isEmpty) return;
    List<_Thread> threads;
    try {
      threads = await _fetchThreadsForUser();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load chats: $e')));
      return;
    }
    final currentTarget = widget.thread.targetUserId;
    final candidates = threads
        .where((t) => t.targetUserId != null && t.targetUserId != currentTarget)
        .toList();
    if (candidates.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No other chats to forward to')));
      return;
    }
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Forward to',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: candidates.length,
              itemBuilder: (context, index) {
                final thread = candidates[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        (thread.isGroup ? Colors.indigo : Colors.teal)
                            .withValues(alpha: 0.15),
                    backgroundImage: thread.avatarUrl != null &&
                            thread.avatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(thread.avatarUrl!)
                        : null,
                    child: thread.avatarUrl == null ||
                            thread.avatarUrl!.isEmpty
                        ? Icon(thread.isGroup
                            ? Icons.groups_rounded
                            : Icons.person_outline,
                            color: thread.isGroup ? Colors.indigo : Colors.teal)
                        : null,
                  ),
                  title: Text(thread.name),
                  subtitle: Text(
                      thread.partnerRole.replaceAll('_', ' ').toUpperCase()),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final supabase = Supabase.instance.client;
                    final currentUserId = supabase.auth.currentUser?.id;
                    try {
                      if (currentUserId != null &&
                          thread.targetUserId != null) {
                        await supabase.from('messages').insert({
                          'sender_id': currentUserId,
                          'receiver_id': thread.targetUserId,
                          'body': message.text,
                          'created_at': DateTime.now().toIso8601String(),
                        });
                      }
                      messenger.showSnackBar(SnackBar(
                          content: Text('Forwarded to ${thread.name}')));
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(
                          content: Text('Forward failed: $e')));
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(Color accent) {
    if (widget.thread.isGroup) {
      return Text(
        widget.thread.partnerRole.replaceAll('_', ' '),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final userId = widget.thread.targetUserId;
    if (userId == null) {
      return Text(
        widget.thread.partnerRole.replaceAll('_', ' '),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final presence = ref.watch(chatPresenceProvider(userId));
    final isOnline = presence.valueOrNull ?? false;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isOnline ? Icons.circle : Icons.circle_outlined,
          size: 10,
          color: isOnline ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          isOnline ? 'Online' : 'Offline',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: isOnline ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }
}

// --- Chat Bubble ---
class _PresenceDot extends ConsumerWidget {
  final String userId;

  const _PresenceDot({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final presence = ref.watch(chatPresenceProvider(userId));
    final isOnline = presence.valueOrNull ?? false;
    return Positioned(
      bottom: 0,
      right: 0,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: isOnline ? Colors.green : Colors.grey,
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.surface, width: 2),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isSender;
  final String time;
  final Color accent;
  final String? replyPreview;
  final VoidCallback? onLongPress;

  const _ChatBubble({
    required this.message,
    required this.isSender,
    required this.time,
    required this.accent,
    this.replyPreview,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment:
          isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isSender ? accent : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: isSender
              ? null
              : Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (replyPreview != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: (isSender
                          ? Colors.white
                          : theme.colorScheme.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(
                        color: isSender ? Colors.white : theme.colorScheme.primary,
                        width: 3),
                  ),
                ),
                child: Text(
                  replyPreview!,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isSender
                        ? Colors.white
                        : theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (message.isNotEmpty)
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: isSender
                      ? Colors.white
                      : theme.colorScheme.onSurface
                          .withValues(alpha: 0.9),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color:
                    isSender ? Colors.white70 : theme.hintColor,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// --- Shared Thread Loader ---
Future<List<_Thread>> _fetchThreadsForUser() async {
  final supabase = Supabase.instance.client;
  final currentUserId = supabase.auth.currentUser?.id;
  if (currentUserId == null) return [];

  final data = List<Map<String, dynamic>>.from(await supabase
      .from('messages')
      .select()
      .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
      .order('created_at', ascending: false));

  final partnerIds = <String>{};
  final messagesByPartner = <String, Map<String, dynamic>>{};
  for (final row in data) {
    final senderId = row['sender_id']?.toString();
    final receiverId = row['receiver_id']?.toString();
    final partnerId = currentUserId == senderId ? receiverId : senderId;
    if (partnerId == null || partnerId.isEmpty) continue;
    partnerIds.add(partnerId);
    messagesByPartner.putIfAbsent(partnerId, () => row);
  }

  var profiles = <Map<String, dynamic>>[];
  if (partnerIds.isNotEmpty) {
    profiles = List<Map<String, dynamic>>.from(await supabase
        .from('users')
        .select('id, full_name, avatar_url, role, is_active')
        .inFilter('id', partnerIds.toList()));
  }
  final profileById = {
    for (final p in profiles) p['id']?.toString(): p,
  };

  return partnerIds.map<_Thread>((partnerId) {
    final row = messagesByPartner[partnerId]!;
    final profile = profileById[partnerId];
    final createdAt = row['created_at']?.toString() ?? '';
    final time = createdAt.length >= 16
        ? createdAt.substring(11, 16)
        : createdAt;
    return _Thread(
      name: profile?['full_name']?.toString() ?? 'Unknown',
      avatarUrl: profile?['avatar_url']?.toString(),
      partnerRole: profile?['role']?.toString() ?? 'User',
      lastMessage: row['body']?.toString() ?? row['content']?.toString() ?? '',
      time: time,
      unread: row['is_read'] == false,
      isGroup: row['is_group'] == true,
      initialMessages: [],
      targetUserId: partnerId,
    );
  }).toList();
}

// --- Data Models ---
class _Thread {
  final String name;
  final String? avatarUrl;
  final String partnerRole;
  final String lastMessage;
  final String time;
  final bool unread;
  final bool isGroup;
  final List<_ChatEntry> initialMessages;
  final String? targetUserId;

  const _Thread({
    required this.name,
    this.avatarUrl,
    required this.partnerRole,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.isGroup,
    required this.initialMessages,
    this.targetUserId,
  });
}

class _ChatEntry {
  final String id;
  final String text;
  final bool isSender;
  final String time;
  final String? senderId;
  final String? replyToId;

  const _ChatEntry({
    this.id = '',
    required this.text,
    required this.isSender,
    required this.time,
    this.senderId,
    this.replyToId,
  });
}

