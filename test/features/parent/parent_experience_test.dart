import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/notifications/data/notification_repository.dart';
import 'package:intellia237/features/parent/application/parent_providers.dart';
import 'package:intellia237/features/parent/data/parent_repository.dart';
import 'package:intellia237/features/parent/domain/parent_announcement.dart';
import 'package:intellia237/features/parent/domain/parent_child_profile.dart';
import 'package:intellia237/features/parent/domain/parent_dashboard.dart';
import 'package:intellia237/features/parent/presentation/child_overview_screen.dart';
import 'package:intellia237/features/parent/presentation/child_progress_screen.dart';
import 'package:intellia237/features/parent/presentation/parent_home_screen.dart';
import 'package:intellia237/features/tour_guide/data/tour_guide_repository.dart';
import 'package:intellia237/features/tour_guide/data/firestore_tour_guide_repository.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

// Matrice imposée par la mission (D).
const _widths = [320.0, 360.0, 390.0, 412.0, 480.0, 600.0];
const _scales = [1.0, 1.3, 1.5, 2.0];
const _locales = [Locale('fr'), Locale('en')];

class _ParentAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
    role: AppRole.parent,
    userId: 'parent-1',
    email: 'parent@example.com',
  );
}

ParentChildProfile _child(
  String id,
  String name, {
  bool withData = true,
  String? series,
}) => ParentChildProfile(
  id: id,
  firstName: name,
  classLevel: 'Terminale',
  series: series,
  globalProgress: withData ? 0.62 : 0,
  studyMinutesToday: withData ? 35 : 0,
  studyMinutesTarget: 45,
  strongSubjects: const [],
  weakSubjects: const [],
  weeklyProgress: withData
      ? const [0.2, 0.4, 0.5, 0.6, 0.7, 0.6, 0.62]
      : const [],
  hasProgressData: withData,
  hasStudyTimeData: withData,
);

class _FakeParentRepository implements ParentRepository {
  _FakeParentRepository(this.dashboard, {this.fail = false});
  final ParentDashboard dashboard;
  final bool fail;
  @override
  Future<ParentDashboard> fetchDashboard({required String parentUid}) async {
    if (fail) throw Exception('offline');
    return dashboard;
  }
}

class _SeenTourRepository implements TourGuideRepository {
  @override
  Future<bool> hasSeenTour(String uid) async => true;
  @override
  Future<void> markTourSeen(String uid) async {}
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  required Size size,
  required double textScale,
  required Locale locale,
  required ParentRepository repository,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_ParentAuthController.new),
        parentRepositoryProvider.overrideWithValue(repository),
        unreadNotificationCountProvider.overrideWithValue(0),
        tourGuideRepositoryProvider.overrideWithValue(_SeenTourRepository()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: home,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  final multiChild = ParentDashboard(
    children: [
      _child('c1', 'Awa', series: 'D'),
      _child('c2', 'Bilo', withData: false),
      _child('c3', 'Céline', series: 'C'),
    ],
    announcements: [
      ParentAnnouncement(
        id: 'a1',
        title: 'Réunion parents-professeurs',
        body:
            'Une rencontre est prévue pour discuter des progrès de la classe.',
        publishedAt: DateTime(2026, 9, 1),
      ),
    ],
  );

  group(
    'Parent home renders across the full responsive/textScale/locale matrix',
    () {
      for (final locale in _locales) {
        for (final width in _widths) {
          for (final scale in _scales) {
            testWidgets(
              'multi-enfants ${width.toInt()}px @${scale}x ${locale.languageCode}',
              (tester) async {
                await _pump(
                  tester,
                  const ParentHomeScreen(),
                  size: Size(width, 900),
                  textScale: scale,
                  locale: locale,
                  repository: _FakeParentRepository(multiChild),
                );
                expect(tester.takeException(), isNull);
                // Le sélecteur d'enfant expose bien plusieurs enfants.
                expect(find.text('Awa'), findsWidgets);
              },
            );
          }
        }
      }
    },
  );

  testWidgets('empty state (no children) exposes the add-child CTA', (
    tester,
  ) async {
    await _pump(
      tester,
      const ParentHomeScreen(),
      size: const Size(360, 800),
      textScale: 1.0,
      locale: const Locale('fr'),
      repository: _FakeParentRepository(
        const ParentDashboard(children: [], announcements: []),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('parent-add-child')), findsWidgets);
  });

  testWidgets('empty state stays overflow-free at textScale 2.0 / 320px', (
    tester,
  ) async {
    await _pump(
      tester,
      const ParentHomeScreen(),
      size: const Size(320, 800),
      textScale: 2.0,
      locale: const Locale('en'),
      repository: _FakeParentRepository(
        const ParentDashboard(children: [], announcements: []),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline/error state stays legible and offers retry', (
    tester,
  ) async {
    await _pump(
      tester,
      const ParentHomeScreen(),
      size: const Size(360, 800),
      textScale: 1.5,
      locale: const Locale('fr'),
      repository: _FakeParentRepository(
        const ParentDashboard(children: [], announcements: []),
        fail: true,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Réessayer'), findsWidgets);
  });

  group('Child overview & progress screens render at extremes', () {
    for (final size in const [Size(320, 800), Size(600, 900)]) {
      for (final scale in const [1.0, 2.0]) {
        testWidgets('overview ${size.width.toInt()}px @${scale}x', (
          tester,
        ) async {
          await _pump(
            tester,
            const ChildOverviewScreen(childId: 'c1'),
            size: size,
            textScale: scale,
            locale: const Locale('fr'),
            repository: _FakeParentRepository(multiChild),
          );
          expect(tester.takeException(), isNull);
        });
        testWidgets('progress ${size.width.toInt()}px @${scale}x', (
          tester,
        ) async {
          await _pump(
            tester,
            const ChildProgressScreen(childId: 'c1'),
            size: size,
            textScale: scale,
            locale: const Locale('en'),
            repository: _FakeParentRepository(multiChild),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
