import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/application/admin_content_providers.dart';
import 'package:intellia237/features/admin/presentation/new_subject_dialog.dart';

/// L'administration générale ouvre une matière pour une classe qui n'en a
/// pas : sans elle, aucun cours ne peut y être rédigé.
void main() {
  Future<List<Map<String, Object?>>> openDialog(
    WidgetTester tester, {
    required String classLevel,
  }) async {
    final created = <Map<String, Object?>>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminContentActionsProvider.overrideWith(
            (ref) => _RecordingContentActions(ref, created),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (_) => NewSubjectDialog(classLevel: classLevel),
                  ),
                  child: const Text('ouvrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    return created;
  }

  testWidgets('une suggestion crée la matière avec son icône et ses séries', (
    tester,
  ) async {
    final created = await openDialog(tester, classLevel: 'Terminale');

    await tester.tap(find.byKey(const ValueKey('new-subject-suggestion-0')));
    await tester.pump();
    // Les séries sont plus bas dans la feuille : on y fait défiler.
    final serieC = find.widgetWithText(FilterChip, 'C');
    await tester.ensureVisible(serieC);
    await tester.pumpAndSettle();
    await tester.tap(serieC);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('new-subject-create')));
    await tester.pumpAndSettle();

    expect(created, [
      {
        'classLevel': 'Terminale',
        'title': 'Mathématiques',
        'iconKey': 'math',
        'allowedSeries': ['C'],
      },
    ]);
    // La feuille se referme une fois la matière créée.
    expect(find.byType(NewSubjectDialog), findsNothing);
  });

  testWidgets('une matière sans nom n’est pas créée', (tester) async {
    final created = await openDialog(tester, classLevel: '6eme');

    // Pas de série en 6e.
    expect(find.byType(FilterChip), findsNothing);
    await tester.tap(find.byKey(const ValueKey('new-subject-create')));
    await tester.pump();

    expect(created, isEmpty);
    expect(find.text('Donnez un nom à la matière.'), findsOneWidget);
  });
}

class _RecordingContentActions extends AdminContentActions {
  _RecordingContentActions(super.ref, this.created);

  final List<Map<String, Object?>> created;

  @override
  Future<void> createSubject({
    required String classLevel,
    required String title,
    required String description,
    required int colorHex,
    required String iconKey,
    List<String> allowedSeries = const [],
  }) async {
    created.add({
      'classLevel': classLevel,
      'title': title,
      'iconKey': iconKey,
      'allowedSeries': allowedSeries,
    });
  }
}
