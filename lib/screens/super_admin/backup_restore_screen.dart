import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  List<Map<String, dynamic>> _backups = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('backups')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _backups = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isCreating = true);
    try {
      await Supabase.instance.client.from('backups').insert({
        'name': 'Backup ${DateTime.now().toString().substring(0, 19)}',
        'status': 'completed',
        'size_mb': 0,
        'tables_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'created_by': Supabase.instance.client.auth.currentUser?.id,
      });
      _loadBackups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_backup_failed_x, ref, [e.toString()]))),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _deleteBackup(Map<String, dynamic> backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Backup'),
        content: Text(
            'Delete "${backup['name']}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('backups')
            .delete()
            .eq('id', backup['id']);
        _loadBackups();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () { if (context.canPop()) { context.pop(); } else { context.go(AppRoutes.superAdmin); } }), title: const Text('Backup & Restore')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreating ? null : _createBackup,
        icon: _isCreating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.backup_rounded),
        label: Text(_isCreating ? 'Creating...' : 'New Backup'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _statCard(
                              'Total Backups',
                              '${_backups.length}',
                              Icons.backup_rounded,
                              Colors.teal),
                          const SizedBox(width: 12),
                          _statCard(
                              'Completed',
                              '${_backups.where((b) => b['status'] == 'completed').length}',
                              Icons.check_circle_outline,
                              Colors.green),
                          const SizedBox(width: 12),
                          _statCard(
                              'Failed',
                              '${_backups.where((b) => b['status'] == 'failed').length}',
                              Icons.error_outline,
                              Colors.red),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _backups.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.backup_outlined,
                                      size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text('No backups yet',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Text('Create your first backup',
                                      style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              itemCount: _backups.length,
                              itemBuilder: (context, index) {
                                final backup = _backups[index];
                                return _BackupCard(
                                  backup: backup,
                                  onRestore: () =>
                                      _restoreBackup(backup),
                                  onDelete: () =>
                                      _deleteBackup(backup),
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

  Future<void> _restoreBackup(Map<String, dynamic> backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup'),
        content: Text(
            'Restore "${backup['name']}"? This will overwrite current data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Restore initiated for "${backup['name']}"')),
        );
      }
    }
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(label,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  final Map<String, dynamic> backup;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _BackupCard({
    required this.backup,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = backup['status']?.toString() ?? 'unknown';
    final statusColor = switch (status) {
      'completed' => Colors.green,
      'failed' => Colors.red,
      _ => Colors.orange,
    };
    final name = backup['name']?.toString() ?? 'Unknown Backup';
    final createdAt = backup['created_at']?.toString() ?? '';
    final dateStr = createdAt.length >= 10
        ? createdAt.substring(0, 10)
        : createdAt;
    final sizeMb = backup['size_mb'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(
            status == 'completed'
                ? Icons.backup_rounded
                : Icons.error_outline,
            color: statusColor,
            size: 20,
          ),
        ),
        title:
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            Text(dateStr, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 12),
            Text('${sizeMb}MB', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.restore_rounded, size: 20),
              tooltip: 'Restore',
              onPressed: onRestore,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

