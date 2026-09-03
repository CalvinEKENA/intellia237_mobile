import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../learn/application/learn_providers.dart';
import '../domain/tutor_persona.dart';

// ─────────────────────────────────────────────────────────────
// Clé SharedPreferences
// ─────────────────────────────────────────────────────────────

const _kTutorKey = 'selected_tutor_id';

// ─────────────────────────────────────────────────────────────
// Provider exposant l'ID du tuteur sélectionné
// ─────────────────────────────────────────────────────────────

final selectedTutorIdProvider =
    StateNotifierProvider<TutorPreferenceNotifier, String?>(
      (ref) => TutorPreferenceNotifier(),
    );

/// Derive directement le [TutorPersona] depuis l'ID.
final selectedTutorProvider = Provider<TutorPersona?>((ref) {
  final cachedId = ref.watch(selectedTutorIdProvider);
  final profileId = ref
      .watch(studentAcademicContextProvider)
      .valueOrNull
      ?.tutorId;
  // Firestore is authoritative. SharedPreferences only avoids an empty card
  // while the profile is loading and may be absent on a second device.
  final id = profileId ?? cachedId;
  if (id == null) return null;
  try {
    // Les identifiants des anciens compagnons sont resolus via TutorPersona.resolve
    // pour conserver les preferences deja enregistrees en production.
    return TutorPersona.resolve(id);
  } catch (_) {
    return null;
  }
});

// ─────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────

class TutorPreferenceNotifier extends StateNotifier<String?> {
  TutorPreferenceNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kTutorKey);
      if (mounted && saved != null) {
        final canonicalId = TutorPersona.resolveId(saved);
        state = canonicalId;
        if (canonicalId != saved) {
          await prefs.setString(_kTutorKey, canonicalId);
        }
      }
    } catch (_) {
      // Local storage is a convenience cache. Profile-backed selection and
      // authentication must remain usable if the cache is unavailable.
    }
  }

  Future<void> select(String tutorId) async {
    final canonicalId = TutorPersona.resolveId(tutorId);
    state = canonicalId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTutorKey, canonicalId);
    } catch (_) {
      // The in-memory choice remains active and the profile is authoritative.
    }
  }

  Future<void> clear() async {
    state = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kTutorKey);
    } catch (_) {
      // Clearing the optional cache must not fail the user flow.
    }
  }
}
