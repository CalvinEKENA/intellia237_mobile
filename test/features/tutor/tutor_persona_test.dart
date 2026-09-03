import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/tutor/application/tutor_preference_provider.dart';
import 'package:intellia237/features/tutor/domain/tutor_persona.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TutorPersona legacy compatibility', () {
    test('keeps official companion ids stable', () {
      expect(TutorPersona.resolve('kira').id, 'kira');
      expect(TutorPersona.resolve('leo').id, 'leo');
      expect(TutorPersona.resolve('Léo').id, 'leo');
    });

    test('maps historical tutor ids to official companions', () {
      expect(TutorPersona.resolve('grace').id, 'kira');
      expect(TutorPersona.resolve('cynthia').id, 'kira');
      expect(TutorPersona.resolve('marianne').id, 'kira');
      expect(TutorPersona.resolve('ethan').id, 'leo');
      expect(TutorPersona.resolve('armel').id, 'leo');
      expect(TutorPersona.resolve('nathan').id, 'leo');
    });

    test('accepts profile and payload maps from stored data', () {
      expect(TutorPersona.fromJson({'tutorId': 'ethan'}).id, 'leo');
      expect(TutorPersona.fromJson({'personaId': 'grace'}).id, 'kira');
      expect(TutorPersona.fromJson({'companion': 'Léo'}).id, 'leo');
    });

    test('falls back safely for malformed or unknown values', () {
      expect(TutorPersona.resolve(null).id, 'kira');
      expect(TutorPersona.resolve('unknown').id, 'kira');
      expect(TutorPersona.resolve({'id': 42}).id, 'kira');
    });
  });

  test('stored and newly selected companion ids are canonical', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'selected_tutor_id': 'Léo',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(selectedTutorIdProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(selectedTutorIdProvider), 'leo');

    await container.read(selectedTutorIdProvider.notifier).select('Grace');
    expect(container.read(selectedTutorIdProvider), 'kira');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('selected_tutor_id'), 'kira');
  });
}
