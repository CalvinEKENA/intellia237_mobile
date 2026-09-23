import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/app/theme/app_theme.dart';
import 'package:intellia237/core/localization/app_locale_controller.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/application/google_access_coordinator.dart';
import 'package:intellia237/features/auth/application/phone_auth_controller.dart';
import 'package:intellia237/features/auth/data/auth_entry_preferences.dart';
import 'package:intellia237/features/auth/data/repositories/firebase_phone_auth_repository.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/auth/domain/repositories/phone_auth_repository.dart';
import 'package:intellia237/features/auth/presentation/widgets/auth_experience_scaffold.dart';
import 'package:intellia237/features/auth/presentation/widgets/intellia_237_membrane.dart';
import 'package:intellia237/features/family_access/application/family_access_providers.dart';
import 'package:intellia237/features/family_access/data/family_access_repository.dart';
import 'package:intellia237/features/family_access/domain/family_access_models.dart';
import 'package:intellia237/features/notifications/data/notification_repository.dart';
import 'package:intellia237/features/onboarding/data/onboarding_preferences.dart';
import 'package:intellia237/features/parent/application/parent_providers.dart';
import 'package:intellia237/features/parent/data/child_link_service.dart';
import 'package:intellia237/features/parent/data/parent_repository.dart';
import 'package:intellia237/features/parent/domain/parent_child_profile.dart';
import 'package:intellia237/features/parent/domain/parent_dashboard.dart';
import 'package:intellia237/features/role_registration/data/firebase_role_registration_repository.dart';
import 'package:intellia237/features/role_registration/data/role_registration_repository.dart';
import 'package:intellia237/features/role_registration/domain/admin_registration_payload.dart';
import 'package:intellia237/features/role_registration/domain/parent_registration_payload.dart';
import 'package:intellia237/features/role_registration/domain/registration_result.dart';
import 'package:intellia237/features/role_registration/domain/teacher_registration_payload.dart';
import 'package:intellia237/features/tour_guide/data/firestore_tour_guide_repository.dart';
import 'package:intellia237/features/tour_guide/data/tour_guide_repository.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

import 'fake_google_access.dart';

/// Parcours d'authentification rejoué comme sur un téléphone Android.
///
/// Registre de décisions (QA appareil, round 3) : les tests précédents
/// posaient une valeur sur le peintre du « 237 », ou pilotaient un écran
/// isolé, sans clavier, dans une fenêtre de test de 800 × 600. Sur le
/// téléphone du propriétaire, la saisie se fait clavier ouvert — le Pass est
/// alors compact —, le SMS peut être lu automatiquement par Android, et la
/// réussite quitte l'écran après une lecture réseau du profil. Ce harnais
/// rejoue ces conditions sur les vrais écrans, les vraies pages de transition
/// (`buildAppTransitionPage`, `buildPassHomePage`, vol du Hero) et la vraie
/// redirection du routeur (`AppRouterNotifier`). Seuls les services distants
/// et le contenu des accueils sont simulés.
class SealJourney {
  SealJourney._(
    this.tester,
    this.container,
    this.router,
    this.trace,
    this.device,
    this.google,
  );

  final WidgetTester tester;
  final ProviderContainer container;
  final GoRouter router;
  final SealTrace trace;
  final SealDevice device;

  /// Sélecteur de comptes Google du téléphone simulé.
  final FakeGoogleCredentialSource google;

  /// Relève du sceau à chaque image. Les parcours qui ne vérifient pas le
  /// sceau s'en passent : le relevé parcourt tout l'arbre à chaque image.
  bool traceSeal = true;

