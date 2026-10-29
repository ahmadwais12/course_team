import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/widgets/modern_ui.dart';

class TimetableScreen extends ConsumerWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = [
      t(LDay.monday, ref), t(LDay.tuesday, ref), t(LDay.wednesday, ref),
      t(LDay.thursday, ref), t(LDay.friday, ref), t(LDay.saturday, ref),
    ];

    return Scaffold(
      appBar: ModernAppBar(title: t(LNav.timetable, ref), hasGradient: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
            child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: days.length,
          itemBuilder: (context, index) => _EnhancedDayCard(day: days[index], index: index),
        ),
      ),
      ),
      ),
    );
  }
}

class _EnhancedDayCard extends StatelessWidget {
  final String day;
  final int index;
  const _EnhancedDayCard({required this.day, required this.index});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.blue, Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.pink];
    final color = colors[index % colors.length];
    
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.8), color],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  day,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ClassItem(
                  time: '09:00 - 10:30',
                  subject: 'IELTS Speaking',
                  room: 'Room 101',
                  color: color,
                ),
                const SizedBox(height: 8),
                _ClassItem(
                  time: '11:00 - 12:30',
                  subject: 'TOEFL Writing',
                  room: 'Room 102',
                  color: color,
                ),
                const SizedBox(height: 8),
                _ClassItem(
                  time: '14:00 - 15:30',
                  subject: 'Business English',
                  room: 'Room 103',
                  color: color,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassItem extends StatelessWidget {
  final String time;
  final String subject;
  final String room;
  final Color color;

  const _ClassItem({
    required this.time,
    required this.subject,
    required this.room,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.access_time, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$time â€¢ $room',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
