import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/data/auth_entry_preferences.dart';
import 'package:intellia237/features/auth/data/repositories/firebase_phone_auth_repository.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/auth/domain/repositories/phone_auth_repository.dart';
import 'package:intellia237/features/auth/presentation/auth_gateway_screen.dart';
import 'package:intellia237/features/auth/presentation/phone_auth_screen.dart';
import 'package:intellia237/features/auth/presentation/widgets/pass_auth_progress.dart';
import 'package:intellia237/features/notifications/data/notification_repository.dart';
import 'package:intellia237/features/onboarding/data/onboarding_preferences.dart';
import 'package:intellia237/features/parent/application/parent_providers.dart';
import 'package:intellia237/features/parent/application/pending_child_link.dart';
import 'package:intellia237/features/parent/data/child_link_service.dart';
import 'package:intellia237/features/parent/data/parent_repository.dart';
import 'package:intellia237/features/parent/domain/parent_child_profile.dart';
import 'package:intellia237/features/parent/domain/parent_dashboard.dart';
import 'package:intellia237/features/parent/presentation/parent_entry_screen.dart';
import 'package:intellia237/features/parent/presentation/parent_home_screen.dart';
import 'package:intellia237/features/parent_registration/presentation/parent_registration_screen.dart';
import 'package:intellia237/features/role_registration/data/firebase_role_registration_repository.dart';
import 'package:intellia237/features/role_registration/data/role_registration_repository.dart';
import 'package:intellia237/features/role_registration/domain/admin_registration_payload.dart';
import 'package:intellia237/features/role_registration/domain/parent_registration_payload.dart';
import 'package:intellia237/features/role_registration/domain/registration_result.dart';
import 'package:intellia237/features/role_registration/domain/teacher_registration_payload.dart';
import 'package:intellia237/features/tour_guide/data/firestore_tour_guide_repository.dart';
import 'package:intellia237/features/tour_guide/data/tour_guide_repository.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/intellia_fonts.dart';

