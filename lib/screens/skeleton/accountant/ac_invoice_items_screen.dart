import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class AcInvoiceItemsScreen extends ConsumerWidget {
  const AcInvoiceItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const AdaptiveDataPage(
        title: 'Invoice Items',
        tableName: 'invoice_items',
        icon: Icons.list_alt,
        accentColor: Color(0xFF8B5CF6),
        displayFields: [
          'description',
          'quantity',
          'unit_price',
          'total',
        ],
      );
}
