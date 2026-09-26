import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/profile/data/account_deletion_service.dart';
import 'package:intellia237/features/profile/presentation/widgets/account_deletion_tile.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

class _FakeDeletionService implements AccountDeletionService {
  int requests = 0;
  int cancellations = 0;

  @override
  Future<DateTime?> requestDeletion() async {
    requests += 1;
    return DateTime(2026, 9, 28);
  }

  @override
  Future<void> cancelDeletion() async {
    cancellations += 1;
  }

  @override
  Stream<AccountDeletionState> watch(String uid) => const Stream.empty();
}

Future<_FakeDeletionService> _pump(
  WidgetTester tester,
  AccountDeletionState state, {
  Locale locale = const Locale('fr'),
}) async {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final service = _FakeDeletionService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountDeletionServiceProvider.overrideWithValue(service),
        accountDeletionStateProvider.overrideWith((ref) => Stream.value(state)),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: AccountDeletionTile()),
      ),
    ),
  );
  await tester.pump();
  return service;
}

void main() {
  testWidgets('no request: the tile asks, then schedules without signing out', (
    tester,
  ) async {
    final service = await _pump(tester, AccountDeletionState.none);
    expect(find.text('Suppression du compte'), findsOneWidget);

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(find.textContaining('dans 7 jours'), findsOneWidget);
    await tester.tap(find.text('Envoyer la demande'));
    await tester.pumpAndSettle();

    expect(service.requests, 1);
    expect(find.textContaining('Suppression programmée le'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scheduled: the date is shown and a tap cancels', (tester) async {
    final service = await _pump(
      tester,
      AccountDeletionState(status: 'scheduled', dueAt: DateTime(2026, 9, 28)),
    );
    expect(find.textContaining('Suppression prévue le'), findsOneWidget);

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler la suppression'));
    await tester.pumpAndSettle();

    expect(service.cancellations, 1);
    expect(find.text('La suppression est annulée.'), findsOneWidget);
  });

  testWidgets('processing: no action is offered any more', (tester) async {
    final service = await _pump(
      tester,
      const AccountDeletionState(status: 'processing'),
    );
    expect(find.text('Suppression en cours de traitement.'), findsOneWidget);
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(service.requests + service.cancellations, 0);
  });

  testWidgets('English copy at 360 px with large text does not overflow', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(
      tester,
      AccountDeletionState(status: 'scheduled', dueAt: DateTime(2026, 9, 28)),
      locale: const Locale('en'),
    );
    expect(find.textContaining('Deletion scheduled for'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
