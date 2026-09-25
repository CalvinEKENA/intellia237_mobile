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
import 'package:intellia237/features/content_engine/data/content_pack_parser.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/domain/chapter.dart';
import 'package:intellia237/features/content_engine/domain/companion_action.dart';
import 'package:intellia237/features/content_engine/domain/pack_catalog.dart';
import 'package:intellia237/features/content_engine/domain/pedagogy.dart';
import 'package:intellia237/features/content_engine/domain/question.dart';
import 'package:intellia237/features/content_engine/engine/answer_checker.dart';
import 'package:intellia237/features/content_engine/engine/companion_engine.dart';
import 'package:intellia237/features/content_engine/feed/learning_card.dart';
import 'package:intellia237/features/content_engine/feed/learning_card_factory.dart';
import 'package:intellia237/features/content_engine/feed/learning_card_history.dart';

import '../../../tool/content/pack_bundle_builder.dart';
import 'pack_fixture.dart';

/// Anglais Terminale, module 1, units 1 et 2 : une matière en modules et
/// units, pour toutes les séries de Terminale, dans la même Content Engine.
const _terminaleD = ClassKey('terminale', series: 'd');
const _terminaleA = ClassKey('terminale', series: 'a');
const _terminaleC = ClassKey('terminale', series: 'c');
const _sixieme = ClassKey('sixieme');

const _u1 = 'english_terminale_m1_u1_applying_for_passport';
const _u2 = 'english_terminale_m1_u2_discussing_recreational_activities';

class _Student extends AuthController {
  @override
  AuthState build() =>
      const AuthState.authenticated(role: AppRole.student, userId: 'eleve-en');
}

