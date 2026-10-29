import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/models/lms_content.dart';
import 'package:course_emis/providers/feedback_provider.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackAsync = ref.watch(feedbackNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t(LTitle.feedbackComplaints, ref))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFeedbackDialog(context, ref),
        icon: const Icon(Icons.feedback),
        label: const Text('Submit Feedback'),
      ),
      body: Padding(
        padding: AppSpacing.paddingLg,
        child: feedbackAsync.when(
          data: (feedbacks) => feedbacks.isEmpty
              ? Center(
                  child: Text('No feedback submitted',
                      style: Theme.of(context).textTheme.bodyLarge))
              : ListView.separated(
                  itemCount: feedbacks.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final feedback = feedbacks[index];
                    return _FeedbackCard(feedback: feedback);
                  },
                ),
          loading: () => const ListSkeleton(itemCount: 5),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Future<void> _showFeedbackDialog(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _SubmitFeedbackPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) ref.invalidate(feedbackNotifierProvider);
  }
}

class _SubmitFeedbackPage extends ConsumerStatefulWidget {
  const _SubmitFeedbackPage();

  @override
  ConsumerState<_SubmitFeedbackPage> createState() => _SubmitFeedbackPageState();
}

class _SubmitFeedbackPageState extends ConsumerState<_SubmitFeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdCtl = TextEditingController();
  final _messageCtl = TextEditingController();
  FeedbackType _type = FeedbackType.general;
  bool _isAnonymous = false;

  @override
  void dispose() {
    _studentIdCtl.dispose();
    _messageCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Feedback'),
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
              controller: _studentIdCtl,
              decoration: InputDecoration(labelText: t(LExtra.studentId, ref)),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<FeedbackType>(
              initialValue: _type,
              items: FeedbackType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
              decoration: InputDecoration(labelText: t(LCrud.category, ref)),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _messageCtl,
              decoration: InputDecoration(labelText: t(LMessage.cMessage, ref)),
              maxLines: 3,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              title: const Text('Submit Anonymously'),
              value: _isAnonymous,
              onChanged: (v) => setState(() => _isAnonymous = v ?? false),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () { debugPrint('[feedback_screen] Save button CLICKED'); _save(); },
              child: const Text('Submit'),
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
    final feedback = Feedback(
      id: 'feedback_${now.millisecondsSinceEpoch}',
      studentId: _studentIdCtl.text,
      type: _type,
      message: _messageCtl.text,
      status: FeedbackStatus.pending,
      isAnonymous: _isAnonymous,
      createdAt: now,
    );
    ref.read(feedbackNotifierProvider.notifier).addFeedback(feedback);
    Navigator.pop(context, true);
  }
}

class _FeedbackCard extends StatelessWidget {
  final Feedback feedback;

  const _FeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = feedback.status == FeedbackStatus.resolved
        ? Colors.blue
        : feedback.status == FeedbackStatus.reviewed
            ? Colors.blue
            : Colors.orange;

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.2),
                child: Icon(
                  feedback.status == FeedbackStatus.resolved
                      ? Icons.check_circle
                      : feedback.status == FeedbackStatus.reviewed
                          ? Icons.visibility
                          : Icons.pending,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(feedback.type.name,
                        style: theme.textTheme.titleMedium),
                    Text(feedback.status.name,
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (feedback.isAnonymous)
                const Chip(
                    label: Text('Anonymous'),
                    labelStyle: TextStyle(fontSize: 10)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(feedback.message, style: theme.textTheme.bodyMedium),
          if (feedback.response != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Response:', style: theme.textTheme.labelSmall),
                  Text(feedback.response!, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
