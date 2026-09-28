import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/application/auth_controller.dart';
import '../../content_engine/application/content_providers.dart';
import '../../content_engine/application/subject_journey.dart';
import '../../tutor/application/tutor_preference_provider.dart';
import '../../tutor/domain/tutor_persona.dart';
import '../domain/pack_quiz.dart';
import 'pack_quiz_session.dart';

/// Les quiz des packs de la classe, tirés des parcours déjà chargés (packs
/// embarqués ou en cache) : disponibles hors ligne, sans autre lecture.
final packQuizCatalogProvider = Provider<AsyncValue<PackQuizCatalog>>(
  (ref) =>
      ref.watch(subjectJourneysProvider).whenData(PackQuizCatalog.fromJourneys),
);

/// Séances terminées de l'élève (sur cet appareil), les plus récentes
/// d'abord.
final packQuizHistoryProvider =
    AsyncNotifierProvider<PackQuizHistory, List<PackQuizHistoryEntry>>(
      PackQuizHistory.new,
    );

class PackQuizHistory extends AsyncNotifier<List<PackQuizHistoryEntry>> {
  static const _keyPrefix = 'pack_quiz_history_v1_';
  static const maxEntries = 30;

  String get _key =>
      '$_keyPrefix${ref.read(authControllerProvider).userId ?? 'guest'}';

  @override
  Future<List<PackQuizHistoryEntry>> build() async {
    ref.watch(authControllerProvider.select((auth) => auth.userId));
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final item in decoded) ?PackQuizHistoryEntry.fromJson(item)];
    } catch (_) {
      return const [];
    }
  }

  Future<void> record(PackQuizHistoryEntry entry) async {
    final current = state.valueOrNull ?? await future;
    final next = [entry, ...current].take(maxEntries).toList();
    state = AsyncData(next);
    try {
      await (await SharedPreferences.getInstance()).setString(
        _key,
        jsonEncode([for (final item in next) item.toJson()]),
      );
    } catch (_) {
      // L'historique est un confort : la séance reste comptée dans la
      // maîtrise même s'il ne s'écrit pas.
    }
  }
}

/// Tentative suivante d'un quiz dans un mode : le nombre de séances déjà
/// terminées. Rejouer change l'ordre des questions, de façon reproductible.
int nextPackQuizAttempt(
  List<PackQuizHistoryEntry> history,
  String setId,
  PackQuizMode mode,
) =>
    history.where((entry) => entry.setId == setId && entry.mode == mode).length;

/// Enregistre une réponse de quiz dans la maîtrise de l'élève : la même
/// que celle des exercices des leçons (aucune seconde progression).
PackQuizRecorder packQuizRecorder(WidgetRef ref) =>
    (item, correct) => ref
        .read(learnerContentControllerProvider.notifier)
        .recordAnswer(
          chapter: item.chapter,
          question: item.question,
          correct: correct,
        );

/// Le compagnon de l'élève (Kira ou Léo), le même que partout ailleurs.
final quizCompanionProvider = Provider<TutorPersona>(
  (ref) => ref.watch(selectedTutorProvider) ?? TutorPersona.resolve('kira'),
);
