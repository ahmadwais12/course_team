import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/motion.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final IconData? icon;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null)
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
        if (icon != null) const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              if (subtitle != null)
                Text(subtitle!, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class InfoBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  const InfoBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = (color ?? theme.colorScheme.primary).withValues(alpha: 0.1);
    final fg = color ?? theme.colorScheme.primary;
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, color: fg, size: 14),
          if (icon != null) const SizedBox(width: 6),
          Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class LabeledValue extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;
  final CrossAxisAlignment crossAxisAlignment;

  const LabeledValue({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
    this.labelStyle,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(label, style: labelStyle ?? theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(value, style: valueStyle ?? theme.textTheme.titleMedium),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(message, style: theme.textTheme.bodySmall),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(actionText!)),
          ],
        ],
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;
  final bool pressable;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.paddingLg,
    this.borderRadius,
    this.onTap,
    this.pressable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.lg);
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: radius,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
    if (!pressable) return box;
    return Pressable(
      borderRadius: radius as BorderRadius?,
      onTap: onTap,
      child: box,
    );
  }
}

class VSpace extends StatelessWidget {
  final double size;
  const VSpace(this.size, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(height: size);
}

class HSpace extends StatelessWidget {
  final double size;
  const HSpace(this.size, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(width: size);
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? trendLabel;
  final double? progress;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.trendLabel,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: accent),
          ),
          const HSpace(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelSmall),
                const VSpace(6),
                Text(value, style: theme.textTheme.titleLarge),
                if (trendLabel != null || progress != null) const VSpace(6),
                if (trendLabel != null)
                  Text(trendLabel!, style: theme.textTheme.bodySmall),
                if (progress != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: theme.dividerColor.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;
  final VoidCallback? onClose;

  const AppBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = color ?? theme.colorScheme.primary;
    final bg = fg.withValues(alpha: 0.08);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const HSpace(AppSpacing.sm),
          Expanded(child: Text(message, style: TextStyle(color: fg))),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close, color: fg),
            ),
        ],
      ),
    );
  }
}

class TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final Color? color;
  final IconData? icon;

  const TimelineItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotColor = color ?? theme.colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 40,
              color: theme.dividerColor.withValues(alpha: 0.3),
            ),
          ],
        ),
        const HSpace(AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: dotColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(icon, color: dotColor, size: 16),
                    ),
                  if (icon != null) const HSpace(8),
                  Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
                  Text(time, style: theme.textTheme.labelSmall),
                ],
              ),
              const VSpace(6),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class AppTable<T> extends StatefulWidget {
  final List<String> columns;
  final List<T> rows;
  final Widget Function(BuildContext, T) rowBuilder;
  final int pageSize;

  const AppTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.rowBuilder,
    this.pageSize = 10,
  });

  @override
  State<AppTable<T>> createState() => _AppTableState<T>();
}

class _AppTableState<T> extends State<AppTable<T>> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final start = _page * widget.pageSize;
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    final pageRows = widget.rows.sublist(start, end);

    return AppCard(
      pressable: false,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.columns
                  .map((c) => Container(
                        width: 160,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Text(c, style: Theme.of(context).textTheme.labelMedium),
                      ))
                  .toList(),
            ),
          ),
          const Divider(height: 1),
          ...pageRows.map((r) => widget.rowBuilder(context, r)),
          const VSpace(AppSpacing.md),
          Consumer(
            builder: (context, ref, _) => Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _page > 0
                      ? () => setState(() => _page -= 1)
                      : null,
                  child: Text(t(L.back, ref)),
                ),
                const HSpace(AppSpacing.sm),
                OutlinedButton(
                  onPressed: end < widget.rows.length
                      ? () => setState(() => _page += 1)
                      : null,
                  child: Text(t(L.next, ref)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MapCardPlaceholder extends ConsumerWidget {
  final double height;
  const MapCardPlaceholder({super.key, this.height = 220});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AppCard(
      pressable: false,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        alignment: Alignment.center,
        child: Text(t(LExtra.mapPlaceholder, ref), style: theme.textTheme.bodyMedium),
      ),
    );
  }
}
