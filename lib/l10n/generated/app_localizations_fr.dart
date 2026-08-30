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
  String get skipIntroduction => 'Passer l’expérience';

  @override
  String get skipIntroductionA11y => 'Passer l’expérience d’introduction';

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
  String get academicPassport => 'Passeport académique';

  @override
  String get academicPassportDescription =>
      'Regroupez l’identité d’usage, la langue et le parcours scolaire dans une seule fiche.';

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
}
