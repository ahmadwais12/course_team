import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';

/// 1. Timeline Widget for Student Progress
class ProgressTimeline extends StatelessWidget {
  final List<(String, String, DateTime, bool)> steps;
  const ProgressTimeline({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;

        return IntrinsicHeight(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: step.$4 ? theme.colorScheme.primary : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: step.$4 
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: step.$4 ? theme.colorScheme.primary : Colors.grey[300],
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.$1,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: step.$4 ? theme.colorScheme.onSurface : Colors.grey[600],
                        ),
                      ),
                      Text(
                        step.$2,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      Text(
                        '${step.$3.year}-${step.$3.month}-${step.$3.day}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// 2. File Upload Widget
class FileUploadWidget extends ConsumerWidget {
  final String label;
  final VoidCallback onTap;
  final String? fileName;

  const FileUploadWidget({
    super.key,
    required this.label,
    required this.onTap,
    this.fileName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 2, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_upload_outlined, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(fileName ?? label, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            if (fileName != null)
              Text(t(LExtra.changeFile, ref), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

/// 3. Avatar / Profile UI Component
class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double radius;
  final bool isEditable;
  final VoidCallback? onEdit;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    required this.initials,
    this.radius = 40,
    this.isEditable = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null 
            ? Text(initials, style: TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.bold, color: theme.colorScheme.primary))
            : null,
        ),
        if (isEditable)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

/// 4. Custom Expansion Panel
class CustomExpansionTile extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final IconData? icon;

  const CustomExpansionTile({
    super.key,
    required this.title,
    required this.children,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: icon != null ? Icon(icon) : null,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        childrenPadding: const EdgeInsets.all(16),
        children: children,
      ),
    );
  }
}
