import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});
  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  final _sb = Supabase.instance.client;
  Map<String, Map<String, bool>> _prefs = {};
  List<String> _types = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    debugPrint('[NotificationPrefs] _load Ã¢â‚¬â€ loading preferences...');
    try {
      final userId = _sb.auth.currentUser?.id;
      debugPrint('[NotificationPrefs] _load Ã¢â‚¬â€ userId=$userId');
      if (userId == null) {
        debugPrint('[NotificationPrefs] _load Ã¢â‚¬â€ no user logged in');
        return;
      }

      final typesFuture = _sb
          .from('notification_types')
          .select('name')
          .eq('is_active', true)
          .order('name', ascending: true);

      final prefsFuture = _sb
          .from('notification_preferences')
          .select()
          .eq('user_id', userId);

      final results = await Future.wait([typesFuture, prefsFuture]);
      final typesData = results[0] as List;
      final prefsData = results[1] as List;

      debugPrint('[NotificationPrefs] _load Ã¢â‚¬â€ types count=${typesData.length}, existing prefs count=${prefsData.length}');

      final types = typesData
          .map((r) => r['name'] as String)
          .where((n) => n.isNotEmpty)
          .toList();

      final Map<String, Map<String, bool>> loaded = {};
      for (final row in prefsData) {
        loaded[row['notification_type']] = {
          'in_app': row['in_app_enabled'] == true,
          'push': row['push_enabled'] == true,
          'email': row['email_enabled'] == true,
          'sms': row['sms_enabled'] == true,
        };
      }
      for (final t in types) {
        loaded.putIfAbsent(t, () => {'in_app': true, 'push': true, 'email': false, 'sms': false});
      }
      setState(() {
        _types = types;
        _prefs = loaded;
        _loading = false;
      });
      debugPrint('[NotificationPrefs] _load Ã¢â‚¬â€ done, ${_types.length} types loaded');
    } catch (e) {
      debugPrint('[NotificationPrefs] _load Ã¢â‚¬â€ error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    debugPrint('[NotificationPrefs] _save Ã¢â‚¬â€ saving ${_prefs.length} type preferences...');
    setState(() => _saving = true);
    try {
      final userId = _sb.auth.currentUser?.id;
      final tenantId = _sb.auth.currentUser?.userMetadata?['tenant_id'];
      debugPrint('[NotificationPrefs] _save Ã¢â‚¬â€ userId=$userId, tenantId=$tenantId');
      if (userId == null) {
        debugPrint('[NotificationPrefs] _save Ã¢â‚¬â€ no user logged in, aborting');
        return;
      }
      for (final entry in _prefs.entries) {
        debugPrint('[NotificationPrefs] _save Ã¢â‚¬â€ upserting type="${entry.key}"');
        await _sb.from('notification_preferences').upsert({
          'user_id': userId,
          'notification_type': entry.key,
          'in_app_enabled': entry.value['in_app'] ?? true,
          'push_enabled': entry.value['push'] ?? true,
          'email_enabled': entry.value['email'] ?? false,
          'sms_enabled': entry.value['sms'] ?? false,
          if (tenantId != null) 'tenant_id': tenantId,
        }, onConflict: 'user_id,notification_type');
      }
      debugPrint('[NotificationPrefs] _save Ã¢â‚¬â€ all saved successfully');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LCrud.savedSuccessfully, ref))),
        );
      }
    } catch (e) {
      debugPrint('[NotificationPrefs] _save Ã¢â‚¬â€ error: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  String _label(String type) =>
      type.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LTitle.notificationPrefs, ref)),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(onPressed: () { debugPrint('[notification_preferences_screen] Save button CLICKED'); _save(); }, child: Text(t(L.save, ref))),
        ],
      ),
      body: _loading
          ? const PageSkeleton(type: 'settings')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _types.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final type = _types[i];
                final p = _prefs[type] ?? {'in_app': true, 'push': true, 'email': false, 'sms': false};
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_label(type), style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _ToggleChip(
                            label: t(LExtra.inApp, ref),
                            value: p['in_app'] ?? true,
                            onChanged: (v) => setState(() => _prefs[type]!['in_app'] = v),
                          ),
                          _ToggleChip(
                            label: t(LExtra.push, ref),
                            value: p['push'] ?? true,
                            onChanged: (v) => setState(() => _prefs[type]!['push'] = v),
                          ),
                          _ToggleChip(
                            label: t(LExtra.emailPref, ref),
                            value: p['email'] ?? false,
                            onChanged: (v) => setState(() => _prefs[type]!['email'] = v),
                          ),
                          _ToggleChip(
                            label: 'SMS',
                            value: p['sms'] ?? false,
                            onChanged: (v) => setState(() => _prefs[type]!['sms'] = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleChip({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      checkmarkColor: theme.colorScheme.primary,
    );
  }
}
