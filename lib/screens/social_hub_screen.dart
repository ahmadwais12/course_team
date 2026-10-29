import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/locale_keys.dart';
import '../services/social_service.dart';
import '../widgets/modern_ui.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class SocialHubScreen extends ConsumerStatefulWidget {
  const SocialHubScreen({super.key});

  @override
  ConsumerState<SocialHubScreen> createState() => _SocialHubScreenState();
}

class _SocialHubScreenState extends ConsumerState<SocialHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        SocialService.instance.getForumPosts(),
        SocialService.instance.getStudyGroups(),
      ]);
      
      setState(() {
        _posts = results[0];
        _groups = results[1];
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
        title: Text(t(LTitle.socialHub, ref)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t(LExtra.forum, ref)),
            Tab(text: t(LExtra.studyGroups, ref)),
          ],
        ),
      ),
      body: _loading
          ? const PageSkeleton(type: 'dashboard')
          : TabBarView(
              controller: _tabController,
              children: [
                _buildForumTab(),
                _buildGroupsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tabController.index == 0 ? _createPost : _createGroup,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildForumTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return ModernCard(
            child: ListTile(
              title: Text(post['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post['content'], maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('by ${post['author']?['name'] ?? 'Unknown'}', style: const TextStyle(fontSize: 12)),
                ],
              ),
              trailing: ModernBadge(label: post['category'], color: Colors.blue),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return ModernCard(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.group)),
              title: Text(group['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${group['members']?['count'] ?? 0} members'),
              trailing: ElevatedButton(
                onPressed: () => _joinGroup(group['id']),
                child: const Text('Join'),
              ),
            ),
          );
        },
      ),
    );
  }

  void _createPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _CreatePostPage(),
        fullscreenDialog: true,
      ),
    ).then((result) {
      if (result == true) _loadData();
    });
  }

  void _createGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _CreateGroupPage(),
        fullscreenDialog: true,
      ),
    ).then((result) {
      if (result == true) _loadData();
    });
  }

  Future<void> _joinGroup(String groupId) async {
    await SocialService.instance.joinGroup(groupId);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _CreatePostPage extends ConsumerWidget {
  const _CreatePostPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(L.add, ref)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t(L.cancel, ref))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(decoration: const InputDecoration(labelText: 'Content'), maxLines: 3),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(t(L.submit, ref))),
        ],
      ),
    );
  }
}

class _CreateGroupPage extends ConsumerWidget {
  const _CreateGroupPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LChat.createGroup, ref)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t(L.cancel, ref))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(decoration: const InputDecoration(labelText: 'Group Name')),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(t(LChat.createGroup, ref))),
        ],
      ),
    );
  }
}
