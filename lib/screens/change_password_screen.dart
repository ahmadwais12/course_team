import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtl = TextEditingController();
  final _newCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Widget _passwordField(
      TextEditingController ctl, String label, bool obscure,
      ValueChanged<bool> onToggle, String? Function(String?) validator) {
    return TextFormField(
      controller: ctl,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: () => onToggle(!obscure),
        ),
      ),
      obscureText: obscure,
      validator: validator,
    );
  }

  @override
  void dispose() {
    _currentCtl.dispose();
    _newCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newCtl.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(LSettings.passwordChanged, ref))),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t(LSettings.changePassword, ref))),
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Container(
            width: 420,
            padding: AppSpacing.paddingXl,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_reset, size: 64),
                  const SizedBox(height: AppSpacing.md),
                  Text('Update Your Password', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.xl),
                  _passwordField(
                      _currentCtl,
                      t(LSettings.currentPassword, ref),
                      _obscureCurrent,
                      (v) => setState(() => _obscureCurrent = v),
                      (v) => v == null || v.isEmpty ? 'Required' : null),
                  const SizedBox(height: AppSpacing.md),
                  _passwordField(
                      _newCtl,
                      t(LSettings.newPassword, ref),
                      _obscureNew,
                      (v) => setState(() => _obscureNew = v),
                      (v) => v == null || v.length < 6 ? 'Min 6 characters' : null),
                  const SizedBox(height: AppSpacing.md),
                  _passwordField(
                      _confirmCtl,
                      t(LAuth.confirmPassword, ref),
                      _obscureConfirm,
                      (v) => setState(() => _obscureConfirm = v),
                      (v) =>
                          v != _newCtl.text ? 'Passwords do not match' : null),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _changePassword,
                      child: _loading ? const CircularProgressIndicator() : Text(t(LSettings.changePassword, ref)),
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
