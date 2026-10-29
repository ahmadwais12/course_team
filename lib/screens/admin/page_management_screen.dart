import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/page_registry.dart';

class PageManagementScreen extends ConsumerStatefulWidget {
  const PageManagementScreen({super.key});

  @override
  ConsumerState<PageManagementScreen> createState() => _PageManagementScreenState();
}

class _PageManagementScreenState extends ConsumerState<PageManagementScreen> {
  String _selectedRole = 'all';
  String _selectedCategory = 'all';
  String _searchQuery = '';

  List<PageRegistry> get _filteredPages {
    List<PageRegistry> pages = AppPageRegistry.getAllPages();
    if (_selectedRole != 'all') {
      pages = pages
          .where((page) => page.role == _selectedRole || page.role == 'all')
          .toList();
    }
    if (_selectedCategory != 'all') {
      pages =
          pages.where((page) => page.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      pages = pages
          .where((page) =>
              page.name.toLowerCase().contains(query) ||
              page.description.toLowerCase().contains(query))
          .toList();
    }
    return pages;
  }

  Future<void> _syncToSupabase(PageRegistry page, String action) async {
    try {
      final client = Supabase.instance.client;
      final table = 'page_registry';
      switch (action) {
        case 'toggle':
          await client.from(table).upsert({
            'id': page.id,
            'is_active': !page.isActive,
          });
          break;
        case 'delete':
          await client.from(table).delete().eq('id', page.id);
          break;
        case 'add':
          await client.from(table).upsert({
            'id': page.id,
            'name': page.name,
            'description': page.description,
            'category': page.category,
            'role': page.role,
            'is_active': page.isActive,
          });
          break;
      }
    } catch (_) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final roles = AppPageRegistry.getAllRoles();
    final categories = AppPageRegistry.getAllCategories();

    return Scaffold(
      appBar: AppBar(
        title: Text(t(LTitle.pageManagement, ref)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddPageDialog,
            tooltip: t(L.add, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: t(LCrud.searchHintGeneric, ref),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
initialValue: _selectedRole,
                        decoration: InputDecoration(
                          labelText: t(LAuth.role, ref),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                              value: 'all', child: Text(t(LFilter.all, ref))),
                          ...roles.map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(role
                                    .split('_')
                                    .map((word) => word.isEmpty
                                        ? ''
                                        : word[0].toUpperCase() +
                                            word.substring(1))
                                    .join(' ')),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value ?? 'all';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
initialValue: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: t(LCrud.category, ref),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                              value: 'all', child: Text(t(LFilter.all, ref))),
                          ...categories.map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value ?? 'all';
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredPages.length} ${t(LModule.pagesAvailable, ref)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${t(LNav.dashboard, ref)}: ${AppPageRegistry.getAllPages().length} ${t(LModule.pagesAvailable, ref)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredPages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(t(LCrud.noResultsFound, ref)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPages.length,
                    itemBuilder: (context, index) {
                      final page = _filteredPages[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: page.isActive
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.grey.shade300,
                            child: Icon(
                              page.icon,
                              color: page.isActive
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : Colors.grey,
                            ),
                          ),
                          title: Text(
                            page.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: page.isActive ? null : Colors.grey,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(page.description),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildChip(page.category, Theme.of(context).colorScheme.secondaryContainer, Theme.of(context).colorScheme.onSecondaryContainer),
                                  const SizedBox(width: 8),
                                  _buildChip(page.role == 'all' ? t(LFilter.all, ref) : page.role, page.role == 'all' ? Colors.blue.shade100 : Colors.blue.shade100, page.role == 'all' ? Colors.blue.shade900 : Colors.blue.shade900),
                                  const SizedBox(width: 8),
                                  _buildChip(page.isActive ? t(LCrud.active, ref) : t(LCrud.inactive, ref), page.isActive ? Colors.blue.shade100 : Colors.red.shade100, page.isActive ? Colors.blue.shade900 : Colors.red.shade900),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'toggle':
                                  _togglePageStatus(page);
                                  break;
                                case 'edit':
                                  _showEditPageDialog(page);
                                  break;
                                case 'delete':
                                  _showDeleteConfirmation(page);
                                  break;
                                case 'navigate':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: page.builder),
                                  );
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'navigate',
                                child: Row(
                                  children: [
                                    const Icon(Icons.open_in_new, size: 20),
                                    const SizedBox(width: 8),
                                    Text(t(LCrud.viewDetails, ref)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Row(
                                  children: [
                                    Icon(
                                        page.isActive
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Text(page.isActive
                                        ? t(LStatus.inactive, ref)
                                        : t(LCrud.active, ref)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit, size: 20),
                                    const SizedBox(width: 8),
                                    Text(t(L.edit, ref)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete,
                                        size: 20, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text(t(L.delete, ref),
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
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

  Widget _buildChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: fg)),
    );
  }

  void _togglePageStatus(PageRegistry page) {
    setState(() {
      AppPageRegistry.togglePageStatus(page.id);
    });
    _syncToSupabase(page, 'toggle');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${page.name} ${page.isActive ? t(LStatus.inactive, ref) : t(LCrud.active, ref)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddPageDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _AddPagePage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _showEditPageDialog(PageRegistry page) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _EditPagePage(existingPage: page),
        fullscreenDialog: true,
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _showDeleteConfirmation(PageRegistry page) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(L.delete, ref)),
        content: Text(t(LCrud.confirmDeleteItem, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(L.cancel, ref)),
          ),
          TextButton(
            onPressed: () {
              AppPageRegistry.removePage(page.id);
              _syncToSupabase(page, 'delete');
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${page.name} ${t(LCrud.deletedSuccessfully, ref)}')),
              );
            },
            child: Text(t(L.delete, ref), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AddPagePage extends ConsumerStatefulWidget {
  const _AddPagePage();

  @override
  ConsumerState<_AddPagePage> createState() => _AddPagePageState();
}

class _AddPagePageState extends ConsumerState<_AddPagePage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  String _selectedRole = 'all';
  String _selectedCategory = 'General';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _idCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(L.add, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t(L.cancel, ref)),
          ),
          TextButton(
            onPressed: () { debugPrint('[page_management_screen] Save button CLICKED'); _save(); },
            child: Text(t(L.save, ref)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _idCtrl,
              decoration: InputDecoration(
                  labelText: t(LColumn.name, ref),
                  hintText: 'e.g. new_feature'),
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration:
                  InputDecoration(labelText: t(LCrud.discountName, ref)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration:
                  InputDecoration(labelText: t(LCrud.description, ref)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
initialValue: _selectedRole,
              decoration: InputDecoration(labelText: t(LAuth.role, ref)),
              items: ['all', 'admin', 'teacher', 'student', 'staff']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRole = v ?? 'all'),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration:
                  InputDecoration(labelText: t(LCrud.category, ref)),
              onChanged: (v) => _selectedCategory = v,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _idCtrl.text.isEmpty) return;
    final newPage = PageRegistry(
      id: _idCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _selectedCategory,
      role: _selectedRole,
      icon: Icons.article,
      builder: (ctx) => Scaffold(
            appBar: AppBar(title: Text(_nameCtrl.text.trim())),
            body: Center(
              child:
                  Text('${_nameCtrl.text.trim()} - ${t(LCrud.placeholder, ref)}'),
            ),
          ),
    );
    AppPageRegistry.addPage(newPage);
    try {
      final client = Supabase.instance.client;
      await client.from('page_registry').upsert({
        'id': newPage.id,
        'name': newPage.name,
        'description': newPage.description,
        'category': newPage.category,
        'role': newPage.role,
        'is_active': newPage.isActive,
      });
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('${newPage.name} ${t(LCrud.createdSuccessfully, ref)}')),
      );
      Navigator.pop(context, true);
    }
  }
}

class _EditPagePage extends ConsumerStatefulWidget {
  final PageRegistry existingPage;

  const _EditPagePage({required this.existingPage});

  @override
  ConsumerState<_EditPagePage> createState() => _EditPagePageState();
}

class _EditPagePageState extends ConsumerState<_EditPagePage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _idCtrl;
  late String _selectedRole;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    final page = widget.existingPage;
    _nameCtrl = TextEditingController(text: page.name);
    _descCtrl = TextEditingController(text: page.description);
    _idCtrl = TextEditingController(text: page.id);
    _selectedRole = page.role;
    _selectedCategory = page.category;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _idCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(L.edit, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t(L.cancel, ref)),
          ),
          TextButton(
            onPressed: () { debugPrint('[page_management_screen] Save button CLICKED'); _save(); },
            child: Text(t(L.save, ref)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _idCtrl,
              decoration: InputDecoration(
                  labelText: t(LColumn.name, ref),
                  border: const OutlineInputBorder()),
              readOnly: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                  labelText: t(LCrud.discountName, ref),
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                  labelText: t(LCrud.description, ref),
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
initialValue: _selectedRole,
              decoration: InputDecoration(
                  labelText: t(LAuth.role, ref),
                  border: const OutlineInputBorder()),
              items: ['all', 'admin', 'teacher', 'student', 'staff']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedRole = v ?? 'all'),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                  labelText: t(LCrud.category, ref),
                  border: const OutlineInputBorder()),
              onChanged: (v) => _selectedCategory = v,
              controller: TextEditingController(text: _selectedCategory),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    try {
      await Supabase.instance.client.from('page_registry').upsert({
        'id': widget.existingPage.id,
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _selectedCategory,
        'role': _selectedRole,
      });
      final updatedPage = PageRegistry(
        id: widget.existingPage.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _selectedCategory,
        role: _selectedRole,
        icon: widget.existingPage.icon,
        builder: widget.existingPage.builder,
        isActive: widget.existingPage.isActive,
      );
      AppPageRegistry.removePage(widget.existingPage.id);
      AppPageRegistry.addPage(updatedPage);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${_nameCtrl.text.trim()} ${t(LCrud.updatedSuccessfully, ref)}')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${t(L.error, ref)}: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}
