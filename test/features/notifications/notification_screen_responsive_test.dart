import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/widgets/tab_presentation.dart';
import 'package:intellia237/core/widgets/tab_section_header.dart';
import 'package:intellia237/features/notifications/data/notification_repository.dart';
import 'package:intellia237/features/notifications/domain/student_notification.dart';
import 'package:intellia237/features/notifications/presentation/student_notifications_screen.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('empty notification inbox is genuinely localized in English', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentNotificationsProvider.overrideWith(
            (ref) => Stream.value(const <StudentNotification>[]),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: StudentNotificationsScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('All quiet'), findsOneWidget);
    expect(find.text('Tout est calme'), findsNothing);
  });

  testWidgets('notification cards fit at 360 px and textScale 1.5', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentNotificationsProvider.overrideWith(
            (ref) => Stream.value([
              StudentNotification(
                id: 'notification-1',
                title: 'Une nouvelle séquence de mathématiques est disponible',
                body:
                    'Reprends ton parcours lorsque tu es prêt. Ce message '
                    'reste accessible même si la notification système est '
                    'retardée.',
                route: '/learn',
                createdAt: DateTime(2026, 9, 4, 12, 30),
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.5),
            ),
            child: const StudentNotificationsScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('nouvelle séquence'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared tab header remains pinned after scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.5),
            ),
            child: TabSurface(
              palette: TabPalette(TabPresentationMode.embeddedLight),
              child: CustomScrollView(
                slivers: [
                  StickyTabSectionHeader(
                    key: ValueKey('contract-sticky-header'),
                    eyebrow: 'Espace élève',
                    title: 'Mon profil',
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 1800)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final before = tester.getTopLeft(find.text('Mon profil')).dy;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -650));
    await tester.pumpAndSettle();
    final after = tester.getTopLeft(find.text('Mon profil')).dy;

    expect(after, greaterThanOrEqualTo(0));
    expect(after, lessThanOrEqualTo(before));
    expect(tester.takeException(), isNull);
  });
}
