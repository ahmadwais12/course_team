import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/theme/dashboard_theme.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:course_emis/services/secure_storage_service.dart';

void _log(String message) {
  dev.log(message, name: 'Login');
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return t(LGen.fieldRequired, ref);
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return t(LGen.invalidEmailLong, ref);
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return t(LGen.fieldRequired, ref);
    }
    if (value.length < 6) {
      return t(L.min6Characters, ref);
    }
    return null;
  }

  Future<void> _signIn() async {
    _log('_signIn START');
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) {
      _log('Form validation FAILED');
      _log('  email="${_emailCtl.text}"');
      _log('  password length=${_passwordCtl.text.length}');
      return;
    }

    final email = _emailCtl.text.trim();
    _log('Signing in with email=$email');

    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: _passwordCtl.text,
      );
      _log('signInWithPassword SUCCESS');
      _log('  user.id=${response.user?.id}');
      _log('  user.role=${response.user?.userMetadata?['role']}');
      _log('  session=${response.session != null}');

      // Persist tokens to secure storage for session restore
      if (response.session?.accessToken != null) {
        _log('Saving tokens to secure storage');
        final secureStorage = SecureStorageService(const FlutterSecureStorage());
        await secureStorage.saveAccessToken(response.session!.accessToken);
        final rt = response.session!.refreshToken;
        if (rt != null && rt.isNotEmpty) {
          await secureStorage.saveRefreshToken(rt);
        }
        _log('Tokens saved');
      }

      if (mounted) {
        _log('Navigating to dashboard');
        context.go(AppRoutesAll.dashboard);
        _log('Navigation done');
      }
    } on AuthException catch (e) {
      _log('!!!!!!!!!! AuthException !!!!!!!!!!');
      _log('  statusCode: ${e.statusCode}');
      _log('  message: ${e.message}');
      setState(() => _errorMessage = e.message);
    } catch (e, st) {
      _log('!!!!!!!!!! UNEXPECTED ERROR !!!!!!!!!!');
      _log('  type: ${e.runtimeType}');
      _log('  message: $e');
      _log('  stack: $st');
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return _buildDesktop();
        }
        return _buildMobile();
      },
    );
  }

  Widget _buildDesktop() {
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: dtBgColor,
      body: Center(
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: dtPrimaryColor.withValues(alpha: 0.15),
                            blurRadius: 80,
                            spreadRadius: 15,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: dtCardColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: dtPrimaryColor.withValues(alpha: 0.4), width: 2),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo/dreamflow-icon-black.png',
                            width: 160, height: 160,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'DreamFlow',
                      style: TextStyle(
                        color: dtTextColor,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Education Management System',
                      style: TextStyle(
                        color: dtSecondaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 1,
              height: 400,
              color: dtBorderColor,
            ),
            Expanded(
              flex: 4,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: dtCardColor,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: dtBorderColor),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Sign In',
                          style: TextStyle(
                            color: dtTextColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome back! Enter your credentials.',
                          style: TextStyle(color: dtSecondaryColor, fontSize: 14),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _emailCtl,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.translate('email', locale),
                            hintText: t(LCrud.enterEmail, ref),
                            prefixIcon: const Icon(Icons.email_outlined, color: dtSecondaryColor),
                            labelStyle: const TextStyle(color: dtSecondaryColor),
                            hintStyle: const TextStyle(color: dtSecondaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: dtBorderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: dtBorderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: dtPrimaryColor, width: 2),
                            ),
                            filled: true,
                            fillColor: dtSurfaceColor,
                          ),
                          style: const TextStyle(color: dtTextColor),
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordCtl,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.translate('password', locale),
                            hintText: t(LCrud.enterPassword, ref),
                            prefixIcon: const Icon(Icons.lock_outlined, color: dtSecondaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: dtSecondaryColor,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            labelStyle: const TextStyle(color: dtSecondaryColor),
                            hintStyle: const TextStyle(color: dtSecondaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: dtBorderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: dtBorderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: dtPrimaryColor, width: 2),
                            ),
                            filled: true,
                            fillColor: dtSurfaceColor,
                          ),
                          style: const TextStyle(color: dtTextColor),
                          obscureText: _obscurePassword,
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.go(AppRoutes.forgotPassword),
                            child: Text(
                              t(L.forgotPassword, ref),
                              style: const TextStyle(
                                color: dtPrimaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: dtDangerColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: dtDangerColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded, color: dtDangerColor, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: dtDangerColor, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: dtPrimaryColor,
                              foregroundColor: dtTextColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(color: dtSecondaryColor),
                            ),
                            TextButton(
                              onPressed: () => context.go(AppRoutesAll.registration),
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: dtPrimaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobile() {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        isDark
                            ? 'assets/logo/dreamflow-icon-black.png'
                            : 'assets/logo/dreamflow-icon-black.png',
                        width: 160,
                        height: 160,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailCtl,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.translate('email', locale),
                        hintText: t(LCrud.enterEmail, ref),
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordCtl,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.translate('password', locale),
                        hintText: t(LCrud.enterPassword, ref),
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.forgotPassword),
                        child: Text(
                          t(L.forgotPassword, ref),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.error.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                theme.colorScheme.error.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.error_outline_rounded,
                                  color: theme.colorScheme.error, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                AppLocalizations.translate('login', locale),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6)),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.go(AppRoutesAll.registration),
                          child: Text(
                            'Create Account',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }
}
