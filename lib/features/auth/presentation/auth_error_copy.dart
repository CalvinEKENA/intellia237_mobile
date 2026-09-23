import '../../../l10n/generated/app_localizations.dart';

/// Annulations volontaires : aucun message d'erreur ne s'affiche.
///
/// Codes vérifiés : `canceled` (google_sign_in 7 et Credential Manager),
/// `web-context-canceled` (Firebase Android, onglet personnalisé fermé),
/// `popup-closed-by-user` et `cancelled-popup-request` (Firebase web).
bool isAuthCancellation(String code) => const {
  'canceled',
  'cancelled',
  'web-context-canceled',
  'popup-closed-by-user',
  'cancelled-popup-request',
}.contains(code);

/// Message humain pour un code d'erreur d'authentification.
///
/// Registre de décisions (refonte Auth V2) : l'ancien écran de liaison
/// affichait `${e.message}` de Firebase. Aucun message technique n'atteint
/// plus l'écran : tout code inconnu reçoit le message générique.
String authErrorMessage(AppLocalizations l10n, String code) => switch (code) {
  'network-request-failed' ||
  'unavailable' ||
  'timeout' ||
  'deadline-exceeded' => l10n.authErrorNetwork,
  'invalid-verification-code' ||
  'invalid-verification-id' ||
  'session-expired' ||
  'code-expired' => l10n.authErrorInvalidCode,
  'too-many-requests' ||
  'quota-exceeded' ||
  'resource-exhausted' => l10n.authErrorTooManyRequests,
  'account-exists-with-different-credential' => l10n.authErrorAccountExists,
  'credential-already-in-use' ||
  'email-already-in-use' => l10n.authErrorCredentialInUse,
  'wrong-password' ||
  'invalid-credential' ||
  'invalid-login-credentials' ||
  'user-not-found' ||
  'invalid-email' => l10n.authErrorWrongPassword,
  'user-disabled' => l10n.authErrorUserDisabled,
  'provider-already-linked' => l10n.authErrorProviderAlreadyLinked,
  'google-not-configured' ||
  'google-unsupported-platform' ||
  'operation-not-allowed' ||
  'failed-precondition' => l10n.authErrorGoogleNotConfigured,
  'google-ui-unavailable' => l10n.authErrorGoogleUnavailable,
  'google-session-expired' => l10n.authGoogleStepExpired,
  'invalid-phone-number' => l10n.authErrorInvalidPhone,
  'missing-fields' => l10n.authErrorMissingFields,
  _ => l10n.authErrorGeneric,
};
