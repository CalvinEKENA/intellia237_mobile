import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/mobile_money/presentation/mobile_money_parent_tab.dart';
import 'package:intellia237/features/notifications/data/notification_repository.dart';
import 'package:intellia237/features/parent/application/parent_preview.dart';
import 'package:intellia237/features/parent/application/parent_providers.dart';
import 'package:intellia237/features/parent/application/pending_child_link.dart';
import 'package:intellia237/features/parent/data/child_link_service.dart';
import 'package:intellia237/features/parent/data/parent_repository.dart';
import 'package:intellia237/features/parent/domain/parent_dashboard.dart';
import 'package:intellia237/features/parent/presentation/parent_home_screen.dart';
import 'package:intellia237/features/tour_guide/data/tour_guide_repository.dart';
import 'package:intellia237/features/tour_guide/data/firestore_tour_guide_repository.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

class _TestAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
    role: AppRole.admin,
    userId: 'super-admin-uid',
    email: 'calvinekena4@gmail.com',
    isSuperAdmin: true,
  );
}

class _EmptyParentRepository implements ParentRepository {
  @override
  Future<ParentDashboard> fetchDashboard({required String parentUid}) async =>
      const ParentDashboard(children: [], announcements: []);
}

class _SeenTourRepository implements TourGuideRepository {
  @override
  Future<bool> hasSeenTour(String uid) async => true;
  @override
  Future<void> markTourSeen(String uid) async {}
}

void main() {
  testWidgets(
    'Paiements neutralisés + bandeau pendant la prévisualisation d\'un autre '
    'parent, et quitter réinitialise le mode',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_TestAuthController.new),
          parentRepositoryProvider.overrideWithValue(_EmptyParentRepository()),
          unreadNotificationCountProvider.overrideWithValue(0),
          tourGuideRepositoryProvider.overrideWithValue(_SeenTourRepository()),
        ],
      );
      addTearDown(container.dispose);

      // Prévisualisation active, ciblant un AUTRE parent → impersonation.
      final entered = container
          .read(parentPreviewControllerProvider.notifier)
          .enter(targetParentUid: 'other-parent-uid', targetParentLabel: 'Awa');
      expect(entered, isTrue);

      final router = GoRouter(
        initialLocation: AppRoutes.parentHome,
        routes: [
          GoRoute(
            path: AppRoutes.parentHome,
            builder: (_, _) => const ParentHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminHome,
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('ADMIN-HOME'))),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            routerConfig: router,
          ),
        ),
      );
      // pump borné (certaines vues d'état ont une animation continue).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Bandeau de prévisualisation visible et dismissible.
      expect(find.byKey(const ValueKey('parent-preview-exit')), findsOneWidget);

      // L'onglet Paiements (IndexedStack, index 3, hors écran au repos) est
      // neutralisé : le vrai formulaire de paiement n'est jamais monté pendant
      // l'impersonation d'un autre parent.
      expect(
        find.byKey(
          const ValueKey('parent-preview-payments-blocked'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.byType(MobileMoneyParentTab, skipOffstage: false),
        findsNothing,
      );

      // Quitter l'aperçu réinitialise le mode et revient à l'administration.
      await tester.tap(find.byKey(const ValueKey('parent-preview-exit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(container.read(parentPreviewControllerProvider).active, isFalse);
      expect(find.text('ADMIN-HOME'), findsOneWidget);
    },
  );

  // Device QA round 2 : le parcours « code enfant » n'existe que pour un vrai
  // parent authentifié. La prévisualisation du super-administrateur ne relie
  // rien, n'affiche aucun compte rendu de liaison, et garde son rôle réel.
  testWidgets(
    'la prévisualisation n’affiche ni ajout d’enfant ni compte rendu de liaison',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_TestAuthController.new),
          parentRepositoryProvider.overrideWithValue(_EmptyParentRepository()),
          unreadNotificationCountProvider.overrideWithValue(0),
          tourGuideRepositoryProvider.overrideWithValue(_SeenTourRepository()),
          childLinkServiceProvider.overrideWithValue(_FailingLinkService()),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(parentPreviewControllerProvider.notifier).enter(),
        isTrue,
      );
      // Un compte rendu d'échec en mémoire ne doit pas s'afficher en aperçu.
      final pending = container.read(pendingChildLinkProvider.notifier);
      expect(pending.hold('K7MP2QXA'), isTrue);
      await pending.linkPending();
      expect(container.read(pendingChildLinkProvider).report, isNotNull);

      final router = GoRouter(
        initialLocation: AppRoutes.parentHome,
        routes: [
          GoRoute(
            path: AppRoutes.parentHome,
            builder: (_, _) => const ParentHomeScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(const ValueKey('parent-preview-exit')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('parent-child-link-report')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('parent-add-child'), skipOffstage: false),
        findsNothing,
      );
      final auth = container.read(authControllerProvider);
      expect(auth.role, AppRole.admin);
      expect(auth.isSuperAdmin, isTrue);
    },
  );
}

class _FailingLinkService extends ChildLinkService {
  @override
  Future<ChildLinkResult> linkChildByCode(String code) async =>
      throw const ChildLinkException('permission-denied');
}
