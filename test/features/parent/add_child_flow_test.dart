import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/notifications/data/notification_repository.dart';
import 'package:intellia237/features/parent/application/parent_providers.dart';
import 'package:intellia237/features/parent/data/child_link_service.dart';
import 'package:intellia237/features/parent/data/parent_repository.dart';
import 'package:intellia237/features/parent/domain/parent_child_profile.dart';
import 'package:intellia237/features/parent/domain/parent_dashboard.dart';
import 'package:intellia237/features/parent/presentation/parent_home_screen.dart';
import 'package:intellia237/features/tour_guide/data/tour_guide_repository.dart';
import 'package:intellia237/features/tour_guide/data/firestore_tour_guide_repository.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

class _ParentAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
    role: AppRole.parent,
    userId: 'parent-1',
    email: 'parent@example.com',
  );
}

/// État mutable partagé : le faux service de liaison y ajoute l'enfant, et le
/// faux dépôt le renvoie au prochain fetch → prouve le rafraîchissement.
class _LinkWorld {
  final List<ParentChildProfile> children = [];
}

class _FakeParentRepository implements ParentRepository {
  _FakeParentRepository(this.world);
  final _LinkWorld world;
  @override
  Future<ParentDashboard> fetchDashboard({required String parentUid}) async =>
      ParentDashboard(
        children: List.of(world.children),
        announcements: const [],
      );
}

class _FakeChildLinkService extends ChildLinkService {
  _FakeChildLinkService(this.world);
  final _LinkWorld world;

  @override
  Future<ChildLinkResult> linkChildByCode(String code) async {
    if (code == 'BADCODE1') {
      throw const ChildLinkException('not-found');
    }
    world.children.add(
      const ParentChildProfile(
        id: 'student-1',
        firstName: 'Awa',
        classLevel: 'Terminale',
        series: 'D',
        globalProgress: 0,
        studyMinutesToday: 0,
        studyMinutesTarget: 45,
        strongSubjects: [],
        weakSubjects: [],
        weeklyProgress: [],
      ),
    );
    return const ChildLinkResult(
      studentId: 'student-1',
      firstName: 'Awa',
      classLevel: 'Terminale',
      alreadyLinked: false,
    );
  }
}

class _SeenTourRepository implements TourGuideRepository {
  @override
  Future<bool> hasSeenTour(String uid) async => true;
  @override
  Future<void> markTourSeen(String uid) async {}
}

Future<void> _pumpParentHome(WidgetTester tester, _LinkWorld world) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_ParentAuthController.new),
        parentRepositoryProvider.overrideWithValue(
          _FakeParentRepository(world),
        ),
        childLinkServiceProvider.overrideWithValue(
          _FakeChildLinkService(world),
        ),
        unreadNotificationCountProvider.overrideWithValue(0),
        tourGuideRepositoryProvider.overrideWithValue(_SeenTourRepository()),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('fr'),
        home: ParentHomeScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('a valid code links a child and the dashboard refreshes', (
    tester,
  ) async {
    final world = _LinkWorld();
    await _pumpParentHome(tester, world);

    // État vide → le bouton d'ajout est présent sur l'accueil parent.
    expect(find.byKey(const ValueKey('parent-add-child')), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('parent-add-child')).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const ValueKey('parent-add-child-code')),
      'ABCDEFGH',
    );
    await tester.tap(find.byKey(const ValueKey('parent-add-child-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // L'enfant lié apparaît (tableau de bord rafraîchi) + message de succès.
    expect(find.text('Awa'), findsWidgets);
    expect(find.textContaining('Awa'), findsWidgets);
  });

  testWidgets('an invalid code shows an explicit error and links nothing', (
    tester,
  ) async {
    final world = _LinkWorld();
    await _pumpParentHome(tester, world);

    await tester.tap(find.byKey(const ValueKey('parent-add-child')).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const ValueKey('parent-add-child-code')),
      'BADCODE1',
    );
    await tester.tap(find.byKey(const ValueKey('parent-add-child-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Message localisé depuis le CODE stable 'not-found' (jamais figé côté
    // service).
    expect(
      find.text('Ce code enfant est introuvable. Vérifie-le avec ton enfant.'),
      findsOneWidget,
    );
    expect(world.children, isEmpty);
  });
}
