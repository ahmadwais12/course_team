import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class DigitalLibraryScreen extends ConsumerStatefulWidget {
  const DigitalLibraryScreen({super.key});

  @override
  ConsumerState<DigitalLibraryScreen> createState() => _DigitalLibraryScreenState();
}

class _DigitalLibraryScreenState extends ConsumerState<DigitalLibraryScreen> {
  List<Map<String, dynamic>> _resources = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    try {
      final data = await Supabase.instance.client
          .from('library')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _resources = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load resources: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()), title: const Text('Digital Library')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: t(LCrud.searchHintGeneric, ref),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                Expanded(
                  child: _resources.isEmpty
                      ? Center(child: Text(t(LCrud.noItemsFound, ref)))
                      : GridView.count(
                          crossAxisCount: 2,
                          padding: const EdgeInsets.all(16),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          children: _resources.map((resource) {
                            return Card(
                              elevation: 3,
                              child: InkWell(
                                onTap: () => _showDetails(resource),
                                borderRadius:
                                    BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                          _getTypeIcon(
                                              resource['type']),
                                          size: 40,
                                          color: Theme.of(context)
                                              .primaryColor),
                                      const SizedBox(height: 12),
                                      Text(
                                        resource['title'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                        maxLines: 2,
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(resource['type'] ?? '',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  Colors.grey[600])),
                                      const Spacer(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                        children: [
                                          Text(
                                              '${resource['download_count'] ?? resource['downloads'] ?? 0} downloads',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors
                                                      .grey[600])),
                                          Icon(Icons.download,
                                              size: 16,
                                              color:
                                                  Colors.grey[600]),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
    );
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'Video Course':
        return Icons.video_library;
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'Interactive':
        return Icons.touch_app;
      case 'Audio':
        return Icons.headphones;
      default:
        return Icons.folder;
    }
  }

  void _showDetails(Map<String, dynamic> resource) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(resource['title'] ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildDetailRow('Type', resource['type'] ?? ''),
              _buildDetailRow(
                  'Size', resource['file_size']?.toString() ?? resource['size'] ?? 'N/A'),
              _buildDetailRow('Downloads',
                  '${resource['download_count'] ?? resource['downloads'] ?? 0}'),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