/// Device QA round 2 — parcours parent « code d'abord ».
///
/// Reproduction propriétaire : un élève copie son code parent, se déconnecte,
/// choisit « Parent ou responsable », ne trouve aucun champ pour le code,
/// saisit le numéro de l'élève… et se retrouve dans l'espace élève.
///
/// Ces tests enchaînent les vrais écrans (porte d'entrée, entrée parent,
/// téléphone et code SMS, inscription parent, espace parent) sous la vraie
/// fonction de redirection du routeur. Seuls les services distants sont
/// simulés : identités téléphone, profils, liaison par code.
void main() {
  setUpAll(loadIntelliaFonts);
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  testWidgets('A · élève → déconnexion → Élève → même numéro → espace élève', (
    tester,
  ) async {
    final backend = _Backend();
    final journey = await _Journey.start(
      tester,
      backend,
      signedInPhone: _studentPhone,
    );
    expect(journey.location, AppRoutes.studentHome);

    await journey.signOut();
    expect(journey.location, AppRoutes.authGateway);

    await journey.tap('gateway-role-student');
    expect(journey.location, AppRoutes.phoneAuth);
    await journey.verifyPhone(_studentPhone);

    expect(journey.location, AppRoutes.studentHome);
    expect(backend.accountFor(_studentPhone)!.role, AppRole.student);
  });

  testWidgets(
    'B · élève → déconnexion → Parent → champ code avant toute auth',
    (tester) async {
      final backend = _Backend();
      final journey = await _Journey.start(
        tester,
        backend,
        signedInPhone: _studentPhone,
      );
      await journey.signOut();

      await journey.tap('gateway-role-parent');

      expect(journey.location, AppRoutes.parentEntry);
      expect(
        find.byKey(const ValueKey('parent-entry-code-field')),
        findsOneWidget,
      );
      expect(find.text('Code de l’enfant'), findsOneWidget);
      expect(find.text('J’ai un code enfant'), findsWidgets);
      expect(find.byKey(const ValueKey('parent-entry-paste')), findsOneWidget);
      expect(find.text('Je suis déjà parent'), findsOneWidget);
      // Aucune identité, aucune résolution de code.
      expect(backend.currentUid, isNull);
      expect(backend.linkCalls, isEmpty);
    },
  );

  testWidgets('C · code collé → parent existant → enfant visible à l’arrivée', (
    tester,
  ) async {
    final backend = _Backend();
    final journey = await _Journey.start(tester, backend);
    _mockClipboard(tester, 'k7mp-2qxa');

    await journey.tap('gateway-role-parent');
    await journey.tap('parent-entry-paste');
    expect(journey.codeFieldText, 'K7MP2QXA');
    await journey.tap('parent-entry-continue');

    expect(journey.location, AppRoutes.phoneAuth);
    expect(
      find.byKey(const ValueKey('phone-pending-child-code')),
      findsOneWidget,
    );
    expect(backend.linkCalls, isEmpty, reason: 'rien avant l’authentification');

    await journey.verifyPhone(_parentPhone);

    expect(journey.location, AppRoutes.parentHome);
    expect(backend.linkCalls, ['K7MP2QXA']);
    expect(find.text('Awa'), findsWidgets);
    expect(journey.pending.code, isNull);
  });

  testWidgets(
    'D · code → numéro de l’élève → proposition explicite, aucun espace élève',
    (tester) async {
      final backend = _Backend();
      final journey = await _Journey.start(tester, backend);

      await journey.enterParentCode('K7MP2QXA');
      await journey.verifyPhone(_studentPhone);

      expect(journey.location, AppRoutes.phoneAuth);
      expect(find.byKey(const ValueKey('family-phone-offer')), findsOneWidget);
      expect(
        find.text(
          'Ce numéro est actuellement utilisé pour l’accès d’un élève. '
          'Souhaitez-vous l’utiliser comme numéro du parent ? L’élève '
          'conservera son profil et utilisera désormais son code d’accès '
          'INTELLIA.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('family-phone-offer-confirm')),
        findsOneWidget,
      );
      expect(journey.pending.code, 'K7MP2QXA');
      // Rien n'est fait en silence : compte élève intact, rien de relié, aucun
      // espace ouvert. La session vérifiée attend la décision du parent.
      expect(backend.accountFor(_studentPhone)!.role, AppRole.student);
      expect(backend.signOuts, 0);
      expect(backend.linkCalls, isEmpty);
      expect(journey.auth.isAuthenticated, isFalse);
    },
  );

  testWidgets('E · après le conflit → autre numéro parent → enfant relié', (
    tester,
  ) async {
    final backend = _Backend();
    final journey = await _Journey.start(tester, backend);
    await journey.enterParentCode('K7MP2QXA');
    await journey.verifyPhone(_studentPhone);
    expect(find.byKey(const ValueKey('family-phone-offer')), findsOneWidget);

    await journey.tap('family-phone-offer-another-number');
    expect(backend.signOuts, 1);
    expect(find.byKey(const ValueKey('phone-entry-stage')), findsOneWidget);
    expect(journey.phoneFieldText, isEmpty);
    expect(
      find.byKey(const ValueKey('phone-pending-child-code')),
      findsOneWidget,
    );

    await journey.verifyPhone(_parentPhone);

    expect(journey.location, AppRoutes.parentHome);
    expect(backend.linkCalls, ['K7MP2QXA']);
    expect(find.text('Awa'), findsWidgets);
    expect(backend.accountFor(_studentPhone)!.role, AppRole.student);
  });

  testWidgets('annuler le conflit abandonne le parcours et le code', (
    tester,
  ) async {
    final backend = _Backend();
    final journey = await _Journey.start(tester, backend);
    await journey.enterParentCode('K7MP2QXA');
    await journey.verifyPhone(_studentPhone);

    await journey.tap('family-phone-offer-cancel');

    expect(journey.location, AppRoutes.authGateway);
    expect(journey.pending.code, isNull);
    expect(backend.currentUid, isNull);
  });

  testWidgets(
    'F · « Je suis déjà parent » → espace parent, enfants existants',
    (tester) async {
      final backend = _Backend();
      final journey = await _Journey.start(tester, backend);

      await journey.tap('gateway-role-parent');
      await journey.tap('parent-entry-existing');
      expect(
        find.byKey(const ValueKey('phone-pending-child-code')),
        findsNothing,
      );
      await journey.verifyPhone(_parentPhone);

      expect(journey.location, AppRoutes.parentHome);
      expect(find.text('Paul'), findsWidgets);
      expect(backend.linkCalls, isEmpty);
    },
  );

  testWidgets(
    'G · parent existant → Ajouter un enfant → code → enfant visible',
    (tester) async {
      final backend = _Backend();
      final journey = await _Journey.start(
        tester,
        backend,
        signedInPhone: _parentPhone,
      );
      expect(journey.location, AppRoutes.parentHome);

      await tester.tap(find.text('Enfants'));
      await journey.settle();
      await tester.tap(
        find.byKey(const ValueKey('parent-add-child')).hitTestable(),
      );
      await journey.settle();
      await tester.enterText(
        find.byKey(const ValueKey('parent-add-child-code')),
        'P3RT9WXY',
      );
      await tester.tap(find.byKey(const ValueKey('parent-add-child-submit')));
      await journey.settle();

      expect(backend.linkCalls, ['P3RT9WXY']);
      expect(find.text('Noah'), findsWidgets);
      expect(find.text('Paul'), findsWidgets);
    },
  );

  testWidgets('H · code mal formé : erreur locale, rien de retenu ni résolu', (
    tester,
  ) async {
    final backend = _Backend();
    final journey = await _Journey.start(tester, backend);
    await journey.tap('gateway-role-parent');

    for (final malformed in ['ABC', 'K7MP2QX0', 'K7MP2QXAB']) {
      await tester.enterText(
        find.byKey(const ValueKey('parent-entry-code-field')),
        malformed,
      );
      await journey.tap('parent-entry-continue');

      expect(journey.location, AppRoutes.parentEntry, reason: malformed);
      expect(
        find.text(
          'Un code enfant compte 8 lettres et chiffres. Vérifiez-le avec votre enfant.',
        ),
        findsOneWidget,
        reason: malformed,
      );
      expect(journey.pending.code, isNull);
    }
    expect(backend.linkCalls, isEmpty);
  });

  for (final (label, code) in const [
    ('code inconnu', 'ZZZZ2222'),
    ('I · code régénéré', 'H4NR8TBZ'),
  ]) {
    testWidgets('$label : même message, aucun enfant, rien de révélé', (
      tester,
    ) async {
      final backend = _Backend();
      final journey = await _Journey.start(tester, backend);

      await journey.enterParentCode(code);
      await journey.verifyPhone(_parentPhone);

      expect(journey.location, AppRoutes.parentHome);
      expect(
        find.byKey(const ValueKey('parent-child-link-report')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Ce code enfant est introuvable. Vérifie-le avec ton enfant.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('parent-child-link-add')),
        findsOneWidget,
      );
      expect(backend.childrenOf(_parentPhone), ['Paul']);
      expect(journey.pending.code, isNull);
    });
  }

  testWidgets('panne réseau : le code reste, « Réessayer » relie l’enfant', (
    tester,
  ) async {
    final backend = _Backend()..linkNetworkDown = true;
    final journey = await _Journey.start(tester, backend);

    await journey.enterParentCode('K7MP2QXA');
    await journey.verifyPhone(_parentPhone);

    expect(journey.location, AppRoutes.parentHome);
    expect(
      find.byKey(const ValueKey('parent-child-link-retry')),
      findsOneWidget,
    );
    expect(journey.pending.code, 'K7MP2QXA');

    backend.linkNetworkDown = false;
    await tester.tap(find.byKey(const ValueKey('parent-child-link-retry')));
    await journey.settle();

    expect(
      find.byKey(const ValueKey('parent-child-link-report')),
      findsNothing,
    );
    expect(find.text('Awa'), findsWidgets);
    expect(journey.pending.code, isNull);
  });

  testWidgets('J · plusieurs enfants : un existant, un relié par code', (
    tester,
  ) async {
    final backend = _Backend();
    final journey = await _Journey.start(tester, backend);

    await journey.enterParentCode('K7MP2QXA');
    await journey.verifyPhone(_parentPhone);

    expect(backend.childrenOf(_parentPhone), ['Paul', 'Awa']);
    expect(find.text('Paul'), findsWidgets);
    expect(find.text('Awa'), findsWidgets);
  });

  testWidgets(
    'nouveau parent : code → numéro inconnu → inscription → enfants visibles',
    (tester) async {
      final backend = _Backend();
      final journey = await _Journey.start(tester, backend);

      await journey.enterParentCode('K7MP2QXA');
      await journey.verifyPhone(_newParentPhone);

      expect(journey.location, AppRoutes.parentRegistration);
      expect(backend.accountFor(_newParentPhone), isNull);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Mireille');
      await tester.enterText(fields.at(1), 'Ekane');
      await journey.tap('registration-primary-action');

      // Le code saisi à l'entrée est déjà là : il n'est pas retapé.
      expect(find.widgetWithText(InputChip, 'K7MP2QXA'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('parent-child-identifier-field')),
          matching: find.byType(TextFormField),
        ),
        'P3RT9WXY',
      );
      await journey.tap('parent-add-child-action');
      expect(find.widgetWithText(InputChip, 'P3RT9WXY'), findsOneWidget);
      await journey.tap('registration-primary-action');

      await tester.tap(find.text('J’accepte les conditions d’utilisation.'));
      await tester.tap(find.text('J’accepte la politique de confidentialité.'));
      await journey.settle();
      await journey.tap('registration-primary-action');

      expect(journey.location, AppRoutes.parentHome);
      expect(backend.accountFor(_newParentPhone)!.role, AppRole.parent);
      expect(backend.childrenOf(_newParentPhone), ['Awa', 'Noah']);
      expect(find.text('Awa'), findsWidgets);
      expect(find.text('Noah'), findsWidgets);
      expect(backend.accountFor(_studentPhone)!.role, AppRole.student);
      expect(journey.pending.code, isNull);
    },
  );

  testWidgets('L · EN : entrée parent et conflit traduits', (tester) async {
    final backend = _Backend();
    final journey = await _Journey.start(
      tester,
      backend,
      locale: const Locale('en'),
    );

    await journey.tap('gateway-role-parent');
    expect(find.text('Child code'), findsOneWidget);
    expect(find.text('I already have a parent account'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('parent-entry-code-field')),
      'nope',
    );
    await journey.tap('parent-entry-continue');
    expect(
      find.text(
        'A child code has 8 letters and digits. Check it with your child.',
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('parent-entry-code-field')),
      'K7MP2QXA',
    );
    await journey.tap('parent-entry-continue');
    expect(
      find.text('Child code ready: it will be linked once you are signed in.'),
      findsOneWidget,
    );
    await journey.verifyPhone(_studentPhone);

    expect(
      find.text(
        'This number is currently used for a student’s access. Would you '
        'like to use it as the parent’s number? The student will keep their '
        'profile and will now use their INTELLIA access code.',
      ),
      findsOneWidget,
    );
    expect(find.text('Use this number for the parent'), findsOneWidget);
    expect(find.text('Use another number'), findsOneWidget);
  });

  testWidgets(
    'M · déconnexion : code et compte rendu effacés, espaces isolés',
    (tester) async {
      final backend = _Backend()..linkNetworkDown = true;
      final journey = await _Journey.start(tester, backend);
      await journey.enterParentCode('K7MP2QXA');
      await journey.verifyPhone(_parentPhone);
      expect(journey.pending.code, 'K7MP2QXA');
      expect(journey.pending.report, isNotNull);

      await journey.signOut();

      expect(journey.location, AppRoutes.authGateway);
      expect(journey.pending.code, isNull);
      expect(journey.pending.report, isNull);

      await journey.tap('gateway-role-student');
      await journey.verifyPhone(_studentPhone);
      expect(journey.location, AppRoutes.studentHome);
      expect(journey.auth.role, AppRole.student);
      expect(journey.pending.code, isNull);
    },
  );

  testWidgets(
    'M · une proposition non tranchée ne laisse aucune session à rouvrir au '
    'démarrage',
    (tester) async {
      final backend = _Backend();
      final journey = await _Journey.start(tester, backend);
      await journey.enterParentCode('K7MP2QXA');
      await journey.verifyPhone(_studentPhone);
      expect(find.byKey(const ValueKey('family-phone-offer')), findsOneWidget);
      final preferences = await SharedPreferences.getInstance();
      final pending = preferences.getString('auth_family_phone_offer_uid_v1');
      expect(pending, 'student-uid');
      final verifiedSession = backend.currentUid;
      await tester.pumpWidget(const SizedBox.shrink());
      // L'application est tuée pendant la décision : rien de ce qui suit
      // n'a pu s'exécuter, la session Firebase de l'élève est encore là.
      await preferences.setString('auth_family_phone_offer_uid_v1', pending!);
      backend.currentUid = verifiedSession;

      // Redémarrage de l'application sur le même appareil.
      final relaunch = await _Journey.start(tester, backend);

      expect(relaunch.auth.status, AuthStatus.unauthenticated);
      expect(relaunch.location, AppRoutes.authGateway);
    },
  );

  testWidgets(
    'rôle illisible après l’OTP : rien ne s’ouvre, « Réessayer » sans nouveau SMS',
    (tester) async {
      final backend = _Backend();
      final journey = await _Journey.start(tester, backend);
      // Le démarrage a déjà lu la session ; c'est la lecture après l'OTP qui
      // échoue.
      backend.failNextResolutions = 1;

      await journey.enterParentCode('K7MP2QXA');
      await journey.verifyPhone(_parentPhone);

      expect(journey.location, AppRoutes.phoneAuth);
      expect(
        find.byKey(const ValueKey('phone-entry-unresolved')),
        findsOneWidget,
      );
      expect(journey.auth.isAuthenticated, isFalse);
      expect(backend.currentUid, isNotNull, reason: 'session gardée');
      expect(journey.pending.code, 'K7MP2QXA');
      expect(backend.linkCalls, isEmpty);

      await journey.tap('phone-entry-retry');

      expect(journey.location, AppRoutes.parentHome);
      expect(backend.otpConfirmations, 1, reason: 'aucun nouveau code SMS');
      expect(find.text('Awa'), findsWidgets);
      expect(journey.pending.code, isNull);
    },
  );

  testWidgets(
    'rôle illisible puis « Annuler » : session refermée, code abandonné',
    (tester) async {
      final backend = _Backend();
      final journey = await _Journey.start(tester, backend);
      backend.failNextResolutions = 1;

      await journey.enterParentCode('K7MP2QXA');
      await journey.verifyPhone(_studentPhone);
      expect(
        find.byKey(const ValueKey('phone-entry-unresolved')),
        findsOneWidget,
      );

      await journey.tap('phone-entry-cancel');

      expect(journey.location, AppRoutes.authGateway);
      expect(backend.currentUid, isNull);
      expect(journey.pending.code, isNull);
      expect(backend.accountFor(_studentPhone)!.role, AppRole.student);
    },
  );

  testWidgets('retour arrière depuis l’entrée parent : le code est abandonné', (
    tester,
  ) async {
    final backend = _Backend();
    final journey = await _Journey.start(tester, backend);
    await journey.enterParentCode('K7MP2QXA');
    expect(journey.pending.code, 'K7MP2QXA');

    // Retour du téléphone vers l'entrée : le code est toujours là.
    journey.router.pop();
    await journey.settle();
    expect(journey.location, AppRoutes.parentEntry);
    expect(journey.codeFieldText, 'K7MP2QXA');
    expect(journey.pending.code, 'K7MP2QXA');

    // Quitter l'entrée parent, c'est abandonner le parcours.
    journey.router.pop();
    await journey.settle();
    expect(journey.location, AppRoutes.authGateway);
    expect(journey.pending.code, isNull);
  });
}

