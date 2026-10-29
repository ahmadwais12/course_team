import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/providers/teacher_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class MessageParentsScreen extends ConsumerStatefulWidget {
  const MessageParentsScreen({super.key});

  @override
  ConsumerState<MessageParentsScreen> createState() =>
      _MessageParentsScreenState();
}

class _MessageParentsScreenState extends ConsumerState<MessageParentsScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messageParentsProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: t(LCrud.searchHintGeneric, ref),
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
                  final subject =
                      m['subject']?.toString().toLowerCase() ?? '';
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
                        Text('No messages found',
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
                      color: isRead ? null : Colors.blue[50],
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isRead ? Colors.grey : Colors.blue,
                          child: Text(
                            (msg['parent_name']?.toString() ?? '?')[0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(msg['parent_name']?.toString() ?? 'Unknown',
                                style: TextStyle(
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold)),
                            if (!isRead) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(msg['subject']?.toString() ?? ''),
                            Text('Student: ${msg['student_name'] ?? ''}'),
                          ],
                        ),
                        trailing: Text(_formatDate(msg['created_at'])),
                        onTap: () => _showMessageDetails(msg),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.invalidate(messageParentsProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
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
        icon: const Icon(Icons.message),
        label: const Text('Compose'),
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
    final diff = now.difference(dt);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showComposeDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _ComposeMessagePage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _showMessageDetails(Map<String, dynamic> msg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(msg['subject']?.toString() ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  'From: ${msg['parent_name']} (Parent of ${msg['student_name']})'),
              const SizedBox(height: 8),
              Text('Date: ${_formatDate(msg['created_at'])}',
                  style: TextStyle(color: Colors.grey[600])),
              const Divider(height: 32),
              Text(msg['message']?.toString() ?? ''),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Reply sent successfully')),
                  );
                },
                icon: const Icon(Icons.reply),
                label: const Text('Reply'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposeMessagePage extends ConsumerStatefulWidget {
  const _ComposeMessagePage();

  @override
  ConsumerState<_ComposeMessagePage> createState() => _ComposeMessagePageState();
}

class _ComposeMessagePageState extends ConsumerState<_ComposeMessagePage> {
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

  Future<void> _save() async {
    if (_parentCtrl.text.isEmpty ||
        _subjectCtrl.text.isEmpty ||
        _messageCtrl.text.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      await Supabase.instance.client
          .from('messages_parents')
          .insert({
            'parent_name': _parentCtrl.text,
            'student_name': _studentCtrl.text,
            'subject': _subjectCtrl.text,
            'message': _messageCtrl.text,
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent successfully')),
        );
        ref.invalidate(messageParentsProvider);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Message'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () { debugPrint('[message_parents_screen] Save button CLICKED'); _save(); },
            child: const Text('Send'),
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
                    border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: _studentCtrl,
                decoration: const InputDecoration(
                    labelText: 'Student Name',
                    border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: _messageCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder())),
          ],
        ),
      ),
    );
  }
}
