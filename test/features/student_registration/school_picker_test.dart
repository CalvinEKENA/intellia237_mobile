import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/student_registration/application/student_registration_controller.dart';
import 'package:intellia237/features/student_registration/data/establishment_catalog.dart';
import 'package:intellia237/features/student_registration/data/reference_establishment_catalog.dart';
import 'package:intellia237/features/student_registration/data/registration_establishments_provider.dart';
import 'package:intellia237/features/student_registration/domain/academic_rules.dart';
import 'package:intellia237/features/student_registration/domain/establishment.dart';
import 'package:intellia237/features/student_registration/presentation/widgets/establishment_search_field.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

final _catalog = ReferenceEstablishmentCatalog.parse(
  File(referenceCatalogAsset).readAsStringSync(),
);

Establishment _partner(String id, String name, String city) => Establishment(
  id: id,
  officialName: name,
  normalizedName: EstablishmentSearch.normalize(name),
  aliases: const [],
  region: '',
  city: city,
  type: EstablishmentType.lycee,
  subsystem: null,
  educationTypes: EstablishmentEducationType.values,
  status: EstablishmentCatalogStatus.active,
  isPartner: true,
);

class _Harness {
  _Harness(this.container);
  final ProviderContainer container;
  EstablishmentAffiliation? get value =>
      container.read(studentRegistrationControllerProvider).establishment;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  Size size = const Size(360, 740),
  double textScale = 1,
  Brightness brightness = Brightness.light,
  Future<List<Establishment>> Function()? partners,
  double keyboard = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  if (keyboard > 0) {
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  }
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      referenceEstablishmentsProvider.overrideWith((ref) async => _catalog),
      registrationEstablishmentsProvider.overrideWith(
        (ref) => partners?.call() ?? Future.value(const <Establishment>[]),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(brightness: brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Consumer(
              builder: (context, ref, _) {
                final controller = ref.read(
                  studentRegistrationControllerProvider.notifier,
                );
                return EstablishmentSearchField(
                  value: ref
                      .watch(studentRegistrationControllerProvider)
                      .establishment,
                  onSelected: controller.selectEstablishment,
                  onSuggestion: controller.suggestEstablishment,
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(container);
}

Future<void> _openPicker(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('passport-establishment')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('school-picker')), findsOneWidget);
}

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(
    find.byKey(const ValueKey('school-picker-search')),
    query,
  );
  await tester.pumpAndSettle();
}

List<String> _recordHaptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

const _comal = 'ce-yaounde-college-prive-laic-marie-albert-ii';

void main() {
  testWidgets('the reference catalogue is declared and loads from assets', (
    tester,
  ) async {
    final raw = await tester.runAsync(
      () => rootBundle.loadString(referenceCatalogAsset),
    );
    expect(
      ReferenceEstablishmentCatalog.parse(raw!),
      hasLength(_catalog.length),
    );
  });

  testWidgets('pick a school: light haptic, check, confirmation, Changer', (
    tester,
  ) async {
    final harness = await _pump(tester);
    expect(find.text('TON ÉTABLISSEMENT'), findsOneWidget);
    await _openPicker(tester);
    expect(find.text('Retrouve ton lycée ou ton collège'), findsOneWidget);
    expect(find.byKey(const ValueKey('school-picker-hint')), findsOneWidget);

    await _search(tester, 'Collège MARIE-ALBERT');
    final card = find.byKey(const ValueKey('school-$_comal'));
    expect(card, findsOneWidget);
    expect(find.text('MEILLEUR RÉSULTAT'), findsOneWidget);
    // Rien n'est choisi d'office, même au clavier.
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('school-picker')), findsOneWidget);
    expect(harness.value, isNull);

    final haptics = _recordHaptics(tester);
    await tester.tap(card);
    await tester.pump();
    expect(haptics, ['HapticFeedbackType.lightImpact']);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('school-picker')), findsNothing);
    expect(
      find.text('Collège Privé Laïc Marie Albert II (COMAL II)'),
      findsOneWidget,
    );
    expect(find.text('Yaoundé'), findsOneWidget);
    expect(
      find.text('C\'est noté. Ton établissement confirmera ton inscription.'),
      findsOneWidget,
    );
    expect(find.text('Partenaire INTELLIA'), findsNothing);
    final value = harness.value!;
    expect(value.candidateId, _comal);
    expect(value.source, EstablishmentAffiliationSource.catalogue);
    expect(value.grantsPrivateAccess, isFalse);

    // Changer, puis fermer sans choisir : la sélection reste.
    await tester.tap(find.byKey(const ValueKey('school-change')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('school-picker')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('school-picker-close')));
    await tester.pumpAndSettle();
    expect(harness.value?.candidateId, _comal);

