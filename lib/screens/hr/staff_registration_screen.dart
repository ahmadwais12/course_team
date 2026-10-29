import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/base_panel_layout.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

final departmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await Supabase.instance.client.from('departments').select();
  return response;
});

class StaffRegistrationScreen extends ConsumerStatefulWidget {
  const StaffRegistrationScreen({super.key});

  @override
  ConsumerState<StaffRegistrationScreen> createState() => _StaffRegistrationScreenState();
}

class _StaffRegistrationScreenState extends ConsumerState<StaffRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _salaryController = TextEditingController();
  final _employeeCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _qualificationsController = TextEditingController();

  String? _selectedRole;
  String? _selectedDepartment;
  String? _selectedContractType;
  String? _selectedEmploymentType;
  DateTime? _joinDate;
  DateTime? _contractEndDate;
  bool _isLoading = false;

  final List<String> _roles = [
    'Teacher',
    'Admin',
    'Accountant',
    'HR Manager',
    'Librarian',
    'IT Support',
    'Receptionist',
    'Maintenance',
    'Other'
  ];

  final List<String> _contractTypes = ['Full-time', 'Part-time', 'Contract', 'Internship'];
  final List<String> _employmentTypes = ['Permanent', 'Temporary', 'Probation'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    _employeeCodeController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _qualificationsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isJoinDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isJoinDate) {
          _joinDate = picked;
        } else {
          _contractEndDate = picked;
        }
      });
    }
  }

  Future<void> _registerStaff() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      
      // Generate employee code if not provided
      final employeeCode = _employeeCodeController.text.isEmpty
          ? 'EMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
          : _employeeCodeController.text;

      // Create staff record
      final staffData = {
        'employee_code': employeeCode,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
        'department': _selectedDepartment,
        'join_date': _joinDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'contract_type': _selectedContractType,
        'employment_type': _selectedEmploymentType,
        'contract_end_date': _contractEndDate?.toIso8601String(),
        'salary': double.tryParse(_salaryController.text) ?? 0.0,
        'address': _addressController.text.trim(),
        'emergency_contact': _emergencyContactController.text.trim(),
        'qualifications': _qualificationsController.text.trim(),
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('staff').insert(staffData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LStaff.staffRegistered, ref))),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(departmentsProvider);

    return BasePanelLayout(
      title: 'Staff Registration',
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: CustomTextField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            if (!value!.contains('@')) return 'Invalid email';
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: CustomTextField(
                          controller: _phoneController,
                          label: 'Phone',
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  CustomTextField(
                    controller: _addressController,
                    label: 'Address',
                    maxLines: 2,
                  ),
                  SizedBox(height: 32.h),
                  Text(
                    'Employment Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
initialValue: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            border: OutlineInputBorder(),
                          ),
                          items: _roles.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedRole = value);
                          },
                          validator: (value) =>
                              value == null ? 'Please select a role' : null,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: departmentsAsync.when(
                          data: (departments) {
                            return DropdownButtonFormField<String>(
initialValue: _selectedDepartment,
                              decoration: const InputDecoration(
                                labelText: 'Department',
                                border: OutlineInputBorder(),
                              ),
                              items: departments.map((dept) {
                                return DropdownMenuItem(
                                  value: dept['name'] as String,
                                  child: Text(dept['name'] as String),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedDepartment = value);
                              },
                            );
                          },
                          loading: () => const PageSkeleton(type: 'list'),
                          error: (_, __) => const Text('Error loading departments'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _employeeCodeController,
                          label: 'Employee Code (Optional)',
                          hint: 'Auto-generated if empty',
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: CustomTextField(
                          controller: _salaryController,
                          label: 'Salary',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
initialValue: _selectedContractType,
                          decoration: const InputDecoration(
                            labelText: 'Contract Type',
                            border: OutlineInputBorder(),
                          ),
                          items: _contractTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedContractType = value);
                          },
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: DropdownButtonFormField<String>(
initialValue: _selectedEmploymentType,
                          decoration: const InputDecoration(
                            labelText: 'Employment Type',
                            border: OutlineInputBorder(),
                          ),
                          items: _employmentTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedEmploymentType = value);
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
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Join Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _joinDate != null
                                  ? '${_joinDate!.day}/${_joinDate!.month}/${_joinDate!.year}'
                                  : 'Select Date',
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Contract End Date (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _contractEndDate != null
                                  ? '${_contractEndDate!.day}/${_contractEndDate!.month}/${_contractEndDate!.year}'
                                  : 'Select Date',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                  Text(
                    'Additional Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 24.h),
                  CustomTextField(
                    controller: _emergencyContactController,
                    label: 'Emergency Contact',
                    hint: 'Name and phone number',
                  ),
                  SizedBox(height: 16.h),
                  CustomTextField(
                    controller: _qualificationsController,
                    label: 'Qualifications',
                    maxLines: 3,
                    hint: 'Education, certifications, skills',
                  ),
                  SizedBox(height: 32.h),
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      onPressed: _isLoading ? () {} : _registerStaff,
                      text: _isLoading ? 'Registering...' : 'Register Staff',
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
