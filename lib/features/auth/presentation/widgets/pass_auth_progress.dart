import '../../application/auth_state.dart';
import '../../application/phone_auth_controller.dart';
import '../../domain/auth_input_validators.dart';
import '../../domain/cameroon_phone_number.dart';
import 'intellia_237_membrane.dart';

/// Seul endroit où l'état réel d'un parcours devient le Pass : l'étape du
/// sceau « 237 » et la ligne gravée au bas de la carte.
///
/// Aucun écran ne pose de valeur de son cru. Chacun passe ici l'état qu'il
/// détient réellement — étape Firebase, texte saisi, session adoptée — et
/// reçoit l'étape du sceau. Le sceau n'est jamais déduit de la ligne gravée.
///
/// Registre de décisions (QA appareil, round 3) :
/// - `LivingPass` retombait sur l'avancement de sa ligne quand un écran ne
///   précisait pas le sceau. L'inscription enseignant y posait ses étapes
///   (0,20 · 0,54 · 0,88 · 0,94) : « 2 » vert à 60 % à l'ouverture, « 7 »
///   moutarde à 64 % sur la dernière étape, jamais un chiffre plein, et
///   l'e-mail et le mot de passe saisis ne comptaient pas ;
/// - le numéro colorait « 2 » au nombre de chiffres, pas à sa validité ;
/// - la réussite Firebase allumait « 7 » avant que l'espace soit ouvert :
///   un conflit de rôle le rééteignait ensuite.
abstract final class PassAuthProgress {
  // ── Sceau ────────────────────────────────────────────────────────────

  /// Parcours téléphone. « 2 » : numéro camerounais valide (la même règle
  /// que l'envoi du SMS). « 3 » : six chiffres saisis, ou numéro validé par
  /// Firebase — SMS lu par Android compris. « 7 » : [accessOpened], l'espace
  /// adopté est en train de s'ouvrir.
  static PassSealStage phone({
    required PhoneAuthStage stage,
    required String phoneInput,
    required String codeInput,
    required bool accessOpened,
  }) {
    if (accessOpened) return PassSealStage.verified;
    return switch (stage) {
      PhoneAuthStage.phoneEntry =>
        isValidPhone(phoneInput)
            ? PassSealStage.identifier
            : PassSealStage.neutral,
      PhoneAuthStage.codeEntry =>
        isCompleteCode(codeInput)
            ? PassSealStage.secret
            : PassSealStage.identifier,
      PhoneAuthStage.success => PassSealStage.secret,
    };
  }

  /// Connexion par e-mail. « 2 » : adresse valide. « 3 » : mot de passe
  /// recevable. « 7 » : [accessOpened], identifiants acceptés et espace
  /// compatible, juste avant l'ouverture.
  static PassSealStage emailSignIn({
    required String email,
    required String password,
    required bool accessOpened,
  }) {
    if (accessOpened) return PassSealStage.verified;
    if (AuthInputValidators.email(email) != null) return PassSealStage.neutral;
    return AuthInputValidators.password(password) == null
        ? PassSealStage.secret
        : PassSealStage.identifier;
  }

  /// Réinitialisation du mot de passe. Aucun accès n'est ouvert ici : le
  /// lien envoyé allume « 3 », jamais « 7 ».
  static PassSealStage passwordReset({
    required String email,
    required bool linkSent,
  }) {
    if (AuthInputValidators.email(email) != null) return PassSealStage.neutral;
    return linkSent ? PassSealStage.secret : PassSealStage.identifier;
  }

  /// Création d'un compte par e-mail (enseignant). « 2 » : adresse valide.
  /// « 3 » : mot de passe recevable et confirmé. « 7 » : [accountOpened],
  /// le compte existe et son espace va s'ouvrir.
  static PassSealStage accountCreation({
    required String email,
    required String password,
    required String confirmation,
    required bool accountOpened,
  }) {
    if (accountOpened) return PassSealStage.verified;
    if (AuthInputValidators.email(email) != null) return PassSealStage.neutral;
    final secretReady =
        AuthInputValidators.password(password) == null &&
        AuthInputValidators.confirmPassword(
              password: password,
              confirmation: confirmation,
            ) ==
            null;
    return secretReady ? PassSealStage.secret : PassSealStage.identifier;
  }

