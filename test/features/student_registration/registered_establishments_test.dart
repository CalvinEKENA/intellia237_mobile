import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/student_registration/data/establishment_catalog.dart';
import 'package:intellia237/features/student_registration/data/registration_establishments_provider.dart';
import 'package:intellia237/features/student_registration/domain/establishment.dart';
import 'package:intellia237/features/student_registration/presentation/widgets/establishment_search_field.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

void main() {
  final school = Establishment(
    id: 'firebase-vogt',
    officialName: 'Collège F.X VOGT',
    normalizedName: 'college f x vogt',
    aliases: const [],
    region: '',
    city: 'Yaoundé',
    type: EstablishmentType.college,
    subsystem: EstablishmentSubsystem.bilingual,
    educationTypes: EstablishmentEducationType.values,
    status: EstablishmentCatalogStatus.active,
  );

  test(
    'search uses only the supplied live catalogue, including city and accents',
    () {
      expect(
        EstablishmentSearch.query(
          'Yaounde',
          catalog: [school],
        ).single.establishment.id,
        'firebase-vogt',
      );
      expect(EstablishmentSearch.query('Leclerc', catalog: [school]), isEmpty);
      expect(EstablishmentSearch.query('Vogt', catalog: const []), isEmpty);
    },
  );

  testWidgets(
    'shows registered schools immediately; selection and edited text stay consistent',
    (tester) async {
      Establishment? selected;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            registrationEstablishmentsProvider.overrideWith(
              (ref) async => [school],
            ),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: EstablishmentSearchField(
                onSelected: (value) => selected = value,
                onCleared: () => selected = null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Collège F.X VOGT'), findsOneWidget);
      expect(find.text('Lycée Général Leclerc'), findsNothing);
      expect(
        find.byKey(const ValueKey('school-not-found-action')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('school-firebase-vogt')));
      await tester.pumpAndSettle();
      expect(selected?.id, 'firebase-vogt');
      await tester.enterText(find.byType(TextFormField), 'inconnu');
      await tester.pumpAndSettle();
      expect(selected, isNull);
      expect(find.byKey(const ValueKey('school-firebase-vogt')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
