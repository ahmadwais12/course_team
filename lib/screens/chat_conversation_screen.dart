import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/models/chat_models.dart';
import 'package:course_emis/providers/chat_providers.dart';
import 'package:course_emis/screens/chat_profile_screen.dart';

class ChatConversationScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatConversationScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatConversationScreen> createState() =>
      _ChatConversationScreenState();
}

class _ChatConversationScreenState
    extends ConsumerState<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatMessage? _replyingTo;
  String? _partnerUserId;
  String? _chatName;

  @override
  void initState() {
    super.initState();
    _loadPartner();
  }

  Future<void> _loadPartner() async {
    try {
      final service = ref.read(chatServiceProvider);
      final info = await service.fetchChatInfo(widget.chatId);
      if (mounted && info != null) {
        setState(() {
          _chatName = info['name']?.toString();
        });
      }
      final partnerId = await service.getDirectChatPartner(widget.chatId);
      if (mounted && partnerId != null) {
        setState(() => _partnerUserId = partnerId);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _buildHeaderAvatar(theme),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHeaderTitle(theme),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'info',
                  child: ListTile(
                      leading: Icon(Icons.info),
                      title: Text('Chat Info'),
                      contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(
                  value: 'media',
                  child: ListTile(
                      leading: Icon(Icons.photo_library),
                      title: Text('Media & Files'),
                      contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(
                  value: 'search',
                  child: ListTile(
                      leading: Icon(Icons.search),
                      title: Text('Search Messages'),
                      contentPadding: EdgeInsets.zero)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_replyingTo != null) _buildReplyBanner(theme),
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients &&
                      _scrollController.position.pixels >=
                          _scrollController.position.maxScrollExtent - 100) {
                    _scrollToBottom();
                  }
                });
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text('No messages yet',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Send a message to start the conversation.',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;
                    final showDateHeader =
                        _shouldShowDateHeader(messages, index);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDateHeader)
                          _buildDateHeader(theme, message.createdAt),
                        _buildMessageBubble(
                            context, theme, message, isMe, messages),
                      ],
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          _buildMessageInput(context, theme),
        ],
      ),
    );
  }

  Widget _buildReplyBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Container(width: 4, height: 40, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Replying to ${_replyingTo!.senderName ?? 'Unknown'}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 12)),
                Text(_replyingTo!.content ?? 'File',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _replyingTo = null)),
        ],
      ),
    );
  }

  bool _shouldShowDateHeader(List<ChatMessage> messages, int index) {
    if (index == 0) return true;
    final current = messages[index].createdAt;
    final previous = messages[index - 1].createdAt;
    return current.year != previous.year ||
        current.month != previous.month ||
        current.day != previous.day;
  }

  Widget _buildDateHeader(ThemeData theme, DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(day).inDays;

    String label;
    if (diff == 0) {
      label = 'Today';
    } else if (diff == 1) {
      label = 'Yesterday';
    } else {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      label = '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ThemeData theme,
      ChatMessage message, bool isMe, List<ChatMessage> messages) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                message.senderName?.substring(0, 1).toUpperCase() ?? 'U',
                style:
                    TextStyle(color: theme.colorScheme.onPrimary, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context, message),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16).copyWith(
                    bottomLeft: isMe
                        ? const Radius.circular(16)
                        : const Radius.circular(4),
                    bottomRight: isMe
                        ? const Radius.circular(4)
                        : const Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Text(
                        message.senderName ?? 'Unknown',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: theme.colorScheme.primary),
                      ),
                    if (message.replyTo != null)
                      _buildReplyIndicator(theme, message, messages),
                    _buildMessageContent(theme, message, isMe),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatMessageTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe
                                ? theme.colorScheme.onPrimary
                                    .withValues(alpha: 0.7)
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator(
      ThemeData theme, ChatMessage message, List<ChatMessage> messages) {
    ChatMessage? replied;
    if (message.replyTo != null) {
      for (final m in messages) {
        if (m.id == message.replyTo) {
          replied = m;
          break;
        }
      }
    }
    final replyText = replied?.content ??
        replied?.fileName ??
        (replied?.messageType == 'image'
            ? 'Photo'
            : replied?.messageType == 'voice' ||
                    replied?.messageType == 'audio'
                ? 'Voice message'
                : 'Replied message');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
      ),
      child: Text(replyText,
          style: const TextStyle(fontSize: 12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildMessageContent(
      ThemeData theme, ChatMessage message, bool isMe) {
    switch (message.messageType) {
      case 'text':
        return Text(message.content ?? '',
            style: TextStyle(
                color: isMe
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface));
      default:
        return Text(message.content ?? '',
            style: TextStyle(
                color: isMe
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface));
    }
  }

  Widget _buildHeaderAvatar(ThemeData theme) {
    final partnerId = _partnerUserId;
    final profileAsync = partnerId != null
        ? ref.watch(chatProfileProvider(partnerId))
        : null;
    final avatarUrl = profileAsync?.valueOrNull?['avatar_url']?.toString();
    return InkWell(
      onTap: () {
        if (partnerId == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatProfileScreen(userId: partnerId),
          ),
        );
      },
      borderRadius: BorderRadius.circular(30),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: theme.colorScheme.primary,
        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
            ? CachedNetworkImageProvider(avatarUrl)
            : null,
        child: avatarUrl == null || avatarUrl.isEmpty
            ? const Icon(Icons.person, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildHeaderTitle(ThemeData theme) {
    final partnerId = _partnerUserId;
    if (partnerId == null) {
      return Text(
        _chatName?.isNotEmpty == true ? _chatName! : 'Chat',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final profileAsync = ref.watch(chatProfileProvider(partnerId));
    final presence = ref.watch(chatPresenceProvider(partnerId));
    final name = profileAsync.valueOrNull?['full_name']?.toString() ??
        (_chatName?.isNotEmpty == true ? _chatName : 'Chat')!;
    final isOnline = presence.valueOrNull ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        Row(
          children: [
            Icon(
              isOnline ? Icons.circle : Icons.circle_outlined,
              size: 10,
              color: isOnline ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 11,
                color: isOnline ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageInput(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: _buildInputRow(theme),
    );
  }

  Widget _buildInputRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            decoration: InputDecoration(
              hintText: t(LCrud.typeMessage, ref),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            maxLines: null,
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          onPressed: _sendMessage,
          child: const Icon(Icons.send),
        ),
      ],
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final replyToId = _replyingTo?.id;
    setState(() => _replyingTo = null);

    try {
      final service = ref.read(chatServiceProvider);
      await service.sendTextMessage(
        groupId: widget.chatId,
        content: text,
        replyTo: replyToId,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Send failed: $e')));
      }
    }
  }

  void _showMessageOptions(BuildContext context, ChatMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.reply),
            title: Text(t(LChat.reply, ref)),
            onTap: () {
              Navigator.pop(ctx);
              setState(() => _replyingTo = message);
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: Text(t(LCrud.copy, ref)),
            onTap: () {
              Navigator.pop(ctx);
              final text = message.content ??
                  message.fileName ??
                  '${message.messageType} message';
              Clipboard.setData(ClipboardData(text: text));
            },
          ),
          ListTile(
            leading: const Icon(Icons.forward),
            title: Text(t(LMessage.forward, ref)),
            onTap: () {
              Navigator.pop(ctx);
              _forwardMessage(message);
            },
          ),
          if (message.senderId == _currentUserId) ...[
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(t(L.delete, ref),
                  style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _forwardMessage(ChatMessage message) async {
    final currentUserId = _currentUserId;
    List<ChatGroup> groups;
    try {
      final service = ref.read(chatServiceProvider);
      groups = await service.fetchGroups(currentUserId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not load chats: $e')));
      }
      return;
    }
    if (groups.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No chats to forward to')));
      }
      return;
    }
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Forward to',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final isCurrent = group.id == widget.chatId;
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(group.type == 'direct'
                        ? Icons.person
                        : Icons.groups),
                  ),
                  title: Text(group.name),
                  trailing: isCurrent
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (isCurrent) return;
                    try {
                      final service = ref.read(chatServiceProvider);
                      await service.sendTextMessage(
                        groupId: group.id,
                        content: message.content ?? '',
                      );
                      if (mounted) {
                        messenger.showSnackBar(SnackBar(
                            content:
                                Text('Forwarded to ${group.name}')));
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                            SnackBar(content: Text('Forward failed: $e')));
                      }
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'info':
      case 'media':
      case 'search':
        break;
    }
  }
}
