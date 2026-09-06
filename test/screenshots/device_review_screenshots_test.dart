@Tags(['screenshots'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/features/ai_companion/data/speech_services.dart';
import 'package:intellia237/features/ai_companion/domain/ai_message.dart';
import 'package:intellia237/features/ai_companion/presentation/widgets/chat_bubble.dart';
import 'package:intellia237/features/ai_companion/presentation/widgets/companion_composer.dart';
import 'package:intellia237/features/auth/presentation/widgets/auth_experience_scaffold.dart';
import 'package:intellia237/features/learn/domain/curriculum_catalog.dart';
import 'package:intellia237/features/learn/domain/learn_subject.dart';
import 'package:intellia237/features/mastery/domain/mastery_estimate.dart';
import 'package:intellia237/features/mastery/presentation/mastery_subject_card.dart';
import 'package:intellia237/features/student_registration/domain/academic_rules.dart';
import 'package:intellia237/features/student_registration/presentation/widgets/companion_discovery.dart';
import 'package:intellia237/features/tutor/domain/tutor_persona.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Génère des captures de **rendu réel** des écrans corrigés.
///
/// Ces images sortent du moteur Flutter peignant l'arbre de widgets de
/// production, polices du projet comprises — ce ne sont pas des maquettes.
/// Elles ne remplacent pas pour autant une capture sur téléphone : le shell
/// Android, la barre d'état et les marges système n'y figurent pas.
///
/// Inerte par défaut. Pour produire les fichiers :
///   flutter test test/screenshots --dart-define=INTELLIA_SCREENSHOTS=1
const _enabled = bool.fromEnvironment('INTELLIA_SCREENSHOTS');

const _outputDirectory =
    r'C:\projets\FlutterProjects\Intellia237_artifacts\device-review-round-1';

Future<void> _loadProjectFonts() async {
  // Sans polices réelles, le moteur de test dessine des rectangles : les
  // captures ne montreraient rien de lisible.
  GoogleFonts.config.allowRuntimeFetching = false;
  for (final family in const {
    'Manrope': ['Manrope-400', 'Manrope-600', 'Manrope-700', 'Manrope-800'],
    'Montserrat': [
      'Montserrat-400',
      'Montserrat-600',
      'Montserrat-700',
      'Montserrat-800',
    ],
    'Playfair Display': ['PlayfairDisplay-400', 'PlayfairDisplay-700'],
  }.entries) {
    final loader = FontLoader(family.key);
    for (final file in family.value) {
      loader.addFont(
        File('assets/fonts/$file.ttf').readAsBytes().then(ByteData.sublistView),
      );
    }
    await loader.load();
  }
}

void main() {
  if (!_enabled) {
    test('captures désactivées (--dart-define=INTELLIA_SCREENSHOTS=1)', () {
      expect(_enabled, isFalse);
    });
    return;
  }

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadProjectFonts();
    Directory(_outputDirectory).createSync(recursive: true);
  });

  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  Future<void> capture(
    WidgetTester tester,
    String name, {
    required Widget child,
    Size size = const Size(390, 844),
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          theme: ThemeData(useMaterial3: true, fontFamily: 'Manrope'),
          home: MediaQuery(
            data: MediaQueryData(size: size, disableAnimations: true),
            child: RepaintBoundary(key: boundaryKey, child: child),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    File(
      '$_outputDirectory/$name',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  Widget surface(Widget child) => Scaffold(
    backgroundColor: const Color(0xFFFBF8F1),
    body: SafeArea(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );

  testWidgets('01 découverte de Kira', (tester) async {
    await capture(
      tester,
      '01_companion_onboarding_kira.png',
      child: const Scaffold(
        backgroundColor: AuthExperienceColors.canvas,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: SingleChildScrollView(child: CompanionDiscovery()),
          ),
        ),
      ),
    );
  });

  testWidgets('04 composeur au repos', (tester) async {
    await capture(
      tester,
      '04_companion_chat_rest.png',
      overrides: [
        speechRecognizerProvider.overrideWithValue(_IdleRecognizer()),
      ],
      child: surface(
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CompanionComposer(
              controller: TextEditingController(),
              onSubmit: () {},
              enabled: true,
              companionName: 'Kira',
              accentColor: TutorPersona.all.first.accentColor,
            ),
          ],
        ),
      ),
    );
  });

  testWidgets('05 « Parler » devient « Envoyer »', (tester) async {
    await capture(
      tester,
      '05_companion_chat_typing.png',
      overrides: [
        speechRecognizerProvider.overrideWithValue(_IdleRecognizer()),
      ],
      child: surface(
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CompanionComposer(
              controller: TextEditingController(
                text: 'Explique-moi le discriminant',
              ),
              onSubmit: () {},
              enabled: true,
              companionName: 'Kira',
              accentColor: TutorPersona.all.first.accentColor,
            ),
          ],
        ),
      ),
    );
  });

  testWidgets('07 réponse riche et fil d’encre', (tester) async {
    final kira = TutorPersona.all.first;
    final leo = TutorPersona.all.last;
    await capture(
      tester,
      '07_companion_rich_answer.png',
      child: surface(
        ListView(
          children: [
            ChatBubble(
              message: AIMessage(
                id: 'u1',
                role: AIMessageRole.user,
                text: 'Explique-moi le discriminant.',
                createdAt: DateTime(2026, 9, 6, 14, 30),
              ),
              tutor: kira,
            ),
            ChatBubble(
              message: AIMessage(
                id: 'a1',
                role: AIMessageRole.assistant,
                companionId: 'kira',
                createdAt: DateTime(2026, 9, 6, 14, 31),
                text:
                    '### Le discriminant\n'
                    'Pour une équation **ax² + bx + c = 0**, on calcule '
                    'Δ = b² − 4ac.\n\n'
                    '- Si Δ > 0, il y a *deux* solutions.\n'
                    '- Si Δ = 0, il y a une solution double.\n'
                    '- Si Δ < 0, il n’y a pas de solution réelle.\n\n'
                    '1. Repère a, b et c.\n'
                    '2. Calcule Δ.\n'
                    '3. Conclus selon son signe.\n\n'
                    '> Le signe de Δ décide de tout.\n',
              ),
              tutor: kira,
            ),
            // Le passé garde son auteur après un changement de compagnon.
            ChatBubble(
              message: AIMessage(
                id: 'a2',
                role: AIMessageRole.assistant,
                companionId: 'leo',
                createdAt: DateTime(2026, 9, 6, 14, 35),
                text: 'On enchaîne ? Calcule Δ pour x² − 5x + 6 = 0.',
              ),
              tutor: leo,
            ),
          ],
        ),
      ),
    );
  });

  testWidgets('08 matières du programme sans preuve', (tester) async {
    final subjects = CurriculumCatalog.forLevel(
      schoolClass: SchoolClass.terminale,
      series: SchoolSeries.d,
    );
    await capture(
      tester,
      '08_profile_subjects.png',
      child: surface(
        ListView(
          children: [
            for (final subject in subjects.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MasterySubjectCard(
                  subject: LearnSubject(
                    id: subject.id,
                    title: subject.frenchLabel,
                    description: '',
                    colorHex: subject.colorHex,
                    iconKey: subject.iconKey,
                    chapters: const [],
                  ),
                  estimate: MasteryEstimate(entityId: subject.id),
                ),
              ),
          ],
        ),
      ),
    );
  });
}

/// Reconnaissance vocale inerte : les captures ne demandent aucun micro.
class _IdleRecognizer implements SpeechRecognizer {
  @override
  bool get isAvailable => true;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> listen({
    required String localeId,
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(double level) onSoundLevel,
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}
