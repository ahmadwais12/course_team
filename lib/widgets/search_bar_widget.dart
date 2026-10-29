import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import '../services/search_service.dart';

class GlobalSearchBar extends ConsumerStatefulWidget {
  const GlobalSearchBar({super.key});

  @override
  ConsumerState<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends ConsumerState<GlobalSearchBar> {
  final _controller = TextEditingController();
  Map<String, List<Map<String, dynamic>>> _results = {};
  bool _isLoading = false;

  void _search(String query) async {
    if (query.isEmpty) {
      setState(() => _results = {});
      return;
    }

    setState(() => _isLoading = true);
    final results = await SearchService.globalSearch(query);
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: t(LCrud.searchHintGeneric, ref),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: _search,
        ),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                if (_results['students']?.isNotEmpty ?? false) ...[
                  _buildSection('Students', _results['students']!, Icons.person),
                ],
                if (_results['teachers']?.isNotEmpty ?? false) ...[
                  _buildSection('Teachers', _results['teachers']!, Icons.school),
                ],
                if (_results['courses']?.isNotEmpty ?? false) ...[
                  _buildSection('Courses', _results['courses']!, Icons.book),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ...items.map((item) => ListTile(
              leading: Icon(icon),
              title: Text(item['name'] ?? ''),
              subtitle: Text(item['email'] ?? item['description'] ?? ''),
              onTap: () {
                // Navigate to detail page
              },
            )),
        const Divider(),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
