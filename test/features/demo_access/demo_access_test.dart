import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/widgets/tab_presentation.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/presentation/student_access_code_screen.dart';
import 'package:intellia237/features/demo_access/application/demo_access_providers.dart';
import 'package:intellia237/features/demo_access/domain/demo_access.dart';
import 'package:intellia237/features/demo_access/presentation/demo_access_card.dart';
import 'package:intellia237/features/family_access/domain/family_access_models.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/features/student_registration/domain/academic_rules.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

// Code fictif : le vrai code d'invitation vit dans Secret Manager, jamais
// dans le dépôt.
const _invitation = 'INVITE2026';

void main() {
  group('saisie du code', () {
    test('un code d’invitation est accepté et part vers l’accès démo', () {
      expect(StudentAccessCodeFormat.isInvitation(_invitation), isTrue);
      expect(StudentAccessCodeFormat.isAcceptable(' invite 2026 '), isTrue);
      expect(
        StudentAccessCodeFormat.callableFor(_invitation),
        'signInWithDemoAccessCode',
      );
      // Un code élève garde son service.
      expect(StudentAccessCodeFormat.isWellFormed('ABCD-EFGH-JKMN'), isTrue);
      expect(
        StudentAccessCodeFormat.callableFor('ABCD-EFGH-JKMN'),
        'signInWithStudentAccessCode',
      );
      for (final refused in ['', 'AB12', 'ÉCOLE2026', 'INVITE-2026!']) {
        expect(
          StudentAccessCodeFormat.isAcceptable(refused),
          isFalse,
          reason: refused,
        );
      }
    });

    test('le champ garde les O et les I d’un code d’invitation', () {
      const formatter = StudentAccessCodeInputFormatter();
      final value = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: 'solo io 2026'),
      );
      expect(value.text, 'SOLO-IO20-26');
      expect(StudentAccessCodeFormat.normalize(value.text), 'SOLOIO2026');
    });

    test('l’application ne connaît aucun code d’invitation', () {
      // Le code est vérifié côté serveur seulement : le client n'en garde
      // aucune copie, ni le nom du secret qui le contient.
      final source = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .map((file) => file.readAsStringSync())
          .join('\n');
      expect(source, isNot(contains('DEMO_ACCESS_CODE')));
      expect(source, isNot(contains('isDemoCode')));
    });
  });

  group('classes', () {
    test('toutes les classes, chaque série à part, Terminale D en tête', () {
      final options = DemoAccess.options;
      expect(options, hasLength(19));
      expect(options.first.label, '6ème');
      expect(options.last.label, 'Upper Sixth');
      expect(DemoAccess.recommended.label, 'Terminale D');
      expect(DemoAccess.recommended.classLevel, 'Terminale');
      expect(DemoAccess.recommended.seriesValue, 'D');
      expect(options.map((o) => o.label), contains('2nde C'));
      expect(options.map((o) => o.label), isNot(contains('2nde D')));
    });

    test('la classe enregistrée est reconnue', () {
      expect(DemoAccess.optionFor('Terminale', 'D'), DemoAccess.recommended);
      expect(
        DemoAccess.optionFor('Premiere', 'c'),
        const DemoClassOption(SchoolClass.premiere, SchoolSeries.c),
      );
      expect(
        DemoAccess.optionFor('6eme', null),
        const DemoClassOption(SchoolClass.sixieme),
      );
      expect(DemoAccess.optionFor('Terminale', null), isNull);
    });
  });

  group('message d’accueil', () {
    test('tutoiement, Calvin EKENA, Terminale D', () {
      final fr =
          jsonDecode(File('lib/l10n/app_fr.arb').readAsStringSync())
              as Map<String, dynamic>;
      final demo = {
        for (final entry in fr.entries)
          if (entry.key.startsWith('demo') && entry.value is String)
            entry.key: entry.value as String,
      };
      expect(demo, isNotEmpty);
      for (final entry in demo.entries) {
        expect(
          entry.value,
          isNot(matches(RegExp(r'\b(vous|votre|vos)\b', caseSensitive: false))),
          reason: entry.key,
        );
      }
      expect(demo['demoWelcomeBody'], contains('Calvin EKENA'));
      expect(demo['demoWelcomeBody'], contains('accès exclusif'));
      expect(demo['demoWelcomeTip'], contains('Terminale D'));
      expect(demo['demoWelcomeStart'], 'Commencer par la Terminale D');
    });

    testWidgets('s’ouvre une seule fois, et « Commencer » garde la '
        'Terminale D', (tester) async {
      final harness = await _pump(tester);
      expect(find.byKey(const ValueKey('demo-welcome')), findsOneWidget);
      expect(find.text('Bienvenue dans INTELLIA237 !'), findsOneWidget);
      final welcome = find.byKey(const ValueKey('demo-welcome'));
      expect(
        find.descendant(
          of: welcome,
          matching: find.textContaining('Calvin EKENA'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: welcome,
          matching: find.textContaining('commence par la Terminale D'),
        ),
        findsOneWidget,
      );
      expect(harness.memory.marked, isTrue);

      await tester.tap(find.byKey(const ValueKey('demo-welcome-start')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('demo-welcome')), findsNothing);
      // Déjà en Terminale D : rien à changer.
      expect(harness.service.calls, isEmpty);
      expect(find.text('Tu explores la classe : Terminale D'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('« Commencer » ramène en Terminale D une autre classe', (
      tester,
    ) async {
      final harness = await _pump(tester, classLevel: '6eme', series: null);
      await tester.tap(find.byKey(const ValueKey('demo-welcome-start')));
      await tester.pumpAndSettle();
      expect(harness.service.calls, [DemoAccess.recommended]);
      expect(
        find.text(
          'C\'est parti : tu explores maintenant la classe Terminale D.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('déjà vu sur l’appareil : pas de message', (tester) async {
      await _pump(tester, seen: true);
      expect(find.byKey(const ValueKey('demo-welcome')), findsNothing);
      expect(find.byKey(const ValueKey('demo-access-card')), findsOneWidget);
    });

    testWidgets('un autre compte ne voit rien', (tester) async {
      final harness = await _pump(tester, uid: 'student-a');
      expect(find.byKey(const ValueKey('demo-access-card')), findsNothing);
      expect(find.byKey(const ValueKey('demo-welcome')), findsNothing);
      expect(harness.memory.marked, isFalse);
    });
  });

  group('changer de classe', () {
    testWidgets('depuis la carte : toutes les classes, Terminale D en avant', (
      tester,
    ) async {
      final harness = await _pump(tester, seen: true);
      await tester.tap(find.byKey(const ValueKey('demo-access-change')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('demo-class-picker')), findsOneWidget);
      expect(find.text('Quelle classe veux-tu explorer ?'), findsOneWidget);
      expect(find.text('En cours'), findsOneWidget);

      final premiere = find.byKey(const ValueKey('demo-class-Premiere-C'));
      await tester.scrollUntilVisible(
        premiere,
        200,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('demo-class-picker')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(premiere);
      await tester.pumpAndSettle();
      expect(harness.service.calls, [
        const DemoClassOption(SchoolClass.premiere, SchoolSeries.c),
      ]);
      expect(
        find.text('C\'est parti : tu explores maintenant la classe 1ère C.'),
        findsOneWidget,
      );
    });

    testWidgets('échec du serveur : un message clair', (tester) async {
      final harness = await _pump(tester, seen: true, failing: true);
      await tester.tap(find.byKey(const ValueKey('demo-access-change')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('demo-class-Terminale-D')).first,
      );
      await tester.pumpAndSettle();
      expect(harness.service.calls, hasLength(1));
      expect(
        find.text(
          'Impossible de changer de classe pour le moment. Réessaie dans un instant.',
        ),
        findsOneWidget,
      );
    });
  });

  group('responsive', () {
    testWidgets('360 dp × 1.5 : la carte reste lisible', (tester) async {
      await _pump(tester, seen: true, textScale: 1.5);
      expect(find.byKey(const ValueKey('demo-access-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('demo-access-change')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final size in const [Size(320, 640), Size(412, 915)]) {
      for (final scale in const [1.0, 1.3]) {
        testWidgets('${size.width.toInt()} dp × $scale : accueil, carte et '
            'choix sans débordement', (tester) async {
          await _pump(tester, size: size, textScale: scale);
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(
            find.byKey(const ValueKey('demo-welcome-other')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('demo-welcome-other')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('demo-class-picker')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.tapAt(const Offset(10, 10));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('demo-access-card')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}

class _Auth extends AuthController {
  _Auth(this.uid);

  final String uid;

  @override
  AuthState build() => AuthState.authenticated(
    role: AppRole.student,
    userId: uid,
    firstName: 'Invité',
  );
}

class _Service implements DemoAccessService {
  _Service({this.failing = false});

  final bool failing;
  final calls = <DemoClassOption>[];

  @override
  Future<void> setClass(DemoClassOption option) async {
    calls.add(option);
    if (failing) throw StateError('hors ligne');
  }
}

class _Memory implements DemoWelcomeMemory {
  _Memory({required this.alreadySeen});

  final bool alreadySeen;
  bool marked = false;

  @override
  Future<bool> seen() async => alreadySeen;

  @override
  Future<void> markSeen() async => marked = true;
}

class _Harness {
  _Harness(this.service, this.memory);

  final _Service service;
  final _Memory memory;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  String uid = DemoAccess.uid,
  String classLevel = 'Terminale',
  String? series = 'D',
  bool seen = false,
  bool failing = false,
  Size size = const Size(360, 740),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final service = _Service(failing: failing);
  final memory = _Memory(alreadySeen: seen);
  var current = LearnAcademicContext(classLevel: classLevel, series: series);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _Auth(uid)),
        demoAccessServiceProvider.overrideWithValue(
          _RecordingService(service, (option) {
            current = LearnAcademicContext(
              classLevel: option.classLevel,
              series: option.seriesValue,
            );
          }),
        ),
        demoWelcomeMemoryProvider.overrideWithValue(memory),
        studentAcademicContextProvider.overrideWith((ref) async => current),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Scaffold(
          body: TabSurface(
            palette: TabPalette(TabPresentationMode.embeddedLight),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: DemoAccessCard(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(service, memory);
}

/// Le service réel écrit le profil ; ici, la classe « enregistrée » suit.
class _RecordingService implements DemoAccessService {
  _RecordingService(this.inner, this.onSaved);

  final _Service inner;
  final void Function(DemoClassOption option) onSaved;

  @override
  Future<void> setClass(DemoClassOption option) async {
    await inner.setClass(option);
    onSaved(option);
  }
}
