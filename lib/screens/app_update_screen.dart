import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class AppUpdateScreen extends ConsumerStatefulWidget {
  const AppUpdateScreen({super.key});

  @override
  ConsumerState<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends ConsumerState<AppUpdateScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _releases = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReleases();
  }

  Future<void> _loadReleases() async {
    try {
      final data = await _supabase
          .from('app_releases')
          .select()
          .eq('is_active', true)
          .order('published_at', ascending: false)
          .limit(10);
      setState(() {
        _releases = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t(LTitle.appUpdates, ref))),
      body: _loading
          ? const PageSkeleton(type: 'dashboard')
          : _releases.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.system_update, size: 64,
                          color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      Text('No updates available',
                          style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text('You are on the latest version',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          )),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _releases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final r = _releases[i];
                    final isMandatory = r['is_mandatory'] == true;
                    final publishedAt = r['published_at'] != null
                        ? DateTime.tryParse(r['published_at'])
                        : null;
                    final notes = r['release_notes'] as String? ?? '';
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.new_releases,
                                    color: isMandatory
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'v${r['version']}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (r['build_number'] != null) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${r['build_number']})',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                                const Spacer(),
                                if (isMandatory)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.error
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Required',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (r['title'] != null) ...[
                              const SizedBox(height: 8),
                              Text(r['title'],
                                  style: theme.textTheme.titleSmall),
                            ],
                            if (publishedAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Released: ${publishedAt.toLocal().toString().substring(0, 10)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                            if (notes.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              Text('Release Notes',
                                  style: theme.textTheme.labelLarge),
                              const SizedBox(height: 4),
                              Text(notes, style: theme.textTheme.bodySmall),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