    // Changer pour un autre établissement.
    await tester.tap(find.byKey(const ValueKey('school-change')));
    await tester.pumpAndSettle();
    await _search(tester, 'Leclerc');
    await tester.tap(find.byKey(const ValueKey('school-ce-yaounde-leclerc')));
    await tester.pumpAndSettle();
    expect(harness.value?.candidateId, 'ce-yaounde-leclerc');
    expect(harness.value?.district, 'Yaoundé III');
    expect(find.text('Yaoundé · Yaoundé III'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no result: propose my school as a pending suggestion', (
    tester,
  ) async {
    final harness = await _pump(tester);
    await _openPicker(tester);
    await _search(tester, 'Collège Étoile du Matin');
    expect(find.byKey(const ValueKey('school-not-found')), findsOneWidget);
    expect(find.text('Ton établissement n\'apparaît pas ?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('school-not-found-action')));
    await tester.pumpAndSettle();
    final name = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('school-suggestion-name')),
        matching: find.byType(EditableText),
      ),
    );
    expect(name.controller.text, 'Collège Étoile du Matin');

    await tester.tap(find.byKey(const ValueKey('school-suggestion-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Écris la ville de ton établissement.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('school-suggestion-city')),
      'Yaoundé',
    );
    await tester.enterText(
      find.byKey(const ValueKey('school-suggestion-district')),
      'Yaoundé VI',
    );
    await tester.tap(find.byKey(const ValueKey('school-suggestion-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('school-picker')), findsNothing);
    expect(
      find.text('Proposition envoyée. Nous vérifions cet établissement.'),
      findsOneWidget,
    );
    final value = harness.value!;
    expect(value.source, EstablishmentAffiliationSource.suggestion);
    expect(value.candidateId, isNull);
    expect(value.isSuggestion, isTrue);
    expect(value.name, 'Collège Étoile du Matin');
    expect(value.city, 'Yaoundé');
    expect(value.region, 'Centre');
    expect(value.district, 'Yaoundé VI');
    expect(value.status, EstablishmentAffiliationStatus.pendingVerification);
    expect(tester.takeException(), isNull);
  });

  testWidgets('city capsules: Yaoundé, Douala, Toutes filter the directory', (
    tester,
  ) async {
    await _pump(tester);
    await _openPicker(tester);
    final capsules = [
      for (final key in [
        'school-city-yaounde',
        'school-city-douala',
        'school-city-all',
      ])
        tester.getTopLeft(find.byKey(ValueKey(key))).dx,
    ];
    expect(capsules, orderedEquals([...capsules]..sort()));

    await tester.tap(find.byKey(const ValueKey('school-city-douala')));
    await tester.pumpAndSettle();
    final douala = _catalog.where((s) => s.city == 'Douala').length;
    expect(find.text('$douala établissements à Douala'), findsOneWidget);

    await _search(tester, 'Lycée Bilingue');
    final results = tester.widgetList<Widget>(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('school-lt-'),
      ),
    );
    expect(results, isNotEmpty);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('school-ce-'),
      ),
      findsNothing,
    );

    // Filtré sur Douala, un établissement de Yaoundé n'est pas « absent ».
    await _search(tester, 'Leclerc');
    expect(find.byKey(const ValueKey('school-not-found')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('school-search-all-cities')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('school-ce-yaounde-leclerc')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('school-city-all')));
    await _search(tester, '');
    expect(find.byKey(const ValueKey('school-picker-hint')), findsOneWidget);
  });

  testWidgets('partner badge only when the server says so', (tester) async {
    final harness = await _pump(
      tester,
      partners: () async => [
        _partner('srv-leclerc', 'Lycée Général Leclerc', 'Yaoundé'),
      ],
    );
    await _openPicker(tester);
    await _search(tester, 'Lycée Général');
    expect(find.byKey(const ValueKey('school-srv-leclerc')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('school-ce-yaounde-leclerc')),
      findsNothing,
    );
    expect(find.text('Partenaire INTELLIA'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('school-srv-leclerc')));
    await tester.pumpAndSettle();
    expect(harness.value?.source, EstablishmentAffiliationSource.partner);
    expect(harness.value?.candidateId, 'srv-leclerc');
    expect(harness.value?.grantsPrivateAccess, isFalse);
    expect(find.text('Partenaire INTELLIA'), findsOneWidget);
    expect(
      find.text(
        'Ton établissement utilise INTELLIA : il confirmera ton inscription.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('offline: the whole catalogue is searchable, without badge', (
    tester,
  ) async {
    await _pump(
      tester,
      partners: () => Future.error(const SocketException('hors ligne')),
    );
    await _openPicker(tester);
    await _search(tester, 'mbohm');
    expect(
      find.byKey(
        const ValueKey('school-ce-yaounde-mbohmelites-bilingual-college'),
      ),
      findsOneWidget,
    );
    expect(find.text('Yaoundé · Yaoundé VII'), findsOneWidget);
    expect(find.text('Partenaire INTELLIA'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('result cards read name, city, district, type in that order', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    await _openPicker(tester);
    await _search(tester, 'Leclerc');
    expect(
      tester.getSemantics(
        find.byKey(const ValueKey('school-ce-yaounde-leclerc')),
      ),
      matchesSemantics(
        label: 'Lycée Général Leclerc, Yaoundé, Yaoundé III, Lycée',
        hint: 'Meilleur résultat',
        isButton: true,
        hasTapAction: true,
        hasSelectedState: true,
      ),
    );
    semantics.dispose();
  });

  group('responsive', () {
    for (final size in const [Size(320, 640), Size(360, 740), Size(412, 915)]) {
      for (final scale in const [1.0, 1.3, 1.5]) {
        for (final brightness in Brightness.values) {
          testWidgets('${size.width.toInt()} dp × $scale ${brightness.name}: '
              'no overflow, long names, keyboard', (tester) async {
            await _pump(
              tester,
              size: size,
              textScale: scale,
              brightness: brightness,
            );
            expect(tester.takeException(), isNull);
            await _openPicker(tester);
            tester.view.viewInsets = const FakeViewPadding(bottom: 300);
            await tester.pumpAndSettle();
            await _search(tester, 'Collège Privé Catholique');
            expect(tester.takeException(), isNull);
            await _search(tester, 'aucun établissement ici');
            expect(
              find.byKey(const ValueKey('school-not-found-action')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            tester.view.resetViewInsets();
            await _search(tester, 'Maria Goretti');
            final goretti = find.byKey(
              const ValueKey(
                'school-ce-yaounde-college-prive-catholique-enseignement-technique-industri',
              ),
            );
            await tester.ensureVisible(goretti);
            await tester.pumpAndSettle();
            await tester.tap(goretti);
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('passport-establishment-name')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });
}