  /// Écrans ouverts après l'authentification — inscription, réussite,
  /// accueil : le sceau dit si une session est réellement établie. Une
  /// inscription atteinte sans session ne montre pas un sceau complet.
  static PassSealStage session(AuthState auth) =>
      auth.hasFirebaseSession ? PassSealStage.verified : PassSealStage.neutral;

  // ── Ligne gravée ─────────────────────────────────────────────────────
  //
  // La ligne suit la saisie touche par touche ; le sceau, lui, n'avance que
  // par étape entière.

  static const double empty = 0;
  static const double complete = 1;

  /// Un espace est choisi, rien n'est encore saisi.
  static const double spaceChosen = 1 / 9;

  static double phoneLine({
    required PhoneAuthStage stage,
    required String phoneInput,
    required String codeInput,
    required bool accessOpened,
  }) {
    if (accessOpened) return complete;
    return switch (stage) {
      PhoneAuthStage.phoneEntry =>
        isValidPhone(phoneInput)
            ? 1 / 3
            : _third(0, _localDigits(phoneInput) / (_localPhoneDigits + 1)),
      PhoneAuthStage.codeEntry => _third(
        1,
        _digits(codeInput).length / _codeDigits,
      ),
      PhoneAuthStage.success => 2 / 3,
    };
  }

  static double emailLine({
    required String email,
    required String password,
    required bool accessOpened,
  }) {
    if (accessOpened) return complete;
    if (AuthInputValidators.email(email) != null) {
      return email.trim().isEmpty ? empty : _third(0, 0.5);
    }
    return _third(1, password.length / _passwordLength);
  }

  static double resetLine({required String email, required bool linkSent}) =>
      switch (passwordReset(email: email, linkSent: linkSent)) {
        PassSealStage.neutral => email.trim().isEmpty ? empty : _third(0, 0.5),
        final stage => stage.progress,
      };

  /// Inscription : chaque étape remplit une part égale, la dernière laisse
  /// la place de l'ouverture du compte.
  static double registrationLine({required int step, required int steps}) =>
      ((step + 1) / (steps + 1)).clamp(empty, complete);

  // ── Règles de saisie partagées ───────────────────────────────────────

  static const _localPhoneDigits = 9;
  static const _codeDigits = 6;
  static const _passwordLength = 8;

  /// Même règle que l'envoi du SMS : un numéro que l'envoi refuserait
  /// n'allume pas « 2 ».
  static bool isValidPhone(String input) {
    try {
      CameroonPhoneNumber.normalize(input);
      return true;
    } on PhoneNumberFormatException {
      return false;
    }
  }

  static bool isCompleteCode(String input) =>
      _digits(input).length == _codeDigits;

  static double _third(int index, double fraction) =>
      (index + fraction.clamp(0.0, 1.0)) / 3;

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

/// Temps pendant lesquels le sceau reste lisible.
abstract final class PassSealTiming {
  /// Un « 3 » allumé par une validation sans saisie — SMS lu par Android,
  /// numéro validé d'emblée — reste seul à l'écran au moins ce temps avant
  /// que « 7 » ne s'allume : la deuxième étape n'est jamais sautée.
  static const Duration stageHold = Duration(milliseconds: 700);

  /// Le sceau complet reste à l'écran d'authentification au moins ce temps
  /// avant l'ouverture de l'espace, animations réduites comprises. Fondu du
  /// « 7 » déduit, ses trois couleurs exactes restent plus d'une seconde.
  static const Duration completionHold = Duration(milliseconds: 1500);
}
