import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/app_routes_all.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  List<Map<String, dynamic>> _settings = [];
  bool _isLoading = true;
  String? _tenantId;

  bool _maintenanceMode = false;
  bool _registrationEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  int _sessionTimeoutMinutes = 30;
  int _maxLoginAttempts = 5;
  String _defaultLanguage = 'en';
  String _defaultTimezone = 'UTC';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final profile = await Supabase.instance.client
          .from('users')
          .select('tenant_id')
          .eq('id', user!.id)
          .maybeSingle();
      final tenantId = profile?['tenant_id']?.toString();
      _tenantId = tenantId;

      final baseQuery = Supabase.instance.client.from('settings').select();
      final filteredQuery =
          tenantId != null ? baseQuery.eq('tenant_id', tenantId) : baseQuery;
      final data = await filteredQuery.order('key');
      if (mounted) {
        setState(() {
          _settings = List<Map<String, dynamic>>.from(data);
          _applySettings(_settings);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e')),
        );
      }
    }
  }

  void _applySettings(List<Map<String, dynamic>> data) {
    for (final s in data) {
      final key = s['key']?.toString() ?? '';
      final value = s['value'];
      switch (key) {
        case 'maintenance_mode':
          _maintenanceMode = value == true || value == 'true';
        case 'registration_enabled':
          _registrationEnabled = value != false && value != 'false';
        case 'email_notifications':
          _emailNotifications = value != false && value != 'false';
        case 'sms_notifications':
          _smsNotifications = value == true || value == 'true';
        case 'session_timeout_minutes':
          _sessionTimeoutMinutes =
              int.tryParse(value?.toString() ?? '') ?? 30;
        case 'max_login_attempts':
          _maxLoginAttempts = int.tryParse(value?.toString() ?? '') ?? 5;
        case 'default_language':
          _defaultLanguage = value?.toString() ?? 'en';
        case 'default_timezone':
          _defaultTimezone = value?.toString() ?? 'UTC';
      }
    }
  }

  String _encodeValue(dynamic value) {
    if (value is bool) return value ? 'true' : 'false';
    return value.toString();
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final encoded = _encodeValue(value);
      final existing = _settings.any((s) => s['key'] == key);
      final tenantId = _tenantId;
      var query = Supabase.instance.client
          .from('settings')
          .update({
            'value': encoded,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('key', key);
      if (tenantId != null) query = query.eq('tenant_id', tenantId);
      if (existing) {
        await query;
      } else {
        final payload = <String, dynamic>{
          'key': key,
          'value': encoded,
          'category': 'general',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (tenantId != null) payload['tenant_id'] = tenantId;
        await Supabase.instance.client.from('settings').insert(payload);
      }
      _loadSettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.superAdmin);
            }
          },
        ),
        title: const Text('System Settings'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await _saveSetting('maintenance_mode', _maintenanceMode);
              await _saveSetting('registration_enabled', _registrationEnabled);
              await _saveSetting('email_notifications', _emailNotifications);
              await _saveSetting('sms_notifications', _smsNotifications);
              await _saveSetting(
                  'session_timeout_minutes', _sessionTimeoutMinutes);
              await _saveSetting('max_login_attempts', _maxLoginAttempts);
              await _saveSetting('default_language', _defaultLanguage);
              await _saveSetting('default_timezone', _defaultTimezone);
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Settings saved')),
                );
              }
            },
            icon: const Icon(Icons.save_outlined),
            label: Text('Save All'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionHeader('General'),
                    _switchTile(
                      'Maintenance Mode',
                      'Put the system in maintenance mode',
                      Icons.build_circle_outlined,
                      Colors.orange,
                      _maintenanceMode,
                      (v) {
                        setState(() => _maintenanceMode = v);
                        _saveSetting('maintenance_mode', v);
                      },
                    ),
                    _switchTile(
                      'Registration Enabled',
                      'Allow new user registrations',
                      Icons.person_add_outlined,
                      Colors.green,
                      _registrationEnabled,
                      (v) {
                        setState(() => _registrationEnabled = v);
                        _saveSetting('registration_enabled', v);
                      },
                    ),
                    const Divider(height: 32),
                    _sectionHeader('Notifications'),
                    _switchTile(
                      'Email Notifications',
                      'Send email notifications for system events',
                      Icons.email_outlined,
                      Colors.blue,
                      _emailNotifications,
                      (v) {
                        setState(() => _emailNotifications = v);
                        _saveSetting('email_notifications', v);
                      },
                    ),
                    _switchTile(
                      'SMS Notifications',
                      'Send SMS notifications for critical alerts',
                      Icons.sms_outlined,
                      Colors.teal,
                      _smsNotifications,
                      (v) {
                        setState(() => _smsNotifications = v);
                        _saveSetting('sms_notifications', v);
                      },
                    ),
                    const Divider(height: 32),
                    _sectionHeader('Security'),
                    _numberTile(
                      'Session Timeout (minutes)',
                      'Auto-logout after inactivity',
                      Icons.timer_outlined,
                      Colors.red,
                      _sessionTimeoutMinutes,
                      (v) {
                        setState(() => _sessionTimeoutMinutes = v);
                        _saveSetting('session_timeout_minutes', v);
                      },
                    ),
                    _numberTile(
                      'Max Login Attempts',
                      'Lock account after failed attempts',
                      Icons.lock_outline,
                      Colors.purple,
                      _maxLoginAttempts,
                      (v) {
                        setState(() => _maxLoginAttempts = v);
                        _saveSetting('max_login_attempts', v);
                      },
                    ),
                    const Divider(height: 32),
                    _sectionHeader('Localization'),
                    _dropdownTile(
                      'Default Language',
                      'Language for new users',
                      Icons.language_rounded,
                      Colors.indigo,
                      _defaultLanguage,
                      {'en': 'English', 'prs': 'Dari', 'ps': 'Pashto'},
                      (v) {
                        setState(() => _defaultLanguage = v);
                        _saveSetting('default_language', v);
                      },
                    ),
                    _dropdownTile(
                      'Default Timezone',
                      'System-wide timezone',
                      Icons.access_time_outlined,
                      Colors.brown,
                      _defaultTimezone,
                      {
                        'UTC': 'UTC',
                        'Asia/Kabul': 'Asia/Kabul',
                        'Asia/Dubai': 'Asia/Dubai',
                        'America/New_York': 'America/New_York',
                        'Europe/London': 'Europe/London',
                      },
                      (v) {
                        setState(() => _defaultTimezone = v);
                        _saveSetting('default_timezone', v);
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _switchTile(String title, String subtitle, IconData icon,
      Color color, bool value, ValueChanged<bool> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _numberTile(String title, String subtitle, IconData icon,
      Color color, int value, ValueChanged<int> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: SizedBox(
          width: 100,
          child: TextField(
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: value.toString()),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null && parsed > 0) onChanged(parsed);
            },
          ),
        ),
      ),
    );
  }

  Widget _dropdownTile(String title, String subtitle, IconData icon,
      Color color, String value, Map<String, String> options,
      ValueChanged<String> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: DropdownButton<String>(
          value: value,
          items: options.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

