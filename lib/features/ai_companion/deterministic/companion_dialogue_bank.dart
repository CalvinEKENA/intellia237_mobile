import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'companion_text.dart';

/// Compagnons connus de la banque. Kira et Léo partagent les intentions ;
/// seules leurs formulations diffèrent.
const companionPersonaIds = ['kira', 'leo'];

/// Clés de réponse de la banque, avec le nombre minimal de variantes par
/// compagnon. Les familles d'intention principales en exigent huit ; les
/// situations particulières (aucune donnée, retour de quiz…) quatre.
const companionResponseMinimums = <String, int>{
  'greeting': 8,
  'how_are_you': 8,
  'thanks': 8,
  'goodbye': 8,
  'motivation': 8,
  'tired': 8,
  'discouraged': 8,
  'self_doubt': 8,
  'exam_stress': 8,
  'dont_understand': 8,
  'dont_understand_lesson': 4,
  'help': 8,
  'want_to_study': 8,
  'want_to_study_resume': 4,
  'want_quiz': 8,
  'want_quiz_subject': 4,
  'want_quiz_none': 4,
  'want_subject': 8,
  'want_math': 8,
  'want_english': 8,
  'want_physics': 8,
  'want_subject_no_quiz': 4,
  'want_subject_missing': 4,
  'what_should_i_review': 8,
  'what_should_i_review_no_data': 4,
  'ask_progress': 8,
  'ask_progress_subject': 4,
  'ask_progress_no_data': 4,
  'who_are_you': 8,
  'are_you_ai': 8,
  'compliment': 8,
  'bored': 8,
  'surprise_me': 8,
  'surprise_me_none': 4,
  'course_topic': 8,
  'unsupported_freeform': 8,
  'unknown': 8,
  'affirm': 8,
  'affirm_open': 4,
  'decline': 8,
  'quiz_return_high': 6,
  'quiz_return_mid': 6,
  'quiz_return_low': 6,
};

/// Intentions reconnues à partir des déclencheurs de la banque.
const companionTriggerIntents = [
  'greeting',
  'how_are_you',
  'thanks',
  'goodbye',
  'motivation',
  'tired',
  'discouraged',
  'self_doubt',
  'exam_stress',
  'dont_understand',
  'help',
  'want_to_study',
  'want_quiz',
  'what_should_i_review',
  'ask_progress',
  'who_are_you',
  'are_you_ai',
  'compliment',
  'bored',
  'surprise_me',
  'affirm',
  'decline',
];

/// Emplacements autorisés dans une réponse.
const companionPlaceholders = {
  'firstName',
  'subjectName',
  'SubjectName',
  'quizCount',
  'score',
  'total',
  'percent',
  'started',
  'mastered',
  'topicTitle',
  'lessonTitle',
};

const companionSuggestionKeys = [
  'review',
  'quiz',
  'what_to_review',
  'subject',
  'progress',
  'surprise',
];

/// Longueur maximale d'une réponse : une à trois phrases, jamais un pavé.
const companionMaxResponseLength = 260;

final _placeholder = RegExp(r'\{(\w+)\}');

class CompanionDialogueException implements Exception {
  const CompanionDialogueException(this.message);
  final String message;

  @override
  String toString() => 'CompanionDialogueException: $message';
}

@immutable
class CompanionSubjectVocabulary {
  const CompanionSubjectVocabulary({
    required this.key,
    required this.name,
    required this.aliases,
  });

  /// Clé de matière des packs (`mathematiques`, `anglais`…).
  final String key;

  /// Nom à insérer dans une phrase (« maths », « English »).
  final String name;

  /// Formes normalisées par lesquelles l'élève la nomme.
  final List<String> aliases;
}

/// Banque de dialogues d'une langue, lue depuis
/// `assets/companions/dialogue/<langue>.json` et validée.
@immutable
class CompanionDialogueBank {
  const CompanionDialogueBank({
    required this.language,
    required this.normalization,
    required this.subjects,
    required this.questionMarkers,
    required this.triggers,
    required this.suggestions,
    required this.responses,
  });

  final String language;

  /// Variantes d'écriture courantes (« stp », « jveux »), déjà normalisées.
  final Map<String, String> normalization;
  final List<CompanionSubjectVocabulary> subjects;

  /// Marques d'une demande d'explication libre (« explique », « c'est
  /// quoi »), normalisées.
  final List<String> questionMarkers;

  /// Déclencheurs normalisés, par intention.
  final Map<String, List<String>> triggers;
  final Map<String, String> suggestions;

  /// `clé → compagnon → variantes`.
  final Map<String, Map<String, List<String>>> responses;

  List<String> variants(String key, String personaId) =>
      responses[key]?[personaId] ??
      responses[key]?[companionPersonaIds.first] ??
      const [];

  CompanionSubjectVocabulary? subject(String key) =>
      subjects.where((s) => s.key == key).firstOrNull;

