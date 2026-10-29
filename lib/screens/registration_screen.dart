import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:course_emis/nav.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:course_emis/services/file_service.dart';
import 'package:course_emis/utils/storage_buckets.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  final _fullNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _tazkiraCtrl = TextEditingController();
  final _passportCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _nationalityCtrl = TextEditingController();
  final _religionCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  final _emergencyRelationCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  int _currentStep = 0;
  String _selectedRole = 'student';
  String _gender = 'Male';
  String _bloodGroup = 'A+';
  String _maritalStatus = 'single';
  Map<String, dynamic>? _selectedDepartment;
  Map<String, dynamic>? _selectedProgram;
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _dbRoles = [];
  bool _isLoading = false;
  bool _loadingRoles = true;
  bool _loadingDeps = true;
  bool _loadingPrograms = true;
  String? _avatarUrl;

  static const _fallbackRoles = [

    {
      'slug': 'super_admin',
      'name': 'Super Admin',
      'description': 'Super Administrator - full system access'
    },
    {
      'slug': 'admin',
      'name': 'Admin',
      'description': 'Administrator - system management access'
    },
    {
      'slug': 'accountant',
      'name': 'Accountant',
      'description': 'Accounting and financial management'
    },
    {
      'slug': 'hr_manager',
      'name': 'HR Manager',
      'description': 'Human resources and payroll management'
    },
    {
      'slug': 'inventory_manager',
      'name': 'Inventory Manager',
      'description': 'Inventory and asset management'
    },
    {
      'slug': 'it_support',
      'name': 'IT Support',
      'description': 'IT systems and device support'
    },
    {
      'slug': 'librarian',
      'name': 'Librarian',
      'description': 'Library and resource management'
    },
    {
      'slug': 'staff',
      'name': 'Staff',
      'description': 'Staff member - panel sub-role access'
    },
    {
      'slug': 'academic_support',
      'name': 'Academic Support',
      'description': 'Academic affairs and curriculum support'
    },
    {
      'slug': 'teacher',
      'name': 'Teacher',
      'description': 'Teacher - academic and class management'
    },
    {
      'slug': 'maintenance',
      'name': 'Maintenance',
      'description': 'Facility and equipment maintenance'
    },
    {
      'slug': 'receptionist',
      'name': 'Receptionist',
      'description': 'Front desk and visitor management'
    },
    {
      'slug': 'event_manager',
      'name': 'Event Manager',
      'description': 'Event and activity coordination'
    },
    {
      'slug': 'guardian',
      'name': 'Guardian',
      'description': 'Parent/Guardian - student monitoring access'
    },
    {
      'slug': 'complaint_manager',
      'name': 'Complaint Manager',
      'description': 'Complaint and feedback management'
    },
    {
      'slug': 'student',
      'name': 'Student',
      'description': 'Student - personal and academic records'
    },
  ];

  static const _fallbackDepartments = [
    {'id': 'academic', 'name': 'Academic Affairs'},
    {'id': 'admin_dept', 'name': 'Administration'},
    {'id': 'finance', 'name': 'Finance & Accounting'},
    {'id': 'hr', 'name': 'Human Resources'},
    {'id': 'it', 'name': 'IT Support'},
    {'id': 'library', 'name': 'Library'},
    {'id': 'maintenance', 'name': 'Maintenance'},
    {'id': 'reception', 'name': 'Reception'},
    {'id': 'transport', 'name': 'Transport'},
  ];

  static const _studentRoles = {'student', 'guardian'};
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

  static const _genders = ['Male', 'Female', 'Other'];
  static const _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];
  static const _maritalStatuses = ['single', 'married', 'divorced', 'widowed'];

  @override
  void initState() {
    super.initState();
    _loadRoles();
    _loadDepartments();
    _loadPrograms();
  }

  Future<void> _loadRoles() async {
    try {
      final data = await Supabase.instance.client
          .from('roles')
          .select('slug, name, description')
          .eq('is_active', true)
          .order('level', ascending: false);
      if (mounted) {
        setState(() {
          _dbRoles = List<Map<String, dynamic>>.from(data);
          _loadingRoles = false;
          if (_dbRoles.isNotEmpty) {
            _selectedRole = _dbRoles.first['slug'] as String;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dbRoles = List<Map<String, dynamic>>.from(_fallbackRoles);
          _loadingRoles = false;
          if (_dbRoles.isNotEmpty) {
            _selectedRole = _dbRoles.first['slug'] as String;
          }
        });
      }
    }
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
      if (mounted) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(_fallbackDepartments);
          _loadingDeps = false;
        });
      }
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
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _tazkiraCtrl.dispose();
    _passportCtrl.dispose();
    _addressCtrl.dispose();
    _fatherNameCtrl.dispose();
    _motherNameCtrl.dispose();
    _nationalityCtrl.dispose();
    _religionCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _emergencyRelationCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  bool get _isStudentRole => _studentRoles.contains(_selectedRole);
  bool get _isEmployeeRole => _employeeRoles.contains(_selectedRole);

  Future<void> _pickAvatar() async {
    final url = await FileService.uploadImage(
      bucket: StorageBuckets.avatars,
      path: 'profiles',
    );
    if (url != null && mounted) {
      setState(() => _avatarUrl = url);
    }
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        data: {
          'full_name': _fullNameCtrl.text.trim(),
          'last_name': _lastNameCtrl.text.trim(),
          'role': _selectedRole,
        },
      );

      final user = response.user;
      if (user == null) throw Exception('Failed to create user');

      final profileData = {
        'id': user.id,
        'full_name': _fullNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'role': _selectedRole,
        'address': _addressCtrl.text.trim(),
        'tazkira_number': _tazkiraCtrl.text.trim(),
        'passport_id': _passportCtrl.text.trim(),
        'father_name': _fatherNameCtrl.text.trim(),
        'mother_name': _motherNameCtrl.text.trim(),
        'nationality': _nationalityCtrl.text.trim(),
        'religion': _religionCtrl.text.trim(),
        'gender': _gender,
        'blood_group': _bloodGroup,
        'marital_status': _maritalStatus,
        'emergency_contact_name': _emergencyNameCtrl.text.trim(),
        'emergency_contact_phone': _emergencyPhoneCtrl.text.trim(),
        'emergency_contact_relation': _emergencyRelationCtrl.text.trim(),
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (_dobCtrl.text.trim().isNotEmpty) {
        profileData['date_of_birth'] = _dobCtrl.text.trim();
      }
      if (_avatarUrl != null) {
        profileData['avatar_url'] = _avatarUrl!;
      }

      await Supabase.instance.client.from('users').insert(profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_getRoleLabel(_selectedRole)} account created successfully! You can now log in.'),
            backgroundColor: Colors.black,
          ),
        );
        context.go(AppRoutesAll.login);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auth error: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getRoleLabel(String roleSlug) {
    for (final r in _dbRoles) {
      if (r['slug'] == roleSlug) return r['name'] ?? roleSlug;
    }
    return roleSlug;
  }

  bool _validateStep() {
    if (_currentStep == 0) {
      if (_fullNameCtrl.text.trim().isEmpty ||
          _emailCtrl.text.trim().isEmpty ||
          _passwordCtrl.text.isEmpty ||
          _phoneCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please fill in all required fields (*)'),
              backgroundColor: Colors.red),
        );
        return false;
      }
    }
    return true;
  }

  void _nextStep() {
    if (!_validateStep()) return;
    if (_currentStep < 4) setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  InputDecoration _inputDec(String label,
      {IconData? icon, bool required = false}) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Theme.of(context).cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go(AppRoutesAll.login),
        ),
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: _buildStepContent(theme),
              ),
            ),
          ),
          _buildNavigation(theme),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final steps = ['Account', 'Personal', 'Identity', 'Emergency', 'Review'];
    final icons = [
      Icons.person_add,
      Icons.person,
      Icons.badge,
      Icons.emergency,
      Icons.checklist,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: InkWell(
              onTap: () {
                if (i < _currentStep) setState(() => _currentStep = i);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDone
                          ? Colors.green
                          : isActive
                              ? Colors.black
                              : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDone ? Icons.check : icons[i],
                      size: 16,
                      color:
                          isDone || isActive ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(steps[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? Colors.black : Colors.grey[600],
                      )),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _stepAccountType(theme);
      case 1:
        return _stepPersonalDetails(theme);
      case 2:
        return _stepIdentityFamily(theme);
      case 3:
        return _stepEmergencyAcademic(theme);
      case 4:
        return _stepPhotoReview(theme);
      default:
        return const SizedBox();
    }
  }

  Widget _stepAccountType(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 1: Account Type & Profile',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Select your role, add your name, and upload a photo',
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 20),
        Text('Profile Photo',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: _pickAvatar,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 2),
                image: _avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _avatarUrl == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt,
                            size: 28, color: Colors.grey[400]),
                        const SizedBox(height: 2),
                        Text('Tap to add\nphoto',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[500])),
                      ],
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Account Type',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _loadingRoles
            ? const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)))
            : DropdownButtonFormField<String>(
initialValue: _selectedRole,
                decoration:
                    _inputDec('Account Type *', icon: Icons.badge_outlined),
                items: _dbRoles
                    .map((r) => DropdownMenuItem(
                          value: r['slug'] as String,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['name'] as String,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                              if (r['description'] != null &&
                                  (r['description'] as String).isNotEmpty)
                                Text(r['description'] as String,
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[500])),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedRole = v);
                },
              ),
        const SizedBox(height: 20),
        Text('Name & Family',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _fullNameCtrl,
                decoration: _inputDec('First Name',
                    icon: Icons.person_outline, required: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _lastNameCtrl,
                decoration: _inputDec('Last Name', icon: Icons.person_outline),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _fatherNameCtrl,
                decoration: _inputDec("Father's Name", icon: Icons.man),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _motherNameCtrl,
                decoration: _inputDec("Mother's Name", icon: Icons.woman),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Login Credentials',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailCtrl,
                decoration: _inputDec('Email',
                    icon: Icons.email_outlined, required: true),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _phoneCtrl,
                decoration: _inputDec('Phone',
                    icon: Icons.phone_outlined, required: true),
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _passwordCtrl,
          decoration: _inputDec('Password',
              icon: Icons.lock_outlined, required: true).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          obscureText: _obscurePassword,
        ),
      ],
    );
  }

  Widget _stepPersonalDetails(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 2: Personal Details',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Date of birth, gender, and other personal info',
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 20),
        TextFormField(
          controller: _dobCtrl,
          decoration: _inputDec('Date of Birth', icon: Icons.calendar_today),
          readOnly: true,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              _dobCtrl.text =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            }
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
initialValue: _gender,
                decoration: _inputDec('Gender', icon: Icons.wc),
                items: _genders
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _gender = v);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
initialValue: _bloodGroup,
                decoration: _inputDec('Blood Group', icon: Icons.bloodtype),
                items: _bloodGroups
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _bloodGroup = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
initialValue: _maritalStatus,
                decoration:
                    _inputDec('Marital Status', icon: Icons.favorite_border),
                items: _maritalStatuses
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m[0].toUpperCase() + m.substring(1)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _maritalStatus = v);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _nationalityCtrl,
                decoration: _inputDec('Nationality', icon: Icons.flag),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _religionCtrl,
          decoration: _inputDec('Religion', icon: Icons.church),
        ),
      ],
    );
  }

  Widget _stepIdentityFamily(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 3: Identity & Documents',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('ID documents and address',
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tazkiraCtrl,
                decoration:
                    _inputDec('Tazkira Number', icon: Icons.badge_outlined),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _passportCtrl,
                decoration: _inputDec('Passport ID', icon: Icons.credit_card),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressCtrl,
          decoration: _inputDec('Address', icon: Icons.location_on_outlined),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _stepEmergencyAcademic(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 4: Emergency & Academic',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Emergency contacts and academic/employment details',
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 20),
        Text('Emergency Contact',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emergencyNameCtrl,
          decoration: _inputDec('Emergency Contact Name', icon: Icons.person),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emergencyPhoneCtrl,
                decoration: _inputDec('Emergency Phone', icon: Icons.phone),
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _emergencyRelationCtrl,
                decoration: _inputDec('Relation', icon: Icons.people),
              ),
            ),
          ],
        ),
        if (_isStudentRole) ...[
          const SizedBox(height: 20),
          Text('Academic Details',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _loadingPrograms
              ? const Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : DropdownButtonFormField<Map<String, dynamic>>(
initialValue: _selectedProgram,
                  decoration: _inputDec('Program'),
                  items: _programs
                      .map((p) => DropdownMenuItem(
                          value: p, child: Text(p['name'] ?? '')))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedProgram = v),
                ),
        ],
        if (_isEmployeeRole) ...[
          const SizedBox(height: 20),
          Text('Employment Details',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _loadingDeps
              ? const Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : DropdownButtonFormField<Map<String, dynamic>>(
initialValue: _selectedDepartment,
                  decoration: _inputDec('Department'),
                  items: _departments
                      .map((d) => DropdownMenuItem(
                          value: d, child: Text(d['name'] ?? '')))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedDepartment = v),
                ),
        ],
      ],
    );
  }

  Widget _stepPhotoReview(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 5: Review & Submit',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Review your information before submitting',
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 20),
        Text('Review Information',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _buildReviewRow('Account Type', _getRoleLabel(_selectedRole)),
        _buildReviewRow('First Name', _fullNameCtrl.text),
        _buildReviewRow('Last Name', _lastNameCtrl.text),
        _buildReviewRow('Email', _emailCtrl.text),
        _buildReviewRow('Phone', _phoneCtrl.text),
        _buildReviewRow('Date of Birth', _dobCtrl.text),
        _buildReviewRow('Gender', _gender),
        _buildReviewRow('Blood Group', _bloodGroup),
        _buildReviewRow('Marital Status',
            _maritalStatus[0].toUpperCase() + _maritalStatus.substring(1)),
        _buildReviewRow('Nationality', _nationalityCtrl.text),
        _buildReviewRow('Religion', _religionCtrl.text),
        _buildReviewRow('Father Name', _fatherNameCtrl.text),
        _buildReviewRow('Mother Name', _motherNameCtrl.text),
        _buildReviewRow('Tazkira', _tazkiraCtrl.text),
        _buildReviewRow('Passport', _passportCtrl.text),
        _buildReviewRow('Address', _addressCtrl.text),
        _buildReviewRow('Emergency Contact', _emergencyNameCtrl.text),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _prevStep,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              )
            else
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutesAll.login),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Sign In'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _currentStep == 4
                    ? (_isLoading ? null : _register)
                    : _nextStep,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(
                        _currentStep == 4 ? Icons.check : Icons.arrow_forward,
                        size: 18),
                label: Text(_isLoading
                    ? 'Creating...'
                    : _currentStep == 4
                        ? 'Create Account'
                        : 'Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
