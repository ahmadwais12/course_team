import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/widgets/adaptive/adaptive_widgets.dart';

/// Reusable adaptive Supabase list/CRUD page used to replace Coming Soon / FeatureHub stubs.
class AdaptiveDataPage extends ConsumerStatefulWidget {
  final String title;
  final String tableName;
  final IconData icon;
  final Color accentColor;
  final String? subtitle;
  final List<String> displayFields;
  final String? orderBy;
  final Map<String, dynamic> Function()? defaultInsert;
  final String Function(Map<String, dynamic> row)? titleBuilder;
  final String Function(Map<String, dynamic> row)? subtitleBuilder;

  const AdaptiveDataPage({
    super.key,
    required this.title,
    required this.tableName,
    this.icon = Icons.table_chart_outlined,
    this.accentColor = const Color(0xFF0EA5E9),
    this.subtitle,
    this.displayFields = const ['name', 'title', 'status'],
    this.orderBy = 'created_at',
    this.defaultInsert,
    this.titleBuilder,
    this.subtitleBuilder,
  });

  @override
  ConsumerState<AdaptiveDataPage> createState() => _AdaptiveDataPageState();
}

class _AdaptiveDataPageState extends ConsumerState<AdaptiveDataPage> {
  final _sb = Supabase.instance.client;
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = widget.orderBy != null
          ? await _sb
              .from(widget.tableName)
              .select()
              .order(widget.orderBy!, ascending: false)
              .limit(200)
          : await _sb.from(widget.tableName).select().limit(200);
      if (!mounted) return;
      setState(() {
        _rows = List<Map<String, dynamic>>.from(raw as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _titleOf(Map<String, dynamic> row) {
    if (widget.titleBuilder != null) return widget.titleBuilder!(row);
    for (final f in widget.displayFields) {
      final v = row[f];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return row['id']?.toString() ?? 'Record';
  }

  String _subtitleOf(Map<String, dynamic> row) {
    if (widget.subtitleBuilder != null) return widget.subtitleBuilder!(row);
    final parts = <String>[];
    for (final f in widget.displayFields.skip(1).take(3)) {
      final v = row[f];
      if (v != null && v.toString().trim().isNotEmpty) {
        parts.add('${_label(f)}: $v');
      }
    }
    return parts.join(' · ');
  }

  String _label(String key) =>
      key.replaceAll('_', ' ').split(' ').map((w) {
        if (w.isEmpty) return w;
        return '${w[0].toUpperCase()}${w.substring(1)}';
      }).join(' ');

  Future<void> _add() async {
    final fields = widget.displayFields
        .where((f) => f != 'id' && f != 'created_at' && f != 'updated_at')
        .toList();
    final controllers = {
      for (final f in fields) f: TextEditingController(),
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add ${widget.title}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: fields
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: controllers[f],
                      decoration: InputDecoration(
                        labelText: _label(f),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final payload = <String, dynamic>{
      ...?widget.defaultInsert?.call(),
      for (final f in fields)
        if (controllers[f]!.text.trim().isNotEmpty) f: controllers[f]!.text.trim(),
    };
    for (final c in controllers.values) {
      c.dispose();
    }
    try {
      await _sb.from(widget.tableName).insert(payload);
      await PlatformAdaptive.lightHaptic();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final confirmed = await showAdaptiveAlert<bool>(
      context: context,
      title: 'Delete?',
      message: 'Delete "${_titleOf(row)}"?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );
    if (confirmed != true) return;
    try {
      await _sb.from(widget.tableName).delete().eq('id', row['id']);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fab = FloatingActionButton.extended(
      onPressed: _add,
      icon: const Icon(Icons.add),
      label: Text('Add ${widget.title}'),
      backgroundColor: widget.accentColor,
    );

    return AdaptiveScaffold(
      title: widget.title,
      floatingActionButton: fab,
      actions: [
        IconButton(
          icon: Icon(PlatformAdaptive.isApple
              ? CupertinoIcons.refresh
              : Icons.refresh),
          onPressed: _load,
        ),
      ],
      body: AdaptiveRefresh(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: AdaptiveProgress());
    }
    if (_error != null) {
      return ListView(
        physics: PlatformAdaptive.scrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(onPressed: _load, child: const Text('Retry')),
          ),
        ],
      );
    }
    if (_rows.isEmpty) {
      return ListView(
        physics: PlatformAdaptive.scrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Icon(widget.icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            widget.subtitle ?? 'No ${widget.title.toLowerCase()} yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Tap + to add the first record.', textAlign: TextAlign.center),
        ],
      );
    }

    return ListView.separated(
      physics: PlatformAdaptive.scrollPhysics(
        const AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final row = _rows[i];
        return Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(
            PlatformAdaptive.isApple ? 12 : 16,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: widget.accentColor.withValues(alpha: 0.15),
              child: Icon(widget.icon, color: widget.accentColor),
            ),
            title: Text(_titleOf(row)),
            subtitle: Text(_subtitleOf(row)),
            trailing: IconButton(
              icon: Icon(
                PlatformAdaptive.isApple
                    ? CupertinoIcons.delete
                    : Icons.delete_outline,
                color: Colors.red[400],
              ),
              onPressed: () => _delete(row),
            ),
          ),
        );
      },
    );
  }
}
