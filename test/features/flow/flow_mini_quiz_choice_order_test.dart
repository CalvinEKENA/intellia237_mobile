import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/features/flow/application/flow_controller.dart';
import 'package:intellia237/features/flow/data/flow_points_gateway.dart';
import 'package:intellia237/features/flow/domain/flow_card.dart';
import 'package:intellia237/features/flow/domain/flow_subject.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_mini_quiz_card_view.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Anciens QCM de Mon Parcours (6e) : la bonne réponse, souvent écrite en
/// premier, n'est plus forcément en haut ; l'index transmis reste celui du
/// contenu et l'ordre ne bouge plus une fois la carte affichée.
void main() {
  const card = FlowMiniQuizCard(
    id: 'quiz-capitale',
    subject: FlowSubjects.svt,
    question: 'Capitale du Cameroun ?',
    options: ['Yaoundé', 'Douala', 'Garoua', 'Bafoussam'],
    correctIndex: 0,
    explanation: 'Yaoundé est la capitale politique.',
  );

  late _RecordingGateway gateway;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() async {
    SharedPreferences.setMockInitialValues(const {});
    await SharedPreferences.getInstance();
    gateway = _RecordingGateway();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flowPointsGatewayProvider.overrideWithValue(gateway),
          flowCardsProvider.overrideWithValue(const [card]),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: FlowMiniQuizCardView(card: card, onAward: (_) {}),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  List<String> shown(WidgetTester tester) => [...card.options]
    ..sort(
      (a, b) => tester
          .getTopLeft(find.text(a))
          .dy
          .compareTo(tester.getTopLeft(find.text(b)).dy),
    );

  double rowOf(WidgetTester tester, Finder finder) =>
      tester.getCenter(finder).dy;

  testWidgets('bonne réponse : index d’origine transmis, ordre inchangé '
      'pendant la correction, validation sur la bonne ligne', (tester) async {
    await pump(tester);
    final before = shown(tester);
    expect(before.toSet(), card.options.toSet());

    await tester.tap(find.text('Yaoundé'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(gateway.answers, [0]);
    expect(shown(tester), before);
    expect(
      rowOf(tester, find.byIcon(Icons.check_circle_rounded)),
      moreOrLessEquals(rowOf(tester, find.text('Yaoundé')), epsilon: 24),
    );
    expect(find.text(card.explanation), findsOneWidget);
    await _drain(tester);
  });

  testWidgets('mauvaise réponse : l’erreur et la correction restent sur '
      'leurs propositions', (tester) async {
    await pump(tester);
    final before = shown(tester);

    await tester.tap(find.text('Garoua'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(gateway.answers, [2]);
    expect(shown(tester), before);
    expect(
      rowOf(tester, find.byIcon(Icons.cancel_rounded)),
      moreOrLessEquals(rowOf(tester, find.text('Garoua')), epsilon: 24),
    );
    expect(
      rowOf(tester, find.byIcon(Icons.check_circle_rounded)),
      moreOrLessEquals(rowOf(tester, find.text('Yaoundé')), epsilon: 24),
    );
    await _drain(tester);
  });
}

/// Laisse s'achever la récompense et les minuteries de la carte.
Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 5));
}

class _RecordingGateway implements FlowPointsGateway {
  final answers = <Object?>[];
  var _event = 0;

  @override
  String newClientEventId() => 'event_${++_event}_abcdefgh';

  @override
  Future<FlowPointsResult> submit(FlowActivityCommand command) async {
    answers.add(command.answer);
    return FlowPointsResult(
      clientEventId: command.clientEventId,
      cardId: command.cardId,
      correct: command.answer == 0,
      pointsAwarded: 0,
      totalPoints: 0,
      alreadyCompleted: false,
      dailyCapReached: false,
      idempotentReplay: false,
    );
  }

  @override
  Future<List<FlowPointsResult>> flushPending() async => const [];

  @override
  Future<int> pendingCount() async => 0;
}
