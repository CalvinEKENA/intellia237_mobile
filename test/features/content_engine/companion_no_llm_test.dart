import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/content_engine/domain/companion_action.dart';
import 'package:intellia237/features/content_engine/domain/pedagogy.dart';
import 'package:intellia237/features/content_engine/engine/companion_engine.dart';

import 'pack_fixture.dart';

/// Paquets et modules qui ouvriraient une porte vers le réseau ou vers un
/// modèle de langage. Le Compagnon de la Content Engine n'en utilise aucun.
const _forbiddenPackages = [
  'package:http/',
  'package:dio/',
  'package:cloud_functions/',
  'package:firebase_ai/',
  'package:firebase_vertexai/',
  'package:google_generative_ai/',
  'package:firebase_storage/',
  'package:cloud_firestore/',
  'dart:io',
  'dart:html',
];

/// Modules de l'application reliés au tuteur conversationnel en ligne.
const _forbiddenAppModules = ['ai_companion', 'tutor/data', 'gemini', 'llm'];

final _importPattern = RegExp(r'''^(?:import|export)\s+'([^']+)'.*;''');

List<String> _imports(File file) => [
  for (final line in file.readAsLinesSync())
    if (_importPattern.firstMatch(line.trim()) case final match?)
      match.group(1)!,
];

/// Fermeture des imports relatifs à partir de [entry] (reste dans `lib/`).
Map<String, List<String>> _closure(String entry) {
  final seen = <String, List<String>>{};
  final pending = [File(entry).absolute.path];
  while (pending.isNotEmpty) {
    final path = pending.removeLast();
    if (seen.containsKey(path)) continue;
    final imports = _imports(File(path));
    seen[path] = imports;
    for (final target in imports) {
      if (target.contains(':')) continue;
      pending.add(File(path).parent.uri.resolve(target).toFilePath());
    }
  }
  return seen;
}

class _RecordingHttpOverrides extends HttpOverrides {
  int created = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    created++;
    throw StateError('Le Compagnon a tenté une requête réseau.');
  }
}

