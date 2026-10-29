import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:course_emis/app_routes_all.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/models/chat_models.dart';
import 'package:course_emis/providers/chat_providers.dart';
import 'package:course_emis/screens/chat_profile_screen.dart';
import 'package:course_emis/widgets/base_panel_layout.dart';

enum _ChatInboxTab { direct, groups }

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  _ChatInboxTab _selectedTab = _ChatInboxTab.direct;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _currentRole {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['role']?.toString().toLowerCase() ?? 'staff';
  }

  bool get _canCreateGroups =>
      _currentRole == 'teacher' || _currentRole == 'admin';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncGroups = ref.watch(chatGroupsProvider);

    return BasePanelLayout(
      title: t(LTitle.chat, ref),
      actions: [
        if (_canCreateGroups)
          IconButton(
            icon: const Icon(Icons.group_add_rounded),
            tooltip: t(LChat.createGroup, ref),
            onPressed: () => _createNewGroup(context),
          ),
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          tooltip: t(LChat.chatSettings, ref),
          onPressed: () => context.go(AppRoutes.settings),
        ),
      ],
      children: [
        asyncGroups.when(
          data: (groups) {
            final direct =
                groups.where((g) => g.type == 'direct').toList();
            final groupChats =
                groups.where((g) => g.type != 'direct').toList();
            final filteredDirect = _filterChats(direct);
            final filteredGroup = _filterChats(groupChats);

            return Column(
              children: [
                _buildOverviewCard(
                    theme, _currentRole, direct.length, groupChats.length),
                const SizedBox(height: 16),
                _buildCapabilityRow(theme),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: t(LChat.searchChats, ref),
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                ),
                const SizedBox(height: 16),
                _buildTabSelector(
                    theme, filteredDirect.length, filteredGroup.length),
                const SizedBox(height: 16),
                if (_selectedTab == _ChatInboxTab.direct)
                  _buildChatSection(
                    context,
                    theme,
                    title: t(LChat.directMessages, ref),
                    subtitle: 'Use direct chat for one-to-one communication.',
                    chats: filteredDirect,
                    emptyTitle: 'No direct conversations',
                    emptySubtitle: t(LChat.yourConversations, ref),
                  )
                else
                  _buildChatSection(
                    context,
                    theme,
                    title: t(LChat.groupMessages, ref),
                    subtitle: 'Class groups and team channels.',
                    chats: filteredGroup,
                    emptyTitle: 'No groups available',
                    emptySubtitle:
                        'Class groups and channels will appear here.',
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Center(child: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    ThemeData theme,
    String role,
    int directCount,
    int groupCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Communication Hub',
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Chat, share files, and collaborate in real-time.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildOverviewStat(
                    label: t(LChat.direct, ref), value: '$directCount',
                    icon: Icons.chat_bubble_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewStat(
                    label: t(LChat.groups, ref), value: '$groupCount',
                    icon: Icons.groups_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewStat(
                    label: t(LChat.realtime, ref), value: 'Active',
                    icon: Icons.bolt_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildCapabilityRow(ThemeData theme) {
    final capabilities = [
      ('Direct DM', Icons.person_rounded, Colors.blue),
      ('Group Chat', Icons.group_rounded, Colors.deepPurple),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: capabilities
          .map((item) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: (item.$3 as Color).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.$2,
                        color: item.$3, size: 18),
                    const SizedBox(width: 8),
                    Text(item.$1,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildTabSelector(ThemeData theme, int directCount, int groupCount) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(theme,
                selected: _selectedTab == _ChatInboxTab.direct,
                label: t(LChat.direct, ref), count: directCount,
                onTap: () =>
                    setState(() => _selectedTab = _ChatInboxTab.direct)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton(theme,
                selected: _selectedTab == _ChatInboxTab.groups,
                label: t(LChat.groups, ref), count: groupCount,
                onTap: () =>
                    setState(() => _selectedTab = _ChatInboxTab.groups)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(ThemeData theme,
      {required bool selected, required String label, required int count, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(tt(LAll.all_s392, ref, ['$count']),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatSection(
    BuildContext context,
    ThemeData theme, {
    required String title,
    required String subtitle,
    required List<ChatGroup> chats,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72))),
        const SizedBox(height: 14),
        if (chats.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Icon(Icons.forum_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                const SizedBox(height: 12),
                Text(emptyTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(emptySubtitle, textAlign: TextAlign.center),
              ],
            ),
          )
        else
          ...chats.map((chat) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildChatTile(context, theme, chat),
              )),
      ],
    );
  }

  Widget _buildChatTile(BuildContext context, ThemeData theme, ChatGroup chat) {
    final isDirect = chat.type == 'direct';
    final preview = chat.lastMessage?.content ??
        chat.lastMessage?.fileName ??
        'No messages yet';
    final partnerIdAsync = isDirect
        ? ref.watch(chatPartnerIdProvider(chat.id))
        : null;
    final partnerId = partnerIdAsync?.valueOrNull;
    final partnerProfileAsync = partnerId != null
        ? ref.watch(chatProfileProvider(partnerId))
        : null;
    final partnerProfile = partnerProfileAsync?.valueOrNull;
    final displayName = isDirect && partnerProfile != null
        ? (partnerProfile['full_name']?.toString() ?? chat.name)
        : chat.name;
    final displaySubtitle = isDirect
        ? (partnerProfile?['role']?.toString().replaceAll('_', ' ') ??
            'Direct conversation')
        : (chat.description ?? 'Group chat');

    return InkWell(
      onTap: () => context.push('${AppRoutes.chat}/${chat.id}'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () {
                if (partnerId != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatProfileScreen(userId: partnerId),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(30),
              child: _ChatTileAvatar(chat: chat, isDirect: isDirect),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(displayName,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      Text(
                        _formatTime(
                            chat.lastMessage?.createdAt ?? chat.updatedAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displaySubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium),
                      ),
                      if ((chat.unreadCount ?? 0) > 0) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(tt(LAll.all_s392, ref, [
                            '${chat.unreadCount}'
                          ]),
                              style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) => _handleChatAction(context, value, chat),
              itemBuilder: (context) => [
                PopupMenuItem(value: 'open', child: Text(t(LChat.openConversation, ref))),
                PopupMenuItem(value: 'mute', child: Text(t(LChat.muteNotifications, ref))),
                if (!isDirect)
                  PopupMenuItem(value: 'leave', child: Text(t(LChat.leaveGroup, ref))),
                PopupMenuItem(value: 'settings', child: Text(t(LChat.chatSettings, ref))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<ChatGroup> _filterChats(List<ChatGroup> chats) {
    if (_searchQuery.isEmpty) return chats;
    final query = _searchQuery.toLowerCase();
    return chats
        .where((c) =>
            c.name.toLowerCase().contains(query) ||
            (c.description ?? '').toLowerCase().contains(query))
        .toList();
  }

  String _formatTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays}d';
    if (difference.inHours > 0) return '${difference.inHours}h';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m';
    return 'now';
  }

  void _handleChatAction(BuildContext context, String action, ChatGroup chat) {
    switch (action) {
      case 'open':
        context.push('${AppRoutes.chat}/${chat.id}');
        break;
      case 'mute':
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(
                content: Text(
                    tt(LAll.all_notifications_muted_for_x, ref, [chat.name]))));
        break;
      case 'leave':
        _leaveGroup(context, chat);
        break;
      case 'settings':
        context.go(AppRoutes.settings);
        break;
    }
  }

  void _createNewGroup(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => const _CreateGroupPage(), fullscreenDialog: true),
    );
    if (result == true) {
      ref.invalidate(chatGroupsProvider);
    }
  }

  void _leaveGroup(BuildContext context, ChatGroup chat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(LChat.leaveGroup, ref)),
        content: Text(
            '${t(LAll.all_are_you_sure_you_want_to_leave, ref)} "${chat.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t(L.cancel, ref))),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final service = ref.read(chatServiceProvider);
                await service.leaveGroup(chat.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              tt(LAll.all_you_left_x, ref, [chat.name]))));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              tt(LAll.all_error_x, ref, [e.toString()]))));
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t(L.delete, ref)),
          ),
        ],
      ),
    );
  }
}

class _ChatTileAvatar extends ConsumerWidget {
  final ChatGroup chat;
  final bool isDirect;

  const _ChatTileAvatar({required this.chat, required this.isDirect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final partnerIdAsync = isDirect
        ? ref.watch(chatPartnerIdProvider(chat.id))
        : null;
    final partnerId = partnerIdAsync?.valueOrNull;
    final presence = partnerId != null
        ? ref.watch(chatPresenceProvider(partnerId))
        : null;
    final isOnline = presence?.valueOrNull ?? false;
    final profileAsync = partnerId != null
        ? ref.watch(chatProfileProvider(partnerId))
        : null;
    final avatarUrl = profileAsync?.valueOrNull?['avatar_url']?.toString();

    final avatar = CircleAvatar(
      radius: 26,
      backgroundColor: isDirect
          ? theme.colorScheme.primary.withValues(alpha: 0.12)
          : theme.colorScheme.secondary.withValues(alpha: 0.14),
      backgroundImage:
          avatarUrl != null && avatarUrl.isNotEmpty && isDirect
              ? CachedNetworkImageProvider(avatarUrl)
              : null,
      child: avatarUrl == null || avatarUrl.isEmpty || !isDirect
          ? Icon(
              isDirect ? Icons.person_rounded : Icons.groups_rounded,
              color: isDirect
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondary,
            )
          : null,
    );

    if (!isDirect) return avatar;

    return Stack(
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.surface, width: 2),
            ),
            child: isOnline
                ? const Icon(Icons.check_circle, size: 10, color: Colors.white)
                : null,
          ),
        ),
      ],
    );
  }
}

class _CreateGroupPage extends ConsumerStatefulWidget {
  const _CreateGroupPage();

  @override
  ConsumerState<_CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends ConsumerState<_CreateGroupPage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim().isEmpty
        ? 'New Group'
        : _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    setState(() => _isSaving = true);
    try {
      final service = ref.read(chatServiceProvider);
      await service.createGroup(
          name: name,
          type: 'group',
          description: desc.isNotEmpty ? desc : null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name created successfully')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LChat.createGroup, ref)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () { debugPrint('[chat_screen] Save button CLICKED'); _save(); },
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(t(L.add, ref)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                  labelText: t(LChat.groupName, ref),
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                  labelText: t(LCrud.description, ref),
                  border: const OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }
}
