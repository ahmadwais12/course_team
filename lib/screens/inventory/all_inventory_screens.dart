import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class InventoryListScreen extends StatelessWidget {
  const InventoryListScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Inventory List',
        tableName: 'inventory_items',
        icon: Icons.list_alt_rounded,
        accentColor: Colors.blue,
        displayFields: ['name', 'sku', 'quantity', 'condition', 'location'],
      );
}

class StockCheckScreen extends StatelessWidget {
  const StockCheckScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Stock Check',
        tableName: 'inventory',
        icon: Icons.inventory_rounded,
        accentColor: Colors.blue,
        displayFields: ['name', 'quantity', 'category', 'status', 'location'],
      );
}

class PurchaseOrdersScreen extends StatelessWidget {
  const PurchaseOrdersScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Purchase Orders',
        tableName: 'purchase_orders',
        icon: Icons.add_shopping_cart_rounded,
        accentColor: Colors.orange,
        displayFields: ['po_number', 'status', 'total_amount', 'order_date'],
      );
}

class SupplierHubScreen extends StatelessWidget {
  const SupplierHubScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Supplier Hub',
        tableName: 'suppliers',
        icon: Icons.business_center_rounded,
        accentColor: Colors.purple,
        displayFields: ['name', 'contact_person', 'phone', 'email', 'is_active'],
      );
}

class AssetTrackingScreen extends StatelessWidget {
  const AssetTrackingScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Asset Tracking',
        tableName: 'asset_assignments',
        icon: Icons.qr_code_scanner_rounded,
        accentColor: Colors.teal,
        displayFields: ['asset_id', 'assigned_to', 'assigned_date', 'expected_return_date'],
      );
}

class RequisitionsScreen extends StatelessWidget {
  const RequisitionsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Requisitions',
        tableName: 'inventory_transactions',
        icon: Icons.request_quote_rounded,
        accentColor: Colors.red,
        displayFields: ['transaction_type', 'quantity', 'notes', 'created_at'],
      );
}

class StockAuditScreen extends StatelessWidget {
  const StockAuditScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Stock Audit',
        tableName: 'inventory_transactions',
        icon: Icons.fact_check_rounded,
        accentColor: Colors.pink,
        displayFields: ['transaction_type', 'quantity', 'notes', 'created_at'],
      );
}

class InventoryCategoriesScreen extends StatelessWidget {
  const InventoryCategoriesScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Inventory Categories',
        tableName: 'inventory',
        icon: Icons.category_rounded,
        accentColor: Colors.indigo,
        displayFields: ['category', 'name', 'quantity', 'status'],
      );
}
