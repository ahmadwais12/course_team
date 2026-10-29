import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class RecruitmentScreen extends ConsumerStatefulWidget {
  const RecruitmentScreen({super.key});

  @override
  ConsumerState<RecruitmentScreen> createState() => _RecruitmentScreenState();
}

class _RecruitmentScreenState extends ConsumerState<RecruitmentScreen> {
  List<Map<String, dynamic>> _candidates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    try {
      final data = await Supabase.instance.client
          .from('job_applications')
          .select()
          .order('applied_at', ascending: false);
      if (mounted) {
        setState(() {
          _candidates = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load candidates: $e')),
        );
      }
    }
  }

  DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    return DateTime.parse(date.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()), title: const Text('Recruitment')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: t(LCrud.searchHintGeneric, ref),
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ),
                    Expanded(
                      child: _candidates.isEmpty
                          ? Center(
                              child: Text(t(LStaff.noCandidates, ref)))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _candidates.length,
                              itemBuilder: (context, index) {
                                final candidate = _candidates[index];
                                return Card(
                                  margin: const EdgeInsets.only(
                                      bottom: 12),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          _getStatusColor(candidate[
                                                  'status'])
                                              .withValues(alpha: 0.1),
                                      child: Icon(Icons.person,
                                          color: _getStatusColor(
                                              candidate['status'])),
                                    ),
                                    title: Text(
                                        candidate['applicant_name'] ??
                                            candidate['name'] ??
                                            ''),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            '${candidate['position'] ?? candidate['job_id'] ?? ''} • ${candidate['experience'] ?? 'N/A'}'),
                                        Text(
                                            'Applied: ${_formatDate(_parseDate(candidate['applied_at'] ?? candidate['applied_date']))}'),
                                      ],
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 8,
                                          vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                                candidate['status'])
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        candidate['status'] ?? '',
                                        style: TextStyle(
                                          color: _getStatusColor(
                                              candidate['status']),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    onTap: () =>
                                        _showDetails(candidate),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPostJobDialog(),
        icon: const Icon(Icons.add),
        label: Text(t(LCrud.postJob, ref)),
      ),
    );
  }

  Future<void> _showPostJobDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _PostJobFormPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) _loadCandidates();
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase() ?? '') {
      case 'new':
      case 'applied':
        return Colors.blue;
      case 'interview':
      case 'shortlisted':
        return Colors.orange;
      case 'hired':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  void _showDetails(Map<String, dynamic> candidate) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  candidate['applicant_name'] ??
                      candidate['name'] ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildDetailRow('Position',
                  candidate['position'] ?? candidate['job_id'] ?? ''),
              _buildDetailRow(
                  'Experience', candidate['experience'] ?? 'N/A'),
              _buildDetailRow('Status', candidate['status'] ?? ''),
              _buildDetailRow('Applied',
                  _formatDate(_parseDate(candidate['applied_at'] ?? candidate['applied_date']))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _PostJobFormPage extends ConsumerStatefulWidget {
  const _PostJobFormPage();

  @override
  ConsumerState<_PostJobFormPage> createState() => _PostJobFormPageState();
}

class _PostJobFormPageState extends ConsumerState<_PostJobFormPage> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _requirementsCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _requirementsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    try {
      await Supabase.instance.client.from('job_postings').insert({
        'title': _titleCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'requirements': _requirementsCtrl.text.trim(),
        'status': 'open',
        'posted_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaff.jobPosted, ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post job: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LStaff.postJobOpening, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(L.cancel, ref)),
          ),
          ElevatedButton(
            onPressed: () { debugPrint('[recruitment_screen] Save button CLICKED'); _save(); },
            child: const Text('Post'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Job Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _requirementsCtrl,
              decoration: const InputDecoration(
                labelText: 'Requirements',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}


