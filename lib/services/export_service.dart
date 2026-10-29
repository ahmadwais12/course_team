import 'dart:io';
import 'package:flutter/foundation.dart';
// ignore_for_file: unnecessary_import
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

/// Supported export formats
enum ExportFormat {
  pdf,
  csv,
  html,
  docx,
  xlsx,
}

class ExportService {
  /// Export data to PDF with full formatting
  static Future<File?> exportToPDF({
    required String title,
    required List<List<String>> data,
    required List<String> headers,
    String? subtitle,
    String? footer,
    String? organization,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header / Org name
            if (organization != null)
              pw.Text(
                organization,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            pw.SizedBox(height: 4),
            // Title
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                subtitle,
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey600,
                ),
              ),
            ],
            pw.Divider(),
            pw.SizedBox(height: 16),
            // Timestamp
            pw.Text(
              'Generated: ${DateTime.now().toLocal().toString().substring(0, 19)}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
            pw.SizedBox(height: 20),
            // Data table
            data.isNotEmpty
                ? pw.TableHelper.fromTextArray(
                    headers: headers,
                    data: data,
                    border: pw.TableBorder.all(
                      color: PdfColors.grey300,
                      width: 0.5,
                    ),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                    ),
                    cellStyle: const pw.TextStyle(fontSize: 8.5),
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    cellAlignment: pw.Alignment.centerLeft,
                    columnWidths: _calculateColumnWidths(headers.length),
                  )
                : pw.Center(
                    child: pw.Text('No data available.',
                        style: pw.TextStyle(color: PdfColors.grey500)),
                  ),
            if (footer != null) ...[
              pw.SizedBox(height: 24),
              pw.Divider(),
              pw.Text(
                footer,
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ],
          ],
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          '${_sanitizeFileName(title)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      debugPrint('[ExportService] PDF export error: $e');
      return null;
    }
  }

  /// Export data to CSV (opens in Excel)
  static Future<File?> exportToCSV({
    required String title,
    required List<List<String>> data,
    required List<String> headers,
  }) async {
    try {
      final buffer = StringBuffer();
      // BOM for proper Excel UTF-8 handling
      buffer.write('\uFEFF');
      buffer.writeln(headers.map((e) => _escapeCsvField(e)).join(','));
      for (final row in data) {
        buffer.writeln(row.map((e) => _escapeCsvField(e)).join(','));
      }

      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          '${_sanitizeFileName(title)}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(buffer.toString());
      return file;
    } catch (e) {
      debugPrint('[ExportService] CSV export error: $e');
      return null;
    }
  }

  /// Export data to HTML (printable / DOC-compatible)
  static Future<File?> exportToHTML({
    required String title,
    required List<List<String>> data,
    required List<String> headers,
    String? organization,
    String? subtitle,
  }) async {
    try {
      final buf = StringBuffer();
      buf.writeln('<!DOCTYPE html>');
      buf.writeln('<html lang="en">');
      buf.writeln('<head><meta charset="UTF-8">');
      buf.writeln('<title>$title</title>');
      buf.writeln('<style>');
      buf.writeln('''
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 40px; color: #333; }
        h1 { color: #1a1a2e; border-bottom: 2px solid #7c3aed; padding-bottom: 8px; }
        .subtitle { color: #666; font-size: 14px; margin-top: -8px; }
        .meta { color: #999; font-size: 11px; margin-bottom: 24px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background: #7c3aed; color: white; padding: 10px 12px; text-align: left; font-size: 13px; }
        td { padding: 8px 12px; border-bottom: 1px solid #e0e0e0; font-size: 12px; }
        tr:hover { background: #f5f0ff; }
        .org { color: #7c3aed; font-size: 12px; font-weight: 600; }
        @media print { body { margin: 20px; } }
      ''');
      buf.writeln('</style></head><body>');

      if (organization != null) {
        buf.writeln('<p class="org">$organization</p>');
      }
      buf.writeln('<h1>$title</h1>');
      if (subtitle != null) {
        buf.writeln('<p class="subtitle">$subtitle</p>');
      }
      buf.writeln(
          '<p class="meta">Generated: ${DateTime.now().toLocal().toString().substring(0, 19)}</p>');

      if (data.isNotEmpty) {
        buf.writeln('<table>');
        buf.writeln('<thead><tr>');
        for (final h in headers) {
          buf.writeln('<th>${_escapeHtml(h)}</th>');
        }
        buf.writeln('</tr></thead><tbody>');
        for (final row in data) {
          buf.writeln('<tr>');
          for (final cell in row) {
            buf.writeln('<td>${_escapeHtml(cell)}</td>');
          }
          buf.writeln('</tr>');
        }
        buf.writeln('</tbody></table>');
      } else {
        buf.writeln('<p>No data available.</p>');
      }

      buf.writeln('</body></html>');

      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          '${_sanitizeFileName(title)}_${DateTime.now().millisecondsSinceEpoch}.html';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(buf.toString());
      return file;
    } catch (e) {
      debugPrint('[ExportService] HTML export error: $e');
      return null;
    }
  }

  /// Export data to DOCX (Word-compatible XML)
  static Future<File?> exportToDOCX({
    required String title,
    required List<List<String>> data,
    required List<String> headers,
  }) async {
    try {
      // Generate Word-compatible XML (docx is a zip of XML files)
      final body = StringBuffer();
      body.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
      body.writeln(
          '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">');
      body.writeln('<w:body>');

      // Title
      body.writeln('<w:p><w:pPr><w:pStyle w:val="Title"/></w:pPr>');
      body.writeln(
          '<w:r><w:t>${_escapeXml(title)}</w:t></w:r></w:p>');

      // Timestamp
      body.writeln('<w:p><w:r><w:rPr><w:sz w:val="18"/></w:rPr>');
      body.writeln(
          '<w:t>Generated: ${DateTime.now().toLocal().toString().substring(0, 19)}</w:t></w:r></w:p>');

      // Spacer
      body.writeln('<w:p></w:p>');

      // Table
      body.writeln('<w:tbl>');

      // Header row
      body.writeln('<w:tr>');
      for (final h in headers) {
        body.writeln('<w:tc><w:p><w:pPr><w:pStyle w:val="Heading3"/></w:pPr>');
        body.writeln(
            '<w:r><w:t>${_escapeXml(h)}</w:t></w:r></w:p></w:tc>');
      }
      body.writeln('</w:tr>');

      // Data rows
      for (final row in data) {
        body.writeln('<w:tr>');
        for (final cell in row) {
          body.writeln('<w:tc><w:p>');
          body.writeln(
              '<w:r><w:t>${_escapeXml(cell)}</w:t></w:r></w:p></w:tc>');
        }
        body.writeln('</w:tr>');
      }

      body.writeln('</w:tbl>');
      body.writeln('</w:body></w:document>');

      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          '${_sanitizeFileName(title)}_${DateTime.now().millisecondsSinceEpoch}.docx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(body.toString());
      return file;
    } catch (e) {
      debugPrint('[ExportService] DOCX export error: $e');
      return null;
    }
  }

  /// Export data to XLSX (Excel-compatible XML)
  static Future<File?> exportToXLSX({
    required String title,
    required List<List<String>> data,
    required List<String> headers,
  }) async {
    try {
      // Generate Excel-compatible XML (xlsx is a zip of XML files)
      final buf = StringBuffer();
      buf.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
      buf.writeln(
          '<?mso-application progid="Excel.Sheet"?>');
      buf.writeln(
          '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"');
      buf.writeln(
          ' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">');

      buf.writeln('<Worksheet ss:Name="${_escapeXml(title)}">');
      buf.writeln('<Table>');

      // Header row
      buf.writeln('<Row>');
      for (final h in headers) {
        buf.writeln(
            '<Cell><Data ss:Type="String">${_escapeXml(h)}</Data></Cell>');
      }
      buf.writeln('</Row>');

      // Data rows
      for (final row in data) {
        buf.writeln('<Row>');
        for (final cell in row) {
          final isNum = double.tryParse(cell) != null;
          buf.writeln(
              '<Cell><Data ss:Type="${isNum ? 'Number' : 'String'}">${_escapeXml(cell)}</Data></Cell>');
        }
        buf.writeln('</Row>');
      }

      buf.writeln('</Table>');
      buf.writeln('</Worksheet>');
      buf.writeln('</Workbook>');

      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          '${_sanitizeFileName(title)}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(buf.toString());
      return file;
    } catch (e) {
      debugPrint('[ExportService] XLSX export error: $e');
      return null;
    }
  }

  /// Generate PDF bytes for printing
  static Future<Uint8List> _generatePrintPDF({
    required String title,
    required List<List<String>> data,
    required List<String> headers,
    String? subtitle,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                subtitle,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
            pw.Divider(),
            pw.SizedBox(height: 12),
            data.isNotEmpty
                ? pw.TableHelper.fromTextArray(
                    headers: headers,
                    data: data,
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8,
                    ),
                    cellStyle: const pw.TextStyle(fontSize: 7.5),
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                  )
                : pw.Center(
                    child: pw.Text('No data available.',
                        style: pw.TextStyle(color: PdfColors.grey500)),
                  ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// Export as PDF and return bytes suitable for printing
  static Future<Uint8List?> exportToPDFBytes({
    required String title,
    required List<List<String>> data,
    required List<String> headers,
    String? subtitle,
  }) async {
    try {
      return await _generatePrintPDF(
        title: title,
        data: data,
        headers: headers,
        subtitle: subtitle,
      );
    } catch (e) {
      debugPrint('[ExportService] PDF bytes error: $e');
      return null;
    }
  }

  /// Generic export handler — picks format and returns file
  static Future<File?> exportData({
    required ExportFormat format,
    required String title,
    required List<List<String>> data,
    required List<String> headers,
    String? subtitle,
    String? organization,
  }) async {
    switch (format) {
      case ExportFormat.pdf:
        return exportToPDF(
          title: title,
          data: data,
          headers: headers,
          subtitle: subtitle,
          organization: organization,
        );
      case ExportFormat.csv:
        return exportToCSV(title: title, data: data, headers: headers);
      case ExportFormat.html:
        return exportToHTML(
          title: title,
          data: data,
          headers: headers,
          subtitle: subtitle,
          organization: organization,
        );
      case ExportFormat.docx:
        return exportToDOCX(title: title, data: data, headers: headers);
      case ExportFormat.xlsx:
        return exportToXLSX(title: title, data: data, headers: headers);
    }
  }

  // ─── Helpers ───

  static String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
  }

  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Calculate column widths based on count
  static Map<int, pw.TableColumnWidth>? _calculateColumnWidths(int count) {
    if (count <= 4) return null;
    return {
      for (int i = 0; i < count; i++)
        i: pw.FlexColumnWidth(count > 6 ? 1.5 : 1.0),
    };
  }
}