const _studentPhone = '699000001';
const _parentPhone = '677000002';
const _newParentPhone = '655000003';

void _mockClipboard(WidgetTester tester, String text) {
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.getData') {
      return <String, Object?>{'text': text};
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
}

class _Journey {
  _Journey(this.tester, this.container, this.router);

  final WidgetTester tester;
  final ProviderContainer container;
  final GoRouter router;

  static Future<_Journey> start(
    WidgetTester tester,
    _Backend backend, {
    String? signedInPhone,
    Locale locale = const Locale('fr'),
  }) async {
    // Un téléphone Android courant, avec les polices réellement livrées.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (signedInPhone != null) backend.signInWithPhone(signedInPhone);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_AuthRepository(backend)),
        phoneAuthRepositoryProvider.overrideWithValue(
          _PhoneRepository(backend),
        ),
        childLinkServiceProvider.overrideWithValue(_LinkService(backend)),
        parentRepositoryProvider.overrideWithValue(_ParentRepository(backend)),
        roleRegistrationRepositoryProvider.overrideWithValue(
          _RegistrationRepository(backend),
        ),
        unreadNotificationCountProvider.overrideWithValue(0),
        tourGuideRepositoryProvider.overrideWithValue(_SeenTour()),
        hasSeenOnboardingProvider.overrideWith((ref) => true),
        hasAuthenticatedBeforeProvider.overrideWith((ref) => true),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).completeBootstrap();

