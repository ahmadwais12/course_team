import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/two_factor_service.dart';
import '../widgets/modern_ui.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  ConsumerState<TwoFactorSetupScreen> createState() =>
      _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends ConsumerState<TwoFactorSetupScreen> {
  bool _loading = false;
  bool _enabled = false;
  String? _secret;
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _loading = true);
    try {
      final userId = 'current_user_id'; // Get from auth
      _enabled = await TwoFactorService.instance.is2FAEnabled(userId);
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _enable2FA() async {
    setState(() => _loading = true);
    try {
      final secret = await TwoFactorService.instance.enable2FA();
      setState(() {
        _secret = secret;
        _enabled = true;
        _loading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LAll.all_2fa_enabled_successfully, ref))),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    }
  }

  Future<void> _disable2FA() async {
    setState(() => _loading = true);
    try {
      await TwoFactorService.instance.disable2FA();
      setState(() {
        _enabled = false;
        _secret = null;
        _loading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LAll.all_2fa_disabled, ref))),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t(LAll.all_twofactor_authentication, ref))),
      body: _loading
          ? const PageSkeleton(type: 'settings')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t(LAll.all_2fa_status, ref), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ModernBadge(
                            label: _enabled ? 'Enabled' : 'Disabled',
                            color: _enabled ? Colors.blue : Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(t(LAll.all_add_an_extra_layer_of_security_to_your_account, ref)),
                      const SizedBox(height: 16),
                      if (!_enabled)
                        ElevatedButton(
                          onPressed: _enable2FA,
                          child: Text(t(LAll.all_enable_2fa, ref)),
                        )
                      else
                        ElevatedButton(
                          onPressed: _disable2FA,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: Text(t(LAll.all_disable_2fa, ref)),
                        ),
                    ],
                  ),
                ),
                if (_secret != null) ...[
                  const SizedBox(height: 16),
                  ModernCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t(LAll.all_secret_key, ref), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_secret!, style: const TextStyle(fontFamily: 'monospace')),
                        ),
                        const SizedBox(height: 8),
                        Text(t(LAll.all_save_this_key_in_a_secure_location, ref), style: const TextStyle(fontSize: 12, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t(LAll.all_how_it_works, ref), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(t(LAll.all_1_enable_2fa_on_your_account, ref)),
                      Text(t(LAll.all_2_save_your_secret_key, ref)),
                      Text(t(LAll.all_3_enter_otp_code_when_logging_in, ref)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
