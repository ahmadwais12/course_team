import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gamification_service.dart';
import '../widgets/modern_ui.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class GamificationScreen extends ConsumerStatefulWidget {
  final String studentId;

  const GamificationScreen({super.key, required this.studentId});

  @override
  ConsumerState<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends ConsumerState<GamificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<Map<String, dynamic>> _badges = [];
  List<Map<String, dynamic>> _leaderboard = [];
  Map<String, dynamic>? _progress;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        GamificationService.instance.getBadges(widget.studentId),
        GamificationService.instance.getLeaderboard(),
        GamificationService.instance.getProgress(widget.studentId),
      ]);
      
      setState(() {
        _badges = results[0] as List<Map<String, dynamic>>;
        _leaderboard = results[1] as List<Map<String, dynamic>>;
        _progress = results[2] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LAll.all_achievements, ref)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Badges'),
            Tab(text: 'Leaderboard'),
            Tab(text: 'Progress'),
          ],
        ),
      ),
      body: _loading
          ? const PageSkeleton(type: 'dashboard')
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBadgesTab(),
                _buildLeaderboardTab(),
                _buildProgressTab(),
              ],
            ),
    );
  }

  Widget _buildBadgesTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _badges.length,
      itemBuilder: (context, index) {
        final badge = _badges[index];
        return ModernCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(badge['icon'], style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(badge['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(badge['description'], style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leaderboard.length,
      itemBuilder: (context, index) {
        final student = _leaderboard[index];
        return ModernCard(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: index < 3 ? Colors.amber : Colors.grey,
              child: Text(tt(LAll.all_s392, ref, ['${index + 1}'])),
            ),
            title: Text(student['name']),
            trailing: Text('${student['points']} pts', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildProgressTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ModernCard(
          child: Column(
            children: [
              Text(tt(LAll.all_s352, ref, ['5']), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: (_progress?['attendance_progress'] ?? 0) / 100),
              const SizedBox(height: 8),
              Text('Attendance: ${_progress?['attendance_progress']?.toStringAsFixed(1)}%'),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: (_progress?['grade_progress'] ?? 0) / 100),
              const SizedBox(height: 8),
              Text('Grades: ${_progress?['grade_progress']?.toStringAsFixed(1)}%'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
