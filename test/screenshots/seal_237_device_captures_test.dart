@Tags(['screenshots'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/presentation/widgets/intellia_237_membrane.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/intellia_fonts.dart';
import '../support/seal_device_journey.dart';

/// Captures de **rendu réel** du sceau « 237 » sur les écrans d'authentification,
/// à la densité d'un Android courant (1080 × 2400, 2,625), clavier simulé.
///
/// Ce ne sont pas des captures de téléphone : ni le clavier, ni la barre
/// d'état n'y sont peints. Elles montrent ce que le moteur Flutter peint à
/// chaque étape du parcours, polices livrées comprises.
///
/// Inerte par défaut. Pour produire les fichiers :
///   flutter test test/screenshots/seal_237_device_captures_test.dart \
///     --dart-define=INTELLIA_SCREENSHOTS=true
const _enabled = bool.fromEnvironment('INTELLIA_SCREENSHOTS');

const _outputDirectory =
    r'C:\projets\FlutterProjects\Intellia237_artifacts\device-qa-round-3-seal-237';

void main() {
  if (!_enabled) {
    test('captures désactivées (--dart-define=INTELLIA_SCREENSHOTS=true)', () {
      expect(_enabled, isFalse);
    });
    return;
  }

  final rects = <String, Map<String, Object>>{};

  setUpAll(() async {
    await loadIntelliaFonts();
    const iconFont =
        r'C:\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf';
    if (File(iconFont).existsSync()) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(File(iconFont).readAsBytes().then(ByteData.sublistView));
      await icons.load();
    }
    Directory(_outputDirectory).createSync(recursive: true);
  });
  setUp(() => SharedPreferences.setMockInitialValues(const {}));
  tearDownAll(() {
    File(
      '$_outputDirectory/seal_rects.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rects));
  });

  final theme = ThemeData(useMaterial3: true, fontFamily: 'CampaignBody');

  Future<void> shot(SealJourney journey, String name) async {
    final seals = find.byKey(Intellia237Membrane.paintKey);
    final seal = journey.seal;
    if (seals.evaluate().isNotEmpty) {
      final rect = journey.tester.getRect(seals.first);
      rects[name] = {
        'route': journey.location,
        'stage': seal?.stage.name ?? '-',
        'left': rect.left,
        'top': rect.top,
        'width': rect.width,
        'height': rect.height,
      };
    }
    await journey.capture('$_outputDirectory/$name.png');
  }

  Future<void> end(SealJourney journey) async {
    await journey.tester.pumpWidget(const SizedBox.shrink());
    journey.container.dispose();
    await journey.tester.pump(const Duration(seconds: 9));
  }

  testWidgets('téléphone : numéro, code tapé, sceau complet, accueil', (
    tester,
  ) async {
    final journey = await SealJourney.start(
      tester,
      DeviceBackend(),
      theme: theme,
    );
    await journey.tap('gateway-role-parent');
    await journey.tap('parent-entry-existing');
    await journey.wait(const Duration(milliseconds: 500));
    await shot(journey, '01_neutre_numero_vide');
    await journey.typeKey('phone-number-field', '6770000');
    await shot(journey, '02_neutre_numero_partiel_clavier');
    await journey.typeKey(
      'phone-number-field',
      DeviceBackend.parentPhone,
      from: 7,
    );
    await journey.wait(const Duration(milliseconds: 400));
    await shot(journey, '03_2vert_numero_valide_clavier');
    await journey.tap('send-phone-code');
    await journey.wait(const Duration(milliseconds: 600));
    await shot(journey, '04_2vert_envoi_du_sms');
    await journey.waitUntil(
      () => find.byKey(const ValueKey('phone-otp-field')).evaluate().isNotEmpty,
    );
    await journey.wait(const Duration(milliseconds: 800));
    await journey.typeKey('phone-otp-field', '123');
    await shot(journey, '05_2vert_code_partiel_clavier');
    await journey.typeKey('phone-otp-field', '123456', from: 3);
    await journey.wait(const Duration(milliseconds: 500));
    await shot(journey, '06_3rouge_code_complet');
    await journey.waitUntil(
      () => journey.seal?.stage == PassSealStage.verified,
    );
    await journey.wait(const Duration(milliseconds: 600));
    await shot(journey, '07_237_complet_ecran_telephone');
    await journey.waitUntil(() => journey.location == AppRoutes.parentHome);
    await journey.wait(const Duration(milliseconds: 1200));
    await shot(journey, '08_237_complet_accueil_parent');
    await end(journey);
  });

  testWidgets('SMS lu par Android : le 3 rouge seul, puis le 7', (
    tester,
  ) async {
    final backend = DeviceBackend()..sms = SmsBehaviour.autoRetrieved;
    final journey = await SealJourney.start(tester, backend, theme: theme);
    await journey.tap('gateway-role-student');
    await journey.wait(const Duration(milliseconds: 400));
    await journey.typeKey('phone-number-field', DeviceBackend.studentPhone);
    await journey.tap('send-phone-code');
    await journey.waitUntil(() => journey.seal?.stage == PassSealStage.secret);
    await journey.wait(const Duration(milliseconds: 320));
    await shot(journey, '09_3rouge_sms_lu_par_android');
    await journey.waitUntil(
      () => journey.seal?.stage == PassSealStage.verified,
    );
    await journey.wait(const Duration(milliseconds: 600));
    await shot(journey, '10_237_complet_sms_lu_par_android');
    await journey.waitUntil(() => journey.location == AppRoutes.studentHome);
    await end(journey);
  });

  testWidgets('e-mail : adresse, mot de passe, sceau complet', (tester) async {
    final journey = await SealJourney.start(
      tester,
      DeviceBackend(),
      theme: theme,
    );
    await journey.tap('gateway-role-teacher');
    await journey.wait(const Duration(milliseconds: 400));
    final email = find.descendant(
      of: find.byKey(const ValueKey('login-email-field')),
      matching: find.byType(TextField),
    );
    final password = find.descendant(
      of: find.byKey(const ValueKey('login-password-field')),
      matching: find.byType(TextField),
    );
    await journey.type(email, DeviceBackend.teacherEmail);
    await journey.type(password, DeviceBackend.teacherPassword);
    await journey.wait(const Duration(milliseconds: 400));
    await shot(journey, '11_2vert_3rouge_email_clavier');
    await journey.tap('login-submit');
    await journey.waitUntil(
      () => journey.seal?.stage == PassSealStage.verified,
    );
    await journey.wait(const Duration(milliseconds: 600));
    await shot(journey, '12_237_complet_connexion_email');
    await journey.waitUntil(() => journey.location == AppRoutes.teacherHome);
    await end(journey);
  });
}
