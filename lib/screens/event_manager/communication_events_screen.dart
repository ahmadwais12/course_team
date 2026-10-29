import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart' as model;
import '../../widgets/base_panel_layout.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/skeleton_loader.dart';

final eventsProvider = StreamProvider<List<model.Event>>((ref) {
  final supabase = Supabase.instance.client;
  return supabase
      .from('events')
      .stream(primaryKey: ['id'])
      .order('start_date', ascending: true)
      .map((data) => data.map((json) => model.Event.fromJson(json)).toList());
});

class CommunicationEventsScreen extends ConsumerStatefulWidget {
  const CommunicationEventsScreen({super.key});

  @override
  ConsumerState<CommunicationEventsScreen> createState() =>
      _CommunicationEventsScreenState();
}

class _CommunicationEventsScreenState
    extends ConsumerState<CommunicationEventsScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  String? _selectedEventType;
  String? _selectedTargetAudience;
  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  bool _isCreating = false;

  final List<String> _eventTypes = [
    'Workshop',
    'Seminar',
    'Conference',
    'Cultural',
    'Sports',
    'Academic',
    'Social',
    'Career Fair',
    'Alumni Meet',
    'Other'
  ];

  final List<String> _targetAudiences = [
    'All',
    'Students',
    'Staff',
    'Parents',
    'Alumni',
    'Public'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _eventTime = picked);
    }
  }

  Future<void> _createEvent() async {
    if (_titleController.text.isEmpty || _eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in required fields')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final supabase = Supabase.instance.client;

      // Combine date and time
      final eventDateTime = _eventTime != null
          ? DateTime(
              _eventDate!.year,
              _eventDate!.month,
              _eventDate!.day,
              _eventTime!.hour,
              _eventTime!.minute,
            )
          : _eventDate!;

      final eventData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'event_type': _selectedEventType ?? 'Other',
        'target_audience': _selectedTargetAudience ?? 'All',
        'event_date': eventDateTime.toIso8601String(),
        'location': _locationController.text.trim(),
        'max_participants': int.tryParse(_maxParticipantsController.text),
        'created_by': supabase.auth.currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'upcoming',
      };

      await supabase.from('events').insert(eventData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully')),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _maxParticipantsController.clear();
    setState(() {
      _selectedEventType = null;
      _selectedTargetAudience = null;
      _eventDate = null;
      _eventTime = null;
    });
  }

  Future<void> _cancelEvent(String eventId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('events').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', eventId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _sendNotification(String eventId, String eventTitle) async {
    try {
      final supabase = Supabase.instance.client;

      // Create notification for target audience
      await supabase.from('notifications').insert({
        'title': 'New Event: $eventTitle',
        'message':
            'A new event has been scheduled. Check the events page for details.',
        'type': 'event',
        'target_audience': _selectedTargetAudience ?? 'All',
        'reference_id': eventId,
        'reference_type': 'event',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getEventTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'workshop':
        return Colors.blue;
      case 'seminar':
        return Colors.purple;
      case 'conference':
        return Colors.orange;
      case 'cultural':
        return Colors.pink;
      case 'sports':
        return Colors.blue;
      case 'academic':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);

    return BasePanelLayout(
      title: 'Communication & Events Management',
      children: [
        // Stats
        Row(
          children: [
            _buildStatCard('Upcoming', '8', Colors.blue),
            SizedBox(width: 16.w),
            _buildStatCard('Today', '2', Colors.blue),
            SizedBox(width: 16.w),
            _buildStatCard('This Week', '5', Colors.orange),
            SizedBox(width: 16.w),
            _buildStatCard('Past', '12', Colors.grey),
          ],
        ),
        SizedBox(height: 24.h),

        // Create Event
        Card(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Event',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 24.h),
                CustomTextField(
                  controller: _titleController,
                  label: 'Event Title',
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  maxLines: 3,
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
initialValue: _selectedEventType,
                        decoration: const InputDecoration(
                          labelText: 'Event Type',
                          border: OutlineInputBorder(),
                        ),
                        items: _eventTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedEventType = value);
                        },
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: DropdownButtonFormField<String>(
initialValue: _selectedTargetAudience,
                        decoration: const InputDecoration(
                          labelText: 'Target Audience',
                          border: OutlineInputBorder(),
                        ),
                        items: _targetAudiences.map((audience) {
                          return DropdownMenuItem(
                            value: audience,
                            child: Text(audience),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedTargetAudience = value);
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Event Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _eventDate != null
                                ? DateFormat('MMM dd, yyyy').format(_eventDate!)
                                : 'Select Date',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: InkWell(
                        onTap: _selectTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Event Time',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _eventTime != null
                                ? _eventTime!.format(context)
                                : 'Select Time',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _locationController,
                  label: 'Location',
                  hint: 'Venue or Online link',
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _maxParticipantsController,
                  label: 'Max Participants (Optional)',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 24.h),
                GradientButton(
                  onPressed: _isCreating ? () {} : _createEvent,
                  text: _isCreating ? 'Creating...' : 'Create Event',
                  isLoading: _isCreating,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.h),

        // Events List
        Card(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Events Calendar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16.h),
                eventsAsync.when(
                  data: (events) {
                    if (events.isEmpty) {
                      return const Center(
                        child: Text('No events scheduled'),
                      );
                    }

                    final upcoming = events
                        .where((e) =>
                            e.status.toLowerCase() != 'cancelled' &&
                            e.status.toLowerCase() != 'completed')
                        .toList();

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: upcoming.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final model.Event event = upcoming[index];
                        final eventDate = event.startDate;
                        final isPast = eventDate.isBefore(DateTime.now());

                        return ListTile(
                          leading: Container(
                            width: 60.w,
                            height: 60.w,
                            decoration: BoxDecoration(
                              color: _getEventTypeColor(event.type)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('MMM').format(eventDate),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: _getEventTypeColor(event.type),
                                  ),
                                ),
                                Text(
                                  '${eventDate.day}',
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: _getEventTypeColor(event.type),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          title: Text(
                            event.title,
                            style: TextStyle(
                              decoration:
                                  isPast ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.access_time,
                                      size: 14.w, color: Colors.grey),
                                  SizedBox(width: 4.w),
                                  Text(
                                    DateFormat('h:mm a').format(eventDate),
                                    style: TextStyle(fontSize: 12.sp),
                                  ),
                                  SizedBox(width: 16.w),
                                  Icon(Icons.location_on,
                                      size: 14.w, color: Colors.grey),
                                  SizedBox(width: 4.w),
                                  Text(
                                    event.location,
                                    style: TextStyle(fontSize: 12.sp),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(
                                      event.type,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor:
                                        _getEventTypeColor(event.type)
                                            .withValues(alpha: 0.2),
                                    side: BorderSide.none,
                                    padding: EdgeInsets.zero,
                                    labelPadding:
                                        EdgeInsets.symmetric(horizontal: 8.w),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  SizedBox(width: 8.w),
                                  Chip(
                                    label: Text(
                                      event.status,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor:
                                        (event.status.toLowerCase() ==
                                                    'cancelled'
                                                ? Colors.red
                                                : Colors.blue)
                                            .withValues(alpha: 0.2),
                                    side: BorderSide.none,
                                    padding: EdgeInsets.zero,
                                    labelPadding:
                                        EdgeInsets.symmetric(horizontal: 8.w),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'notify':
                                  _sendNotification(event.id, event.title);
                                  break;
                                case 'cancel':
                                  _cancelEvent(event.id);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'notify',
                                child: Row(
                                  children: [
                                    Icon(Icons.notifications),
                                    SizedBox(width: 8),
                                    Text('Send Notification'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'cancel',
                                child: Row(
                                  children: [
                                    Icon(Icons.cancel, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Cancel Event'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const PageSkeleton(type: 'dashboard'),
                  error: (error, _) => Text('Error: $error'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event,
                  color: color,
                  size: 20.w,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
