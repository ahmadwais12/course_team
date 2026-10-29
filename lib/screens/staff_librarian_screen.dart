import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/ui_helpers.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class StaffLibrarianScreen extends ConsumerStatefulWidget {
  const StaffLibrarianScreen({super.key});
  @override
  ConsumerState<StaffLibrarianScreen> createState() =>
      _StaffLibrarianScreenState();
}

class _StaffLibrarianScreenState extends ConsumerState<StaffLibrarianScreen> {
  final _sb = Supabase.instance.client;
  bool _loading = true;
  int _totalBooks = 0;
  int _issuedBooks = 0;
  List<Map<String, dynamic>> _bookIssues = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final books = await _sb.from('books').select('id');
      final issues = await _sb.from('book_issues').select();
      final issued = issues
          .where((i) => i['status'] == 'issued')
          .toList();
      setState(() {
        _totalBooks = books.length;
        _issuedBooks = issued.length;
        _bookIssues = List<Map<String, dynamic>>.from(issues);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? issue}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _BookIssueFormPage(issue: issue),
        fullscreenDialog: true,
      ),
    );
    if (result is Map<String, dynamic> && result['saved'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      try {
        if (issue != null) {
          await _sb.from('book_issues').update(data).eq('id', issue['id']);
        } else {
          await _sb.from('book_issues').insert(data);
        }
        await _loadData();
      } catch (_) {}
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> issue) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(LAll.all_delete_book_issue, ref)),
        content: Text(
            t(LAll.all_are_you_sure_you_want_to_delete_this_book_issue, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(t(L.delete, ref)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _sb.from('book_issues').delete().eq('id', issue['id']);
        await _loadData();
      } catch (_) {}
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'returned':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          const SectionHeader(
            title: 'Librarian',
            subtitle: 'Books, catalog, and memberships',
            icon: Icons.local_library_outlined,
          ),
          const VSpace(AppSpacing.lg),
          StatCard(
            title: 'Total Books',
            value: '$_totalBooks',
            icon: Icons.menu_book_rounded,
          ),
          const VSpace(AppSpacing.md),
          StatCard(
            title: 'Books Issued',
            value: '$_issuedBooks',
            icon: Icons.bookmark_added_outlined,
          ),
          const VSpace(AppSpacing.lg),
          Text(
            'Book Issues',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const VSpace(AppSpacing.md),
          if (_bookIssues.isEmpty)
            EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No book issues',
              message: 'Tap + to create a book issue record.',
            )
          else
            ..._bookIssues.map((issue) => _BookIssueCard(
                  issue: issue,
                  statusColor: _statusColor(issue['status'] ?? ''),
                  onEdit: () => _showAddEditDialog(issue: issue),
                  onDelete: () => _confirmDelete(issue),
                )),
        ],
      ),
    );
  }
}

class _BookIssueCard extends StatelessWidget {
  final Map<String, dynamic> issue;
  final Color statusColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BookIssueCard({
    required this.issue,
    required this.statusColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = (issue['status'] ?? 'issued') as String;
    final issueDate = issue['issue_date'] != null
        ? DateTime.tryParse(issue['issue_date'])
        : null;
    final returnDate = issue['return_date'] != null
        ? DateTime.tryParse(issue['return_date'])
        : null;
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return AppCard(
      pressable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book #${issue['book_id'] ?? '-'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const VSpace(AppSpacing.xs),
                    Text(
                      'Student #${issue['student_id'] ?? '-'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const VSpace(AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 14, color: Theme.of(context).hintColor),
              const HSpace(AppSpacing.xs),
              Text(
                'Issued: ${issueDate != null ? fmt(issueDate) : '-'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const HSpace(AppSpacing.md),
              Icon(Icons.event_available,
                  size: 14, color: Theme.of(context).hintColor),
              const HSpace(AppSpacing.xs),
              Text(
                'Returned: ${returnDate != null ? fmt(returnDate) : '-'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const VSpace(AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookIssueFormPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? issue;
  const _BookIssueFormPage({this.issue});

  @override
  ConsumerState<_BookIssueFormPage> createState() =>
      _BookIssueFormPageState();
}

class _BookIssueFormPageState extends ConsumerState<_BookIssueFormPage> {
  late final TextEditingController _bookIdCtrl;
  late final TextEditingController _studentIdCtrl;
  late String _status;
  late DateTime _issueDate;
  DateTime? _returnDate;

  bool get _isEdit => widget.issue != null;

  @override
  void initState() {
    super.initState();
    final issue = widget.issue;
    _bookIdCtrl = TextEditingController(
        text: _isEdit ? (issue!['book_id']?.toString() ?? '') : '');
    _studentIdCtrl = TextEditingController(
        text: _isEdit ? (issue!['student_id']?.toString() ?? '') : '');
    _status = _isEdit ? (issue!['status'] ?? 'issued') : 'issued';
    _issueDate = _isEdit && issue!['issue_date'] != null
        ? DateTime.parse(issue['issue_date'])
        : DateTime.now();
    _returnDate = _isEdit && issue!['return_date'] != null
        ? DateTime.parse(issue['return_date'])
        : null;
  }

  @override
  void dispose() {
    _bookIdCtrl.dispose();
    _studentIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isIssue) async {
    final initial = isIssue ? _issueDate : (_returnDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isIssue) {
          _issueDate = picked;
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _save() {
    final data = {
      'book_id': int.tryParse(_bookIdCtrl.text),
      'student_id': int.tryParse(_studentIdCtrl.text),
      'issue_date': _issueDate.toIso8601String(),
      'return_date': _returnDate?.toIso8601String(),
      'status': _status,
    };
    Navigator.pop(context, {'saved': true, 'data': data});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Book Issue' : 'New Book Issue'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            onPressed: () { debugPrint('[staff_librarian_screen] Save button CLICKED'); _save(); },
            child: Text(_isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _bookIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Book ID'),
            ),
            const VSpace(AppSpacing.md),
            TextField(
              controller: _studentIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Student ID'),
            ),
            const VSpace(AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t(LAll.all_issue_date, ref)),
              subtitle: Text(_fmt(_issueDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t(LAll.all_return_date, ref)),
              subtitle: Text(_returnDate != null ? _fmt(_returnDate!) : 'Not returned yet'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(false),
            ),
            const VSpace(AppSpacing.md),
            DropdownButtonFormField<String>(
initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                DropdownMenuItem(value: 'issued', child: Text(t(LAll.all_issued, ref))),
                DropdownMenuItem(value: 'returned', child: Text(t(LAll.all_returned, ref))),
                DropdownMenuItem(value: 'overdue', child: Text(t(LAll.all_overdue, ref))),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
