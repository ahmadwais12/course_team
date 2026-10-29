import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class AcademicYearScreen extends ConsumerStatefulWidget {
  const AcademicYearScreen({super.key});

  @override
  ConsumerState<AcademicYearScreen> createState() =>
      _AcademicYearScreenState();
}

class _AcademicYearScreenState extends ConsumerState<AcademicYearScreen> {
  final _sb = Supabase.instance.client;
  bool _loading = true;
  List<Map<String, dynamic>> _years = [];
  int _totalStudents = 0;
  int _totalTeachers = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final years = await _sb
          .from('academic_years')
          .select()
          .order('created_at', ascending: false);
      final students = await _sb.from('students').select('id');
      final teachers = await _sb.from('teachers').select('id');
      setState(() {
        _years = List<Map<String, dynamic>>.from(years);
        _totalStudents = students.length;
        _totalTeachers = teachers.length;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading academic years: $e');
      setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? get _currentYear {
    try {
      return _years.firstWhere((y) => y['status'] == 'active');
    } catch (_) {
      return _years.isNotEmpty ? _years.first : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = _currentYear;

    return Scaffold(
      appBar: AppBar(
        title: Text(t(LTitle.academicYear, ref)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showYearDialog(),
        icon: const Icon(Icons.add_rounded),
        label: Text(t(L.add, ref)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: AppSpacing.paddingLg,
                children: [
                  // Current Year Banner
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: current != null
                            ? [const Color(0xFF38BDF8), const Color(0xFF67E8F9)]
                            : [Colors.grey.shade400, Colors.grey.shade300],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: AppSpacing.paddingSm,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Academic Year',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                current?['name'] ?? 'No active year',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (current != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Year Statistics
                  Text(
                    'Year Statistics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        context,
                        'Total Students',
                        _totalStudents.toString(),
                        Icons.people_rounded,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        context,
                        'Total Teachers',
                        _totalTeachers.toString(),
                        Icons.school_rounded,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        context,
                        'Total Years',
                        _years.length.toString(),
                        Icons.calendar_month_rounded,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        context,
                        'Active Year',
                        _years.where((y) => y['status'] == 'active').length.toString(),
                        Icons.check_circle_rounded,
                        Colors.purple,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // All Academic Years
                  Text(
                    'All Academic Years',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (_years.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.calendar_month_outlined,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(t(LAll.all_no_academic_years_found, ref),
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._years.map((year) => Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: year['status'] == 'active'
                                    ? Colors.blue.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Icon(
                                Icons.calendar_month_rounded,
                                color: year['status'] == 'active'
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                            ),
                            title: Text(year['name'] ?? 'Unnamed'),
                            subtitle: Text(
                              'Start: ${_formatDate(year['start_date'])} â€¢ End: ${_formatDate(year['end_date'])}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (year['status'] == 'active')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppRadius.full),
                                    ),
                                    child: const Text(
                                      'Active',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                else ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, size: 20),
                                    onPressed: () => _showYearDialog(year: year),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    color: Colors.red,
                                    onPressed: () => _confirmDelete(year),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }

  Future<void> _showYearDialog({Map<String, dynamic>? year}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _YearFormPage(year: year),
        fullscreenDialog: true,
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _confirmDelete(Map<String, dynamic> year) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(LAll.all_delete_academic_year, ref)),
        content: Text(
            '${t(LAll.all_are_you_sure_you_want_to_delete, ref)} "${year['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t(L.delete, ref)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _sb.from('academic_years').delete().eq('id', year['id']);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(tt(LAll.all_error_x, ref, [e.toString()]))),
          );
        }
      }
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: AppSpacing.paddingSm,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearFormPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? year;
  const _YearFormPage({this.year});

  @override
  ConsumerState<_YearFormPage> createState() => _YearFormPageState();
}

class _YearFormPageState extends ConsumerState<_YearFormPage> {
  final _sb = Supabase.instance.client;
  late final TextEditingController _nameCtl;
  late DateTime _startDate;
  late DateTime _endDate;
  late String _status;

  bool get _isEdit => widget.year != null;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.year?['name'] ?? '');
    _startDate = widget.year != null
        ? DateTime.tryParse(widget.year!['start_date'] ?? '') ?? DateTime.now()
        : DateTime.now();
    _endDate = widget.year != null
        ? DateTime.tryParse(widget.year!['end_date'] ?? '') ?? DateTime.now().add(const Duration(days: 300))
        : DateTime.now().add(const Duration(days: 300));
    _status = widget.year?['status'] ?? 'active';
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Academic Year' : 'Add Academic Year'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t(L.cancel, ref))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtl,
            decoration: const InputDecoration(
              labelText: 'Year Name (e.g. 2025-2026)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t(LAll.all_start_date, ref)),
            subtitle: Text(_formatDate(_startDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => _startDate = picked);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t(LAll.all_end_date, ref)),
            subtitle: Text(_formatDate(_endDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _endDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => _endDate = picked);
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
initialValue: _status,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'active', child: Text(t(LCrud.active, ref))),
              DropdownMenuItem(value: 'archived', child: Text(t(LAll.all_archived, ref))),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _status = v);
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () { debugPrint('[academic_year_screen] Save button CLICKED'); _save(); },
            child: Text(_isEdit ? t(L.save, ref) : t(L.add, ref)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtl.text.isEmpty) return;
    final data = {
      'name': _nameCtl.text,
      'start_date': _startDate.toIso8601String(),
      'end_date': _endDate.toIso8601String(),
      'status': _status,
    };
    try {
      if (_isEdit) {
        await _sb.from('academic_years').update(data).eq('id', widget.year!['id']);
      } else {
        await _sb.from('academic_years').insert(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    }
  }
}