    final refresh = ValueNotifier<int>(0);
    addTearDown(refresh.dispose);
    container.listen<AuthState>(
      authControllerProvider,
      (_, _) => refresh.value++,
    );
    Widget stub(String path) => Scaffold(body: Center(child: Text(path)));
    final router = GoRouter(
      initialLocation: AppRoutes.bootstrap,
      refreshListenable: refresh,
      redirect: (context, state) => resolveAppRedirect(
        auth: container.read(authControllerProvider),
        hasSeenOnboarding: true,
        hasAuthenticatedBefore: true,
        location: state.uri.path,
      ),
      routes: [
        GoRoute(
          path: AppRoutes.authGateway,
          builder: (_, _) => const AuthGatewayScreen(),
        ),
        GoRoute(
          path: AppRoutes.parentEntry,
          builder: (_, _) => const ParentEntryScreen(),
        ),
        GoRoute(
          path: AppRoutes.phoneAuth,
          builder: (_, state) =>
              PhoneAuthScreen(authIntent: AppRoutes.entryIntentFrom(state.uri)),
        ),
        GoRoute(
          path: AppRoutes.parentRegistration,
          builder: (_, _) => const ParentRegistrationScreen(),
        ),
        GoRoute(
          path: AppRoutes.parentHome,
          builder: (_, _) => const ParentHomeScreen(),
        ),
        for (final path in [
          AppRoutes.bootstrap,
          AppRoutes.login,
          AppRoutes.emailLogin,
          AppRoutes.register,
          AppRoutes.studentRegistration,
          AppRoutes.studentHome,
          AppRoutes.teacherHome,
          AppRoutes.adminHome,
          AppRoutes.authProfileRecovery,
        ])
          GoRoute(path: path, builder: (_, _) => stub(path)),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );
    final journey = _Journey(tester, container, router);
    await journey.settle();
    return journey;
  }

