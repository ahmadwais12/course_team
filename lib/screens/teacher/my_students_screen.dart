import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyStudentsScreen extends ConsumerStatefulWidget {
  const MyStudentsScreen({super.key});

  @override
  ConsumerState<MyStudentsScreen> createState() => _MyStudentsScreenState();
}

class _MyStudentsScreenState extends ConsumerState<MyStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final classesData = await Supabase.instance.client
          .from('classes')
          .select('id, name')
          .eq('teacher_id', userId)
          .eq('active', true);

      final classList = List<Map<String, dynamic>>.from(classesData);
      if (classList.isEmpty) {
        if (mounted) setState(() { _classes = []; _students = []; _isLoading = false; });
        return;
      }

      final ids = classList.map((c) => c['id']).toList();
      final studentsData = await Supabase.instance.client
          .from('students')
          .select('id, full_name, student_code, email, phone, status, class_id, enrollment_date, attendance_percentage, average_grade')
          .inFilter('class_id', ids)
          .order('full_name', ascending: true);

      if (mounted) {
        setState(() {
          _classes = classList;
          _students = List<Map<String, dynamic>>.from(studentsData);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load students: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    var filtered = _students;
    if (_selectedClassId != null) {
      filtered = filtered.where((s) => s['class_id'] == _selectedClassId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        return (s['full_name']?.toString().toLowerCase().contains(q) ?? false) ||
            (s['student_code']?.toString().toLowerCase().contains(q) ?? false) ||
            (s['email']?.toString().toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return filtered;
  }

  String _className(dynamic classId) {
    for (final c in _classes) {
      if (c['id'] == classId) return c['name'] ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredStudents;

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()), title: const Text('My Students')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.people, color: Colors.black, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Students',
                            style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold)),
                        Text('${filtered.length} student${filtered.length == 1 ? '' : 's'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: theme.cardColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                if (_classes.length > 1) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _selectedClassId == null,
                          onTap: () => setState(() => _selectedClassId = null),
                        ),
                        ..._classes.map((c) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                            label: c['name'] ?? '',
                            selected: _selectedClassId == c['id'],
                            onTap: () => setState(() => _selectedClassId = c['id']),
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(_selectedClassId != null
                                ? 'No students in this class'
                                : 'No students assigned to you',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final student = filtered[index];
                            final status = student['status']?.toString() ?? 'active';
                            final isActive = status == 'active';
                            final attendance = student['attendance_percentage'];
                            final grade = student['average_grade'];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _showStudentDetails(student),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: Colors.grey[200],
                                        child: Text(
                                          (student['full_name'] ?? '?')
                                              .toString()
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(student['full_name'] ?? '',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Text(student['student_code'] ?? '',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[600])),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isActive
                                                        ? Colors.grey[200]
                                                        : Colors.red[50],
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    status,
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      color: isActive
                                                          ? Colors.black
                                                          : Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (attendance != null)
                                        _MetricBadge(
                                          value: '${attendance.toStringAsFixed(0)}%',
                                          label: 'Att',
                                          color: attendance >= 75
                                              ? Colors.black
                                              : Colors.orange,
                                        ),
                                      if (grade != null) ...[
                                        const SizedBox(width: 8),
                                        _MetricBadge(
                                          value: grade.toStringAsFixed(1),
                                          label: 'Avg',
                                          color: grade >= 70
                                              ? Colors.black
                                              : Colors.orange,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[200],
                    child: Text(
                      (student['full_name'] ?? '?').toString().substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student['full_name'] ?? '',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(student['student_code'] ?? '',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_selectedClassId != null)
                _DetailRow('Class', _className(student['class_id'])),
              _DetailRow('Email', student['email'] ?? 'N/A'),
              _DetailRow('Phone', student['phone'] ?? 'N/A'),
              _DetailRow('Status', student['status']?.toString() ?? 'N/A'),
              if (student['enrollment_date'] != null)
                _DetailRow('Enrolled', student['enrollment_date'].toString().substring(0, 10)),
              if (student['attendance_percentage'] != null)
                _DetailRow('Attendance', '${student['attendance_percentage']}%'),
              if (student['average_grade'] != null)
                _DetailRow('Average Grade', student['average_grade'].toString()),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.black : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MetricBadge({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        Text(label,
            style: TextStyle(fontSize: 9, color: Colors.grey[500])),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

