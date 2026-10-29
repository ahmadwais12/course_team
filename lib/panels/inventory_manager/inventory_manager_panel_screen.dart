import 'package:flutter/material.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/widgets/realtime_watcher.dart';
import 'package:course_emis/providers/panel_stats_provider.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/base_panel_layout.dart';
import 'package:course_emis/core/responsive/responsive.dart';
import 'package:course_emis/widgets/insight_ui.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class InventoryManagerPanelScreen extends ConsumerWidget {
  const InventoryManagerPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryStatsAsync = ref.watch(inventoryStatsProvider);
    final supabase = Supabase.instance.client;

    return BasePanelLayout(
      title: t(LPanel.inventoryManagerPanel, ref),
      children: [
        RealtimeDashboardWatcher(
          channelName: 'inventory-dashboard',
          tables: ['inventory_items', 'suppliers', 'purchase_orders', 'inventory_transactions'],
          onChange: () => ref.invalidate(inventoryStatsProvider),
        ),

        // Hero Card
        inventoryStatsAsync
            .when(
              data: (stats) {
                return InsightHeroCard(
                  eyebrow: 'INVENTORY & ASSETS',
                  title: 'Inventory Control Center',
                  subtitle:
                      'Monitor stock levels, track purchase orders, manage suppliers, and audit assets from a single operations console.',
                  accent: Colors.green,
                  chips: [
                    InsightStatChip(
                      label: 'Total Items',
                      value: stats.totalItems.toString(),
                    ),
                    InsightStatChip(
                      label: 'Low Stock',
                      value: stats.lowStockItems.toString(),
                    ),
                    InsightStatChip(
                      label: 'Open Orders',
                      value: stats.openOrders.toString(),
                    ),
                    InsightStatChip(
                      label: 'Suppliers',
                      value: stats.totalSuppliers.toString(),
                    ),
                  ],
                  actions: [
                    _GradientButton(
                      onPressed: () => context.go(AppRoutes.inventoryList),
                      icon: Icons.inventory_2_rounded,
                      label: 'Stock List',
                      gradient: AppGradients.skyCyanHorizontal,
                    ),
                    _GradientButton(
                      onPressed: () => context.go(AppRoutes.stockCheck),
                      icon: Icons.fact_check_rounded,
                      label: 'Stock Check',
                      gradient: AppGradients.blueHorizontal,
                      isOutlined: true,
                    ),
                  ],
                );
              },
              loading: () => const PageSkeleton(type: 'dashboard'),
              error: (_, __) => const SizedBox.shrink(),
            )
            .animate()
            .fadeIn(duration: 800.ms)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
        const SizedBox(height: 24),

        // Procurement Workflow
        InsightSectionTitle(
          title: 'Procurement Workflow',
          subtitle: 'From requisition to restock - complete inventory lifecycle',
        ),
        const SizedBox(height: 12),
        InsightProcessDiagram(
          title: '',
          subtitle: '',
          accent: Colors.green,
          steps: const [
            InsightFlowStep(
              title: 'Requisition',
              subtitle: 'Request items',
              icon: Icons.request_quote_rounded,
            ),
            InsightFlowStep(
              title: 'Order',
              subtitle: 'Create purchase order',
              icon: Icons.shopping_cart_rounded,
            ),
            InsightFlowStep(
              title: 'Receive',
              subtitle: 'Stock in deliveries',
              icon: Icons.inventory_rounded,
            ),
            InsightFlowStep(
              title: 'Audit',
              subtitle: 'Reconcile stock',
              icon: Icons.fact_check_rounded,
            ),
            InsightFlowStep(
              title: 'Restock',
              subtitle: 'Maintain levels',
              icon: Icons.restore_rounded,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Inventory Modules
        InsightSectionTitle(
          title: 'Inventory Modules',
          subtitle: 'Complete toolset for stock and asset management',
        ),
        const SizedBox(height: 12),
        _buildModulesGrid(context),
        const SizedBox(height: 24),

        // Analytics Row
        inventoryStatsAsync.when(
          data: (stats) {
            return ResponsiveMetricRow(
              children: [
                InsightMetricCard(
                  label: 'Stock Items',
                  value: stats.totalItems.toString(),
                  trend: 'Tracked SKUs',
                  icon: Icons.inventory_2_rounded,
                  accent: Colors.green,
                ),
                InsightMetricCard(
                  label: 'Low Stock Alerts',
                  value: stats.lowStockItems.toString(),
                  trend: 'Below minimum',
                  icon: Icons.warning_amber_rounded,
                  accent: Colors.orange,
                ),
                InsightMetricCard(
                  label: 'Open POs',
                  value: stats.openOrders.toString(),
                  trend: 'Awaiting delivery',
                  icon: Icons.pending_actions_rounded,
                  accent: Colors.blue,
                ),
                InsightMetricCard(
                  label: 'Purchase Orders',
                  value: stats.totalPurchaseOrders.toString(),
                  trend: 'All time',
                  icon: Icons.receipt_long_rounded,
                  accent: Colors.purple,
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
        const SizedBox(height: 24),

        // Stock Analytics
        InsightSectionTitle(
          title: 'Stock Analytics',
          subtitle: 'Inventory health and movement trends',
        ),
        const SizedBox(height: 12),
        ResponsiveBuilder(
          builder: (context, isMobile, isTablet, isDesktop) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final twoCol = constraints.maxWidth >= 900;
                final charts = <Widget>[
                  inventoryStatsAsync.when(
                    data: (stats) => InsightSegmentsCard(
                      title: 'Stock Health',
                      subtitle: 'Items by stock sufficiency',
                      segments: [
                        InsightSegment(
                          label: 'Healthy',
                          value: (stats.totalItems - stats.lowStockItems)
                              .toDouble(),
                          color: Colors.green,
                        ),
                        InsightSegment(
                          label: 'Low Stock',
                          value: stats.lowStockItems.toDouble(),
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    loading: () => const PageSkeleton(type: 'card'),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const InsightLineChartCard(
                    title: 'Weekly Stock Movement',
                    subtitle: 'Items received vs dispatched over the week',
                    accent: Colors.green,
                    points: [
                      InsightPoint('Mon', 34),
                      InsightPoint('Tue', 28),
                      InsightPoint('Wed', 41),
                      InsightPoint('Thu', 37),
                      InsightPoint('Fri', 45),
                      InsightPoint('Sat', 22),
                      InsightPoint('Sun', 16),
                    ],
                  ),
                ];
                if (twoCol) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: charts[0]),
                      const SizedBox(width: 16),
                      Expanded(child: charts[1]),
                    ],
                  );
                }
                return Column(
                  children: [
                    charts[0],
                    const SizedBox(height: 16),
                    charts[1],
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),

        // Coverage Matrix
        InsightSectionTitle(
          title: 'Inventory Coverage Matrix',
          subtitle: 'Complete overview of responsibilities',
        ),
        const SizedBox(height: 12),
        const InsightTableCard(
          title: '',
          subtitle: '',
          columns: ['Area', 'Responsibility', 'Primary Tool', 'Target'],
          rows: [
            [
              'Catalog',
              'Maintain item master',
              'Inventory List',
              'Departments'
            ],
            [
              'Procurement',
              'Create & manage POs',
              'Purchase Orders',
              'Suppliers'
            ],
            [
              'Suppliers',
              'Vendor management',
              'Suppliers',
              'Vendors'
            ],
            [
              'Audits',
              'Physical stock counts',
              'Stock Audit',
              'Warehouse'
            ],
            [
              'Assets',
              'Track equipment assets',
              'Asset Tracking',
              'Facilities'
            ],
          ],
        ),
        const SizedBox(height: 24),

        // Recent Activity
        FutureBuilder(
          future: Future.wait([
            supabase
                .from('inventory_transactions')
                .select('item_id, transaction_type, quantity, created_at')
                .order('created_at', ascending: false)
                .limit(2),
            supabase
                .from('purchase_orders')
                .select('id, supplier_id, status, created_at')
                .order('created_at', ascending: false)
                .limit(2),
          ]),
          builder: (context, AsyncSnapshot<List<Object?>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const PageSkeleton(type: 'list', itemCount: 4);
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final transactions = snapshot.data![0] as List;
            final orders = snapshot.data![1] as List;

            final List<List<String>> rows = [];

            for (var tx in transactions) {
              rows.add([
                'Stock ${tx['transaction_type']?.toString().toUpperCase() ?? ''}',
                tx['quantity']?.toString() ?? '0',
                tx['item_id']?.toString().substring(0, 8) ?? '-',
                _timeAgo(tx['created_at']),
                'Posted',
              ]);
            }

            for (var order in orders) {
              final status = order['status']?.toString() ?? 'Open';
              final supplier = order['supplier_id']?.toString().substring(0, 8) ?? '-';
              rows.add([
                'Purchase Order',
                supplier,
                order['id']?.toString().substring(0, 8) ?? '-',
                _timeAgo(order['created_at']),
                status,
              ]);
            }

            return Column(
              children: [
                InsightSectionTitle(
                  title: t(LDash.recentActivity, ref),
                  subtitle: 'Latest stock movements and purchase orders',
                  trailing: TextButton(
                    onPressed: () => context.go(AppRoutes.inventoryList),
                    child: Text(t(LDash.viewAll, ref)),
                  ),
                ),
                const SizedBox(height: 12),
                InsightTableCard(
                  title: '',
                  subtitle: '',
                  columns: const ['Item', 'Qty/Ref', 'ID', 'Time', 'Status'],
                  rows: rows.isEmpty
                      ? [
                          [t(L.noData, ref), '-', '-', '-', '-'],
                        ]
                      : rows,
                ),
              ],
            );
          },
        ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
      ],
    );
  }

  Widget _buildModulesGrid(BuildContext context) {
    final modules = [
      (
        'Inventory List',
        Icons.inventory_2_rounded,
        Colors.green,
        AppRoutes.inventoryList,
        'Item master & stock levels',
      ),
      (
        'Stock Check',
        Icons.fact_check_rounded,
        Colors.teal,
        AppRoutes.stockCheck,
        'Quick stock verification',
      ),
      (
        'Purchase Orders',
        Icons.receipt_long_rounded,
        Colors.blue,
        AppRoutes.purchaseOrders,
        'Create & track POs',
      ),
      (
        'Suppliers',
        Icons.local_shipping_rounded,
        Colors.indigo,
        AppRoutes.suppliers,
        'Vendor management',
      ),
      (
        'Asset Tracking',
        Icons.precision_manufacturing_rounded,
        Colors.orange,
        AppRoutes.assetTracking,
        'Track equipment assets',
      ),
      (
        'Requisitions',
        Icons.request_quote_rounded,
        Colors.purple,
        AppRoutes.requisitions,
        'Internal item requests',
      ),
      (
        'Stock Audit',
        Icons.ballot_rounded,
        Colors.pink,
        AppRoutes.stockAudit,
        'Reconciliation & counts',
      ),
      (
        'Categories',
        Icons.category_rounded,
        Colors.brown,
        AppRoutes.inventoryCategories,
        'Organize inventory groups',
      ),
    ];

    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 2 : 3,
            childAspectRatio: isMobile ? 1.2 : 1.1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final module = modules[index];
            return _buildModuleCard(
              context,
              module.$1,
              module.$2,
              module.$3,
              module.$4,
              module.$5,
            ).animate().fadeIn(delay: (index * 50).ms).scale(
                begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
          },
        );
      },
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
    String subtitle,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        color: Colors.grey[500],
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(dynamic date) {
    if (date == null) return 'Recently';
    try {
      final dt = DateTime.parse(date.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (e) {
      return 'Recently';
    }
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Gradient gradient;
  final bool isOutlined;

  const _GradientButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.gradient,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isOutlined) {
      return Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        padding: const EdgeInsets.all(2),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}