  /// Écran au sommet de la pile, route poussée comprise.
  String get location => router.state.uri.path;
  AuthState get auth => container.read(authControllerProvider);
  PendingChildLink get pending => container.read(pendingChildLinkProvider);

  String get codeFieldText => tester
      .widget<TextField>(find.byKey(const ValueKey('parent-entry-code-field')))
      .controller!
      .text;

  String get phoneFieldText => tester
      .widget<TextFormField>(find.byKey(const ValueKey('phone-number-field')))
      .controller!
      .text;

  /// Laisse passer l'anti-rebond des boutons, puis stabilise l'écran.
  ///
  /// Device QA round 3 : un espace s'ouvre après que le Pass a montré son
  /// sceau complet (`PassSealTiming.completionHold`).
  Future<void> settle() async {
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    await tester.pump(PassSealTiming.completionHold);
    await tester.pumpAndSettle();
  }

  Future<void> tap(String key) async {
    if (key == 'gateway-role-student' &&
        find
            .byKey(const ValueKey('gateway-phone-auth'))
            .evaluate()
            .isNotEmpty) {
      router.push(AppRoutes.phoneRegistration(AppRole.student));
      await settle();
      return;
    }
    if (key == 'gateway-role-parent' &&
        find
            .byKey(const ValueKey('gateway-phone-auth'))
            .evaluate()
            .isNotEmpty) {
      router.push(AppRoutes.parentEntry);
      await settle();
      return;
    }
    final target = find.byKey(ValueKey(key));
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    await settle();
  }

