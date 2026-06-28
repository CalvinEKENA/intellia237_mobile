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

    group('diagnosticId (staging)', () {
      test('Firebase Auth non configuré → AUTH-CONFIG-001', () {
        expect(
          FirebaseErrorMapper.diagnosticId('configuration-not-found'),
          'AUTH-CONFIG-001',
        );
        // Email/Mot de passe non activé remonte operation-not-allowed.
        expect(
          FirebaseErrorMapper.diagnosticId('operation-not-allowed'),
          'AUTH-CONFIG-001',
        );
        // Variante cachée dans un message technique.
        expect(
          FirebaseErrorMapper.diagnosticId(
            'internal-error',
            '[CONFIGURATION_NOT_FOUND]',
          ),
          'AUTH-CONFIG-001',
        );
      });

      test('autres catégories diagnostiques', () {
        expect(
          FirebaseErrorMapper.diagnosticId('network-request-failed'),
          'AUTH-NET-002',
        );
        expect(
          FirebaseErrorMapper.diagnosticId('email-already-in-use'),
          'AUTH-EMAIL-004',
        );
        expect(
          FirebaseErrorMapper.diagnosticId('permission-denied'),
          'DATA-PERM-101',
        );
        expect(
          FirebaseErrorMapper.diagnosticId('something-weird'),
          'APP-UNKNOWN-000',
        );
      });
    });
  });
}
