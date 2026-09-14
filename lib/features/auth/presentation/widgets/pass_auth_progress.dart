import '../../application/phone_auth_controller.dart';
import '../../domain/auth_input_validators.dart';

/// Où chaque étape d'authentification amène le sceau « 237 ».
///
/// Un chiffre par étape, chacun sur son tiers exact : l'identifiant (numéro
/// ou e-mail) colore « 2 » en vert, le secret (code SMS ou mot de passe)
/// colore « 3 » en rouge, l'accès vérifié colore « 7 » en jaune. Chaque tiers
/// se remplit au fil de la saisie.
///
/// Registre de décisions (QA appareil, round 2) : les écrans passaient des
/// valeurs approchées — 0,33 et 0,66 au téléphone, 0,65 figé à l'e-mail —,
/// si bien qu'aucun chiffre n'atteignait exactement sa couleur et que l'e-mail
/// ne progressait pas du tout. Les valeurs sont désormais calculées ici, une
/// seule fois, et vérifiées par des tests déterministes.
abstract final class PassAuthProgress {
  /// Rien n'est encore saisi : les trois chiffres restent à l'encre de base.
  static const double start = 0;

  /// Identifiant complet : « 2 » est vert.
  static const double identifier = 1 / 3;

  /// Secret complet : « 3 » est rouge.
  static const double secret = 2 / 3;

  /// Accès vérifié : « 7 » est jaune.
  static const double verified = 1;

  static const _localPhoneDigits = 9;
  static const _codeDigits = 6;
  static const _passwordLength = 8;

  /// Parcours téléphone : numéro, puis code SMS, puis réussite.
  static double phone({
    required PhoneAuthStage stage,
    required String phoneInput,
    required String codeInput,
  }) => switch (stage) {
    PhoneAuthStage.phoneEntry => _within(
      start,
      _localDigits(phoneInput) / _localPhoneDigits,
    ),
    PhoneAuthStage.codeEntry => _within(
      identifier,
      _digits(codeInput).length / _codeDigits,
    ),
    PhoneAuthStage.success => verified,
  };

  /// Connexion par e-mail : adresse, puis mot de passe. La réussite quitte
  /// l'écran : l'espace d'arrivée présente le sceau vérifié.
  static double emailSignIn({required String email, required String password}) {
    if (AuthInputValidators.email(email) != null) {
      return _within(start, email.trim().isEmpty ? 0 : 0.5);
    }
    return _within(identifier, password.length / _passwordLength);
  }

  /// Réinitialisation : adresse, puis lien envoyé. Aucun accès n'est ouvert
  /// ici, le sceau s'arrête donc au secret.
  static double passwordReset({required String email, required bool linkSent}) {
    if (linkSent) return secret;
    if (AuthInputValidators.email(email) != null) {
      return _within(start, email.trim().isEmpty ? 0 : 0.5);
    }
    return identifier;
  }

  static double _within(double stepStart, double fraction) =>
      stepStart + fraction.clamp(0.0, 1.0) * (1 / 3);

  static String _digits(String input) => input.replaceAll(RegExp(r'\D'), '');

  /// Chiffres du numéro local, indicatif +237 exclu s'il a été saisi.
  static int _localDigits(String input) {
    final typed = input.trimLeft();
    var digits = _digits(typed);
    if (typed.startsWith('+237')) {
      digits = digits.substring(3);
    } else if (digits.startsWith('00237')) {
      digits = digits.substring(5);
    } else if (digits.length > _localPhoneDigits && digits.startsWith('237')) {
      digits = digits.substring(3);
    }
    return digits.length;
  }
}
