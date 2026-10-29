import 'package:flutter/material.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class ReturnBookScreen extends StatelessWidget {
  const ReturnBookScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Return Book',
        tableName: 'book_issues',
        icon: Icons.assignment_return_rounded,
        accentColor: Colors.blue,
        displayFields: ['book_id', 'student_id', 'status', 'due_date', 'return_date'],
      );
}

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Catalog',
        tableName: 'library_books',
        icon: Icons.library_books_rounded,
        accentColor: Colors.indigo,
        displayFields: ['title', 'author', 'category', 'status', 'available_quantity'],
      );
}

class MembershipsScreen extends StatelessWidget {
  const MembershipsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Memberships',
        tableName: 'library_members',
        icon: Icons.badge_rounded,
        accentColor: Colors.orange,
        displayFields: [
          'membership_number',
          'membership_type',
          'status',
          'expiry_date',
        ],
      );
}

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Reservations',
        tableName: 'reservations',
        icon: Icons.bookmark_added_rounded,
        accentColor: Colors.pink,
        displayFields: ['member_id', 'status', 'reservation_date', 'expiry_date'],
      );
}

class FineManagementScreen extends StatelessWidget {
  const FineManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdaptiveDataPage(
        title: 'Fine Management',
        tableName: 'book_issues',
        icon: Icons.payments_rounded,
        accentColor: Colors.red,
        displayFields: ['student_id', 'fine_amount', 'status', 'due_date'],
      );
}
