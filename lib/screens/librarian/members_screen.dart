import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final data = await Supabase.instance.client
          .from('library_members')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _members = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load members: $e')),
        );
      }
    }
  }

  DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    return DateTime.parse(date.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: t(LCrud.searchHintGeneric, ref),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                Expanded(
                  child: _members.isEmpty
                      ? Center(child: Text(t(LCrud.noItemsFound, ref)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _members.length,
                          itemBuilder: (context, index) {
                            final member = _members[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getMemberTypeColor(
                                          member['member_type'])
                                      .withValues(alpha: 0.1),
                                  child: Icon(Icons.person,
                                      color: _getMemberTypeColor(
                                          member['member_type'])),
                                ),
                                title: Text(member['name'] ?? ''),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${member['member_type'] ?? 'N/A'} â€¢ ID: ${member['member_id'] ?? member['id'] ?? 'N/A'}'),
                                    Text(
                                        'Books borrowed: ${member['books_borrowed'] ?? 0}'),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: () =>
                                      _showDetails(member),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemberDialog(),
        icon: const Icon(Icons.add),
        label: Text(t(LCrud.addMember, ref)),
      ),
    );
  }

  Future<void> _showAddMemberDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _AddMemberFormPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) _loadMembers();
  }

  Color _getMemberTypeColor(String? type) {
    switch (type) {
      case 'Student':
        return Colors.blue;
      case 'Teacher':
        return Colors.blue;
      case 'Staff':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showDetails(Map<String, dynamic> member) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member['name'] ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildDetailRow('Member ID',
                  member['member_id'] ?? member['id']?.toString() ?? ''),
              _buildDetailRow('Type', member['member_type'] ?? ''),
              _buildDetailRow('Joined',
                  _formatDate(_parseDate(member['joined_date']))),
              _buildDetailRow(
                  'Books Borrowed', '${member['books_borrowed'] ?? 0}'),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
              width: 120,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _AddMemberFormPage extends ConsumerStatefulWidget {
  const _AddMemberFormPage();

  @override
  ConsumerState<_AddMemberFormPage> createState() => _AddMemberFormPageState();
}

class _AddMemberFormPageState extends ConsumerState<_AddMemberFormPage> {
  final _nameCtrl = TextEditingController();
  final _memberIdCtrl = TextEditingController();
  String _selectedType = 'Student';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _memberIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    try {
      await Supabase.instance.client.from('library_members').insert({
        'name': _nameCtrl.text.trim(),
        'member_id': _memberIdCtrl.text.trim(),
        'member_type': _selectedType,
        'joined_date': DateTime.now().toIso8601String(),
        'books_borrowed': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaff.memberAdded, ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add member: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LCrud.addMember, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(L.cancel, ref)),
          ),
          ElevatedButton(
            onPressed: () { debugPrint('[members_screen] Save button CLICKED'); _save(); },
            child: Text(t(L.add, ref)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _memberIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Member ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: const ['Student', 'Teacher', 'Staff']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
          ],
        ),
      ),
    );
  }
}
