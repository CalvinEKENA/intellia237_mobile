import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:intellia237/features/flow/application/flow_controller.dart';
import 'package:intellia237/features/flow/domain/flow_card.dart';
import 'package:intellia237/features/flow/domain/flow_subject.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_card_view.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_typography.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

const chemistry =
    'Propriétés chimiques et synthèse des composés oxygénés — comprendre les transformations';
const paragraph =
    'CH₃CH₂OH + [O] → CH₃CHO + H₂O. Oxidation of an alcohol / Oxydation d’un alcool. x² + y² = r² ; ΔE = hν. Anticonstitutionnellement : les mots longs restent entièrement lisibles.';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });
  final cards = <FlowCard>[
    FlowNotionCard(
      id: 'long',
      subject: FlowSubjects.svt,
      title: chemistry,
      insight: List.filled(8, paragraph).join('\n\n'),
      points: const [paragraph, paragraph],
    ),
    const FlowNotionCard(
      id: 'short',
      subject: FlowSubjects.maths,
      title: 'Énergie',
      insight: 'E = mc²',
      points: [],
    ),
    const FlowQuestionCard(
      id: 'question',
      subject: FlowSubjects.svt,
      question: chemistry,
      answer: paragraph,
    ),
    const FlowMiniQuizCard(
      id: 'quiz',
      subject: FlowSubjects.svt,
      question: chemistry,
      options: [paragraph, paragraph],
      correctIndex: 0,
      explanation: paragraph,
    ),
    const FlowVideoCard(
      id: 'video',
      subject: FlowSubjects.svt,
      title: chemistry,
      description: paragraph,
      durationLabel: '4 s',
      storagePath:
          'educational_assets/global/Terminale/chemistry/lesson/test/video.mp4',
    ),
    const FlowAnimationCard(
      id: 'animation',
      subject: FlowSubjects.maths,
      title: chemistry,
      caption: paragraph,
      kind: FlowAnimationKind.parabola,
    ),
    const FlowAnecdoteCard(
      id: 'anecdote',
      subject: FlowSubjects.svt,
      title: chemistry,
      story: paragraph,
    ),
  ];
  for (final locale in const [Locale('fr'), Locale('en')]) {
    for (final width in [320.0, 360.0, 390.0, 412.0, 480.0, 640.0]) {
      for (final scale in [1.0, 1.3, 1.5, 2.0]) {
        testWidgets(
          'FLOW ${locale.languageCode} width=$width textScale=$scale',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = Size(width, 760);
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            for (final card in cards) {
              await tester.pumpWidget(
                ProviderScope(
                  overrides: [
                    flowCatalogProvider.overrideWith(
                      (_) async => FlowCatalog.empty,
                    ),
                  ],
                  child: MaterialApp(
                    locale: locale,
                    supportedLocales: AppLocalizations.supportedLocales,
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    home: MediaQuery(
                      data: MediaQueryData(
                        size: Size(width, 760),
                        textScaler: TextScaler.linear(scale),
                      ),
                      child: Scaffold(
                        body: FlowCardView(
                          key: ValueKey(card.id),
                          card: card,
                          onAward: (_) {},
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pump(const Duration(seconds: 1));
              expect(
                tester.takeException(),
                isNull,
                reason: '${card.id} at $width × $scale',
              );
              final scroll = find.byKey(const ValueKey('flow-content-scroll'));
              expect(scroll, findsOneWidget);
              await tester.drag(scroll, const Offset(0, -600));
              await tester.pump(const Duration(milliseconds: 500));
              expect(
                tester.takeException(),
                isNull,
                reason: '${card.id} after scrolling',
              );
              // Échelle éditoriale compacte device-QA (jamais l'ancienne trop
              // grande). L'accessibilité de Flutter s'applique par-dessus, non
              // capturée ici — ces valeurs sont la base avant textScale.
              final ctx = tester.element(find.byType(FlowTypographyScope));
              expect(
                FlowTypography.eyebrow(ctx).fontSize,
                inInclusiveRange(12, 13),
              );
              expect(
                FlowTypography.title(ctx).fontSize,
                inInclusiveRange(18, 21),
              );
              expect(
                FlowTypography.question(ctx).fontSize,
                inInclusiveRange(19, 22),
              );
              expect(
                FlowTypography.body(ctx).fontSize,
                inInclusiveRange(15, 17),
              );
              expect(
                FlowTypography.choice(ctx).fontSize,
                inInclusiveRange(15, 16),
              );
              expect(
                FlowTypography.explanation(ctx).fontSize,
                inInclusiveRange(16, 17),
              );
            }
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          },
        );
      }
    }
  }
}