void main() {
  late ContentPackRepository repository;
  setUp(
    () => repository = ContentPackRepository(source: DiskContentPackSource()),
  );

  Future<Chapter> unit(String id) => repository.chapter(id);

  group('Apprendre : Anglais → Module 1 → Units', () {
    for (final classKey in [_terminaleA, _terminaleC, _terminaleD]) {
      test('Terminale ${classKey.series!.toUpperCase()} voit les deux units, '
          'cible générique « terminale »', () async {
        final english = (await repository.subjectsFor(
          classKey,
        )).singleWhere((s) => s.key == 'anglais');
        expect(english.chapters.map((c) => c.contentId), [_u1, _u2]);
        for (final (i, entry) in english.chapters.indexed) {
          expect(entry.curriculum.moduleNumber, 1);
          expect(entry.curriculum.moduleTitle, 'Family and social life');
          expect(entry.curriculum.unitNumber, i + 1);
          expect(entry.curriculum.isUnit, isTrue);
        }
        expect(english.chapters.map((c) => c.curriculum.chapterTitle), [
          'Applying for a passport',
          'Discussing recreational activities',
        ]);
      });
    }

    test('Sixième : aucune unit d’anglais de Terminale', () async {
      final subjects = await repository.subjectsFor(_sixieme);
      expect(subjects.where((s) => s.key == 'anglais'), isEmpty);
      final chapters = await repository.chaptersFor(_sixieme);
      expect(chapters.map((c) => c.contentId), isNot(contains(_u1)));
    });

    test(
      'Terminale D : mathématiques et anglais, chacun dans sa matière',
      () async {
        final keys = (await repository.subjectsFor(
          _terminaleD,
        )).map((s) => s.key);
        expect(keys, containsAll(['anglais', 'mathematiques']));
      },
    );

    test('une leçon garde toutes ses notions (M1U2, leçon 4)', () async {
      final u2 = await unit(_u2);
      expect(u2.lesson(4)!.conceptIds, [
        'recreation_vocabulary',
        'phrasal_verbs',
        'prepositional_phrases',
      ]);
      expect(u2.conceptsForLesson(4), hasLength(3));
    });

    test('libellés dans la langue du contenu : niveaux et Compagnon', () async {
      final u1 = await unit(_u1);
      expect(u1.explanationLabels[ExplanationMode.simple], 'Simple English');
      expect(u1.explanationLabels[ExplanationMode.ultraSimple], 'Very simple');
      expect(
        u1.companion.labels[CompanionAction.explainStandard],
        'Explain this',
      );
      expect(
        u1.companion.labels[CompanionAction.whyWrong],
        'Why is my answer wrong?',
      );
      expect(u1.companion.unrecognizedLabels, isEmpty);
      expect(u1.difficulty(3).label, 'Bac Challenge');
    });
  });

  group('Questions', () {
    test(
      '34 notées, 6 activités ouvertes jamais présentées comme notées',
      () async {
        for (final (id, manual) in [
          (_u1, ['l1_q07', 'l1_q08', 'l2_q08', 'l3_q08', 'l4_q08', 'l5_q08']),
          (_u2, ['l1_q07', 'l1_q08', 'l2_q08', 'l5_q06', 'l5_q07', 'l5_q08']),
        ]) {
          final chapter = await unit(id);
          expect(chapter.isPlayable, isTrue);
          expect(chapter.questions, hasLength(40));
          final open = chapter.questions.where((q) => !q.autoScorable);
          expect(open.map((q) => q.id), manual, reason: id);
          for (final question in open) {
            expect(question.type, QuestionType.reasoning);
            expect(question.disabledReason, 'question_not_auto_scored');
            expect(
              () => const AnswerChecker().grade(
                question,
                const TextResponse('anything'),
              ),
              throwsArgumentError,
            );
          }
          final cards = const LearningCardFactory().build(chapter);
          expect(
            cards.map((c) => c.question?.id).whereType<String>().toSet(),
            isNot(containsAll(manual)),
          );
          expect(
            cards.any((c) => c.question != null && !c.question!.autoScorable),
            isFalse,
          );
        }
      },
    );

    test('QCM : bonne réponse en A, B, C et D selon la tentative', () async {
      for (final (id, questionId) in [(_u1, 'l1_q01'), (_u2, 'l1_q02')]) {
        final question = (await unit(id)).question(questionId)!;
        final answer = (question.answer as ChoiceAnswer).choice;
        final correct = question.choices.indexOf(answer);
        final positions = {
          for (var seed = 0; seed < 16; seed++)
            choiceOrder(
              question.choices.length,
              questionId: question.id,
              attemptKey: 'graine-$seed',
            ).indexOf(correct),
        };
        expect(positions, {0, 1, 2, 3}, reason: '$id $questionId');
        expect(
          const AnswerChecker().grade(question, ChoiceResponse(answer)).correct,
          isTrue,
        );
        expect(question.choiceFeedback[answer], isNotNull);
      }
    });

    test('choix multiples et verbes : correction par valeur', () async {
      final u1 = await unit(_u1);
      final personal = u1.question('l2_q04')!;
      expect(
        const AnswerChecker()
            .grade(
              personal,
              MultiChoiceResponse({
                for (final label in [
                  'Residential address',
                  'Surname',
                  'Date of birth',
                  'Marital status',
                ])
                  AnswerAtom.text(label),
              }),
            )
            .correct,
        isTrue,
      );
      final passive = u1.question('l5_q03')!;
      bool grade(Question q, String text) =>
          const AnswerChecker().grade(q, TextResponse(text)).correct;
      expect(grade(passive, 'be signed'), isTrue);
      expect(grade(passive, 'Be signed'), isTrue);
      expect(grade(passive, 'signed'), isFalse);
      final phrasal = (await unit(_u2)).question('l4_q05')!;
      expect(grade(phrasal, 'across'), isTrue);
      expect(grade(phrasal, 'through'), isFalse);
    });
  });

  group('Sources incomplètes : rien d’inventé', () {
    test('écoute absente : seules les questions appuyées sur un texte '
        'visible sont notées', () async {
      for (final (id, scoredListening, openListening, flag) in [
        (_u1, {'l1_q06'}, 'l1_q07', 'listening'),
        (_u2, {'l1_q05', 'l1_q06'}, 'l1_q07', 'listening testimony'),
      ]) {
        final chapter = await unit(id);
        final listening = chapter.questions.where(
          (q) => q.conceptId!.startsWith('listening'),
        );
        expect(
          {
            for (final q in listening)
              if (q.autoScorable) q.id,
          },
          scoredListening,
          reason: id,
        );
        final open = chapter.question(openListening)!;
        expect(open.autoScorable, isFalse);
        expect(open.visibleFlags.single.issue.toLowerCase(), contains(flag));
      }
    });

    test(
      'lettre formelle : la clôture contradictoire n’est jamais notée',
      () async {
        final u2 = await unit(_u2);
        final review = u2.question('l5_q08')!;
        expect(review.autoScorable, isFalse);
        expect(review.visibleFlags.single.issue, contains('Yours faithfully'));
        for (final question in u2.questions.where((q) => q.autoScorable)) {
          final text = jsonEncode([
            question.prompt,
            question.explanation,
            for (final choice in question.choices) choice.display,
          ]).toLowerCase();
          expect(text, isNot(contains('faithfully')), reason: question.id);
          expect(text, isNot(contains('sincerely')), reason: question.id);
        }
      },
    );
  });

  group('Mon Parcours et Compagnon', () {
    test('chaque unit produit ses cartes, sans jeu en préparation', () async {
      for (final id in [_u1, _u2]) {
        final chapter = await unit(id);
        final cards = const LearningCardFactory().build(
          chapter,
          classKeys: const [_terminaleA],
        );
        final types = cards.map((c) => c.type).toSet();
        expect(
          types,
          containsAll([
            LearningCardType.explanation,
            LearningCardType.ultraSimple,
            LearningCardType.mcq,
            LearningCardType.trueFalse,
            LearningCardType.commonMistake,
            LearningCardType.revision,
          ]),
          reason: id,
        );
        expect(types, isNot(contains(LearningCardType.game)));
        expect(chapter.games.every((g) => !g.playable), isTrue);
        expect(cards.map((c) => c.id).toSet(), hasLength(cards.length));
      }
      // Notions de toutes les leçons, dont les verbes à particule.
      final u2Cards = const LearningCardFactory().build(await unit(_u2));
      expect(
        u2Cards.map((c) => c.conceptId),
        containsAll(['phrasal_verbs', 'prepositional_phrases']),
      );
    });

    test(
      'le fil d’un élève de Terminale A mêle les deux units, hors ligne',
      () async {
        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(_Student.new),
            contentClassKeyProvider.overrideWith((ref) async => _terminaleA),
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
        expect(feed.chapters.keys.toSet(), {_u1, _u2});
        expect(feed.cards.map((c) => c.contentId).toSet(), {_u1, _u2});
      },
    );

    test(
      'Compagnon : réponses du pack uniquement, honnête hors pack',
      () async {
        for (final (id, topic, concept) in [
          (_u1, 'passive voice', 'passive_voice'),
          (_u2, 'phrasal verbs', 'phrasal_verbs'),
        ]) {
          final chapter = await unit(id);
          expect(chapter.llmRequired, isFalse);
          final engine = CompanionEngine(chapter);
          final reply = engine.ask(topic);
          expect(reply.concept?.id, concept, reason: topic);
          expect(
            reply.parts.single.text,
            chapter.concepts[concept]!.explanation(ExplanationMode.standard),
          );
          final unknown = engine.ask('photosynthesis of green plants');
          expect(unknown.gap, CompanionGap.unknownTopic);
          expect(unknown.parts, isEmpty);
        }
      },
    );
  });

  test('bundles draft : relus comme les packs embarqués, moteur v2', () async {
    for (final (directory, id) in [
      ('m1_u1_applying_for_a_passport', _u1),
      ('m1_u2_discussing_recreational_activities', _u2),
    ]) {
      final documents = readPackDocuments(
        Directory('assets/content/terminale/anglais/$directory'),
      );
      final encoded = encodeBundle(
        buildPackBundle(
          id: id,
          version: 1,
          classKeys: const ['terminale'],
          documents: documents,
        ),
      );
      final bundle = PackBundle.tryParse(utf8.decode(encoded.bytes))!;
      final remote = const ContentPackParser().parse(rawFromBundle(bundle));
      expect(remote.isPlayable, isTrue, reason: id);
      expect(remote.questions.where((q) => q.autoScorable), hasLength(34));
      expect(documents['manifest']!['minimum_engine_version'], 2);
      expect(2, lessThanOrEqualTo(kContentEngineVersion));
    }
  });
}