void main() {
  group('Compagnon : aucune dépendance à un modèle de langage', () {
    test('le moteur, ses règles et ses données ne touchent ni réseau ni '
        'modèle de langage (fermeture complète des imports)', () {
      const entries = [
        'lib/features/content_engine/engine/companion_engine.dart',
        'lib/features/content_engine/engine/companion_name_policy.dart',
        'lib/features/content_engine/domain/companion_action.dart',
      ];
      final offenders = <String>[];
      for (final entry in entries) {
        _closure(entry).forEach((file, imports) {
          for (final target in imports) {
            final external = target.contains(':');
            final allowed =
                !external ||
                target == 'package:flutter/foundation.dart' ||
                target == 'package:meta/meta.dart' ||
                target.startsWith('package:collection/') ||
                target == 'dart:math' ||
                target == 'dart:convert' ||
                target == 'dart:collection';
            if (!allowed) offenders.add('$file → $target');
            if (_forbiddenAppModules.any(target.contains)) {
              offenders.add('$file → $target');
            }
          }
        });
      }
      expect(offenders, isEmpty);
    });

    test('le fil Mon Parcours (fabrique, classement, historique) reste '
        'déterministe et local', () {
      const entries = [
        'lib/features/content_engine/feed/learning_card_factory.dart',
        'lib/features/content_engine/feed/learning_feed_ranker.dart',
      ];
      final offenders = <String>[];
      for (final entry in entries) {
        _closure(entry).forEach((file, imports) {
          for (final target in imports) {
            final allowed =
                !target.contains(':') ||
                target == 'package:flutter/foundation.dart' ||
                target ==
                    'package:shared_preferences/shared_preferences.dart' ||
                target == 'dart:math' ||
                target == 'dart:convert';
            if (!allowed || _forbiddenAppModules.any(target.contains)) {
              offenders.add('$file → $target');
            }
          }
        });
      }
      expect(offenders, isEmpty);
    });

    test('la carte de pack du fil n\'importe aucun client réseau ni tuteur '
        'en ligne', () {
      const view =
          'lib/features/flow/presentation/widgets/flow_learning_card_view.dart';
      for (final target in _imports(File(view))) {
        expect(
          _forbiddenPackages.any(target.startsWith),
          isFalse,
          reason: target,
        );
        expect(
          _forbiddenAppModules.any(target.contains),
          isFalse,
          reason: target,
        );
      }
    });

    test('la fenêtre du Compagnon n\'importe aucun client réseau ni tuteur '
        'en ligne', () {
      const sheet =
          'lib/features/content_engine/presentation/widgets/companion_sheet.dart';
      final imports = _imports(File(sheet));
      for (final target in imports) {
        expect(
          _forbiddenPackages.any(target.startsWith),
          isFalse,
          reason: target,
        );
        expect(
          _forbiddenAppModules.any(target.contains),
          isFalse,
          reason: target,
        );
      }
      final source = File(sheet).readAsStringSync();
      for (final symbol in ['httpsCallable', 'TutorService', 'Gemini']) {
        expect(source.contains(symbol), isFalse, reason: symbol);
      }
    });

    test('à l\'exécution, aucune connexion réseau n\'est ouverte', () {
      final chapter = pilotChapter();
      final overrides = _RecordingHttpOverrides();
      HttpOverrides.runZoned(() {
        final companion = CompanionEngine(chapter);
        for (final concept in chapter.concepts.values) {
          final context = CompanionContext(
            conceptId: concept.id,
            lessonNumber: concept.lessonNumber ?? 1,
          );
          for (final action in CompanionAction.values) {
            companion.respond(action, context);
          }
        }
        for (final text in [
          'c\'est quoi une congruence',
          'je comprends pas le pgcd',
          'photosynthèse',
          '',
        ]) {
          companion.ask(text);
        }
      }, createHttpClient: overrides.createHttpClient);
      expect(overrides.created, 0);
    });
  });

  group('Compagnon : questions libres, sans rien inventer', () {
    final chapter = pilotChapter();
    final companion = CompanionEngine(chapter);

    test('faute de frappe tolérée', () {
      expect(companion.ask('congruance').concept?.id, 'congruence');
    });

    test('synonyme scolaire : PGCD', () {
      expect(companion.ask('comment trouver le pgcd').concept?.id, 'gcd_lcm');
    });

    test('hors du pack : pas de réponse inventée, notion introuvable', () {
      final reply = companion.ask('photosynthèse des plantes vertes');
      expect(reply.gap, CompanionGap.unknownTopic);
      expect(reply.parts, isEmpty);
    });

    test('la réponse est un texte du pack, mot pour mot', () {
      final reply = companion.ask('congruence');
      final text = reply.parts.single.text;
      final concept = chapter.concepts['congruence']!;
      expect(text, concept.explanation(ExplanationMode.standard));
    });
  });

  group('« Donne-moi un exemple »', () {
    final chapter = pilotChapter();
    final companion = CompanionEngine(chapter);

    test('toujours proposé, même si le pack ne le déclare pas', () {
      expect(
        chapter.companion.effectiveActions,
        contains(CompanionAction.example),
      );
    });

    test('exemples tirés du pack, ou manque signalé honnêtement', () {
      for (final concept in chapter.concepts.values) {
        final reply = companion.respond(
          CompanionAction.example,
          CompanionContext(
            conceptId: concept.id,
            lessonNumber: concept.lessonNumber ?? 1,
          ),
        );
        if (reply.gap != null) {
          expect(reply.gap, CompanionGap.noExample);
          continue;
        }
        final questions = chapter.questions.map((q) => q.prompt).toSet();
        final core = {
          for (final lesson in chapter.lessons) ...lesson.verifiedCore,
        };
        for (final part in reply.parts) {
          final first = part.text.split('\n→ ').first;
          expect(
            questions.contains(first) || core.contains(first),
            isTrue,
            reason: part.text,
          );
        }
      }
    });

    test('« Teste-moi » suit la maîtrise, sauf si l\'élève a choisi', () {
      const base = (conceptId: 'congruence', lessonNumber: 4);
      final weak = companion.respond(
        CompanionAction.testMe,
        CompanionContext(
          conceptId: base.conceptId,
          lessonNumber: base.lessonNumber,
          mastery: 10,
          difficulty: 3,
        ),
      );
      expect(weak.question?.difficulty, 1);
      final chosen = companion.respond(
        CompanionAction.testMe,
        CompanionContext(
          conceptId: base.conceptId,
          lessonNumber: base.lessonNumber,
          mastery: 10,
          difficulty: 3,
          difficultyChosen: true,
        ),
      );
      expect(chosen.question?.difficulty, 3);
    });
  });

  group('prénom avec parcimonie', () {
    test('premier échange important : le prénom, puis plus rien', () {
      final policy = CompanionNamePolicy();
      expect(policy.nameFor(CompanionMoment.routine, 'awa'), 'Awa');
      expect(policy.nameFor(CompanionMoment.routine, 'Awa'), isNull);
      expect(policy.nameFor(CompanionMoment.routine, 'Awa'), isNull);
    });

    test('jamais deux fois de suite, même après des erreurs', () {
      final policy = CompanionNamePolicy();
      expect(policy.nameFor(CompanionMoment.afterErrors, 'Awa'), 'Awa');
      expect(policy.nameFor(CompanionMoment.afterErrors, 'Awa'), isNull);
      expect(policy.nameFor(CompanionMoment.notableSuccess, 'Awa'), isNull);
      expect(policy.nameFor(CompanionMoment.routine, 'Awa'), isNull);
      expect(policy.nameFor(CompanionMoment.notableSuccess, 'Awa'), 'Awa');
    });

    test('une réponse ordinaire ne porte jamais le prénom', () {
      final policy = CompanionNamePolicy()
        ..nameFor(CompanionMoment.routine, 'A');
      for (var i = 0; i < 20; i++) {
        expect(policy.nameFor(CompanionMoment.routine, 'Awa'), isNull);
      }
    });

    test('sans prénom exploitable : échange naturel, aucun trou', () {
      expect(CompanionNamePolicy.usableFirstName(null), isNull);
      expect(CompanionNamePolicy.usableFirstName('  '), isNull);
      expect(CompanionNamePolicy.usableFirstName('user_4821'), isNull);
      expect(CompanionNamePolicy.usableFirstName('x'), isNull);
      expect(
        CompanionNamePolicy.usableFirstName('jean-paul ekena'),
        'Jean-paul',
      );
      final policy = CompanionNamePolicy();
      expect(policy.nameFor(CompanionMoment.firstInteraction, null), isNull);
    });
  });
}
