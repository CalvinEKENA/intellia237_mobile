import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final id = ref.watch(selectedTutorIdProvider);
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
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kTutorKey);
    if (mounted) state = saved;
  }

  Future<void> select(String tutorId) async {
    state = tutorId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTutorKey, tutorId);
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTutorKey);
  }
}
