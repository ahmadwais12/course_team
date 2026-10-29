import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/theme.dart';
import 'package:go_router/go_router.dart';

class FeeManagementScreen extends ConsumerStatefulWidget {
  const FeeManagementScreen({super.key});

  @override
  ConsumerState<FeeManagementScreen> createState() => _FeeManagementScreenState();
}

class _FeeManagementScreenState extends ConsumerState<FeeManagementScreen> {
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      final data = await Supabase.instance.client
          .from('payments')
          .select()
          .order('created_at', ascending: false);
      if (mounted) setState(() => _payments = List<Map<String, dynamic>>.from(data));
    } catch (_) {
      if (mounted) setState(() => _payments = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final collected = _payments
        .where((p) => (p['status']?.toString() ?? '').toLowerCase() == 'paid')
        .fold<double>(0, (s, p) => s + ((p['amount'] ?? 0) as num).toDouble());
    final pending = _payments
        .where((p) => (p['status']?.toString() ?? '').toLowerCase() == 'pending')
        .fold<double>(0, (s, p) => s + ((p['amount'] ?? 0) as num).toDouble());

    return Scaffold(
      appBar: AppBar(
        title: Text(t(LTitle.feeManagement, ref)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadPayments,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.go('/payments'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: RefreshIndicator(
                  onRefresh: _loadPayments,
                  child: ListView(
                    padding: AppSpacing.paddingLg,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Collected',
                              'PKR ${_formatAmount(collected)}',
                              Icons.check_circle_rounded,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Pending',
                              'PKR ${_formatAmount(pending)}',
                              Icons.pending_actions_rounded,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        t(LTitle.feeManagement, ref),
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                padding: AppSpacing.paddingSm,
                                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
                                child: const Icon(Icons.school_rounded, color: Colors.blue),
                              ),
                              title: Text(t(LFee.tuition, ref)),
                              subtitle: Text('${t(LFee.monthly, ref)}/${t(LFee.quarterly, ref)}/${t(LFee.yearly, ref)}'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => context.go('/payments'),
                            ),
                            const Divider(),
                            ListTile(
                              leading: Container(
                                padding: AppSpacing.paddingSm,
                                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
                                child: const Icon(Icons.local_library_rounded, color: Colors.blue),
                              ),
                              title: Text(t(LFee.library, ref)),
                              subtitle: Text(t(LFee.annual, ref)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => context.go('/payments'),
                            ),
                            const Divider(),
                            ListTile(
                              leading: Container(
                                padding: AppSpacing.paddingSm,
                                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
                                child: const Icon(Icons.sports_soccer_rounded, color: Colors.orange),
                              ),
                              title: Text(t(LFee.sports, ref)),
                              subtitle: Text(t(LFee.extracurricular, ref)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => context.go('/payments'),
                            ),
                            const Divider(),
                            ListTile(
                              leading: Container(
                                padding: AppSpacing.paddingSm,
                                decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
                                child: const Icon(Icons.computer_rounded, color: Colors.purple),
                              ),
                              title: Text(t(LFee.lab, ref)),
                              subtitle: const Text('Computer & Science labs'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => context.go('/payments'),
                            ),
                            const Divider(),
                            ListTile(
                              leading: Container(
                                padding: AppSpacing.paddingSm,
                                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
                                child: const Icon(Icons.bus_alert_rounded, color: Colors.red),
                              ),
                              title: Text(t(LFee.transport, ref)),
                              subtitle: Text('Bus service (${t(LFee.optional, ref)})'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => context.go('/payments'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        t(LPayment.paymentHistory, ref),
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_payments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text('No transactions yet.', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                          ),
                        )
                      else
                        ..._payments.take(15).map((p) {
                          final status = (p['status']?.toString() ?? '').toLowerCase();
                          final isPaid = status == 'paid';
                          final amount = ((p['amount'] ?? 0) as num).toDouble();
                          final date = (p['created_at']?.toString() ?? '').length >= 10
                              ? (p['created_at']?.toString() ?? '').substring(0, 10)
                              : '';
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isPaid ? Colors.blue.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                child: Icon(
                                  isPaid ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  color: isPaid ? Colors.blue : Colors.orange,
                                ),
                              ),
                              title: Text(p['student_name']?.toString() ?? 'Student'),
                              subtitle: Text(
                                '${isPaid ? 'Payment received' : 'Fee pending'} • $date',
                              ),
                              trailing: Text(
                                isPaid ? '+PKR ${_formatAmount(amount)}' : '-PKR ${_formatAmount(amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isPaid ? Colors.blue : Colors.orange,
                                ),
                              ),
                              onTap: () => context.go('/payments'),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
