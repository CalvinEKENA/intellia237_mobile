import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthEntryPreferences {
  static const _storageKey = 'has_authenticated_before';
  static bool _hasAuthenticatedBefore = false;

  static Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    _hasAuthenticatedBefore = prefs.getBool(_storageKey) ?? false;
  }

  Future<bool> hasAuthenticatedBefore() async => _hasAuthenticatedBefore;

  Future<void> markAuthenticated() async {
    _hasAuthenticatedBefore = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, true);
  }

  Future<void> clearForTesting() async {
    _hasAuthenticatedBefore = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

final hasAuthenticatedBeforeProvider = StateProvider<bool>(
  (_) => AuthEntryPreferences._hasAuthenticatedBefore,
);
