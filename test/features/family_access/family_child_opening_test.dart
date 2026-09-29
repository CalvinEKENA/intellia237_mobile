import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/application/google_access_coordinator.dart';
import 'package:intellia237/features/auth/data/services/firebase_identity_port.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/family_access/application/family_access_providers.dart';
import 'package:intellia237/features/family_access/data/family_access_repository.dart';
import 'package:intellia237/features/family_access/domain/family_access_models.dart';
import 'package:intellia237/features/family_access/domain/family_access_outcomes.dart';
import 'package:intellia237/features/family_access/presentation/family_entry_screen.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/intellia_fonts.dart';

void main() {
  setUpAll(loadIntelliaFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ouverture de la session enfant', () {
    test('voie directe : le jeton du serveur, aucun code émis', () async {
      final calls = <String>[];
      await openLinkedChildSession(
        'kid',
        direct: () async => 'direct-token',
        issueCode: (id) async {
          calls.add('issue:$id');
          return const IssuedStudentAccessCode(code: 'ABCD-EFGH-JKMN');
        },
        signInWithCode: (code) async => calls.add('code:$code'),
        signInWithToken: (token) async => calls.add('token:$token'),
      );
      expect(calls, ['token:direct-token']);
    });

    for (final missing in ['not-found', 'unimplemented']) {
      test('service absent ($missing) : code émis pour cet enfant, puis '
          'session ouverte par ce code', () async {
        final calls = <String>[];
        await openLinkedChildSession(
          'kid',
          direct: () async => throw FamilyAccessException(missing),
          issueCode: (id) async {
            calls.add('issue:$id');
            return const IssuedStudentAccessCode(code: 'ABCD-EFGH-JKMN');
          },
          signInWithCode: (code) async => calls.add('code:$code'),
          signInWithToken: (token) async => calls.add('token:$token'),
        );
        expect(calls, ['issue:kid', 'code:ABCD-EFGH-JKMN']);
      });
    }

    for (final refusal in [
      'permission-denied',
      'failed-precondition',
      'unavailable',
      'internal',
    ]) {
      test('refus du serveur ($refusal) : transmis, aucun code émis', () async {
        final calls = <String>[];
        await expectLater(
          openLinkedChildSession(
            'kid',
            direct: () async => throw FamilyAccessException(refusal),
            issueCode: (id) async {
              calls.add('issue:$id');
              return const IssuedStudentAccessCode(code: 'ABCD-EFGH-JKMN');
            },
            signInWithCode: (code) async => calls.add('code:$code'),
            signInWithToken: (token) async => calls.add('token:$token'),
          ),
          throwsA(
            isA<FamilyAccessException>().having((e) => e.code, 'code', refusal),
          ),
        );
        expect(calls, isEmpty);
      });
    }
  });

  group('choix de l’enfant', () {
    test('preuve du numéro trop ancienne : le confirmer de nouveau, '
        'jamais un simple « réessayez »', () async {
      final session = _Session(uid: 'parent', user: _parent);
      final container = _container(
        session,
        _Family(
          session,
          failure: const FamilyAccessException('failed-precondition'),
        ),
      );
      final controller = container.read(authControllerProvider.notifier);
      await controller.adoptSessionForIntent(
        null,
        confirmSharedStudentPhone: true,
      );
      expect(container.read(authControllerProvider).familyEntryPending, isTrue);

      expect(await controller.openFamilyChild('kid'), isFalse);
      final state = container.read(authControllerProvider);
      expect(state.error, AuthController.familyAccessVerifyAgain);
      // La session du parent reste close derrière le choix : aucune page
      // parent ne s'ouvre.
      expect(state.familyEntryPending, isTrue);
      expect(_redirect(state, AppRoutes.parentHome), AppRoutes.familySelection);
    });

    test('autre refus : message d’indisponibilité', () async {
      final session = _Session(uid: 'parent', user: _parent);
      final container = _container(
        session,
        _Family(session, failure: const FamilyAccessException('unavailable')),
      );
      final controller = container.read(authControllerProvider.notifier);
      await controller.adoptSessionForIntent(
        null,
        confirmSharedStudentPhone: true,
      );
      expect(await controller.openFamilyChild('kid'), isFalse);
      expect(
        container.read(authControllerProvider).error,
        AuthController.familyAccessUnavailable,
      );
    });

    test('enfant existant : son espace élève s’ouvre', () async {
      final session = _Session(uid: 'parent', user: _parent);
      final container = _container(
        session,
        _Family(session, childProfile: _student('kid')),
      );
      final controller = container.read(authControllerProvider.notifier);
      await controller.adoptSessionForIntent(
        null,
        confirmSharedStudentPhone: true,
      );
      expect(await controller.openFamilyChild('kid'), isTrue);
      final state = container.read(authControllerProvider);
      expect(state.userId, 'kid');
      expect(state.role, AppRole.student);
      expect(
        _redirect(state, AppRoutes.familySelection),
        AppRoutes.studentHome,
      );
    });

    test('enfant dont le parent a ouvert l’accès, profil pas encore rempli : '
        'inscription élève directe, jamais le choix d’objectif', () async {
      final session = _Session(uid: 'parent', user: _parent);
      final container = _container(session, _Family(session));
      final controller = container.read(authControllerProvider.notifier);
      await controller.adoptSessionForIntent(
        null,
        confirmSharedStudentPhone: true,
      );
      expect(await controller.openFamilyChild('kid'), isTrue);
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.needsOnboarding);
      expect(state.userId, 'kid');
      expect(state.role, AppRole.student);
      expect(state.familyEntryPending, isFalse);
      expect(
        _redirect(state, AppRoutes.familySelection),
        AppRoutes.studentRegistration,
      );
    });

    test('code d’accès d’un enfant au profil pas encore rempli : '
        'inscription élève directe', () async {
      final session = _Session();
      final container = _container(session, _Family(session));
      final outcome = await container
          .read(authControllerProvider.notifier)
          .signInWithStudentAccessCode('ABCD-EFGH-JKMN');
      expect(outcome, isA<StudentAccessCodeAdopted>());
      final state = container.read(authControllerProvider);
      expect(state.role, AppRole.student);
      expect(
        _redirect(state, AppRoutes.accountWelcome),
        AppRoutes.studentRegistration,
      );
    });
  });

  testWidgets('écran : la preuve trop ancienne propose de confirmer le numéro, '
      'qui ferme la session du parent', (tester) async {
    final session = _Session(uid: 'parent', user: _parent);
    final container = _container(
      session,
      _Family(
        session,
        failure: const FamilyAccessException('failed-precondition'),
      ),
    );
    await container
        .read(authControllerProvider.notifier)
        .adoptSessionForIntent(null, confirmSharedStudentPhone: true);
    final router = GoRouter(
      initialLocation: AppRoutes.familySelection,
      routes: [
        GoRoute(
          path: AppRoutes.familySelection,
          builder: (_, _) => const FamilyEntryScreen(),
        ),
        GoRoute(
          path: AppRoutes.phoneAuth,
          builder: (_, _) => const Text('téléphone'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('fr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    // Un seul enfant : son ouverture est tentée d'elle-même.
    await _settle(tester);
    expect(
      find.text(
        'Pour protéger l’espace de l’enfant, confirmez de nouveau votre '
        'numéro.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Impossible d’ouvrir cet espace pour le moment. '
        'Réessayez ou reconnectez-vous.',
      ),
      findsNothing,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('family-verify-again')),
    );
    await tester.tap(find.byKey(const ValueKey('family-verify-again')));
    await _settle(tester);
    expect(session.uid, isNull);
    expect(container.read(authControllerProvider).hasFirebaseSession, isFalse);
    expect(find.text('téléphone'), findsOneWidget);
  });
}

const _parent = AuthUserData(
  uid: 'parent',
  email: 'famille@example.com',
  role: AppRole.parent,
  firstName: 'Awa',
  lastName: 'Test',
  profileCompleted: true,
);

AuthUserData _student(String uid) => AuthUserData(
  uid: uid,
  email: '',
  role: AppRole.student,
  firstName: 'Nina',
  lastName: 'Test',
  profileCompleted: true,
);

ProviderContainer _container(_Session session, _Family family) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(session),
      familyAccessRepositoryProvider.overrideWithValue(family),
      firebaseIdentityPortProvider.overrideWithValue(_Identity(session)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

String? _redirect(AuthState auth, String location) => resolveAppRedirect(
  auth: auth,
  hasSeenOnboarding: true,
  hasAuthenticatedBefore: true,
  location: location,
);

/// Session de l'appareil : une identité, avec ou sans profil.
class _Session implements AuthRepository, AuthSessionResolver {
  _Session({this.uid, this.user});

  String? uid;
  AuthUserData? user;

  @override
  Future<AuthSessionResolution> resolveCurrentSession() async =>
      AuthSessionResolution(
        kind: uid == null
            ? AuthSessionResolutionKind.unauthenticated
            : user == null
            ? AuthSessionResolutionKind.needsOnboarding
            : AuthSessionResolutionKind.authenticated,
        firebaseUid: uid,
        user: user,
      );

  @override
  Future<AuthUserData?> getCurrentUser() async => user;

  @override
  Future<void> signOut() async {
    uid = null;
    user = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Serveur famille : ouvre la session de l'enfant, ou refuse.
class _Family implements FamilyAccessRepository, FamilyChildSessionRepository {
  _Family(this.session, {this.failure, this.childProfile});

  final _Session session;
  final FamilyAccessException? failure;

  /// Profil de l'enfant ; `null` : accès ouvert, profil pas encore rempli.
  final AuthUserData? childProfile;

  @override
  Future<List<ParentChildSummary>> listParentChildren({
    String? parentUid,
  }) async => const [
    ParentChildSummary(
      studentId: 'kid',
      firstName: 'Nina',
      lastName: 'Test',
      classLevel: 'Terminale',
      series: 'D',
      establishmentId: '',
      establishmentName: '',
      access: ChildAccessMethods.unknown,
      subscription: ChildSubscription.inactive,
      offerAvailable: false,
    ),
  ];

  @override
  Future<void> signInAsLinkedChild(String studentId) async {
    if (failure case final error?) throw error;
    session
      ..uid = studentId
      ..user = childProfile;
  }

  @override
  Future<void> signInWithStudentAccessCode(String code) async {
    session
      ..uid = 'kid'
      ..user = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Identity implements FirebaseIdentityPort {
  _Identity(this.session);

  final _Session session;

  @override
  String? get currentUid => session.uid;

  @override
  Stream<String?> uidChanges() => const Stream<String?>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Le Pass reste vivant : avancer le temps sans attendre son repos.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
