// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get adminManageProfile => 'Administrer le profil';

  @override
  String get adminSuspendProfile => 'Suspendre le profil';

  @override
  String get adminReactivateProfile => 'Réactiver le profil';

  @override
  String get adminRestoreProfile => 'Restaurer le profil';

  @override
  String get adminDeleteProfile => 'Supprimer le profil';

  @override
  String get adminAccountUpdated => 'Le profil a été mis à jour.';

  @override
  String get adminDeleteProfileBody =>
      'Le profil sera retiré des annuaires et son accès sera bloqué. Ses données seront conservées pour permettre sa restauration par l’administration générale.';

  @override
  String get adminAccountDecisionBody =>
      'Cette décision modifie l’accès du compte. Son motif sera conservé dans l’historique d’administration.';

  @override
  String get adminDecisionReason => 'Motif de la décision';

  @override
  String get adminCreateStudent => 'Ajouter un élève';

  @override
  String get adminCreateStudentBody =>
      'Crée son compte dans l’établissement choisi. L’élève se connectera avec son numéro, puis complétera sa classe et ses préférences.';

  @override
  String get adminStudentCreated =>
      'Le compte élève est créé. Il peut se connecter par téléphone.';

  @override
  String get adminStudentContactExists =>
      'Ce téléphone ou cet e-mail possède déjà un compte. Retrouve-le avec la recherche.';

  @override
  String get adminStudentFirstName => 'Prénom';

  @override
  String get adminStudentLastName => 'Nom';

  @override
  String get adminFieldRequired => 'Ce champ est obligatoire.';

  @override
  String get adminStudentEmailOptional => 'E-mail (facultatif)';

  @override
  String get adminInvalidEmail => 'Vérifie l’adresse e-mail.';

  @override
  String get adminStatusSuspended => 'Compte suspendu';

  @override
  String get adminStatusDeleted => 'Profil supprimé';

  @override
  String get backToPreviousAct => 'Revenir à l’acte précédent';

  @override
  String get onboardingOpeningBody =>
      'Une expérience d’apprentissage pour mieux comprendre, pratiquer et progresser.';

  @override
  String get onboardingTapToContinue => 'Appuie pour continuer';

  @override
  String get companionSwitchHint =>
      'Touche ou balaie pour changer de personnalité.';

  @override
  String get companionChangeLater => 'Tu pourras changer plus tard.';

  @override
  String get ascensionSemanticLabel => 'L’Ascension';

  @override
  String get ascensionEyebrow => 'ACTE VI — L’ASCENSION';

  @override
  String get ascensionTitle => 'Ton avenir se construit, marche après marche.';

  @override
  String get ascensionBody =>
      'INTELLIA237 complète tes cours, tes livres et tes cahiers pour t’aider à comprendre, t’entraîner et progresser. Tes enseignants restent au cœur de ton parcours.';

  @override
  String get ascensionCta => 'Créer mon INTELLIA PASS';

  @override
  String get ascensionImageA11y =>
      'Deux élèves avancent vers une bibliothèque lumineuse, symbole de leur progression scolaire';

  @override
  String get portalContinue => 'Découvrir la suite';

  @override
  String get passEyebrow => 'INTELLIA PASS';

  @override
  String get passTitle => 'Qui utilise INTELLIA237 ?';

  @override
  String get passSubtitle =>
      'Un accès clair pour chaque membre de la famille, même lorsque l’appareil est partagé.';

  @override
  String get studentRole => 'Élève';

  @override
  String get studentRoleDescription =>
      'Apprendre, s’entraîner et progresser avec un compagnon pédagogique.';

  @override
  String get parentRole => 'Parent ou responsable';

  @override
  String get parentRoleDescription =>
      'Créer le foyer, ajouter plusieurs enfants et suivre leur progression.';

  @override
  String get professionalAccess => 'Accès professionnel';

  @override
  String get teacherRole => 'Enseignant';

  @override
  String get teacherRoleDescription =>
      'Préparer les classes et partager des ressources pédagogiques.';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get existingAccount => 'J’ai déjà un compte';

  @override
  String chooseIdentityA11y(String role) {
    return 'Choisir le profil $role';
  }

  @override
  String get householdQuestion => 'Qui apprend aujourd’hui ?';

  @override
  String get householdSubtitle =>
      'Choisissez un profil élève. Le changement de profil ne contourne jamais les autorisations du parent.';

  @override
  String get addLearner => 'Ajouter un enfant';

  @override
  String get parentArea => 'Espace parent';

  @override
  String get academicPassport => 'Passeport scolaire';

  @override
  String get academicPassportDescription =>
      'Parle-nous un peu de toi pour préparer ton espace.';

  @override
  String get interfaceLanguage => 'Langue de l’interface';

  @override
  String get frenchLanguage => 'Français';

  @override
  String get englishLanguage => 'English';

  @override
  String get educationalSubsystem => 'Sous-système éducatif';

  @override
  String get francophoneSubsystem => 'Francophone';

  @override
  String get anglophoneSubsystem => 'Anglophone';

  @override
  String get educationType => 'Type d’enseignement';

  @override
  String get generalEducation => 'Général';

  @override
  String get technicalEducation => 'Technique';

  @override
  String get schoolLevel => 'Niveau';

  @override
  String get streamOrSpeciality => 'Série, filière ou spécialité';

  @override
  String get establishment => 'Établissement';

  @override
  String get establishmentHint => 'Rechercher ou saisir un établissement';

  @override
  String get establishmentUnverified =>
      'Établissement sélectionné — vérification en attente';

  @override
  String get establishmentSecurityNote =>
      'La sélection d’un établissement ne donne accès à aucune donnée privée. L’autorisation du serveur reste obligatoire.';

  @override
  String get individualAccount => 'Compte élève individuel';

  @override
  String get parentLinkedAccount => 'Compte rattaché au foyer familial';

  @override
  String get parentLinkedHelp =>
      'Le parent crée et protège les profils du foyer depuis son espace.';

  @override
  String get learningCompanion => 'Compagnon pédagogique';

  @override
  String get createAccount => 'Créer mon compte';

  @override
  String get previousStep => 'Étape précédente';

  @override
  String get phoneOtp => 'Téléphone et code de vérification';

  @override
  String get emailAuthentication => 'Adresse e-mail';

  @override
  String get availableNow => 'Disponible maintenant';

  @override
  String get plannedLater => 'Prévu ultérieurement';

  @override
  String get loginEyebrow => 'Votre espace personnel';

  @override
  String get loginTitle => 'Heureux de vous retrouver.';

  @override
  String get loginSubtitle =>
      'Reprenez votre progression et retrouvez votre compagnon pédagogique.';

  @override
  String get emailLabel => 'Adresse e-mail';

  @override
  String get emailHint => 'prenom.nom@exemple.com';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get passwordHint => 'Votre mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get signIn => 'Se connecter';

  @override
  String get noAccount => 'Pas encore de compte ?';

  @override
  String get createAccountLink => 'Créer un compte';

  @override
  String get forgotEyebrow => 'Accès au compte';

  @override
  String get forgotTitle => 'Retrouvez votre mot de passe.';

  @override
  String get forgotSubtitle =>
      'Nous enverrons un lien sécurisé à l’adresse de votre compte.';

  @override
  String get emailSent => 'E-mail envoyé';

  @override
  String checkEmail(String email) {
    return 'Consultez $email et ouvrez le lien reçu.';
  }

  @override
  String get backToLogin => 'Retour à la connexion';

  @override
  String get sendLink => 'Envoyer le lien';

  @override
  String get phonePrimary => 'Téléphone camerounais';

  @override
  String get phonePrimaryHint => '+237 6XX XX XX XX';

  @override
  String get emailOptional => 'E-mail (optionnel)';

  @override
  String get phoneIdentityTarget => 'Identité cible : téléphone + code OTP';

  @override
  String get temporaryEmailNotice =>
      'Dans cette version, un e-mail technique reste temporairement nécessaire pour créer le compte Firebase. Il ne constitue pas l’identité principale cible.';

  @override
  String get temporaryEmailLabel => 'E-mail technique (temporaire)';

  @override
  String get otpChannelTitle => 'Comment souhaitez-vous recevoir le code ?';

  @override
  String get otpWhatsapp => 'Recevoir le code par WhatsApp';

  @override
  String get otpSms => 'Recevoir le code par SMS';

  @override
  String get otpSmsFallback =>
      'Le SMS reste disponible si vous n’utilisez pas WhatsApp.';

  @override
  String get studyModeTitle => 'Mode Étude';

  @override
  String get studyModeDuration => 'Choisissez la durée d’étude';

  @override
  String get studyModeComplete => 'Session terminée';

  @override
  String get studyModeCompleteBody =>
      'L’appareil reste dans INTELLIA237 jusqu’à ce que le parent le récupère.';

  @override
  String get studyModeFamilyCopy =>
      'Prêtez votre téléphone pour étudier, pas pour se distraire.';

  @override
  String get reclaimDevice => 'Récupérer l’appareil';

  @override
  String get preparingYourSpace => 'Préparation de ton espace…';

  @override
  String companionQuotaReached(String name) {
    return 'Tu as utilisé toutes tes questions du jour. Tu pourras de nouveau interroger $name demain.';
  }

  @override
  String companionProfileSync(String name) {
    return '$name a besoin de resynchroniser ton profil avant de répondre. Tes cours et exercices restent disponibles.';
  }

  @override
  String companionInvalidRequest(String name) {
    return '$name ne peut pas traiter cette question. Reformule-la en quelques mots.';
  }

  @override
  String companionNetworkUnavailable(String name) {
    return '$name n’arrive pas à se connecter pour le moment. Vérifie ta connexion; tes cours et exercices restent disponibles.';
  }

  @override
  String companionServiceUnavailable(String name) {
    return '$name n’arrive pas à répondre pour le moment. Tu peux continuer à consulter tes cours et exercices.';
  }

  @override
  String companionInvalidResponse(String name) {
    return '$name a reçu une réponse incomplète. Tu peux réessayer dans un instant.';
  }

  @override
  String get companionStatusReady => 'Prêt à t’aider';

  @override
  String get companionStatusThinking => 'réfléchit…';

  @override
  String get companionStatusQuota => 'limite du jour atteinte';

  @override
  String get companionStatusProfile => 'profil à synchroniser';

  @override
  String get companionStatusNetwork => 'connexion à retrouver';

  @override
  String get companionStatusUnavailable => 'réponse indisponible';

  @override
  String get phoneAuthEyebrow => 'ACCÈS SÉCURISÉ · 237';

  @override
  String get phoneAuthTitle => 'Votre numéro ouvre votre espace.';

  @override
  String get phoneAuthSubtitle =>
      'Nous envoyons un code unique par SMS. Aucun e-mail n’est nécessaire.';

  @override
  String get phoneLinkTitle => 'Ajouter votre téléphone.';

  @override
  String get phoneLinkSubtitle =>
      'Votre compte et votre profil actuels restent inchangés.';

  @override
  String get cameroonCountry => 'Cameroun';

  @override
  String get phoneNumberLabel => 'Numéro de téléphone';

  @override
  String get phoneNumberLocalHint => '6XX XX XX XX';

  @override
  String get sendVerificationCode => 'Recevoir mon code';

  @override
  String get useEmailCompatibility => 'Utiliser mon e-mail à la place';

  @override
  String get phoneCodeTitle => 'Saisissez les 6 chiffres.';

  @override
  String phoneCodeSubtitle(String phone) {
    return 'Le code a été envoyé au $phone.';
  }

  @override
  String get verificationCodeLabel => 'Code de vérification';

  @override
  String get verificationCodeHint => '000000';

  @override
  String get verifyCode => 'Vérifier le code';

  @override
  String get changePhoneNumber => 'Modifier le numéro';

  @override
  String get resendCode => 'Renvoyer le code';

  @override
  String resendCodeIn(int seconds) {
    return 'Renvoyer dans $seconds s';
  }

  @override
  String get smsAutoRetrievalTimeout =>
      'La détection automatique est terminée. Saisissez le code reçu ou renvoyez-en un.';

  @override
  String get phoneVerificationSuccess => 'Numéro vérifié';

  @override
  String get phoneVerificationSuccessBody => 'Votre accès sécurisé est prêt.';

  @override
  String get phoneLinkSuccessBody =>
      'Votre numéro est maintenant lié à ce même compte.';

  @override
  String get phoneErrorInvalidNumber =>
      'Saisissez un numéro mobile camerounais valide à 9 chiffres.';

  @override
  String get phoneErrorInvalidCode =>
      'Le code saisi est incorrect ou a expiré.';

  @override
  String get phoneErrorTooManyRequests =>
      'Les demandes de code sont temporairement bloquées par Firebase. Le délai de déblocage n’est pas communiqué et peut dépasser une heure. Évite les demandes répétées. Si tu as déjà associé un e-mail à ton compte, utilise-le pour te connecter.';

  @override
  String get phoneErrorAppVerification =>
      'Cette version de l’application n’a pas pu être vérifiée. Contacte l’assistance avec la référence ci-dessous.';

  @override
  String get phoneErrorCaptcha =>
      'La vérification de sécurité n’a pas abouti. Réessaie depuis l’application.';

  @override
  String phoneRequestPause(int seconds) {
    return 'Nouvelle demande dans $seconds s';
  }

  @override
  String get phoneErrorQuota =>
      'L’envoi de SMS est momentanément indisponible. Réessayez plus tard.';

  @override
  String get phoneErrorNetwork =>
      'La connexion est interrompue. Vérifiez Internet puis réessayez.';

  @override
  String get phoneErrorDisabled =>
      'La connexion par téléphone doit être activée dans Firebase Authentication.';

  @override
  String get phoneErrorCollision =>
      'Ce numéro est déjà lié à un autre compte. Reconnectez-vous avec ce numéro ou contactez l’assistance.';

  @override
  String get phoneErrorRecentLogin =>
      'Reconnectez-vous avant d’ajouter ce numéro.';

  @override
  String get phoneErrorProfileMissing =>
      'Aucun profil INTELLIA237 n’est encore associé à ce numéro. Créez d’abord votre compte.';

  @override
  String get phoneErrorGeneric =>
      'La vérification n’a pas abouti. Réessayez dans un instant.';

  @override
  String get schoolSearchLabel => 'Votre établissement';

  @override
  String get schoolSearchHint => 'Commencez à écrire son nom ou sa ville';

  @override
  String get schoolSearchHelp =>
      'Les meilleurs résultats apparaissent au fil de votre saisie.';

  @override
  String get schoolSelectedPending =>
      'Sélection enregistrée · affiliation en attente de vérification';

  @override
  String get schoolNotFound => 'Mon établissement n’apparaît pas';

  @override
  String get schoolSuggestionTitle => 'Proposer un établissement';

  @override
  String get schoolSuggestionBody =>
      'Cette proposition sera examinée. Elle ne crée jamais une affiliation vérifiée.';

  @override
  String get schoolNameLabel => 'Nom de l’établissement';

  @override
  String get schoolCityLabel => 'Ville';

  @override
  String get schoolRegionLabel => 'Région';

  @override
  String get schoolSuggestionSubmit => 'Envoyer la proposition';

  @override
  String get schoolSuggestionSaved =>
      'Proposition enregistrée · vérification en attente';

  @override
  String get schoolSuggestionRequired =>
      'Renseignez le nom, la ville et la région.';

  @override
  String get schoolTypeLycee => 'Lycée';

  @override
  String get schoolTypeCollege => 'Collège';

  @override
  String get schoolTypeTechnical => 'Technique';

  @override
  String get schoolTypeGovernment => 'Public';

  @override
  String get schoolTypePrivate => 'Privé';

  @override
  String get schoolSubsystemFrancophone => 'Francophone';

  @override
  String get schoolSubsystemAnglophone => 'Anglophone';

  @override
  String get schoolSubsystemBilingual => 'Bilingue';

  @override
  String get selectedCompanionEyebrow => 'TON COMPAGNON';

  @override
  String get changeCompanion => 'Modifier mon compagnon';

  @override
  String get leoProfileTagline => 'Sciences · méthode · raisonnement';

  @override
  String get kiraProfileTagline => 'Clarté · confiance · progression';

  @override
  String get stepIdentity => 'Identité';

  @override
  String get stepClass => 'Classe';

  @override
  String get stepCompanion => 'Compagnon';

  @override
  String get stepSecurity => 'Sécurité';

  @override
  String get studentSpaceEyebrow => 'Espace élève';

  @override
  String get studentRegistrationTitle => 'Crée ton parcours\nIntellia 237.';

  @override
  String get studentRegistrationSubtitle =>
      'Quatre étapes rapides pour préparer ton espace personnel.';

  @override
  String get firstNameLabel => 'Prénom';

  @override
  String get firstNameHint => 'Ex. Marie';

  @override
  String get lastNameLabel => 'Nom';

  @override
  String get lastNameHint => 'Ex. Ndi';

  @override
  String get seriesLabel => 'Série';

  @override
  String get meetCompanionTitle => 'Rencontre ton compagnon';

  @override
  String get meetCompanionSubtitle =>
      'Découvre Kira, puis Léo. Tu choisiras une fois que tu les auras vus.';

  @override
  String get secureAccountTitle => 'Sécurise ton compte';

  @override
  String get secureAccountPhoneVerified =>
      'Ton numéro a été vérifié. Relis tes choix avant de créer ton espace.';

  @override
  String get phoneVerifiedNoExtraCredential =>
      'Votre numéro a été vérifié. Aucun e-mail ni mot de passe supplémentaire n’est nécessaire.';

  @override
  String get classToConfirm => 'Classe à confirmer';

  @override
  String get acceptTerms => 'J’accepte les conditions d’utilisation.';

  @override
  String get acceptPrivacy => 'J’accepte la politique de confidentialité.';

  @override
  String get acceptLearningData =>
      'J’accepte le traitement pédagogique des données.';

  @override
  String get parentRegistrationTitle => 'Créer un compte Parent';

  @override
  String get parentStepIdentity => 'Identité parent';

  @override
  String get parentStepChildren => 'Liaison enfants';

  @override
  String get parentStepFinal => 'Validation finale';

  @override
  String get parentDetailsTitle => 'Coordonnées du parent';

  @override
  String get parentDetailsSubtitle =>
      'Quelques informations suffisent pour préparer le parcours de votre enfant.';

  @override
  String get linkChildrenTitle => 'Lier vos enfants';

  @override
  String get linkChildrenSubtitle =>
      'Ajoutez un identifiant élève maintenant, ou plus tard.';

  @override
  String get childIdentifierLabel => 'Code / Identifiant enfant';

  @override
  String get childIdentifierHint => 'Ex. STU-94K2';

  @override
  String get addLabel => 'Ajouter';

  @override
  String get noLinkedChild => 'Aucun enfant lié pour le moment.';

  @override
  String get finalReviewTitle => 'Validation finale';

  @override
  String get finalReviewSubtitle =>
      'Relisez vos informations et acceptez les consentements requis.';

  @override
  String get parentChildrenLater =>
      'Vous pourrez également lier ou modifier vos enfants après la création de votre compte.';

  @override
  String get previousLabel => 'Précédent';

  @override
  String get nextLabel => 'Suivant';

  @override
  String get createParentAccount => 'Créer mon compte parent';

  @override
  String get retryLabel => 'Réessayer';

  @override
  String get cancelLabel => 'Annuler';

  @override
  String get confirmLabel => 'Valider';

  @override
  String get refreshLabel => 'Actualiser';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get readingComfortSection => 'Confort de lecture';

  @override
  String get textSizeLabel => 'Taille du texte';

  @override
  String get reduceMotionLabel => 'Réduire les animations';

  @override
  String get reduceMotionDescription =>
      'Remplace les mouvements décoratifs par des transitions sobres.';

  @override
  String get dataRemindersSection => 'Données et rappels';

  @override
  String get weeklyGoalTitle => 'Mon objectif de la semaine';

  @override
  String get weeklyGoalUnset => 'Non défini — choisis ton rythme.';

  @override
  String weeklyGoalSummary(int sessions, int minutes) {
    return '$sessions séances par semaine · ~$minutes min';
  }

  @override
  String get dataSaverLabel => 'Économie de données';

  @override
  String get dataSaverDescription =>
      'Privilégie les contenus légers et limite les effets coûteux.';

  @override
  String get learningRemindersLabel => 'Rappels d’apprentissage';

  @override
  String get learningRemindersDescription =>
      'Un rappel au maximum par jour, activé seulement après ton autorisation système.';

  @override
  String get reminderTimeLabel => 'Heure du rappel';

  @override
  String get anonymousDiagnosticsLabel => 'Diagnostics anonymes';

  @override
  String get anonymousDiagnosticsDescription =>
      'Aide à repérer les pannes et parcours bloqués. Aucun message au compagnon, réponse libre, nom ou e-mail n’est collecté.';

  @override
  String get privacySection => 'Confidentialité';

  @override
  String get personalDataTitle => 'Données personnelles';

  @override
  String get personalDataDescription =>
      'Intellia237 ne doit jamais envoyer les conversations pédagogiques dans les outils de mesure.';

  @override
  String get deleteAccountTitle => 'Suppression du compte';

  @override
  String get deleteAccountDescription =>
      'Envoyer une demande de suppression sécurisée.';

  @override
  String get accountSection => 'Compte';

  @override
  String get addPhoneTitle => 'Ajouter ou sécuriser mon numéro';

  @override
  String get addPhoneDescription =>
      'Lie un numéro +237 sans changer ce compte ni son profil.';

  @override
  String get editProfileTitle => 'Modifier mon profil';

  @override
  String get editProfileDescription => 'Nom, téléphone et photo de profil.';

  @override
  String get signOutTitle => 'Se déconnecter';

  @override
  String get signOutDescription =>
      'Tes données synchronisées seront disponibles à ta prochaine connexion.';

  @override
  String get deleteRequestQuestion => 'Demander la suppression ?';

  @override
  String get deleteRequestBody =>
      'Le compte et ses données seront supprimés dans 7 jours. D’ici là, le compte reste utilisable et la demande peut être annulée depuis cet écran.';

  @override
  String get sendRequestLabel => 'Envoyer la demande';

  @override
  String get deleteRequestError =>
      'Impossible d’envoyer la demande maintenant. Réessaie plus tard.';

  @override
  String deleteScheduledSubtitle(String date) {
    return 'Suppression prévue le $date. Touchez pour annuler.';
  }

  @override
  String deleteScheduledConfirmation(String date) {
    return 'Suppression programmée le $date. Elle peut être annulée d’ici là.';
  }

  @override
  String get deleteInProgressSubtitle => 'Suppression en cours de traitement.';

  @override
  String get cancelDeletionQuestion => 'Annuler la suppression ?';

  @override
  String get cancelDeletionBody =>
      'Le compte sera conservé et la demande abandonnée.';

  @override
  String get cancelDeletionAction => 'Annuler la suppression';

  @override
  String get cancelDeletionDone => 'La suppression est annulée.';

  @override
  String get cancelDeletionError =>
      'Impossible d’annuler la demande maintenant. Réessayez plus tard.';

  @override
  String get chooseReminderTime => 'Choisir l’heure du rappel';

  @override
  String get signOutQuestion => 'Se déconnecter ?';

  @override
  String get emailVerificationTitle => 'Vérification de l’adresse e-mail';

  @override
  String get statusUnavailable => 'Statut momentanément indisponible.';

  @override
  String get emailVerifiedTitle => 'Adresse e-mail vérifiée';

  @override
  String get verifyEmailTitle => 'Vérifie ton e-mail';

  @override
  String get emailRecoveryDescription =>
      'Protège ton compte et facilite sa récupération.';

  @override
  String get resendLabel => 'Renvoyer';

  @override
  String get emailVerificationSent =>
      'E-mail envoyé. Ouvre le lien reçu puis actualise ce statut.';

  @override
  String accountReadyWithCompanion(String name) {
    return 'Ton compte est prêt. $name t’accompagne dès maintenant.';
  }

  @override
  String get discoverIntellia => 'Découvrir Intellia 237';

  @override
  String get learnTitle => 'Apprendre';

  @override
  String get learnEyebrow => 'Explorer · comprendre · progresser';

  @override
  String get learnUnavailableTitle =>
      'Tes matières ne sont pas disponibles pour le moment';

  @override
  String get learnUnavailableBody => 'Réessaie dans quelques instants.';

  @override
  String get learnUnavailableOfflineBody =>
      'Vérifie ta connexion, puis réessaie. Ton parcours reste disponible.';

  @override
  String get learnSubtitle => 'Tes matières, adaptées à ton niveau.';

  @override
  String get subjectsLoadError => 'Impossible de charger les matières';

  @override
  String get subjectsComingTitle => 'Tes matières arrivent';

  @override
  String get subjectsComingBody =>
      'Les cours de ta classe sont en cours de préparation. Tu seras parmi les premiers à en profiter.';

  @override
  String get noSubjectFound => 'Aucune matière trouvée';

  @override
  String get tryAnotherKeyword => 'Essaie un autre mot-clé.';

  @override
  String get clearSearch => 'Effacer la recherche';

  @override
  String get personalizedPath => 'Parcours personnalisé';

  @override
  String get levelAdaptedContent => 'Contenus adaptés à ton niveau actuel.';

  @override
  String get searchSubjectHint => 'Rechercher une matière…';

  @override
  String get subjectGenericTitle => 'Matière';

  @override
  String get subjectUnavailable => 'Matière indisponible';

  @override
  String get chaptersTitle => 'Chapitres';

  @override
  String get chaptersComingTitle => 'Chapitres en préparation';

  @override
  String get chaptersComingBody =>
      'Le contenu de cette matière est en cours de rédaction pour ta classe. Reviens bientôt !';

  @override
  String lessonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leçons',
      one: '1 leçon',
      zero: 'Aucune leçon',
    );
    return '$_temp0';
  }

  @override
  String get lessonsTitle => 'Leçons';

  @override
  String get lessonsComingTitle => 'Leçons en préparation';

  @override
  String get lessonsComingBody =>
      'Les leçons de ce chapitre sont en cours de rédaction. Reviens bientôt.';

  @override
  String get chapterSavedOffline =>
      'Chapitre enregistré pour la lecture hors connexion';

  @override
  String get availableOffline => 'Disponible hors connexion';

  @override
  String get studyOffline => 'Étudier sans réseau';

  @override
  String offlineLessonPrepared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leçons préparées sur cet appareil.',
      one: '1 leçon préparée sur cet appareil.',
      zero: 'Aucune leçon préparée sur cet appareil.',
    );
    return '$_temp0';
  }

  @override
  String get prepareOfflineLessons =>
      'Prépare toutes les leçons pour une lecture hors connexion.';

  @override
  String get chapterReadyOffline =>
      'Chapitre prêt pour une lecture hors connexion.';

  @override
  String get downloadFailed =>
      'Le téléchargement n’a pas abouti. Vérifie la connexion et réessaie.';

  @override
  String get nextLabelShort => 'À suivre';

  @override
  String get lessonUnavailable => 'Leçon indisponible';

  @override
  String get localProgressSaved =>
      'Progression conservée sur cet appareil. Elle sera synchronisée automatiquement.';

  @override
  String get markLessonComplete => 'Marquer la leçon comme terminée';

  @override
  String get markComplete => 'Marquer comme terminée';

  @override
  String get completedLabel => 'Terminée';

  @override
  String askTutorAboutLesson(String name) {
    return 'Demander de l’aide à $name sur cette leçon';
  }

  @override
  String askTutorPrompt(String name) {
    return 'Une question ? Demande à $name';
  }

  @override
  String get checkUnderstanding => 'Vérifie ta compréhension';

  @override
  String get lessonCompletedCongrats => 'Leçon terminée, bravo !';

  @override
  String get startNextLesson => 'Commencer la leçon suivante';

  @override
  String get nextLesson => 'Leçon suivante';

  @override
  String get writeQuestionHint => 'Écris ta question…';

  @override
  String stepProgressA11y(int current, int total, String label) {
    return 'Étape $current sur $total: $label';
  }

  @override
  String get networkOfflineBanner =>
      'Aucun réseau détecté — les contenus déjà chargés restent accessibles.';

  @override
  String welcomeName(String name) {
    return 'Bienvenue, $name !';
  }

  @override
  String get closeLabel => 'Fermer';

  @override
  String get companionPromptExplain => 'Explique ce concept';

  @override
  String get companionPromptSummarize => 'Résume en points clés';

  @override
  String get companionPromptExample => 'Donne un exemple concret';

  @override
  String get companionPromptQuestions => 'Pose-moi 3 questions';

  @override
  String companionContext(String topic) {
    return 'Contexte : $topic';
  }

  @override
  String get chapterLabel => 'Chapitre';

  @override
  String get chapterUnavailable => 'Chapitre indisponible';

  @override
  String get chapterEyebrow => 'CHAPITRE';

  @override
  String completedProgress(int done, int total) {
    return '$done/$total terminées';
  }

  @override
  String get saveChapterOffline =>
      'Enregistrer ce chapitre pour la lecture hors connexion';

  @override
  String get reconnectToPrepareLessons =>
      'Reconnecte-toi pour préparer toutes les leçons.';

  @override
  String prepareChapterLessons(int count) {
    return 'Prépare les $count leçons de ce chapitre.';
  }

  @override
  String get prepareLabel => 'Préparer';

  @override
  String get backLabel => 'Revenir en arrière';

  @override
  String get backToChapter => 'Retour au chapitre';

  @override
  String get lastLessonCompleted =>
      'Tu as terminé la dernière leçon de ce chapitre.';

  @override
  String nextStepLesson(String title) {
    return 'Prochaine étape : « $title ».';
  }

  @override
  String get phoneProfileChoicePrompt =>
      'Ce numéro n’a pas encore de profil. Choisis le compte à créer :';

  @override
  String get phoneCreateStudentProfile => 'Créer mon profil élève';

  @override
  String get phoneCreateParentProfile => 'Créer un profil parent';

  @override
  String get authProfileSetupTitle => 'Configuration du compte';

  @override
  String get authCompleteProfileTitle => 'Complète ton profil';

  @override
  String get authSessionActiveTitle => 'Ta session est toujours active';

  @override
  String get authChooseProfileBody =>
      'Choisis le profil à créer. Ta session Firebase vérifiée sera réutilisée.';

  @override
  String get authProfileSyncFailureBody =>
      'Le profil n’a pas pu être synchronisé. Aucune déconnexion automatique n’a été effectuée.';

  @override
  String get chooseRolePrompt => 'Je suis…';

  @override
  String get adminRole => 'Administration';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationMarkAllRead => 'Tout lire';

  @override
  String get notificationsUnavailable => 'Notifications indisponibles';

  @override
  String get notificationsSyncError =>
      'La boîte de réception n’a pas pu être synchronisée. Vérifie la connexion puis réessaie.';

  @override
  String get notificationsEmptyTitle => 'Tout est calme';

  @override
  String get notificationsEmptyBody =>
      'Les rappels de cours, nouveautés et messages importants apparaîtront ici.';

  @override
  String get notificationPermissionDenied =>
      'Permission refusée. La boîte de réception reste disponible ici.';

  @override
  String get notificationEnableTitle => 'Ne manque aucune nouveauté';

  @override
  String get notificationEnableBody =>
      'Active les alertes système. Tous les messages restent aussi conservés dans cette boîte de réception.';

  @override
  String get notificationEnableAction => 'Activer les alertes';

  @override
  String get profileUnavailable => 'Profil indisponible';

  @override
  String get profileUnavailableBody =>
      'Le profil n’a pas pu être chargé. Vérifie la connexion puis réessaie.';

  @override
  String get loginEmailImmutable =>
      'L’adresse de connexion ne se modifie pas ici.';

  @override
  String get phoneOptionalLabel => 'Téléphone (facultatif)';

  @override
  String get invalidCameroonPhone => 'Numéro camerounais invalide.';

  @override
  String get savingLabel => 'Enregistrement…';

  @override
  String get saveLabel => 'Enregistrer';

  @override
  String get profileRestrictedFields =>
      'La classe, le rôle et l’établissement ne peuvent être modifiés que par un responsable autorisé.';

  @override
  String profileNameLengthError(String label) {
    return 'Le champ $label doit contenir entre 2 et 60 caractères.';
  }

  @override
  String get profileUpdated => 'Profil mis à jour.';

  @override
  String get kiraDiscoveryPhraseOne => 'Elle prend le temps de t’expliquer.';

  @override
  String get kiraDiscoveryPhraseTwo => 'Elle avance avec méthode et douceur.';

  @override
  String get kiraDiscoveryPhraseThree =>
      'Elle t’aide à comprendre sans pression.';

  @override
  String get leoDiscoveryPhraseOne => 'Il transforme chaque notion en défi.';

  @override
  String get leoDiscoveryPhraseTwo => 'Il te pousse à aller un peu plus loin.';

  @override
  String get leoDiscoveryPhraseThree => 'Il célèbre chaque progrès avec toi.';

  @override
  String get discoverLeo => 'Découvrir Léo';

  @override
  String get returnToKira => 'Revenir vers Kira';

  @override
  String discoverCompanionBeforeChoice(String name) {
    return 'Découvre $name pour pouvoir le choisir';
  }

  @override
  String companionChosenA11y(String name) {
    return '$name choisi';
  }

  @override
  String chooseCompanionA11y(String name) {
    return 'Choisir $name';
  }

  @override
  String currentCompanionLabel(String name) {
    return '$name, ton compagnon';
  }

  @override
  String get subjectMathematics => 'Mathématiques';

  @override
  String get subjectFrench => 'Français';

  @override
  String get subjectGeography => 'Géographie';

  @override
  String get classPremiereDisplay => 'Première';

  @override
  String get stateLoadingTitle => 'Chargement…';

  @override
  String get stateEmptyTitle => 'Rien ici pour le moment';

  @override
  String get stateNoResultsTitle => 'Aucun résultat';

  @override
  String get stateComingSoonTitle => 'Contenu bientôt disponible';

  @override
  String get stateRetryableErrorTitle => 'Un problème est survenu';

  @override
  String get stateFatalErrorTitle => 'Une erreur inattendue est survenue';

  @override
  String get stateOfflineTitle => 'Tu es hors ligne';

  @override
  String get stateAccessDeniedTitle => 'Accès non autorisé';

  @override
  String get stateLockedTitle => 'Contenu verrouillé';

  @override
  String get stateSuccessTitle => 'C’est fait !';

  @override
  String get stateOfflineBody =>
      'Vérifie ta connexion puis réessaie. Tes contenus déjà consultés restent disponibles.';

  @override
  String get stateAccessDeniedBody =>
      'Ton compte n’a pas accès à ce contenu. Reconnecte-toi ou contacte ton établissement.';

  @override
  String get stateRetryableErrorBody =>
      'Ce n’est pas de ton côté. Réessaie dans un instant.';

  @override
  String completionPercent(int percent) {
    return '$percent % terminé';
  }

  @override
  String get nextUpA11y => ', à suivre';

  @override
  String lessonTileA11y(int index, String title, String status, String next) {
    return 'Leçon $index : $title, $status$next';
  }

  @override
  String subjectTileA11y(String title, int percent, String lessons) {
    return '$title, $percent % terminé, $lessons';
  }

  @override
  String get lessonProgressQueuedOffline =>
      'Hors ligne : ta progression sera validée après la reconnexion.';

  @override
  String get lessonProgressSaveFailed =>
      'Impossible d’enregistrer pour le moment. Réessaie dans un instant.';

  @override
  String get removeFromFavorites => 'Retirer des favoris';

  @override
  String get addToFavorites => 'Ajouter aux favoris';

  @override
  String lessonReadingMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min de lecture',
      one: '1 min de lecture',
      zero: 'Moins d’une minute de lecture',
    );
    return '$_temp0';
  }

  @override
  String miniQuizScoreSuccess(int score, int total) {
    return 'Score : $score/$total — bien joué !';
  }

  @override
  String miniQuizScoreReview(int score, int total) {
    return 'Score : $score/$total — relis la leçon et réessaie.';
  }

  @override
  String get submitMiniQuiz => 'Valider le mini quiz';

  @override
  String get answerAllBeforeSubmit =>
      'Réponds à toutes les questions pour valider';

  @override
  String get answerAllQuestions => 'Réponds à toutes les questions';

  @override
  String correctAnswerA11y(String answer) {
    return 'Bonne réponse : $answer';
  }

  @override
  String incorrectAnswerA11y(String answer) {
    return 'Ta réponse est incorrecte : $answer';
  }

  @override
  String get quizProfileIncompleteBody =>
      'Ton profil scolaire doit être complété ou resynchronisé avant de choisir les quiz de ton niveau.';

  @override
  String get quizCatalogDeniedBody =>
      'Tes quiz ne sont pas encore ouverts pour ton profil. Tu peux continuer avec tes cours en attendant.';

  @override
  String get quizCatalogUnavailableBody =>
      'Tes quiz sont momentanément inaccessibles. Continue ton parcours ou tes cours en attendant.';

  @override
  String get quizCatalogInvalidBody =>
      'Certains quiz ne sont pas encore prêts. Tu peux continuer ton parcours et revenir t’entraîner dans quelques instants.';

  @override
  String get quizCatalogNetworkBody =>
      'La connexion est interrompue. Tes cours et ton parcours restent disponibles.';

  @override
  String get quizLoadErrorTitle =>
      'Impossible de charger les quiz pour le moment.';

  @override
  String get quizOfflineTitle => 'Les quiz attendent le réseau';

  @override
  String get quizOfflineBody =>
      'Aucun quiz n’est lancé sans connexion : le serveur protège la correction et valide l’envoi, sans conserver tes réponses hors ligne. Tu peux continuer avec ton parcours ou une leçon téléchargée.';

  @override
  String get openOfflineFlow => 'Ouvrir mon parcours hors ligne';

  @override
  String get viewDownloadedLessons => 'Voir mes leçons téléchargées';

  @override
  String get allLabel => 'Tous';

  @override
  String get quizModeTraining => 'Entraînement';

  @override
  String get quizModeExam => 'Évaluation / examen blanc';

  @override
  String get quizModeUnspecified => 'Mode non précisé';

  @override
  String get quizHubIntro =>
      'Entraîne-toi avec des corrections guidées ou évalue-toi dans les conditions d’un examen blanc.';

  @override
  String get chooseRevisionMode => 'Choisis ton mode de révision';

  @override
  String get quizPausedOfflineTitle => 'Quiz en pause hors connexion';

  @override
  String get quizPausedOfflineBody =>
      'Les corrections et l’envoi sont vérifiés par le serveur. Pour protéger l’évaluation, aucune réponse ni aucun corrigé n’est conservé hors ligne.';

  @override
  String get displayLabel => 'Afficher';

  @override
  String get filterQuizByModeA11y => 'Filtrer les quiz par mode';

  @override
  String get quizComingTitle => 'Les quiz de ta classe arrivent';

  @override
  String get quizComingBody =>
      'De nouveaux quiz sont en préparation pour ton niveau. En attendant, révise une leçon ou lance ton parcours depuis l’accueil.';

  @override
  String get quizTrainingAction => 'S’entraîner';

  @override
  String get quizTrainingDescription =>
      'Une correction guidée t’aide à comprendre avant de continuer.';

  @override
  String get quizExamAction => 'S’évaluer';

  @override
  String get quizExamDescription =>
      'Les réponses sont corrigées à la fin. Ces quiz préparent aux épreuves, sans remplacer un examen officiel.';

  @override
  String get studentSpace => 'Espace élève';

  @override
  String get quizTitle => 'Quiz';

  @override
  String get quizEyebrow => 'S’entraîner · se tester';

  @override
  String get quizUnavailableTitle =>
      'Tes quiz ne sont pas disponibles pour le moment';

  @override
  String get quizUnavailableBody =>
      'Tu peux continuer ton parcours et revenir t’entraîner dans quelques instants.';

  @override
  String get quizUnavailableOfflineBody =>
      'Vérifie ta connexion. Tu peux continuer ton parcours et revenir t’entraîner ensuite.';

  @override
  String get quizUnavailableModesLabel =>
      'Modes disponibles dès le retour de tes quiz';

  @override
  String get quizHistoryLoading => 'Chargement des tentatives validées…';

  @override
  String get quizHistoryUnavailable =>
      'Historique indisponible pour le moment.';

  @override
  String get quizNoValidatedAttempt =>
      'Aucune tentative validée pour le moment.';

  @override
  String lastScore(String score) {
    return 'Dernier score : $score';
  }

  @override
  String get myResults => 'Mes résultats';

  @override
  String get quizResultsLoadFailed =>
      'Impossible de récupérer les résultats validés. Tes quiz restent accessibles.';

  @override
  String get quizFirstResultBody =>
      'Aucun résultat inventé ici : ta première tentative apparaîtra après sa validation par le serveur.';

  @override
  String get quizMasteryUnavailable =>
      'La maîtrise par thème n’est pas affichée : les tentatives actuelles n’enregistrent pas encore de compétences pédagogiques validées.';

  @override
  String get dateUnavailable => 'Date non disponible';

  @override
  String pointsEarned(int count) {
    return '+$count points';
  }

  @override
  String get scoreUnavailable => 'Score non disponible';

  @override
  String get quizTrainingGuide => 'Correction guidée pendant le quiz.';

  @override
  String get quizExamGuide => 'Correction complète après l’envoi.';

  @override
  String questionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
      zero: 'Aucune question',
    );
    return '$_temp0';
  }

  @override
  String get unavailableOfflineA11y => ' Indisponible hors connexion.';

  @override
  String get quizNeedsNetworkTitle => 'Ce quiz a besoin du réseau';

  @override
  String get quizNeedsNetworkBody =>
      'Le serveur protège la correction et valide l’envoi. Intellia237 ne met ni tes réponses ni les corrigés en cache. Reconnecte-toi pour commencer, ou poursuis une activité disponible hors ligne.';

  @override
  String get quizPlayOfflineTitle => 'Quiz indisponible hors connexion';

  @override
  String get quizPlayOfflineBody =>
      'Le contenu, la correction et l’envoi sont vérifiés par le serveur. Intellia237 ne conserve ni tes réponses ni les corrigés hors ligne. Reconnecte-toi, ou poursuis une activité déjà disponible sur cet appareil.';

  @override
  String get quizQuestionsComingTitle => 'Questions en préparation';

  @override
  String get quizQuestionsComingBody =>
      'Ce quiz est publié, mais ses questions ne sont pas encore disponibles.';

  @override
  String get leaveQuizTitle => 'Quitter ce quiz ?';

  @override
  String get leaveQuizBody => 'Tes réponses de cette tentative seront perdues.';

  @override
  String get continueQuiz => 'Continuer le quiz';

  @override
  String get leaveAndDiscardAnswers => 'Quitter et perdre mes réponses';

  @override
  String get checkAnswerAction => 'Vérifier';

  @override
  String get finishLabel => 'Terminer';

  @override
  String get guidedCorrectionUnavailableTitle => 'Correction indisponible';

  @override
  String guidedCorrectionFailureBody(String reason) {
    return '$reason\nTa réponse reste saisie sur cet écran et n’est pas mise en cache.';
  }

  @override
  String get continueWithoutCorrection => 'Continuer sans correction';

  @override
  String get correctAnswerTitle => 'Bonne réponse !';

  @override
  String get keyTakeawayTitle => 'À retenir';

  @override
  String expectedAnswer(String answer) {
    return 'Réponse attendue : $answer';
  }

  @override
  String unansweredQuestionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions sans réponse',
      one: '1 question sans réponse',
      zero: 'Aucune question sans réponse',
    );
    return '$_temp0';
  }

  @override
  String get incompleteQuizBody =>
      'Tu peux revenir à la première question incomplète ou envoyer maintenant.';

  @override
  String get completeMyAnswers => 'Compléter mes réponses';

  @override
  String get submitAnyway => 'Envoyer quand même';

  @override
  String quizSubmissionFailureBody(String reason) {
    return '$reason Tes réponses restent saisies sur cet écran : réessaie sans les ressaisir. Aucune copie hors ligne n’est créée.';
  }

  @override
  String get quizAnswerCheckNetworkError =>
      'La connexion est trop faible pour vérifier cette réponse. Réessaie quand le réseau revient.';

  @override
  String get quizAnswerCheckUnavailable =>
      'La correction guidée est indisponible pour le moment.';

  @override
  String get quizAnswerCheckFailed =>
      'Cette réponse ne peut pas être vérifiée pour le moment.';

  @override
  String get quizAnswerCheckGenericError =>
      'La correction guidée ne répond pas pour le moment. Vérifie ta connexion, puis réessaie.';

  @override
  String get quizSubmissionNotFound => 'Quiz introuvable ou indisponible.';

  @override
  String get quizSubmissionPrecondition =>
      'Ce quiz ne peut pas encore être soumis.';

  @override
  String get quizSubmissionAlreadyExists =>
      'Cette tentative a déjà été utilisée.';

  @override
  String get quizSubmissionDenied => 'Tu ne peux pas soumettre ce quiz.';

  @override
  String get quizSubmissionInvalid =>
      'La tentative contient des réponses invalides.';

  @override
  String get quizSubmissionUnauthenticated =>
      'Connecte-toi pour valider le quiz.';

  @override
  String get quizSubmissionUnavailable =>
      'Le serveur n’a pas pu valider cette tentative pour le moment.';

  @override
  String get singleAnswerQcm => 'QCM — Une seule bonne réponse';

  @override
  String get selectedA11y => ', sélectionnée';

  @override
  String quizOptionA11y(String letter, String answer, String selected) {
    return 'Réponse $letter : $answer$selected';
  }

  @override
  String get shortAnswerInstruction => 'Réponds en quelques mots';

  @override
  String get yourAnswerHint => 'Ta réponse…';

  @override
  String get trueOrFalse => 'Vrai ou faux';

  @override
  String get trueLabel => 'Vrai';

  @override
  String get falseLabel => 'Faux';

  @override
  String get backToQuizzes => 'Retour aux quiz';

  @override
  String get replayMyMistakes => 'Rejouer mes erreurs';

  @override
  String get restartQuiz => 'Recommencer';

  @override
  String get detailedCorrection => 'Correction détaillée';

  @override
  String mistakeProgress(int current, int total) {
    return 'Erreur $current/$total';
  }

  @override
  String get mentalAnswerInstruction =>
      'Réponds mentalement, puis révèle la correction.';

  @override
  String get revealAnswer => 'Révéler la réponse';

  @override
  String get finishReview => 'Terminer la révision';

  @override
  String get nextMistake => 'Erreur suivante';

  @override
  String get excellentResult => 'Excellent !';

  @override
  String get wellDoneResult => 'Bien joué !';

  @override
  String get keepGoingResult => 'Continue !';

  @override
  String get zeroPoints => '0 point';

  @override
  String get yourAnswerLabel => 'Ta réponse';

  @override
  String get correctAnswerLabel => 'Bonne réponse';

  @override
  String quizImprovement(int delta) {
    return '+$delta % par rapport à ta dernière tentative';
  }

  @override
  String quizImprovementA11y(String label) {
    return 'Score en progrès : $label';
  }

  @override
  String get continueWithFlow => 'Continuer mon parcours';

  @override
  String get homeLabel => 'Accueil';

  @override
  String get companionNavLabel => 'Compagnon';

  @override
  String get profileNavLabel => 'Profil';

  @override
  String get homeLoadError => 'Impossible de charger l’accueil';

  @override
  String get flowSyncSignedOut =>
      'Connecte-toi pour faire valider tes points du parcours.';

  @override
  String get flowSyncUnavailable =>
      'Tes points n’ont pas pu être validés pour le moment. Ta réponse est conservée.';

  @override
  String get flowSyncQueued =>
      'Réponse enregistrée hors ligne. Les points seront validés à la prochaine synchronisation.';

  @override
  String get flowSyncNotEligible =>
      'La validation des points du parcours est réservée aux profils élèves.';

  @override
  String get flowSyncContentNotValidated =>
      'Cette activité du parcours n’est pas encore validée par le serveur.';

  @override
  String get flowSyncDuplicate =>
      'Cette validation a déjà été utilisée pour une autre activité.';

  @override
  String get flowSyncInvalidAnswer =>
      'La réponse envoyée pour cette activité est invalide.';

  @override
  String get flowSyncUnknown =>
      'Impossible de valider les points du parcours pour le moment.';

  @override
  String get flowDailyCapReached =>
      'Plafond quotidien atteint : reviens demain pour gagner de nouveaux points.';

  @override
  String get companionSpeak => 'Parler';

  @override
  String get companionSend => 'Envoyer';

  @override
  String companionMicRationale(String name) {
    return '$name a besoin du micro pour t’écouter. Rien n’est enregistré sans que tu envoies.';
  }

  @override
  String get companionMicDenied =>
      'Le micro est refusé. Tu peux l’autoriser dans les réglages, ou écrire ta question.';

  @override
  String get companionMicUnavailable =>
      'La dictée n’est pas disponible sur cet appareil. Tu peux écrire ta question.';

  @override
  String get companionListening => 'Je t’écoute';

  @override
  String get companionDictationCancel => 'Annuler';

  @override
  String get companionDictationStop => 'Arrêter';

  @override
  String get companionDictationNearEnd => 'Bientôt la fin';

  @override
  String get companionDictationFailed =>
      'Je n’ai pas bien entendu. Tu peux réessayer ou écrire.';

  @override
  String get companionListen => 'Écouter';

  @override
  String get companionPauseListening => 'Pause';

  @override
  String get companionHistoryTitle => 'Tes conversations';

  @override
  String get companionHistoryEmpty => 'Tes conversations apparaîtront ici.';

  @override
  String get companionNewConversation => 'Nouvelle conversation';

  @override
  String companionSaveDeferred(String name) {
    return '$name est ton compagnon. La synchronisation avec ton profil se fera d’elle-même.';
  }

  @override
  String get authGatewayTitle => 'Bienvenue sur INTELLIA237';

  @override
  String get authGatewaySubtitle => 'Quel espace veux-tu ouvrir ?';

  @override
  String get todayEyebrow => 'Aujourd’hui';

  @override
  String get firstSessionEyebrow => 'Pour commencer';

  @override
  String get firstSessionTitle => 'Choisis ta première activité';

  @override
  String get resumeWhereLeftOff => 'Reprends là où tu t’es arrêté';

  @override
  String get keepMomentum => 'Continue sur ta lancée.';

  @override
  String get exploreEyebrow => 'Explorer';

  @override
  String get chooseNextActivity => 'Choisis ta prochaine activité';

  @override
  String get homeLessonsComingTitle => 'Tes cours arrivent';

  @override
  String get homeLessonsComingBody =>
      'Les leçons de ta classe sont en cours de préparation. En attendant, découvre ton parcours ou révise avec ton compagnon.';

  @override
  String get discoverFlow => 'Découvrir mon parcours';

  @override
  String get talkToCompanion => 'Parler à mon compagnon';

  @override
  String get forYouEyebrow => 'Pour toi';

  @override
  String get adaptiveJourneyTitle => 'Un parcours qui avance avec toi';

  @override
  String get demoDataLabel => 'Données de démonstration';

  @override
  String get settingsDescription =>
      'Lecture, animations, données et confidentialité';

  @override
  String get myProfileTitle => 'Mon profil';

  @override
  String get testAppVersionA11y => 'Version de l’application de test';

  @override
  String get versionLoading => 'Version en cours de lecture';

  @override
  String get versionUnavailable => 'Version indisponible';

  @override
  String get intelliaUser => 'Utilisateur Intellia 237';

  @override
  String get studentAccount => 'Compte Élève';

  @override
  String get academicJourney => 'Parcours scolaire';

  @override
  String get loadErrorLabel => 'Erreur de chargement';

  @override
  String get classLabel => 'Classe';

  @override
  String get statisticsAndProgress => 'Statistiques et progression';

  @override
  String get statisticsUnavailable => 'Statistiques indisponibles';

  @override
  String get pointsLabel => 'Points';

  @override
  String get levelLabel => 'Niveau';

  @override
  String get currentStreak => 'Série actuelle';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
      zero: '0 jour',
    );
    return '$_temp0';
  }

  @override
  String get progressLabel => 'Progression';

  @override
  String get statisticsComingTitle => 'Tes statistiques arrivent';

  @override
  String get statisticsComingBody =>
      'Termine ta première leçon ou ton premier quiz pour voir tes points et ta progression ici.';

  @override
  String get companionSaveDenied =>
      'Ce compagnon ne peut pas être enregistré sur ton profil.';

  @override
  String get companionSaveNetworkError =>
      'Le réseau est indisponible. Réessaie dans un instant.';

  @override
  String get companionSaveFailed =>
      'Le compagnon n’a pas pu être enregistré pour le moment.';

  @override
  String get noCompanionSelected => 'Aucun compagnon sélectionné';

  @override
  String get chooseCompanionToPersonalize =>
      'Choisis un compagnon pour personnaliser ton expérience';

  @override
  String get dailyChallenges => 'Défis du jour';

  @override
  String challengesRenewIn(String duration) {
    return 'Les défis se renouvellent dans $duration';
  }

  @override
  String challengeCompletedA11y(String title) {
    return 'Défi terminé : $title';
  }

  @override
  String challengeRewardA11y(String title, int points) {
    return 'Défi : $title, récompense $points points';
  }

  @override
  String progressOverviewA11y(int percent, int level, int points) {
    return 'Ma progression : $percent % global, niveau $level, $points points. Ouvrir le profil.';
  }

  @override
  String get myProgress => 'Ma progression';

  @override
  String levelShort(int level) {
    return 'Niv. $level';
  }

  @override
  String get currentLevel => 'Niveau actuel';

  @override
  String levelValue(int level) {
    return 'Niveau $level';
  }

  @override
  String get globalLabel => 'global';

  @override
  String get quickQuiz => 'Quiz rapide';

  @override
  String get personalizedRecommendations => 'Recommandations personnalisées';

  @override
  String resumeLessonA11y(String title, int percent) {
    return 'Reprendre la leçon $title, avancée à $percent pour cent.';
  }

  @override
  String get resumeLastLesson => 'Reprendre le dernier cours';

  @override
  String streakA11y(int count, String message) {
    return 'Série de $count jours. $message';
  }

  @override
  String streakDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours de série',
      one: '1 jour de série',
      zero: '0 jour de série',
    );
    return '$_temp0';
  }

  @override
  String get mySpace => 'Mon espace';

  @override
  String get myLearningSpace => 'Mon espace d’apprentissage';

  @override
  String openNotificationsA11y(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ouvrir les notifications, $count non lues',
      one: 'Ouvrir les notifications, 1 non lue',
      zero: 'Ouvrir les notifications',
    );
    return '$_temp0';
  }

  @override
  String get openMyProfile => 'Ouvrir mon profil';

  @override
  String get subjectsTitle => 'Matières';

  @override
  String subjectProgressA11y(String title, int percent) {
    return '$title, $percent % terminé';
  }

  @override
  String weeklyGoalProgressA11y(int done, int total, String status) {
    return 'Mon objectif de la semaine : $done sur $total séances. $status';
  }

  @override
  String get goalAchievedA11y => 'Objectif atteint.';

  @override
  String get myWeeklyGoal => 'Mon objectif de la semaine';

  @override
  String get editMyGoal => 'Modifier mon objectif';

  @override
  String get goalAchievedMessage => 'Objectif atteint — belle semaine !';

  @override
  String weeklyGoalProgressSummary(int done, int total, int minutes) {
    return '$done/$total séances · environ $minutes min chacune';
  }

  @override
  String openPrioritySubjectA11y(String subject) {
    return 'Ouvrir ma matière prioritaire : $subject';
  }

  @override
  String prioritySubject(String subject) {
    return 'Priorité : $subject';
  }

  @override
  String get setWeeklyPace => 'Fixer mon rythme de la semaine';

  @override
  String get setYourWeeklyPace => 'Fixe ton rythme de la semaine';

  @override
  String get weeklyPaceChoices => '2, 3 ou 5 séances : c’est toi qui choisis.';

  @override
  String get weeklyGoalExplanation =>
      'Un rythme réaliste que tu choisis. Le compteur repart chaque lundi, sans pression.';

  @override
  String get sessionsPerWeek => 'Séances par semaine';

  @override
  String get sessionDuration => 'Durée d’une séance';

  @override
  String get prioritySubjectOptional => 'Matière prioritaire (optionnel)';

  @override
  String get noneLabel => 'Aucune';

  @override
  String get saveMyGoal => 'Enregistrer mon objectif';

  @override
  String get removeGoal => 'Supprimer l’objectif';

  @override
  String get childOverviewTitle => 'Vue enfant';

  @override
  String get childNotFound => 'Enfant introuvable.';

  @override
  String get weeklyProgress => 'Progression hebdomadaire';

  @override
  String get progressChartComing =>
      'La courbe apparaîtra après les premières activités.';

  @override
  String get strongSubjects => 'Forts';

  @override
  String get needsImprovement => 'À renforcer';

  @override
  String get viewDetailedProgress => 'Voir la progression détaillée';

  @override
  String get notMeasuredYet => 'Pas encore mesuré';

  @override
  String get childProgressTitle => 'Progression enfant';

  @override
  String childSevenDayProgress(String name) {
    return '$name — progression sur 7 jours';
  }

  @override
  String get todayStudy => 'Étude du jour';

  @override
  String get dailyTrend => 'Tendance quotidienne';

  @override
  String get childrenLabel => 'Enfants';

  @override
  String get announcementsLabel => 'Annonces';

  @override
  String get subscriptionLabel => 'Abonnement';

  @override
  String get parentSpace => 'Espace parent';

  @override
  String get myChildren => 'Mes enfants';

  @override
  String get paymentsLabel => 'Paiements';

  @override
  String get parentSpaceUnavailable => 'Espace parent indisponible';

  @override
  String get parentSpaceDescription =>
      'Suivi clair et rassurant de la progression scolaire.';

  @override
  String globalProgressPercent(int percent) {
    return 'Progression globale $percent%';
  }

  @override
  String get progressComingAfterActivities =>
      'La progression apparaîtra après les premières activités.';

  @override
  String get activityChartComing => 'Courbe d’activité à venir';

  @override
  String childWeeklyProgressComing(String name) {
    return 'La progression hebdomadaire de $name apparaîtra ici après ses premières leçons et quiz.';
  }

  @override
  String get subjectsToImprove => 'À renforcer';

  @override
  String get subjectStrengthsComing =>
      'Les points forts et les matières à renforcer seront identifiés après les premières évaluations.';

  @override
  String get schoolAnnouncements => 'Annonces de l’établissement';

  @override
  String get parentAccountActiveBody =>
      'Votre compte est actif. Les enfants liés apparaîtront ici après validation du lien.';

  @override
  String get noChildLinked => 'Aucun enfant lié';

  @override
  String get linkChildHelp =>
      'Ajoutez un code enfant depuis le profil ou demandez le lien à l’établissement.';

  @override
  String get overviewLabel => 'Vue d’ensemble';

  @override
  String get parentProfile => 'Profil Parent';

  @override
  String get parentAccountActive => 'Compte parent actif';

  @override
  String get parentSettingsDescription =>
      'Lecture, notifications, données et confidentialité';

  @override
  String get toBeDetermined => 'À déterminer';

  @override
  String get studyTimeComing =>
      'Le temps d’étude sera affiché dès que la mesure sera disponible.';

  @override
  String get todayStudyTime => 'Temps d’étude du jour';

  @override
  String studyMinutesGoal(int done, int goal) {
    return '$done min / objectif $goal min';
  }

  @override
  String get badgeUnlocked => 'Badge débloqué';

  @override
  String get discoverAnswer => 'Découvrir la réponse';

  @override
  String get newLabel => 'NOUVEAU';

  @override
  String get flowEntryDescription =>
      'Apprends en glissant,\nune carte à la fois.';

  @override
  String get missingAnswerHint => 'Écris le mot ou le nombre manquant';

  @override
  String get submitMyAnswer => 'Valider ma réponse';

  @override
  String get checkOrder => 'Vérifier l’ordre';

  @override
  String sessionVerifiedPoints(int count) {
    return '$count points vérifiés dans cette session';
  }

  @override
  String get totalPendingShort => 'Total —';

  @override
  String totalPointsShort(int count) {
    return '$count au total';
  }

  @override
  String get totalPendingValidation => 'Total en attente de validation serveur';

  @override
  String totalVerifiedPoints(int count) {
    return '$count points vérifiés au total';
  }

  @override
  String pendingValidationShort(int count) {
    return '$count à valider';
  }

  @override
  String offlineActivitiesToSync(int count) {
    return '$count activités hors ligne à synchroniser';
  }

  @override
  String get verifiedSession => 'Session vérifiée';

  @override
  String get verifiedTotal => 'Total vérifié';

  @override
  String get pendingValidationLabel => 'À valider';

  @override
  String activeTab(String label) {
    return 'Onglet actif : $label';
  }

  @override
  String get startupInterrupted => 'Démarrage interrompu';

  @override
  String roleSpace(String role) {
    return 'Espace $role';
  }

  @override
  String welcomeRoleSpace(String role) {
    return 'Bienvenue dans l’espace $role';
  }

  @override
  String get roleOptionsBody =>
      'Consultez les options disponibles pour votre profil.';

  @override
  String get skipLabel => 'Passer';

  @override
  String get probatoireLevel => 'Probatoire';

  @override
  String get baccalaureateLevel => 'Baccalauréat';

  @override
  String chooseTutorA11y(String name) {
    return 'Choisir $name comme tuteur';
  }

  @override
  String get chooseYourTutor => 'Choisis ton tuteur';

  @override
  String get tutorJourneyDescription =>
      'Il t’accompagnera tout au long de ton parcours';

  @override
  String get activationEyebrow => 'INTELLIA // L’ÉVEIL';

  @override
  String get activationTitle => 'Le savoir attend ton signal.';

  @override
  String get knowledgeEyebrow => 'UNIVERS DES SAVOIRS';

  @override
  String get knowledgeTitle => 'Chaque matière ouvre une trajectoire.';

  @override
  String get knowledgeBody =>
      'Mathématiques, français, anglais, sciences : entre par le sujet qui t’attire.';

  @override
  String get challengeEyebrow => 'PREMIER DÉFI';

  @override
  String get challengeTitle => 'Comprendre compte plus que deviner.';

  @override
  String get challengeBody =>
      'Essaie. Si tu hésites, INTELLIA décompose le raisonnement avec toi.';

  @override
  String get companionsEyebrow => 'DEUX ÉNERGIES';

  @override
  String get companionsTitle => 'Deux personnalités. Un même objectif.';

  @override
  String get companionsBody =>
      'Te faire progresser, avec une manière d’expliquer qui te ressemble.';

  @override
  String get journeyEyebrow => 'PARCOURS INTELLIA';

  @override
  String get journeyTitle => 'Un défi devient une maîtrise.';

  @override
  String get journeyBody =>
      'INTELLIA237 relie les leçons, l’entraînement et les quiz dans un parcours cohérent.';

  @override
  String get portalEyebrow => 'TON ESPACE PREND FORME';

  @override
  String get portalTitle => 'Le parcours commence maintenant.';

  @override
  String get portalBody =>
      'Retrouve tes matières, tes défis et ton compagnon dans une seule expérience.';

  @override
  String get holdToEnterIntellia => 'Maintiens pour entrer dans INTELLIA237';

  @override
  String get holdCenterToActivate => 'Maintenir le centre jusqu’à activation';

  @override
  String answerChoiceA11y(String answer) {
    return 'Réponse $answer';
  }

  @override
  String continueAfterDiscovering(String name) {
    return 'Continuer après avoir découvert $name';
  }

  @override
  String continueWithCompanion(String name) {
    return 'Continuer avec $name';
  }

  @override
  String discoverCompanionA11y(String name) {
    return 'Découvrir $name';
  }

  @override
  String get kiraOnboardingSignature => 'CALME • MÉTHODE • CONFIANCE';

  @override
  String get kiraOnboardingExample =>
      'On reprend l’idée essentielle, puis on avance ensemble.';

  @override
  String get leoOnboardingSignature => 'DÉFI • ÉNERGIE • DÉPASSEMENT';

  @override
  String get leoOnboardingExample =>
      'Prêt pour un défi ? Je te donne l’indice qui débloque tout.';

  @override
  String get lessonNodeLabel => 'LEÇON';

  @override
  String get trainingNodeLabel => 'ENTRAÎNEMENT';

  @override
  String get reachMasteryA11y => 'Atteindre la maîtrise et ouvrir le portail';

  @override
  String get masteryNodeLabel => 'MAÎTRISE';

  @override
  String get tapMasteryInstruction =>
      'Touche la maîtrise pour ouvrir ton espace';

  @override
  String get chooseSubject => 'Choisis une matière';

  @override
  String get yourLearningSpace => 'Ton espace d’apprentissage';

  @override
  String get journeyAtYourPace => 'Une trajectoire, à ton rythme';

  @override
  String get nextLessonPreview => 'Prochaine leçon';

  @override
  String get equationsPreview => 'Équations';

  @override
  String get dailyChallengePreview => 'Défi du jour';

  @override
  String get quizFiveMinutesPreview => 'Quiz • 5 min';

  @override
  String get factorizedLabel => 'Factorisé';

  @override
  String get whoWillBeYourCompanion => 'Qui sera ton compagnon pédagogique ?';

  @override
  String get learningDialogueA11y => 'Dialogue pédagogique';

  @override
  String get firstNameWithArticle => 'Le prénom';

  @override
  String get lastNameWithArticle => 'Le nom';

  @override
  String get passwordMinEight => '8 caractères minimum';

  @override
  String get confirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get confirmPasswordHint => 'Retapez le mot de passe';

  @override
  String get teacherRegistrationTitle => 'Créer un compte Enseignant';

  @override
  String get teacherIdentityStep => 'Identité enseignant';

  @override
  String get teachingStep => 'Enseignement';

  @override
  String get teacherDetailsTitle => 'Coordonnées enseignant';

  @override
  String get teacherDetailsSubtitle =>
      'Renseignez vos informations de connexion.';

  @override
  String get firstNameTeacherHint => 'Ex. Serge';

  @override
  String get lastNameTeacherHint => 'Ex. Mbarga';

  @override
  String get teacherEmailHint => 'enseignant@exemple.com';

  @override
  String get teachingTitle => 'Votre enseignement';

  @override
  String get teachingSubtitle =>
      'Sélectionnez vos matières et niveaux enseignés.';

  @override
  String get taughtSubjectsTitle => 'Matières enseignées';

  @override
  String get taughtSubjectsCaption =>
      'Sélectionnez vos disciplines principales.';

  @override
  String get taughtLevelsTitle => 'Niveaux enseignés';

  @override
  String get taughtLevelsCaption =>
      'Sélectionnez les classes que vous couvrez.';

  @override
  String get teacherFinalSubtitle =>
      'Relisez vos informations avant de confirmer.';

  @override
  String get teacherValidationNotice =>
      'L’inscription d’un compte enseignant nécessite une validation par une équipe autorisée.';

  @override
  String get createTeacherAccount => 'Créer mon compte enseignant';

  @override
  String get adminRegistrationTitle => 'Créer un compte Direction';

  @override
  String get adminIdentityStep => 'Identité direction';

  @override
  String get jobFunctionStep => 'Fonction';

  @override
  String get adminDetailsTitle => 'Coordonnées direction';

  @override
  String get adminDetailsSubtitle =>
      'Informations du responsable ou membre de direction.';

  @override
  String get firstNameAdminHint => 'Ex. Nadine';

  @override
  String get lastNameAdminHint => 'Ex. Meka';

  @override
  String get adminEmailHint => 'direction@exemple.com';

  @override
  String get adminFunctionTitle => 'Votre fonction';

  @override
  String get adminFunctionSubtitle =>
      'Précisez votre rôle au sein de la direction.';

  @override
  String get jobTitleLabel => 'Fonction';

  @override
  String get jobTitleHint => 'Ex. Proviseur, Censeur, Directeur adjoint';

  @override
  String get minimumThreeCharacters => 'Minimum 3 caractères';

  @override
  String get adminAccreditationNotice =>
      'Votre compte direction sera soumis à un contrôle d’accréditation par nos équipes avant activation.';

  @override
  String get adminFinalSubtitle =>
      'Votre demande sera transmise pour validation.';

  @override
  String get adminValidationNotice =>
      'Une fois validé, vous recevrez une notification par e-mail vous invitant à vous connecter à votre console d’administration.';

  @override
  String get createAdminAccount => 'Soumettre mon compte direction';

  @override
  String get legalVersion => 'Version du 16 juillet 2026';

  @override
  String get legalContactNotice =>
      'Pour toute question ou demande liée aux données, contacte ton établissement ou l’équipe Intellia237. Une validation juridique locale reste requise avant la mise en production commerciale.';

  @override
  String get legalTermsTitle => 'Conditions d’utilisation';

  @override
  String get legalServicePurposeTitle => 'Objet du service';

  @override
  String get legalServicePurposeBody =>
      'Intellia237 fournit des ressources pédagogiques, des quiz et un compagnon d’apprentissage. Le service complète l’enseignement et ne remplace ni l’établissement ni l’enseignant.';

  @override
  String get legalAccountSecurityTitle => 'Compte et sécurité';

  @override
  String get legalAccountSecurityBody =>
      'Les informations fournies doivent être exactes. Les identifiants restent personnels. Les comptes enseignants et administrateurs peuvent nécessiter une validation.';

  @override
  String get legalResponsibleUseTitle => 'Usage responsable';

  @override
  String get legalResponsibleUseBody =>
      'Il est interdit de contourner les règles des évaluations, d’extraire des données d’autres utilisateurs ou d’utiliser le compagnon pour produire un contenu nuisible.';

  @override
  String get availabilityLabel => 'Disponibilité';

  @override
  String get legalAvailabilityBody =>
      'Certaines fonctions exigent une connexion. Les maintenances et indisponibilités temporaires sont signalées aussi clairement que possible.';

  @override
  String get legalPrivacyTitle => 'Politique de confidentialité';

  @override
  String get legalCollectedDataTitle => 'Données collectées';

  @override
  String get legalCollectedDataBody =>
      'Le compte, le rôle, la classe, la progression et les tentatives nécessaires au service peuvent être enregistrés. Les données demandées doivent rester limitées à la finalité pédagogique.';

  @override
  String get legalMinorsPrivacyTitle => 'Mineurs et confidentialité';

  @override
  String get legalMinorsPrivacyBody =>
      'Les conversations, réponses libres, noms et e-mails ne doivent jamais être envoyés aux outils de mesure d’audience. Les diagnostics anonymes sont désactivés par défaut.';

  @override
  String get legalRetentionAccessTitle => 'Conservation et accès';

  @override
  String get legalRetentionAccessBody =>
      'Les données sont accessibles uniquement aux personnes autorisées selon leur rôle. Les durées de conservation et procédures d’accès doivent être validées avant mise en production.';

  @override
  String get legalYourRightsTitle => 'Vos droits';

  @override
  String get legalYourRightsBody =>
      'L’utilisateur ou son représentant peut demander l’accès, la correction ou la suppression de ses données auprès de l’établissement ou de l’équipe Intellia237.';

  @override
  String get legalEducationalDataTitle => 'Traitement pédagogique des données';

  @override
  String get legalPurposeTitle => 'Finalité';

  @override
  String get legalPurposeBody =>
      'Les réponses, résultats et progressions servent à proposer une prochaine étape, présenter une correction et aider l’enseignant ou le parent autorisé à accompagner l’élève.';

  @override
  String get legalDecisionsTitle => 'Décisions';

  @override
  String get legalDecisionsBody =>
      'Une recommandation automatisée ne constitue pas une décision scolaire officielle. L’enseignant et l’établissement restent responsables de l’évaluation scolaire.';

  @override
  String get legalCompanionTitle => 'Compagnon pédagogique';

  @override
  String get legalCompanionBody =>
      'Les messages sont transmis au service nécessaire pour générer une réponse. L’élève ne doit pas y communiquer d’information personnelle sensible.';

  @override
  String get readTerms => 'Lire les conditions';

  @override
  String get readPrivacy => 'Lire la confidentialité';

  @override
  String get readEducationalData => 'Comprendre les données pédagogiques';

  @override
  String get loadingOffer => 'Chargement de l’offre';

  @override
  String get serviceUnavailable => 'Service indisponible';

  @override
  String get subscriptionTitle => 'Abonnement';

  @override
  String get mobileMoneyParentDescription =>
      'Paiement Mobile Money déclaré, puis vérifié manuellement par l’établissement de l’enfant concerné.';

  @override
  String get myPaymentRequests => 'Mes demandes';

  @override
  String accessDaysAfterApproval(int days) {
    return 'Accès pendant $days jours après validation';
  }

  @override
  String get mobileMoneyStepTransfer => '1. Effectuez le transfert';

  @override
  String get operatorLabel => 'Opérateur';

  @override
  String get recipientNumberConfigured => 'Numéro bénéficiaire configuré';

  @override
  String get copyNumber => 'Copier le numéro';

  @override
  String get numberCopied => 'Numéro copié.';

  @override
  String get mobileMoneyNoDebitNotice =>
      'Intellia237 ne déclenche aucun débit. Réalisez vous-même le transfert dans l’application de votre opérateur et vérifiez le numéro avant de confirmer.';

  @override
  String get mobileMoneyStepProof => '2. Envoyez la preuve de transfert';

  @override
  String get payerPhoneLabel => 'Numéro ayant effectué le transfert';

  @override
  String get transactionReferenceLabel => 'Référence de transaction';

  @override
  String get sendingLabel => 'Envoi en cours…';

  @override
  String get submitForReview => 'Transmettre pour vérification';

  @override
  String get enterTransferDetails =>
      'Saisissez le téléphone et la référence du transfert.';

  @override
  String get confirmDeclarationTitle => 'Confirmer la déclaration';

  @override
  String confirmTransferDeclaration(
    String amount,
    String operator,
    String phone,
  ) {
    return 'Vous déclarez avoir transféré $amount via $operator vers $phone. Aucune somme ne sera débitée par Intellia237.';
  }

  @override
  String get paymentRequestSubmitted =>
      'Demande transmise. L’accès sera activé uniquement après vérification.';

  @override
  String get noValidatedSchoolLinked =>
      'Aucun établissement validé n’est encore lié à ce compte parent.';

  @override
  String get multipleSchoolsLinked =>
      'Vos enfants sont inscrits dans plusieurs établissements : choisissez l’enfant pour qui vous payez.';

  @override
  String get noActiveMobileMoneyOffer =>
      'L’établissement de cet enfant n’a pas encore publié d’offre Mobile Money active.';

  @override
  String get offerUnavailable => 'Offre indisponible';

  @override
  String referenceValue(String reference) {
    return 'Référence $reference';
  }

  @override
  String schoolNote(String note) {
    return 'Note de l’établissement : $note';
  }

  @override
  String get mobileMoneyReferenceAlreadySubmitted =>
      'Cette référence a déjà été transmise. Consultez son statut ci-dessous.';

  @override
  String get mobileMoneyOfferNoLongerAvailable =>
      'L’offre ou le rattachement à l’établissement n’est plus disponible.';

  @override
  String get mobileMoneyPermissionDenied =>
      'Votre compte n’est pas autorisé à effectuer cette opération.';

  @override
  String get mobileMoneyInvalidDetails =>
      'Vérifiez le numéro de téléphone et la référence de transaction.';

  @override
  String get mobileMoneyTemporarilyUnavailable =>
      'Le service est momentanément indisponible. Réessayez sans refaire le transfert.';

  @override
  String get mobileMoneyGenericError =>
      'Impossible de traiter cette demande pour le moment.';

  @override
  String get paymentPendingReview => 'En vérification';

  @override
  String get paymentApproved => 'Validé';

  @override
  String get paymentRejected => 'Rejeté';

  @override
  String get loadingPayments => 'Chargement des paiements';

  @override
  String get paymentQueueUnavailable => 'File indisponible';

  @override
  String get mobileMoneyApprovalTitle => 'Validation Mobile Money';

  @override
  String get mobileMoneyAdminDescription =>
      'Comparez chaque référence avec le portail de l’opérateur avant toute décision. Intellia237 ne prélève aucune somme.';

  @override
  String get noPendingPaymentRequest => 'Aucune demande en attente';

  @override
  String get payerPhoneShort => 'Téléphone payeur';

  @override
  String get referenceLabel => 'Référence';

  @override
  String get rejectLabel => 'Rejeter';

  @override
  String get paymentVerifiedQuestion => 'Paiement vérifié ?';

  @override
  String paymentVerificationWarning(
    String amount,
    String reference,
    String operator,
  ) {
    return 'Confirmez uniquement si $amount et la référence $reference apparaissent dans le portail $operator. Cette action activera l’accès.';
  }

  @override
  String get paymentVerifiedLabel => 'Paiement vérifié';

  @override
  String get rejectPaymentRequest => 'Rejeter la demande';

  @override
  String get rejectionReasonOptional =>
      'Motif visible par le parent (facultatif)';

  @override
  String get rejectionReasonHint => 'Ex. référence introuvable';

  @override
  String get confirmRejection => 'Confirmer le rejet';

  @override
  String get paymentApprovedAndActivated => 'Paiement validé et accès activé.';

  @override
  String get paymentRequestRejected => 'Demande rejetée.';

  @override
  String get classesUnavailable => 'Classes indisponibles';

  @override
  String get teacherAnalyticsTitle => 'Analyses enseignant';

  @override
  String get teacherAnalyticsSubtitle =>
      'Vue d’ensemble des performances de vos classes.';

  @override
  String get averageCompletionRate => 'Taux moyen de complétion';

  @override
  String activeClassesCount(int count) {
    return '$count classes actives';
  }

  @override
  String get dailyEngagement => 'Engagement journalier';

  @override
  String get metricComingSoon => 'Mesure disponible prochainement';

  @override
  String trackedStudentsCount(int count) {
    return '$count élèves suivis';
  }

  @override
  String get weeklyTrend => 'Tendance hebdomadaire';

  @override
  String get weeklyTrendEmpty =>
      'La tendance apparaîtra après la première semaine d’activité de vos élèves.';

  @override
  String get progressByClass => 'Progression par classe';

  @override
  String get noDataAvailable => 'Aucune donnée disponible.';

  @override
  String get classDetailTitle => 'Détail de la classe';

  @override
  String get publishAnnouncementShort => 'Publier annonce';

  @override
  String get studentProgressTitle => 'Progression élèves';

  @override
  String get studentTrackingComing =>
      'Le suivi individuel arrive : les élèves de cette classe apparaîtront ici avec leur progression dès leurs premières activités.';

  @override
  String studyMinutesToday(int count) {
    return '$count min aujourd’hui';
  }

  @override
  String get publishAnnouncementTitle => 'Publier une annonce';

  @override
  String get titleLabel => 'Titre';

  @override
  String get messageLabel => 'Message';

  @override
  String get announcementPublished => 'Annonce publiée.';

  @override
  String get publishLabel => 'Publier';

  @override
  String get myClasses => 'Mes classes';

  @override
  String get classesLabel => 'Classes';

  @override
  String studentsCount(int count) {
    return '$count élèves';
  }

  @override
  String averageProgressPercent(int percent) {
    return 'Moyenne progression $percent%';
  }

  @override
  String pendingSubmissionsCount(int count) {
    return '$count remises en attente';
  }

  @override
  String get contentManagementTitle => 'Gestion de contenus';

  @override
  String get publishContentTitle => 'Publier un contenu';

  @override
  String get classSecondeA => 'Seconde A';

  @override
  String get classSecondeC => 'Seconde C';

  @override
  String get classPremiereD => 'Première D';

  @override
  String get subjectLabel => 'Matière';

  @override
  String get subjectPhysics => 'Physique';

  @override
  String get lessonTitleLabel => 'Titre de la leçon';

  @override
  String get titleRequired => 'Titre requis';

  @override
  String get chapterRequired => 'Chapitre requis';

  @override
  String get summaryLabel => 'Résumé';

  @override
  String get summaryRequired => 'Résumé requis';

  @override
  String get publishingLabel => 'Publication…';

  @override
  String get contentLabel => 'Contenu';

  @override
  String get contentPublishedSuccess => 'Contenu publié avec succès.';

  @override
  String get quizLabel => 'Quiz';

  @override
  String get statisticsLabel => 'Statistiques';

  @override
  String get dashboardUnavailable => 'Tableau de bord indisponible';

  @override
  String get noClassesYet => 'Aucune classe pour le moment';

  @override
  String get noClassesYetBody =>
      'Vos classes apparaîtront ici dès que votre établissement vous les aura assignées. Vous pouvez déjà préparer des quiz depuis l’onglet Quiz.';

  @override
  String get activeClassesTitle => 'Classes actives';

  @override
  String get recentAnnouncements => 'Annonces récentes';

  @override
  String get noRecentAnnouncement => 'Aucune annonce récente.';

  @override
  String get teacherSpaceTitle => 'Espace Enseignant';

  @override
  String get teacherSpaceDescription =>
      'Pilotez vos classes, contenus et évaluations depuis un tableau unique.';

  @override
  String get studentsLabel => 'Élèves';

  @override
  String get completionLabel => 'Complétion';

  @override
  String get dailyEngagementShort => 'Engagement / jour';

  @override
  String get quizCreationTitle => 'Création de quiz';

  @override
  String get quizCreationSubtitle =>
      'Créez une évaluation et publiez-la à vos classes.';

  @override
  String get quizTitleLabel => 'Titre du quiz';

  @override
  String get questionsLabel => 'Questions';

  @override
  String get addQuestion => 'Ajouter une question';

  @override
  String get publishQuiz => 'Publier le quiz';

  @override
  String get selectClassRequired => 'Sélectionnez une classe.';

  @override
  String get addCompleteQuestion => 'Ajoutez au moins une question complète.';

  @override
  String get quizPublishedSuccess => 'Quiz publié avec succès.';

  @override
  String questionNumber(int index) {
    return 'Question $index';
  }

  @override
  String get deleteLabel => 'Supprimer';

  @override
  String get questionPromptLabel => 'Énoncé';

  @override
  String get questionPromptHint => 'Posez la question';

  @override
  String get expectedAnswerLabel => 'Réponse attendue';

  @override
  String get expectedAnswerHint => 'Indiquez la réponse';

  @override
  String get subjectBiology => 'SVT';

  @override
  String get subjectEnglish => 'Anglais';

  @override
  String get subjectHistory => 'Histoire';

  @override
  String get administrationRole => 'Administration';

  @override
  String get pendingStatus => 'En attente';

  @override
  String get approvedStatus => 'Approuvé';

  @override
  String get hiddenStatus => 'Masqué';

  @override
  String get publishedStatus => 'Publié';

  @override
  String get aiStatus => 'IA ✨';

  @override
  String get draftStatus => 'Brouillon';

  @override
  String get audienceWholeSchool => 'Tout l’établissement';

  @override
  String get beginnerDifficulty => 'Débutant';

  @override
  String get intermediateDifficulty => 'Intermédiaire';

  @override
  String get advancedDifficulty => 'Avancé';

  @override
  String get expertDifficulty => 'Expert';

  @override
  String get contentPluralLabel => 'Contenus';

  @override
  String get analyticsLabel => 'Analyses';

  @override
  String get usersLabel => 'Utilisateurs';

  @override
  String get toolsLabel => 'Outils';

  @override
  String get teachersLabel => 'Enseignants';

  @override
  String get parentsLabel => 'Parents';

  @override
  String get dailyActiveUsersShort => 'Actifs/jour';

  @override
  String get pendingAccounts => 'Comptes en attente';

  @override
  String get moderationTickets => 'Tickets modération';

  @override
  String get adminSettingsDescription =>
      'Accessibilité, diagnostics et confidentialité';

  @override
  String get recentOfficialAnnouncements => 'Annonces officielles récentes';

  @override
  String get moderationLabel => 'Modération';

  @override
  String administrationAtSchool(String school) {
    return 'Direction • $school';
  }

  @override
  String helloUser(String name) {
    return 'Bonjour, $name';
  }

  @override
  String get adminHeroDescription =>
      'Supervisez l’usage de la plateforme et les opérations critiques.';

  @override
  String get broadcastCenterTitle => 'Centre de diffusion';

  @override
  String get broadcastCenterSubtitle =>
      'Publiez des annonces officielles ciblées.';

  @override
  String get audienceLabel => 'Audience';

  @override
  String get messageRequired => 'Message requis';

  @override
  String get recentHistory => 'Historique récent';

  @override
  String audienceValue(String audience) {
    return 'Audience : $audience';
  }

  @override
  String get contentModerationTitle => 'Modération des contenus';

  @override
  String get contentModerationSubtitle =>
      'Validez ou masquez les contenus signalés.';

  @override
  String get noModerationTicket => 'Aucun ticket de modération.';

  @override
  String contentReports(String type, int count) {
    return '$type • $count signalement(s)';
  }

  @override
  String get contentHidden => 'Contenu masqué.';

  @override
  String get hideLabel => 'Masquer';

  @override
  String get contentApproved => 'Contenu validé.';

  @override
  String get schoolAnalyticsTitle => 'Analyses de l’établissement';

  @override
  String get activeUsersSevenDays => 'Utilisateurs actifs (7 jours)';

  @override
  String get studyMinutesSevenDays => 'Minutes d’étude cumulées (7 jours)';

  @override
  String get averageProgressRate => 'Taux de progression moyen';

  @override
  String get metricAvailableAfterActivities =>
      'Mesure en construction : disponible après les premières activités des élèves.';

  @override
  String get accountApprovalTitle => 'Validation des comptes';

  @override
  String pendingRequestsCount(int count) {
    return '$count demande(s) en attente';
  }

  @override
  String get noPendingRequest => 'Aucune demande en attente.';

  @override
  String get userManagementTitle => 'Gestion des utilisateurs';

  @override
  String get accountRejected => 'Compte refusé.';

  @override
  String get refuseLabel => 'Refuser';

  @override
  String get accountApproved => 'Compte validé.';

  @override
  String get unpublishLabel => 'Dépublier';

  @override
  String get addChapter => 'Ajouter chapitre';

  @override
  String get chaptersUnavailable => 'Chapitres indisponibles';

  @override
  String get noChapterAdmin => 'Aucun chapitre.\nAppuyez sur + pour commencer.';

  @override
  String get newChapter => 'Nouveau chapitre';

  @override
  String get chapterTitleLabel => 'Titre du chapitre';

  @override
  String get shortDescriptionLabel => 'Description courte';

  @override
  String get createLabel => 'Créer';

  @override
  String lessonsCount(int count) {
    return '$count leçon(s)';
  }

  @override
  String get addLesson => 'Ajouter leçon';

  @override
  String get lessonsUnavailable => 'Leçons indisponibles';

  @override
  String get noLessonAdmin => 'Aucune leçon.\nAppuyez sur + pour créer.';

  @override
  String get newLesson => 'Nouvelle leçon';

  @override
  String get objectiveSummaryLabel => 'Objectif / résumé';

  @override
  String get estimatedDurationMinutes => 'Durée estimée (min)';

  @override
  String get lessonSaved => '✅ Leçon sauvegardée';

  @override
  String get lessonSaveFailed =>
      'La leçon n’a pas pu être enregistrée. Vérifie la connexion et réessaie.';

  @override
  String get lessonPublished => '🚀 Leçon publiée !';

  @override
  String get publicationFailed =>
      'La publication n’a pas abouti. Vérifie la connexion et réessaie.';

  @override
  String get newSection => 'Nouvelle section';

  @override
  String get courseContentLabel => 'Contenu du cours';

  @override
  String get lessonEditorTitle => 'Éditeur de leçon';

  @override
  String get aiGeneratedReviewNotice =>
      'Contenu généré par l’IA — Relisez avant publication';

  @override
  String get informationLabel => 'Informations';

  @override
  String get learningObjectiveLabel => 'Objectif pédagogique';

  @override
  String get estimatedDurationLabel => 'Durée estimée';

  @override
  String get aiGenerationTitle => 'Génération IA';

  @override
  String get aiGenerationBackendOnly =>
      'La génération automatique se fait côté serveur, jamais depuis cet écran.';

  @override
  String get aiGenerationBackendInstructions =>
      'Rédigez la leçon ici. Pour partir de pages de cours photographiées, utilisez « Importer des pages » depuis le chapitre : des brouillons sont préparés, que vous relisez avant publication.';

  @override
  String courseSectionsCount(int count) {
    return 'Sections du cours ($count)';
  }

  @override
  String get noCourseSection => 'Aucune section.\nAjoutez-en manuellement.';

  @override
  String miniQuizQuestionsCount(int count) {
    return 'Mini-quiz ($count questions)';
  }

  @override
  String get noGeneratedQuestion => 'Aucune question générée pour cette leçon.';

  @override
  String quizOptionsCorrectAnswer(int options, int answer) {
    return '$options options • Réponse : $answer';
  }

  @override
  String get quizPublished => '🚀 Quiz publié !';

  @override
  String get quizSaved => '✅ Quiz sauvegardé';

  @override
  String get quizSaveFailed =>
      'Le quiz n’a pas pu être enregistré. Vérifie la connexion et réessaie.';

  @override
  String get newQuiz => 'Nouveau Quiz';

  @override
  String get editQuiz => 'Modifier Quiz';

  @override
  String get quizInformation => 'Informations du quiz';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get difficultyLabel => 'Difficulté';

  @override
  String get durationSecondsLabel => 'Durée (sec)';

  @override
  String get trainingModeLabel => 'Entraînement';

  @override
  String get examModeLabel => 'Examen';

  @override
  String get trainingCorrectionDescription =>
      'La correction est affichée après chaque réponse validée.';

  @override
  String get examCorrectionDescription =>
      'La correction complète est révélée uniquement après la soumission.';

  @override
  String get targetLevels => 'Niveaux cibles';

  @override
  String questionsCount(int count) {
    return 'Questions ($count)';
  }

  @override
  String get noQuestionAdmin => 'Aucune question.\nAjoutez-en manuellement.';

  @override
  String get newQuestion => 'Nouvelle question';

  @override
  String get trueFalseShort => 'V/F';

  @override
  String get answerLabel => 'Réponse';

  @override
  String optionNumber(int number) {
    return 'Option $number';
  }

  @override
  String get selectCorrectAnswerInstruction =>
      '• Sélectionnez la bonne réponse avec le bouton radio';

  @override
  String get correctAnswerColon => 'Réponse correcte :';

  @override
  String get acceptedAnswersLabel => 'Réponse(s) acceptée(s) (séparées par ,)';

  @override
  String get explanationLabel => 'Explication';

  @override
  String get trueFalseLabel => 'Vrai/Faux';

  @override
  String get shortAnswerLabel => 'Réponse courte';

  @override
  String get contentStudioTitle => 'Studio de Contenu';

  @override
  String get subjectsAndCourses => 'Matières & Cours';

  @override
  String noSubjectForClass(String classLevel) {
    return 'Aucune matière pour $classLevel.\nAjoutez-en une pour commencer.';
  }

  @override
  String chaptersCount(int count) {
    return '$count chapitre(s)';
  }

  @override
  String get noQuizForLevel => 'Aucun quiz pour ce niveau.';

  @override
  String quizQuestionsDifficulty(int count, String difficulty) {
    return '$count questions • $difficulty';
  }

  @override
  String get generatedByAi => 'Généré par l’IA';

  @override
  String get masteryTitle => 'Ton apprentissage';

  @override
  String get masteryBySubject => 'Matière par matière';

  @override
  String get masteryDimension => 'Maîtrise';

  @override
  String get masteryCoverage => 'Parcours';

  @override
  String get masteryContinuity => 'Régularité';

  @override
  String get masteryNoEvidence => 'Pas encore assez d’éléments';

  @override
  String get masteryExploring => 'À explorer';

  @override
  String get masteryBuilding => 'En construction';

  @override
  String get masteryUnderstood => 'Bien compris';

  @override
  String get masterySolid => 'Solide';

  @override
  String get masteryConfidenceInsufficient => 'Données insuffisantes';

  @override
  String get masteryConfidenceLimited => 'Estimation prudente';

  @override
  String get masteryConfidenceSupported => 'Confiance étayée';

  @override
  String get masteryTrendProgressing => 'Estimation en progression';

  @override
  String get masteryTrendSteady => 'Estimation stable';

  @override
  String get masteryTrendDeclining => 'Estimation à réexaminer';

  @override
  String get masteryConsolidate => 'À consolider';

  @override
  String get masteryRevisit => 'À revoir';

  @override
  String get masteryNoEvidenceHint =>
      'Les réponses aux quiz aideront à construire cette lecture.';

  @override
  String get masteryScopeNote =>
      'Une estimation issue des quiz, distincte du parcours et des notes scolaires.';

  @override
  String get masterySourceLimits =>
      'Les résultats disponibles ne précisent pas les conditions de passation. Cette lecture reste prudente : « Bien compris » et « Solide » nécessitent des preuves plus complètes.';

  @override
  String get masteryLoading => 'Les repères d’apprentissage se chargent.';

  @override
  String get masteryUnavailable =>
      'La lecture de maîtrise est momentanément indisponible.';

  @override
  String get masterySubjectsUnavailable =>
      'Les matières ne sont pas disponibles pour le moment.';

  @override
  String get masterySubjectsEmpty =>
      'Les matières apparaîtront ici quand le programme sera disponible.';

  @override
  String get masteryStudentCollecting =>
      'INTELLIA237 commence à construire ton profil d’apprentissage. Continue à travailler et à répondre aux exercices.';

  @override
  String get masteryStudentFirst =>
      'Tes réponses aux quiz donnent de premiers repères. Cette lecture reste prudente et se précisera avec de nouvelles preuves.';

  @override
  String get masteryStudentProgress =>
      'Une estimation a évolué avec de nouveaux résultats de quiz. Retrouve ce changement dans les matières ci-dessous.';

  @override
  String get masteryParentCollecting =>
      'Il n’y a pas encore assez d’éléments pour lire ses acquis. Vous pouvez déjà l’encourager à expliquer ce qu’il apprend.';

  @override
  String get masteryParentFirst =>
      'Les quiz donnent de premiers repères sur son apprentissage. Les estimations restent prudentes.';

  @override
  String get masteryParentProgress =>
      'De nouveaux résultats de quiz font évoluer une estimation. Cette comparaison porte seulement sur les observations disponibles.';

  @override
  String get masteryParentTitle => 'Comment avance son apprentissage ?';

  @override
  String get masteryParentEvolving => 'Ce qui évolue';

  @override
  String get masteryParentNoComparison =>
      'Pas encore de comparaison suffisamment étayée.';

  @override
  String get masteryParentSupport => 'À accompagner';

  @override
  String get masteryParentSupportBody =>
      'Poursuivre les exercices aidera à préciser cette lecture.';

  @override
  String get masteryParentContinuity => 'Continuité du parcours';

  @override
  String get masteryParentNoPattern =>
      'Les données disponibles ne permettent pas encore de décrire une régularité.';

  @override
  String get masteryParentHelp => 'Comment l’aider';

  @override
  String get masteryParentHelpBody =>
      'Vous pouvez lui demander quelle notion lui a semblé difficile et l’inviter à l’expliquer avec ses mots.';

  @override
  String get masteryCoverageNote =>
      'Explorer un cours ne prouve pas encore qu’il est compris.';

  @override
  String get masteryCoverageUnavailable =>
      'Le parcours n’est pas disponible pour le moment.';

  @override
  String get masteryChapterDetailPending =>
      'Le détail des acquis par chapitre viendra avec des preuves rattachées aux chapitres. Aucune maîtrise de chapitre n’est déduite de la lecture.';

  @override
  String get masteryRecentActivity => 'Résultats de quiz disponibles';

  @override
  String get masteryRecentLimits =>
      'Seul le dernier résultat de chaque quiz est conservé dans cette lecture. Ce n’est pas l’historique de toutes les tentatives.';

  @override
  String get masteryRecordedQuiz => 'Quiz corrigé';

  @override
  String get masteryOpenCourse => 'Retrouver le cours';

  @override
  String get masteryScaleLegend =>
      'L’étendue de l’encre indique l’état, sa densité la confiance. Un tracé apparaît seulement lorsqu’une estimation antérieure a réellement été observée.';

  @override
  String get masteryOfficialRecord => 'Carnet officiel';

  @override
  String get masteryOfficialRecordBody =>
      'Les notes scolaires restent des résultats officiels de l’établissement. Elles ne sont pas calculées à partir de cette estimation.';

  @override
  String get masteryOfficialRecordUnavailable =>
      'Aucun carnet de notes scolaires n’est relié à cette vue pour le moment.';

  @override
  String get masteryRefresh => 'Actualiser les repères';

  @override
  String masteryEvidenceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quiz distincts pris en compte',
      one: '1 quiz distinct pris en compte',
      zero: 'Aucun résultat exploitable',
    );
    return '$_temp0';
  }

  @override
  String masteryExploredChapters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapitres explorés',
      one: '1 chapitre exploré',
      zero: 'Aucun chapitre exploré',
    );
    return '$_temp0';
  }

  @override
  String masteryExploredLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leçons explorées enregistrées',
      one: '1 leçon explorée enregistrée',
      zero: 'Aucune leçon explorée enregistrée',
    );
    return '$_temp0';
  }

  @override
  String get masteryPartialCoverage =>
      'Ce parcours porte sur une partie des leçons enregistrées.';

  @override
  String masteryRecordedStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Série d’activité enregistrée : $count jours',
      one: 'Série d’activité enregistrée : 1 jour',
    );
    return '$_temp0';
  }

  @override
  String masteryPreviousState(String state) {
    return 'Tracé précédent : $state';
  }

  @override
  String masteryLastEvidence(String date) {
    return 'Dernier résultat enregistré : $date';
  }

  @override
  String masteryDeclaredSchool(String name) {
    return 'Établissement déclaré : $name';
  }

  @override
  String masteryWithCompanion(String name) {
    return 'Avec $name';
  }

  @override
  String masteryEvidenceWindow(int days) {
    return 'Résultats des $days derniers jours.';
  }

  @override
  String get passWelcomeBack => 'REPRENDRE SA PLACE';

  @override
  String get passSignIn => 'CONNEXION';

  @override
  String get passGoodToSeeYouAgain => 'Heureux de vous retrouver.';

  @override
  String get passLinkSent => 'LIEN ENVOYÉ';

  @override
  String get passRecoverMyAccess => 'RÉCUPÉRER MON ACCÈS';

  @override
  String get passForgotPassword => 'MOT DE PASSE OUBLIÉ';

  @override
  String get passOneLinkThenYouReBack => 'Un lien.\nEt tu reprends.';

  @override
  String get passFindYourWayBack => 'Retrouve\nton accès.';

  @override
  String get passTheNextStepIsWaitingIn =>
      'La prochaine étape t’attend dans ta messagerie.';

  @override
  String get passEmailAccess => 'ACCÈS PAR EMAIL';

  @override
  String get passYourNextChapterAwaits => 'La suite\nt’attend.';

  @override
  String get passReturnToYourSpaceWithYour =>
      'Retrouve ton espace avec ton email et ton mot de passe.';

  @override
  String get passChooseAnotherWayIn => 'Choisir un autre accès';

  @override
  String get passYourNumber => 'TON NUMÉRO';

  @override
  String get passVerificationInProgress => 'VÉRIFICATION EN COURS';

  @override
  String get passNumberVerified => 'NUMÉRO VÉRIFIÉ';

  @override
  String get passPhoneAccess => 'ACCÈS PAR TÉLÉPHONE';

  @override
  String get passSixDigitsThenWeContinue => 'Six chiffres.\nEt on continue.';

  @override
  String get passYourNumberIsConfirmed => 'Ton numéro\nest confirmé.';

  @override
  String get passYourNumberYourAccess => 'Ton numéro.\nTon accès.';

  @override
  String get passChooseYourSpace => '01 / CHOISIR SON ESPACE';

  @override
  String get passCreateAnAccount => 'CRÉER UN COMPTE';

  @override
  String get passYourPlaceStartsHere => 'Votre place commence ici.';

  @override
  String get passChooseYourSpaceYourPassTakes =>
      'Choisissez votre espace. Votre Pass prend forme avec vous.';

  @override
  String get passRegistrationComplete => 'INSCRIPTION TERMINÉE';

  @override
  String get passYourPlaceIsReady => 'TA PLACE\nEST PRÊTE.';

  @override
  String get passYourSpace => 'Votre espace';

  @override
  String get passPassReady => 'PASS PRÊT';

  @override
  String get passTakingShape => 'EN CONSTRUCTION';

  @override
  String get passAPlaceForYou => 'Une place pour vous.';

  @override
  String get passYourFamilySpace => 'Votre espace famille';

  @override
  String get passYourTeachingSpace => 'Votre espace enseignant';

  @override
  String get passValidationPending => 'Validation en attente';

  @override
  String get passAccountCreated => 'COMPTE CRÉÉ.';

  @override
  String passChildIdentifiersAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count identifiants ajoutés',
      one: '1 identifiant ajouté',
    );
    return '$_temp0';
  }

  @override
  String passWithCompanion(String companion) {
    return 'Avec $companion';
  }

  @override
  String get authorSignature =>
      'Application conçue par Calvin EKENA · +237 699 98 90 99';

  @override
  String get schoolHeadShieldTooltip => 'Espace direction d’établissement';

  @override
  String get schoolHeadSheetEyebrow => 'ESPACE DIRECTION';

  @override
  String get schoolHeadSheetTitle => 'Votre école,\nen entier.';

  @override
  String get schoolHeadSheetBody =>
      'Connectez-vous pour administrer toute votre école : personnel, classes, contenus et suivi. Les comptes des élèves restent les leurs : vous ne pouvez ni en ajouter ni en supprimer.';

  @override
  String get schoolHeadContinueEmail => 'Continuer par e-mail';

  @override
  String get schoolHeadContinuePhone => 'Continuer par téléphone';

  @override
  String get schoolHeadPhoneNote =>
      'Le téléphone fonctionne une fois votre numéro rattaché à votre compte, depuis vos paramètres.';

  @override
  String get schoolHeadRequestAccess => 'Demander un accès pour mon école';

  @override
  String get schoolDirectoryTitle => 'Annuaire de l’école';

  @override
  String get schoolDirectoryEmpty =>
      'Personne dans cette catégorie pour le moment.';

  @override
  String get schoolDirectoryStudentsNote =>
      'Les élèves rejoignent l’école par leur propre inscription : la direction les consulte, sans les ajouter ni les retirer.';

  @override
  String get schoolDirectoryLoadMore => 'Voir plus';

  @override
  String get schoolDirectoryPending => 'En attente de validation';

  @override
  String get schoolClassesTitle => 'Classes de l’école';

  @override
  String get schoolClassesEmpty =>
      'Aucune classe n’est encore ouverte pour votre école.';

  @override
  String schoolClassCounts(int students, int teachers) {
    return 'Élèves : $students · Enseignants : $teachers';
  }

  @override
  String get renameClassLabel => 'Renommer la classe';

  @override
  String get classNameLabel => 'Nom de la classe';

  @override
  String get reviewNoSchool => 'Aucune école rattachée';

  @override
  String get reviewAttachSchoolTitle => 'Rattacher à une école';

  @override
  String get reviewAttachSchoolBody =>
      'Ce compte n’appartient encore à aucune école. Choisissez la sienne pour l’approuver.';

  @override
  String get reviewCreateSchool => 'Ouvrir une nouvelle école';

  @override
  String get reviewCreateSchoolAction => 'Ouvrir et rattacher';

  @override
  String get accountReviewFailed =>
      'La décision n’a pas pu être enregistrée. Réessayez.';

  @override
  String get adminPhoneLinkTitle => 'Se connecter aussi par téléphone';

  @override
  String get adminPhoneLinkBody =>
      'Rattachez votre numéro pour recevoir un code à chaque connexion.';

  @override
  String get unattachedStaffTitle => 'Personnel sans école';

  @override
  String get unattachedStaffBody =>
      'Ces comptes ont été approuvés avant d’être rattachés. Sans école, ils ne composent ni ne gèrent rien pour elle.';

  @override
  String get unattachedStaffEmpty => 'Tout le personnel approuvé a son école.';

  @override
  String get attachStaffAction => 'Rattacher';

  @override
  String get attachStaffSheetBody =>
      'Choisissez l’école de ce compte. Une fois rattaché, il ne changera plus d’école depuis l’application.';

  @override
  String get staffAttached =>
      'Compte rattaché. La personne retrouve son école à sa prochaine ouverture de l’application.';

  @override
  String get schoolNameRequired => 'Donnez le nom complet de l’école.';

  @override
  String get schoolCityRequired => 'Indiquez la ville de l’école.';

  @override
  String get schoolCityHelper =>
      'Saisie libre, par exemple Douala ou Bafoussam.';

  @override
  String get schoolTransferTitle => 'Changer un compte d’école';

  @override
  String get schoolTransferBody =>
      'Erreur à l’inscription, déménagement, mutation : retrouvez l’élève, le parent ou le membre du personnel par son e-mail ou son téléphone.';

  @override
  String get schoolTransferQueryLabel => 'E-mail ou téléphone';

  @override
  String get schoolTransferQueryHint => '699 98 90 99 ou nom@exemple.cm';

  @override
  String get schoolTransferSearch => 'Rechercher';

  @override
  String get schoolTransferNoResult =>
      'Aucun compte ne correspond. Vérifiez l’e-mail ou le numéro.';

  @override
  String schoolTransferCurrentSchool(String school) {
    return 'École : $school';
  }

  @override
  String schoolTransferDeclared(String school) {
    return 'Déclarée à l’inscription : $school';
  }

  @override
  String get schoolTransferMove => 'Changer d’école';

  @override
  String get schoolTransferAttachBody => 'Choisissez l’école de ce compte.';

  @override
  String get schoolTransferMoveBody =>
      'Choisissez la nouvelle école. Ce compte quittera les classes de son ancienne école.';

  @override
  String get schoolTransferReasonTitle => 'Motif du changement';

  @override
  String get schoolTransferReasonHint =>
      'Par exemple : erreur du parent à l’inscription';

  @override
  String get schoolTransferConfirm => 'Confirmer le changement';

  @override
  String get schoolTransferDone =>
      'École mise à jour. La personne la retrouve à sa prochaine ouverture de l’application.';

  @override
  String get schoolTransferSameSchool =>
      'Ce compte appartient déjà à cette école.';

  @override
  String get schoolTransferChildren => 'Enfants liés';

  @override
  String get generalAdministrationAllSchools =>
      'Administration générale · toutes les écoles';

  @override
  String get broadcastTargetSchool => 'École destinataire';

  @override
  String get broadcastTargetSchoolRequired =>
      'Choisissez l’école destinataire.';

  @override
  String get announcementFailed =>
      'L’annonce n’a pas pu être publiée. Réessayez.';

  @override
  String get schoolsOverviewTitle => 'Écoles';

  @override
  String get schoolsOverviewBody =>
      'Toutes les écoles d’INTELLIA237. Touchez-en une pour voir son annuaire et ses classes.';

  @override
  String get schoolsOverviewCreate => 'Ouvrir une école';

  @override
  String get schoolsOverviewEmpty => 'Aucune école n’est encore ouverte.';

  @override
  String get schoolsOverviewHint =>
      'Choisissez une école existante, ou ouvrez-en une nouvelle avec sa ville.';

  @override
  String get parentPreviewBadge => 'Prévisualisation Parent';

  @override
  String get parentPreviewExit => 'Quitter l’aperçu';

  @override
  String parentPreviewViewingParent(String name) {
    return 'Espace de $name';
  }

  @override
  String get parentPreviewOwnAccountNote =>
      'Aperçu de votre propre espace Parent.';

  @override
  String get adminParentPreviewAction => 'Prévisualiser l’espace Parent';

  @override
  String get adminParentPreviewDescription =>
      'Ouvrir l’espace Parent en tant que super-administrateur, sans changer de compte.';

  @override
  String get parentPreviewChooseParent => 'Prévisualiser en tant que';

  @override
  String get parentPreviewOwnAccount => 'Mon compte (super-admin)';

  @override
  String get parentPreviewNoParents =>
      'Aucun compte parent à prévisualiser pour l’instant.';

  @override
  String get parentPreviewPaymentsBlockedTitle =>
      'Paiement indisponible en prévisualisation';

  @override
  String get parentPreviewPaymentsBlockedBody =>
      'Vous consultez l’espace d’un autre parent : pour protéger ses données, aucune opération de paiement n’est possible ici.';

  @override
  String get addChildTitle => 'Ajouter un enfant';

  @override
  String get addChildCodeLabel => 'Code de liaison de l’enfant';

  @override
  String get addChildCodeHelp =>
      'Demande à ton enfant son code, visible dans son espace Profil › « Mon code parent ».';

  @override
  String get addChildSubmit => 'Lier l’enfant';

  @override
  String addChildSuccess(String name) {
    return '$name est maintenant lié à ton compte.';
  }

  @override
  String addChildAlready(String name) {
    return '$name est déjà lié à ton compte.';
  }

  @override
  String get studentLinkCodeTitle => 'Mon code parent';

  @override
  String get studentLinkCodeBody =>
      'Communique ce code à ton parent pour qu’il puisse suivre ta progression.';

  @override
  String get studentLinkCodeCopy => 'Copier le code';

  @override
  String get studentLinkCodeCopied => 'Code copié.';

  @override
  String get studentLinkCodeError =>
      'Le code n’a pas pu être généré. Réessaie.';

  @override
  String get studentLinkCodeRotate => 'Régénérer le code';

  @override
  String get studentLinkCodeRotateConfirmTitle => 'Régénérer le code ?';

  @override
  String get studentLinkCodeRotateConfirmBody =>
      'L’ancien code cessera immédiatement de fonctionner. Les parents déjà liés le restent.';

  @override
  String get studentLinkCodeRotated => 'Nouveau code généré.';

  @override
  String get createClassLabel => 'Créer une classe';

  @override
  String get classLevelLabel => 'Niveau';

  @override
  String get classSeriesLabel => 'Série (optionnel)';

  @override
  String get classTrackLabel => 'Filière (optionnel)';

  @override
  String get classSeriesNone => 'Aucune';

  @override
  String get deleteClassLabel => 'Supprimer la classe';

  @override
  String deleteClassConfirm(String name) {
    return 'Supprimer « $name » ? Cette classe est vide.';
  }

  @override
  String get deleteClassBlocked =>
      'Classe non vide : retirez d’abord les élèves.';

  @override
  String get classCreatedMessage => 'Classe créée.';

  @override
  String get classDeletedMessage => 'Classe supprimée.';

  @override
  String get editEstablishmentLabel => 'Modifier l’école';

  @override
  String get archiveEstablishmentLabel => 'Archiver l’école';

  @override
  String get unarchiveEstablishmentLabel => 'Réactiver l’école';

  @override
  String get establishmentArchivedBadge => 'Archivée';

  @override
  String get establishmentCityLabel => 'Ville';

  @override
  String get flowChoiceTrue => 'Vrai';

  @override
  String get flowChoiceFalse => 'Faux';

  @override
  String flowHintPrefix(String hint) {
    return 'Indice : $hint';
  }

  @override
  String get flowFeedbackCorrect => 'Exact !';

  @override
  String get flowFeedbackIncorrect => 'Pas encore.';

  @override
  String flowExpectedOrder(String order) {
    return 'Ordre attendu : $order';
  }

  @override
  String get flowSwipeToContinue => 'Balayez vers le haut pour continuer';

  @override
  String get childLinkErrorNotFound =>
      'Ce code enfant est introuvable. Vérifie-le avec ton enfant.';

  @override
  String get childLinkErrorInvalid =>
      'Saisis le code de liaison de ton enfant.';

  @override
  String get childLinkErrorPermission =>
      'Seul un compte parent peut rattacher un enfant.';

  @override
  String get childLinkErrorUnauthenticated =>
      'Ta session a expiré. Reconnecte-toi puis réessaie.';

  @override
  String get childLinkErrorTooMany =>
      'Trop de tentatives. Réessaie un peu plus tard.';

  @override
  String get childLinkErrorGeneric =>
      'La liaison n’a pas abouti. Réessaie dans un instant.';

  @override
  String get studyReserveTitle => 'Réserve d’étude';

  @override
  String studyReserveRemaining(int percent) {
    return '$percent % restants';
  }

  @override
  String studyReserveRenews(String date) {
    return 'Renouvellement le $date';
  }

  @override
  String get studyReserveStatusHealthy => 'Bonne réserve';

  @override
  String get studyReserveStatusWarning => 'À surveiller';

  @override
  String get studyReserveStatusLow => 'Réserve basse';

  @override
  String get studyReserveStatusCritical => 'Presque épuisée';

  @override
  String get studyReserveStatusDepleted => 'Réserve épuisée';

  @override
  String get studyReserveDepletedHelp =>
      'Le tuteur IA se repose jusqu’au renouvellement. Les cours, quiz et lectures restent accessibles.';

  @override
  String get studyReserveUnavailable =>
      'Réserve d’étude indisponible pour le moment.';

  @override
  String get studyReserveNotifTitle => 'Réserve d’étude';

  @override
  String studyReserveNotifInfo(int percent) {
    return 'Il reste $percent % de la réserve d’étude ce cycle.';
  }

  @override
  String studyReserveNotifLow(int percent) {
    return 'La réserve d’étude est à $percent %. Pense à la ménager pour le tuteur.';
  }

  @override
  String studyReserveNotifCritical(int percent) {
    return 'La réserve d’étude est presque épuisée ($percent %).';
  }

  @override
  String get studyReserveNotifDepleted =>
      'La réserve d’étude est épuisée ; elle se renouvelle au prochain cycle. Les cours et quiz restent accessibles.';

  @override
  String get studyReserveLoadError =>
      'Impossible de charger la réserve d’étude pour le moment.';

  @override
  String companionStudyReserveDepleted(String name) {
    return 'Ta réserve d’étude est épuisée pour ce cycle. $name reprendra au renouvellement ; tes cours et quiz restent accessibles.';
  }

  @override
  String get parentEntryTitle => 'Reliez votre enfant';

  @override
  String get parentEntrySubtitle =>
      'Saisissez son code, puis connectez-vous avec votre propre numéro.';

  @override
  String get parentEntryHaveCode => 'J’ai un code enfant';

  @override
  String get parentEntryCodeLabel => 'Code de l’enfant';

  @override
  String get parentEntryCodeHint => 'Ex. K7MP2QXA';

  @override
  String get parentEntryCodeHelp =>
      'Votre enfant le trouve dans son profil, rubrique « Mon code parent ».';

  @override
  String get parentEntryCodeInvalid =>
      'Un code enfant compte 8 lettres et chiffres. Vérifiez-le avec votre enfant.';

  @override
  String get parentEntryPaste => 'Coller';

  @override
  String get parentEntryAlreadyParent => 'Je suis déjà parent';

  @override
  String get parentEntryPrivacy =>
      'Le code sert uniquement à relier votre enfant, une fois votre connexion établie.';

  @override
  String get phonePendingChildCode =>
      'Code enfant prêt : il sera relié après votre connexion.';

  @override
  String get phoneLinkingChild => 'Rattachement de votre enfant…';

  @override
  String get passNumberAlreadyUsed => 'Numéro déjà associé';

  @override
  String get roleConflictStudentAccount =>
      'Ce numéro est déjà associé à un compte élève.';

  @override
  String get roleConflictParentAccount =>
      'Ce numéro est déjà associé à un compte parent.';

  @override
  String get roleConflictStaffAccount =>
      'Ce numéro est déjà associé à un compte de l’établissement.';

  @override
  String get roleConflictCredentialsStudentAccount =>
      'Ces identifiants ouvrent un compte élève.';

  @override
  String get roleConflictCredentialsParentAccount =>
      'Ces identifiants ouvrent un compte parent.';

  @override
  String get roleConflictCredentialsStaffAccount =>
      'Ces identifiants ouvrent un compte de l’établissement.';

  @override
  String get roleConflictUseParentCredentials =>
      'Pour créer ou ouvrir un espace parent, utilisez les identifiants du parent.';

  @override
  String get roleConflictUseStudentCredentials =>
      'Pour ouvrir l’espace élève, utilisez les identifiants de l’élève.';

  @override
  String get roleConflictChildCodeKept => 'Le code enfant reste enregistré.';

  @override
  String get roleConflictUseAnotherNumber => 'Utiliser un autre numéro';

  @override
  String get childLinkReportFailedTitle =>
      'Le code enfant n’a pas pu être relié';

  @override
  String childLinkBatchSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enfants reliés à votre compte.',
      one: '1 enfant relié à votre compte.',
    );
    return '$_temp0';
  }

  @override
  String get parentEntryCodePurpose =>
      'Ce code permet de rattacher l’enfant.\nVotre numéro de téléphone sert à vous identifier comme parent.';

  @override
  String get passFamilyNumber => 'Numéro de la famille';

  @override
  String get familyPhoneMigrationPrompt =>
      'Ce numéro est actuellement utilisé pour l’accès d’un élève. Souhaitez-vous l’utiliser comme numéro du parent ? L’élève conservera son profil et utilisera désormais son code d’accès INTELLIA.';

  @override
  String get familyPhoneMigrationConfirm => 'Utiliser ce numéro pour le parent';

  @override
  String get familyPhoneMigrationNothingChanged =>
      'Le transfert n’a pas abouti. Rien n’a changé : réessayez.';

  @override
  String get familyPhoneMigrationVerifyAgain =>
      'Pour votre sécurité, vérifiez à nouveau ce numéro avant de le transférer.';

  @override
  String get familyPhoneMigrationVerifyAgainAction =>
      'Vérifier à nouveau le numéro';

  @override
  String get familyPhoneMigrationInProgress =>
      'Un transfert est déjà en cours pour ce numéro. Patientez un instant puis réessayez.';

  @override
  String get familyPhoneMigrationVerifyAgainToFinish =>
      'L’élève a déjà son code d’accès. Vérifiez à nouveau ce numéro pour terminer l’ouverture de votre espace parent.';

  @override
  String get familyPhoneMigrationRefused =>
      'Ce numéro ne peut pas être transféré depuis ce compte. Utilisez un autre numéro ou contactez l’établissement.';

  @override
  String get familyPhoneMigrationUnavailable =>
      'Le transfert du numéro n’est pas encore disponible. Réessayez plus tard ou utilisez un autre numéro.';

  @override
  String get familyPhoneMigratedTitle => 'Ce numéro est désormais le vôtre';

  @override
  String get familyPhoneMigratedContinue =>
      'J’ai noté le code, ouvrir mon espace parent';

  @override
  String get studentNoPhoneUseAccessCode =>
      'Pas de téléphone ? Entre avec ton code d’accès INTELLIA';

  @override
  String get studentAccessCodePhase => 'Ton code d’accès';

  @override
  String get studentAccessCodeTitle => 'Entre avec ton code d’accès';

  @override
  String get studentAccessCodeSubtitle =>
      'Saisis les 12 caractères que ton parent ou ton établissement t’a donnés. Pas besoin de téléphone.';

  @override
  String get studentAccessCodeLabel => 'Code d’accès INTELLIA';

  @override
  String get studentAccessCodeSubmit => 'Entrer dans mon espace';

  @override
  String get studentAccessCodePrivacy =>
      'Garde ce code pour toi : il ouvre ton espace. Si tu l’as perdu, demande un nouveau code à ton parent ou à ton établissement.';

  @override
  String get studentAccessCodeUsePhone => 'J’ai un téléphone : recevoir un SMS';

  @override
  String get studentAccessCodeInvalid =>
      'Ce code ne fonctionne pas. Vérifie-le, ou demande un nouveau code à ton parent ou à ton établissement.';

  @override
  String get studentAccessCodeTooManyAttempts =>
      'Trop d’essais. Attends quelques minutes avant de réessayer.';

  @override
  String get studentAccessCodeUnavailable =>
      'Le service ne répond pas pour le moment. Réessaie dans un instant.';

  @override
  String studentAccessCodeRevealTitle(String name) {
    return 'Code d’accès INTELLIA de $name';
  }

  @override
  String get studentAccessCodeRevealTitleGeneric =>
      'Code d’accès INTELLIA de l’élève';

  @override
  String studentAccessCodeRevealBody(String name) {
    return 'Notez ce code et remettez-le à $name : il ouvre son espace sans téléphone. Il ne sera plus affiché ; vous pourrez en générer un nouveau depuis sa fiche.';
  }

  @override
  String get studentAccessCodeRevealBodyGeneric =>
      'Notez ce code et remettez-le à l’élève : il ouvre son espace sans téléphone. Il ne sera plus affiché ; vous pourrez en générer un nouveau depuis sa fiche.';

  @override
  String get studentAccessCodeNotShownAgain =>
      'Le code d’accès de l’élève a déjà été créé. Pour sa sécurité, il n’est jamais affiché à nouveau : générez-en un nouveau depuis sa fiche.';

  @override
  String get studentAccessCodeCopy => 'Copier le code';

  @override
  String get studentAccessCodeCopied => 'Code copié';

  @override
  String get studentAccessCodeSheetBody =>
      'Ce code permet à votre enfant d’ouvrir son espace INTELLIA sans téléphone. Pour sa sécurité, il n’est jamais affiché à nouveau : générer un nouveau code remplace l’ancien, qui cesse aussitôt de fonctionner.';

  @override
  String get studentAccessCodeGenerate =>
      'Afficher / générer un nouveau code d’accès';

  @override
  String get studentAccessCodeReplaceTitle => 'Remplacer le code d’accès ?';

  @override
  String studentAccessCodeReplaceBody(String name) {
    return 'L’ancien code de $name cessera immédiatement de fonctionner.';
  }

  @override
  String get studentAccessCodeReplaceConfirm => 'Générer le nouveau code';

  @override
  String get studentAccessCodeDone => 'J’ai noté le code';

  @override
  String get studentAccessCodeIssueFailed =>
      'Le code n’a pas pu être généré. Réessayez.';

  @override
  String studentAccessCodeActiveSince(String date) {
    return 'Code d’accès actif depuis le $date';
  }

  @override
  String get studentAccessCodeActive => 'Code d’accès actif';

  @override
  String get studentAccessCodeNone => 'Aucun code d’accès pour l’instant';

  @override
  String get childAccessOwnPhone => 'Connecté avec son propre accès INTELLIA';

  @override
  String get childAccessCodeOnly =>
      'Se connecte avec son code d’accès INTELLIA';

  @override
  String get childAccessUnknown =>
      'Accès de l’enfant non disponible pour le moment';

  @override
  String get childAccessNone =>
      'Aucun accès personnel : générez son code d’accès';

  @override
  String get childActionViewProfile => 'Voir le profil';

  @override
  String get childActionViewActivity => 'Voir son activité';

  @override
  String get childActionAccessCode => 'Code d’accès élève';

  @override
  String get childActionSubscription => 'Abonnement';

  @override
  String childSubscriptionActiveUntil(String date) {
    return 'Abonnement actif jusqu’au $date';
  }

  @override
  String get childSubscriptionPaidByAnotherGuardian =>
      'Réglé par un autre responsable de l’enfant';

  @override
  String get childSubscriptionInactive =>
      'Aucun abonnement actif pour cet enfant';

  @override
  String get childSchoolUnknown => 'Établissement non renseigné';

  @override
  String parentChildrenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enfants',
      one: '1 enfant',
    );
    return '$_temp0';
  }

  @override
  String parentModeProfileBanner(String name) {
    return 'MODE PARENT — PROFIL DE $name';
  }

  @override
  String get parentModeProfileNote =>
      'Vous consultez ce profil avec votre compte parent. Vous ne pouvez rien y modifier au nom de votre enfant.';

  @override
  String get childProfileTitle => 'Profil de l’enfant';

  @override
  String get childProfileClass => 'Classe';

  @override
  String get childProfileSchool => 'Établissement';

  @override
  String get childProfileAccess => 'Accès INTELLIA';

  @override
  String get childProfileSubscription => 'Abonnement';

  @override
  String get parentSchoolsAnnouncements => 'Annonces des écoles de vos enfants';

  @override
  String get mobileMoneyChooseChild => 'Pour quel enfant payez-vous ?';

  @override
  String mobileMoneyOfferOfSchool(String school) {
    return 'Offre de $school';
  }

  @override
  String mobileMoneyCoversChildren(String names) {
    return 'Ce paiement couvre : $names';
  }

  @override
  String get childPendingFirstSignIn => 'En attente de sa première connexion';

  @override
  String get addChildNoAccountAction =>
      'Mon enfant n’a pas encore de compte INTELLIA';

  @override
  String get addChildNoAccountTitle => 'Ouvrir l’accès de votre enfant';

  @override
  String get addChildNoAccountBody =>
      'Votre enfant n’a pas besoin de téléphone. Vous recevrez son code d’accès INTELLIA ; il complétera lui-même son profil scolaire à sa première connexion.';

  @override
  String get addChildNoAccountNameLabel => 'Prénom de l’enfant';

  @override
  String get addChildNoAccountNameRequired =>
      'Indiquez le prénom de votre enfant.';

  @override
  String get addChildNoAccountSubmit => 'Créer son code d’accès';

  @override
  String get addChildNoAccountFailed =>
      'L’accès n’a pas pu être ouvert. Réessayez.';

  @override
  String get adminStudentAccessRecoveryTitle => 'Récupérer l’accès de l’élève';

  @override
  String get adminStudentAccessRecoveryBody =>
      'Un nouveau code d’accès INTELLIA remplace le précédent, qui cesse aussitôt de fonctionner. Remettez-le à l’élève ou à sa famille en main propre : il ne sera plus affiché.';

  @override
  String get adminStudentPhoneOptional => 'Téléphone de l’élève (facultatif)';

  @override
  String get childActionLinkCode => 'Code de liaison parent';

  @override
  String guardianLinkCodeBody(String name) {
    return 'Ce code permet à un autre parent ou responsable de rattacher $name à son propre compte. Il n’ouvre pas l’espace de l’élève : pour cela, utilisez le code d’accès élève.';
  }

  @override
  String get guardianLinkCodeRotate => 'Remplacer ce code';

  @override
  String get guardianLinkCodeRotateBody =>
      'L’ancien code de liaison cessera immédiatement de fonctionner. Les responsables déjà rattachés le restent.';

  @override
  String get guardianLinkCodeUnavailable =>
      'Le code de liaison n’a pas pu être obtenu. Réessayez.';
}
