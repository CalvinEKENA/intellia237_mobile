import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/flow/application/flow_controller.dart';
import 'package:intellia237/features/flow/data/flow_feed_repository.dart';
import 'package:intellia237/features/flow/data/flow_points_gateway.dart';
import 'package:intellia237/features/flow/domain/flow_item.dart';
import 'package:intellia237/features/flow/presentation/flow_screen.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Parcours ne charge plus tout le catalogue à l'ouverture : une première
/// fenêtre, puis la suite à la demande, sans cascade d'appels.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  test(
    'a window follows at most two empty pages, never the whole catalog',
    () async {
      final feed = _PagedFeed({
        null: const FlowFeedPage(items: [], nextCursor: 'c1'),
        'c1': const FlowFeedPage(items: [], nextCursor: 'c2'),
        'c2': FlowFeedPage(items: _notions('late', 3), nextCursor: 'c3'),
      });
      final page = await fetchFlowWindow(feed, '3eme');
      expect(feed.requests, hasLength(kFlowMaxPagesPerLoad));
      expect(page.items, isEmpty);
      expect(page.nextCursor, 'c2');
    },
  );

  test('an empty page followed by content is still served', () async {
    final feed = _PagedFeed({
      null: const FlowFeedPage(items: [], nextCursor: 'c1'),
      'c1': FlowFeedPage(items: _notions('later', 1)),
    });
    final page = await fetchFlowWindow(feed, '6eme');
    expect(page.items.map((item) => item.id), ['later-0']);
  });

  testWidgets('opening Parcours reads one small window, not the catalog', (
    tester,
  ) async {
    final feed = _PagedFeed({
      null: FlowFeedPage(items: _notions('p1', 12), nextCursor: 'c2'),
      'c2': FlowFeedPage(items: _notions('p2', 12), nextCursor: 'c3'),
      'c3': FlowFeedPage(items: _notions('p3', 12), nextCursor: 'c4'),
    });
    await _pump(tester, feed);

    expect(feed.requests, [(null, kFlowFirstPageSize)]);
    expect(_pageCount(tester), 12);
    await _dispose(tester);
  });

  testWidgets('the next page is asked once, near the end, and appended', (
    tester,
  ) async {
    final feed = _PagedFeed({
      null: FlowFeedPage(items: _notions('p1', 6), nextCursor: 'c2'),
      'c2': FlowFeedPage(items: _notions('p2', 6)),
    });
    await _pump(tester, feed);
    expect(feed.requests, [(null, kFlowFirstPageSize)]);

    // Deux cartes avant le seuil : rien n'est demandé.
    await _swipe(tester);
    expect(feed.requests, hasLength(1));
    // À quatre cartes de la fin : une seule demande pour la suite.
    await _swipe(tester);
    await _swipe(tester);
    expect(feed.requests, [
      (null, kFlowFirstPageSize),
      ('c2', kFlowNextPageSize),
    ]);
    expect(_pageCount(tester), 12);

    // Le fil est complet : plus aucune demande, même en arrivant au bout.
    for (var i = 0; i < 8; i++) {
      await _swipe(tester);
    }
    expect(feed.requests, hasLength(2));
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  testWidgets('a failing network stops asking after the retry budget', (
    tester,
  ) async {
    final feed = _PagedFeed(
      {null: FlowFeedPage(items: _notions('p1', 6), nextCursor: 'c2')},
      failingCursors: {'c2'},
    );
    await _pump(tester, feed);
    for (var i = 0; i < 5; i++) {
      await _swipe(tester);
    }
    final followUps = feed.requests.where((request) => request.$1 == 'c2');
    expect(followUps.length, lessThanOrEqualTo(kFlowMaxLoadFailures));
    expect(_pageCount(tester), 6, reason: 'l’élève garde ses cartes');
    await _dispose(tester);
  });
}

const _uid = 'student-pagination';

List<FlowItem> _notions(String prefix, int count) => [
  for (var i = 0; i < count; i++)
    FlowItem(
      id: '$prefix-$i',
      type: FlowItemType.notion,
      title: 'Carte $prefix $i',
      subjectId: i.isEven ? 'maths' : 'svt',
      classLevels: const ['3eme'],
      status: 'published',
      payload: {
        'insight': 'Idée $i',
        'points': ['Point $i'],
      },
    ),
];

int _pageCount(WidgetTester tester) =>
    tester
        .widget<PageView>(find.byType(PageView))
        .childrenDelegate
        .estimatedChildCount ??
    -1;

Future<void> _swipe(WidgetTester tester) async {
  await tester.drag(find.byType(PageView), const Offset(0, -600));
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pump(WidgetTester tester, _PagedFeed feed) async {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(const {});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        flowDemoContentPermittedProvider.overrideWithValue(false),
        authControllerProvider.overrideWith(_SignedInStudent.new),
        studentAcademicContextProvider.overrideWith(
          (ref) async => const LearnAcademicContext(
            classLevel: '3ème',
            catalogClassLevel: '3eme',
          ),
        ),
        learnCatalogRevisionProvider.overrideWith(
          (ref) => Stream<String>.value('revision-1'),
        ),
        flowFeedRepositoryProvider.overrideWithValue(feed),
        flowPointsGatewayProvider.overrideWithValue(_NoopGateway()),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: FlowScreen(),
      ),
    ),
  );
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
}

class _SignedInStudent extends AuthController {
  @override
  AuthState build() =>
      const AuthState.authenticated(role: AppRole.student, userId: _uid);
}

class _PagedFeed implements FlowFeedRepository {
  _PagedFeed(this.pages, {this.failingCursors = const {}});

  final Map<String?, FlowFeedPage> pages;
  final Set<String> failingCursors;
  final requests = <(String?, int)>[];

  @override
  Future<FlowFeedPage> fetchPage({
    required String classLevel,
    String? cursor,
    int limit = kFlowPageSize,
  }) async {
    requests.add((cursor, limit));
    if (failingCursors.contains(cursor)) throw StateError('offline');
    return pages[cursor] ?? const FlowFeedPage(items: []);
  }
}

class _NoopGateway implements FlowPointsGateway {
  var _event = 0;

  @override
  String newClientEventId() => 'event_${++_event}_abcdefgh';

  @override
  Future<FlowPointsResult> submit(FlowActivityCommand command) async =>
      FlowPointsResult(
        clientEventId: command.clientEventId,
        cardId: command.cardId,
        correct: true,
        pointsAwarded: 0,
        totalPoints: 0,
        alreadyCompleted: false,
        dailyCapReached: false,
        idempotentReplay: false,
      );

  @override
  Future<List<FlowPointsResult>> flushPending() async => const [];

  @override
  Future<int> pendingCount() async => 0;
}
