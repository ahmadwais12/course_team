import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class IssueBookScreen extends ConsumerStatefulWidget {
  const IssueBookScreen({super.key});

  @override
  ConsumerState<IssueBookScreen> createState() => _IssueBookScreenState();
}

class _IssueBookScreenState extends ConsumerState<IssueBookScreen> {
  List<Map<String, dynamic>> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final data = await Supabase.instance.client
          .from('books')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _books = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_failed_to_load_books_x, ref, ['$e']))),
        );
      }
    }
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
                  child: _books.isEmpty
                      ? Center(child: Text(t(LCrud.noItemsFound, ref)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _books.length,
                          itemBuilder: (context, index) {
                            final book = _books[index];
                            final available = book['available_copies'] ?? book['available'] ?? 0;
                            final total = book['total_copies'] ?? book['total'] ?? 0;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: available > 0
                                      ? Colors.blue[100]
                                      : Colors.grey[300],
                                  child: Icon(Icons.book,
                                      color: available > 0
                                          ? Colors.blue
                                          : Colors.grey),
                                ),
                                title: Text(book['title'] ?? ''),
                                subtitle:
                                    Text('By ${book['author'] ?? 'Unknown'}'),
                                trailing: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$available/$total available',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: available > 0
                                            ? Colors.blue
                                            : Colors.red,
                                      ),
                                    ),
                                    if (available > 0)
                                      ElevatedButton(
                                        onPressed: () =>
                                            _issueBook(book),
                                        child: Text(t(LStaff.issueBook, ref)),
                                      )
                                    else
                                      Text(t(LStaff.unavailable, ref),
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontWeight:
                                                  FontWeight.bold)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _issueBook(Map<String, dynamic> book) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _IssueBookFormPage(book: book),
        fullscreenDialog: true,
      ),
    );
    if (result is Map<String, dynamic> && result['saved'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      try {
        await Supabase.instance.client.from('book_issues').insert(data);
        await Supabase.instance.client
            .from('books')
            .update({
              'available_copies':
                  (book['available_copies'] ?? book['available'] ?? 1) - 1,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', book['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t(LCrud.savedSuccessfully, ref))),
          );
        }
        _loadBooks();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tt(LAll.all_failed_to_issue_book_x, ref, ['$e']))),
          );
        }
      }
    }
  }
}

class _IssueBookFormPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> book;
  const _IssueBookFormPage({required this.book});

  @override
  ConsumerState<_IssueBookFormPage> createState() => _IssueBookFormPageState();
}

class _IssueBookFormPageState extends ConsumerState<_IssueBookFormPage> {
  final _studentIdCtrl = TextEditingController();
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 14));

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  void _save() {
    if (_studentIdCtrl.text.trim().isEmpty) return;
    final data = {
      'book_id': widget.book['id'],
      'member_id': _studentIdCtrl.text.trim(),
      'issued_at': DateTime.now().toIso8601String(),
      'due_date': _selectedDueDate.toIso8601String(),
      'status': 'issued',
    };
    Navigator.pop(context, {'saved': true, 'data': data});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LStaff.bookingIssue, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(L.cancel, ref)),
          ),
          ElevatedButton(
            onPressed: () { debugPrint('[issue_book_screen] Save button CLICKED'); _save(); },
            child: Text(t(L.confirm, ref)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Book: ${widget.book['title'] ?? ''}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _studentIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Student/Member ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                '${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}',
              ),
              subtitle: Text(t(LAll.all_tap_to_change_due_date, ref)),
              onTap: _pickDate,
            ),
          ],
        ),
      ),
    );
  }
}
