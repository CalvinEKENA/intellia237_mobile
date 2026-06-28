import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/theme/design_tokens.dart';
import 'package:intellia237/core/widgets/tab_presentation.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/features/learn/domain/learn_hub_snapshot.dart';
import 'package:intellia237/features/learn/domain/learn_subject.dart';
import 'package:intellia237/features/learn/presentation/learn_hub_screen.dart';
import 'package:intellia237/features/quiz/application/quiz_providers.dart';
import 'package:intellia237/features/quiz/domain/quiz_model.dart';
import 'package:intellia237/features/quiz/presentation/quiz_hub_screen.dart';

const _sizes = [Size(320, 640), Size(360, 800), Size(390, 844), Size(430, 932)];
const _scales = [1.0, 1.3, 1.5];

LearnHubSnapshot _learnSnapshot() => LearnHubSnapshot(
  context: const LearnAcademicContext(classLevel: 'Terminale', series: 'D'),
  subjects: const [
    LearnSubject(
      id: 's1',
      title: 'Mathématiques',
      description: 'Algèbre et analyse.',
      colorHex: 0xFF1451E1,
      iconKey: 'math',
      chapters: [],
    ),
  ],
);

List<QuizModel> _quizzes() => const [
  QuizModel(
    id: 'q1',
    title: 'Test de logique',
    subjectId: 's1',
    subjectLabel: 'Maths',
    description: 'Un quiz pour t’échauffer.',
    difficultyLabel: 'Facile',
    questions: [],
  ),
];

Future<void> _pumpEmbedded(
  WidgetTester tester,
  Widget tab, {
  required List<Override> overrides,
  Size size = const Size(390, 844),
  double textScale = 1.0,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          // Shell clair de l'accueil + contrat embeddedLight.
          child: Scaffold(
            backgroundColor: IntelliaColors.backgroundPrimary,
            body: TabSurface(
              palette: const TabPalette(TabPresentationMode.embeddedLight),
              child: tab,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color _titleColor(WidgetTester tester, String title) =>
    tester.widget<Text>(find.text(title)).style!.color!;

void main() {
  group('TabPalette', () {
    test('embeddedLight = textes sombres ; standaloneDark = blancs', () {
      const light = TabPalette(TabPresentationMode.embeddedLight);
      const dark = TabPalette(TabPresentationMode.standaloneDark);

      expect(light.textPrimary, IntelliaColors.textPrimary);
      expect(light.textPrimary.computeLuminance(), lessThan(0.2));
      expect(dark.textPrimary, const Color(0xFFFFFFFF));
      expect(light.isLight, isTrue);
      expect(dark.useGlass, isTrue);
      expect(light.useGlass, isFalse);
    });
  });

  group('Apprendre embedded (shell clair)', () {
    for (final size in _sizes) {
      for (final scale in _scales) {
        testWidgets(
          'lisible ${size.width.toInt()}x${size.height.toInt()} @${scale}x',
          (tester) async {
            await _pumpEmbedded(
              tester,
              const LearnHubScreen(embedded: true),
              overrides: [
                learnHubProvider.overrideWith((ref) async => _learnSnapshot()),
              ],
              size: size,
              textScale: scale,
            );

            expect(find.text('Apprendre'), findsOneWidget);
            // Titre sombre (jamais blanc sur clair) — à toutes les échelles.
            expect(
              _titleColor(tester, 'Apprendre'),
              IntelliaColors.textPrimary,
            );
            // Recherche lisible présente.
            expect(find.text('Rechercher une matière…'), findsOneWidget);
            // La tuile est dans la grille ; à grand texte sur petit écran elle
            // passe sous la ligne de flottaison (sliver paresseux) → on ne
            // vérifie sa présence qu'à l'échelle nominale.
            if (scale == 1.0) {
              expect(find.text('Mathématiques'), findsOneWidget);
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets('reduced motion : rendu sans exception', (tester) async {
      await _pumpEmbedded(
        tester,
        const LearnHubScreen(embedded: true),
        overrides: [
          learnHubProvider.overrideWith((ref) async => _learnSnapshot()),
        ],
        reduceMotion: true,
      );
      expect(find.text('Apprendre'), findsOneWidget);
      expect(_titleColor(tester, 'Apprendre'), IntelliaColors.textPrimary);
      expect(tester.takeException(), isNull);
    });
  });

  group('Quiz embedded (shell clair)', () {
    for (final size in _sizes) {
      testWidgets('lisible ${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        await _pumpEmbedded(
          tester,
          const QuizHubScreen(embedded: true),
          overrides: [quizHubProvider.overrideWith((ref) async => _quizzes())],
          size: size,
        );

        expect(find.text('Quiz'), findsOneWidget);
        expect(_titleColor(tester, 'Quiz'), IntelliaColors.textPrimary);
        expect(find.text('Test de logique'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('texte 1.5 + reduced motion sans exception', (tester) async {
      await _pumpEmbedded(
        tester,
        const QuizHubScreen(embedded: true),
        overrides: [quizHubProvider.overrideWith((ref) async => _quizzes())],
        textScale: 1.5,
        reduceMotion: true,
      );
      expect(find.text('Quiz'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