  Future<void> enterParentCode(String code) async {
    await tap('gateway-role-parent');
    await tester.enterText(
      find.byKey(const ValueKey('parent-entry-code-field')),
      code,
    );
    await tap('parent-entry-continue');
  }

  Future<void> verifyPhone(String localNumber) async {
    await tester.enterText(
      find.byKey(const ValueKey('phone-number-field')),
      localNumber,
    );
    await tap('send-phone-code');
    await tester.enterText(
      find.byKey(const ValueKey('phone-otp-field')),
      '123456',
    );
    await settle();
  }

  Future<void> signOut() async {
    await container.read(authControllerProvider.notifier).signOut();
    await settle();
  }
}

class _Account {
  _Account({required this.uid, required this.role, required this.firstName});

  final String uid;
  AppRole role;
  String firstName;
}

/// Services distants simulés : identités par numéro, profils, liaisons.
class _Backend {
  _Backend() {
    _createAccount(_studentPhone, 'student-uid', AppRole.student, 'Awa');
    _createAccount(_parentPhone, 'parent-uid', AppRole.parent, 'Claire');
    links['parent-uid'] = ['Paul'];
  }

  final uidsByPhone = <String, String>{};
  final accounts = <String, _Account>{};
  final links = <String, List<String>>{};
  final linkCalls = <String>[];
  String? currentUid;
  int signOuts = 0;
  int otpConfirmations = 0;
  bool linkNetworkDown = false;

