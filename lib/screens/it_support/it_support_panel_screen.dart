import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/it_support_model.dart';
import '../../widgets/base_panel_layout.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

final supportTicketsProvider = StreamProvider<List<ITSupportTicket>>((ref) {
  final supabase = Supabase.instance.client;
  return supabase
      .from('it_support_tickets')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((data) =>
          data.map((json) => ITSupportTicket.fromJson(json)).toList());
});

class ITSupportPanelScreen extends ConsumerStatefulWidget {
  const ITSupportPanelScreen({super.key});

  @override
  ConsumerState<ITSupportPanelScreen> createState() =>
      _ITSupportPanelScreenState();
}

class _ITSupportPanelScreenState extends ConsumerState<ITSupportPanelScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedPriority;
  String? _selectedCategory;
  bool _isCreating = false;

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];
  final List<String> _categories = [
    'Hardware',
    'Software',
    'Network',
    'Email',
    'Login/Access',
    'Printer',
    'WiFi',
    'Other'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTicket() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(LCrud.fillRequiredFields, ref))),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final supabase = Supabase.instance.client;
      final ticket = ITSupportTicket(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority ?? 'Medium',
        category: _selectedCategory ?? 'Other',
        status: 'Open',
        requesterId: supabase.auth.currentUser?.id ?? '',
        createdAt: DateTime.now(),
      );

      await supabase.from('it_support_tickets').insert(ticket.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaff.ticketCreated, ref))),
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
    setState(() {
      _selectedPriority = null;
      _selectedCategory = null;
    });
  }

  Future<void> _updateTicketStatus(String ticketId, String status) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('it_support_tickets').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        'resolved_at':
            status == 'Resolved' ? DateTime.now().toIso8601String() : null,
      }).eq('id', ticketId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaff.ticketStatusUpdated, ref))),
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

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow.shade700;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'in progress':
        return Colors.orange;
      case 'resolved':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(supportTicketsProvider);

    return BasePanelLayout(
      title: 'IT Support & System Management',
      children: [
        // Stats Cards
        Row(
          children: [
            _buildStatCard('Open Tickets', '12', Colors.blue),
            SizedBox(width: 16.w),
            _buildStatCard('In Progress', '5', Colors.orange),
            SizedBox(width: 16.w),
            _buildStatCard('Resolved Today', '8', Colors.blue),
            SizedBox(width: 16.w),
            _buildStatCard('Critical', '2', Colors.red),
          ],
        ),
        SizedBox(height: 24.h),

        // Create Ticket Section
        Card(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    'Create Support Ticket',
                    style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 24.h),
                CustomTextField(
                  controller: _titleController,
                  label: 'Title',
                  hint: 'Brief summary of the issue',
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  maxLines: 4,
                  hint: 'Detailed description of the problem',
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
initialValue: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: t(LCrud.category, ref),
                          border: const OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategory = value);
                        },
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: DropdownButtonFormField<String>(
initialValue: _selectedPriority,
                        decoration: InputDecoration(
                          labelText: t(LPanelUI.priority, ref),
                          border: OutlineInputBorder(),
                        ),
                        items: _priorities.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Text(priority),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedPriority = value);
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                GradientButton(
                  onPressed: _isCreating ? () {} : _createTicket,
                  text: _isCreating ? 'Creating...' : 'Create Ticket',
                  isLoading: _isCreating,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.h),

        // Tickets List
        Card(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support Tickets',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16.h),
                ticketsAsync.when(
                  data: (tickets) {
                    if (tickets.isEmpty) {
                      return Center(
                        child: Text(t(LStaff.noTickets, ref)),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tickets.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        return ExpansionTile(
                          leading: Container(
                            width: 12.w,
                            height: 12.w,
                            decoration: BoxDecoration(
                              color: _getPriorityColor(ticket.priority),
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(ticket.title),
                          subtitle: Row(
                            children: [
                              Chip(
                                label: Text(
                                  ticket.status,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                backgroundColor: _getStatusColor(ticket.status)
                                    .withValues(alpha: 0.2),
                                side: BorderSide.none,
                                padding: EdgeInsets.zero,
                                labelPadding:
                                    EdgeInsets.symmetric(horizontal: 8.w),
                                visualDensity: VisualDensity.compact,
                              ),
                              SizedBox(width: 8.w),
                              if (ticket.category != null)
                                Text(
                                  ticket.category!,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Text(
                            '${ticket.createdAt.day}/${ticket.createdAt.month}/${ticket.createdAt.year}',
                            style:
                                TextStyle(fontSize: 12.sp, color: Colors.grey),
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(16.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Description:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(ticket.description),
                                  SizedBox(height: 16.h),
                                  if (ticket.status != 'Resolved' &&
                                      ticket.status != 'Closed') ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => _updateTicketStatus(
                                              ticket.id, 'In Progress'),
                                          child: Text(t(LCrud.markInProgress, ref)),
                                        ),
                                        SizedBox(width: 8.w),
                                        ElevatedButton(
                                          onPressed: () => _updateTicketStatus(
                                              ticket.id, 'Resolved'),
                                          child: Text(t(LCrud.resolve, ref)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
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
                  Icons.support_agent,
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
