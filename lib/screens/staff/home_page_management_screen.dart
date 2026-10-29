import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class HomePageManagementScreen extends ConsumerStatefulWidget {
  const HomePageManagementScreen({super.key});

  @override
  ConsumerState<HomePageManagementScreen> createState() =>
      _HomePageManagementScreenState();
}

class _HomePageManagementScreenState
    extends ConsumerState<HomePageManagementScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _heroSections = [];
  List<Map<String, dynamic>> _features = [];
  List<Map<String, dynamic>> _stats = [];
  List<Map<String, dynamic>> _testimonials = [];

  @override
  void initState() {
    super.initState();
    _loadHomePageData();
  }

  Future<void> _loadHomePageData() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // Load hero sections
      final heroResponse = await supabase
          .from('home_hero_sections')
          .select()
          .order('display_order');
      _heroSections = List<Map<String, dynamic>>.from(heroResponse);

      // Load features
      final featuresResponse =
          await supabase.from('home_features').select().order('display_order');
      _features = List<Map<String, dynamic>>.from(featuresResponse);

      // Load stats
      final statsResponse =
          await supabase.from('home_stats').select().order('display_order');
      _stats = List<Map<String, dynamic>>.from(statsResponse);

      // Load testimonials
      final testimonialsResponse = await supabase
          .from('home_testimonials')
          .select()
          .order('display_order');
      _testimonials = List<Map<String, dynamic>>.from(testimonialsResponse);

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(LStaff.manageHomePage, ref)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHomePageData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const PageSkeleton(type: 'dashboard')
          : DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  const TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(
                          text: 'Hero Section',
                          icon: Icon(Icons.view_carousel)),
                      Tab(
                          text: 'Features',
                          icon: Icon(Icons.featured_play_list)),
                      Tab(text: 'Stats', icon: Icon(Icons.bar_chart)),
                      Tab(text: 'Testimonials', icon: Icon(Icons.format_quote)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildHeroSectionList(theme),
                        _buildFeaturesList(theme),
                        _buildStatsList(theme),
                        _buildTestimonialsList(theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        icon: const Icon(Icons.add),
        label: Text(t(L.add, ref)),
      ),
    );
  }

  Widget _buildHeroSectionList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _heroSections.length,
      itemBuilder: (context, index) {
        final item = _heroSections[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(Icons.view_carousel, color: theme.colorScheme.primary),
            ),
            title: Text(item['title'] ?? 'No Title'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item['subtitle'] != null)
                  Text(item['subtitle'], maxLines: 2),
                const SizedBox(height: 4),
                    Text(
                      '${t(LStaffCMS.displayOrder, ref)}: ${item['display_order'] ?? index + 1}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, item),
                  itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text(t(L.edit, ref))
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 20),
                        SizedBox(width: 8),
                        Text(t(LStaffCMS.toggleActive, ref)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text(t(L.delete, ref), style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              ),
            );
          },
        );
    }

