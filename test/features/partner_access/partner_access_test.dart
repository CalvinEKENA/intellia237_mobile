import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/router/app_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/application/google_access_coordinator.dart';
import 'package:intellia237/features/auth/data/services/firebase_identity_port.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/auth_entry_intent.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/auth/presentation/login_screen.dart';
import 'package:intellia237/features/auth/presentation/widgets/auth_controls.dart';
import 'package:intellia237/features/auth/presentation/widgets/pass_auth_progress.dart';
import 'package:intellia237/features/auth/presentation/widgets/intellia_237_membrane.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/demo_access/application/demo_access_providers.dart';
import 'package:intellia237/features/demo_access/domain/demo_access.dart';
import 'package:intellia237/features/partner_access/data/partner_access_repository.dart';
import 'package:intellia237/features/partner_access/domain/partner_access.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/intellia_fonts.dart';
import '../content_engine/pack_fixture.dart';

/// Accès partenaire : le compte de test « démo pour Francis », ouvert par son
/// adresse exacte, sans mot de passe. Décision assumée du propriétaire
/// (29/09/2026). Ces tests prouvent que le comportement spécial est limité à
/// cette adresse, que l'application n'accorde aucun privilège localement, et
/// que la session ouvre bien un élève de Terminale D.

const _partnerEmail = 'fran6farmer@yahoo.fr';

const _partnerUser = AuthUserData(
  uid: PartnerAccess.uid,
  email: _partnerEmail,
  role: AppRole.student,
  firstName: 'Francis',
  lastName: 'Partenaire',
  profileCompleted: true,
);

const _otherUser = AuthUserData(
  uid: 'student-42',
  email: 'student@example.com',
  role: AppRole.student,
  firstName: 'Amina',
  lastName: 'Ndi',
  profileCompleted: true,
);

