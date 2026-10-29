import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/providers/teacher_providers.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class MessageParentsScreenRealtime extends ConsumerStatefulWidget {
  const MessageParentsScreenRealtime({super.key});

  @override
  ConsumerState<MessageParentsScreenRealtime> createState() =>
      _MessageParentsScreenRealtimeState();
}

class _MessageParentsScreenRealtimeState
    extends ConsumerState<MessageParentsScreenRealtime> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messageParentsStreamProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search messages...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                var filtered = messages.where((m) {
                  final parent =
                      m['parent_name']?.toString().toLowerCase() ?? '';
                  final student =
                      m['student_name']?.toString().toLowerCase() ?? '';
                  final subject = m['subject']?.toString().toLowerCase() ?? '';
                  final searchLower = searchQuery.toLowerCase();
                  return parent.contains(searchLower) ||
                      student.contains(searchLower) ||
                      subject.contains(searchLower);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.message_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(t(LAll.all_no_messages_found, ref),
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final msg = filtered[index];
                    final isRead = msg['is_read'] ?? false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _showDetails(msg),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isRead
                                        ? Colors.grey[300]
                                        : Colors.blue[100],
                                    child: Icon(
                                      isRead ? Icons.mail_outline : Icons.mail,
                                      color: isRead ? Colors.grey : Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg['parent_name']?.toString() ??
                                              'Unknown',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isRead
                                                ? Colors.grey[700]
                                                : Colors.black,
                                          ),
                                        ),
                                        Text(
                                          '${msg['student_name']} • ${msg['subject']}',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatDate(msg['created_at']),
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 12),
                                  ),
                                ],
                              ),
                              if (!isRead) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'New Message',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const PageSkeleton(type: 'chat'),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(tt(LAll.all_error_x, ref, [error.toString()])),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.invalidate(messageParentsStreamProvider),
                      icon: const Icon(Icons.refresh),
                      label: Text(t(L.retry, ref)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showComposeDialog(),
        icon: const Icon(Icons.edit),
        label: Text(t(LAll.all_compose, ref)),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    DateTime dt;
    if (date is String) {
      dt = DateTime.parse(date);
    } else if (date is DateTime) {
      dt = date;
    } else {
      return '';
    }
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showDetails(Map<String, dynamic> msg) {
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.person, color: Colors.blue[700]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['parent_name']?.toString() ?? 'Unknown',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Parent of ${msg['student_name']}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text(
                msg['subject']?.toString() ?? 'No Subject',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                msg['message']?.toString() ?? '',
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t(LAll.all_reply_feature, ref))),
                        );
                      },
                      icon: const Icon(Icons.reply),
                      label: Text(t(LChat.reply, ref)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t(LMessage.markAsRead, ref))),
                        );
                      },
                      icon: const Icon(Icons.done_all),
                      label: Text(t(LAll.all_mark_read, ref)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComposeDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _ComposeMessageRTPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }
}

class _ComposeMessageRTPage extends ConsumerStatefulWidget {
  const _ComposeMessageRTPage();

  @override
  ConsumerState<_ComposeMessageRTPage> createState() => _ComposeMessageRTPageState();
}

class _ComposeMessageRTPageState extends ConsumerState<_ComposeMessageRTPage> {
  final _parentCtrl = TextEditingController();
  final _studentCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _parentCtrl.dispose();
    _studentCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final parent = _parentCtrl.text;
    final student = _studentCtrl.text;
    final subject = _subjectCtrl.text;
    final message = _messageCtrl.text;
    if (parent.isEmpty || subject.isEmpty || message.isEmpty) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client
          .from('messages_parents')
          .insert({
            'parent_name': parent,
            'student_name': student,
            'subject': subject,
            'message': message,
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LAll.all_message_sent_successfully, ref))),
        );
        ref.invalidate(messageParentsStreamProvider);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_failed_to_send_message_x, ref, [e.toString()]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LAll.all_compose_message, ref)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _send,
            child: Text(t(LAll.all_send, ref)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _parentCtrl,
              decoration: const InputDecoration(
                labelText: 'Parent Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _studentCtrl,
              decoration: const InputDecoration(
                labelText: 'Student Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