Widget _buildFeaturesList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _features.length,
      itemBuilder: (context, index) {
        final item = _features[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.featured_play_list,
                  color: theme.colorScheme.secondary),
            ),
            title: Text(item['title'] ?? 'No Title'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item['description'] != null)
                  Text(item['description'], maxLines: 2),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(
                      label:
                          Text('${t(LStaffCMS.displayOrder, ref)}: ${item['display_order'] ?? index + 1}'),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    if (item['is_active'] == true)
                      Chip(
                        label: Text(t(LCrud.active, ref)),
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, item),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text(t(L.edit, ref))
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 8),
                      Text(t(LStaffCMS.toggleActive, ref)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text(t(L.delete, ref), style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

Widget _buildStatsList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stats.length,
      itemBuilder: (context, index) {
        final item = _stats[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.bar_chart, color: theme.colorScheme.tertiary),
            ),
            title: Text(item['value'] ?? 'No Value'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['label'] ?? 'No Label'),
                const SizedBox(height: 4),
                Text(
                  'Order: ${item['display_order'] ?? index + 1}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, item),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text(t(L.edit, ref))
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text(t(L.delete, ref), style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

Widget _buildTestimonialsList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _testimonials.length,
      itemBuilder: (context, index) {
        final item = _testimonials[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.format_quote, color: Colors.purple),
            ),
            title: Text(
              item['quote'] ?? 'No Quote',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item['author'] != null) Text('â€” ${item['author']}'),
                const SizedBox(height: 4),
                Text(
                  'Order: ${item['display_order'] ?? index + 1}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, item),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text(t(L.edit, ref))
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text(t(L.delete, ref), style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

void _handleMenuAction(String action, Map<String, dynamic> item) {
    switch (action) {
      case 'edit':
        _showEditDialog(item);
        break;
      case 'toggle':
        _toggleActive(item);
        break;
      case 'delete':
        _showDeleteConfirmation(item);
        break;
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> item) async {
    try {
      final supabase = Supabase.instance.client;
      final table = _getTableName(item);
      final newStatus = !(item['is_active'] ?? true);

      await supabase
          .from(table)
          .update({'is_active': newStatus}).eq('id', item['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated')),
        );
      }
      _loadHomePageData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(L.delete, ref)),
        content: Text(
            'Are you sure you want to delete "${item['title'] ?? item['value'] ?? 'this item'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t(L.cancel, ref)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t(L.delete, ref)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final supabase = Supabase.instance.client;
        final table = _getTableName(item);

        await supabase.from(table).delete().eq('id', item['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Content deleted')),
          );
        }
        _loadHomePageData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _showAddDialog() {
    // Show dialog to select content type
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(t(L.add, ref)),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showHeroForm();
            },
            child: const ListTile(
              leading: Icon(Icons.view_carousel),
              title: Text('Hero Section'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showFeatureForm();
            },
            child: const ListTile(
              leading: Icon(Icons.featured_play_list),
              title: Text('Feature'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showStatsForm();
            },
            child: const ListTile(
              leading: Icon(Icons.bar_chart),
              title: Text('Stat'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showTestimonialForm();
            },
            child: const ListTile(
              leading: Icon(Icons.format_quote),
              title: Text('Testimonial'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> item) {
    // Similar to add dialog but pre-filled
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Edit form - Implement based on content type')),
    );
  }

  void _showHeroForm() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => _HeroSectionFormPage(
              nextOrder: _heroSections.length + 1),
          fullscreenDialog: true),
    );
    if (result == true) {
      _loadHomePageData();
    }
  }

  void _showFeatureForm() {
    // Similar to hero form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feature form - Similar implementation')),
    );
  }

  void _showStatsForm() {
    // Similar to hero form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stats form - Similar implementation')),
    );
  }

  void _showTestimonialForm() {
    // Similar to hero form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Testimonial form - Similar implementation')),
    );
  }

  String _getTableName(Map<String, dynamic> item) {
    if (item.containsKey('quote')) return 'home_testimonials';
    if (item.containsKey('description')) return 'home_features';
    if (item.containsKey('subtitle')) return 'home_hero_sections';
    return 'home_stats';
  }
}

class _HeroSectionFormPage extends ConsumerStatefulWidget {
  final int nextOrder;

  const _HeroSectionFormPage({required this.nextOrder});

  @override
  ConsumerState<_HeroSectionFormPage> createState() =>
      _HeroSectionFormPageState();
}

class _HeroSectionFormPageState extends ConsumerState<_HeroSectionFormPage> {
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  late final TextEditingController _orderCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _orderCtrl = TextEditingController(text: '${widget.nextOrder}');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.from('home_hero_sections').insert({
        'title': _titleCtrl.text.trim(),
        'subtitle': _subtitleCtrl.text.trim(),
        'display_order': int.tryParse(_orderCtrl.text.trim()) ?? 1,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaffCMS.contentAdded, ref))),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LStaffCMS.heroSections, ref)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () { debugPrint('[home_page_management_screen] Save button CLICKED'); _save(); },
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(t(L.add, ref)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration:
                  InputDecoration(labelText: t(LStaffCMS.cTitle, ref)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subtitleCtrl,
              decoration:
                  InputDecoration(labelText: t(LStaffCMS.cSubtitle, ref)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _orderCtrl,
              decoration: InputDecoration(
                  labelText: t(LStaffCMS.displayOrder, ref)),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
}