void main() {
  setUpAll(loadIntelliaFonts);
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  group('reconnaissance de l’adresse', () {
    test('l’adresse exacte est reconnue', () {
      expect(PartnerAccess.recognizes('fran6farmer@yahoo.fr'), isTrue);
      expect(PartnerAccess.canonicalEmail, 'fran6farmer@yahoo.fr');
    });

    test('la casse est ignorée', () {
      expect(PartnerAccess.recognizes('FRAN6FARMER@YAHOO.FR'), isTrue);
      expect(PartnerAccess.recognizes('Fran6Farmer@Yahoo.fr'), isTrue);
    });

    test('les espaces autour sont ignorés', () {
      expect(PartnerAccess.recognizes(' fran6farmer@yahoo.fr '), isTrue);
      expect(PartnerAccess.recognizes('\tfran6farmer@yahoo.fr\n'), isTrue);
      expect(
        PartnerAccess.normalize('  FRAN6FARMER@YAHOO.FR  '),
        'fran6farmer@yahoo.fr',
      );
    });

    test('un autre domaine n’est pas reconnu', () {
      expect(PartnerAccess.recognizes('fran6farmer@yahoo.com'), isFalse);
      expect(PartnerAccess.recognizes('fran6farmer@gmail.com'), isFalse);
    });

    test('un autre identifiant n’est pas reconnu', () {
      expect(PartnerAccess.recognizes('fran6farmer2@yahoo.fr'), isFalse);
      expect(PartnerAccess.recognizes('xfran6farmer@yahoo.fr'), isFalse);
      expect(PartnerAccess.recognizes('fran6farme@yahoo.fr'), isFalse);
    });

    test('ni préfixe, ni suffixe, ni espace intérieur, ni vide', () {
      for (final raw in [
        'fran6farmer@yahoo.fr.evil.example',
        'fran6farmer@@yahoo.fr',
        'fran6 farmer@yahoo.fr',
        'fran6farmer@yahoo.fr,other@x.fr',
        'fran6farmer',
        '@yahoo.fr',
        '',
        '   ',
      ]) {
        expect(PartnerAccess.recognizes(raw), isFalse, reason: raw);
      }
    });

    test('le mot de passe est écarté du sceau : « 3 » est acquis', () {
      expect(
        PassAuthProgress.emailSignIn(
          email: _partnerEmail,
          password: '',
          accessOpened: false,
          passwordWaived: true,
        ),
        PassSealStage.secret,
      );
      expect(
        PassAuthProgress.emailSignIn(
          email: 'other@example.com',
          password: '',
          accessOpened: false,
        ),
        PassSealStage.identifier,
        reason: 'un autre compte garde la règle du mot de passe',
      );
    });
  });

  group('session du compte partenaire', () {
    test('l’adresse exacte ouvre une session élève réelle, même UID', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      final adoption = await harness.controller.signInWithPartnerAccess(
        '  FRAN6FARMER@YAHOO.FR ',
      );
      expect(adoption, isA<AuthEntryAdopted>());
      final auth = harness.container.read(authControllerProvider);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.role, AppRole.student);
      expect(auth.userId, PartnerAccess.uid);
      expect(harness.partner.calls, [_partnerEmail]);
      expect(harness.repo.emailSignIns, 0, reason: 'aucun mot de passe');
    });

    test('chaque connexion réutilise le même compte', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      await harness.controller.signInWithPartnerAccess(_partnerEmail);
      await harness.controller.signOut();
      await harness.controller.signInWithPartnerAccess('FRAN6FARMER@yahoo.fr');
      expect(
        harness.container.read(authControllerProvider).userId,
        PartnerAccess.uid,
      );
      expect(harness.partner.calls, hasLength(2));
      expect(harness.partner.uids, {PartnerAccess.uid});
    });

    test('toute autre adresse : rien n’est envoyé, rien ne s’ouvre', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      for (final other in [
        'fran6farmer@yahoo.com',
        'fran6farmer2@yahoo.fr',
        'student@example.com',
        '',
      ]) {
        final adoption = await harness.controller.signInWithPartnerAccess(
          other,
        );
        expect(adoption, isA<AuthEntryUnresolved>(), reason: other);
      }
      expect(harness.partner.calls, isEmpty);
      expect(
        harness.container.read(authControllerProvider).isAuthenticated,
        isFalse,
      );
    });

    test(
      'échec du serveur : aucune session, un message, aucun blocage',
      () async {
        final harness = _Harness()..partner.fail = true;
        addTearDown(harness.dispose);
        final adoption = await harness.controller.signInWithPartnerAccess(
          _partnerEmail,
        );
        expect(
          adoption,
          isA<AuthEntryUnresolved>().having(
            (result) => result.errorCode,
            'errorCode',
            AuthController.partnerAccessUnavailable,
          ),
        );
        final auth = harness.container.read(authControllerProvider);
        expect(auth.isAuthenticated, isFalse);
        expect(auth.isLoading, isFalse);
        expect(auth.error, AuthController.partnerAccessUnavailable);
      },
    );

    test(
      'session restaurée : l’accès est conservé, sans nouvelle saisie',
      () async {
        final first = _Harness();
        await first.controller.signInWithPartnerAccess(_partnerEmail);
        expect(
          first.container.read(authControllerProvider).isAuthenticated,
          isTrue,
        );
        first.dispose();

        // Nouveau démarrage : Firebase a gardé la session du même UID.
        final restored = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _Repo()..current = _partnerUser,
            ),
            firebaseIdentityPortProvider.overrideWithValue(
              _Identity(PartnerAccess.uid),
            ),
          ],
        );
        addTearDown(restored.dispose);
        final controller = restored.read(authControllerProvider.notifier);
        expect(controller.hasRestorableSession, isTrue);
        await controller.completeBootstrap();
        final auth = restored.read(authControllerProvider);
        expect(auth.status, AuthStatus.authenticated);
        expect(auth.role, AppRole.student);
        expect(auth.userId, PartnerAccess.uid);
        // La lecture en ligne qui confirme l'espace finit avant la libération.
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(
          restored.read(authControllerProvider).userId,
          PartnerAccess.uid,
          reason: 'confirmé en ligne : toujours le même compte',
        );
      },
    );

    test('la progression reste celle du même UID', () async {
      const store = LocalLearnerContentStore();
      final snapshot = await store.load(PartnerAccess.uid);
      await store.save(PartnerAccess.uid, snapshot);
      final harness = _Harness();
      addTearDown(harness.dispose);
      await harness.controller.signInWithPartnerAccess(_partnerEmail);
      await harness.controller.signOut();
      await harness.controller.signInWithPartnerAccess(_partnerEmail);
      final uid = harness.container.read(authControllerProvider).userId!;
      expect(uid, PartnerAccess.uid);
      expect(LocalLearnerContentStore.keyFor(uid), contains(PartnerAccess.uid));
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.containsKey(LocalLearnerContentStore.keyFor(PartnerAccess.uid)),
        isTrue,
        reason:
            'la progression est rangée sous l’UID canonique, jamais un '
            'nouvel utilisateur',
      );
    });
  });

  group('aucun droit accordé aux autres', () {
    test('un autre élève n’est pas le compte partenaire', () async {
      final harness = _Harness()..repo.current = _otherUser;
      addTearDown(harness.dispose);
      await harness.controller.signInWithEmail(
        email: 'student@example.com',
        password: 'Motdepasse1!',
      );
      final container = harness.container;
      expect(container.read(authControllerProvider).userId, 'student-42');
      expect(container.read(isDemoAccessProvider), isFalse);
      expect(harness.partner.calls, isEmpty);
    });

    test(
      'le compte partenaire, comme le compte démo, est un compte de test',
      () async {
        final harness = _Harness();
        addTearDown(harness.dispose);
        await harness.controller.signInWithPartnerAccess(_partnerEmail);
        expect(harness.container.read(isDemoAccessProvider), isTrue);
      },
    );

    test(
      'l’adresse ne donne aucun privilège local : le rôle vient du serveur',
      () async {
        // Le serveur répond avec un profil élève ordinaire ; rien n'est ajouté
        // par l'application.
        final harness = _Harness();
        addTearDown(harness.dispose);
        await harness.controller.signInWithPartnerAccess(_partnerEmail);
        final auth = harness.container.read(authControllerProvider);
        expect(auth.role, AppRole.student);
        expect(auth.isSuperAdmin, isFalse);
        expect(AppRoutes.roleHomes, contains(AppRoutes.studentHome));
        // Aucune route d'administration ni de personnel n'est ouverte.
        for (final route in [AppRoutes.adminHome, AppRoutes.teacherHome]) {
          expect(
            resolveAppRedirect(
              auth: auth,
              hasSeenOnboarding: true,
              hasAuthenticatedBefore: true,
              location: route,
            ),
            isNot(isNull),
            reason: route,
          );
        }
      },
    );
  });

  group('la chaîne jusqu’au contenu de Terminale D', () {
    test('le compte arrive en Terminale D, la classe proposée par défaut', () {
      expect(DemoAccess.recommended.label, 'Terminale D');
      expect(DemoAccess.recommended.classLevel, 'Terminale');
      expect(DemoAccess.recommended.seriesValue, 'D');
      expect(DemoAccess.optionFor('Terminale', 'D'), DemoAccess.recommended);
    });

    test('toutes les classes et séries restent explorables', () {
      final labels = DemoAccess.options.map((option) => option.label);
      expect(DemoAccess.options, hasLength(19));
      expect(labels, containsAll(['6ème', 'Terminale A', 'Terminale C']));
      expect(labels, contains('Terminale D'));
      expect(labels, contains('Upper Sixth'));
    });

    test(
      'Terminale D : maths, anglais et physique, tous leurs chapitres',
      () async {
        final key = ClassKey.fromProfile('Terminale', series: 'D');
        expect(key, const ClassKey('terminale', series: 'd'));
        final repository = ContentPackRepository(
          source: DiskContentPackSource(),
        );
        final subjects = await repository.subjectsFor(key);
        expect(subjects.map((subject) => subject.key), {
          'anglais',
          'mathematiques',
          'physique',
        });
        final chapters = [
          for (final subject in subjects)
            for (final entry in subject.chapters) entry.contentId,
        ];
        expect(chapters, hasLength(7));
      },
    );

    test(
      'Quiz, exercices et jeux : chaque chapitre a de quoi s’exercer',
      () async {
        final repository = ContentPackRepository(
          source: DiskContentPackSource(),
        );
        final subjects = await repository.subjectsFor(
          ClassKey.fromProfile('Terminale', series: 'D'),
        );
        var withQuestions = 0;
        for (final subject in subjects) {
          for (final entry in subject.chapters) {
            final chapter = await repository.chapter(entry.contentId);
            expect(chapter.lessons, isNotEmpty, reason: entry.contentId);
            if (chapter.questions.isNotEmpty) withQuestions++;
          }
        }
        expect(withQuestions, greaterThanOrEqualTo(6));
      },
    );

    test(
      'aucune porte fermée : toutes les routes élève restent ouvertes',
      () async {
        final harness = _Harness();
        addTearDown(harness.dispose);
        await harness.controller.signInWithPartnerAccess(_partnerEmail);
        final auth = harness.container.read(authControllerProvider);
        for (final location in [
          AppRoutes.studentHome,
          AppRoutes.learnHub,
          AppRoutes.quizHub,
          AppRoutes.aiCompanion,
          AppRoutes.flow,
          AppRoutes.settings,
          AppRoutes.studentNotifications,
          '/learn/local/maths_td_ch01_arithmetique',
          '/quiz/play/some-quiz',
        ]) {
          expect(
            resolveAppRedirect(
              auth: auth,
              hasSeenOnboarding: true,
              hasAuthenticatedBefore: true,
              location: location,
            ),
            isNull,
            reason: '$location doit rester ouvert au compte partenaire',
          );
        }
      },
    );

    test('le Compagnon ne demande aucun abonnement ni aucun réseau', () {
      // Le moteur du Compagnon est déterministe et local (voir
      // companion_no_llm_test.dart) : aucune réserve, aucun droit à vérifier.
      expect(AppRoutes.aiCompanion, '/ai');
    });
  });

  group('écran de connexion', () {
    Finder field(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(TextFormField),
    );

    bool passwordEnabled(WidgetTester tester) =>
        tester.widget<TextFormField>(field('login-password-field')).enabled;

    Future<void> type(WidgetTester tester, String email) async {
      await tester.enterText(field('login-email-field'), email);
      await tester.pump();
    }

    Finder cta(String label) => find.descendant(
      of: find.byKey(const ValueKey('login-submit')),
      matching: find.text(label),
    );

    testWidgets('adresse reconnue : mot de passe grisé, statut, bouton', (
      tester,
    ) async {
      await _pumpLogin(tester, _Harness());
      expect(passwordEnabled(tester), isTrue);
      expect(cta('Se connecter'), findsOneWidget);
      expect(find.byKey(const ValueKey('partner-access-status')), findsNothing);

      await type(tester, _partnerEmail);
      expect(passwordEnabled(tester), isFalse, reason: 'non éditable');
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('login-password-dimmer')),
            )
            .opacity,
        lessThan(0.5),
        reason: 'grisé',
      );
      expect(find.text('Accès partenaire INTELLIA'), findsOneWidget);
      expect(cta('Accéder à INTELLIA'), findsOneWidget);
      expect(cta('Se connecter'), findsNothing);
      expect(find.text('Mot de passe oublié ?'), findsNothing);
    });

    testWidgets('majuscules et espaces : le même comportement', (tester) async {
      await _pumpLogin(tester, _Harness());
      for (final raw in ['FRAN6FARMER@YAHOO.FR', ' fran6farmer@yahoo.fr ']) {
        await type(tester, raw);
        expect(passwordEnabled(tester), isFalse, reason: raw);
        expect(cta('Accéder à INTELLIA'), findsOneWidget, reason: raw);
      }
    });

    testWidgets('toute autre adresse : le flux normal, inchangé', (
      tester,
    ) async {
      await _pumpLogin(tester, _Harness());
      for (final raw in [
        'fran6farmer@yahoo.com',
        'fran6farmer2@yahoo.fr',
        'student@example.com',
        'fran6farmer@yahoo',
      ]) {
        await type(tester, raw);
        expect(passwordEnabled(tester), isTrue, reason: raw);
        expect(cta('Se connecter'), findsOneWidget, reason: raw);
        expect(
          find.byKey(const ValueKey('partner-access-status')),
          findsNothing,
          reason: raw,
        );
        expect(find.text('Mot de passe oublié ?'), findsOneWidget, reason: raw);
      }
    });

    testWidgets('le comportement suit l’adresse en direct', (tester) async {
      await _pumpLogin(tester, _Harness());
      await type(tester, _partnerEmail);
      expect(passwordEnabled(tester), isFalse);
      await type(tester, 'fran6farmer2@yahoo.fr');
      expect(passwordEnabled(tester), isTrue);
      expect(cta('Se connecter'), findsOneWidget);
    });

    testWidgets('« Accéder à INTELLIA » ouvre la session, sans mot de passe', (
      tester,
    ) async {
      final harness = _Harness();
      await _pumpLogin(tester, harness);
      await type(tester, ' FRAN6FARMER@YAHOO.FR ');
      // Le mot de passe est vide : aucune validation ne le réclame.
      await tester.tap(find.byKey(const ValueKey('login-submit')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      expect(harness.partner.calls, [_partnerEmail]);
      expect(harness.repo.emailSignIns, 0);
      final auth = harness.container.read(authControllerProvider);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.userId, PartnerAccess.uid);
      expect(find.text('Le mot de passe est requis'), findsNothing);
    });

    testWidgets('une autre adresse suit le parcours e-mail habituel', (
      tester,
    ) async {
      final harness = _Harness()..repo.current = _otherUser;
      await _pumpLogin(tester, harness);
      await type(tester, 'student@example.com');
      await tester.enterText(field('login-password-field'), 'Motdepasse1!');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('login-submit')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      expect(harness.repo.emailSignIns, 1);
      expect(harness.partner.calls, isEmpty);
    });

    testWidgets('échec : un message calme, l’écran reste utilisable', (
      tester,
    ) async {
      final harness = _Harness()..partner.fail = true;
      await _pumpLogin(tester, harness);
      await type(tester, _partnerEmail);
      await tester.tap(find.byKey(const ValueKey('login-submit')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(AuthErrorBanner), findsOneWidget);
      expect(
        harness.container.read(authControllerProvider).isAuthenticated,
        isFalse,
      );
      expect(harness.container.read(authControllerProvider).isLoading, isFalse);
    });

    testWidgets('l’écran de création de compte reconnaît aussi l’adresse', (
      tester,
    ) async {
      await _pumpLogin(tester, _Harness(), createIdentity: true);
      await type(tester, _partnerEmail);
      expect(passwordEnabled(tester), isFalse);
      expect(cta('Accéder à INTELLIA'), findsOneWidget);
    });

    testWidgets('l’accès personnel (administration) ne la reconnaît jamais', (
      tester,
    ) async {
      await _pumpLogin(tester, _Harness(), requireSuperAdmin: true);
      await type(tester, _partnerEmail);
      expect(passwordEnabled(tester), isTrue);
      expect(find.byKey(const ValueKey('partner-access-status')), findsNothing);
    });
  });
}

