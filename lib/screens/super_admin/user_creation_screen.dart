import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/utils/storage_buckets.dart';
import 'package:course_emis/services/secure_storage_service.dart';

void _log(String message) {
  dev.log(message, name: 'UserCreation');
}

class UserCreationScreen extends ConsumerStatefulWidget {
  const UserCreationScreen({super.key});

  @override
  ConsumerState<UserCreationScreen> createState() => _UserCreationScreenState();
}

class _UserCreationScreenState extends ConsumerState<UserCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _fullNameArCtrl = TextEditingController();
  final _firstNameArCtrl = TextEditingController();
  final _lastNameArCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _tazkiraCtrl = TextEditingController();
  final _passportCtrl = TextEditingController();
  final _nationalityCtrl = TextEditingController();
  final _religionCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _fatherNameArCtrl = TextEditingController();
  final _emergencyContactNameCtrl = TextEditingController();
  final _emergencyContactPhoneCtrl = TextEditingController();
  final _emergencyContactRelationCtrl = TextEditingController();

  String _selectedRole = 'admin';
  String? _selectedBloodGroup;
  String? _selectedMaritalStatus;
  Map<String, dynamic>? _selectedTenant;
  List<Map<String, dynamic>> _tenants = [];
  bool _isLoading = false;
  bool _loadingTenants = true;
  String? _avatarUrl;
  bool _isUploadingAvatar = false;
  Uint8List? _avatarBytes;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const _bloodGroupOptions = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  static const _maritalStatusOptions = [
    'single',
    'married',
    'divorced',
    'widowed',
  ];

  bool get _requiresTenant => _selectedRole != 'super_admin';

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    _log('_loadTenants START');
    try {
      final data = await Supabase.instance.client
          .from('tenants')
          .select('id, name, slug')
          .order('name');
      _log('_loadTenants returned ${data.length} tenants');
      if (data.isNotEmpty) {
        _log('  First tenant: ${data[0]}');
      }
      if (mounted) {
        setState(() {
          _tenants = List<Map<String, dynamic>>.from(data);
          _loadingTenants = false;
        });
      }
    } catch (e, st) {
      _log('!!!!!!!!!! _loadTenants ERROR !!!!!!!!!!');
      _log('  type: ${e.runtimeType}');
      _log('  message: $e');
      _log('  stack: $st');
      if (mounted) {
        setState(() => _loadingTenants = false);
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _fullNameCtrl.dispose();
    _fullNameArCtrl.dispose();
    _firstNameArCtrl.dispose();
    _lastNameArCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _tazkiraCtrl.dispose();
    _passportCtrl.dispose();
    _nationalityCtrl.dispose();
    _religionCtrl.dispose();
    _fatherNameCtrl.dispose();
    _fatherNameArCtrl.dispose();
    _emergencyContactNameCtrl.dispose();
    _emergencyContactPhoneCtrl.dispose();
    _emergencyContactRelationCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm password';
    if (value != _passwordCtrl.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _pickAvatarSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(t(LCrud.camera, ref)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(t(LCrud.gallery, ref)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) _pickAvatar(source);
  }

  Future<void> _pickAvatar(ImageSource source) async {
    _log('_pickAvatar START source=$source');
    setState(() => _isUploadingAvatar = true);
    final oldAvatarUrl = _avatarUrl;
    try {
      _log('Opening image picker...');
      final XFile? image =
          await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (image == null) {
        _log('_pickAvatar: User cancelled image selection');
        if (mounted) setState(() => _isUploadingAvatar = false);
        return;
      }
      _log('Image selected: ${image.name} (${await image.length()} bytes)');

      final bytes = await File(image.path).readAsBytes();
      _log('Bytes read: ${bytes.length}');

      final ext =
          image.name.contains('.') ? '.${image.name.split('.').last}' : '.jpg';
      final safeName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final storagePath = 'profiles/$safeName';

      _log('Setting _avatarBytes for preview (${bytes.length} bytes)');
      setState(() => _avatarBytes = bytes);

      _log(
          'Uploading to Supabase Storage bucket="${StorageBuckets.avatars}" path="$storagePath"');
      await Supabase.instance.client.storage
          .from(StorageBuckets.avatars)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      _log('Upload to storage SUCCESS');

      _log('Getting public URL...');
      final url = Supabase.instance.client.storage
          .from(StorageBuckets.avatars)
          .getPublicUrl(storagePath);
      _log('_pickAvatar url=$url');
      setState(() => _avatarUrl = url);
      _log('_pickAvatar COMPLETE - avatarUrl set');
    } catch (e, st) {
      _log('!!!!!!!!!! _pickAvatar ERROR !!!!!!!!!!');
      _log('  type: ${e.runtimeType}');
      _log('  message: $e');
      _log('  stack: $st');
      _log('  oldAvatarUrl=${oldAvatarUrl ?? "null"}');
      setState(() {
        _avatarBytes = null;
        _avatarUrl = oldAvatarUrl;
      });
      if (mounted) {
        final msg = e.toString().contains('policy') ||
                e.toString().contains('Unauthorized')
            ? 'Storage RLS policy blocks upload. Run this SQL in Supabase SQL Editor:\n'
                'CREATE POLICY "avatars_all" ON storage.objects FOR ALL TO authenticated USING (bucket_id = \'avatars\');'
            : e.toString().contains('bucket')
                ? 'Storage bucket "avatars" not found. Create it in Supabase Dashboard → Storage.'
                : 'Avatar upload failed: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(msg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 8)),
        );
      }
    }
    if (mounted) setState(() => _isUploadingAvatar = false);
  }

  Map<String, dynamic> _buildProfilePayload(String userId) {
    return {
      'id': userId,
      'tenant_id': _requiresTenant ? (_selectedTenant?['id']) : null,
      'full_name': _fullNameCtrl.text.trim(),
      'full_name_ar': _fullNameArCtrl.text.trim().isEmpty
          ? null
          : _fullNameArCtrl.text.trim(),
      'first_name_ar': _firstNameArCtrl.text.trim().isEmpty
          ? null
          : _firstNameArCtrl.text.trim(),
      'last_name_ar': _lastNameArCtrl.text.trim().isEmpty
          ? null
          : _lastNameArCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'address':
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      'tazkira_number':
          _tazkiraCtrl.text.trim().isEmpty ? null : _tazkiraCtrl.text.trim(),
      'passport_id':
          _passportCtrl.text.trim().isEmpty ? null : _passportCtrl.text.trim(),
      'blood_group': _selectedBloodGroup,
      'nationality': _nationalityCtrl.text.trim().isEmpty
          ? null
          : _nationalityCtrl.text.trim(),
      'religion':
          _religionCtrl.text.trim().isEmpty ? null : _religionCtrl.text.trim(),
      'father_name': _fatherNameCtrl.text.trim().isEmpty
          ? null
          : _fatherNameCtrl.text.trim(),
      'father_name_ar': _fatherNameArCtrl.text.trim().isEmpty
          ? null
          : _fatherNameArCtrl.text.trim(),
      'marital_status': _selectedMaritalStatus,
      'emergency_contact_name': _emergencyContactNameCtrl.text.trim().isEmpty
          ? null
          : _emergencyContactNameCtrl.text.trim(),
      'emergency_contact_phone': _emergencyContactPhoneCtrl.text.trim().isEmpty
          ? null
          : _emergencyContactPhoneCtrl.text.trim(),
      'emergency_contact_relation':
          _emergencyContactRelationCtrl.text.trim().isEmpty
              ? null
              : _emergencyContactRelationCtrl.text.trim(),
      'avatar_url': _avatarUrl,
      'role': _selectedRole,
      'is_active': true,
    };
  }

  Future<void> _createUser() async {
    _log('_createUser START');
    _log('Form valid: ${_formKey.currentState?.validate()}');
    if (!_formKey.currentState!.validate()) {
      _log('Form validation FAILED');
      _log('  email="${_emailCtrl.text}"');
      _log('  password length=${_passwordCtrl.text.length}');
      _log('  fullName="${_fullNameCtrl.text}"');
      _log('  selectedRole=$_selectedRole');
      _log('  selectedTenant=${_selectedTenant?['name']}');
      _log('  avatarUrl=$_avatarUrl');
      return;
    }
    _log('Selected role: $_selectedRole');
    _log('Requires tenant: $_requiresTenant');

    if (_requiresTenant && _selectedTenant == null) {
      _log('No tenant selected');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(LAll.all_please_select_a_tenant_for_this_role, ref))),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Ensure admin session is active — restore from secure storage if needed
    var adminSession = Supabase.instance.client.auth.currentSession;
    if (adminSession == null) {
      _log('Admin session null, attempting restore from secure storage...');
      final secureStorage = SecureStorageService(const FlutterSecureStorage());
      final at = await secureStorage.getAccessToken();
      final rt = await secureStorage.getRefreshToken();
      if (at != null && at.isNotEmpty) {
        try {
          final json = rt != null && rt.isNotEmpty
              ? "{\"access_token\":\"$at\",\"refresh_token\":\"$rt\"}"
              : "{\"access_token\":\"$at\"}";
          await Supabase.instance.client.auth
              .setSession(json)
              .timeout(const Duration(seconds: 15));
          adminSession = Supabase.instance.client.auth.currentSession;
          _log('Admin session restored from secure storage');
        } catch (e) {
          _log('Session restore failed: $e');
        }
      }
    }

    // Save admin session tokens before signUp — signUp replaces the current session
    final adminAccessToken = adminSession?.accessToken;
    final adminRefreshToken = adminSession?.refreshToken;
    _log(
        'Admin access token before signUp: ${adminAccessToken == null ? "missing" : "available"}');

    if (adminAccessToken == null || adminRefreshToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(t(LAll.all_your_session_has_expired_please_sign_in_again, ref))),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    Future<AuthResponse> restoreAdminSession() =>
        Supabase.instance.client.auth
            .setSession(
              "{\"access_token\":\"$adminAccessToken\",\"refresh_token\":\"$adminRefreshToken\"}",
            )
            .timeout(const Duration(seconds: 15));

    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;
      _log('STEP 1: Calling auth.signUp email=$email role=$_selectedRole');

      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': _fullNameCtrl.text.trim(),
          'role': _selectedRole,
        },
      ).timeout(const Duration(seconds: 30));

      _log('STEP 1 COMPLETE: auth.signUp response received');
      _log('  response.user.id=${response.user?.id}');

      final user = response.user;
      if (user == null) {
        _log('ERROR: No user returned from signUp');
        throw Exception('Failed to create auth user - no user returned');
      }

      _log('STEP 2: Building profile payload for user id=${user.id}');

      final payload = _buildProfilePayload(user.id);
      payload['email'] = email;
      _log('  Payload keys: ${payload.keys.join(", ")}');

      _log('STEP 3: Inserting into profiles table...');
      await Supabase.instance.client.from('users').insert(payload);
      _log('STEP 3 COMPLETE: Profile insert SUCCESS');

      // Restore admin session BEFORE navigating back, otherwise the router
      // still sees the newly-created user's session and redirects to login.
      _log('STEP 4: Restoring admin session (awaited)...');
      try {
        final restored = await restoreAdminSession();
        final session = restored.session;
        if (session != null) {
          final secureStorage =
              SecureStorageService(const FlutterSecureStorage());
          await secureStorage.saveAccessToken(session.accessToken);
          final rt = session.refreshToken;
          if (rt != null && rt.isNotEmpty) {
            await secureStorage.saveRefreshToken(rt);
          }
          _log('STEP 4 COMPLETE: Admin session restored + tokens re-saved');
        } else {
          final secureStorage =
              SecureStorageService(const FlutterSecureStorage());
          final at = await secureStorage.getAccessToken();
          final rt = await secureStorage.getRefreshToken();
          if (at != null && at.isNotEmpty) {
            final json = rt != null && rt.isNotEmpty
                ? "{\"access_token\":\"$at\",\"refresh_token\":\"$rt\"}"
                : "{\"access_token\":\"$at\"}";
            await Supabase.instance.client.auth
                .setSession(json)
                .timeout(const Duration(seconds: 15));
          }
        }
      } catch (e, st) {
        _log('STEP 4 FAILED: $e');
        _log('  stack: $st');
      }
      _log('STEP 5: Navigating to super admin panel');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(LAll.all_user_account_created_successfully, ref)),
            backgroundColor: Colors.black,
          ),
        );
        context.go(AppRoutesAll.superAdmin);
        _log('STEP 5 COMPLETE: Navigation done');
      }
    } on AuthException catch (e) {
      _log('!!!!!!!!!! AuthException !!!!!!!!!!');
      _log('  message: ${e.message}');
      _log('  statusCode: ${e.statusCode}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_auth_error_x, ref, [e.message]))),
        );
      }
    } catch (e, st) {
      _log('!!!!!!!!!! UNEXPECTED ERROR !!!!!!!!!!');
      _log('  type: ${e.runtimeType}');
      _log('  message: $e');
      _log('  stack trace: $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tt(LAll.all_failed_to_create_user_x, ref, ['$e'])),
              duration: const Duration(seconds: 8)),
        );
      }
    } finally {
      _log('_createUser END | isSaving=false');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              }),
          title: Text(t(LAll.all_create_user, ref))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
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
                        child: const Icon(Icons.person_add_alt_1,
                            color: Colors.black),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t(LAll.all_create_user_account, ref),
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                              'Create authentication accounts with role-based access',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _sectionTitle(theme, 'Account Type'),
                  const SizedBox(height: 12),
                  _RoleGrid(
                    selectedRole: _selectedRole,
                    onRoleChanged: (role) =>
                        setState(() => _selectedRole = role),
                  ),
                  if (_requiresTenant) ...[
                    const SizedBox(height: 20),
                    Text(t(LAll.all_tenant, ref),
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _loadingTenants
                        ? const SizedBox(
                            height: 48,
                            child: Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)))
                        : _tenants.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: Colors.orange[700], size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'No tenants found. Create a tenant first.',
                                        style: TextStyle(
                                            color: Colors.orange[700],
                                            fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : DropdownButtonFormField<Map<String, dynamic>>(
                                initialValue: _selectedTenant,
                                decoration: _inputDecoration(theme,
                                    hint: t(LAll.all_select_a_tenant, ref)),
                                hint: const Text('Select a tenant'),
                                items: _tenants
                                    .map((t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(t['name'] ?? ''),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedTenant = v),
                              ),
                  ],
                  const SizedBox(height: 24),
                  _sectionTitle(theme, 'Basic Information'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fullNameCtrl,
                    decoration: _inputDecoration(theme,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        required: true),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _fullNameArCtrl,
                    decoration: _inputDecoration(theme,
                        label: 'Full Name (Arabic/Dari)',
                        icon: Icons.translate),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _isUploadingAvatar ? null : _pickAvatarSource,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              key: ValueKey(_avatarBytes ?? _avatarUrl),
                              radius: 40,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _avatarBytes != null
                                  ? MemoryImage(_avatarBytes!)
                                  : (_avatarUrl != null
                                      ? NetworkImage(_avatarUrl!)
                                      : null),
                              child: _avatarBytes == null && _avatarUrl == null
                                  ? Icon(Icons.person,
                                      size: 40, color: Colors.grey[400])
                                  : null,
                            ),
                            if (_isUploadingAvatar)
                              const Positioned.fill(
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                                child: _isUploadingAvatar
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Icon(Icons.camera_alt,
                                        size: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t(LAll.all_profile_photo, ref),
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(
                                'Tap to upload. JPEG, PNG, WebP, GIF up to 2MB',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: _inputDecoration(theme,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        required: true),
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: _inputDecoration(theme,
                        label: 'Phone Number', icon: Icons.phone_outlined),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle(theme, 'Dari / Pashto Names'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameArCtrl,
                          decoration:
                              _inputDecoration(theme, label: 'First Name (Ar)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameArCtrl,
                          decoration:
                              _inputDecoration(theme, label: 'Last Name (Ar)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle(theme, 'Personal Details'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: _inputDecoration(theme,
                        label: 'Address', icon: Icons.location_on_outlined),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _tazkiraCtrl,
                          decoration: _inputDecoration(theme,
                              label: 'Tazkira Number',
                              icon: Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _passportCtrl,
                          decoration: _inputDecoration(theme,
                              label: 'Passport ID',
                              icon: Icons.airplane_ticket_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedBloodGroup,
                          decoration:
                              _inputDecoration(theme, hint: t(LAll.all_blood_group, ref)),
                          hint: const Text('Blood Group'),
                          items: _bloodGroupOptions
                              .map((bg) => DropdownMenuItem(
                                    value: bg,
                                    child: Text(bg),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedBloodGroup = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedMaritalStatus,
                          decoration:
                              _inputDecoration(theme, hint: t(LAll.all_marital_status, ref)),
                          hint: const Text('Marital Status'),
                          items: _maritalStatusOptions
                              .map((ms) => DropdownMenuItem(
                                    value: ms,
                                    child: Text(
                                        ms[0].toUpperCase() + ms.substring(1)),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedMaritalStatus = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nationalityCtrl,
                          decoration: _inputDecoration(theme,
                              label: 'Nationality', icon: Icons.flag_outlined),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _religionCtrl,
                          decoration: _inputDecoration(theme,
                              label: 'Religion', icon: Icons.church_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle(theme, 'Family Information'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _fatherNameCtrl,
                          decoration: _inputDecoration(theme,
                              label: "Father's Name", icon: Icons.man_outlined),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _fatherNameArCtrl,
                          decoration: _inputDecoration(theme,
                              label: "Father's Name (Ar)"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle(theme, 'Emergency Contact'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emergencyContactNameCtrl,
                    decoration: _inputDecoration(theme,
                        label: 'Contact Name',
                        icon: Icons.contact_emergency_outlined),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _emergencyContactPhoneCtrl,
                          decoration: _inputDecoration(theme,
                              label: 'Contact Phone',
                              icon: Icons.phone_outlined),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _emergencyContactRelationCtrl,
                          decoration: _inputDecoration(theme,
                              label: 'Relation', icon: Icons.people_outline),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle(theme, 'Security'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _passwordCtrl,
                          decoration: _inputDecoration(theme,
                              label: 'Password',
                              icon: Icons.lock_outlined,
                              required: true,
                              obscure: _obscurePassword,
                              onToggleObscure: () => setState(
                                  () => _obscurePassword = !_obscurePassword)),
                          obscureText: _obscurePassword,
                          validator: _validatePassword,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _confirmPasswordCtrl,
                          decoration: _inputDecoration(theme,
                              label: 'Confirm Password',
                              icon: Icons.lock_outlined,
                              required: true,
                              obscure: _obscureConfirmPassword,
                              onToggleObscure: () => setState(() =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword)),
                          obscureText: _obscureConfirmPassword,
                          validator: _validateConfirmPassword,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              _log('Save/Create button CLICKED');
                              _createUser();
                            },
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
                            : 'Create ${_selectedRole.replaceAll('_', ' ').toUpperCase()} Account',
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

  Widget _sectionTitle(ThemeData theme, String title) {
    return Text(title,
        style:
            theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600));
  }

  InputDecoration _inputDecoration(ThemeData theme,
      {String? label,
      String? hint,
      IconData? icon,
      bool required = false,
      bool obscure = false,
      VoidCallback? onToggleObscure}) {
    final labelText = label != null ? (required ? '$label *' : label) : null;
    return InputDecoration(
      labelText: labelText,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      suffixIcon: obscure
          ? IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: onToggleObscure,
            )
          : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: theme.cardColor,
    );
  }
}

class _RoleGrid extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;

  const _RoleGrid({
    required this.selectedRole,
    required this.onRoleChanged,
  });

  static const _roleIcons = {
    'ceo': Icons.leaderboard,
    'super_admin': Icons.shield,
    'admin': Icons.admin_panel_settings,
    'teacher': Icons.school,
    'student': Icons.person,
    'guardian': Icons.people,
    'staff': Icons.badge,
    'academic_support': Icons.support,
    'accountant': Icons.calculate,
    'librarian': Icons.local_library,
    'receptionist': Icons.desk,
    'hr_manager': Icons.group,
    'inventory_manager': Icons.inventory,
    'it_support': Icons.computer,
    'maintenance': Icons.build,
    'event_manager': Icons.event,
    'complaint_manager': Icons.report,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _roleIcons.entries.map((entry) {
        final role = entry.key;
        final icon = entry.value;
        final isSelected = selectedRole == role;
        final label = role.replaceAll('_', ' ');

        return GestureDetector(
          onTap: () => onRoleChanged(role),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.grey[100] : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 18,
                    color: isSelected ? Colors.black : Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  label[0].toUpperCase() + label.substring(1),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.black : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
