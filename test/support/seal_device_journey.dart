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
import 'package:intellia237/core/animations/app_page_transitions.dart';
import 'package:intellia237/core/localization/app_locale_controller.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/data/auth_entry_preferences.dart';
import 'package:intellia237/features/auth/data/repositories/firebase_phone_auth_repository.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/auth/domain/repositories/phone_auth_repository.dart';
import 'package:intellia237/features/auth/presentation/auth_gateway_screen.dart';
import 'package:intellia237/features/auth/presentation/forgot_password_screen.dart';
import 'package:intellia237/features/auth/presentation/login_screen.dart';
import 'package:intellia237/features/auth/presentation/phone_auth_screen.dart';
import 'package:intellia237/features/auth/presentation/register_screen.dart';
import 'package:intellia237/features/auth/presentation/widgets/auth_experience_scaffold.dart';
import 'package:intellia237/features/auth/presentation/widgets/intellia_237_membrane.dart';
import 'package:intellia237/features/auth/presentation/widgets/pass_home_arrival.dart';
import 'package:intellia237/features/notifications/data/notification_repository.dart';
import 'package:intellia237/features/onboarding/data/onboarding_preferences.dart';
import 'package:intellia237/features/parent/application/parent_providers.dart';
import 'package:intellia237/features/parent/data/child_link_service.dart';
import 'package:intellia237/features/parent/data/parent_repository.dart';
import 'package:intellia237/features/parent/domain/parent_dashboard.dart';
import 'package:intellia237/features/parent/presentation/parent_entry_screen.dart';
import 'package:intellia237/features/parent_registration/presentation/parent_registration_screen.dart';
import 'package:intellia237/features/role_registration/data/firebase_role_registration_repository.dart';
import 'package:intellia237/features/role_registration/data/role_registration_repository.dart';
import 'package:intellia237/features/role_registration/domain/admin_registration_payload.dart';
import 'package:intellia237/features/role_registration/domain/parent_registration_payload.dart';
import 'package:intellia237/features/role_registration/domain/registration_result.dart';
import 'package:intellia237/features/role_registration/domain/teacher_registration_payload.dart';
import 'package:intellia237/features/student_registration/presentation/student_registration_flow_screen.dart';
import 'package:intellia237/features/teacher_registration/presentation/teacher_registration_screen.dart';
import 'package:intellia237/features/tour_guide/data/firestore_tour_guide_repository.dart';
import 'package:intellia237/features/tour_guide/data/tour_guide_repository.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

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
  );

  final WidgetTester tester;
  final ProviderContainer container;
  final GoRouter router;
  final SealTrace trace;
  final SealDevice device;

  static Future<SealJourney> start(
    WidgetTester tester,
    DeviceBackend backend, {
    String initialLocation = AppRoutes.authGateway,
    Locale locale = const Locale('fr'),
    bool reduceMotion = false,
    String? signedInPhone,
    ThemeData? theme,
    SealDevice device = SealDevice.midRange,
  }) async {
    tester.view.physicalSize = device.physicalSize;
    tester.view.devicePixelRatio = device.pixelRatio;
    // Barre d'état d'un téléphone à caméra poinçonnée.
    tester.view.padding = FakeViewPadding(top: 32 * device.pixelRatio);
    addTearDown(tester.view.reset);
    if (signedInPhone != null) backend.signInWithPhone(signedInPhone);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(DeviceAuthRepository(backend)),
        phoneAuthRepositoryProvider.overrideWithValue(
          DevicePhoneRepository(backend),
        ),
        childLinkServiceProvider.overrideWithValue(_LinkService(backend)),
        parentRepositoryProvider.overrideWithValue(_ParentRepository()),
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
    // Le démarrage se lit sans délai : hors pompage, le temps simulé des
    // tests ne s'écoule pas.
    backend.networkDelays = false;
    await container.read(authControllerProvider.notifier).completeBootstrap();
    backend.networkDelays = true;

    final notifier = container.read(_routerNotifierProvider);
    Widget home(String label) => Material(
      color: AuthExperienceColors.canvas,
      child: Center(child: Text(label)),
    );
    Page<void> page(GoRouterState state, Widget child) =>
        buildAppTransitionPage(state: state, child: child);

    final router = GoRouter(
      initialLocation: initialLocation,
      refreshListenable: notifier,
      redirect: notifier.redirect,
      routes: [
        GoRoute(
          path: AppRoutes.bootstrap,
          pageBuilder: (_, state) => page(state, home('bootstrap')),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          pageBuilder: (_, state) => page(state, home('onboarding')),
        ),
        GoRoute(
          path: AppRoutes.authGateway,
          pageBuilder: (_, state) => page(state, const AuthGatewayScreen()),
        ),
        GoRoute(
          path: AppRoutes.login,
          pageBuilder: (_, state) => page(state, const PhoneAuthScreen()),
        ),
        GoRoute(
          path: AppRoutes.emailLogin,
          pageBuilder: (_, state) => page(
            state,
            LoginScreen(authIntent: AppRoutes.entryIntentFrom(state.uri)),
          ),
        ),
        GoRoute(
          path: AppRoutes.phoneAuth,
          pageBuilder: (_, state) => page(
            state,
            PhoneAuthScreen(
              authIntent: AppRoutes.entryIntentFrom(state.uri),
              linkCurrentUser: state.uri.queryParameters['mode'] == 'link',
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.parentEntry,
          pageBuilder: (_, state) => page(state, const ParentEntryScreen()),
        ),
        GoRoute(
          path: AppRoutes.register,
          pageBuilder: (_, state) => buildAppTransitionPage(
            state: state,
            transitionBackground: const AuthAmbientBackground(),
            child: const RegisterScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.studentRegistration,
          pageBuilder: (_, state) =>
              page(state, const StudentRegistrationFlowScreen()),
        ),
        GoRoute(
          path: AppRoutes.parentRegistration,
          pageBuilder: (_, state) =>
              page(state, const ParentRegistrationScreen()),
        ),
        GoRoute(
          path: AppRoutes.teacherRegistration,
          pageBuilder: (_, state) =>
              page(state, const TeacherRegistrationScreen()),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          pageBuilder: (_, state) => page(state, const ForgotPasswordScreen()),
        ),
        for (final path in [
          AppRoutes.adminRegistration,
          AppRoutes.authProfileRecovery,
          AppRoutes.adminHome,
          AppRoutes.tutorSelection,
        ])
          GoRoute(
            path: path,
            pageBuilder: (_, state) => page(state, home(path)),
          ),
        for (final (path, role) in const [
          (AppRoutes.studentHome, AppRole.student),
          (AppRoutes.parentHome, AppRole.parent),
          (AppRoutes.teacherHome, AppRole.teacher),
        ])
          GoRoute(
            path: path,
            pageBuilder: (_, state) => buildPassHomePage(
              state: state,
              role: role,
              duration: notifier.homeArrivalDuration,
              child: home(path),
            ),
          ),
      ],
    );
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
    journey = SealJourney._(tester, container, router, trace, device);
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
      trace.sample(tester, frame);
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

  Future<void> tap(String key) => tapFinder(find.byKey(ValueKey(key)));

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
  String? currentUid;

  void createPhoneAccount(String phone, String uid, AppRole role, String name) {
    uidsByPhone['+237$phone'] = uid;
    accounts[uid] = DeviceAccount(uid: uid, role: role, name: name);
  }

  void signInWithPhone(String e164OrLocal) {
    final key = e164OrLocal.startsWith('+') ? e164OrLocal : '+237$e164OrLocal';
    currentUid = uidsByPhone.putIfAbsent(key, () => 'uid-$key');
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

final _routerNotifierProvider = Provider<AppRouterNotifier>((ref) {
  final notifier = AppRouterNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

class _LinkService extends ChildLinkService {
  _LinkService(this.backend);
  final DeviceBackend backend;

  @override
  Future<ChildLinkResult> linkChildByCode(String code) async =>
      const ChildLinkResult(
        studentId: 'student-Awa',
        firstName: 'Awa',
        classLevel: '3eme',
        alreadyLinked: false,
      );
}

class _ParentRepository implements ParentRepository {
  @override
  Future<ParentDashboard> fetchDashboard({required String parentUid}) async =>
      const ParentDashboard(children: [], announcements: []);
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
