import '../domain/account_school_record.dart';
import '../domain/admin_models.dart';

abstract class AdminRepository {
  /// [establishmentId] ne sert qu'à l'administration générale ; une direction
  /// lit toujours sa propre école.
  Future<SchoolDirectoryPage> fetchSchoolDirectory({
    required String adminUid,
    required AdminRoleType role,
    String? afterId,
    String? establishmentId,
  });

  Future<List<SchoolClassSummary>> fetchSchoolClasses({
    required String adminUid,
    String? establishmentId,
  });

  Future<void> renameSchoolClass({
    required String adminUid,
    required String classId,
    required String name,
  });

  /// Crée une classe d'établissement. [classLevel] est un **niveau académique
  /// canonique** (6eme…Terminale, Form1…UpperSixth), distinct du nom d'usage
  /// (« 6e A »). La classe naît sans élève (les règles l'exigent).
  Future<String> createSchoolClass({
    required String adminUid,
    required String name,
    required String classLevel,
    String? series,
    String? track,
    String? establishmentId,
  });

  /// Met à jour le nom et/ou les métadonnées (niveau/série/filière) d'une classe.
  /// Ne touche jamais à la composition (élèves/enseignants).
  Future<void> updateSchoolClass({
    required String adminUid,
    required String classId,
    String? name,
    String? classLevel,
    String? series,
    String? track,
  });

  /// Supprime une classe **uniquement si elle est vide** (aucun élève). Lève une
  /// erreur explicite sinon, pour ne jamais orpheliner d'élèves.
  Future<void> deleteSchoolClass({
    required String adminUid,
    required String classId,
  });

  Future<AdminDashboard> fetchDashboard({required String adminUid});

  Future<List<PendingAccountReview>> fetchPendingReviews({
    required String adminUid,
  });

  Future<List<ModerationEntry>> fetchModerationQueue({
    required String adminUid,
  });

  Future<void> validateAccount({
    required String adminUid,
    required String reviewId,
    required bool approved,
    String? establishmentId,
  });

  Future<List<EstablishmentOption>> fetchEstablishments({
    required String adminUid,
  });

  Future<String> createEstablishment({
    required String adminUid,
    required String name,
    required String city,
  });

  /// Modifie le nom et/ou la ville d'un établissement.
  Future<void> updateEstablishment({
    required String adminUid,
    required String establishmentId,
    required String name,
    required String city,
  });

  /// Archive (désactive) ou réactive un établissement sans supprimer ses
  /// données : on ne détruit jamais une école qui porte des comptes/classes.
  Future<void> setEstablishmentArchived({
    required String adminUid,
    required String establishmentId,
    required bool archived,
  });

  Future<List<UnattachedStaffMember>> fetchUnattachedStaff({
    required String adminUid,
  });

  /// Retrouve un compte par son e-mail ou son téléphone exacts.
  Future<List<AccountSchoolRecord>> searchAccounts({
    required String adminUid,
    required String query,
  });

  /// Rattache un compte à une école, ou le change d'école avec un motif.
  Future<void> changeAccountEstablishment({
    required String adminUid,
    required String accountId,
    required String establishmentId,
    String? reason,
  });

  Future<void> publishAnnouncement({
    required String adminUid,
    required String title,
    required String message,
    required String audience,
    String? establishmentId,
  });

  Future<void> updateModeration({
    required String adminUid,
    required String moderationId,
    required ModerationStatus status,
  });
}
