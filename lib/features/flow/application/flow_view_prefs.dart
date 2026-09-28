import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/application/auth_controller.dart';
import '../../content_engine/domain/curriculum.dart';
import '../domain/flow_card.dart';

/// Deux façons de parcourir le même fil : le mélange personnalisé, ou une
/// matière à la fois. Un filtre d'affichage, jamais une seconde progression.
enum FlowViewMode { forYou, bySubject }

@immutable
class FlowViewPrefs {
  const FlowViewPrefs({this.mode = FlowViewMode.forYou, this.subject});

  final FlowViewMode mode;

  /// Dernière matière choisie en mode « Par matière ».
  final String? subject;

  Map<String, Object?> toJson() => {'mode': mode.name, 'subject': subject};

  static FlowViewPrefs fromJson(Object? raw) {
    if (raw is! Map) return const FlowViewPrefs();
    final mode = FlowViewMode.values
        .where((m) => m.name == raw['mode'])
        .firstOrNull;
    final subject = raw['subject'];
    return FlowViewPrefs(
      mode: mode ?? FlowViewMode.forYou,
      subject: subject is String && subject.isNotEmpty ? subject : null,
    );
  }
}

/// Choix d'affichage du Parcours, mémorisés sur l'appareil pour cet élève.
class FlowViewPrefsController extends AsyncNotifier<FlowViewPrefs> {
  static String keyFor(String learnerId) => 'flow_view_v1_$learnerId';

  String get _learnerId => ref.read(authControllerProvider).userId ?? 'guest';

  @override
  Future<FlowViewPrefs> build() async {
    ref.watch(authControllerProvider.select((state) => state.userId));
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(keyFor(_learnerId));
      return raw == null
          ? const FlowViewPrefs()
          : FlowViewPrefs.fromJson(jsonDecode(raw));
    } catch (_) {
      return const FlowViewPrefs();
    }
  }

  Future<void> save(FlowViewPrefs next) async {
    state = AsyncData(next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyFor(_learnerId), jsonEncode(next.toJson()));
    } catch (_) {
      // Confort local : le choix vaut pour la séance.
    }
  }
}

final flowViewPrefsProvider =
    AsyncNotifierProvider<FlowViewPrefsController, FlowViewPrefs>(
      FlowViewPrefsController.new,
    );

/// Matière d'une carte du fil, en clé canonique (`physique`, `anglais`…).
String flowCardSubjectKey(FlowCard card) => card is FlowLearningCard
    ? card.chapter.curriculum.subjectKey
    : canonicalSubjectKey(card.subject.label);

/// Libellé de matière d'une carte, tel que son contenu le nomme.
String flowCardSubjectLabel(FlowCard card) => card is FlowLearningCard
    ? card.chapter.curriculum.subject
    : card.subject.label;

/// Les matières présentes dans [cards], dans l'ordre de leur première carte.
List<({String key, String label})> flowSubjects(Iterable<FlowCard> cards) {
  final seen = <String>{};
  return [
    for (final card in cards)
      if (seen.add(flowCardSubjectKey(card)))
        (key: flowCardSubjectKey(card), label: flowCardSubjectLabel(card)),
  ];
}
