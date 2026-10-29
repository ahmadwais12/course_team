import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/widgets/adaptive/adaptive_widgets.dart';

/// Generic CRUD screen that auto-discovers columns from any Supabase table
/// and provides full create/read/update/delete UI with real-time data.
class DynamicTableScreen extends ConsumerStatefulWidget {
  final String tableName;
  final String title;
  final IconData icon;
  final Color accentColor;
  final String? orderColumn;
  final bool ascending;
  final List<String>? hiddenColumns;

  const DynamicTableScreen({
    super.key,
    required this.tableName,
    required this.title,
    this.icon = Icons.table_chart_outlined,
    this.accentColor = Colors.blue,
    this.orderColumn,
    this.ascending = false,
    this.hiddenColumns,
  });

  @override
  ConsumerState<DynamicTableScreen> createState() => _DynamicTableScreenState();
}

class _DynamicTableScreenState extends ConsumerState<DynamicTableScreen> {
  static const int _pageSize = 15;

  final _sb = Supabase.instance.client;
  List<Map<String, dynamic>> _records = [];
  List<String> _columns = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeRealtime();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _subscribeRealtime() {
    try {
      _realtimeChannel = _sb.channel('${widget.tableName}_changes');
      _realtimeChannel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: widget.tableName,
        callback: (_) {
          if (mounted) _refresh();
        },
      );
      _realtimeChannel!.subscribe();
    } catch (_) {}
  }

  Future<void> _refresh() async {
    _page = 0;
    _hasMore = true;
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      final query = _sb
          .from(widget.tableName)
          .select()
          .range(0, _pageSize - 1);
      if (widget.orderColumn != null) {
        query.order(widget.orderColumn!, ascending: widget.ascending);
      }
      final data = await query;
      final records = (data as List).cast<Map<String, dynamic>>();

      // Discover columns from first record or columns API
      List<String> cols = [];
      if (records.isNotEmpty) {
        cols = records.first.keys.toList();
      }

      // Remove hidden columns
      if (widget.hiddenColumns != null) {
        cols = cols.where((c) => !widget.hiddenColumns!.contains(c)).toList();
      }

      if (mounted) {
        setState(() {
          _records = records;
          _columns = cols;
          _loading = false;
          _error = null;
          _hasMore = records.length >= _pageSize;
          _page = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    if (_searchQuery.isNotEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final start = (_page + 1) * _pageSize;
      final end = start + _pageSize - 1;
      final query = _sb
          .from(widget.tableName)
          .select()
          .range(start, end);
      if (widget.orderColumn != null) {
        query.order(widget.orderColumn!, ascending: widget.ascending);
      }
      final data = await query;
      final newRecords = (data as List).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _records.addAll(newRecords);
          _page += 1;
          _hasMore = newRecords.length >= _pageSize;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<Map<String, dynamic>> get _filteredRecords {
    if (_searchQuery.isEmpty) return _records;
    final q = _searchQuery.toLowerCase();
    return _records.where((r) {
      return r.values.any((v) => v?.toString().toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredRecords;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.icon, color: widget.accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Text(widget.title),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add ${widget.title}',
            onPressed: () => _showFormDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search records...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          // Status bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${filtered.length} record(s)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                if (_loading)
                  const SizedBox(
                    width: 16, height: 16,
                    child: AdaptiveProgress(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Content
          Expanded(
            child: _buildContent(theme, filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, List<Map<String, dynamic>> filtered) {
    if (_loading) {
      return const Center(child: AdaptiveProgress());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(t(LAll.all_error_loading_data, ref), style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(_error!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: Text(t(L.retry, ref)),
            ),
          ],
        ),
      );
    }
    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(t(LAll.all_no_records_found, ref), style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(t(LAll.all_add_a_new_record_to_get_started, ref),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                )),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => _showFormDialog(context),
              icon: const Icon(Icons.add),
              label: Text(t(LAll.all_add_record, ref)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
        itemCount: filtered.length + 1,
        itemBuilder: (context, index) {
          if (index >= filtered.length) {
            return _buildFooter(theme);
          }
          final record = filtered[index];
          return _RecordCard(
            record: record,
            columns: _columns,
            accentColor: widget.accentColor,
            onEdit: () => _showFormDialog(context, record: record),
            onDelete: () => _confirmDelete(context, record),
          );
        },
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    final filtered = _filteredRecords;
    if (_error != null) return const SizedBox.shrink();
    if (_searchQuery.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            '${filtered.length} result(s)',
            style: theme.textTheme.bodySmall,
          ),
        ),
      );
    }
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      );
    }
    if (!_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'End of list — ${_records.length} record(s)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _confirmDelete(BuildContext context, Map<String, dynamic> record) async {
    final id = record['id']?.toString() ?? '';
    final name = record.values.firstWhere(
      (v) => v is String && v.length > 3 && v.length < 50,
      orElse: () => id,
    ).toString();

    final confirmed = await showAdaptiveAlert<bool>(
      context: context,
      title: t(LAll.all_confirm_delete, ref),
      message: 'Delete "$name"? This action cannot be undone.',
      confirmLabel: t(L.delete, ref),
      cancelLabel: t(L.cancel, ref),
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      try {
        await _sb.from(widget.tableName).delete().eq('id', id);
        _loadData();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tt(LAll.all_x_deleted_successfully, ref, [name]))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tt(LAll.all_delete_failed_x, ref, [e.toString()])), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showFormDialog(BuildContext context, {Map<String, dynamic>? record}) async {
    final isEditing = record != null;
    final formKey = GlobalKey<FormState>();
    final controllers = <String, TextEditingController>{};
    final displayColumns = _columns.where((c) => 
      c != 'id' && c != 'nid' && c != 'created_at' && c != 'updated_at' && 
      !c.endsWith('_at') && c != 'password_hash' && c != 'token'
    ).toList();

    for (final col in displayColumns) {
      controllers[col] = TextEditingController(
        text: isEditing ? (record[col]?.toString() ?? '') : '',
      );
    }

    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(isEditing ? Icons.edit : Icons.add, color: widget.accentColor),
            const SizedBox(width: 8),
            Text(isEditing ? 'Edit ${widget.title}' : 'New ${widget.title}'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: displayColumns.map((col) {
                  final displayName = col.replaceAll('_', ' ');
                  final parts = displayName.split(' ');
                  final capitalized = parts.map((p) => 
                    p.isNotEmpty ? '${p[0].toUpperCase()}${p.substring(1)}' : ''
                  ).join(' ');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: controllers[col],
                      decoration: InputDecoration(
                        labelText: capitalized,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                      maxLines: col.contains('description') || col.contains('text') || col.contains('content') ? 3 : 1,
                      validator: record?[col] != null && col == 'name'
                          ? (v) => v == null || v.isEmpty ? 'Required' : null
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton.icon(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final data = <String, dynamic>{};
                for (final col in displayColumns) {
                  final val = controllers[col]?.text ?? '';
                  if (record != null && val == record[col]?.toString()) continue;
                  if (val.isNotEmpty) {
                    data[col] = val;
                  }
                }
                if (isEditing) {
                  final id = record['id'];
                  if (data.isNotEmpty) {
                    await _sb.from(widget.tableName).update(data).eq('id', id);
                  }
                } else {
                  await _sb.from(widget.tableName).insert(data);
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
                _loadData();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(tt(LAll.all_error_x, ref, [e.toString()])),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: Icon(isEditing ? Icons.save : Icons.add),
            label: Text(isEditing ? 'Save Changes' : 'Create'),
          ),
        ],
      ),
    );

    for (final c in controllers.values) {
      c.dispose();
    }
  }
}

class _RecordCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final List<String> columns;
  final Color accentColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecordCard({
    required this.record,
    required this.columns,
    required this.accentColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Find name/title field for the card title
    final titleField = columns.firstWhere(
      (c) => ['name', 'title', 'label', 'full_name', 'slug'].contains(c),
      orElse: () => columns.isNotEmpty ? columns[0] : 'id',
    );
    final title = record[titleField]?.toString() ?? 'No name';
    final nid = record['nid']?.toString() ?? '';

    // Get subtitle and status fields
    final subtitleCols = columns.where((c) =>
      c != titleField && c != 'id' && c != 'nid' && c != 'created_at' &&
      c != 'updated_at' && !c.endsWith('_at') && !c.contains('password') &&
      c != 'token' && c != 'settings' && !c.contains('json')
    ).take(3).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    title.isNotEmpty ? title[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (nid.isNotEmpty)
                      Text(
                        '#$nid',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    if (subtitleCols.isNotEmpty)
                      ...subtitleCols.map((c) {
                        final val = record[c]?.toString() ?? '';
                        if (val.isEmpty || val == title) return const SizedBox.shrink();
                        return Text(
                          val,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: onDelete,
                tooltip: 'Delete',
                color: Colors.red[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
