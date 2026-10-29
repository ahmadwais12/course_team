import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:course_emis/theme.dart';

class Skeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const Skeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.dividerColor.withValues(alpha: 0.25),
      highlightColor: theme.dividerColor.withValues(alpha: 0.08),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class SkeletonAvatar extends StatelessWidget {
  final double size;
  const SkeletonAvatar({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Skeleton(width: size, height: size, borderRadius: size / 2);
  }
}

class SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  const SkeletonLine({super.key, this.width = double.infinity, this.height = 14});

  @override
  Widget build(BuildContext context) => Skeleton(width: width, height: height);
}

class SkeletonParagraph extends StatelessWidget {
  final int lines;
  final double lineHeight;
  final double lastLineWidthFactor;

  const SkeletonParagraph({
    super.key,
    this.lines = 3,
    this.lineHeight = 14,
    this.lastLineWidthFactor = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (i) {
        final isLast = i == lines - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: i < lines - 1 ? 10 : 0),
          child: SkeletonLine(
            width: isLast ? double.infinity * lastLineWidthFactor : double.infinity,
            height: lineHeight,
          ),
        );
      }),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Widget? child;

  const SkeletonCard({super.key, this.margin, this.padding, this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Shimmer.fromColors(
        baseColor: theme.dividerColor.withValues(alpha: 0.25),
        highlightColor: theme.dividerColor.withValues(alpha: 0.08),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: child ?? const SkeletonParagraph(),
        ),
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  final double avatarSize;
  const SkeletonListTile({super.key, this.avatarSize = 40});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SkeletonAvatar(size: avatarSize),
        const SizedBox(width: 12),
        const Expanded(
          child: SkeletonParagraph(lines: 2, lineHeight: 12),
        ),
      ],
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double avatarSize;
  const SkeletonList({super.key, this.itemCount = 5, this.avatarSize = 40});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (i) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16,
            top: 8, bottom: i < itemCount - 1 ? 8 : 0,
          ),
          child: SkeletonListTile(avatarSize: avatarSize),
        ),
      ),
    );
  }
}

class SkeletonTableRow extends StatelessWidget {
  final int columns;
  const SkeletonTableRow({super.key, this.columns = 4});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(
          columns,
          (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < columns - 1 ? 12 : 0),
              child: SkeletonLine(height: 14),
            ),
          ),
        ),
      ),
    );
  }
}

class SkeletonTable extends StatelessWidget {
  final int columns;
  final int rows;
  const SkeletonTable({super.key, this.columns = 4, this.rows = 6});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: theme.dividerColor.withValues(alpha: 0.25),
        highlightColor: theme.dividerColor.withValues(alpha: 0.08),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: SkeletonTableRow(columns: columns),
            ),
            const SizedBox(height: 4),
            ...List.generate(rows, (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SkeletonTableRow(columns: columns),
            )),
          ],
        ),
      ),
    );
  }
}

class SkeletonStatsGrid extends StatelessWidget {
  final int itemCount;
  const SkeletonStatsGrid({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: List.generate(itemCount, (_) {
          return SizedBox(
            width: (MediaQuery.of(context).size.width - 44) / 2,
            child: Shimmer.fromColors(
              baseColor: theme.dividerColor.withValues(alpha: 0.25),
              highlightColor: theme.dividerColor.withValues(alpha: 0.08),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: 32, height: 32, borderRadius: 8),
                    const SizedBox(height: 12),
                    SkeletonLine(width: 80, height: 22),
                    const SizedBox(height: 6),
                    SkeletonLine(height: 12),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class SkeletonFormField extends StatelessWidget {
  final double inputHeight;
  const SkeletonFormField({super.key, this.inputHeight = 48});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonLine(width: 100, height: 12),
        const SizedBox(height: 8),
        Skeleton(height: inputHeight),
      ],
    );
  }
}

class SkeletonForm extends StatelessWidget {
  final int fields;
  const SkeletonForm({super.key, this.fields = 4});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...List.generate(fields, (i) => Padding(
            padding: EdgeInsets.only(bottom: i < fields - 1 ? 20 : 0),
            child: const SkeletonFormField(),
          )),
          const SizedBox(height: 8),
          Skeleton(height: 48, borderRadius: AppRadius.md),
        ],
      ),
    );
  }
}

class SkeletonDetailPage extends StatelessWidget {
  const SkeletonDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Skeleton(height: 200, borderRadius: 0),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 240, height: 24),
                const SizedBox(height: 8),
                SkeletonLine(width: 160, height: 16),
                const SizedBox(height: 24),
                const SkeletonParagraph(lines: 5, lineHeight: 14),
                const SizedBox(height: 20),
                const SkeletonParagraph(lines: 4, lineHeight: 14, lastLineWidthFactor: 0.4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          const SkeletonStatsGrid(itemCount: 4),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonCard(child: SkeletonParagraph(lines: 3)),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonCard(
              child: SkeletonList(itemCount: 3, avatarSize: 36),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
