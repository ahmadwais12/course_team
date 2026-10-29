import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/lms_content.dart';
import 'package:course_emis/providers/lms_provider.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class LMSScreen extends ConsumerWidget {
  const LMSScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(lmsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t(LAll.all_learning_management, ref))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContentDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(t(LStaffCMS.addContent, ref)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: contentAsync.when(
          data: (contents) => contents.isEmpty
              ? Center(
                  child: Text(t(LAll.all_no_content_available, ref),
                      style: Theme.of(context).textTheme.bodyLarge))
              : ListView.separated(
                  itemCount: contents.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final content = contents[index];
                    return _ContentCard(content: content);
                  },
                ),
          loading: () => const ListSkeleton(itemCount: 5),
          error: (err, stack) =>
              Center(child: Text(tt(LAll.all_error_x, ref, [err.toString()]))),
        ),
      ),
      ),
      ),
    );
  }

  Future<void> _showContentDialog(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _AddContentPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) ref.invalidate(lmsNotifierProvider);
  }
}

class _AddContentPage extends ConsumerStatefulWidget {
  const _AddContentPage();

  @override
  ConsumerState<_AddContentPage> createState() => _AddContentPageState();
}

class _AddContentPageState extends ConsumerState<_AddContentPage> {
  final _formKey = GlobalKey<FormState>();
  final _classIdCtl = TextEditingController();
  final _titleCtl = TextEditingController();
  final _urlCtl = TextEditingController();
  final _orderCtl = TextEditingController(text: '1');
  ContentType _type = ContentType.lesson;
  bool _isPublished = true;

  @override
  void dispose() {
    _classIdCtl.dispose();
    _titleCtl.dispose();
    _urlCtl.dispose();
    _orderCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LStaffCMS.addContent, ref)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t(L.cancel, ref))),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _classIdCtl,
              decoration: const InputDecoration(labelText: 'Class ID'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<ContentType>(
              initialValue: _type,
              items: ContentType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
              decoration: const InputDecoration(labelText: 'Content Type'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _titleCtl,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _urlCtl,
              decoration: const InputDecoration(labelText: 'URL (optional)'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _orderCtl,
              decoration: const InputDecoration(labelText: 'Order'),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              title: Text(t(LAll.all_published, ref)),
              value: _isPublished,
              onChanged: (v) => setState(() => _isPublished = v ?? true),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () { debugPrint('[lms_screen] Save button CLICKED'); _save(); },
              child: Text(t(L.add, ref)),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final ref = this.ref;
    final now = DateTime.now();
    final content = LMSContent(
      id: 'content_${now.millisecondsSinceEpoch}',
      classId: _classIdCtl.text,
      type: _type,
      title: _titleCtl.text,
      url: _urlCtl.text.isEmpty ? null : _urlCtl.text,
      order: int.parse(_orderCtl.text),
      isPublished: _isPublished,
      createdAt: now,
    );
    ref.read(lmsNotifierProvider.notifier).addContent(content);
    Navigator.pop(context, true);
  }
}

class _ContentCard extends ConsumerWidget {
  final LMSContent content;

  const _ContentCard({required this.content});

  IconData _getIcon() {
    switch (content.type) {
      case ContentType.video:
        return Icons.play_circle;
      case ContentType.pdf:
        return Icons.picture_as_pdf;
      case ContentType.assignment:
        return Icons.assignment;
      case ContentType.quiz:
        return Icons.quiz;
      default:
        return Icons.book;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            child: Icon(_getIcon(), color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(content.title, style: theme.textTheme.titleMedium),
                Text(tt(LAll.all_x_order_x, ref,
                    [content.type.name, '${content.order}']),
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (!content.isPublished)
            Chip(
                label: Text(t(LMessage.draft, ref)),
                labelStyle: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
