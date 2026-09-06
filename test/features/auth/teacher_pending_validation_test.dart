import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/role_registration/domain/registration_result.dart';

/// L'écran « Validation finale » annonçait qu'une validation par une équipe
/// autorisée est nécessaire, puis affichait « Le profil n'a pas pu être
/// finalisé. » — le repli générique de `serviceMessage`.
///
/// Le contrat serveur est pourtant sans ambiguïté : `submitStaffRegistration`
/// crée la demande et renvoie `accountStatus: "pending_validation"`. Une
/// demande enregistrée est un succès en attente, pas un échec. Le client
/// ignorait ce champ.
void main() {
  test('le statut serveur d’attente est conservé', () {
    const result = RoleRegistrationResult(
      uid: 'teacher-1',
      email: 'prof@example.com',
      firstName: 'Amina',
      lastName: 'Nkolo',
      accountStatus: 'pending_validation',
    );

    expect(result.accountStatus, 'pending_validation');
    expect(result.awaitsValidation, isTrue);
  });

  test('un compte immédiatement actif ne se déclare pas en attente', () {
    const result = RoleRegistrationResult(
      uid: 'teacher-2',
      email: 'prof2@example.com',
      firstName: 'Jean',
      lastName: 'Fotso',
      accountStatus: 'active',
    );

    expect(result.awaitsValidation, isFalse);
  });

  test('un statut absent ne suppose aucune attente', () {
    const result = RoleRegistrationResult(
      uid: 'teacher-3',
      email: 'prof3@example.com',
      firstName: 'Marie',
      lastName: 'Etoga',
    );

    expect(result.accountStatus, isNull);
    expect(result.awaitsValidation, isFalse);
  });
}
