import 'package:flutter/material.dart';
import 'package:course_emis/core/responsive/responsive.dart';

/// Section title widget for panel screens
class PanelSectionTitle extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry padding;

  const PanelSectionTitle({
    super.key,
    required this.title,
    this.padding = const EdgeInsets.only(bottom: 12, top: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
      ),
    );
  }
}

/// Stat item data for PanelStatGrid
typedef StatItem = (String label, String value, IconData icon, Color color, String subtitle);

/// Grid of stat cards for panel screens
class PanelStatGrid extends StatelessWidget {
  final List<StatItem> stats;

  const PanelStatGrid({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = context.gridColumns().toInt();
    return GridView.count(
      crossAxisCount: crossAxisCount > 4 ? 4 : crossAxisCount.clamp(2, 4),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: context.isDesktop ? 1.6 : 1.3,
      children: stats.map((stat) => _StatCard(item: stat)).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final (label, value, icon, color, subtitle) = item;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Action item data for PanelActionGrid
typedef ActionItem = (String label, IconData icon, Color color, VoidCallback onTap);

/// Grid of action buttons for panel screens
class PanelActionGrid extends StatelessWidget {
  final List<ActionItem> actions;

  const PanelActionGrid({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = (context.gridColumns() + 1).toInt().clamp(3, 6);
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: context.isDesktop ? 1.0 : 0.85,
      children: actions.map((action) => _ActionButton(item: action)).toList(),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final ActionItem item;

  const _ActionButton({required this.item});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color, onTap) = item;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
