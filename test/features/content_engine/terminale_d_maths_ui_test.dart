import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/engine/answer_checker.dart';
import 'package:intellia237/features/content_engine/presentation/content_lesson_screen.dart';
import 'package:intellia237/features/content_engine/presentation/widgets/answer_input.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

import 'pack_fixture.dart';

/// Chapitres 2 et 3 de Terminale D à l'écran : leçons à plusieurs notions,
/// saisie des nouveaux types de réponse, petits écrans et grand texte.
const _ch02 = 'maths_td_ch02_nombres_complexes_algebrique';
const _ch03 = 'maths_td_ch03_fonctions_numeriques';

Future<void> _pump(
  WidgetTester tester,
  String contentId,
  int lesson, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      contentPackRepositoryProvider.overrideWithValue(
        ContentPackRepository(source: DiskContentPackSource()),
      ),
      learnerContentStoreProvider.overrideWithValue(
        InMemoryLearnerContentStore(),
      ),
      contentClassKeyProvider.overrideWith(
        (ref) async => const ClassKey('terminale', series: 'd'),
      ),
      contentPackCacheProvider.overrideWithValue(InMemoryContentPackCache()),
      remoteContentGatewayProvider.overrideWithValue(const OfflineGateway()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: ContentLessonScreen(
              contentId: contentId,
              lessonNumber: lesson,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.runAsync(
    () => container.read(contentChapterProvider(contentId).future),
  );
  await tester.runAsync(
    () => container.read(learnerContentControllerProvider.future),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('une leçon à trois notions : l’élève passe de l’une à l’autre', (
    tester,
  ) async {
    await _pump(tester, _ch03, 2);
    for (final id in [
      'inverse_function',
      'inverse_derivative',
      'roots_limits_inequalities',
    ]) {
      expect(find.byKey(ValueKey('lesson-concept-$id')), findsOneWidget);
    }
    await _tap(
      tester,
      find.byKey(const ValueKey('lesson-concept-inverse_derivative')),
    );
    expect(
      find.textContaining('(f⁻¹)\'(y)=1/f\'(x)', findRichText: true),
      findsWidgets,
    );
  });

  testWidgets('320 px et texte ×1,3 : chaque étape de chaque leçon des '
      'chapitres 2 et 3 tient', (tester) async {
    for (final (contentId, lessons) in [(_ch02, 3), (_ch03, 3)]) {
      for (var lesson = 1; lesson <= lessons; lesson++) {
        await _pump(
          tester,
          contentId,
          lesson,
          size: const Size(320, 640),
          textScale: 1.3,
        );
        for (var step = 0; step < 5; step++) {
          await _tap(tester, find.byKey(ValueKey('lesson-step-$step')));
          expect(
            tester.takeException(),
            isNull,
            reason: '$contentId leçon $lesson étape $step',
          );
        }
      }
    }
  });

  testWidgets('saisie d’un complexe : touche « i », correction par valeur', (
    tester,
  ) async {
    final chapter = await tester.runAsync(
      () =>
          ContentPackRepository(source: DiskContentPackSource()).chapter(_ch02),
    );
    final question = chapter!.question('l1_m3')!;
    StudentResponse? response;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AnswerInput(
            question: question,
            onChanged: (value) => response = value,
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('answer-field-value')),
      '2/5+',
    );
    await tester.tap(find.widgetWithText(ActionChip, 'i'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('answer-field-value')),
      '${(tester.widget(find.byKey(const ValueKey('answer-field-value'))) as TextField).controller!.text}/5',
    );
    await tester.pump();
    expect((response! as TextResponse).text, '2/5+i/5');
    expect(const AnswerChecker().grade(question, response!).correct, isTrue);
  });
}
