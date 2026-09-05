import 'package:flutter/widgets.dart';

import '../../domain/models/campus_program.dart';
import '../../domain/models/campus_resource.dart';
import '../../domain/models/campus_roles.dart';
import '../../domain/models/campus_student.dart';

/// Typed localization helper for INTELLIA Campus.
///
/// Provides natural, context-appropriate phrasing for both French and English
/// in the Cameroonian bilingual educational context.
///
/// Strictly adheres to the institutional terminology requirements.
class CampusLocalizations {
  final Locale locale;

  CampusLocalizations(this.locale);

  static CampusLocalizations of(BuildContext context) {
    final loc = Localizations.maybeLocaleOf(context) ?? const Locale('fr');
    return CampusLocalizations(loc);
  }

  bool get isEnglish => locale.languageCode.toLowerCase().startsWith('en');

  // App & Shell
  String get campusTitle => 'INTELLIA CAMPUS';
  String get campusTagline => isEnglish
      ? 'Institutional Pedagogical Command Center'
      : 'Le poste de pilotage pédagogique de l’établissement';

  // Navigation Items
  String get navOverview => isEnglish ? 'Overview' : 'Vue générale';
  String get navToday => isEnglish ? 'Today' : 'Aujourd’hui';
  String get navProgram => isEnglish ? 'Curriculum Plan' : 'Programme';
  String get navClasses => isEnglish ? 'Classes' : 'Classes';
  String get navStudents => isEnglish ? 'Students' : 'Élèves';
  String get navStaff => isEnglish ? 'Staff' : 'Enseignants';
  String get navEvaluations => isEnglish ? 'Assessments' : 'Évaluations';
  String get navStudio => isEnglish ? 'Studio' : 'Studio';
  String get navCommunications =>
      isEnglish ? 'Communications' : 'Communications';
  String get navReports => isEnglish ? 'Reports' : 'Rapports';
  String get navAdministration =>
      isEnglish ? 'Administration' : 'Administration';

  // Common UI Actions & States
  String get searchPlaceholder => isEnglish ? 'Search...' : 'Rechercher...';
  String get retryLabel => isEnglish ? 'Retry' : 'Réessayer';
  String get cancelLabel => isEnglish ? 'Cancel' : 'Annuler';
  String get saveLabel => isEnglish ? 'Save' : 'Enregistrer';
  String get publishLabel => isEnglish ? 'Publish' : 'Publier';
  String get inviteLabel => isEnglish ? 'Invite' : 'Inviter';
  String get actionsLabel => isEnglish ? 'Actions' : 'Actions';
  String get closeLabel => isEnglish ? 'Close' : 'Fermer';
  String get filterAll => isEnglish ? 'All' : 'Tous';
  String get emptyStateDefault =>
      isEnglish ? 'No records available.' : 'Aucun élément disponible.';

  // Direction Dashboard
  String get schoolYearLabel => isEnglish ? 'School year' : 'Année scolaire';
  String get attentionSectionTitle => isEnglish
      ? 'Priority points for this week'
      : 'Ce qui mérite votre attention cette semaine';
  String get kpiCurriculumProgress => isEnglish
      ? 'Planned sequences started'
      : 'Séquences engagées du programme';
  String get kpiDifficulties => isEnglish
      ? 'Recurring consolidation points'
      : 'Points de consolidation récurrents';
  String get kpiStaffSync => isEnglish
      ? 'Teachers updated current chapter'
      : 'Enseignants à jour sur le chapitre';
  String get kpiClassesToReview => isEnglish
      ? 'Classes flagged for pedagogical follow-up'
      : 'Classes signalées pour suivi pédagogique';

  // Teacher Home
  String teacherGreeting(String name) =>
      isEnglish ? 'Welcome, $name' : 'Bonjour, $name';
  String get currentChapterLabel =>
      isEnglish ? 'Current chapter' : 'Chapitre en cours';
  String sequenceCount(int current, int total) => isEnglish
      ? 'Sequence $current of $total'
      : 'Séquence $current sur $total';
  String classNeedsConsolidation(String topic) => isEnglish
      ? 'The class appears to need consolidation on: $topic'
      : 'La classe semble avoir besoin de reprendre : $topic';

  String get actionContinueChapter =>
      isEnglish ? 'Continue chapter' : 'Continuer le chapitre';
  String get actionPrepareQuiz =>
      isEnglish ? 'Prepare assessment' : 'Préparer un quiz';
  String get actionAddResource =>
      isEnglish ? 'Share resource' : 'Ajouter une ressource';
  String get actionViewClass => isEnglish ? 'View class' : 'Voir la classe';

