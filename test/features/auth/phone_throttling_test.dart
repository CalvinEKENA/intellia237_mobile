import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/domain/firebase_error_mapper.dart';

/// Sur appareil réel, le reCAPTCHA s'ouvrait puis Firebase répondait « trop de
/// tentatives ». L'écran affichait pourtant « La vérification n'a pas abouti.
/// Réessayez dans un instant. », ce qui pousse l'élève à relancer une demande
/// et prolonge exactement le blocage en cours.
void main() {
  group('détection du throttling Firebase', () {
    test('le code canonique est reconnu', () {
      expect(
        FirebaseErrorMapper.normalizeCode('too-many-requests'),
        'too-many-requests',
      );
      expect(
        FirebaseErrorMapper.normalizeCode('TOO_MANY_REQUESTS'),
        'too-many-requests',
      );
    });

    test('le message Android est reconnu sous un code générique', () {
      // Le SDK Android renvoie très souvent « unknown » ou « internal-error »,
      // le motif réel n'étant lisible que dans le message technique.
      const androidMessage =
          'We have blocked all requests from this device due to unusual '
          'activity. Try again later.';

      expect(
        FirebaseErrorMapper.normalizeCode('unknown', androidMessage),
        'too-many-requests',
      );
      expect(
        FirebaseErrorMapper.normalizeCode('internal-error', androidMessage),
        'too-many-requests',
      );
    });

    test('le throttling garde son identifiant de diagnostic', () {
      expect(
        FirebaseErrorMapper.diagnosticId('unknown', 'unusual activity'),
        'AUTH-RATE-003',
      );
    });

    test('un message anodin ne devient pas un throttling', () {
      expect(
        FirebaseErrorMapper.normalizeCode('network-request-failed', 'offline'),
        'network-request-failed',
      );
      expect(FirebaseErrorMapper.normalizeCode('unknown', 'boom'), 'unknown');
    });

    test('le message utilisateur nomme l’attente, pas un échec vague', () {
      final message = FirebaseErrorMapper.authMessage(
        code: 'unknown',
        technicalMessage: 'blocked all requests',
      );

      expect(message, contains('Attends un moment'));
      expect(message, isNot(contains('Firebase')));
      expect(message, isNot(contains('quelques minutes')));
      expect(message, isNot(contains('Une erreur')));
    });
  });
}
