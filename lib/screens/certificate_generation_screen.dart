import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class CertificateGenerationScreen extends ConsumerStatefulWidget {
  const CertificateGenerationScreen({super.key});

  @override
  ConsumerState<CertificateGenerationScreen> createState() =>
      _CertificateGenerationScreenState();
}

class _CertificateGenerationScreenState
    extends ConsumerState<CertificateGenerationScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _eligibleStudents = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEligibleStudents();
  }

  Future<void> _loadEligibleStudents() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('students')
          .select(
              'id, full_name, student_code, program_id, status, enrollment_date, expected_completion_date, actual_completion_date, certificate_issued')
          .eq('status', 'graduated')
          .order('full_name', ascending: true);

      setState(() {
        _eligibleStudents = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _generateCertificate(Map<String, dynamic> student) async {
    try {
      final certificateNumber = 'CERT-${DateTime.now().millisecondsSinceEpoch}';
      final issueDate = DateTime.now().toIso8601String();

      // Insert certificate record
      await _supabase.from('certificates').insert({
        'student_id': student['id'],
        'certificate_type': 'completion',
        'course_name': student['program_id'],
        'issue_date': issueDate,
        'certificate_number': certificateNumber,
        'issued_by': _supabase.auth.currentUser?.id,
        'status': 'issued',
        'notes': 'Certificate generated for course completion',
      });

      // Update student record
      await _supabase.from('students').update({
        'certificate_issued': true,
        'certificate_issued_date': issueDate,
        'certificate_number': certificateNumber,
      }).eq('id', student['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Certificate generated: $certificateNumber'),
            backgroundColor: Colors.blue,
          ),
        );
        _loadEligibleStudents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) return _eligibleStudents;
    return _eligibleStudents.where((student) {
      final name = student['full_name']?.toString().toLowerCase() ?? '';
      final code = student['student_code']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase()) ||
          code.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LTitle.certificateGeneration, ref)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEligibleStudents,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                labelText: t(L.search, ref),
                hintText: t(LCrud.searchHintGeneric, ref),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Eligible',
                    _eligibleStudents.length.toString(),
                    Colors.blue,
                    Icons.verified,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Showing',
                    _filteredStudents.length.toString(),
                    Colors.blue,
                    Icons.filter_list,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Issued',
                    _eligibleStudents
                        .where((s) => s['certificate_issued'] == true)
                        .length
                        .toString(),
                    Colors.purple,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Student List
          Expanded(
            child: _isLoading
                ? const PageSkeleton(type: 'dashboard')
                : _filteredStudents.isEmpty
                    ? const Center(
                        child: Text('No eligible students found'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = _filteredStudents[index];
                          return _buildStudentCard(student);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final isIssued = student['certificate_issued'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isIssued
              ? Colors.blue.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isIssued
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.blue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isIssued ? Icons.check_circle : Icons.workspace_premium,
            color: isIssued ? Colors.blue : Colors.blue,
            size: 28,
          ),
        ),
        title: Text(
          student['full_name'] ?? 'Unknown',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Code: ${student['student_code']}'),
            Text('Status: ${student['status']}'),
            if (isIssued)
              Text(
                'Certificate Issued',
                style: TextStyle(
                    color: Colors.blue[700], fontWeight: FontWeight.w600),
              ),
          ],
        ),
        trailing: isIssued
            ? const Icon(Icons.check_circle, color: Colors.blue, size: 32)
            : FilledButton.icon(
                onPressed: () => _showGenerateDialog(student),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
      ),
    );
  }

  void _showGenerateDialog(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(LExam.certificate, ref)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${student['full_name']}'),
            const SizedBox(height: 8),
            Text('Code: ${student['student_code']}'),
            const SizedBox(height: 8),
            const Text(
                'This will generate a completion certificate for this student.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _generateCertificate(student);
            },
            child: Text(t(LExam.certificate, ref)),
          ),
        ],
      ),
    );
  }
}
