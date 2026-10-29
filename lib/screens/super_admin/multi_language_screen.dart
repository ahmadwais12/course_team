import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class MultiLanguageScreen extends ConsumerStatefulWidget {
  const MultiLanguageScreen({super.key});

  @override
  ConsumerState<MultiLanguageScreen> createState() =>
      _MultiLanguageScreenState();
}

class _MultiLanguageScreenState extends ConsumerState<MultiLanguageScreen> {
  List<Map<String, dynamic>> _languages = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('languages')
          .select()
          .order('name');
      if (mounted) {
        setState(() {
          _languages = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredLanguages {
    if (_searchQuery.isEmpty) return _languages;
    final q = _searchQuery.toLowerCase();
    return _languages.where((l) {
      return (l['name']?.toString().toLowerCase().contains(q) ?? false) ||
          (l['code']?.toString().toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _showLanguageDialog(
      BuildContext context, {Map<String, dynamic>? language}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _LanguageFormPage(language: language),
        fullscreenDialog: true,
      ),
    );
    if (result == true) _loadLanguages();
  }

  Future<void> _deleteLanguage(Map<String, dynamic> language) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(LAll.all_delete_language, ref)),
        content: Text(
            'Delete "${language['name']}"? This may affect translations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t(L.delete, ref)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('languages')
            .delete()
            .eq('id', language['id']);
        _loadLanguages();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tt(LAll.all_delete_failed_x, ref, [e.toString()]))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () { if (context.canPop()) { context.pop(); } else { context.go(AppRoutes.superAdmin); } }), title: const Text('Multi-Language')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLanguageDialog(context),
        icon: const Icon(Icons.add),
        label: Text(t(LAll.all_add_language, ref)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                              decoration: InputDecoration(
                                hintText: 'Search languages...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_filteredLanguages.length} languages',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filteredLanguages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.language_rounded,
                                      size: 64,
                                      color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text(t(LAll.all_no_languages_found, ref),
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredLanguages.length,
                              itemBuilder: (context, index) {
                                final lang = _filteredLanguages[index];
                                return _LanguageCard(
                                  language: lang,
                                  onEdit: () =>
                                      _showLanguageDialog(context,
                                          language: lang),
                                  onDelete: () =>
                                      _deleteLanguage(lang),
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
}

class _LanguageCard extends ConsumerWidget {
  final Map<String, dynamic> language;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LanguageCard({
    required this.language,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = language['name']?.toString() ?? 'Unknown';
    final code = language['code']?.toString() ?? '';
    final nativeName = language['native_name']?.toString() ?? '';
    final isRtl = language['is_rtl'] == true;
    final isActive = language['is_active'] != false;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.withValues(alpha: 0.15),
          child: Text(
            code.toUpperCase(),
            style: const TextStyle(
                color: Colors.indigo,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
        ),
        title: Row(
          children: [
            Text(name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (nativeName.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(tt(LAll.all_s255, ref, [nativeName]),
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey[600])),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            if (isRtl)
              Container(
                margin: const EdgeInsets.only(top: 4, right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(t(LAll.all_rtl, ref),
                    style: const TextStyle(
                        fontSize: 9,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold)),
              ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 9,
                  color: isActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
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

class _LanguageFormPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? language;
  const _LanguageFormPage({this.language});

  @override
  ConsumerState<_LanguageFormPage> createState() => _LanguageFormPageState();
}

class _LanguageFormPageState extends ConsumerState<_LanguageFormPage> {
  late final TextEditingController _nameCtl;
  late final TextEditingController _codeCtl;
  late final TextEditingController _nativeNameCtl;
  late bool _isRtl;
  late bool _isActive;

  bool get _isEdit => widget.language != null;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.language?['name']?.toString() ?? '');
    _codeCtl = TextEditingController(text: widget.language?['code']?.toString() ?? '');
    _nativeNameCtl = TextEditingController(text: widget.language?['native_name']?.toString() ?? '');
    _isRtl = widget.language?['is_rtl'] == true;
    _isActive = widget.language?['is_active'] != false;
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _codeCtl.dispose();
    _nativeNameCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      if (_isEdit) {
        await Supabase.instance.client
            .from('languages')
            .update({
              'name': _nameCtl.text.trim(),
              'native_name': _nativeNameCtl.text.trim(),
              'is_rtl': _isRtl,
              'is_active': _isActive,
            })
            .eq('id', widget.language!['id']);
      } else {
        await Supabase.instance.client.from('languages').insert({
          'name': _nameCtl.text.trim(),
          'code': _codeCtl.text.trim(),
          'native_name': _nativeNameCtl.text.trim(),
          'is_rtl': _isRtl,
          'is_active': _isActive,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Language updated' : 'Language added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () { if (context.canPop()) { context.pop(); } else { context.go(AppRoutes.superAdmin); } }),
        title: Text(_isEdit ? 'Edit Language' : 'Add Language'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            onPressed: () { debugPrint('[multi_language_screen] Save button CLICKED'); _save(); },
            child: Text(_isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtl,
              decoration: const InputDecoration(labelText: 'Language Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeCtl,
              decoration: const InputDecoration(
                  labelText: 'Language Code (e.g. en, prs, ps)'),
              enabled: !_isEdit,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nativeNameCtl,
              decoration: const InputDecoration(labelText: 'Native Name'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t(LAll.all_rtl_script, ref)),
              subtitle: Text(t(LAll.all_righttoleft_text_direction, ref),
                  style: const TextStyle(fontSize: 12)),
              value: _isRtl,
              onChanged: (v) => setState(() => _isRtl = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t(LCrud.active, ref)),
              subtitle: Text(t(LAll.all_show_in_language_selector, ref),
                  style: const TextStyle(fontSize: 12)),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
        ),
      ),
    );
  }
}

