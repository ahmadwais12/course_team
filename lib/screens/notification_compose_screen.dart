import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:course_emis/providers/notification_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationComposeScreen extends ConsumerStatefulWidget {
  const NotificationComposeScreen({super.key});

  @override
  ConsumerState<NotificationComposeScreen> createState() => _NotificationComposeScreenState();
}

class _NotificationComposeScreenState extends ConsumerState<NotificationComposeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String _targetType = 'all'; // 'all', 'specific'
  String _type = 'announcement';
  String _priority = 'normal';
  final Set<String> _selectedUserIds = {};

  List<Map<String, dynamic>> _users = [];
  bool _loadingUsers = false;
  String _userSearch = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    debugPrint('[NotificationCompose] _loadUsers — fetching non-student profiles...');
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('id, full_name, email, role')
          .neq('role', 'student')
          .order('full_name');
      _users = List<Map<String, dynamic>>.from(data);
      debugPrint('[NotificationCompose] _loadUsers — loaded ${_users.length} users');
    } catch (e) {
      debugPrint('[NotificationCompose] _loadUsers — error: $e');
    }
    setState(() => _loadingUsers = false);
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('[NotificationCompose] _send — form validation failed');
      return;
    }
    if (_targetType == 'specific' && _selectedUserIds.isEmpty) {
      debugPrint('[NotificationCompose] _send — no specific users selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one user')),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    String? tenantId;
    if (user != null) {
      final profile = await Supabase.instance.client
          .from('users')
          .select('tenant_id')
          .eq('id', user.id)
          .maybeSingle();
      tenantId = profile?['tenant_id']?.toString();
    }
    final actorId = user?.id;

    debugPrint('[NotificationCompose] _send — preparing payload:');
    debugPrint('[NotificationCompose]   title="${_titleController.text.trim()}"');
    debugPrint('[NotificationCompose]   body="${_bodyController.text.trim()}"');
    debugPrint('[NotificationCompose]   type=$_type, priority=$_priority');
    debugPrint('[NotificationCompose]   actorId=$actorId, tenantId=$tenantId');
    debugPrint('[NotificationCompose]   targetType=$_targetType');
    debugPrint('[NotificationCompose]   selectedUserIds=${_selectedUserIds.length} users');

    try {
      await ref.read(notificationRepositoryProvider).sendBulkNotification(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        type: _type,
        priority: _priority,
        actorId: actorId,
        tenantId: tenantId,
        targetType: _targetType,
        targetRoles: null,
        targetUserIds: _targetType == 'specific' ? _selectedUserIds.toList() : null,
      );

      debugPrint('[NotificationCompose] _send — success!');
      // Reload the notifications cache so the (still-mounted) list screen
      // updates immediately after popping back.
      await ref.read(notificationRepositoryProvider).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent successfully')),
        );
        context.pop();
      }
    } catch (e) {
      debugPrint('[NotificationCompose] _send — error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Notification'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bodyController,
                  decoration: const InputDecoration(
                    labelText: 'Message *',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _type,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'general', child: Text('General')),
                          DropdownMenuItem(value: 'announcement', child: Text('Announcement')),
                          DropdownMenuItem(value: 'academic', child: Text('Academic')),
                          DropdownMenuItem(value: 'attendance', child: Text('Attendance')),
                          DropdownMenuItem(value: 'payment', child: Text('Payment')),
                          DropdownMenuItem(value: 'grade', child: Text('Grade')),
                          DropdownMenuItem(value: 'discount', child: Text('Discount')),
                          DropdownMenuItem(value: 'salary', child: Text('Salary')),
                          DropdownMenuItem(value: 'hr', child: Text('HR')),
                          DropdownMenuItem(value: 'system', child: Text('System')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _type = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                          DropdownMenuItem(value: 'normal', child: Text('Normal')),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                          DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _priority = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text('Send To', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('All Users')),
                    ButtonSegment(value: 'specific', label: Text('Specific Users')),
                  ],
                  selected: {_targetType},
                  onSelectionChanged: (v) {
                    debugPrint('[NotificationCompose] targetType changed: ${v.first}');
                    setState(() {
                      _targetType = v.first;
                      if (v.first == 'specific') _loadUsers();
                    });
                  },
                ),
                const SizedBox(height: 20),

                if (_targetType == 'specific') ...[
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _userSearch = v.toLowerCase()),
                  ),
                  const SizedBox(height: 12),
                  if (_loadingUsers)
                    const Center(child: CircularProgressIndicator())
                  else
                    ...(_users.where((u) {
                      if (_userSearch.isEmpty) return true;
                      final name = (u['full_name'] as String? ?? '').toLowerCase();
                      final email = (u['email'] as String? ?? '').toLowerCase();
                      return name.contains(_userSearch) || email.contains(_userSearch);
                    }).map((u) {
                      final uid = u['id'] as String;
                      final sel = _selectedUserIds.contains(uid);
                      return CheckboxListTile(
                        dense: true,
                        title: Text(u['full_name'] as String? ?? 'No name'),
                        subtitle: Text('${u['role']}  •  ${u['email']}'),
                        value: sel,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) { _selectedUserIds.add(uid); } else { _selectedUserIds.remove(uid); }
                          });
                        },
                      );
                    })),
                ],

                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _send,
                  icon: const Icon(Icons.send),
                  label: const Text('Send Notification'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
