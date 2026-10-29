import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/providers/program_provider.dart';
import 'package:course_emis/providers/class_provider.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class StudentRegistrationScreen extends ConsumerStatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  ConsumerState<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState
    extends ConsumerState<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  // Form controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _guardianEmailController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedGender;
  String? _selectedProgram;
  String? _selectedClass;
  String? _selectedDuration;
  String? _selectedLevel;
  String? _selectedGuardianRelationship;
  double _totalFees = 0.0;
  double _discountPercentage = 0.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _guardianEmailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _registerStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? adminAccessToken;
    String? adminRefreshToken;

    try {
      final guardianEmail = _guardianEmailController.text.trim();
      final guardianName = _guardianNameController.text.trim();
      final guardianPhone = _guardianPhoneController.text.trim();

      // Generate student code
      final studentCode =
          'STU-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      // Get current tenant
      final currentUser = _supabase.auth.currentUser;
      String? tenantId;
      if (currentUser != null) {
        final profile = await _supabase
            .from('users')
            .select('tenant_id')
            .eq('id', currentUser.id)
            .single();
        tenantId = profile['tenant_id']?.toString();
      }
      if (tenantId == null) {
        throw Exception(
            'Your account has no tenant assigned. Contact an administrator.');
      }

      final adminSession = _supabase.auth.currentSession;
      adminAccessToken = adminSession?.accessToken;
      adminRefreshToken = adminSession?.refreshToken;
      if (adminAccessToken == null || adminRefreshToken == null) {
        throw Exception('Your session has expired. Please sign in again.');
      }
      final savedAccessToken = adminAccessToken;
      final savedRefreshToken = adminRefreshToken;
      Future<void> restoreAdminSession() => _supabase.auth.setSession(
            "{\"access_token\":\"$savedAccessToken\",\"refresh_token\":\"$savedRefreshToken\"}",
          );

      // Auto-generate guardian password
      final guardianPassword =
          'Guard@${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 13)}';

      // 1. Create guardian auth user
      debugPrint('[StudentReg] Creating guardian auth user: $guardianEmail');
      final signUpResponse = await _supabase.auth.signUp(
        email: guardianEmail,
        password: guardianPassword,
        data: {
          'full_name': guardianName,
          'role': 'guardian',
        },
      );

      final guardianUser = signUpResponse.user;
      if (guardianUser == null) {
        throw Exception('Failed to create guardian account');
      }
      debugPrint('[StudentReg] Guardian auth user created: ${guardianUser.id}');

      // 2. Insert guardian profile
      await restoreAdminSession();
      await _supabase.from('users').insert({
        'id': guardianUser.id,
        'tenant_id': tenantId,
        'full_name': guardianName,
        'phone': guardianPhone,
        'role': 'guardian',
        'is_active': true,
      });
      debugPrint('[StudentReg] Guardian profile inserted');

      // 3. Insert parent record
      final parentResult = await _supabase.from('parents').insert({
        'tenant_id': tenantId,
        'profile_id': guardianUser.id,
        'full_name': guardianName,
        'phone': guardianPhone,
        'email': guardianEmail,
        'is_guardian': true,
      }).select();
      final parentId = parentResult[0]['id'];
      debugPrint('[StudentReg] Parent record inserted: $parentId');

      // 4. Insert student record
      final studentResult = await _supabase.from('students').insert({
        'tenant_id': tenantId,
        'student_code': studentCode,
        'full_name': _fullNameController.text.trim(),
        'first_name': _fullNameController.text.trim().split(' ').first,
        'last_name': _fullNameController.text.trim().split(' ').last,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'date_of_birth': _dobController.text.isNotEmpty
            ? DateTime.parse(_dobController.text).toIso8601String()
            : null,
        'gender': _selectedGender,
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'guardian_name': guardianName,
        'guardian_phone': guardianPhone,
        'guardian_email': guardianEmail,
        'guardian_relationship': _selectedGuardianRelationship,
        'program_id': _selectedProgram,
        'class_id': _selectedClass,
        'duration_months': int.tryParse(_selectedDuration ?? '0'),
        'student_level': _selectedLevel,
        'enrollment_date': DateTime.now().toIso8601String(),
        'status': 'active',
        'total_fees': _totalFees.toDouble(),
        'discount_percentage': _discountPercentage.toDouble(),
        'notes': _notesController.text.trim(),
      }).select();
      final studentId = studentResult[0]['id'];
      debugPrint('[StudentReg] Student record inserted: $studentId');

      // 5. Link parent to student via parent_students
      await _supabase.from('parent_students').insert({
        'tenant_id': tenantId,
        'parent_id': parentId,
        'student_id': studentId,
        'relationship': _selectedGuardianRelationship ?? 'guardian',
        'is_primary': true,
      });
      debugPrint('[StudentReg] Parent-student link created');

      await restoreAdminSession();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${t(LCrud.createdSuccessfully, ref)} Code: $studentCode\n'
                    'Guardian login: $guardianEmail / $guardianPassword'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 10),
          ),
        );
        context.pop();
      }
    } catch (e, st) {
      debugPrint('[StudentReg] ERROR: $e');
      debugPrint('[StudentReg] STACK: $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (adminAccessToken != null && adminRefreshToken != null) {
        try {
          await _supabase.auth.setSession(
            "{\"access_token\":\"$adminAccessToken\",\"refresh_token\":\"$adminRefreshToken\"}",
          );
        } catch (e) {
          debugPrint('[StudentReg] Could not restore admin session: $e');
        }
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _dobController.text = date.toIso8601String().split('T').first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final programsAsync = ref.watch(programsProvider);
    final classesAsync = ref.watch(classesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Registration'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Personal Information Section
                _buildSectionTitle(t(LCourse.courseDetails, ref), Icons.person),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: '${t(L.fullName, ref)} *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        decoration: InputDecoration(
                          labelText: '${t(LExtra.female, ref)} *',
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: 'Male', child: Text('Male')),
                          const DropdownMenuItem(
                              value: 'Female', child: Text('Female')),
                          const DropdownMenuItem(
                              value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedGender = value),
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _dobController,
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: _selectDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          if (!value!.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                ),

                const SizedBox(height: 24),
                // Academic Information Section
                _buildSectionTitle(t(LCourse.courseDetails, ref), Icons.school),
                const SizedBox(height: 12),
                programsAsync.when(
                  data: (programs) {
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedProgram,
                      decoration: const InputDecoration(
                        labelText: 'Program *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.menu_book),
                      ),
                      items: programs.map((program) {
                        return DropdownMenuItem(
                          value: program.id,
                          child: Text(program.name),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedProgram = value),
                      validator: (value) => value == null ? 'Required' : null,
                    );
                  },
                  loading: () => const PageSkeleton(type: 'dashboard'),
                  error: (_, __) => const Text('Error loading programs'),
                ),
                const SizedBox(height: 12),
                classesAsync.when(
                  data: (classes) {
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedClass,
                      decoration: InputDecoration(
                        labelText: t(LCrud.className, ref),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.groups),
                      ),
                      items: classes.map((cls) {
                        return DropdownMenuItem(
                          value: cls.id,
                          child: Text(cls.name),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedClass = value),
                    );
                  },
                  loading: () => const PageSkeleton(type: 'dashboard'),
                  error: (_, __) => const Text('Error loading classes'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedDuration,
                        decoration: const InputDecoration(
                          labelText: 'Duration *',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: '4', child: Text('4 Months')),
                          DropdownMenuItem(value: '6', child: Text('6 Months')),
                          DropdownMenuItem(
                              value: '12', child: Text('12 Months')),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedDuration = value),
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Student Level',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _selectedLevel = value,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                // Guardian Information Section
                _buildSectionTitle(
                    'Guardian / Parent Account', Icons.family_restroom),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _guardianNameController,
                  decoration: InputDecoration(
                    labelText: '${t(L.fullName, ref)} *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _guardianPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Guardian Phone *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_android),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _guardianEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Guardian Email *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          if (!value!.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedGuardianRelationship,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people_outline),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'father', child: Text('Father')),
                    DropdownMenuItem(value: 'mother', child: Text('Mother')),
                    DropdownMenuItem(
                        value: 'guardian', child: Text('Guardian')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedGuardianRelationship = value),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.amber.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'A guardian account will be created with email and auto-generated password shown after registration.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Fee Information Section
                _buildSectionTitle(
                    t(LPayment.paymentDetails, ref), Icons.payments),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: t(LPayment.amount, ref),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: _totalFees.toString(),
                        onChanged: (value) {
                          setState(() {
                            _totalFees = double.tryParse(value) ?? 0.0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Discount %',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.discount),
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: _discountPercentage.toString(),
                        onChanged: (value) {
                          setState(() {
                            _discountPercentage = double.tryParse(value) ?? 0.0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Net Amount:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '\$${(_totalFees - (_totalFees * _discountPercentage / 100)).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Notes Section
                _buildSectionTitle(t(LCrud.notes, ref), Icons.note),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 32),
                // Submit Button
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _registerStudent,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(_isLoading
                        ? t(L.add, ref)
                        : t(LPanelUI.studentRegistration, ref)),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Student Registration'),
        content: const Text(
          'This form registers a new student in the system. '
          'A unique student code will be generated automatically. '
          'All fields marked with * are required.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(L.ok, ref)),
          ),
        ],
      ),
    );
  }
}