  static Future<SealJourney> start(
    WidgetTester tester,
    DeviceBackend backend, {
    String initialLocation = AppRoutes.authGateway,
    Locale locale = const Locale('fr'),
    bool reduceMotion = false,
    String? signedInPhone,
    ThemeData? theme,
    SealDevice device = SealDevice.midRange,
    List<String> extraSlots = const [],
    bool realParentHome = false,
    bool traceSeal = true,
  }) async {
    tester.view.physicalSize = device.physicalSize;
    tester.view.devicePixelRatio = device.pixelRatio;
    // Barre d'état d'un téléphone à caméra poinçonnée.
    tester.view.padding = FakeViewPadding(top: 32 * device.pixelRatio);
    addTearDown(tester.view.reset);
    if (signedInPhone != null) backend.signInWithPhone(signedInPhone);

    Widget home(String label) => Material(
      color: AuthExperienceColors.canvas,
      child: Center(child: Text(label)),
    );
    final google = FakeGoogleCredentialSource(backend.identity);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(DeviceAuthRepository(backend)),
        // Google et Firebase Auth simulés sur le même backend : la sonde, la
        // connexion, le rattachement et l'écoute de l'identité.
        googleCredentialSourceProvider.overrideWithValue(google),
        googleIdentityProbeProvider.overrideWithValue(backend.probe),
        firebaseIdentityPortProvider.overrideWithValue(
          FakeFirebaseIdentity(backend.identity),
        ),
        phoneAuthRepositoryProvider.overrideWithValue(
          DevicePhoneRepository(backend),
        ),
        phoneRequestGateProvider.overrideWithValue(backend.requestGate),
        familyAccessRepositoryProvider.overrideWithValue(
          DeviceFamilyAccess(backend),
        ),
        childLinkServiceProvider.overrideWithValue(_LinkService(backend)),
        parentRepositoryProvider.overrideWithValue(
          DeviceParentRepository(backend),
        ),
        roleRegistrationRepositoryProvider.overrideWithValue(
          _RegistrationRepository(backend),
        ),
        unreadNotificationCountProvider.overrideWithValue(0),
        tourGuideRepositoryProvider.overrideWithValue(_SeenTour()),
        hasSeenOnboardingProvider.overrideWith((ref) => true),
        hasAuthenticatedBeforeProvider.overrideWith((ref) => true),
        appRouterInitialLocationProvider.overrideWithValue(initialLocation),
        // Table de routes, pages de transition, vol du Pass et redirection de
        // production ; seuls les écrans d'accueil et leurs services sont
        // remplacés.
        appRouteSlotsProvider.overrideWithValue({
          for (final path in [
            AppRoutes.bootstrap,
            AppRoutes.onboarding,
            AppRoutes.adminRegistration,
            AppRoutes.authProfileRecovery,
            AppRoutes.adminHome,
            AppRoutes.tutorSelection,
            AppRoutes.studentHome,
            if (!realParentHome) AppRoutes.parentHome,
            AppRoutes.teacherHome,
            ...extraSlots,
          ])
            path: (_, _) => home(path),
        }),
      ],
    );
    addTearDown(container.dispose);
    // Le démarrage se lit sans délai : hors pompage, le temps simulé des
    // tests ne s'écoule pas.
    backend.networkDelays = false;
    await container.read(authControllerProvider.notifier).completeBootstrap();
    backend.networkDelays = true;

    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);

    // La langue suit le même provider que l'application : un changement de
    // langue en cours de parcours reconstruit toute l'application.
    await container
        .read(appLocaleProvider.notifier)
        .setLanguage(locale.languageCode);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: screenKey,
          child: Consumer(
            builder: (context, ref, _) => MaterialApp.router(
              routerConfig: router,
              debugShowCheckedModeBanner: false,
              locale: ref.watch(appLocaleProvider),
              theme: theme ?? AppTheme.light,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: reduceMotion,
                  textScaler: TextScaler.linear(device.textScale),
                ),
                child: child!,
              ),
            ),
          ),
        ),
      ),
    );
    late final SealJourney journey;
    final trace = SealTrace(
      () => router.state.uri.path,
      () => journey.unobscured,
    );
    journey = SealJourney._(tester, container, router, trace, device, google)
      ..traceSeal = traceSeal;
    await journey.wait(const Duration(milliseconds: 600));
    return journey;
  }

  static final screenKey = GlobalKey();

  String get location => router.state.uri.path;
  AuthState get auth => container.read(authControllerProvider);

  /// Écrit l'image réellement peinte de l'écran, à la densité du téléphone.
  Future<void> capture(String path) async {
    final boundary =
        screenKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: device.pixelRatio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(path).writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  /// Un clavier est ouvert tant qu'un champ de saisie a le focus.
  void _syncKeyboard() {
    final focus = FocusManager.instance.primaryFocus;
    final editing =
        focus?.context?.findAncestorStateOfType<EditableTextState>() != null;
    final bottom = editing ? device.keyboardHeight * device.pixelRatio : 0.0;
    if (tester.view.viewInsets.bottom != bottom) {
      tester.view.viewInsets = FakeViewPadding(bottom: bottom);
    }
  }

  /// Avance le temps image par image (60 Hz), en relevant le sceau à chaque
  /// image effectivement peinte.
  Future<void> wait(Duration duration) async {
    const frame = Duration(microseconds: 16667);
    var elapsed = Duration.zero;
    while (elapsed < duration) {
      _syncKeyboard();
      await tester.pump(frame);
      elapsed += frame;
      if (traceSeal) trace.sample(tester, frame);
    }
  }

  /// Avance jusqu'à ce que [done] soit vrai, ou échoue après [limit].
  Future<void> waitUntil(
    bool Function() done, {
    Duration limit = const Duration(seconds: 20),
  }) async {
    var elapsed = Duration.zero;
    const step = Duration(milliseconds: 50);
    while (!done()) {
      if (elapsed > limit) {
        fail('condition not reached after $limit (at $location)');
      }
      await wait(step);
      elapsed += step;
    }
  }

  /// Zone de l'écran que ni la barre d'état ni le clavier ne couvrent.
  Rect get unobscured {
    final view = tester.view;
    final size = view.physicalSize / view.devicePixelRatio;
    final top = view.padding.top / view.devicePixelRatio;
    final bottom = view.viewInsets.bottom / view.devicePixelRatio;
    return Rect.fromLTRB(0, top, size.width, size.height - bottom);
  }

  /// Fait défiler juste assez pour atteindre [target], comme un doigt : sans
  /// l'aligner en haut de l'écran, ce que ferait `tester.ensureVisible`.
  Future<void> reveal(Finder target) async {
    final rect = tester.getRect(target);
    final area = unobscured;
    if (rect.top >= area.top && rect.bottom <= area.bottom) return;
    await Scrollable.ensureVisible(
      tester.element(target),
      alignmentPolicy: rect.bottom > area.bottom
          ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
          : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
    await wait(const Duration(milliseconds: 50));
  }

  /// Touche l'élément [key] réellement affiché — jamais une navigation
  /// directe : les parcours traversent les vrais écrans (refonte Auth V2).
  Future<void> tap(String key) => tapFinder(find.byKey(ValueKey(key)));

  /// Attend qu'un élément [key] soit affiché, puis le touche.
  Future<void> tapWhenShown(String key) async {
    await waitUntil(() => find.byKey(ValueKey(key)).evaluate().isNotEmpty);
    await tap(key);
  }

  /// Téléphone de famille : la personne confirme être l'élève du numéro.
  Future<void> confirmStudentPhone() => tapWhenShown('phone-student-confirm');

  Future<void> tapText(String text) => tapFinder(find.text(text));

  Future<void> tapFinder(Finder target) async {
    await reveal(target);
    await wait(const Duration(milliseconds: 50));
    await tester.tap(target, warnIfMissed: false);
    await wait(const Duration(milliseconds: 120));
  }

  /// Saisie touche par touche, clavier ouvert. Le défilement vers le champ
  /// est laissé au framework, qui révèle le curseur au-dessus du clavier.
  Future<void> type(
    Finder field,
    String text, {
    int from = 0,
    Duration perKey = const Duration(milliseconds: 180),
  }) async {
    await tester.showKeyboard(field);
    await wait(const Duration(milliseconds: 250));
    for (var i = from + 1; i <= text.length; i++) {
      await tester.enterText(field, text.substring(0, i));
      await wait(perKey);
    }
  }

  /// Poursuit la saisie de [text] dans le champ [key] à partir du caractère
  /// [from] : les caractères précédents sont déjà tapés.
  Future<void> typeKey(String key, String text, {int from = 0}) =>
      type(find.byKey(ValueKey(key)), text, from: from);

  /// Ce que le peintre du sceau le plus visible reçoit à l'image courante.
  SealReading? get seal {
    trace.sample(tester, Duration.zero);
    return trace.frames.removeLast().primary;
  }

  /// Transformations de mouvement de tous les sceaux à l'écran.
  Iterable<Matrix4> get motions => tester
      .widgetList<Transform>(find.byKey(Intellia237Membrane.motionKey))
      .map((transform) => transform.transform);
}

/// Téléphone simulé : écran, densité, clavier et taille de texte système.
class SealDevice {
  const SealDevice({
    required this.physicalSize,
    required this.pixelRatio,
    this.keyboardHeight = 300,
    this.textScale = 1,
  });

  /// 1080 × 2400 à 2,625 : un milieu de gamme Android courant.
  static const midRange = SealDevice(
    physicalSize: Size(1080, 2400),
    pixelRatio: 2.625,
  );

  /// 720 × 1520 à 2 (360 × 760) : un petit Android d'entrée de gamme, texte
  /// système agrandi à 130 % et clavier haut.
  static const smallLargeText = SealDevice(
    physicalSize: Size(720, 1520),
    pixelRatio: 2,
    keyboardHeight: 320,
    textScale: 1.3,
  );

  final Size physicalSize;
  final double pixelRatio;

  /// Hauteur du clavier, en pixels logiques.
  final double keyboardHeight;
  final double textScale;
}

// ─────────────────────────────────────────────────────────────
// Relevé du sceau
// ─────────────────────────────────────────────────────────────

/// Ce que le peintre du sceau reçoit à une image donnée.
class SealReading {
  const SealReading({
    required this.stage,
    required this.digitColors,
    required this.size,
    required this.visible,
  });

  /// Étape livrée au peintre.
  final PassSealStage stage;

  /// Couleurs réellement peintes pour « 2 », « 3 », « 7 ».
  final List<Color> digitColors;
  final Size size;

  /// Part du sceau (0 → 1) dans la zone que ni la barre d'état ni le clavier
  /// ne couvrent.
  final double visible;

  /// Fondu terminé : les couleurs peintes sont exactement celles de l'étape.
  bool get settled =>
      listEquals(digitColors, Intellia237Palette.digitColors(stage));

  /// « 2 » vert, « 3 » rouge, « 7 » jaune, exactement.
  bool get tricolor => listEquals(digitColors, Intellia237Palette.digitTargets);

  String get key =>
      '${stage.name}|$settled|'
      '${size.width.round()}x${size.height.round()}|'
      '${(visible * 10).round()}';
}

class SealFrame {
  SealFrame(this.at, this.route, this.seals);

  final Duration at;
  final String route;
  final List<SealReading> seals;

  String get key => '$route|${seals.map((s) => s.key).join(',')}';

  /// Le sceau le plus visible de l'image : pendant un vol de Hero, celui qui
  /// vole.
  SealReading? get primary {
    if (seals.isEmpty) return null;
    return seals.reduce((a, b) => b.visible > a.visible ? b : a);
  }
}

class SealTrace {
  SealTrace(this._route, this._unobscured);

  final String Function() _route;
  final Rect Function() _unobscured;
  final frames = <SealFrame>[];
  Duration _clock = Duration.zero;

  Duration get clock => _clock;

  void sample(WidgetTester tester, Duration frame) {
    _clock += frame;
    final seals = <SealReading>[];
    final area = _unobscured();
    for (final element in find.byKey(Intellia237Membrane.paintKey).evaluate()) {
      final paint = element.widget as CustomPaint;
      final painter = paint.painter! as Intellia237SealPainter;
      final box = element.renderObject as RenderBox?;
      final attached = box != null && box.attached && box.hasSize;
      var visible = 0.0;
      if (attached) {
        final rect = box.localToGlobal(Offset.zero) & box.size;
        final overlap = rect.intersect(area);
        if (!overlap.isEmpty && rect.height > 0) {
          visible =
              (overlap.width * overlap.height) / (rect.width * rect.height);
        }
      }
      seals.add(
        SealReading(
          stage: painter.stage,
          digitColors: painter.digitColors,
          size: attached ? box.size : Size.zero,
          visible: visible,
        ),
      );
    }
    frames.add(SealFrame(_clock, _route(), seals));
  }

  /// Images consécutives identiques regroupées en plages.
  List<({Duration from, Duration to, SealFrame frame})> get spans {
    final result = <({Duration from, Duration to, SealFrame frame})>[];
    for (final frame in frames) {
      if (result.isNotEmpty && result.last.frame.key == frame.key) {
        final last = result.removeLast();
        result.add((from: last.from, to: frame.at, frame: last.frame));
      } else {
        result.add((from: frame.at, to: frame.at, frame: frame));
      }
    }
    return result;
  }

  /// Étapes successives livrées au peintre du sceau le plus en vue, doublons
  /// consécutifs retirés.
  List<PassSealStage> get stages {
    final result = <PassSealStage>[];
    for (final frame in frames) {
      final seal = frame.primary;
      if (seal == null) continue;
      if (result.isEmpty || result.last != seal.stage) result.add(seal.stage);
    }
    return result;
  }

  /// Plus longue durée continue pendant laquelle [test] est vrai, sur la
  /// route [route].
  Duration longest(bool Function(SealReading seal) test, {String? route}) {
    var best = Duration.zero;
    Duration? since;
    for (final frame in frames) {
      final seal = frame.primary;
      final holds =
          seal != null && test(seal) && (route == null || frame.route == route);
      if (holds) {
        since ??= frame.at;
        final span = frame.at - since;
        if (span > best) best = span;
      } else {
        since = null;
      }
    }
    return best;
  }

  static String digits(List<Color> colors) {
    String name(Color color, int digit) {
      if (color == Intellia237Palette.base) return 'indigo';
      if (color == Intellia237Palette.digitTargets[digit]) {
        return const ['green', 'red', 'yellow'][digit];
      }
      return 'fading';
    }

    return '2=${name(colors[0], 0)} 3=${name(colors[1], 1)} '
        '7=${name(colors[2], 2)}';
  }

  String describe() {
    final buffer = StringBuffer();
    for (final span in spans) {
      final seals = span.frame.seals.isEmpty
          ? 'no seal on screen'
          : span.frame.seals
                .map(
                  (s) =>
                      '${s.stage.name.padRight(10)} '
                      '[${digits(s.digitColors)}] '
                      '${s.size.width.round()}×${s.size.height.round()} '
                      'visible=${(s.visible * 100).round()}%',
                )
                .join(' + ');
      buffer.writeln(
        '${_ms(span.from).padLeft(6)}–${_ms(span.to).padLeft(6)} ms  '
        '${span.frame.route.padRight(22)} $seals',
      );
    }
    return buffer.toString();
  }

  static String _ms(Duration d) => '${d.inMilliseconds}';
}

// ─────────────────────────────────────────────────────────────
// Services distants simulés, aux délais d'un réseau mobile réel
// ─────────────────────────────────────────────────────────────

enum SmsBehaviour {
  /// L'élève tape le code reçu.
  typed,

  /// Android lit le SMS et Firebase valide sans saisie.
  autoRetrieved,

  /// Firebase valide le numéro sans envoyer de SMS.
  instant,
}

class DeviceAccount {
  DeviceAccount({required this.uid, required this.role, required this.name});

  final String uid;
  final AppRole role;
  final String name;
}

class DeviceBackend {
  DeviceBackend() {
    createPhoneAccount(studentPhone, 'student-uid', AppRole.student, 'Awa');
    createPhoneAccount(parentPhone, 'parent-uid', AppRole.parent, 'Claire');
    emailAccounts[teacherEmail] = 'teacher-uid';
    identity.emailAccounts[teacherEmail] = (
      uid: 'teacher-uid',
      password: teacherPassword,
    );
    accounts['teacher-uid'] = DeviceAccount(
      uid: 'teacher-uid',
      role: AppRole.teacher,
      name: 'Serge',
    );
  }

  static const studentPhone = '699000001';
  static const parentPhone = '677000002';
  static const newPhone = '655000003';
  static const teacherEmail = 'serge@ecole.cm';
  static const teacherPassword = 'motdepasse';

  /// Délais observés sur un réseau mobile : envoi du SMS (Play Integrity
  /// compris), arrivée du SMS, validation du code, lecture du profil.
  Duration codeSentDelay = const Duration(milliseconds: 1200);
  Duration smsArrivalDelay = const Duration(milliseconds: 2500);
  Duration confirmDelay = const Duration(milliseconds: 900);
  Duration profileReadDelay = const Duration(milliseconds: 600);
  SmsBehaviour sms = SmsBehaviour.typed;
  bool networkDelays = true;

  Future<void> network(Duration delay) =>
      networkDelays ? Future<void>.delayed(delay) : Future<void>.value();

  final uidsByPhone = <String, String>{};
  final emailAccounts = <String, String>{};
  final accounts = <String, DeviceAccount>{};

  /// Identités Firebase (session courante, Google, e-mail) partagées avec
  /// l'écoute de l'identité du contrôleur d'authentification.
  final identity = FakeIdentityBackend();
  late final probe = FakeGoogleIdentityProbe(identity);

  String? get currentUid => identity.currentUid;
  set currentUid(String? uid) => identity.currentUid = uid;

  void createPhoneAccount(String phone, String uid, AppRole role, String name) {
    uidsByPhone['+237$phone'] = uid;
    accounts[uid] = DeviceAccount(uid: uid, role: role, name: name);
  }

  void signInWithPhone(String e164OrLocal) {
    final key = e164OrLocal.startsWith('+') ? e164OrLocal : '+237$e164OrLocal';
    currentUid = uidsByPhone.putIfAbsent(key, () => 'uid-$key');
  }

  /// Codes d'accès élève actifs : code normalisé → UID élève. Une émission
  /// remplace le code précédent du même élève.
  final accessCodes = <String, String>{};
  final parentLinks = <String, Set<String>>{};

  /// École de chaque élève (nom affiché).
  final schoolOf = <String, String>{};

  /// Codes SMS que Firebase refuse (code faux ou expiré).
  final rejectedCodes = <String>{};

  /// Espacement des SMS par numéro, comme en production, sur une horloge que
  /// le parcours peut avancer : une famille attend avant de redemander un
  /// SMS pour le même numéro.
  final requestGate = DevicePhoneRequestGate();

  /// Codes de liaison parent actifs : code → UID élève.
  final linkCodes = <String, String>{'K7MP2QXA': 'student-uid'};

  /// Enfants dont le parent a ouvert l'accès : identité et code, mais aucun
  /// profil tant que l'enfant ne s'est pas connecté (UID → prénom).
  final pendingChildren = <String, String>{};

  /// Crée un élève sans téléphone : seul un code d'accès l'ouvre.
  void createStudentWithoutPhone(String uid, String name) {
    accounts[uid] = DeviceAccount(uid: uid, role: AppRole.student, name: name);
  }

  int _issued = 0;

  /// Double panne simulée pendant la migration : le numéro quitte l'élève,
  /// l'identité parent n'est pas créée, la compensation échoue aussi. Le
  /// serveur renvoie alors le code d'accès de l'élève et attend une nouvelle
  /// vérification du numéro.
  bool failMigrationAfterDetach = false;
  String? migrationAwaitingRecovery;

  /// Délai de la migration côté serveur (plusieurs appels Admin).
  Duration migrationDelay = const Duration(milliseconds: 1400);

  String issueAccessCode(String studentUid) {
    accessCodes.removeWhere((_, uid) => uid == studentUid);
    const alphabet = StudentAccessCodeFormat.alphabet;
    final seed = (++_issued * 7919 + studentUid.hashCode).abs();
    final code = List.generate(
      StudentAccessCodeFormat.length,
      (i) => alphabet[(seed ~/ (i + 1) + i * 13) % alphabet.length],
    ).join();
    accessCodes[code] = studentUid;
    return StudentAccessCodeFormat.format(code);
  }
}

/// Espacement des demandes de SMS de production, sur une horloge avançable.
class DevicePhoneRequestGate extends PhoneRequestGate {
  final _deadlines = <String, DateTime>{};
  Duration _offset = Duration.zero;

  DateTime get _now => DateTime.now().add(_offset);

  /// Le temps passe pour la famille (en temps réel, comme l'espacement).
  void advance(Duration duration) => _offset += duration;

  @override
  int remaining(String phone) {
    final deadline = _deadlines[phone];
    if (deadline == null) return 0;
    final milliseconds = deadline.difference(_now).inMilliseconds;
    return milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
  }

  @override
  void reserve(String phone, int seconds) {
    _deadlines.removeWhere((_, deadline) => deadline.isBefore(_now));
    _deadlines[phone] = _now.add(Duration(seconds: seconds));
  }
}

/// Accès famille simulé comme le serveur : migration du téléphone familial,
/// codes d'accès élève, jetons personnalisés.
class DeviceFamilyAccess implements FamilyAccessRepository {
  DeviceFamilyAccess(this.backend);
  final DeviceBackend backend;

  @override
  Future<FamilyPhoneMigrationResult> migrateStudentPhoneToParent() async {
    await backend.network(backend.migrationDelay);
    final awaiting = backend.migrationAwaitingRecovery;
    final caller = backend.currentUid;
    if (awaiting != null &&
        caller != null &&
        backend.accounts[caller] == null) {
      // Reprise : l'identité fraîche, vérifiée par SMS, devient le parent.
      backend.migrationAwaitingRecovery = null;
      backend.parentLinks.putIfAbsent(caller, () => {}).add(awaiting);
      return FamilyPhoneMigrationResult(
        studentId: awaiting,
        studentFirstName: backend.accounts[awaiting]!.name,
        parentUid: caller,
      );
    }
    final studentUid = backend.currentUid;
    final student = backend.accounts[studentUid];
    final phone = backend.uidsByPhone.entries
        .where((entry) => entry.value == studentUid)
        .map((entry) => entry.key)
        .firstOrNull;
    if (studentUid == null ||
        student?.role != AppRole.student ||
        phone == null) {
      throw const FamilyAccessException('failed-precondition');
    }
    if (backend.failMigrationAfterDetach) {
      backend.uidsByPhone.remove(phone);
      backend.migrationAwaitingRecovery = studentUid;
      throw FamilyAccessException(
        'unavailable',
        reason: 'migration-needs-recovery',
        studentAccessCode: backend.issueAccessCode(studentUid),
      );
    }
    final parentUid = 'parent-of-$studentUid';
    backend.uidsByPhone[phone] = parentUid;
    backend.parentLinks.putIfAbsent(parentUid, () => {}).add(studentUid);
    return FamilyPhoneMigrationResult(
      studentId: studentUid,
      studentFirstName: student!.name,
      parentUid: parentUid,
      parentToken: 'token:$parentUid',
      studentAccessCode: backend.issueAccessCode(studentUid),
    );
  }

  @override
  Future<void> signInWithCustomToken(String token) async {
    await backend.network(backend.confirmDelay);
    backend.currentUid = token.substring('token:'.length);
  }

  @override
  Future<void> signInWithStudentAccessCode(String code) async {
    await backend.network(backend.confirmDelay);
    final uid = backend.accessCodes[StudentAccessCodeFormat.normalize(code)];
    if (uid == null) throw const FamilyAccessException('permission-denied');
    backend.currentUid = uid;
  }

  @override
  Future<IssuedStudentAccessCode> issueStudentAccessCode(
    String studentId,
  ) async {
    await backend.network(backend.confirmDelay);
    final parent = backend.currentUid;
    if (!(backend.parentLinks[parent]?.contains(studentId) ?? false)) {
      throw const FamilyAccessException('permission-denied');
    }
    return IssuedStudentAccessCode(code: backend.issueAccessCode(studentId));
  }

  @override
  Future<List<ParentChildSummary>> listParentChildren({
    String? parentUid,
  }) async => const [];

  @override
  Future<CreatedChildAccess> createChildStudentAccess(String firstName) async {
    await backend.network(backend.confirmDelay);
    final parent = backend.currentUid!;
    final uid = 'child-${backend.pendingChildren.length + 1}';
    backend.pendingChildren[uid] = firstName;
    backend.parentLinks.putIfAbsent(parent, () => {}).add(uid);
    return CreatedChildAccess(
      studentId: uid,
      firstName: firstName,
      code: backend.issueAccessCode(uid),
    );
  }
}

class DevicePhoneRepository implements PhoneAuthRepository {
  DevicePhoneRepository(this.backend);
  final DeviceBackend backend;

  PhoneAuthSession _session(String phoneNumber) {
    backend.signInWithPhone(phoneNumber);
    return PhoneAuthSession(
      uid: backend.currentUid!,
      phoneNumber: phoneNumber,
      isNewUser: backend.accounts[backend.currentUid] == null,
      linkedToExistingUser: false,
    );
  }

  @override
  Future<void> startVerification({
    required String phoneNumber,
    required bool linkCurrentUser,
    int? forceResendingToken,
    required void Function(PhoneAuthSession) onVerified,
    required void Function(PhoneAuthFailure) onFailed,
    required void Function(PhoneCodeDispatch) onCodeSent,
    required void Function(String) onAutoRetrievalTimeout,
  }) async {
    await Future<void>.delayed(backend.codeSentDelay);
    if (backend.sms == SmsBehaviour.instant) {
      await Future<void>.delayed(backend.confirmDelay);
      onVerified(_session(phoneNumber));
      return;
    }
    onCodeSent(PhoneCodeDispatch(verificationId: phoneNumber));
    if (backend.sms == SmsBehaviour.autoRetrieved) {
      unawaited(
        Future<void>.delayed(
          backend.smsArrivalDelay + backend.confirmDelay,
          () => onVerified(_session(phoneNumber)),
        ),
      );
    }
  }

  @override
  Future<PhoneAuthSession> confirmCode({
    required String verificationId,
    required String smsCode,
    required bool linkCurrentUser,
  }) async {
    await Future<void>.delayed(backend.confirmDelay);
    if (backend.rejectedCodes.contains(smsCode)) {
      throw const PhoneAuthFailure('invalid-verification-code');
    }
    return _session(verificationId);
  }
}

class DeviceAuthRepository implements AuthRepository, AuthSessionResolver {
  DeviceAuthRepository(this.backend);
  final DeviceBackend backend;

  AuthUserData? get _user {
    final account = backend.accounts[backend.currentUid];
    if (account == null) return null;
    return AuthUserData(
      uid: account.uid,
      email: account.role == AppRole.teacher ? DeviceBackend.teacherEmail : '',
      role: account.role,
      firstName: account.name,
      lastName: '',
      profileCompleted: true,
    );
  }

  @override
  Future<AuthSessionResolution> resolveCurrentSession() async {
    await backend.network(backend.profileReadDelay);
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
      signInProviders: [
        if (backend.uidsByPhone.containsValue(uid)) 'phone',
        if (backend.identity.googleOf.containsKey(uid)) 'google.com',
      ],
    );
  }

  @override
  Future<AuthUserData?> getCurrentUser() async => _user;

  @override
  Future<AuthUserData> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(backend.confirmDelay + backend.profileReadDelay);
    final uid = backend.emailAccounts[email.trim()];
    if (uid == null || password != DeviceBackend.teacherPassword) {
      throw Exception('wrong credentials');
    }
    backend.currentUid = uid;
    return _user!;
  }

  @override
  Future<void> signOut() async => backend.currentUid = null;

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      Future<void>.delayed(backend.confirmDelay);

  @override
  Future<AuthUserData> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required AppRole role,
  }) => throw UnimplementedError();
}