  /// Lectures de profil qui échouent (réseau) avant de réussir.
  int failNextResolutions = 0;

  /// Codes actifs. `H4NR8TBZ` est l'ancien code d'Awa, régénéré depuis.
  static const codes = {'K7MP2QXA': 'Awa', 'P3RT9WXY': 'Noah'};

  void _createAccount(String phone, String uid, AppRole role, String name) {
    uidsByPhone['+237$phone'] = uid;
    accounts[uid] = _Account(uid: uid, role: role, firstName: name);
  }

  void signInWithPhone(String e164OrLocal) {
    final key = e164OrLocal.startsWith('+') ? e164OrLocal : '+237$e164OrLocal';
    currentUid = uidsByPhone.putIfAbsent(key, () => 'uid-$key');
  }

  _Account? accountFor(String localPhone) =>
      accounts[uidsByPhone['+237$localPhone']];

  List<String> childrenOf(String localPhone) =>
      links[uidsByPhone['+237$localPhone']] ?? const [];
}

class _PhoneRepository implements PhoneAuthRepository {
  _PhoneRepository(this.backend);
  final _Backend backend;

  @override
  Future<void> startVerification({
    required String phoneNumber,
    required bool linkCurrentUser,
    int? forceResendingToken,
    required void Function(PhoneAuthSession) onVerified,
    required void Function(PhoneAuthFailure) onFailed,
    required void Function(PhoneCodeDispatch) onCodeSent,
    required void Function(String) onAutoRetrievalTimeout,
  }) async => onCodeSent(PhoneCodeDispatch(verificationId: phoneNumber));

  @override
  Future<PhoneAuthSession> confirmCode({
    required String verificationId,
    required String smsCode,
    required bool linkCurrentUser,
  }) async {
    backend.otpConfirmations++;
    backend.signInWithPhone(verificationId);
    return PhoneAuthSession(
      uid: backend.currentUid!,
      phoneNumber: verificationId,
      isNewUser: backend.accounts[backend.currentUid] == null,
      linkedToExistingUser: false,
    );
  }
}

class _AuthRepository implements AuthRepository, AuthSessionResolver {
  _AuthRepository(this.backend);
  final _Backend backend;