Future<void> _pumpLogin(
  WidgetTester tester,
  _Harness harness, {
  bool createIdentity = false,
  bool requireSuperAdmin = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(harness.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: harness.container,
      child: MaterialApp(
        locale: const Locale('fr'),
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
        home: LoginScreen(
          createIdentity: createIdentity,
          requireSuperAdmin: requireSuperAdmin,
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Les services simulés : aucun Firebase, aucun réseau.
class _Harness {
  _Harness() {
    partner = _Partner(repo);
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        partnerAccessRepositoryProvider.overrideWithValue(partner),
      ],
    );
  }

  final repo = _Repo();
  late final _Partner partner;
  late final ProviderContainer container;
  bool _disposed = false;

  AuthController get controller =>
      container.read(authControllerProvider.notifier);

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    container.dispose();
  }
}

/// Le serveur : une réponse réussie ouvre la session du compte canonique.
class _Partner implements PartnerAccessRepository {
  _Partner(this.repo);

  final _Repo repo;
  final calls = <String>[];
  final uids = <String>{};
  bool fail = false;

  @override
  Future<void> signIn(String email) async {
    calls.add(email);
    if (fail) throw const PartnerAccessException('unavailable');
    repo.current = _partnerUser;
    uids.add(_partnerUser.uid);
  }
}

class _Repo
    implements AuthRepository, AuthSessionResolver, EmailIdentityCreator {
  AuthUserData? current;
  int emailSignIns = 0;

  @override
  Future<AuthUserData?> getCurrentUser() async => current;

  @override
  Future<AuthSessionResolution> resolveCurrentSession() async =>
      AuthSessionResolution(
        kind: current == null
            ? AuthSessionResolutionKind.unauthenticated
            : AuthSessionResolutionKind.authenticated,
        firebaseUid: current?.uid,
        user: current,
      );

  @override
  Future<AuthUserData> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emailSignIns++;
    return current!;
  }

  @override
  Future<void> signOut() async {
    current = null;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AuthUserData> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required AppRole role,
  }) async => throw UnimplementedError();

  @override
  Future<void> createEmailIdentity({
    required String email,
    required String password,
  }) async {}
}

class _Identity implements FirebaseIdentityPort {
  _Identity(this.currentUid);

  @override
  final String? currentUid;

  @override
  Stream<String?> uidChanges() => const Stream<String?>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
