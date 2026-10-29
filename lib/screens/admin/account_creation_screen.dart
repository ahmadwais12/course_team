import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class AccountCreationScreen extends ConsumerStatefulWidget {
  const AccountCreationScreen({super.key});

  @override
  ConsumerState<AccountCreationScreen> createState() =>
      _AccountCreationScreenState();
}

class _AccountCreationScreenState
    extends ConsumerState<AccountCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _tazkiraCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String _selectedRole = 'student';
  Map<String, dynamic>? _selectedDepartment;
  Map<String, dynamic>? _selectedProgram;
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _programs = [];
  bool _isLoading = false;
  bool _loadingDeps = true;
  bool _loadingPrograms = true;
  bool _obscurePassword = true;

  final List<Map<String, dynamic>> _roles = [
    {
      'id': 'student',
      'label': 'Student',
      'icon': Icons.school,
      'desc': 'Course enrollment & academics'
    },
    {
      'id': 'guardian',
      'label': 'Guardian',
      'icon': Icons.family_restroom,
      'desc': 'Parent / guardian access'
    },
    {
      'id': 'teacher',
      'label': 'Teacher',
      'icon': Icons.badge,
      'desc': 'Teaching & course delivery'
    },
    {
      'id': 'staff',
      'label': 'Staff',
      'icon': Icons.person,
      'desc': 'General staff operations'
    },
    {
      'id': 'admin',
      'label': 'Admin',
      'icon': Icons.admin_panel_settings,
      'desc': 'Tenant-level administration'
    },
    {
      'id': 'hr_manager',
      'label': 'HR Manager',
      'icon': Icons.group,
      'desc': 'Human resources management'
    },
    {
      'id': 'accountant',
      'label': 'Accountant',
      'icon': Icons.account_balance,
      'desc': 'Finance & accounting'
    },
    {
      'id': 'librarian',
      'label': 'Librarian',
      'icon': Icons.local_library,
      'desc': 'Library management'
    },
    {
      'id': 'receptionist',
      'label': 'Receptionist',
      'icon': Icons.desk,
      'desc': 'Front desk & reception'
    },
    {
      'id': 'it_support',
      'label': 'IT Support',
      'icon': Icons.support_agent,
      'desc': 'Technical support'
    },
    {
      'id': 'inventory_manager',
      'label': 'Inventory Mgr',
      'icon': Icons.inventory,
      'desc': 'Inventory management'
    },
    {
      'id': 'maintenance',
      'label': 'Maintenance',
      'icon': Icons.build,
      'desc': 'Facility maintenance'
    },
    {
      'id': 'event_manager',
      'label': 'Event Manager',
      'icon': Icons.event,
      'desc': 'Event coordination'
    },
    {
      'id': 'complaint_manager',
      'label': 'Complaint Mgr',
      'icon': Icons.assignment_late,
      'desc': 'Complaint handling'
    },
    {
      'id': 'academic_support',
      'label': 'Academic Support',
      'icon': Icons.psychology,
      'desc': 'Academic assistance'
    },
    {
      'id': 'super_admin',
      'label': 'Super Admin',
      'icon': Icons.shield,
      'desc': 'Full platform access'
    },
  ];

  static const _studentRoles = {'student'};
  static const _employeeRoles = {
    'teacher',
    'staff',
    'admin',
    'super_admin',
    'hr_manager',
    'accountant',
    'librarian',
    'receptionist',
    'it_support',
    'inventory_manager',
    'maintenance',
    'event_manager',
    'complaint_manager',
    'academic_support',
  };

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadPrograms();
  }

  Future<void> _loadDepartments() async {
    try {
      final data = await Supabase.instance.client
          .from('departments')
          .select('id, name')
          .eq('active', true)
          .order('name');
      if (mounted) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(data);
          _loadingDeps = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDeps = false);
    }
  }

  Future<void> _loadPrograms() async {
    try {
      final data = await Supabase.instance.client
          .from('programs')
          .select('id, name')
          .eq('status', 'active')
          .order('name');
      if (mounted) {
        setState(() {
          _programs = List<Map<String, dynamic>>.from(data);
          _loadingPrograms = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPrograms = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _tazkiraCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  bool get _isStudentRole => _studentRoles.contains(_selectedRole);
  bool get _isEmployeeRole => _employeeRoles.contains(_selectedRole);

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final adminSession = Supabase.instance.client.auth.currentSession;
    final adminAccessToken = adminSession?.accessToken;
    final adminRefreshToken = adminSession?.refreshToken;
    if (adminAccessToken == null || adminRefreshToken == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(t(
                  LAll.all_your_session_has_expired_please_sign_in_again,
                  ref))),
        );
      }
      return;
    }

    final creatorId = Supabase.instance.client.auth.currentUser?.id;
    String? tenantId;
    try {
      if (creatorId != null) {
        final creatorProfile = await Supabase.instance.client
            .from('users')
            .select('tenant_id')
            .eq('id', creatorId)
            .maybeSingle();
        tenantId = creatorProfile?['tenant_id']?.toString();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tt(LAll.all_could_not_verify_your_tenant_x, ref,
                  [e.toString()]))),
        );
      }
      return;
    }
    if (_selectedRole != 'super_admin' && tenantId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Your account has no tenant assigned. Contact a super admin.')),
        );
      }
      return;
    }

    Future<AuthResponse> restoreAdminSession() => Supabase.instance.client.auth
        .setSession(
          "{\"access_token\":\"$adminAccessToken\",\"refresh_token\":\"$adminRefreshToken\"}",
        )
        .timeout(const Duration(seconds: 15));

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        data: {
          'full_name': _fullNameCtrl.text.trim(),
          'role': _selectedRole,
        },
      ).timeout(const Duration(seconds: 30));

      final user = response.user;
      if (user == null) throw Exception('Failed to create user');

      // The authenticated profile policy permits this insert using the signUp
      // session, so saving does not wait for a session restore.
      await Supabase.instance.client.from('users').insert({
        'id': user.id,
        'tenant_id': _selectedRole == 'super_admin' ? null : tenantId,
        'full_name': _fullNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'tazkira_number': _tazkiraCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'role': _selectedRole,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Restore admin session before the UI resets, otherwise the router
      // still sees the newly-created user's session and may redirect to login.
      await restoreAdminSession();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_getRoleLabel(_selectedRole)} account created successfully'),
            backgroundColor: Colors.black,
          ),
        );
        _resetForm();
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(tt(LAll.all_auth_error_x, ref, [e.message]))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tt(LAll.all_failed_to_create_account_x, ref,
                  [e.toString()]))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _emailCtrl.clear();
    _passwordCtrl.clear();
    _fullNameCtrl.clear();
    _phoneCtrl.clear();
    _tazkiraCtrl.clear();
    _addressCtrl.clear();
    setState(() {
      _selectedDepartment = null;
      _selectedProgram = null;
    });
  }

  String _getRoleLabel(String roleId) {
    for (final r in _roles) {
      if (r['id'] == roleId) return r['label'];
    }
    return roleId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop()),
          title: Text(t(LAll.all_account_creation, ref))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            const Icon(Icons.person_add, color: Colors.black),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t(L.createAccount, ref),
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                              'Register students, teachers, staff, and other roles',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(t(LAuth.selectRole, ref),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _roles.map((role) {
                      final selected = _selectedRole == role['id'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRole = role['id']),
                        child: Container(
                          width: 140,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                selected ? Colors.grey[100] : theme.cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  selected ? Colors.black : Colors.grey[300]!,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(role['icon'] as IconData,
                                  color: selected
                                      ? Colors.black
                                      : Colors.grey[600],
                                  size: 24),
                              const SizedBox(height: 6),
                              Text(role['label'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: selected
                                        ? Colors.black
                                        : Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center),
                              Text(role['desc'],
                                  style: TextStyle(
                                      fontSize: 9, color: Colors.grey[500]),
                                  textAlign: TextAlign.center,
                                  maxLines: 2),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  Text(t(LAll.all_account_information, ref),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fullNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: theme.cardColor,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _emailCtrl,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: theme.cardColor,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email required';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(v.trim())) {
                              return 'Invalid email';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneCtrl,
                          decoration: InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: theme.cardColor,
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordCtrl,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: theme.cardColor,
                    ),
                    obscureText: _obscurePassword,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Password required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: InputDecoration(
                      labelText: 'Address (optional)',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: theme.cardColor,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _tazkiraCtrl,
                    decoration: InputDecoration(
                      labelText: 'Tazkira / ID Number (optional)',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: theme.cardColor,
                    ),
                  ),
                  if (_isStudentRole) ...[
                    const SizedBox(height: 20),
                    Text(t(LAll.all_academic_details, ref),
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _loadingPrograms
                              ? const SizedBox(
                                  height: 48,
                                  child: Center(
                                      child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))))
                              : DropdownButtonFormField<Map<String, dynamic>>(
                                  initialValue: _selectedProgram,
                                  decoration: InputDecoration(
                                    labelText: 'Program',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    filled: true,
                                    fillColor: theme.cardColor,
                                  ),
                                  items: _programs
                                      .map((p) => DropdownMenuItem(
                                          value: p,
                                          child: Text(p['name'] ?? '')))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedProgram = v),
                                ),
                        ),
                      ],
                    ),
                  ],
                  if (_isEmployeeRole) ...[
                    const SizedBox(height: 20),
                    Text(t(LAll.all_employment_details, ref),
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _loadingDeps
                        ? const SizedBox(
                            height: 48,
                            child: Center(
                                child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))))
                        : DropdownButtonFormField<Map<String, dynamic>>(
                            initialValue: _selectedDepartment,
                            decoration: InputDecoration(
                              labelText: 'Department',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              filled: true,
                              fillColor: theme.cardColor,
                            ),
                            items: _departments
                                .map((d) => DropdownMenuItem(
                                    value: d, child: Text(d['name'] ?? '')))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedDepartment = v),
                          ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _createAccount,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.person_add),
                      label: Text(
                        _isLoading
                            ? 'Creating...'
                            : 'Create ${_getRoleLabel(_selectedRole)} Account',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
