import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class AdmissionsScreen extends ConsumerStatefulWidget {
  const AdmissionsScreen({super.key});

  @override
  ConsumerState<AdmissionsScreen> createState() => _AdmissionsScreenState();
}

class _AdmissionsScreenState extends ConsumerState<AdmissionsScreen> {
  List<Map<String, dynamic>> _admissions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAdmissions();
  }

  Future<void> _loadAdmissions() async {
    try {
      final data = await Supabase.instance.client
          .from('admissions')
          .select()
          .order('created_at', ascending: false);
      if (mounted) setState(() => _admissions = List<Map<String, dynamic>>.from(data));
    } catch (_) {
      if (mounted) setState(() => _admissions = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final pending = _admissions.where((a) => (a['status']?.toString() ?? '').toLowerCase() == 'pending').length;
    final approved = _admissions.where((a) => (a['status']?.toString() ?? '').toLowerCase() == 'approved').length;
    final rejected = _admissions.where((a) => (a['status']?.toString() ?? '').toLowerCase() == 'rejected').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(t(LTitle.admissions, ref)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadAdmissions,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.go('/students'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: RefreshIndicator(
                  onRefresh: _loadAdmissions,
                  child: ListView(
                    padding: AppSpacing.paddingLg,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(context, 'Pending', '$pending', Icons.hourglass_empty_rounded, Colors.orange),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildStatCard(context, 'Approved', '$approved', Icons.check_circle_rounded, Colors.blue),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildStatCard(context, 'Rejected', '$rejected', Icons.cancel_rounded, Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Recent Applications',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_admissions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.person_add_alt_1, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(t(LCrud.noApplications, ref), style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._admissions.map((a) {
                          final status = (a['status']?.toString() ?? '').toLowerCase();
                          Color statusColor;
                          String statusLabel;
                          switch (status) {
                            case 'approved':
                              statusColor = Colors.blue;
                              statusLabel = 'Approved';
                              break;
                            case 'rejected':
                              statusColor = Colors.red;
                              statusLabel = 'Rejected';
                              break;
                            default:
                              statusColor = Colors.orange;
                              statusLabel = 'Pending';
                          }
                          final name = a['student_name']?.toString() ?? a['name']?.toString() ?? 'Unknown';
                          final grade = a['grade']?.toString() ?? '';
                          final section = a['section']?.toString() ?? '';
                          final applied = (a['created_at']?.toString() ?? '').length >= 10
                              ? (a['created_at']?.toString() ?? '').substring(0, 10)
                              : '';
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                                child: Icon(Icons.person_rounded, color: Colors.blue),
                              ),
                              title: Text(name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (grade.isNotEmpty) Text('$grade${section.isNotEmpty ? ' - Section $section' : ''}'),
                                  if (applied.isNotEmpty) Text('Applied: $applied'),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                              ),
                              onTap: () => context.go('/students'),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/students'),
        icon: const Icon(Icons.add_rounded),
        label: Text(t(L.add, ref)),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
