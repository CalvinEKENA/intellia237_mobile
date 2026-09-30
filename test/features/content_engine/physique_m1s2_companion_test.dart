import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/content_engine/data/content_pack_parser.dart';
import 'package:intellia237/features/content_engine/domain/chapter.dart';
import 'package:intellia237/features/content_engine/domain/companion_action.dart';
import 'package:intellia237/features/content_engine/domain/pedagogy.dart';
import 'package:intellia237/features/content_engine/engine/answer_checker.dart';
import 'package:intellia237/features/content_engine/engine/companion_engine.dart';

import 'pack_fixture.dart';

const _directory =
    'assets/content/terminale_cd/physique/'
    'm1_s2_dimension_d_une_grandeur_physique';

Chapter _chapter(String directory) => const ContentPackParser().parse(
  RawContentPack(
    directory: directory,
    manifest: readPackJson('manifest.json', directory: directory),
    source: readPackJson('source.json', directory: directory),
    pedagogy: readPackJson('pedagogy.json', directory: directory),
    runtime: readPackJson('runtime.json', directory: directory),
    validation: readPackJson('validation_report.json', directory: directory),
  ),
);

void main() {
  final chapter = _chapter(_directory);
  final companion = CompanionEngine(chapter);

  group('M1S2 : vocabulaire du vrai pack', () {
    for (final (term, expected) in [
      ('dimension', 'dimension_vs_unit'),
      ('unité', 'dimension_vs_unit'),
      ('grandeur fondamentale', 'base_dimensions'),
      ('grandeur dérivée', 'derived_quantities'),
      ('équation aux dimensions', 'dimensional_equation'),
      ('exposant dimensionnel', 'dimensional_equation'),
      ('homogénéité', 'dimensional_homogeneity'),
      ('sans dimension', 'dimensionless_quantities'),
      ('radian', 'dimensionless_quantities'),
      ('vitesse', 'derived_quantities'),
      ('accélération', 'derived_quantities'),
      ('force', 'derived_quantities'),
      ('pression', 'derived_units'),
      ('fréquence', 'derived_units'),
      ('newton', 'derived_units'),
      ('joule', 'derived_units'),
      ('watt', 'derived_units'),
      ('pascal', 'derived_units'),
    ]) {
      test(term, () {
        final reply = companion.ask(term);
        expect(reply.concept?.id, expected);
        expect(reply.gap, isNull);
        expect(
          reply.parts.single.text,
          chapter.concepts[expected]!.explanation(ExplanationMode.standard),
        );
      });
    }
  });

  test('sans dimension garde son sens dans une phrase et avec du contexte', () {
    for (final query in [
      'explique-moi une grandeur sans dimension',
      "qu'est-ce que sans dimension signifie ?",
    ]) {
      expect(
        companion.ask(query, contextConceptId: 'dimension_vs_unit').concept?.id,
        'dimensionless_quantities',
        reason: query,
      );
    }
    expect(companion.ask('dimension').concept?.id, 'dimension_vs_unit');
    expect(companion.ask('unité dérivée').concept?.id, 'derived_units');
    expect(
      companion.ask('une unité sans rapport avec la dimension').concept?.id,
      isNot('dimensionless_quantities'),
    );
  });

  test('les actions du pack distinguent exemple et modèle visuel', () {
    expect(
      CompanionAction.fromLabel('Montre-moi un exemple'),
      CompanionAction.example,
    );
    expect(CompanionAction.fromLabel('Montre-moi'), CompanionAction.showMe);
    expect(
      CompanionAction.fromLabel('Show me an example'),
      CompanionAction.example,
    );
    expect(CompanionAction.fromLabel('Show me'), CompanionAction.showMe);
    expect(chapter.companion.actions, [
      CompanionAction.explainStandard,
      CompanionAction.explainSimple,
      CompanionAction.explainUltraSimple,
      CompanionAction.example,
      CompanionAction.hint,
      CompanionAction.whyWrong,
      CompanionAction.testMe,
    ]);
  });

  test('les trois niveaux reprennent exactement les explications du pack', () {
    const context = CompanionContext(
      conceptId: 'dimensional_equation',
      lessonNumber: 2,
    );
    for (final (action, mode) in [
      (CompanionAction.explainStandard, ExplanationMode.standard),
      (CompanionAction.explainSimple, ExplanationMode.simple),
      (CompanionAction.explainUltraSimple, ExplanationMode.ultraSimple),
    ]) {
      final reply = companion.respond(action, context);
      expect(reply.gap, isNull);
      expect(
        reply.parts.single.text,
        chapter.concepts['dimensional_equation']!.explanation(mode),
      );
    }
  });

  test('exemple et indice viennent des vraies questions M1S2', () {
    final question = chapter.question('l2_q04')!;
    final context = CompanionContext(
      conceptId: question.conceptId,
      lessonNumber: question.lessonNumber,
      question: question,
    );
    final example = companion.respond(CompanionAction.example, context);
    expect(example.gap, isNull);
    expect(
      chapter.questions.any(
        (q) => example.parts.single.text == '${q.prompt}\n→ ${q.explanation}',
      ),
      isTrue,
    );
    final hint = companion.respond(CompanionAction.hint, context);
    expect(hint.parts.single.text, question.hints.first);
  });

  test(
    'pourquoi faux explique une erreur objective, jamais une réponse ouverte',
    () {
      final question = chapter.question('l4_q05')!;
      final grade = const AnswerChecker().grade(
        question,
        const BooleanResponse(false),
      );
      final reply = companion.respond(
        CompanionAction.whyWrong,
        CompanionContext(
          conceptId: question.conceptId,
          lessonNumber: 4,
          question: question,
          lastGrade: grade,
        ),
      );
      expect(reply.gap, isNull);
      expect(reply.parts.first.text, question.explanation);
      final open = chapter.question('l5_q08')!;
      final subjective = companion.respond(
        CompanionAction.whyWrong,
        CompanionContext(
          conceptId: open.conceptId,
          lessonNumber: 5,
          question: open,
        ),
      );
      expect(subjective.gap, CompanionGap.nothingToExplain);
      expect(subjective.parts, isEmpty);
    },
  );

  test('Teste-moi sélectionne une question réelle dans la leçon', () {
    final reply = companion.respond(
      CompanionAction.testMe,
      const CompanionContext(conceptId: 'derived_units', lessonNumber: 3),
    );
    expect(reply.gap, isNull);
    expect(reply.question?.lessonNumber, 3);
    expect(chapter.question(reply.question!.id), same(reply.question));
  });

  test('réponses déterministes hors réseau, refus explicite hors pack', () {
    var clients = 0;
    HttpOverrides.runZoned(
      () {
        for (final query in ['pression', 'fréquence', 'sans dimension']) {
          final first = companion.ask(query);
          final repeated = companion.ask(query);
          expect(repeated.concept?.id, first.concept?.id);
          expect(
            repeated.parts.map((p) => p.text),
            first.parts.map((p) => p.text),
          );
        }
        for (final query in [
          'photosynthèse des plantes vertes',
          'passeport',
          'incertitude',
        ]) {
          final reply = companion.ask(query);
          expect(reply.gap, CompanionGap.unknownTopic, reason: query);
          expect(reply.parts, isEmpty);
        }
      },
      createHttpClient: (context) {
        clients++;
        throw StateError('Le Companion ne doit pas ouvrir de réseau.');
      },
    );
    expect(clients, 0);
    expect(chapter.llmRequired, isFalse);
  });

  test('M1S1 conserve type A/type B et ses limites de pack', () {
    final previous = CompanionEngine(
      _chapter(
        'assets/content/terminale_cd/physique/m1_s1_erreurs_et_incertitudes',
      ),
    );
    for (final (query, id) in [
      ('c’est quoi le type A ?', 'type_a_uncertainty'),
      ('explique le type B', 'type_b_uncertainty'),
      ('somme quadratique', 'combined_uncertainty'),
      ('justesse et fidélité', 'accuracy_precision'),
    ]) {
      expect(previous.ask(query).concept?.id, id, reason: query);
    }
    expect(
      previous.ask('photosynthèse des plantes vertes').gap,
      CompanionGap.unknownTopic,
    );
    expect(
      previous.ask('homogénéité dimensionnelle').gap,
      CompanionGap.unknownTopic,
    );
  });
}
