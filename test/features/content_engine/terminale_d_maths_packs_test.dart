import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/academics/choice_order.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/application/learning_feed_providers.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/data/content_pack_parser.dart';
import 'package:intellia237/features/content_engine/domain/chapter.dart';
import 'package:intellia237/features/content_engine/domain/pack_catalog.dart';
import 'package:intellia237/features/content_engine/domain/question.dart';
import 'package:intellia237/features/content_engine/engine/answer_checker.dart';
import 'package:intellia237/features/content_engine/engine/companion_engine.dart';
import 'package:intellia237/features/content_engine/feed/learning_card.dart';
import 'package:intellia237/features/content_engine/feed/learning_card_factory.dart';
import 'package:intellia237/features/content_engine/feed/learning_card_history.dart';

import '../../../tool/content/pack_bundle_builder.dart';
import 'pack_fixture.dart';

/// Mathématiques Terminale D, chapitres 1 à 3 : les trois packs embarqués
/// passent par la même Content Engine, pour Apprendre, Mon Parcours, les
/// QCM et le Compagnon, sans réseau ni modèle de langage.
const _terminaleD = ClassKey('terminale', series: 'd');
const _sixieme = ClassKey('sixieme');

const _ch01 = 'maths_td_ch01_arithmetique';
const _ch02 = 'maths_td_ch02_nombres_complexes_algebrique';
const _ch03 = 'maths_td_ch03_fonctions_numeriques';

class _Student extends AuthController {
  @override
  AuthState build() =>
      const AuthState.authenticated(role: AppRole.student, userId: 'eleve-td');
}

