import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../learn/application/learn_providers.dart';
import '../domain/tutor_persona.dart';

// ─────────────────────────────────────────────────────────────
// Clés SharedPreferences
// ─────────────────────────────────────────────────────────────

const _kTutorKey = 'selected_tutor_id';
const _kTutorPendingKey = 'selected_tutor_pending_sync';

/// Choix de compagnon connu localement.
@immutable
class TutorPreference {
  const TutorPreference({this.id, this.pendingSync = false});

  final String? id;

  /// Vrai quand ce choix n'a pas encore été confirmé par le profil.
  ///
  /// Registre de décisions : un élève doit pouvoir changer de compagnon même
  /// quand l'écriture du profil échoue. Tant que la synchronisation n'a pas
  /// abouti, son choix prime sur la valeur encore stockée côté serveur.
  final bool pendingSync;

  @override
  bool operator ==(Object other) =>
      other is TutorPreference &&
      other.id == id &&
      other.pendingSync == pendingSync;

  @override
  int get hashCode => Object.hash(id, pendingSync);
}

final tutorPreferenceProvider =
    StateNotifierProvider<TutorPreferenceNotifier, TutorPreference>(
      (ref) => TutorPreferenceNotifier(),
    );

/// Identifiant retenu localement, sans notion de synchronisation.
final selectedTutorIdProvider = Provider<String?>(
  (ref) => ref.watch(tutorPreferenceProvider).id,
);

/// Vrai quand le choix local attend encore d'être écrit au profil.
final tutorSelectionPendingProvider = Provider<bool>(
  (ref) => ref.watch(tutorPreferenceProvider).pendingSync,
);

/// Derive directement le [TutorPersona] depuis l'ID.
final selectedTutorProvider = Provider<TutorPersona?>((ref) {
  final preference = ref.watch(tutorPreferenceProvider);
  final profileId = ref
      .watch(studentAcademicContextProvider)
      .valueOrNull
      ?.tutorId;

  // Le profil fait autorité une fois la synchronisation aboutie : il porte le
  // choix venu d'un autre appareil. Mais tant qu'un changement local attend
  // d'être écrit, c'est lui qui prime — sinon le profil réimposerait aussitôt
  // l'ancien compagnon et le changement paraîtrait impossible.
  final id = preference.pendingSync
      ? (preference.id ?? profileId)
      : (profileId ?? preference.id);
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

class TutorPreferenceNotifier extends StateNotifier<TutorPreference> {
  TutorPreferenceNotifier() : super(const TutorPreference()) {
    _load();
  }

  /// Vrai dès qu'un choix explicite a eu lieu.
  ///
  /// L'hydratation depuis le cache est asynchrone : sans ce garde-fou, elle
  /// pouvait reprendre la main entre les deux écritures d'un `select` et
  /// effacer l'indicateur de synchronisation qui venait d'être posé.
  var _chosen = false;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kTutorKey);
      if (!mounted || saved == null || _chosen) return;
      final canonicalId = TutorPersona.resolveId(saved);
      state = TutorPreference(
        id: canonicalId,
        pendingSync: prefs.getBool(_kTutorPendingKey) ?? false,
      );
      if (canonicalId != saved) {
        await prefs.setString(_kTutorKey, canonicalId);
      }
    } catch (_) {
      // Local storage is a convenience cache. Profile-backed selection and
      // authentication must remain usable if the cache is unavailable.
    }
  }

  /// Enregistre le compagnon choisi.
  ///
  /// [pendingSync] indique que le profil serveur ne porte pas encore ce choix.
  Future<void> select(String tutorId, {bool pendingSync = false}) async {
    final canonicalId = TutorPersona.resolveId(tutorId);
    _chosen = true;
    state = TutorPreference(id: canonicalId, pendingSync: pendingSync);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTutorKey, canonicalId);
      if (pendingSync) {
        await prefs.setBool(_kTutorPendingKey, true);
      } else {
        await prefs.remove(_kTutorPendingKey);
      }
    } catch (_) {
      // The in-memory choice remains active and the profile is authoritative.
    }
  }

  /// Le profil porte désormais le choix : il reprend la main.
  Future<void> markSynced() async {
    _chosen = true;
    if (mounted) state = TutorPreference(id: state.id);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kTutorPendingKey);
    } catch (_) {
      // Ne jamais faire échouer un parcours pour un cache optionnel.
    }
  }

  Future<void> clear() async {
    _chosen = false;
    if (mounted) state = const TutorPreference();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kTutorKey);
      await prefs.remove(_kTutorPendingKey);
    } catch (_) {
      // Clearing the optional cache must not fail the user flow.
    }
  }
}
