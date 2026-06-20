import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/tutor/domain/tutor_persona.dart';

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
}
