import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CmResolvedCasesScreen extends ConsumerStatefulWidget {
  const CmResolvedCasesScreen({super.key});

  @override
  ConsumerState<CmResolvedCasesScreen> createState() => _CmResolvedCasesScreenState();
}

class _CmResolvedCasesScreenState extends ConsumerState<CmResolvedCasesScreen> {
  List<Map<String, dynamic>> _cases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    try {
      final data = await Supabase.instance.client
          .from('complaints')
          .select()
          .inFilter('status', ['resolved', 'closed'])
          .order('resolved_at', ascending: false);
      if (mounted) {
        setState(() {
          _cases = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseDate(dynamic date) {
    if (date == null) return '—';
    if (date is DateTime) return date.toLocal().toString().substring(0, 10);
    return date.toString().substring(0, 10);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolved Cases'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cases.isEmpty
              ? Center(
                  child: Text(
                    'No resolved cases yet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cases.length,
                  itemBuilder: (context, index) {
                    final c = _cases[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.withValues(alpha: 0.12),
                          child: const Icon(Icons.check_circle,
                              color: Colors.green),
                        ),
                        title: Text(c['subject']?.toString() ?? 'Complaint'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${c['category'] ?? 'General'} · '
                              '${c['priority'] ?? 'medium'}'.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Resolved: ${_parseDate(c['resolved_at'])}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () {
                          showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                  c['subject']?.toString() ?? 'Complaint'),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (c['description'] != null)
                                      Text(c['description'].toString()),
                                    if (c['resolution_notes'] != null) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        'Resolution:',
                                        style: theme.textTheme.labelLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(c['resolution_notes'].toString()),
                                    ],
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
