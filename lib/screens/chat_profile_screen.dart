import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:course_emis/providers/chat_providers.dart';

class ChatProfileScreen extends ConsumerWidget {
  final String userId;

  const ChatProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(chatProfileProvider(userId));
    final presenceAsync = ref.watch(chatPresenceProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }
          final name = profile['full_name']?.toString() ?? 'Unknown';
          final email = profile['email']?.toString() ?? 'Not available';
          final role = profile['role']?.toString() ?? 'User';
          final avatarUrl = profile['avatar_url']?.toString();
          final phone = profile['phone']?.toString();
          final address = profile['address']?.toString();
          final nid = profile['nid']?.toString();
          final bloodGroup = profile['blood_group']?.toString();
          final maritalStatus = profile['marital_status']?.toString();
          final nationality = profile['nationality']?.toString();
          final religion = profile['religion']?.toString();
          final fatherName = profile['father_name']?.toString();
          final motherName = profile['mother_name']?.toString();
          final tazkiraNumber = profile['tazkira_number']?.toString();
          final passportId = profile['passport_id']?.toString();
          final emergencyName =
              profile['emergency_contact_name']?.toString();
          final emergencyPhone =
              profile['emergency_contact_phone']?.toString();
          final joinedAt = profile['created_at']?.toString();
          final joinedDate = joinedAt != null && joinedAt.length >= 10
              ? joinedAt.substring(0, 10)
              : null;
          final isOnline = presenceAsync.valueOrNull ?? false;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        _buildAvatar(theme, avatarUrl, name, role),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? Colors.green
                                  : theme.colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: theme.colorScheme.surface, width: 3),
                            ),
                            child: isOnline
                                ? const Icon(Icons.check_circle,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(name,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOnline ? Icons.circle : Icons.circle_outlined,
                          size: 12,
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: isOnline ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        role.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Contact Information',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow(
                          Icons.email_rounded, 'Email', email, theme),
                      const Divider(height: 20),
                      _buildInfoRow(Icons.person_rounded, 'Role',
                          role.replaceAll('_', ' '), theme),
                      if (nid != null) ...[
                        const Divider(height: 20),
                        _buildInfoRow(Icons.tag_rounded, 'ID', '#$nid', theme),
                      ],
                      if (phone != null) ...[
                        const Divider(height: 20),
                        _buildInfoRow(
                            Icons.phone_rounded, 'Phone', phone, theme),
                      ],
                      if (address != null) ...[
                        const Divider(height: 20),
                        _buildInfoRow(Icons.location_on_rounded, 'Address',
                            address, theme),
                      ],
                      if (joinedDate != null) ...[
                        const Divider(height: 20),
                        _buildInfoRow(Icons.calendar_today_rounded, 'Joined',
                            joinedDate, theme),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Personal Information',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (fatherName != null) ...[
                        _buildInfoRow(Icons.man_rounded, "Father's Name",
                            fatherName, theme),
                        const Divider(height: 20),
                      ],
                      if (motherName != null) ...[
                        _buildInfoRow(Icons.woman_rounded, "Mother's Name",
                            motherName, theme),
                        const Divider(height: 20),
                      ],
                      if (bloodGroup != null) ...[
                        _buildInfoRow(Icons.bloodtype_rounded, 'Blood Group',
                            bloodGroup, theme),
                        const Divider(height: 20),
                      ],
                      if (maritalStatus != null) ...[
                        _buildInfoRow(
                            Icons.favorite_rounded,
                            'Marital Status',
                            maritalStatus[0].toUpperCase() +
                                maritalStatus.substring(1),
                            theme),
                        const Divider(height: 20),
                      ],
                      if (nationality != null) ...[
                        _buildInfoRow(Icons.flag_rounded, 'Nationality',
                            nationality, theme),
                        const Divider(height: 20),
                      ],
                      if (religion != null) ...[
                        _buildInfoRow(Icons.church_rounded, 'Religion',
                            religion, theme),
                        const Divider(height: 20),
                      ],
                      if (tazkiraNumber != null) ...[
                        _buildInfoRow(Icons.badge_outlined, 'Tazkira Number',
                            tazkiraNumber, theme),
                        const Divider(height: 20),
                      ],
                      if (passportId != null) ...[
                        _buildInfoRow(Icons.airplane_ticket_rounded,
                            'Passport ID', passportId, theme),
                        const Divider(height: 20),
                      ],
                      if (emergencyName != null) ...[
                        _buildInfoRow(Icons.emergency_rounded,
                            'Emergency Contact', emergencyName, theme),
                        const Divider(height: 20),
                      ],
                      if (emergencyPhone != null) ...[
                        _buildInfoRow(Icons.emergency_share_rounded,
                            'Emergency Phone', emergencyPhone, theme),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, String? avatarUrl, String name,
      String role) {
    final fallbackIcon = switch (role) {
      'super_admin' => Icons.admin_panel_settings_rounded,
      'admin' => Icons.verified_user_rounded,
      'teacher' => Icons.school_rounded,
      'student' => Icons.menu_book_rounded,
      'guardian' || 'parent' => Icons.family_restroom_rounded,
      'accountant' => Icons.account_balance_rounded,
      'librarian' => Icons.library_books_rounded,
      'receptionist' => Icons.receipt_long_rounded,
      _ => Icons.person_rounded,
    };
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF67E8F9)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) =>
                    Icon(fallbackIcon, size: 60, color: Colors.white),
              )
            : Icon(fallbackIcon, size: 60, color: Colors.white),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
