import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/models/discount.dart';
import 'package:course_emis/providers/discount_provider.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class DiscountsScreen extends ConsumerWidget {
  const DiscountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discountsAsync = ref.watch(discountsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t(LNav.discounts, ref))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.local_offer_rounded),
        label: Text(t(LCrud.addDiscount, ref)),
      ),
      body: Padding(
        padding: AppSpacing.paddingLg,
        child: discountsAsync.when(
          data: (discounts) => discounts.isEmpty
              ? Center(
                  child: Text('No discounts found',
                      style: Theme.of(context).textTheme.bodyLarge))
              : ListView.separated(
                  itemCount: discounts.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) =>
                      _DiscountCard(discount: discounts[index]),
                ),
          loading: () => const ListSkeleton(itemCount: 5),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _AddDiscountPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) ref.invalidate(discountsNotifierProvider);
  }
}

class _AddDiscountPage extends ConsumerStatefulWidget {
  const _AddDiscountPage();

  @override
  ConsumerState<_AddDiscountPage> createState() => _AddDiscountPageState();
}

class _AddDiscountPageState extends ConsumerState<_AddDiscountPage> {
  final _formKey = GlobalKey<FormState>();
  final _percentCtl = TextEditingController(text: '20');
  DiscountType _type = DiscountType.excellence;

  @override
  void dispose() {
    _percentCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LCrud.addDiscount, ref)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t(L.cancel, ref))),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<DiscountType>(
              initialValue: _type,
              items: DiscountType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
              decoration: InputDecoration(labelText: t(LCrud.category, ref)),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _percentCtl,
              decoration: InputDecoration(
                  labelText: t(LCrud.percentage, ref), suffixText: '%'),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () { debugPrint('[discounts_screen] Save button CLICKED'); _save(); },
              child: Text(t(L.add, ref)),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final ref = this.ref;
    final now = DateTime.now();
    final discount = Discount(
      id: 'discount_${now.millisecondsSinceEpoch}',
      type: _type,
      percentage: double.parse(_percentCtl.text),
      isActive: true,
      createdAt: now,
    );
    ref.read(discountsNotifierProvider.notifier).addDiscount(discount);
    Navigator.pop(context, true);
  }
}

class _DiscountCard extends StatelessWidget {
  final Discount discount;
  const _DiscountCard({required this.discount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange.withValues(alpha: 0.2),
            child: Text('${discount.percentage.toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(discount.type.name, style: theme.textTheme.titleLarge),
                Text('${discount.percentage}% discount',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Chip(label: Text(discount.isActive ? 'Active' : 'Inactive')),
        ],
      ),
    );
  }
}
