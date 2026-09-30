import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/profile/application/user_preferences_controller.dart';
import 'package:intellia237/features/profile/data/profile_repository.dart';
import 'package:intellia237/features/profile/presentation/edit_profile_screen.dart';
import 'package:intellia237/features/profile/presentation/settings_screen.dart';
import 'package:intellia237/features/profile/presentation/widgets/profile_surfaces.dart';
import 'package:intellia237/features/profile/services/profile_image_service.dart';
import 'package:intellia237/features/profile/widgets/avatar_picker_widget.dart';
import 'package:intellia237/features/profile/widgets/profile_avatar.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mastery/mastery_test_harness.dart';

class _ProfileRepo implements ProfileRepository {
  int writes = 0;
  bool offline = false;
  String? savedName;
  String? savedPhone;
  @override
  Future<EditableProfile> fetch(String userId) async => const EditableProfile(
    firstName: 'Amina',
    lastName: 'Ndi',
    email: 'amina@example.test',
    phoneNumber: '',
    photoUrl: null,
  );
  @override
  Future<void> update({
    required String userId,
    required AppRole role,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    if (offline) throw const ProfileUpdateException('Hors connexion');
    writes++;
    savedName = firstName;
    savedPhone = phoneNumber;
  }
}

class _Images implements ProfileImageService {
  int gallery = 0, camera = 0, uploads = 0, deletes = 0;
  bool offline = false;
  bool cancel = false;
  @override
  Future<Uint8List?> pickFromGallery() async {
    gallery++;
    return cancel ? null : File('assets/branding/logo.png').readAsBytesSync();
  }

  @override
  Future<Uint8List?> pickFromCamera() async {
    camera++;
    return cancel ? null : File('assets/branding/logo.png').readAsBytesSync();
  }

  @override
  Future<String?> uploadProfileImage(Uint8List imageBytes) async {
    uploads++;
    if (offline) throw StateError('offline');
    return 'https://example.test/avatar.png';
  }

  @override
  Future<void> deleteOldProfileImage() async {
    deletes++;
    if (offline) throw StateError('offline');
  }
}

void _readable(WidgetTester tester) {
  expect(tester.takeException(), isNull);
  for (final paragraph
      in tester.allRenderObjects.whereType<RenderParagraph>()) {
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: paragraph.text.toPlainText(),
    );
  }
}