/// Liaison par code comme le serveur : le code désigne un élève, le lien est
/// créé pour le parent connecté, idempotent.
class _LinkService extends ChildLinkService {
  _LinkService(this.backend);
  final DeviceBackend backend;

  @override
  Future<ChildLinkResult> linkChildByCode(String code) async {
    await backend.network(backend.confirmDelay);
    final parent = backend.currentUid;
    final studentUid = backend.linkCodes[code.trim().toUpperCase()];
    final student = backend.accounts[studentUid];
    if (parent == null || backend.accounts[parent]?.role != AppRole.parent) {
      throw const ChildLinkException('permission-denied');
    }
    if (studentUid == null || student == null) {
      throw const ChildLinkException('not-found');
    }
    final links = backend.parentLinks.putIfAbsent(parent, () => {});
    final already = !links.add(studentUid);
    return ChildLinkResult(
      studentId: studentUid,
      firstName: student.name,
      classLevel: 'Terminale',
      alreadyLinked: already,
    );
  }
}

/// Enfants liés au parent, lus comme le serveur les projette.
class DeviceParentRepository implements ParentRepository {
  DeviceParentRepository(this.backend);
  final DeviceBackend backend;

  @override
  Future<ParentDashboard> fetchDashboard({required String parentUid}) async {
    return ParentDashboard(
      children: [
        for (final uid in backend.parentLinks[parentUid] ?? const <String>{})
          if (backend.pendingChildren[uid] case final firstName?)
            ParentChildProfile(
              id: uid,
              firstName: firstName,
              classLevel: '',
              series: null,
              globalProgress: 0,
              studyMinutesToday: 0,
              studyMinutesTarget: 0,
              strongSubjects: const [],
              weakSubjects: const [],
              weeklyProgress: const [],
              access: const ChildAccessMethods(
                ownPhone: false,
                accessCode: true,
              ),
              pendingFirstSignIn: true,
            )
          else if (backend.accounts[uid] case final account?)
            ParentChildProfile(
              id: uid,
              firstName: account.name,
              establishmentName: backend.schoolOf[uid],
              classLevel: 'Terminale',
              series: null,
              globalProgress: 0,
              studyMinutesToday: 0,
              studyMinutesTarget: 45,
              strongSubjects: const [],
              weakSubjects: const [],
              weeklyProgress: const [],
              access: ChildAccessMethods(
                ownPhone: backend.uidsByPhone.containsValue(uid),
                accessCode: backend.accessCodes.containsValue(uid),
              ),
            ),
      ],
      announcements: const [],
    );
  }
}

class _RegistrationRepository implements RoleRegistrationRepository {
  _RegistrationRepository(this.backend);
  final DeviceBackend backend;

  @override
  Future<RoleRegistrationResult> registerParent(
    ParentRegistrationPayload payload,
  ) async {
    await Future<void>.delayed(backend.confirmDelay);
    final uid = backend.currentUid!;
    backend.accounts[uid] = DeviceAccount(
      uid: uid,
      role: AppRole.parent,
      name: payload.firstName,
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
  ) async {
    await Future<void>.delayed(backend.confirmDelay);
    backend.currentUid = 'new-teacher-uid';
    backend.accounts['new-teacher-uid'] = DeviceAccount(
      uid: 'new-teacher-uid',
      role: AppRole.teacher,
      name: payload.firstName,
    );
    return RoleRegistrationResult(
      uid: 'new-teacher-uid',
      email: payload.email,
      firstName: payload.firstName,
      lastName: payload.lastName,
      accountStatus: 'pending_validation',
    );
  }

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