  AuthUserData? get _user {
    final account = backend.accounts[backend.currentUid];
    if (account == null) return null;
    return AuthUserData(
      uid: account.uid,
      email: '',
      role: account.role,
      firstName: account.firstName,
      lastName: '',
      profileCompleted: true,
    );
  }

  @override
  Future<AuthSessionResolution> resolveCurrentSession() async {
    if (backend.failNextResolutions > 0) {
      backend.failNextResolutions--;
      throw Exception('profile read failed');
    }
    final uid = backend.currentUid;
    if (uid == null) {
      return const AuthSessionResolution(
        kind: AuthSessionResolutionKind.unauthenticated,
      );
    }
    final user = _user;
    return AuthSessionResolution(
      kind: user == null
          ? AuthSessionResolutionKind.needsOnboarding
          : AuthSessionResolutionKind.authenticated,
      firebaseUid: uid,
      firebaseEmail: '',
      user: user,
    );
  }

  @override
  Future<AuthUserData?> getCurrentUser() async => _user;

  @override
  Future<void> signOut() async {
    backend.signOuts++;
    backend.currentUid = null;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AuthUserData> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AuthUserData> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required AppRole role,
  }) => throw UnimplementedError();
}

class _LinkService extends ChildLinkService {
  _LinkService(this.backend);
  final _Backend backend;

  @override
  Future<ChildLinkResult> linkChildByCode(String code) async {
    backend.linkCalls.add(code);
    final uid = backend.currentUid;
    if (uid == null) throw const ChildLinkException('unauthenticated');
    // Le serveur exige un compte parent : jamais un élève.
    if (backend.accounts[uid]?.role != AppRole.parent) {
      throw const ChildLinkException('permission-denied');
    }
    if (backend.linkNetworkDown) throw const ChildLinkException('unavailable');
    final child = _Backend.codes[code];
    if (child == null) throw const ChildLinkException('not-found');
    final children = backend.links.putIfAbsent(uid, () => []);
    final already = children.contains(child);
    if (!already) children.add(child);
    return ChildLinkResult(
      studentId: 'student-$child',
      firstName: child,
      classLevel: '3eme',
      alreadyLinked: already,
    );
  }
}

class _ParentRepository implements ParentRepository {
  _ParentRepository(this.backend);
  final _Backend backend;

  @override
  Future<ParentDashboard> fetchDashboard({required String parentUid}) async =>
      ParentDashboard(
        children: [
          for (final name in backend.links[parentUid] ?? const <String>[])
            ParentChildProfile(
              id: 'student-$name',
              firstName: name,
              classLevel: '3eme',
              series: null,
              globalProgress: 0,
              studyMinutesToday: 0,
              studyMinutesTarget: 45,
              strongSubjects: const [],
              weakSubjects: const [],
              weeklyProgress: const [],
            ),
        ],
        announcements: const [],
      );
}

class _RegistrationRepository implements RoleRegistrationRepository {
  _RegistrationRepository(this.backend);
  final _Backend backend;

  @override
  Future<RoleRegistrationResult> registerParent(
    ParentRegistrationPayload payload,
  ) async {
    final uid = backend.currentUid!;
    // Les règles Firestore refusent tout changement de rôle d'un compte.
    if (backend.accounts.containsKey(uid)) {
      throw StateError('an existing account role must never be rewritten');
    }
    backend.accounts[uid] = _Account(
      uid: uid,
      role: AppRole.parent,
      firstName: payload.firstName,
    );
    return RoleRegistrationResult(
      uid: uid,
      email: '',
      firstName: payload.firstName,
      lastName: payload.lastName,
    );
  }

  @override
  Future<RoleRegistrationResult> registerTeacher(
    TeacherRegistrationPayload payload,
  ) => throw UnimplementedError();

  @override
  Future<RoleRegistrationResult> registerAdmin(
    AdminRegistrationPayload payload,
  ) => throw UnimplementedError();
}

class _SeenTour implements TourGuideRepository {
  @override
  Future<bool> hasSeenTour(String uid) async => true;

  @override
  Future<void> markTourSeen(String uid) async {}
}
