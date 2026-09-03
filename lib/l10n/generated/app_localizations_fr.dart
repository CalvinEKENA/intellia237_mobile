// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

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
      'Trop de tentatives. Patientez quelques minutes avant de réessayer.';

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
      'La demande sera enregistrée pour vérification et traitement sécurisé. Cette action te déconnectera.';

  @override
  String get sendRequestLabel => 'Envoyer la demande';

  @override
  String get deleteRequestError =>
      'Impossible d’envoyer la demande maintenant. Réessaie plus tard.';

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
}
