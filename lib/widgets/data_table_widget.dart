import 'package:flutter/material.dart';

class CustomDataTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final List<VoidCallback>? onRowTap;

  const CustomDataTable({
    super.key,
    required this.headers,
    required this.rows,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: headers.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
          rows: List.generate(
            rows.length,
            (index) => DataRow(
              cells: rows[index].map((cell) => DataCell(Text(cell))).toList(),
              onSelectChanged: onRowTap != null && index < onRowTap!.length ? (_) => onRowTap![index]() : null,
            ),
          ),
        ),
      ),
    );
  }
}