void main() {
  late ContentPackRepository repository;
  setUp(
    () => repository = ContentPackRepository(source: DiskContentPackSource()),
  );

  Future<Chapter> chapter(String id) => repository.chapter(id);

  bool grade(Question question, String text) =>
      const AnswerChecker().grade(question, TextResponse(text)).correct;

  bool gradeFields(Question question, Map<String, String> fields) =>
      const AnswerChecker().grade(question, FieldsResponse(fields)).correct;

  group('Apprendre', () {
    test('Terminale D : Mathématiques, chapitres 1, 2 et 3 dans la même '
        'matière', () async {
      final subjects = await repository.subjectsFor(_terminaleD);
      final maths = subjects.singleWhere((s) => s.key == 'mathematiques');
      expect(maths.chapters.map((c) => c.contentId), [_ch01, _ch02, _ch03]);
      expect(maths.chapters.map((c) => c.curriculum.chapterTitle), [
        'Arithmétique',
        'Nombres complexes : approche algébrique',
        "Fonctions numériques d'une variable réelle",
      ]);
      final chapters = await repository.chaptersFor(_terminaleD);
      expect(chapters.map((c) => c.contentId), [_ch01, _ch02, _ch03]);
      expect(chapters.every((c) => c.isPlayable), isTrue);
    });

    test('Sixième : aucun des trois chapitres', () async {
      expect(await repository.subjectsFor(_sixieme), isEmpty);
      expect(await repository.chaptersFor(_sixieme), isEmpty);
    });

    test('leçons à plusieurs notions : chaque question a sa notion', () async {
      final ch03 = await chapter(_ch03);
      expect(ch03.lessons.map((l) => l.conceptIds.length), [3, 3, 3]);
      for (final question in ch03.questions) {
        expect(
          ch03.conceptForQuestion(question),
          isNotNull,
          reason: question.id,
        );
      }
      expect(
        ch03.conceptForQuestion(ch03.question('l2_m1')!)!.id,
        'inverse_derivative',
      );
    });
  });

  group('Mon Parcours', () {
    test(
      'chaque chapitre produit ses cartes, sans jeu en préparation',
      () async {
        for (final id in [_ch01, _ch02, _ch03]) {
          final cards = const LearningCardFactory().build(
            await chapter(id),
            classKeys: const [_terminaleD],
          );
          expect(cards, isNotEmpty, reason: id);
          expect(cards.map((c) => c.id).toSet(), hasLength(cards.length));
          expect(cards.where((c) => c.type.asksAnswer), isNotEmpty, reason: id);
          expect(
            cards.where((c) => c.type == LearningCardType.explanation),
            isNotEmpty,
            reason: id,
          );
          if (id != _ch01) {
            // Aucun moteur de jeu pour ces blueprints : aucune carte « jeu ».
            expect(
              cards.where((c) => c.type == LearningCardType.game),
              isEmpty,
            );
          }
        }
      },
    );

    test('le fil Terminale D mêle les trois chapitres, hors ligne', () async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_Student.new),
          contentClassKeyProvider.overrideWith((ref) async => _terminaleD),
          contentPackRepositoryProvider.overrideWithValue(repository),
          learnerContentStoreProvider.overrideWithValue(
            InMemoryLearnerContentStore(),
          ),
          learningCardHistoryStoreProvider.overrideWithValue(
            InMemoryLearningCardHistoryStore(),
          ),
          contentPackCacheProvider.overrideWithValue(
            InMemoryContentPackCache(),
          ),
          remoteContentGatewayProvider.overrideWithValue(
            const OfflineGateway(),
          ),
        ],
      );
      addTearDown(container.dispose);
      var opened = 0;
      final feed = await HttpOverrides.runZoned(
        () => container.read(learningFeedProvider.future),
        createHttpClient: (_) {
          opened++;
          throw StateError('réseau');
        },
      );
      expect(opened, 0);
      expect(feed.chapters.keys, containsAll([_ch01, _ch02, _ch03]));
      expect(
        feed.cards.map((c) => c.contentId).toSet(),
        containsAll([_ch01, _ch02, _ch03]),
      );
    });
  });

  group('QCM : la bonne réponse n’est jamais une position', () {
    test('CH02 et CH03 : bonne réponse en A, B, C et D selon la tentative, '
        'correction identique', () async {
      for (final (id, questionId) in [(_ch02, 'l2_m4'), (_ch03, 'l1_e1')]) {
        final question = (await chapter(id)).question(questionId)!;
        final answer = (question.answer as ChoiceAnswer).choice;
        final correctIndex = question.choices.indexOf(answer);
        final positions = {
          for (var seed = 0; seed < 12; seed++)
            choiceOrder(
              question.choices.length,
              questionId: question.id,
              attemptKey: 'graine-$seed',
            ).indexOf(correctIndex),
        };
        expect(positions, {0, 1, 2, 3}, reason: questionId);
        expect(
          const AnswerChecker().grade(question, ChoiceResponse(answer)).correct,
          isTrue,
        );
      }
    });

    test(
      'CH03 : le retour de chaque proposition reste lié à sa valeur',
      () async {
        final question = (await chapter(_ch03)).question('l1_e1')!;
        expect(
          question.choiceFeedback[const AnswerAtom.text('[0;4]')],
          'Cela oublie le +1.',
        );
        expect(
          question.choiceFeedback[const AnswerAtom.text('[1;5]')],
          contains('ajoutant 1'),
        );
      },
    );
  });

  group('Correction des nouveaux types (données réelles)', () {
    test('CH02 : complexes, ensembles, radicaux, champs', () async {
      final ch02 = await chapter(_ch02);
      Question q(String id) => ch02.question(id)!;

      expect(gradeFields(q('l1_e1'), {'re': '3', 'im': '-4'}), isTrue);
      expect(gradeFields(q('l1_e1'), {'re': '3', 'im': '-4i'}), isFalse);

      for (final text in ['2/5+1/5i', '0,4+0,2i', '2/5+i/5', '(2+i)/5']) {
        expect(grade(q('l1_m3'), text), isTrue, reason: text);
      }
      expect(grade(q('l1_m3'), '2+i'), isFalse);
      expect(grade(q('l1_h3'), '7/3+i'), isTrue);
      expect(grade(q('l1_h3'), '2,33+i'), isFalse);
      expect(grade(q('l1_m1'), '8−i'), isTrue);

      expect(grade(q('l1_h1'), '1+2i ; 1−2i'), isTrue);
      expect(grade(q('l1_h1'), '1±2i'), isTrue);
      expect(grade(q('l1_h1'), '1+2i'), isFalse);

      expect(grade(q('l2_m1'), '5√2'), isTrue);
      expect(grade(q('l2_m1'), '√50'), isTrue);
      expect(grade(q('l2_m1'), 'sqrt(50)'), isTrue);
      expect(grade(q('l2_m1'), '7,07'), isFalse);

      expect(
        gradeFields(q('int_impedance'), {
          're': '3',
          'im': '4',
          'conjugate': '3−4i',
          'modulus': '5',
        }),
        isTrue,
      );
      expect(
        gradeFields(q('int_mission'), {'solutions': '1±2i', 'module': '√5'}),
        isTrue,
      );
      expect(
        gradeFields(q('l3_h2'), {'a': '1', 'b': '-1-4i', 'c': '-5+5i'}),
        isTrue,
      );
    });

    test('CH03 : intervalles, décimaux, approximations, expressions', () async {
      final ch03 = await chapter(_ch03);
      Question q(String id) => ch03.question(id)!;

      expect(grade(q('l1_m2'), '[0,5;1]'), isTrue);
      expect(grade(q('l1_m2'), '[0.5;1]'), isTrue);
      expect(grade(q('l1_m2'), ']0,5;1]'), isFalse);
      expect(grade(q('l1_h3'), '[-4;7]'), isTrue);

      expect(grade(q('l1_h1'), '0,68'), isTrue);
      expect(grade(q('l1_h1'), '0.682'), isTrue);
      expect(grade(q('l1_h1'), '0,69'), isFalse);

      expect(grade(q('l2_m1'), '1/4'), isTrue);
      expect(grade(q('l2_m1'), '0,25'), isTrue);
      expect(grade(q('l2_m1'), '0,3'), isFalse);

      expect(grade(q('l2_e1'), 'f⁻¹(y)=√(y−1)'), isTrue);
      expect(grade(q('l2_e1'), '√(y-1)'), isTrue);
      expect(grade(q('l2_e1'), '√y-1'), isFalse);

      expect(grade(q('l3_m2'), 'y=2 ; x=3'), isTrue);
      expect(grade(q('l3_m2'), 'x=3'), isFalse);
      expect(grade(q('l3_h3'), 'y=x−2 ; y=−x+2'), isTrue);
      expect(grade(q('l3_h2'), '1±√2'), isTrue);
      expect(grade(q('l2_m5'), '|f(b)−f(a)|≤3|b−a|'), isTrue);
    });

    test('les réponses rédigées ne sont jamais notées par le moteur', () async {
      final ch03 = await chapter(_ch03);
      final manual = ch03.questions.where((q) => !q.autoScorable).toList();
      expect(manual.map((q) => q.id), hasLength(9));
      expect(
        manual.every((q) => q.disabledReason == 'question_not_auto_scored'),
        isTrue,
      );
    });
  });

  group('Compagnon sans modèle de langage', () {
    test('CH02 et CH03 : réponses tirées du pack, honnête hors pack', () async {
      for (final (id, topic, concept) in [
        (_ch02, 'le module d’un nombre complexe', 'complex_modulus'),
        (
          _ch03,
          'théorème des valeurs intermédiaires',
          'intermediate_value_root',
        ),
      ]) {
        final chapter = await repository.chapter(id);
        expect(chapter.llmRequired, isFalse);
        final engine = CompanionEngine(chapter);
        final reply = engine.ask(topic);
        expect(reply.concept?.id, concept, reason: topic);
        expect(
          reply.parts.single.text,
          chapter.concepts[concept]!.explanations.values.first,
        );
        final unknown = engine.ask('photosynthèse des végétaux');
        expect(unknown.gap, CompanionGap.unknownTopic);
        expect(unknown.parts, isEmpty);
      }
    });
  });

  group('Diffusion distante (draft, rien n’est envoyé)', () {
    test(
      'chaque bundle se relit comme le pack embarqué et exige le moteur v2',
      () async {
        for (final (directory, id) in [
          ('ch01_arithmetique', _ch01),
          ('ch02_nombres_complexes', _ch02),
          ('ch03_fonctions_numeriques', _ch03),
        ]) {
          final documents = readPackDocuments(
            Directory('assets/content/terminale_d/mathematiques/$directory'),
          );
          final encoded = encodeBundle(
            buildPackBundle(
              id: id,
              version: 1,
              classKeys: const ['terminale-d'],
              documents: documents,
            ),
          );
          final bundle = PackBundle.tryParse(utf8.decode(encoded.bytes))!;
          final remote = const ContentPackParser().parse(rawFromBundle(bundle));
          final embedded = await repository.chapter(id);
          expect(remote.isPlayable, isTrue, reason: id);
          expect(remote.questions.length, embedded.questions.length);
          expect(
            remote.questions.where((q) => q.autoScorable).length,
            embedded.questions.where((q) => q.autoScorable).length,
          );
          expect(
            (documents['manifest']!['minimum_engine_version'] as num).toInt(),
            lessThanOrEqualTo(kContentEngineVersion),
          );
        }
      },
    );
  });
}
