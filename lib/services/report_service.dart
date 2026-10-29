import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ReportService {
  static final instance = ReportService._();
  ReportService._();

  final _supabase = Supabase.instance.client;

  // Custom report builder
  Future<Map<String, dynamic>> buildCustomReport({
    required String reportType,
    required Map<String, dynamic> filters,
    required List<String> fields,
  }) async {
    String table;
    switch (reportType) {
      case 'students':
        table = 'students';
        break;
      case 'attendance':
        table = 'attendance';
        break;
      case 'grades':
        table = 'grades';
        break;
      case 'payments':
        table = 'payments';
        break;
      default:
        throw Exception('Invalid report type');
    }

    var query = _supabase.from(table).select(fields.join(','));

    filters.forEach((key, value) {
      if (value != null) {
        query = query.eq(key, value);
      }
    });

    final data = await query;
    return {
      'type': reportType,
      'data': data,
      'generated_at': DateTime.now().toIso8601String(),
      'total_records': data.length,
    };
  }

  // Schedule report
  Future<void> scheduleReport({
    required String name,
    required String reportType,
    required Map<String, dynamic> config,
    required String frequency, // daily, weekly, monthly
  }) async {
    await _supabase.from('scheduled_reports').insert({
      'name': name,
      'report_type': reportType,
      'config': config,
      'frequency': frequency,
      'user_id': _supabase.auth.currentUser!.id,
      'next_run': _getNextRunDate(frequency),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  DateTime _getNextRunDate(String frequency) {
    final now = DateTime.now();
    switch (frequency) {
      case 'daily':
        return now.add(const Duration(days: 1));
      case 'weekly':
        return now.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(now.year, now.month + 1, now.day);
      default:
        return now.add(const Duration(days: 1));
    }
  }

  // Generate PDF report
  Future<String> generatePDFReport(Map<String, dynamic> reportData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Report: ${reportData['type']}',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('Generated: ${reportData['generated_at']}'),
            pw.Text('Total Records: ${reportData['total_records']}'),
            pw.SizedBox(height: 20),
            pw.Text('Data:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...List.generate(
              (reportData['data'] as List).length,
              (index) => pw.Text(reportData['data'][index].toString()),
            ),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  // Data visualization data
  Future<Map<String, dynamic>> getVisualizationData(String type) async {
    switch (type) {
      case 'attendance_trend':
        final data = await _supabase
            .from('attendance')
            .select('date, status')
            .order('date', ascending: true)
            .limit(30);
        
        final grouped = <String, int>{};
        for (var item in data) {
          final date = item['date'] as String;
          grouped[date] = (grouped[date] ?? 0) + 1;
        }
        
        return {'labels': grouped.keys.toList(), 'values': grouped.values.toList()};

      case 'grade_distribution':
        final data = await _supabase.from('grades').select('score');
        final ranges = {'A': 0, 'B': 0, 'C': 0, 'D': 0, 'F': 0};
        
        for (var item in data) {
          final score = item['score'] as num;
          if (score >= 90) {
            ranges['A'] = ranges['A']! + 1;
          } else if (score >= 80) {
            ranges['B'] = ranges['B']! + 1;
          } else if (score >= 70) {
            ranges['C'] = ranges['C']! + 1;
          } else if (score >= 60) {
            ranges['D'] = ranges['D']! + 1;
          } else {
            ranges['F'] = ranges['F']! + 1;
          }
        }
        
        return {'labels': ranges.keys.toList(), 'values': ranges.values.toList()};

      default:
        return {};
    }
  }
}
