import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/domain/firebase_error_mapper.dart';

void main() {
  group('FirebaseErrorMapper', () {
    test('translates known Firebase Auth errors into French', () {
      expect(
        FirebaseErrorMapper.authMessage(code: 'email-already-in-use'),
        'Cette adresse e-mail est déjà associée à un compte.',
      );
      expect(
        FirebaseErrorMapper.authMessage(code: 'weak-password'),
        'Choisis un mot de passe plus sécurisé.',
      );
    });

    test('detects CONFIGURATION_NOT_FOUND hidden in an internal error', () {
      expect(
        FirebaseErrorMapper.normalizeCode(
          'internal-error',
          'An internal error has occurred. [CONFIGURATION_NOT_FOUND]',
        ),
        'configuration-not-found',
      );
      expect(
        FirebaseErrorMapper.authMessage(
          code: 'internal-error',
          technicalMessage: '[CONFIGURATION_NOT_FOUND]',
        ),
        'Le service d’inscription est momentanément indisponible. '
        'Réessaie dans quelques instants.',
      );
    });
  });
}
