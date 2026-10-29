import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/theme.dart';
import 'package:go_router/go_router.dart';

class NoticeBoardScreen extends ConsumerStatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  ConsumerState<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends ConsumerState<NoticeBoardScreen> {
  List<Map<String, dynamic>> _notices = [];
  bool _loading = true;
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('announcements')
          .select()
          .eq('status', 'published')
          .order('created_at', ascending: false);

      final categories = <String>{'All'};
      for (final row in data) {
        final cat = row['category']?.toString();
        if (cat != null && cat.isNotEmpty) categories.add(cat);
      }

      if (mounted) {
        setState(() {
          _notices = data;
          _categories = categories.toList()..sort();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _notices = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filtered = _selectedCategory == 'All'
        ? _notices
        : _notices.where((n) => n['category']?.toString() == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.go('/notifications'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: AppSpacing.paddingLg,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((cat) {
                          final isSelected = cat == _selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: FilterChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() => _selectedCategory = selected ? cat : 'All');
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor: Colors.blue.withValues(alpha: 0.2),
                              checkmarkColor: Colors.blue,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Recent Notices',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No notices found.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      ...filtered.map((notice) => Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: InkWell(
                          onTap: () => context.go('/notifications'),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Padding(
                            padding: AppSpacing.paddingMd,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.sm,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(notice['category']?.toString() ?? '').withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(AppRadius.full),
                                      ),
                                      child: Text(
                                        notice['category']?.toString() ?? 'General',
                                        style: TextStyle(
                                          color: _getCategoryColor(notice['category']?.toString() ?? ''),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDate(notice['created_at']?.toString()),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  notice['title']?.toString() ?? 'Untitled',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  notice['content']?.toString() ?? '',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                  ],
                ),
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.length < 10) return date ?? '';
    return date.substring(0, 10);
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'important':
        return Colors.red;
      case 'events':
        return Colors.orange;
      case 'holiday':
        return Colors.blue;
      case 'exam':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}
