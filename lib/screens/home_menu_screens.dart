import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:course_emis/l10n/locale_keys.dart';

class OurCoursesScreen extends ConsumerStatefulWidget {
  const OurCoursesScreen({super.key});

  @override
  ConsumerState<OurCoursesScreen> createState() => _OurCoursesScreenState();
}

class _OurCoursesScreenState extends ConsumerState<OurCoursesScreen> {
  final _sb = Supabase.instance.client;
  List<Map<String, dynamic>> _courses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _sb
          .from('courses')
          .select('name, level, duration')
          .eq('is_active', true)
          .order('name', ascending: true);
      if (mounted) {
        setState(() {
          _courses = data.map((r) => Map<String, dynamic>.from(r)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.blue, Colors.blue, Colors.orange, Colors.purple,
      Colors.teal, Colors.pink, Colors.indigo, Colors.cyan,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(t(LTitle.ourCourses, ref)), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? Center(child: Text(t(LCrud.noResultsFound, ref)))
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: _courses.length,
                    itemBuilder: (context, index) {
                      final course = _courses[index];
                      return _CourseCard(
                        name: course['name'] as String? ?? '',
                        level: course['level'] as String? ?? '',
                        duration: course['duration'] as String? ?? '',
                        icon: Icons.book,
                        color: colors[index % colors.length],
                      );
                    },
                  ),
                ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final String name;
  final String level;
  final String duration;
  final IconData icon;
  final Color color;

  const _CourseCard({
    required this.name,
    required this.level,
    required this.duration,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Level: $level', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          Text('Duration: $duration', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

class OurBranchesScreen extends ConsumerStatefulWidget {
  const OurBranchesScreen({super.key});

  @override
  ConsumerState<OurBranchesScreen> createState() => _OurBranchesScreenState();
}

class _OurBranchesScreenState extends ConsumerState<OurBranchesScreen> {
  final _sb = Supabase.instance.client;
  List<Map<String, dynamic>> _branches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _sb
          .from('branches')
          .select('name, location, student_count')
          .eq('is_active', true)
          .order('name', ascending: true);
      if (mounted) {
        setState(() {
          _branches = data.map((r) => Map<String, dynamic>.from(r)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icons = [Icons.location_city, Icons.business, Icons.apartment, Icons.store, Icons.domain, Icons.corporate_fare];

    return Scaffold(
      appBar: AppBar(title: Text(t(LTitle.ourBranches, ref)), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _branches.isEmpty
              ? Center(child: Text(t(LCrud.noResultsFound, ref)))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _branches.length,
                  itemBuilder: (context, index) {
                    final branch = _branches[index];
                    final sc = branch['student_count'];
                    final students = sc != null ? '$sc+' : 'N/A';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icons[index % icons.length], color: theme.colorScheme.primary, size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(branch['name'] as String? ?? '', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(branch['location'] as String? ?? '', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                                  const SizedBox(height: 4),
                                  Text('$students Students', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class OurNewClassesScreen extends ConsumerStatefulWidget {
  const OurNewClassesScreen({super.key});

  @override
  ConsumerState<OurNewClassesScreen> createState() => _OurNewClassesScreenState();
}

class _OurNewClassesScreenState extends ConsumerState<OurNewClassesScreen> {
  final _sb = Supabase.instance.client;
  List<Map<String, dynamic>> _classes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _sb
          .from('classes')
          .select('name, schedule, capacity, enrolled_count, status')
          .eq('is_active', true)
          .order('name', ascending: true);
      if (mounted) {
        setState(() {
          _classes = data.map((r) => Map<String, dynamic>.from(r)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t(LTitle.newClasses, ref)), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _classes.isEmpty
              ? Center(child: Text(t(LCrud.noResultsFound, ref)))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _classes.length,
                  itemBuilder: (context, index) {
                    final cls = _classes[index];
                    final cap = cls['capacity'] as int? ?? 0;
                    final enrolled = cls['enrolled_count'] as int? ?? 0;
                    final seats = cap > 0 ? '$enrolled/$cap' : 'N/A';
                    final status = cls['status'] as String? ?? 'Open';
                    final isFilling = status.toLowerCase().contains('fast') || (cap > 0 && enrolled >= cap * 0.8);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(cls['name'] as String? ?? '', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isFilling ? Colors.orange.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isFilling ? 'Filling Fast' : 'Open',
                                    style: TextStyle(color: isFilling ? Colors.orange : Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(children: [const Icon(Icons.access_time, size: 16), const SizedBox(width: 8), Text(cls['schedule'] as String? ?? '')]),
                            const SizedBox(height: 8),
                            Row(children: [const Icon(Icons.people, size: 16), const SizedBox(width: 8), Text('$seats Seats Available')]),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