  // Class Detail & Mastery
  String get collectiveMasteryTitle =>
      isEnglish ? 'Collective comprehension' : 'Compréhension collective';
  String get masterySolidLabel => isEnglish ? 'Solid' : 'Solide';
  String get masteryWellUnderstoodLabel =>
      isEnglish ? 'Well understood' : 'Bien compris';
  String get masteryConstructingLabel =>
      isEnglish ? 'In construction' : 'En construction';
  String get masteryInsufficientLabel =>
      isEnglish ? 'Insufficient evidence' : 'Pas assez d’éléments';
  String get toConsolidateTitle =>
      isEnglish ? 'To consolidate' : 'À consolider';
  String get positiveMomentumTitle =>
      isEnglish ? 'Positive momentum' : 'Bonne dynamique';
  String get teacherLabel => isEnglish ? 'Teacher' : 'Enseignant';
  String chapterProgressLabel(int current, int total) =>
      isEnglish ? 'Chapter $current of $total' : 'Chapitre $current sur $total';

  // Student Directory & Detail
  String get studentMatriculeLabel => isEnglish ? 'Student ID' : 'Matricule';
  String get accessStatusLabel =>
      isEnglish ? 'Access status' : 'Statut d’accès';
  String get learningEvidenceLabel =>
      isEnglish ? 'Learning evidence' : 'Preuve d’apprentissage';
  String get lastActivityLabel =>
      isEnglish ? 'Last activity' : 'Dernière activité';
  String chaptersExploredCount(int current, int total) => isEnglish
      ? '$current / $total chapters explored'
      : '$current / $total chapitres explorés';
  String quizActivitiesCount(int count) => isEnglish
      ? '$count quiz activities completed'
      : '$count activités quiz réalisées';
  String get actionOfferRevision =>
      isEnglish ? 'Suggest revision' : 'Proposer une révision';
  String get actionAssignQuiz => isEnglish ? 'Assign quiz' : 'Affecter un quiz';
  String get actionShareResource =>
      isEnglish ? 'Share resource' : 'Partager une ressource';

  // Staff & Invitations
  String get addStaffTitle => isEnglish ? 'Add member' : 'Ajouter un membre';
  String get staffFullNameLabel => isEnglish ? 'Full name' : 'Nom complet';
  String get staffPhoneLabel => isEnglish ? 'Phone number' : 'Téléphone';
  String get staffEmailLabel =>
      isEnglish ? 'Email (optional)' : 'E-mail facultatif';
  String get staffRoleLabel => isEnglish ? 'Role / Function' : 'Fonction';
  String get staffSubjectsLabel => isEnglish ? 'Subject(s)' : 'Matière(s)';
  String get staffClassesLabel => isEnglish ? 'Class(es)' : 'Classe(s)';
  String get invitationReadyTitle =>
      isEnglish ? 'Invitation ready' : 'Invitation prête';
  String get invitationReadySubtitle => isEnglish
      ? 'Member will be invited to access INTELLIA Campus.'
      : 'Le membre pourra se connecter sur INTELLIA Campus.';
  String get actionSuspendAccess =>
      isEnglish ? 'Suspend access' : 'Suspendre l’accès';
  String get actionRestoreAccess =>
      isEnglish ? 'Restore access' : 'Rétablir l’accès';
  String get confirmSuspensionTitle => isEnglish
      ? 'Confirm access suspension'
      : 'Confirmer la suspension d’accès';
  String confirmSuspensionBody(String name) => isEnglish
      ? 'Are you sure you want to suspend access for $name? They will not be able to log in to Campus until restored.'
      : 'Êtes-vous certain de vouloir suspendre l’accès de $name ? Ce membre ne pourra plus se connecter à Campus jusqu’à réactivation.';

  // Program & Teaching Plan
  String get plannedStartLabel => isEnglish ? 'Planned start' : 'Début prévu';
  String get plannedEndLabel => isEnglish ? 'Planned end' : 'Fin prévue';
  String get statusPlanned => isEnglish ? 'Planned' : 'Planifié';
  String get statusInProgress => isEnglish ? 'In progress' : 'En cours';
  String get statusCompleted => isEnglish ? 'Completed' : 'Terminé';
  String get statusDelayed => isEnglish ? 'Delayed' : 'En retard';

  // Studio & Quiz Creation
  String get draftBadgeLabel => isEnglish ? 'Draft' : 'Brouillon';
  String get generateDraftQuizButton =>
      isEnglish ? 'Generate draft' : 'Générer un brouillon';
  String get quizPurposeLabel => isEnglish ? 'Purpose' : 'Finalité';
  String get quizDifficultyLabel => isEnglish ? 'Difficulty' : 'Difficulté';
  String get quizQuestionCountLabel =>
      isEnglish ? 'Question count' : 'Nombre de questions';
  String get purposeRevision => isEnglish ? 'Revision' : 'Révision';
  String get purposeDiagnostic => isEnglish ? 'Diagnostic' : 'Diagnostic';
  String get purposeHomework => isEnglish ? 'Homework' : 'Devoir';
  String get difficultyAccessible => isEnglish ? 'Accessible' : 'Accessible';
  String get difficultyStandard => isEnglish ? 'Standard' : 'Standard';
  String get difficultyChallenging => isEnglish ? 'Challenging' : 'Approfondi';

