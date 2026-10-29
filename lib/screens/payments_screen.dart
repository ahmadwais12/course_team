import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/models/payment.dart';
import 'package:course_emis/providers/payment_provider.dart';
import 'package:course_emis/widgets/insight_ui.dart';
import 'package:course_emis/widgets/motion.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(LNav.payments, ref)),
        actions: [
          IconButton(
            onPressed: () => context.go('/ads'),
            icon: const Icon(Icons.campaign_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPaymentDialog(context, ref),
        icon: const Icon(Icons.payment_rounded),
        label: Text(t(LCrud.recordPayment, ref)),
      ),
      body: InsightBackground(
        maxWidth: 1200,
        child: paymentsAsync.when(
          data: (payments) {
            final totalAmount = payments.fold<double>(
                0, (sum, payment) => sum + payment.amount);
            final paidAmount = payments
                .where((payment) => payment.status == PaymentStatus.paid)
                .fold<double>(0, (sum, payment) => sum + payment.amount);
            final overdueAmount = payments
                .where((payment) => payment.status == PaymentStatus.overdue)
                .fold<double>(0, (sum, payment) => sum + payment.amount);

            return SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  InsightHeroCard(
                    eyebrow: t(LPay2.paymentManagement, ref),
                    title: t(LNav.payments, ref),
                    subtitle: t(LPay2.paymentManagement, ref),
                    accent: const Color(0xFF16A34A),
                    chips: [
                      InsightStatChip(label: t(LDash2.collectionRate, ref), value: '91%'),
                      InsightStatChip(label: t(LPay2.monthLabel, ref), value: '38'),
                      InsightStatChip(label: t(LCrud.status, ref), value: 'Low'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: 240,
                        child: InsightMetricCard(
                          label: t(LDash2.totalRevenue, ref),
                          value: 'PKR ${totalAmount.toStringAsFixed(0)}',
                          trend: '+9%',
                          icon: Icons.account_balance_wallet_outlined,
                          accent: Colors.blue,
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: InsightMetricCard(
                          label: t(LPanelUI.collected, ref),
                          value: 'PKR ${paidAmount.toStringAsFixed(0)}',
                          trend: '+14%',
                          icon: Icons.check_circle_outline_rounded,
                          accent: Colors.blue,
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: InsightMetricCard(
                            label: t(LPayment.status, ref),
                          value: 'PKR ${overdueAmount.toStringAsFixed(0)}',
                          trend: overdueAmount > 0 ? 'Watch' : 'Clear',
                          icon: Icons.warning_amber_rounded,
                          accent: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 840;
                      final trendCard = InsightLineChartCard(
                        title: t(LPayment.paymentHistory, ref),
                        subtitle: t(LPayment.paymentHistory, ref),
                        points: _buildPoints(payments),
                        accent: Colors.blue,
                      );
                      final breakdownCard = InsightSegmentsCard(
                        title: t(LColumn.status, ref),
                        subtitle: t(LPayment.paymentDetails, ref),
                        segments: [
                          InsightSegment(
                            label: t(LPayment.paid, ref),
                            value:
                                _count(payments, PaymentStatus.paid).toDouble(),
                            color: Colors.blue,
                          ),
                          InsightSegment(
                            label: t(LPayment.cPending, ref),
                            value: _count(payments, PaymentStatus.pending)
                                .toDouble(),
                            color: Colors.blue,
                          ),
                          InsightSegment(
                          label: t(LPayment.status, ref),
                            value: _count(payments, PaymentStatus.overdue)
                                .toDouble(),
                            color: Colors.orange,
                          ),
                        ],
                      );

                      if (narrow) {
                        return Column(
                          children: [
                            trendCard,
                            const SizedBox(height: 16),
                            breakdownCard,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: trendCard),
                          const SizedBox(width: 16),
                          Expanded(child: breakdownCard),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  InsightProcessDiagram(
                    title: t(LPayment.paymentHistory, ref),
                    subtitle: t(LPayment.paymentDetails, ref),
                    accent: Color(0xFF16A34A),
                    steps: [
                      InsightFlowStep(
                        title: 'Invoice',
                        subtitle: 'Issue or schedule the expected payment.',
                        icon: Icons.receipt_long_outlined,
                      ),
                      InsightFlowStep(
                        title: 'Reminder',
                        subtitle: 'Notify for due or overdue installments.',
                        icon: Icons.notifications_active_outlined,
                      ),
                      InsightFlowStep(
                        title: 'Collect',
                        subtitle: 'Record cash or installment receipts.',
                        icon: Icons.payments_outlined,
                      ),
                      InsightFlowStep(
                        title: 'Reconcile',
                        subtitle: 'Close the ledger and flag exceptions.',
                        icon: Icons.fact_check_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InsightTableCard(
                    title: t(LPayment.paymentHistory, ref),
                    subtitle: t(LPayment.paymentDetails, ref),
                    columns: [t(LAuth.cStudent, ref), t(LPayment.amount, ref), t(LCrud.category, ref), t(LColumn.status, ref)],
                    rows: payments.isEmpty
                        ? const [
                            ['No payments', '-', '-', '-'],
                          ]
                        : payments.take(4).map((payment) {
                            return [
                              payment.studentId,
                              'PKR ${payment.amount.toStringAsFixed(0)}',
                              payment.method.name,
                              payment.status.name.toUpperCase(),
                            ];
                          }).toList(),
                  ),
                  const SizedBox(height: 16),
                  ...payments.map(
                    (payment) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AnimatedListItem(
                        index: payments.indexOf(payment),
                        child: Consumer(
                          builder: (context, ref, _) => _PaymentCard(
                            payment: payment,
                            onEdit: () => _showPaymentDialog(context, ref, payment: payment),
                            onDelete: () => _confirmDelete(context, ref, payment),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InsightPromoBanner(
                    title: t(LAds.campaigns, ref),
                    subtitle: t(LAds.campaignManager, ref),
                    ctaLabel: t(LNav.payments, ref),
                    accent: const Color(0xFFDB2777),
                    icon: Icons.campaign_rounded,
                    onTap: () => context.go('/ads'),
                  ),
                ],
              ),
            );
          },
          loading: () => const ListSkeleton(itemCount: 6),
          error: (err, stack) => Center(child: Text('${t(LGen.errorDetails, ref)}: $err')),
        ),
      ),
    );
  }

  int _count(List<Payment> payments, PaymentStatus status) {
    final count = payments.where((payment) => payment.status == status).length;
    return count == 0 ? 1 : count;
  }

  List<InsightPoint> _buildPoints(List<Payment> payments) {
    final base = payments.isEmpty ? 6 : payments.length.toDouble();
    return [
      InsightPoint('Mon', base + 2),
      InsightPoint('Tue', base + 5),
      InsightPoint('Wed', base + 4),
      InsightPoint('Thu', base + 7),
      InsightPoint('Fri', base + 10),
      InsightPoint('Sat', base + 8),
    ];
  }

  Future<void> _showPaymentDialog(BuildContext context, WidgetRef ref, {Payment? payment}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _PaymentFormPage(payment: payment),
        fullscreenDialog: true,
      ),
    );
    if (result == true) ref.invalidate(paymentsNotifierProvider);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Payment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Text('Are you sure you want to delete this payment of PKR ${payment.amount.toStringAsFixed(0)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(paymentsActionsProvider).deletePayment(payment.id);
    }
  }
}

class _PaymentFormPage extends ConsumerStatefulWidget {
  final Payment? payment;
  const _PaymentFormPage({this.payment});

  @override
  ConsumerState<_PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends ConsumerState<_PaymentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtl;
  late PaymentMethod _method;

  bool get _isEditing => widget.payment != null;

  @override
  void initState() {
    super.initState();
    _amountCtl = TextEditingController(text: widget.payment?.amount.toStringAsFixed(0) ?? '');
    _method = widget.payment?.method ?? PaymentMethod.cash;
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Payment' : t(LCrud.recordPayment, ref)),
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
            TextFormField(
              controller: _amountCtl,
              decoration: InputDecoration(
                labelText: t(LPayment.amount, ref),
                prefixText: 'PKR ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value == null || value.isEmpty ? t(L.required, ref) : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentMethod>(
initialValue: _method,
              items: PaymentMethod.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _method = value);
              },
              decoration: InputDecoration(labelText: t(LPayment.paymentMethod, ref)),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () { debugPrint('[payments_screen] Save button CLICKED'); _save(); },
              child: Text(_isEditing ? 'Update' : t(LCrud.recordPayment, ref)),
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
    if (_isEditing) {
      final updated = widget.payment!.copyWith(
        amount: double.parse(_amountCtl.text),
        method: _method,
      );
      ref.read(paymentsActionsProvider).updatePayment(updated);
    } else {
      final newPayment = Payment(
        id: 'payment_${now.millisecondsSinceEpoch}',
        studentId: 'student_default',
        amount: double.parse(_amountCtl.text),
        method: _method,
        status: PaymentStatus.paid,
        paidDate: now,
        createdAt: now,
      );
      ref.read(paymentsActionsProvider).addPayment(newPayment);
    }
    Navigator.pop(context, true);
  }
}

class _PaymentCard extends StatelessWidget {
  final Payment payment;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PaymentCard({required this.payment, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: payment.status == PaymentStatus.paid
                      ? Colors.blue.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  child: Icon(
                    payment.status == PaymentStatus.paid
                        ? Icons.check
                        : Icons.pending,
                    color: payment.status == PaymentStatus.paid
                        ? Colors.blue
                        : Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PKR ${payment.amount.toStringAsFixed(0)}',
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        '${payment.method.name} - ${payment.status.name}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (payment.paidDate != null)
                  Text(
                    '${payment.paidDate!.day}/${payment.paidDate!.month}/${payment.paidDate!.year}',
                    style: theme.textTheme.labelSmall,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
