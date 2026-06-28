import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/domain/auth_input_validators.dart';

void main() {
  group('AuthInputValidators', () {
    test('accepts the Web App identity constraints', () {
      expect(
        AuthInputValidators.displayName('Marie Ndi', label: 'Le nom'),
        isNull,
      );
      expect(AuthInputValidators.email('user@example.com'), isNull);
      expect(AuthInputValidators.password('password8'), isNull);
    });

    test('rejects invalid account creation inputs with explicit messages', () {
      expect(
        AuthInputValidators.displayName('A', label: 'Le nom'),
        'Le nom doit contenir au moins 2 caracteres.',
      );
      expect(
        AuthInputValidators.email('not-an-email'),
        'Adresse email invalide.',
      );
      expect(
        AuthInputValidators.password('short'),
        'Le mot de passe doit contenir au moins 8 caracteres.',
      );
      expect(
        AuthInputValidators.confirmPassword(
          password: 'password8',
          confirmation: 'different',
        ),
        'La confirmation du mot de passe est invalide.',
      );
    });
  });
}
