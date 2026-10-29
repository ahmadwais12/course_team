import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingStatusProvider = StateNotifierProvider<OnboardingStatusNotifier, bool?>((ref) {
  return OnboardingStatusNotifier();
});

class OnboardingStatusNotifier extends StateNotifier<bool?> {
  OnboardingStatusNotifier() : super(null) { // Use null to indicate loading
    _loadOnboardingStatus();
  }

  Future<void> _loadOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('has_seen_onboarding') ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    state = true;
  }
}
