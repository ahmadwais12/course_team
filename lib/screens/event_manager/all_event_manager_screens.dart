import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class EventCalendarScreen extends StatelessWidget {
  const EventCalendarScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Event Calendar',
        tableName: 'events',
        icon: Icons.calendar_month_rounded,
        accentColor: Colors.blue,
        displayFields: ['title', 'start_date', 'end_date', 'status', 'location'],
      );
}

class VenuesScreen extends StatelessWidget {
  const VenuesScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Venues',
        tableName: 'event_venues',
        icon: Icons.place_rounded,
        accentColor: Colors.orange,
        displayFields: ['name', 'capacity', 'address', 'is_active'],
      );
}

class EventTasksScreen extends StatelessWidget {
  const EventTasksScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Event Tasks',
        tableName: 'staff_tasks',
        icon: Icons.task_alt_rounded,
        accentColor: Colors.blue,
        displayFields: ['title', 'status', 'due_date', 'staff_id'],
      );
}

class GuestListScreen extends StatelessWidget {
  const GuestListScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Guest List',
        tableName: 'event_registrations',
        icon: Icons.group_add_rounded,
        accentColor: Colors.teal,
        displayFields: ['user_id', 'status', 'event_id', 'registration_date'],
      );
}

class EventBudgetScreen extends StatelessWidget {
  const EventBudgetScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Event Budget',
        tableName: 'budgets',
        icon: Icons.account_balance_wallet_rounded,
        accentColor: Colors.pink,
        displayFields: ['category', 'allocated_amount', 'spent_amount', 'fiscal_year'],
      );
}

class EventVendorsScreen extends StatelessWidget {
  const EventVendorsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Event Vendors',
        tableName: 'suppliers',
        icon: Icons.business_center_rounded,
        accentColor: Colors.brown,
        displayFields: ['name', 'phone', 'email', 'is_active'],
      );
}
