import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/study_reserve/data/study_reserve_service.dart';
import 'package:intellia237/features/study_reserve/domain/study_reserve.dart';
import 'package:intellia237/features/study_reserve/presentation/study_reserve_card.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

/// Service factice : répond par élève, peut rester en attente ou échouer.
class _FakeReserveService extends StudyReserveService {
  _FakeReserveService(this.respond);

  Future<StudyReserve> Function(String? studentId) respond;
  int calls = 0;

  @override
  Future<StudyReserve> fetch({String? studentId}) {
    calls++;
    return respond(studentId);
  }
}

Future<void> _pump(
  WidgetTester tester,
  _FakeReserveService service,
  Widget child, {
  Locale locale = const Locale('fr'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [studyReserveServiceProvider.overrideWithValue(service)],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

StudyReserve _reserve(String id, int percent, StudyReserveStatus status) =>
    StudyReserve(studentId: id, percentRemaining: percent, status: status);

void main() {
  testWidgets('loading keeps a visible Study reserve frame (never blank)', (
    tester,
  ) async {
    final pending = Completer<StudyReserve>();
    await _pump(
      tester,
      _FakeReserveService((_) => pending.future),
      const StudyReserveCard(),
    );
    expect(find.byKey(const ValueKey('study-reserve-loading')), findsOneWidget);
    expect(find.text('Réserve d’étude'), findsOneWidget);
    pending.complete(_reserve('', 60, StudyReserveStatus.healthy));
    await tester.pumpAndSettle();
    expect(find.textContaining('60 %'), findsOneWidget);
  });

  for (final locale in const [Locale('fr'), Locale('en')]) {
    testWidgets(
      'network error is distinct from server unavailable and retries (${locale.languageCode})',
      (tester) async {
        var fail = true;
        final service = _FakeReserveService((_) async {
          if (fail) throw Exception('unavailable');
          return _reserve('', 0, StudyReserveStatus.unavailable);
        });
        await _pump(tester, service, const StudyReserveCard(), locale: locale);
        await tester.pumpAndSettle();

        final fr = locale.languageCode == 'fr';
        expect(
          find.byKey(const ValueKey('study-reserve-error')),
          findsOneWidget,
        );
        expect(
          find.text(
            fr
                ? 'Impossible de charger la réserve d’étude pour le moment.'
                : 'Couldn’t load the study reserve right now.',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(fr ? 'indisponible' : 'unavailable'),
          findsNothing,
        );

        fail = false;
        await tester.tap(find.text(fr ? 'Réessayer' : 'Try again'));
        await tester.pumpAndSettle();

        // La réponse légitime « unavailable » reste affichée, jamais masquée.
        expect(service.calls, 2);
        expect(
          find.byKey(const ValueKey('study-reserve-gauge')),
          findsOneWidget,
        );
        expect(
          find.text(
            fr
                ? 'Réserve d’étude indisponible pour le moment.'
                : 'Study reserve unavailable right now.',
          ),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('parent view: each linked child shows its own reserve', (
    tester,
  ) async {
    final service = _FakeReserveService(
      (id) async => switch (id) {
        'amelie' => _reserve('amelie', 82, StudyReserveStatus.healthy),
        'junior' => _reserve('junior', 31, StudyReserveStatus.low),
        _ => throw StateError('unexpected $id'),
      },
    );
    await _pump(
      tester,
      service,
      const Column(
        children: [
          StudyReserveCard(studentId: 'amelie', compact: true),
          StudyReserveCard(studentId: 'junior', compact: true),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('study-reserve-gauge')), findsNWidgets(2));
    expect(find.text('82 % restants'), findsOneWidget);
    expect(find.text('31 % restants'), findsOneWidget);
    expect(service.calls, 2);
  });
}
