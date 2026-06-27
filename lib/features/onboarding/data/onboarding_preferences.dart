import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestion du flag de premier parcours pre-auth.
class OnboardingPreferences {
  static const _storageKey = 'has_seen_onboarding';
  static bool _hasSeenOnboarding = false;

  static Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool(_storageKey) ?? false;
  }

  Future<bool> hasSeenOnboarding() async => _hasSeenOnboarding;

  Future<void> setSeenOnboarding(bool value) async {
    _hasSeenOnboarding = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, value);
  }
}

/// Provider Riverpod pour le flag hasSeenOnboarding.
final hasSeenOnboardingProvider = StateProvider<bool>(
  (_) => OnboardingPreferences._hasSeenOnboarding,
);

Future<void> markOnboardingSeen(WidgetRef ref) async {
  final prefs = OnboardingPreferences();
  ref.read(hasSeenOnboardingProvider.notifier).state = true;
  await prefs.setSeenOnboarding(true);
}
