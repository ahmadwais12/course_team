import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class StudentGroupsScreen extends ConsumerStatefulWidget {
  const StudentGroupsScreen({super.key});

  @override
  ConsumerState<StudentGroupsScreen> createState() => _StudentGroupsScreenState();
}

class _StudentGroupsScreenState extends ConsumerState<StudentGroupsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await Supabase.instance.client
          .from('student_groups')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _groups = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredGroups = _searchQuery.isEmpty
        ? _groups
        : _groups.where((g) =>
            g['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            g['class'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroups,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateGroupDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Error loading groups: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadGroups,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: t(LCrud.searchHintGeneric, ref),
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                    ),
                    Expanded(
                      child: filteredGroups.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.group_off, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text('No groups found', style: theme.textTheme.titleMedium),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredGroups.length,
                              itemBuilder: (context, index) {
                                final group = filteredGroups[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: theme.colorScheme.primary,
                                      child: const Icon(Icons.group, color: Colors.white),
                                    ),
                                    title: Text(group['name'] as String),
                                    subtitle: Text('${group['class']} â€¢ ${group['members']} students'),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) => _handleGroupAction(context, value, group),
                                      itemBuilder: (context) => [
                                        PopupMenuItem(value: 'view', child: const Text('View Members')),
                                        PopupMenuItem(value: 'chat', child: Text(t(LChat.openConversation, ref))),
                                        PopupMenuItem(value: 'edit', child: Text(t(L.edit, ref))),
                                        PopupMenuItem(value: 'delete', child: Text(t(L.delete, ref), style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                    onTap: () => _openGroupChat(context, group),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroupDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Group'),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _CreateGroupPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) {
      _loadGroups();
    }
  }

  void _handleGroupAction(BuildContext context, String action, Map<String, dynamic> group) {
    switch (action) {
      case 'view':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Viewing ${group['name']} members')),
        );
        break;
      case 'chat':
        context.push('/chat/${group['id']}');
        break;
      case 'edit':
        _showEditGroupDialog(context, group);
        break;
      case 'delete':
        _showDeleteConfirmation(context, group);
        break;
    }
  }

  void _showEditGroupDialog(BuildContext context, Map<String, dynamic> group) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _EditGroupPage(group: group),
        fullscreenDialog: true,
      ),
    );
    if (result == true) {
      _loadGroups();
    }
  }

  void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete "${group['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client
                    .from('student_groups')
                    .delete()
                    .eq('id', group['id']);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Group "${group['name']}" deleted')),
                  );
                  _loadGroups();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete group: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openGroupChat(BuildContext context, Map<String, dynamic> group) {
    context.push('/chat/${group['id']}');
  }
}

class _CreateGroupPage extends ConsumerStatefulWidget {
  const _CreateGroupPage();

  @override
  ConsumerState<_CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends ConsumerState<_CreateGroupPage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedClass;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty || _selectedClass == null) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.from('student_groups').insert({
        'name': _nameController.text,
        'class': _selectedClass,
        'description': _descController.text,
        'members': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group "${_nameController.text}" created for $_selectedClass')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Student Group'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () { debugPrint('[student_groups_screen] Save button CLICKED'); _save(); },
            child: const Text('Create'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
initialValue: _selectedClass,
              decoration: const InputDecoration(
                labelText: 'Select Class',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'IELTS-A1', child: Text('IELTS-A1')),
                DropdownMenuItem(value: 'IELTS-A2', child: Text('IELTS-A2')),
                DropdownMenuItem(value: 'Grade 10-A', child: Text('Grade 10-A')),
                DropdownMenuItem(value: 'Grade 10-B', child: Text('Grade 10-B')),
              ],
              onChanged: (value) => setState(() => _selectedClass = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditGroupPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> group;
  const _EditGroupPage({required this.group});

  @override
  ConsumerState<_EditGroupPage> createState() => _EditGroupPageState();
}

class _EditGroupPageState extends ConsumerState<_EditGroupPage> {
  late final TextEditingController _nameController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group['name'] as String);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await Supabase.instance.client
          .from('student_groups')
          .update({
            'name': _nameController.text,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.group['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update group: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Group'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () { debugPrint('[student_groups_screen] Save button CLICKED'); _save(); },
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
