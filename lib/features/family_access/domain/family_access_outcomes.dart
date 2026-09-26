import 'family_access_models.dart';

/// Issue de la cession du téléphone familial au parent.
sealed class FamilyPhoneMigrationOutcome {
  const FamilyPhoneMigrationOutcome();
}

final class FamilyPhoneMigrated extends FamilyPhoneMigrationOutcome {
  const FamilyPhoneMigrated(this.result);

  final FamilyPhoneMigrationResult result;
}

enum FamilyPhoneMigrationFailure {
  /// Rien n'a changé : réessayer tout de suite.
  nothingChanged,

  /// La vérification SMS est trop ancienne : vérifier le numéro à nouveau.
  verificationExpired,

  /// Une autre tentative est en cours : patienter un instant.
  inProgress,

  /// Le numéro est libre (double panne) : le vérifier à nouveau termine
  /// l'ouverture de l'espace parent ; l'élève a déjà son code d'accès.
  verifyAgainToFinish,

  /// Service absent (non déployé) ou erreur inattendue.
  unavailable,

  /// Ce numéro ne peut pas être cédé depuis ce compte.
  refused,
}

final class FamilyPhoneMigrationFailed extends FamilyPhoneMigrationOutcome {
  const FamilyPhoneMigrationFailed(this.failure, {this.studentAccessCode});

  factory FamilyPhoneMigrationFailed.from(FamilyAccessException error) {
    final failure = switch ((error.code, error.reason)) {
      (_, 'migration-compensated') =>
        FamilyPhoneMigrationFailure.nothingChanged,
      (_, 'recent-phone-verification-required') =>
        FamilyPhoneMigrationFailure.verificationExpired,
      (_, 'migration-needs-recovery' || 'migration-resumable') =>
        FamilyPhoneMigrationFailure.verifyAgainToFinish,
      ('aborted', _) => FamilyPhoneMigrationFailure.inProgress,
      ('failed-precondition' || 'permission-denied', _) =>
        FamilyPhoneMigrationFailure.refused,
      _ => FamilyPhoneMigrationFailure.unavailable,
    };
    return FamilyPhoneMigrationFailed(
      failure,
      studentAccessCode: error.studentAccessCode,
    );
  }

  final FamilyPhoneMigrationFailure failure;

  /// Code d'accès déjà émis pour l'élève quand la migration s'est arrêtée
  /// après l'avoir créé : il faut le montrer, il ouvre l'espace de l'élève.
  final String? studentAccessCode;
}

/// Issue d'une connexion par code d'accès élève.
sealed class StudentAccessCodeSignIn {
  const StudentAccessCodeSignIn();
}

final class StudentAccessCodeAdopted extends StudentAccessCodeSignIn {
  const StudentAccessCodeAdopted();
}

enum StudentAccessCodeRejection {
  /// Code inconnu, remplacé, mal formé ou compte suspendu : une seule
  /// réponse, pour ne rien révéler.
  invalid,
  tooManyAttempts,
  unavailable,
}

final class StudentAccessCodeRejected extends StudentAccessCodeSignIn {
  const StudentAccessCodeRejected(this.rejection);

  factory StudentAccessCodeRejected.from(FamilyAccessException error) =>
      StudentAccessCodeRejected(switch (error.code) {
        'permission-denied' ||
        'invalid-argument' => StudentAccessCodeRejection.invalid,
        'resource-exhausted' => StudentAccessCodeRejection.tooManyAttempts,
        _ => StudentAccessCodeRejection.unavailable,
      });

  final StudentAccessCodeRejection rejection;
}

/// Le code est accepté mais le profil de l'élève n'a pas pu être lu.
final class StudentAccessCodeUnresolved extends StudentAccessCodeSignIn {
  const StudentAccessCodeUnresolved(this.errorCode);

  final String errorCode;
}
