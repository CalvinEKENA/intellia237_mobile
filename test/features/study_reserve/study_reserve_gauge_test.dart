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
}
