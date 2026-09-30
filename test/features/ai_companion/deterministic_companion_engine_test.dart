import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/ai_companion/deterministic/companion_conversation_state.dart';
import 'package:intellia237/features/ai_companion/deterministic/companion_dialogue_bank.dart';
import 'package:intellia237/features/ai_companion/deterministic/companion_reply_action.dart';
import 'package:intellia237/features/ai_companion/deterministic/companion_study_context.dart';
import 'package:intellia237/features/ai_companion/deterministic/companion_text.dart';
import 'package:intellia237/features/ai_companion/deterministic/deterministic_companion_engine.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/quiz/application/pack_quiz_session.dart';
import 'package:intellia237/features/quiz/domain/pack_quiz.dart';

import 'companion_fixture.dart';

/// Kira et Léo sans modèle de langage : banque de dialogues validée,
/// intentions, contexte réel, mémoire courte, variété sans hasard.
void main() {
  const engine = DeterministicCompanionEngine();
  final fr = loadBank('fr');
  final en = loadBank('en');

  group('banque de dialogues', () {
    for (final bank in [fr, en]) {
      test('${bank.language} : complète, valide, deux voix distinctes', () {
        final families = companionResponseMinimums.entries
            .where((e) => e.value >= 8)
            .map((e) => e.key)
            .toList();
        expect(families.length, greaterThanOrEqualTo(16));
        for (final key in families) {
          for (final persona in companionPersonaIds) {
            expect(
              bank.variants(key, persona).length,
              greaterThanOrEqualTo(8),
              reason: '$key $persona',
            );
          }
          expect(
            bank.variants(key, 'kira'),
            isNot(equals(bank.variants(key, 'leo'))),
            reason: key,
          );
        }
        final total = bank.responses.values.fold<int>(
          0,
          (sum, byPersona) =>
              sum + byPersona.values.fold(0, (s, list) => s + list.length),
        );
        expect(total, greaterThanOrEqualTo(16 * 8 * 2));
      });

      test('${bank.language} : aucun jargon, aucune prétention humaine', () {
        final jargon = RegExp(
          r'\b(?:firebase|firestore|backend|api|token|jeton|serveur|server|'
          r'gemini|openai|gpt|llm|json|otp|timeout)\b',
          caseSensitive: false,
        );
        final aiWord = RegExp(r'\b(?:IA|AI)\b');
        for (final MapEntry(key: key, value: byPersona)
            in bank.responses.entries) {
          for (final line in byPersona.values.expand((l) => l)) {
            expect(jargon.hasMatch(line), isFalse, reason: '$key : $line');
            if (key != 'are_you_ai') {
              expect(aiWord.hasMatch(line), isFalse, reason: '$key : $line');
            }
          }
        }
        for (final line in bank.responses['are_you_ai']!.values.expand(
          (l) => l,
        )) {
          expect(
            RegExp(
              r'je suis (?:un |une )?(?:humain|humaine|personne|vraie)|'
              r"i(?: am|'m) (?:a )?(?:human|person|real)\b",
              caseSensitive: false,
            ).hasMatch(line),
            isFalse,
            reason: line,
          );
        }
      });
    }

    test('FR et EN : mêmes clés, mêmes emplacements', () {
      expect(fr.responses.keys.toSet(), en.responses.keys.toSet());
      Set<String> slots(CompanionDialogueBank bank, String key) => {
        for (final line in bank.responses[key]!.values.expand((l) => l))
          for (final m in RegExp(r'\{(\w+)\}').allMatches(line)) m.group(1)!,
      };
      for (final key in fr.responses.keys) {
        expect(slots(en, key), slots(fr, key), reason: key);
      }
    });

    test('une banque incomplète est refusée', () {
      final raw = File('assets/companions/dialogue/fr.json').readAsStringSync();
      expect(
        () => CompanionDialogueBank.parse(
          raw.replaceFirst('"greeting": {', '"greetingX": {'),
        ),
        throwsA(isA<CompanionDialogueException>()),
      );
      expect(
        () => CompanionDialogueBank.parse(
          raw.replaceFirst('{firstName}', '{prenomInconnu}'),
        ),
        throwsA(isA<CompanionDialogueException>()),
      );
    });
  });

  test('normalisation : accents, apostrophes, variantes d’écriture', () {
    expect(
      normalizeCompanionText(
        "J'veux faire des MATHS stp !!",
        replacements: fr.normalization,
      ),
      'je veux faire des maths',
    );
    expect(normalizeCompanionText('Ça  va ?'), 'ca va');
  });

  group('Terminale D, maîtrise vierge', () {
    late CompanionStudyContext context;

    testWidgets('prépare le contexte réel', (tester) async {
      final container = await terminaleDContainer(tester);
      context = contextFrom(container);
      expect(context.subjects.map((s) => s.key), [
        'anglais',
        'mathematiques',
        'physique',
        'svt',
      ]);
      expect(context.quizSubjects, hasLength(4));
      expect(context.reviewFocus, isNull);
      expect(context.startedConcepts, 0);
    });

    CompanionReply say(
      String message, {
      String persona = 'kira',
      CompanionDialogueBank? bank,
      CompanionConversationState state = CompanionConversationState.initial,
    }) => engine.respond(
      message: message,
      context: context,
      bank: bank ?? fr,
      personaId: persona,
      state: state,
    );

    test('bonjour, ça va, merci, au revoir : réponses sociales naturelles', () {
      expect(say('bonjour').responseKey, 'greeting');
      expect(say('Salut Kira !').responseKey, 'greeting');
      expect(say('ça va ?').responseKey, 'how_are_you');
      expect(say('merci').responseKey, 'thanks');
      expect(say('au revoir').responseKey, 'goodbye');
      expect(say('à demain').responseKey, 'goodbye');
      expect(say('bonjour').text, contains('Amina'), skip: false);
    });

    test('fatigue, découragement, stress : réponses adaptées et une action '
        'courte', () {
      final tired = say('je suis fatigué');
      expect(tired.responseKey, 'tired');
      expect(
        tired.actions.first.kind,
        CompanionActionKind.openQuiz,
        reason: 'un petit quiz, pas une longue séance',
      );
      expect(say('je n’arrive pas à travailler').responseKey, 'motivation');
      expect(say('j’abandonne').responseKey, 'discouraged');
      expect(say("J'ai peur pour mon examen").responseKey, 'exam_stress');
      expect(say('je m’ennuie').responseKey, 'bored');
    });

    test('« je suis nul » : jamais confirmé', () {
      for (final persona in ['kira', 'leo']) {
        for (var turn = 0; turn < 8; turn++) {
          final reply = say(
            'je suis nul',
            persona: persona,
            state: CompanionConversationState(turn: turn),
          );
          expect(reply.responseKey, 'self_doubt');
          expect(
            reply.text.toLowerCase(),
            isNot(matches(RegExp(r"(oui|c'est vrai|tu es nul)"))),
          );
        }
      }
      final physics = say('je suis nul en physique');
      expect(physics.responseKey, 'self_doubt');
      expect(
        physics.actions.map((a) => a.subjectKey),
        everyElement('physique'),
      );
    });

    test('« je veux un quiz » : les quiz réels de la classe', () {
      final reply = say('je veux un quiz');
      expect(reply.responseKey, 'want_quiz');
      final quizzes = reply.actions.where(
        (a) => a.kind == CompanionActionKind.openQuiz,
      );
      expect(quizzes.map((a) => a.subjectKey), [
        'anglais',
        'mathematiques',
        'physique',
        'svt',
      ]);
      for (final action in quizzes) {
        expect(action.setId, startsWith('seq:'));
      }
      expect(reply.actions.last.kind, CompanionActionKind.showQuizzes);
    });

    for (final (message, key, subject) in [
      ('maths', 'want_math', 'mathematiques'),
      ('On fait de l’anglais ?', 'want_english', 'anglais'),
      ('physique', 'want_physics', 'physique'),
      ("J'veux faire des maths stp", 'want_math', 'mathematiques'),
    ]) {
      test('« $message » : $key, avec cours et quiz de la matière', () {
        final reply = say(message);
        expect(reply.responseKey, key);
        expect(reply.actions.map((a) => a.kind).toSet(), {
          CompanionActionKind.openSubject,
          CompanionActionKind.openQuiz,
        });
        expect(reply.actions.map((a) => a.subjectKey), everyElement(subject));
      });
    }

    test('matière absente de la classe : jamais inventée', () {
      final reply = engine.respond(
        message: 'on fait de la SVT ?',
        context: CompanionStudyContext.empty,
        bank: fr,
        personaId: 'kira',
      );
      expect(reply.responseKey, 'want_subject_missing');
      expect(reply.actions.where((a) => a.subjectKey == 'svt'), isEmpty);
    });

    test('« que dois-je réviser ? » sans réponses : pas de diagnostic '
        'inventé', () {
      final reply = say("qu'est-ce que je dois réviser ?");
      expect(reply.responseKey, 'what_should_i_review_no_data');
      expect(say('où j’en suis ?').responseKey, 'ask_progress_no_data');
    });

    test('relativité générale : aucune explication inventée', () {
      for (final bank in [fr, en]) {
        final reply = say('explique-moi la relativité générale', bank: bank);
        expect(reply.responseKey, 'unsupported_freeform');
        expect(reply.text, isNot(contains('Einstein')));
        expect(reply.text.toLowerCase(), isNot(contains('espace-temps')));
      }
      expect(say('xqzt blorp').responseKey, 'unknown');
    });

    test('« tu es une IA ? » : réponse honnête', () {
      final reply = say('tu es une IA ?');
      expect(reply.responseKey, 'are_you_ai');
      expect(say('are you an AI?', bank: en).responseKey, 'are_you_ai');
      expect(say('qui es-tu ?').text, contains('Kira'));
      expect(say('qui es-tu ?', persona: 'leo').text, contains('Léo'));
    });

    test('un cours réel nommé : navigation, pas d’explication', () {
      final reply = say('Je veux revoir les nombres complexes');
      expect(reply.responseKey, 'course_topic');
      expect(reply.text, contains('Nombres complexes'));
      expect(reply.actions.first.kind, CompanionActionKind.openChapter);
      expect(reply.actions.first.contentId, contains('nombres_complexes'));
      expect(reply.actions.last.kind, CompanionActionKind.openQuiz);
    });

    test('mémoire courte : « Quelle matière ? » puis « Anglais »', () {
      final ask = say('je veux travailler');
      expect(ask.responseKey, 'want_to_study');
      expect(ask.state.awaiting, CompanionAwaiting.subjectToStudy);
      final answer = say('Anglais', state: ask.state);
      expect(answer.responseKey, 'want_english');
      expect(answer.actions.first.kind, CompanionActionKind.openSubject);

      final quiz = say('je veux un quiz');
      final english = say('anglais', state: quiz.state);
      expect(english.responseKey, 'want_quiz_subject');
      expect(english.actions.map((a) => a.mode), ['training', 'evaluation']);
    });

    test('« surprends-moi » puis « oui » : le même quiz, réellement '
        'disponible', () {
      final surprise = say('surprends-moi');
      expect(surprise.responseKey, 'surprise_me');
      final action = surprise.actions.single;
      expect(action.kind, CompanionActionKind.openQuiz);
      expect(
        context.quizSubjects.map((s) => s.quizSetId),
        contains(action.setId),
      );
      final yes = say('oui', state: surprise.state);
      expect(yes.responseKey, 'affirm');
      expect(yes.actions, [action]);
      expect(say('non', state: surprise.state).responseKey, 'decline');
    });

    test('déterminisme : même contexte, même réponse', () {
      final a = say(
        'bonjour',
        state: const CompanionConversationState(turn: 3),
      );
      final b = say(
        'bonjour',
        state: const CompanionConversationState(turn: 3),
      );
      expect(a.text, b.text);
    });

    test('variété : jamais deux fois la même phrase de suite', () {
      for (final persona in ['kira', 'leo']) {
        var state = CompanionConversationState.initial;
        String? previous;
        final seen = <String>{};
        for (var i = 0; i < 12; i++) {
          final reply = say('merci', persona: persona, state: state);
          expect(reply.text, isNot(previous), reason: '$persona tour $i');
          previous = reply.text;
          seen.add(reply.text);
          state = reply.state;
        }
        expect(seen.length, greaterThanOrEqualTo(4), reason: persona);
      }
    });

    test('Kira et Léo : même sens, formulations différentes', () {
      for (final message in ['bonjour', 'je suis fatigué', 'je veux un quiz']) {
        final kira = say(message);
        final leo = say(message, persona: 'leo');
        expect(kira.responseKey, leo.responseKey);
        expect(kira.text, isNot(leo.text));
        expect(kira.actions.map((a) => a.kind), leo.actions.map((a) => a.kind));
      }
    });

    test('anglais de l’interface : réponses anglaises', () {
      expect(say('hello', bank: en).text, isNot(contains('Salut')));
      expect(say('I want a quiz', bank: en).responseKey, 'want_quiz');
      expect(
        say('What should I review?', bank: en).responseKey,
        'what_should_i_review_no_data',
      );
    });

    test('suggestions : ce que l’élève peut réellement faire', () {
      final suggestions = engine.suggestions(context: context, bank: fr);
      expect(suggestions, contains('Je veux un quiz'));
      for (final suggestion in suggestions) {
        expect(
          say(suggestion).responseKey,
          isNot('unknown'),
          reason: suggestion,
        );
      }
    });
  });

  testWidgets('avec des réponses réelles : priorité, progression et retour '
      'de quiz', (tester) async {
    final container = await terminaleDContainer(
      tester,
      answer: (container) async {
        final journeys = journeysOf(container);
        final maths = journeys.firstWhere((j) => j.key == 'mathematiques');
        final chapter = maths.chapters.first.chapter;
        final controller = container.read(
          learnerContentControllerProvider.notifier,
        );
        final scored = chapter.questions.where((q) => q.autoScorable);
        for (final (i, question) in scored.take(6).indexed) {
          await controller.recordAnswer(
            chapter: chapter,
            question: question,
            correct: i.isEven,
          );
        }
      },
    );
    final journeys = journeysOf(container);
    final setId = PackQuizCatalog.fromJourneys(
      journeys,
    ).subjects.first.sequences.first.id;
    final context = contextFrom(
      container,
      history: [
        PackQuizHistoryEntry(
          setId: setId,
          subjectKey: 'anglais',
          title: 'Unit 1',
          mode: PackQuizMode.evaluation,
          score: 4,
          total: 10,
          completedAt: DateTime.now(),
        ),
      ],
    );

    final review = engine.respond(
      message: 'Qu’est-ce que je dois réviser ?',
      context: context,
      bank: fr,
      personaId: 'kira',
    );
    expect(review.responseKey, 'what_should_i_review');
    final focus = context.reviewFocus!;
    expect(focus.subjectKey, 'mathematiques');
    expect(review.text, contains(focus.topicTitle));
    expect(review.actions.first.contentId, focus.contentId);

    final progress = engine.respond(
      message: 'où j’en suis ?',
      context: context,
      bank: fr,
      personaId: 'leo',
    );
    expect(progress.responseKey, 'ask_progress');
    expect(progress.text, contains('${context.startedConcepts}'));
    expect(progress.text, contains('${context.masteredConcepts}'));

    final back = engine.quizReturn(
      result: context.lastQuiz!,
      context: context,
      bank: fr,
      personaId: 'kira',
    );
    expect(back.responseKey, 'quiz_return_low');
    expect(back.text, contains('4/10'));
    expect(back.actions.first.label, CompanionActionLabel.retryQuiz);
    expect(back.actions.first.setId, setId);
    expect(back.actions[1].mode, 'training');
  });

  testWidgets('classe sans contenus : honnête, jamais de quiz inventé', (
    tester,
  ) async {
    final container = await terminaleDContainer(tester, classKey: null);
    final context = contextFrom(container);
    expect(context.subjects, isEmpty);
    for (final (message, key) in [
      ('je veux un quiz', 'want_quiz_none'),
      ('maths', 'want_subject_missing'),
      ('surprends-moi', 'surprise_me_none'),
    ]) {
      final reply = engine.respond(
        message: message,
        context: context,
        bank: fr,
        personaId: 'kira',
      );
      expect(reply.responseKey, key, reason: message);
      expect(
        reply.actions.where((a) => a.kind == CompanionActionKind.openQuiz),
        isEmpty,
      );
    }
  });

  test('zéro modèle de langage : le compagnon n’importe aucun client '
      'distant', () {
    final files = Directory('lib/features/ai_companion')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final forbidden in [
        'cloud_functions',
        'httpsCallable',
        'askTutor',
        'cloud_ai_repository',
        'ai_service',
        'package:http/',
      ]) {
        expect(source, isNot(contains(forbidden)), reason: file.path);
      }
    }
    // Aucun appel du tuteur en ligne ne subsiste dans l'application.
    final all = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains("'askTutor'"));
    expect(all, isEmpty);
  });
}
