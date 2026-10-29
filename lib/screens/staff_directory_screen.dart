import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/theme.dart';
import 'package:go_router/go_router.dart';

class StaffDirectoryScreen extends ConsumerStatefulWidget {
  const StaffDirectoryScreen({super.key});

  @override
  ConsumerState<StaffDirectoryScreen> createState() => _StaffDirectoryScreenState();
}

class _StaffDirectoryScreenState extends ConsumerState<StaffDirectoryScreen> {
  List<Map<String, dynamic>> _staff = [];
  bool _loading = true;
  String _selectedFilter = 'All';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    try {
      final data = await Supabase.instance.client
          .from('staff')
          .select()
          .order('full_name', ascending: true);
      if (mounted) setState(() => _staff = List<Map<String, dynamic>>.from(data));
    } catch (_) {
      if (mounted) setState(() => _staff = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredStaff {
    var list = _staff;
    if (_selectedFilter != 'All') {
      list = list.where((s) {
        final role = s['role']?.toString() ?? s['department']?.toString() ?? '';
        return role.toLowerCase() == _selectedFilter.toLowerCase();
      }).toList();
    }
    final query = _searchCtrl.text.toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((s) {
        final name = s['full_name']?.toString().toLowerCase() ?? '';
        final role = s['role']?.toString().toLowerCase() ?? '';
        return name.contains(query) || role.contains(query);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ['All', 'Teachers', 'Admin', 'Support', 'Maintenance'];

    return Scaffold(
      appBar: AppBar(
        title: Text(t(LTitle.staffDirectory, ref)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadStaff,
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStaff,
              child: ListView(
                padding: AppSpacing.paddingLg,
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: t(LCrud.searchHintStaff, ref),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                      filled: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: filters.map((f) {
                        final isSelected = f == _selectedFilter;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: _buildFilterChip(f, isSelected),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    _selectedFilter == 'All' ? t(LCrud.allStatus, ref) : '$_selectedFilter ${t(LStaff.noStaff, ref)}',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_filteredStaff.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(t(LStaff.noStaff, ref), style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._filteredStaff.map((s) {
                      final name = s['full_name']?.toString() ?? 'Unknown';
                      final role = s['role']?.toString() ?? s['department']?.toString() ?? '';
                      final staffId = s['staff_id']?.toString() ?? s['id']?.toString() ?? '';
                      final status = (s['status']?.toString() ?? 'active').toLowerCase();
                      final isActive = status == 'active';
                      final initials = name.isNotEmpty ? name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join() : '?';
                      final colors = [Colors.blue, Colors.blue, Colors.orange, Colors.purple, Colors.red];
                      final color = colors[name.hashCode % colors.length];

                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.1),
                            child: Text(initials, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (role.isNotEmpty) Text(role),
                              if (staffId.isNotEmpty) Text('ID: $staffId'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.blue : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(isActive ? t(LStatus.activeStatus, ref) : t(LCrud.inactive, ref), style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                          onTap: () => context.go('/profile'),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = label);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue.withValues(alpha: 0.2),
      checkmarkColor: Colors.blue,
    );
  }
}
