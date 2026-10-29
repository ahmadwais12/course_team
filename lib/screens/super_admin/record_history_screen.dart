import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/app_routes_all.dart';

class RecordHistoryScreen extends StatefulWidget {
  const RecordHistoryScreen({super.key});

  @override
  State<RecordHistoryScreen> createState() => _RecordHistoryScreenState();
}

class _RecordHistoryScreenState extends State<RecordHistoryScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final data = await Supabase.instance.client
          .from('record_history')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      if (mounted) {
        setState(() {
          _records = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load record history: $e')),
        );
      }
    }
  }

  DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    return DateTime.parse(date.toString());
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  List<Map<String, dynamic>> get _filteredRecords {
    if (_searchQuery.isEmpty) return _records;
    final q = _searchQuery.toLowerCase();
    return _records.where((r) {
      return (r['table_name']?.toString().toLowerCase().contains(q) ??
          false) ||
          (r['record_id']?.toString().toLowerCase().contains(q) ?? false) ||
          (r['action']?.toString().toLowerCase().contains(q) ?? false);
    }).toList();
  }

  IconData _actionIcon(String? action) {
    switch (action?.toLowerCase()) {
      case 'delete':
        return Icons.delete_outline;
      case 'update':
        return Icons.edit;
      case 'insert':
        return Icons.add_circle_outline;
      default:
        return Icons.history;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () { if (context.canPop()) { context.pop(); } else { context.go(AppRoutes.superAdmin); } }), title: const Text('Record History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        onChanged: (v) =>
                            setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Search record history...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ),
                    Expanded(
                      child: _filteredRecords.isEmpty
                          ? const Center(
                              child: Text('No record history found'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredRecords.length,
                              itemBuilder: (context, index) {
                                final record = _filteredRecords[index];
                                final action =
                                    record['action']?.toString() ?? 'N/A';
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.grey[200],
                                      child: Icon(_actionIcon(action),
                                          color: Colors.black),
                                    ),
                                    title: Text(
                                        '${record['table_name'] ?? 'N/A'} > $action'),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Record ID: ${record['record_id'] ?? 'N/A'}'),
                                        Text(
                                            'Changed by: ${record['changed_by'] ?? 'N/A'}'),
                                        Text(
                                            'Time: ${_formatDateTime(_parseDate(record['created_at']))}'),
                                      ],
                                    ),
                                    onTap: record['old_data'] != null ||
                                            record['new_data'] != null
                                        ? () => _showDataDiff(record)
                                        : null,
                                  ),
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

  void _showDataDiff(Map<String, dynamic> record) {
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
              Text('Data Changes',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (record['old_data'] != null) ...[
                Text('Old Data:',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(record['old_data'].toString()),
                ),
              ],
              if (record['new_data'] != null) ...[
                const SizedBox(height: 16),
                Text('New Data:',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(record['new_data'].toString()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


