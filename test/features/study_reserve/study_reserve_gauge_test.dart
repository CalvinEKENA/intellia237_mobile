import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/study_reserve/domain/study_reserve.dart';
import 'package:intellia237/features/study_reserve/presentation/study_reserve_gauge.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester,
  StudyReserve reserve, {
  required Locale locale,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: StudyReserveGauge(reserve: reserve)),
    ),
  );
  await tester.pump();
}

String _allText(WidgetTester tester) {
  final buffer = StringBuffer();
  for (final e in find.byType(Text).evaluate()) {
    buffer.write((e.widget as Text).data ?? '');
    buffer.write(' ');
  }
  return buffer.toString();
}

void main() {
  StudyReserve reserve(int percent, StudyReserveStatus status) => StudyReserve(
    studentId: 's1',
    percentRemaining: percent,
    status: status,
    cycleEnd: DateTime(2026, 7, 1),
  );

  testWidgets('renders the product-safe title and percentage (FR)', (
    tester,
  ) async {
    await _pump(
      tester,
      reserve(75, StudyReserveStatus.healthy),
      locale: const Locale('fr'),
    );
    final text = _allText(tester);
    expect(text, contains('Réserve d’étude'));
    expect(text, contains('75 % restants'));
    expect(text, contains('Bonne réserve'));
    // Aucun terme technique/gamifié n'est jamais affiché.
    for (final banned in ['token', 'Token', 'XP', 'crédit', 'credit']) {
      expect(text.contains(banned), isFalse, reason: banned);
    }
  });

  testWidgets('renders in English with the same product-safe wording', (
    tester,
  ) async {
    await _pump(
      tester,
      reserve(75, StudyReserveStatus.healthy),
      locale: const Locale('en'),
    );
    final text = _allText(tester);
    expect(text, contains('Study reserve'));
    expect(text, contains('75% remaining'));
    expect(text, contains('Plenty left'));
  });

  testWidgets('depleted state explains the tutor rests, content stays', (
    tester,
  ) async {
    await _pump(
      tester,
      reserve(0, StudyReserveStatus.depleted),
      locale: const Locale('fr'),
    );
    final text = _allText(tester);
    expect(text, contains('0 % restants'));
    expect(text, contains('Réserve épuisée'));
    expect(text, contains('cours'));
  });

  testWidgets('unavailable state never fabricates a percentage', (
    tester,
  ) async {
    await _pump(
      tester,
      const StudyReserve(
        studentId: 's1',
        percentRemaining: 0,
        status: StudyReserveStatus.unavailable,
      ),
      locale: const Locale('fr'),
    );
    final text = _allText(tester);
    expect(text, contains('Réserve d’étude'));
    expect(text, contains('indisponible'));
    // Ni « 100 % » ni « 0 % » : aucune donnée inventée.
    expect(text.contains('%'), isFalse);
  });

  // États visuels imposés : 100/75/50/25/5/0.
  final visualStates = <(int, StudyReserveStatus)>[
    (100, StudyReserveStatus.healthy),
    (75, StudyReserveStatus.healthy),
    (50, StudyReserveStatus.warning),
    (25, StudyReserveStatus.low),
    (5, StudyReserveStatus.critical),
    (0, StudyReserveStatus.depleted),
  ];
  for (final (percent, status) in visualStates) {
    for (final locale in const [Locale('fr'), Locale('en')]) {
      testWidgets('visual state $percent% (${locale.languageCode})', (
        tester,
      ) async {
        await _pump(tester, reserve(percent, status), locale: locale);
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('study-reserve-gauge')),
          findsOneWidget,
        );
      });
    }
  }

  // Responsive + textScale : aucun débordement.
  for (final width in const [320.0, 360.0, 390.0, 412.0, 480.0, 600.0]) {
    for (final scale in const [1.0, 1.3, 1.5, 2.0]) {
      testWidgets('no overflow ${width.toInt()}px @${scale}x', (tester) async {
        tester.view.physicalSize = Size(width, 400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 400),
                textScaler: TextScaler.linear(scale),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: StudyReserveGauge(
                    reserve: reserve(5, StudyReserveStatus.critical),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('multiple children each render their own distinct reserve', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: ListView(
            children: [
              StudyReserveGauge(
                reserve: reserve(82, StudyReserveStatus.healthy),
              ),
              StudyReserveGauge(reserve: reserve(31, StudyReserveStatus.low)),
              StudyReserveGauge(
                reserve: reserve(4, StudyReserveStatus.critical),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    // Trois réserves indépendantes, jamais agrégées.
    expect(find.textContaining('82 %'), findsOneWidget);
    expect(find.textContaining('31 %'), findsOneWidget);
    expect(find.textContaining('4 %'), findsOneWidget);
  });
}
