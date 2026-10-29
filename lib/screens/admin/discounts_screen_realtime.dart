import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/providers/admin_providers.dart';
import 'package:course_emis/widgets/common_state_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiscountsScreenRealtime extends ConsumerStatefulWidget {
  const DiscountsScreenRealtime({super.key});

  @override
  ConsumerState<DiscountsScreenRealtime> createState() =>
      _DiscountsScreenRealtimeState();
}

class _DiscountsScreenRealtimeState
    extends ConsumerState<DiscountsScreenRealtime> {
  String searchQuery = '';
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    final discountsAsync = ref.watch(discountsStreamProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: t(LCrud.searchHintGeneric, ref),
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child: discountsAsync.when(
              data: (discounts) {
                var filtered = discounts.where((d) {
                  final name = d['name']?.toString().toLowerCase() ?? '';
                  final matchesSearch =
                      name.contains(searchQuery.toLowerCase());
                  final matchesCategory = selectedCategory == null ||
                      d['category'] == selectedCategory;
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.local_offer_outlined,
                    title: t(LCrud.noDiscountsFound, ref),
                    subtitle: t(LCrud.tryAdjustSearch, ref),
                    onRefresh: () => ref.invalidate(discountsStreamProvider),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final discount = filtered[index];
                    final percentage = discount['percentage'] ?? 0.0;

                    return Card(
                      child: InkWell(
                        onTap: () => _showDetails(discount),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.local_offer,
                                  color: Colors.orange[700],
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                discount['name']?.toString() ?? 'Untitled',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                discount['category']?.toString() ?? '',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${percentage.toStringAsFixed(0)}% OFF',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if ((discount['active'] ?? false))
                                    const Icon(Icons.check_circle,
                                        color: Colors.blue, size: 20),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  LoadingWidget(message: t(L.loading, ref)),
              error: (error, stack) => CustomErrorWidget(
                error: error,
                onRetry: () => ref.invalidate(discountsStreamProvider),
                customMessage: t(LGen.somethingWentWrong, ref),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDiscountDialog,
        icon: const Icon(Icons.add),
        label: Text(t(LCrud.addDiscount, ref)),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> discount) {
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
              Text(
                discount['name']?.toString() ?? 'Unknown',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDetailRow(t(LCrud.percentage, ref), '${discount['percentage']}%'),
              _buildDetailRow(
                  t(LCrud.category, ref), discount['category']?.toString() ?? 'N/A'),
              _buildDetailRow(
                  t(LCrud.description, ref), discount['description']?.toString() ?? 'N/A'),
              _buildDetailRow(
                  t(LCrud.value, ref), _formatDate(discount['valid_until'])),
              _buildDetailRow(t(LCrud.status, ref),
                  (discount['active'] ?? false) ? t(LCrud.active, ref) : t(LCrud.inactive, ref)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditDiscountDialog(discount);
                      },
                      icon: const Icon(Icons.edit),
                      label: Text(t(L.edit, ref)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteDiscountConfirmation(discount);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: Text(t(L.delete, ref),
                          style: TextStyle(color: Colors.red)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                      ),
                    ),
                  ),
                ],
              ),
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

  void _showCreateDiscountDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => const _CreateDiscountPage(), fullscreenDialog: true),
    );
    if (result == true) {
      ref.invalidate(discountsStreamProvider);
    }
  }

  void _showEditDiscountDialog(Map<String, dynamic> discount) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => _EditDiscountPage(discount: discount),
          fullscreenDialog: true),
    );
    if (result == true) {
      ref.invalidate(discountsStreamProvider);
    }
  }

  void _showDeleteDiscountConfirmation(Map<String, dynamic> discount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(LCrud.confirmDelete, ref)),
        content: Text(
            t(LCrud.confirmDeleteItem, ref)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t(L.cancel, ref))),
          FilledButton(
            onPressed: () async {
              try {
                final id = discount['id'];
                await Supabase.instance.client
                    .from('discounts')
                    .delete()
                    .eq('id', id);
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(discountsStreamProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(t(LCrud.discountDeleted, ref))),
                  );
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
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t(L.delete, ref)),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    DateTime dt;
    if (date is String) {
      dt = DateTime.parse(date);
    } else if (date is DateTime) {
      dt = date;
    } else {
      return 'N/A';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _CreateDiscountPage extends ConsumerStatefulWidget {
  const _CreateDiscountPage();

  @override
  ConsumerState<_CreateDiscountPage> createState() =>
      _CreateDiscountPageState();
}

class _CreateDiscountPageState extends ConsumerState<_CreateDiscountPage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _percentageCtrl = TextEditingController(text: '0');
  final _valueCtrl = TextEditingController(text: '0');
  String _category = 'General';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _percentageCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(LCrud.nameRequired, ref))),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.from('discounts').insert({
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'percentage': double.tryParse(_percentageCtrl.text.trim()) ?? 0.0,
        'value': double.tryParse(_valueCtrl.text.trim()) ?? 0.0,
        'category': _category,
        'active': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${_nameCtrl.text.trim()} ${t(LCrud.createdSuccessfully, ref)}')),
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
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LCrud.addDiscount, ref)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () { debugPrint('[discounts_screen_realtime] Save button CLICKED'); _save(); },
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
              controller: _nameCtrl,
              decoration: InputDecoration(
                  labelText: t(LCrud.discountName, ref),
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                  labelText: t(LCrud.description, ref),
                  border: const OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _percentageCtrl,
              decoration: InputDecoration(
                  labelText: t(LCrud.percentage, ref),
                  border: const OutlineInputBorder(),
                  suffixText: '%'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valueCtrl,
              decoration: InputDecoration(
                  labelText: t(LCrud.value, ref),
                  border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
initialValue: _category,
              decoration: InputDecoration(
                  labelText: t(LCrud.category, ref),
                  border: const OutlineInputBorder()),
              items: ['General', 'Merit', 'Need-based', 'Special']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? 'General'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditDiscountPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> discount;

  const _EditDiscountPage({required this.discount});

  @override
  ConsumerState<_EditDiscountPage> createState() => _EditDiscountPageState();
}

class _EditDiscountPageState extends ConsumerState<_EditDiscountPage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _percentageCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  String _category = 'General';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.discount['name']?.toString() ?? '';
    _descCtrl.text = widget.discount['description']?.toString() ?? '';
    _percentageCtrl.text = '${widget.discount['percentage'] ?? 0}';
    _valueCtrl.text = '${widget.discount['value'] ?? 0}';
    _category = widget.discount['category']?.toString() ?? 'General';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _percentageCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(LCrud.nameRequired, ref))),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.from('discounts').update({
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'percentage': double.tryParse(_percentageCtrl.text.trim()) ?? 0.0,
        'value': double.tryParse(_valueCtrl.text.trim()) ?? 0.0,
        'category': _category,
      }).eq('id', widget.discount['id']);
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
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LCrud.editDiscount, ref)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () { debugPrint('[discounts_screen_realtime] Save button CLICKED'); _save(); },
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(t(L.save, ref)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                  labelText: t(LCrud.discountName, ref),
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                  labelText: t(LCrud.description, ref),
                  border: const OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _percentageCtrl,
              decoration: InputDecoration(
                  labelText: t(LCrud.percentage, ref),
                  border: const OutlineInputBorder(),
                  suffixText: '%'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valueCtrl,
              decoration: InputDecoration(
                  labelText: t(LCrud.value, ref),
                  border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
initialValue: _category,
              decoration: InputDecoration(
                  labelText: t(LCrud.category, ref),
                  border: const OutlineInputBorder()),
              items: ['General', 'Merit', 'Need-based', 'Special']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? 'General'),
            ),
          ],
        ),
      ),
    );
  }
}


