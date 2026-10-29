import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/announcement_model.dart';
import '../../widgets/base_panel_layout.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

final announcementsProvider = StreamProvider<List<Announcement>>((ref) {
  final supabase = Supabase.instance.client;
  return supabase
      .from('announcements')
      .stream(primaryKey: ['id'])
      .order('is_pinned', ascending: false)
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => Announcement.fromJson(json)).toList());
});

class AnnouncementManagementScreen extends ConsumerStatefulWidget {
  const AnnouncementManagementScreen({super.key});

  @override
  ConsumerState<AnnouncementManagementScreen> createState() => _AnnouncementManagementScreenState();
}

class _AnnouncementManagementScreenState extends ConsumerState<AnnouncementManagementScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  String? _selectedAudience;
  String? _selectedPriority;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isPinned = false;
  bool _isCreating = false;

  final List<String> _audiences = ['all', 'students', 'teachers', 'staff', 'parents'];
  final List<String> _priorities = ['low', 'normal', 'high', 'urgent'];
  final List<String> _statuses = ['draft', 'scheduled', 'published'];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _createAnnouncement() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(LAll.all_please_fill_in_title_and_content, ref))),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final supabase = Supabase.instance.client;
      final announcementData = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'audience': _selectedAudience ?? 'all',
        'priority': _selectedPriority ?? 'normal',
        'status': _selectedStatus ?? 'draft',
        'start_date': _startDate?.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
        'is_pinned': _isPinned,
        'views': 0,
        'created_by': supabase.auth.currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('announcements').insert(announcementData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaff.announcementCreated, ref))),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _contentController.clear();
    setState(() {
      _selectedAudience = null;
      _selectedPriority = null;
      _selectedStatus = null;
      _startDate = null;
      _endDate = null;
      _isPinned = false;
    });
  }

  Future<void> _publishAnnouncement(Announcement announcement) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('announcements').update({
        'status': 'published',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', announcement.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaff.announcementPublished, ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    }
  }

  Future<void> _archiveAnnouncement(Announcement announcement) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('announcements').update({
        'status': 'archived',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', announcement.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaff.announcementArchived, ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    }
  }

  Future<void> _togglePin(Announcement announcement) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('announcements').update({
        'is_pinned': !announcement.isPinned,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', announcement.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(announcement.isPinned ? 'Unpinned' : 'Pinned')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return Colors.blue;
      case 'draft':
        return Colors.grey;
      case 'scheduled':
        return Colors.blue;
      case 'archived':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(announcementsProvider);

    return BasePanelLayout(
      title: 'Announcement Management',
      children: [
        // Create Announcement Section
        Card(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Announcement',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 24.h),
                CustomTextField(
                  controller: _titleController,
                  label: 'Title',
                  hint: 'Announcement title',
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _contentController,
                  label: 'Content',
                  maxLines: 4,
                  hint: 'Announcement content',
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
initialValue: _selectedAudience,
                        decoration: const InputDecoration(
                          labelText: 'Audience',
                          border: OutlineInputBorder(),
                        ),
                        items: _audiences.map((audience) {
                          return DropdownMenuItem(
                            value: audience,
                            child: Text(audience.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedAudience = value);
                        },
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: DropdownButtonFormField<String>(
initialValue: _selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                        items: _priorities.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Text(priority.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedPriority = value);
                        },
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: DropdownButtonFormField<String>(
initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: _statuses.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedStatus = value);
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
                        onTap: _selectStartDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _startDate != null
                                ? DateFormat('MMM dd, yyyy').format(_startDate!)
                                : 'Select Date',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: InkWell(
                        onTap: _selectEndDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _endDate != null
                                ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                : 'Select Date',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: CheckboxListTile(
                        title: Text(t(LCrud.pin, ref)),
                        value: _isPinned,
                        onChanged: (value) {
                          setState(() => _isPinned = value ?? false);
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                GradientButton(
                  onPressed: _isCreating ? () {} : _createAnnouncement,
                  text: _isCreating ? 'Creating...' : 'Create Announcement',
                  isLoading: _isCreating,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.h),

        // Announcements List
        Card(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Announcements',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16.h),
                announcementsAsync.when(
                  data: (announcements) {
                    if (announcements.isEmpty) {
                      return Center(
                        child: Text(t(LAll.all_no_announcements_found, ref)),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: announcements.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final announcement = announcements[index];
                        return ListTile(
                          leading: Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              color: announcement.priorityColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              announcement.isPinned ? Icons.push_pin : Icons.campaign,
                              color: announcement.priorityColor,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  announcement.title,
                                  style: TextStyle(
                                    fontWeight: announcement.isPinned ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (announcement.isPinned)
                                const Icon(Icons.push_pin, size: 16, color: Colors.red),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                announcement.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(
                                      announcement.status ?? 'draft',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor: _getStatusColor(announcement.status ?? 'draft').withValues(alpha: 0.2),
                                    side: BorderSide.none,
                                    padding: EdgeInsets.zero,
                                    labelPadding: EdgeInsets.symmetric(horizontal: 8.w),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  SizedBox(width: 8.w),
                                  Chip(
                                    label: Text(
                                      announcement.audience ?? 'all',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor: Colors.blue.withValues(alpha: 0.2),
                                    side: BorderSide.none,
                                    padding: EdgeInsets.zero,
                                    labelPadding: EdgeInsets.symmetric(horizontal: 8.w),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  SizedBox(width: 8.w),
                                  Icon(Icons.visibility, size: 14.w, color: Colors.grey),
                                  SizedBox(width: 4.w),
                                  Text(
                                    '${announcement.views}',
                                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'publish':
                                  _publishAnnouncement(announcement);
                                  break;
                                case 'archive':
                                  _archiveAnnouncement(announcement);
                                  break;
                                case 'pin':
                                  _togglePin(announcement);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              if (announcement.isDraft || announcement.isScheduled)
                                PopupMenuItem(
                                  value: 'publish',
                                  child: Row(
                                    children: [
                                      Icon(Icons.publish),
                                      SizedBox(width: 8),
                                      Text(t(LCrud.publish, ref)),
                                    ],
                                  ),
                                ),
                              PopupMenuItem(
                                value: 'pin',
                                child: Row(
                                  children: [
                                    Icon(announcement.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
                                    SizedBox(width: 8),
                                    Text(announcement.isPinned ? 'Unpin' : 'Pin'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'archive',
                                child: Row(
                                  children: [
                                    Icon(Icons.archive, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text(t(LCrud.archive, ref)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const PageSkeleton(type: 'dashboard'),
                  error: (error, _) => Text(tt(LAll.all_error_x, ref, [error.toString()])),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