  /// Lit et valide [raw]. Toute anomalie est une erreur : une banque
  /// incomplète ne doit jamais atteindre un élève.
  static CompanionDialogueBank parse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const CompanionDialogueException('Banque de dialogues illisible.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const CompanionDialogueException('Objet racine attendu.');
    }
    if (decoded['schemaVersion'] != 1) {
      throw const CompanionDialogueException('schemaVersion 1 attendu.');
    }
    final language = decoded['language'];
    if (language is! String || language.isEmpty) {
      throw const CompanionDialogueException('language manquant.');
    }

    final normalizationMap = _map(decoded['normalization'], 'normalization');
    final normalization = <String, String>{
      for (final entry in normalizationMap.entries)
        normalizeCompanionText(entry.key): normalizeCompanionText(
          _string(entry.value, 'normalization.${entry.key}', allowEmpty: true),
        ),
    };
    String normalized(String text) =>
        normalizeCompanionText(text, replacements: normalization);

    final subjects = [
      for (final entry in _map(decoded['subjects'], 'subjects').entries)
        () {
          final subject = _map(entry.value, 'subjects.${entry.key}');
          return CompanionSubjectVocabulary(
            key: entry.key,
            name: _string(subject['name'], 'subjects.${entry.key}.name'),
            aliases: [
              for (final alias in _stringList(
                subject['aliases'],
                'subjects.${entry.key}.aliases',
              ))
                normalized(alias),
            ],
          );
        }(),
    ];

    final triggerMap = _map(decoded['triggers'], 'triggers');
    final triggers = <String, List<String>>{};
    for (final intent in companionTriggerIntents) {
      final phrases = _stringList(triggerMap[intent], 'triggers.$intent');
      triggers[intent] = [for (final phrase in phrases) normalized(phrase)];
    }

    final suggestionMap = _map(decoded['suggestions'], 'suggestions');
    final suggestions = <String, String>{
      for (final key in companionSuggestionKeys)
        key: _string(suggestionMap[key], 'suggestions.$key'),
    };

    final responseMap = _map(decoded['responses'], 'responses');
    final responses = <String, Map<String, List<String>>>{};
    for (final MapEntry(key: key, value: minimum)
        in companionResponseMinimums.entries) {
      final byPersona = _map(responseMap[key], 'responses.$key');
      final lists = <String, List<String>>{};
      for (final persona in companionPersonaIds) {
        final variants = _stringList(
          byPersona[persona],
          'responses.$key.$persona',
        );
        if (variants.length < minimum) {
          throw CompanionDialogueException(
            'responses.$key.$persona : $minimum variantes au moins '
            '(${variants.length}).',
          );
        }
        if (variants.toSet().length != variants.length) {
          throw CompanionDialogueException(
            'responses.$key.$persona : variante en double.',
          );
        }
        for (final variant in variants) {
          if (variant.length > companionMaxResponseLength) {
            throw CompanionDialogueException(
              'responses.$key.$persona : réponse trop longue « $variant ».',
            );
          }
          for (final match in _placeholder.allMatches(variant)) {
            if (!companionPlaceholders.contains(match.group(1))) {
              throw CompanionDialogueException(
                'responses.$key.$persona : emplacement inconnu '
                '« ${match.group(0)} ».',
              );
            }
          }
        }
        lists[persona] = List.unmodifiable(variants);
      }
      if (lists['kira']!.toSet().intersection(lists['leo']!.toSet()).length >
          lists['kira']!.length ~/ 2) {
        throw CompanionDialogueException(
          'responses.$key : Kira et Léo doivent parler différemment.',
        );
      }
      responses[key] = Map.unmodifiable(lists);
    }
    final unknownKeys = responseMap.keys.toSet().difference(
      companionResponseMinimums.keys.toSet(),
    );
    if (unknownKeys.isNotEmpty) {
      throw CompanionDialogueException(
        'Clés de réponse inconnues : ${unknownKeys.join(', ')}.',
      );
    }

    return CompanionDialogueBank(
      language: language,
      normalization: Map.unmodifiable(normalization),
      subjects: List.unmodifiable(subjects),
      questionMarkers: List.unmodifiable([
        for (final marker in _stringList(
          decoded['questionMarkers'],
          'questionMarkers',
        ))
          normalized(marker),
      ]),
      triggers: Map.unmodifiable(triggers),
      suggestions: Map.unmodifiable(suggestions),
      responses: Map.unmodifiable(responses),
    );
  }

  static Map<String, dynamic> _map(Object? value, String path) {
    if (value is Map<String, dynamic>) return value;
    throw CompanionDialogueException('$path : objet attendu.');
  }

  static String _string(Object? value, String path, {bool allowEmpty = false}) {
    if (value is String && (allowEmpty || value.trim().isNotEmpty)) {
      return value;
    }
    throw CompanionDialogueException('$path : texte attendu.');
  }

  static List<String> _stringList(Object? value, String path) {
    if (value is! List || value.isEmpty) {
      throw CompanionDialogueException('$path : liste non vide attendue.');
    }
    return [
      for (final (index, item) in value.indexed) _string(item, '$path[$index]'),
    ];
  }
}