  // Communications
  String get newAnnouncementTitle =>
      isEnglish ? 'New announcement' : 'Nouvelle communication';
  String get audienceLabel => isEnglish ? 'Audience' : 'Destinataires';
  String get audienceAll =>
      isEnglish ? 'Whole establishment' : 'Tout l’établissement';
  String get audienceClass => isEnglish ? 'Single class' : 'Une classe';
  String get audienceTeachers => isEnglish ? 'Teachers' : 'Enseignants';
  String get audienceParents => isEnglish ? 'Parents' : 'Parents';
  String get audienceStudents => isEnglish ? 'Students' : 'Élèves';

  // Audit Log
  String get auditLogTitle => isEnglish
      ? 'Institutional audit log'
      : 'Journal d’activité institutionnelle';
  String get auditLogSubtitle => isEnglish
      ? 'Immutable record of pedagogical and administrative operations.'
      : 'Enregistrement immuable des opérations pédagogiques et administratives.';

  // Safe Errors
  String get errorLoadingClasses => isEnglish
      ? 'Unable to load classes at the moment.'
      : 'Impossible de charger les classes pour le moment.';
  String get errorLoadingStudents => isEnglish
      ? 'Unable to load students at the moment.'
      : 'Impossible de charger les élèves pour le moment.';
  String get errorLoadingStaff => isEnglish
      ? 'Unable to load staff at the moment.'
      : 'Impossible de charger les membres du personnel pour le moment.';
  String get errorLoadingOverview => isEnglish
      ? 'Unable to load overview data at the moment.'
      : 'Impossible de charger les données de pilotage pour le moment.';

  // Domain Enum Labels
  String roleLabel(CampusRole role) {
    switch (role) {
      case CampusRole.headOfSchool:
        return isEnglish ? 'Head of School' : 'Chef d’établissement';
      case CampusRole.pedagogicalLead:
        return isEnglish ? 'Pedagogical Lead' : 'Directeur des Études';
      case CampusRole.departmentHead:
        return isEnglish ? 'Department Head' : 'Chef de département';
      case CampusRole.teacher:
        return isEnglish ? 'Teacher' : 'Enseignant';
      case CampusRole.schoolAdmin:
        return isEnglish ? 'School Administrator' : 'Intendant';
      case CampusRole.counsellor:
        return isEnglish ? 'Counsellor' : 'Conseiller d’orientation';
      case CampusRole.observer:
        return isEnglish ? 'Observer' : 'Observateur';
    }
  }

  String membershipStatusLabel(MembershipStatus status) {
    switch (status) {
      case MembershipStatus.invited:
        return isEnglish ? 'Invited' : 'Invité';
      case MembershipStatus.active:
        return isEnglish ? 'Active' : 'Actif';
      case MembershipStatus.suspended:
        return isEnglish ? 'Suspended' : 'Suspendu';
      case MembershipStatus.archived:
        return isEnglish ? 'Archived' : 'Archivé';
    }
  }

  String teachingPlanStatusLabel(TeachingPlanStatus status) {
    switch (status) {
      case TeachingPlanStatus.planned:
        return statusPlanned;
      case TeachingPlanStatus.inProgress:
        return statusInProgress;
      case TeachingPlanStatus.completed:
        return statusCompleted;
      case TeachingPlanStatus.delayed:
        return statusDelayed;
    }
  }

  String resourceStatusLabel(ResourceStatus status) {
    switch (status) {
      case ResourceStatus.draft:
        return draftBadgeLabel;
      case ResourceStatus.pendingReview:
        return isEnglish ? 'Pending review' : 'À valider';
      case ResourceStatus.published:
        return isEnglish ? 'Published' : 'Publié';
      case ResourceStatus.archived:
        return isEnglish ? 'Archived' : 'Archivé';
    }
  }

  String learnerEvidenceLabel(LearnerEvidenceStatus status) {
    switch (status) {
      case LearnerEvidenceStatus.solidMastery:
        return masterySolidLabel;
      case LearnerEvidenceStatus.wellUnderstood:
        return masteryWellUnderstoodLabel;
      case LearnerEvidenceStatus.inConstruction:
        return masteryConstructingLabel;
      case LearnerEvidenceStatus.insufficientEvidence:
        return masteryInsufficientLabel;
    }
  }
}
