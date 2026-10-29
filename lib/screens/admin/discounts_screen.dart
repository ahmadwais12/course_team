import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/models/discount.dart';
import 'package:course_emis/providers/discount_provider.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class DiscountsScreen extends ConsumerStatefulWidget {
  const DiscountsScreen({super.key});

  @override
  ConsumerState<DiscountsScreen> createState() => _DiscountsScreenState();
}

class _DiscountsScreenState extends ConsumerState<DiscountsScreen> {
  String searchQuery = '';
  DiscountType? selectedType;

  @override
  Widget build(BuildContext context) {
    final discountsAsync = ref.watch(discountsNotifierProvider);

    return discountsAsync.when(
      data: (discounts) {
        final filtered = discounts.where((d) {
          final matchesSearch =
              d.type.name.toLowerCase().contains(searchQuery.toLowerCase());
          final matchesType = selectedType == null || d.type == selectedType;
          return matchesSearch && matchesType;
        }).toList();

        return _buildContent(filtered);
      },
      loading: () => const PageSkeleton(type: 'list'),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(t(L.error, ref),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(error.toString(), style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(discountsNotifierProvider),
              icon: const Icon(Icons.refresh),
              label: Text(t(L.retry, ref)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Discount> discounts) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: t(LCrud.searchHintGeneric, ref),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(t(LFilter.all, ref)),
                      selected: selectedType == null,
                      onSelected: (selected) =>
                          setState(() => selectedType = null),
                    ),
                    ...DiscountType.values.map((type) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChip(
                            label: Text(_formatType(type)),
                            selected: selectedType == type,
                            onSelected: (selected) => setState(
                                () => selectedType = selected ? type : null),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: discounts.length,
            itemBuilder: (context, index) {
              final discount = discounts[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: InkWell(
                  onTap: () => _showDetails(discount),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: discount.isActive
                                ? Colors.blue[100]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${discount.percentage.toInt()}%',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: discount.isActive
                                    ? Colors.blue[800]
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getTypeColor(discount.type)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _formatType(discount.type),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _getTypeColor(discount.type),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!discount.isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        t(LCrud.inactive, ref),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                discount.conditions ??
                                    'No conditions specified',
                                style: TextStyle(color: Colors.grey[600]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (discount.validUntil != null)
                                Text(
                                  'Valid until: ${_formatDate(discount.validUntil!)}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[500]),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showOptions(discount),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        FloatingActionButton.extended(
          onPressed: () => _showAddEditDialog(null),
          icon: const Icon(Icons.add),
          label: Text(t(LCrud.addDiscount, ref)),
        ),
      ],
    );
  }

  Color _getTypeColor(DiscountType type) {
    switch (type) {
      case DiscountType.excellence:
        return Colors.purple;
      case DiscountType.family:
        return Colors.blue;
      case DiscountType.staff:
        return Colors.teal;
      case DiscountType.promotional:
        return Colors.orange;
      case DiscountType.special:
        return Colors.pink;
      case DiscountType.percentage:
        return Colors.indigo;
      case DiscountType.fixed:
        return Colors.brown;
    }
  }

  String _formatType(DiscountType type) {
    return type.name.substring(0, 1).toUpperCase() + type.name.substring(1);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDetails(Discount discount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_formatType(discount.type)} Discount',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDetailRow(t(LCrud.percentage, ref), '${discount.percentage}%'),
              _buildDetailRow(t(LCrud.conditions, ref), discount.conditions ?? t(LCrud.placeholder, ref)),
              _buildDetailRow(
                  t(LCrud.value, ref),
                  discount.validUntil != null
                      ? _formatDate(discount.validUntil!)
                      : t(L.noData, ref)),
              _buildDetailRow(
                  t(LCrud.status, ref), discount.isActive ? t(LCrud.active, ref) : t(LCrud.inactive, ref)),
              _buildDetailRow(t(LStatus.created, ref), _formatDate(discount.createdAt)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddEditDialog(discount);
                },
                icon: const Icon(Icons.edit),
                label: Text(t(LCrud.editDiscount, ref)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showOptions(Discount discount) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(t(L.edit, ref)),
              onTap: () {
                Navigator.pop(context);
                _showAddEditDialog(discount);
              },
            ),
            ListTile(
              leading: Icon(
                discount.isActive ? Icons.visibility_off : Icons.visibility,
                color: Colors.orange,
              ),
              title: Text(discount.isActive ? t(LStatus.inactive, ref) : t(LCrud.active, ref)),
              onTap: () {
                Navigator.pop(context);
                _toggleActive(discount);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(t(L.delete, ref), style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(discount.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleActive(Discount discount) async {
    try {
      final updated = discount.copyWith(isActive: !discount.isActive);
      await ref.read(discountsNotifierProvider.notifier).updateDiscount(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updated.isActive
                ? t(LCrud.active, ref)
                : t(LCrud.inactive, ref)),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t(L.error, ref)}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddEditDialog(Discount? discount) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AddDiscountPage(existingDiscount: discount),
        fullscreenDialog: true,
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t(LCrud.confirmDelete, ref)),
        content: Text(t(LCrud.confirmDeleteItem, ref)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t(L.cancel, ref))),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(discountsNotifierProvider.notifier)
                    .deleteDiscount(id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(t(LCrud.discountDeleted, ref)),
                        backgroundColor: Colors.blue),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t(L.delete, ref)),
          ),
        ],
      ),
    );
  }
}

class _AddDiscountPage extends ConsumerStatefulWidget {
  final Discount? existingDiscount;

  const _AddDiscountPage({this.existingDiscount});

  @override
  ConsumerState<_AddDiscountPage> createState() => _AddDiscountPageState();
}

class _AddDiscountPageState extends ConsumerState<_AddDiscountPage> {
  late final TextEditingController _percentageController;
  late final TextEditingController _conditionsController;
  late DiscountType _selectedDiscountType;

  @override
  void initState() {
    super.initState();
    final discount = widget.existingDiscount;
    _percentageController =
        TextEditingController(text: discount?.percentage.toString() ?? '');
    _conditionsController =
        TextEditingController(text: discount?.conditions ?? '');
    _selectedDiscountType = discount?.type ?? DiscountType.excellence;
  }

  @override
  void dispose() {
    _percentageController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  String _formatType(DiscountType type) {
    return type.name.substring(0, 1).toUpperCase() + type.name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final discount = widget.existingDiscount;
    return Scaffold(
      appBar: AppBar(
        title: Text(discount == null
            ? t(LCrud.addDiscount, ref)
            : t(LCrud.editDiscount, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t(L.cancel, ref)),
          ),
          TextButton(
            onPressed: () { debugPrint('[discounts_screen] Save button CLICKED'); _save(); },
            child: Text(t(L.save, ref)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<DiscountType>(
initialValue: _selectedDiscountType,
              decoration: InputDecoration(labelText: t(LCrud.category, ref)),
              items: DiscountType.values.map((type) {
                return DropdownMenuItem(
                    value: type, child: Text(_formatType(type)));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedDiscountType = value!);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: t(LCrud.percentage, ref)),
              controller: _percentageController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: t(LCrud.conditions, ref)),
              controller: _conditionsController,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final percentage =
        double.tryParse(_percentageController.text.trim()) ?? 0;
    final conditions = _conditionsController.text.trim();
    final type = _selectedDiscountType;
    if (percentage <= 0) return;

    try {
      final now = DateTime.now();
      final discount = widget.existingDiscount;
      if (discount == null) {
        final newDiscount = Discount(
          id: now.millisecondsSinceEpoch.toString(),
          type: type,
          percentage: percentage,
          conditions: conditions.isNotEmpty ? conditions : null,
          isActive: true,
          createdAt: now,
        );
        await ref
            .read(discountsNotifierProvider.notifier)
            .addDiscount(newDiscount);
      } else {
        final updated = discount.copyWith(
          type: type,
          percentage: percentage,
          conditions: conditions.isNotEmpty ? conditions : null,
        );
        await ref
            .read(discountsNotifierProvider.notifier)
            .updateDiscount(updated);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(t(LCrud.discountSaved, ref)),
              backgroundColor: Colors.blue),
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