Future<void> _scroll(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<ProviderContainer> _custom(
  WidgetTester tester,
  Widget body, {
  _ProfileRepo? repository,
}) async {
  await tester.runAsync(loadMasteryReviewFonts);
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(320, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      if (repository != null)
        profileRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  container
      .read(authControllerProvider.notifier)
      .setAuthenticatedUser(
        role: AppRole.student,
        userId: 'profile-test',
        firstName: 'Amina',
        email: 'amina@example.test',
      );
  await container.read(userPreferencesProvider.notifier).setReduceMotion(true);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'Manrope'),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.5)),
          child: child!,
        ),
        home: body,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  for (final language in ['fr', 'en']) {
    for (final width in [320.0, 360.0, 412.0, 480.0]) {
      testWidgets('real Profile $language $width text x2 offline', (
        tester,
      ) async {
        await pumpMasteryHarness(
          tester,
          language: language,
          width: width,
          textScale: 2,
          reduced: true,
        );
        expect(
          find.byKey(const ValueKey('profile-identity-card')),
          findsOneWidget,
        );
        expect(find.text('INTELLIA PASS'), findsOneWidget);
        expect(find.text('Amina'), findsOneWidget);
        _readable(tester);
        final end = find.text(language == 'fr' ? 'Se déconnecter' : 'Sign out');
        await _scroll(tester, end);
        _readable(tester);
      });
      testWidgets('Settings $language $width text x2 offline', (tester) async {
        await pumpMasteryHarness(
          tester,
          content: const SettingsScreen(),
          language: language,
          width: width,
          textScale: 2,
          reduced: true,
        );
        expect(find.byType(CupertinoSlider), findsOneWidget);
        _readable(tester);
        await _scroll(
          tester,
          find.byKey(const ValueKey('settings-parent-space')),
        );
        _readable(tester);
        expect(find.byType(IntelliaProfileSection), findsWidgets);
      });
    }
  }

  testWidgets(
    'Cupertino switches persist actual accessibility/data preferences',
    (tester) async {
      final container = await pumpMasteryHarness(
        tester,
        content: const SettingsScreen(),
      );
      for (final icon in [
        Icons.animation_rounded,
        Icons.data_saver_on_rounded,
        Icons.monitor_heart_outlined,
      ]) {
        final tile = find.byWidgetPredicate(
          (w) => w is IntelliaProfileSwitch && w.icon == icon,
        );
        await _scroll(tester, tile);
        await tester.tap(
          find.descendant(of: tile, matching: find.byType(CupertinoSwitch)),
        );
        await tester.pumpAndSettle();
      }
      final prefs = container.read(userPreferencesProvider);
      expect(prefs.reduceMotion, isTrue);
      expect(prefs.dataSaver, isTrue);
      expect(prefs.diagnostics, isTrue);
      final stored = await SharedPreferences.getInstance();
      expect(stored.getBool('preferences_data_saver'), isTrue);
      _readable(tester);
    },
  );

  testWidgets(
    'Cupertino editor saves validated fields and keeps email immutable',
    (tester) async {
      final repo = _ProfileRepo();
      final container = await _custom(
        tester,
        const EditProfileScreen(),
        repository: repo,
      );
      expect(find.byType(CupertinoTextFormFieldRow), findsNWidgets(3));
      expect(find.text('amina@example.test'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('profile-first-name')),
        'Amina Rose',
      );
      await tester.enterText(
        find.byKey(const ValueKey('profile-phone')),
        '699000000',
      );
      final save = find.byKey(const ValueKey('profile-save'));
      await _scroll(tester, save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repo.writes, 1);
      expect(repo.savedName, 'Amina Rose');
      expect(repo.savedPhone, '699000000');
      expect(container.read(authControllerProvider).firstName, 'Amina Rose');
      _readable(tester);
    },
  );

  testWidgets(
    'failed offline edit keeps entered data and reports the failure',
    (tester) async {
      final repo = _ProfileRepo()..offline = true;
      final container = await _custom(
        tester,
        const EditProfileScreen(),
        repository: repo,
      );
      await tester.enterText(
        find.byKey(const ValueKey('profile-first-name')),
        'Amina Rose',
      );
      final save = find.byKey(const ValueKey('profile-save'));
      await _scroll(tester, save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('Hors connexion'), findsOneWidget);
      expect(container.read(authControllerProvider).firstName, 'Amina');
      expect(repo.writes, 0);
      _readable(tester);
    },
  );

  for (final camera in [false, true]) {
    testWidgets('avatar ${camera ? 'camera' : 'gallery'} failure rolls back', (
      tester,
    ) async {
      final service = _Images()..offline = true;
      String? uploaded;
      await _custom(
        tester,
        Scaffold(
          body: Center(
            child: AvatarPickerWidget(
              service: service,
              onUploaded: (url) => uploaded = url,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('profile-avatar-picker')));
      await tester.pump();
      final sheetContext = tester.element(find.byType(CupertinoActionSheet));
      expect(ModalRoute.of(sheetContext)!.transitionDuration, Duration.zero);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      await tester.tap(
        find.text(camera ? 'Prendre une photo' : 'Choisir depuis la galerie'),
      );
      await tester.pumpAndSettle();
      expect(service.uploads, 1);
      expect(uploaded, isNull);
      expect(
        tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).image,
        isNull,
        reason: 'an unsaved local preview is removed',
      );
      _readable(tester);
    });
  }

  testWidgets('cancelled avatar picker leaves identity unchanged', (
    tester,
  ) async {
    final service = _Images()..cancel = true;
    await _custom(tester, Scaffold(body: AvatarPickerWidget(service: service)));
    await tester.tap(find.byKey(const ValueKey('profile-avatar-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choisir depuis la galerie'));
    await tester.pumpAndSettle();
    expect(service.uploads, 0);
    _readable(tester);
  });

  testWidgets('optional real-font Profile capture at 412px', (tester) async {
    final directory = Platform.environment['PROFILE_CAPTURE_DIR'];
    if (directory == null) return;
    final key = GlobalKey();
    await pumpMasteryHarness(tester, width: 412, captureKey: key);
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(directory).createSync(recursive: true);
      File(
        '$directory/profile_412.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
