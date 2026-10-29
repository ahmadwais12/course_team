import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('events')
          .select()
          .order('start_date', ascending: true);
      if (mounted) setState(() => _events = data);
    } catch (e) {
      if (mounted) setState(() => _events = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t(LModule.calendar, ref))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _events.isEmpty
                  ? ListView(
                      padding: AppSpacing.paddingLg,
                      children: [
                        _MonthSection(
                          month: 'No events',
                          events: [
                            _EventItem(
                              title: t(LCrud.noEventsFound, ref),
                              date: '',
                              type: '',
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    )
                  : _buildEventList(),
        ),
      ),
    );
  }

  Widget _buildEventList() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final event in _events) {
      final date = event['start_date']?.toString() ?? '';
      final monthYear = date.length >= 7 ? date.substring(0, 7) : 'Unknown';
      grouped.putIfAbsent(monthYear, () => []).add(event);
    }

    return ListView(
      padding: AppSpacing.paddingLg,
      children: grouped.entries.map((entry) {
        final monthLabel = _formatMonth(entry.key);
        return _MonthSection(
          month: monthLabel,
          events: entry.value.map((event) {
            final type = event['type']?.toString() ?? 'Event';
            return _EventItem(
              title: event['title']?.toString() ?? 'Untitled',
              date: _formatDate(event['start_date']?.toString()),
              type: type,
              color: _eventColor(type),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  String _formatMonth(String ym) {
    final parts = ym.split('-');
    if (parts.length != 2) return ym;
    final months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final m = int.tryParse(parts[1]) ?? 0;
    return '${m >= 1 && m <= 12 ? months[m] : parts[1]} ${parts[0]}';
  }

  String _formatDate(String? date) {
    if (date == null || date.length < 10) return date ?? '';
    return date.substring(0, 10);
  }

  Color _eventColor(String type) {
    switch (type.toLowerCase()) {
      case 'holiday':
        return Colors.blue;
      case 'exam':
        return Colors.orange;
      case 'event':
        return Colors.blue;
      default:
        return Colors.purple;
    }
  }
}

class _MonthSection extends StatelessWidget {
  final String month;
  final List<Widget> events;

  const _MonthSection({required this.month, required this.events});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(month, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        ...events,
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _EventItem extends StatelessWidget {
  final String title;
  final String date;
  final String type;
  final Color color;

  const _EventItem({
    required this.title,
    required this.date,
    required this.type,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              type == 'Holiday' ? Icons.event_available :
              type == 'Exam' ? Icons.quiz :
              Icons.event,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text(date, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(type, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
