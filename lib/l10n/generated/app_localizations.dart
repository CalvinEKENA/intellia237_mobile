import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @adminManageProfile.
  ///
  /// In fr, this message translates to:
  /// **'Administrer le profil'**
  String get adminManageProfile;

  /// No description provided for @adminSuspendProfile.
  ///
  /// In fr, this message translates to:
  /// **'Suspendre le profil'**
  String get adminSuspendProfile;

  /// No description provided for @adminReactivateProfile.
  ///
  /// In fr, this message translates to:
  /// **'Réactiver le profil'**
  String get adminReactivateProfile;

  /// No description provided for @adminRestoreProfile.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer le profil'**
  String get adminRestoreProfile;

  /// No description provided for @adminDeleteProfile.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le profil'**
  String get adminDeleteProfile;

  /// No description provided for @adminAccountUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Le profil a été mis à jour.'**
  String get adminAccountUpdated;

  /// No description provided for @adminDeleteProfileBody.
  ///
  /// In fr, this message translates to:
  /// **'Le profil sera retiré des annuaires et son accès sera bloqué. Ses données seront conservées pour permettre sa restauration par l’administration générale.'**
  String get adminDeleteProfileBody;

  /// No description provided for @adminAccountDecisionBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette décision modifie l’accès du compte. Son motif sera conservé dans l’historique d’administration.'**
  String get adminAccountDecisionBody;

  /// No description provided for @adminDecisionReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif de la décision'**
  String get adminDecisionReason;

  /// No description provided for @adminCreateStudent.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un élève'**
  String get adminCreateStudent;

  /// No description provided for @adminCreateStudentBody.
  ///
  /// In fr, this message translates to:
  /// **'Créez son compte dans l’établissement choisi. L’élève se connectera avec son numéro, puis complétera sa classe et ses préférences.'**
  String get adminCreateStudentBody;

  /// No description provided for @adminStudentCreated.
  ///
  /// In fr, this message translates to:
  /// **'Le compte élève est créé. Il peut se connecter par téléphone.'**
  String get adminStudentCreated;

  /// No description provided for @adminStudentContactExists.
  ///
  /// In fr, this message translates to:
  /// **'Ce téléphone ou cet e-mail possède déjà un compte. Retrouvez-le avec la recherche.'**
  String get adminStudentContactExists;

  /// No description provided for @adminStudentFirstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get adminStudentFirstName;

  /// No description provided for @adminStudentLastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get adminStudentLastName;

  /// No description provided for @adminFieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire.'**
  String get adminFieldRequired;

  /// No description provided for @adminStudentEmailOptional.
  ///
  /// In fr, this message translates to:
  /// **'E-mail (facultatif)'**
  String get adminStudentEmailOptional;

  /// No description provided for @adminInvalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez l’adresse e-mail.'**
  String get adminInvalidEmail;

  /// No description provided for @adminStatusSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Compte suspendu'**
  String get adminStatusSuspended;

  /// No description provided for @adminStatusDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Profil supprimé'**
  String get adminStatusDeleted;

  /// No description provided for @backToPreviousAct.
  ///
  /// In fr, this message translates to:
  /// **'Revenir à l’acte précédent'**
  String get backToPreviousAct;

  /// No description provided for @onboardingOpeningBody.
  ///
  /// In fr, this message translates to:
  /// **'Une expérience d’apprentissage pour mieux comprendre, pratiquer et progresser.'**
  String get onboardingOpeningBody;

  /// No description provided for @onboardingTapToContinue.
  ///
  /// In fr, this message translates to:
  /// **'Appuie pour continuer'**
  String get onboardingTapToContinue;

  /// No description provided for @companionSwitchHint.
  ///
  /// In fr, this message translates to:
  /// **'Touche ou balaie pour changer de personnalité.'**
  String get companionSwitchHint;

  /// No description provided for @companionChangeLater.
  ///
  /// In fr, this message translates to:
  /// **'Tu pourras changer plus tard.'**
  String get companionChangeLater;

  /// No description provided for @ascensionSemanticLabel.
  ///
  /// In fr, this message translates to:
  /// **'L’Ascension'**
  String get ascensionSemanticLabel;

  /// No description provided for @ascensionEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'ACTE VI — L’ASCENSION'**
  String get ascensionEyebrow;

  /// No description provided for @ascensionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton avenir se construit, marche après marche.'**
  String get ascensionTitle;

  /// No description provided for @ascensionBody.
  ///
  /// In fr, this message translates to:
  /// **'INTELLIA237 complète tes cours, tes livres et tes cahiers pour t’aider à comprendre, t’entraîner et progresser. Tes enseignants restent au cœur de ton parcours.'**
  String get ascensionBody;

  /// No description provided for @ascensionCta.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon INTELLIA PASS'**
  String get ascensionCta;

  /// No description provided for @ascensionImageA11y.
  ///
  /// In fr, this message translates to:
  /// **'Deux élèves avancent vers une bibliothèque lumineuse, symbole de leur progression scolaire'**
  String get ascensionImageA11y;

  /// No description provided for @portalContinue.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir la suite'**
  String get portalContinue;

  /// No description provided for @passEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'INTELLIA PASS'**
  String get passEyebrow;

  /// No description provided for @passTitle.
  ///
  /// In fr, this message translates to:
  /// **'Qui utilise INTELLIA237 ?'**
  String get passTitle;

  /// No description provided for @passSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Un accès clair pour chaque membre de la famille, même lorsque l’appareil est partagé.'**
  String get passSubtitle;

  /// No description provided for @studentRole.
  ///
  /// In fr, this message translates to:
  /// **'Élève'**
  String get studentRole;

  /// No description provided for @studentRoleDescription.
  ///
  /// In fr, this message translates to:
  /// **'Apprendre, s’entraîner et progresser avec un compagnon pédagogique.'**
  String get studentRoleDescription;

  /// No description provided for @parentRole.
  ///
  /// In fr, this message translates to:
  /// **'Parent ou responsable'**
  String get parentRole;

  /// No description provided for @parentRoleDescription.
  ///
  /// In fr, this message translates to:
  /// **'Créer le foyer, ajouter plusieurs enfants et suivre leur progression.'**
  String get parentRoleDescription;

  /// No description provided for @professionalAccess.
  ///
  /// In fr, this message translates to:
  /// **'Accès professionnel'**
  String get professionalAccess;

  /// No description provided for @teacherRole.
  ///
  /// In fr, this message translates to:
  /// **'Enseignant'**
  String get teacherRole;

  /// No description provided for @teacherRoleDescription.
  ///
  /// In fr, this message translates to:
  /// **'Préparer les classes et partager des ressources pédagogiques.'**
  String get teacherRoleDescription;

  /// No description provided for @continueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueLabel;

  /// No description provided for @existingAccount.
  ///
  /// In fr, this message translates to:
  /// **'J’ai déjà un compte'**
  String get existingAccount;

  /// No description provided for @chooseIdentityA11y.
  ///
  /// In fr, this message translates to:
  /// **'Choisir le profil {role}'**
  String chooseIdentityA11y(String role);

  /// No description provided for @householdQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Qui apprend aujourd’hui ?'**
  String get householdQuestion;

  /// No description provided for @householdSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un profil élève. Le changement de profil ne contourne jamais les autorisations du parent.'**
  String get householdSubtitle;

  /// No description provided for @addLearner.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un enfant'**
  String get addLearner;

  /// No description provided for @parentArea.
  ///
  /// In fr, this message translates to:
  /// **'Espace parent'**
  String get parentArea;

  /// No description provided for @academicPassport.
  ///
  /// In fr, this message translates to:
  /// **'Passeport scolaire'**
  String get academicPassport;

  /// No description provided for @academicPassportDescription.
  ///
  /// In fr, this message translates to:
  /// **'Parle-nous un peu de toi pour préparer ton espace.'**
  String get academicPassportDescription;

  /// No description provided for @interfaceLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l’interface'**
  String get interfaceLanguage;

  /// No description provided for @frenchLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get frenchLanguage;

  /// No description provided for @englishLanguage.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @educationalSubsystem.
  ///
  /// In fr, this message translates to:
  /// **'Sous-système éducatif'**
  String get educationalSubsystem;

  /// No description provided for @francophoneSubsystem.
  ///
  /// In fr, this message translates to:
  /// **'Francophone'**
  String get francophoneSubsystem;

  /// No description provided for @anglophoneSubsystem.
  ///
  /// In fr, this message translates to:
  /// **'Anglophone'**
  String get anglophoneSubsystem;

  /// No description provided for @educationType.
  ///
  /// In fr, this message translates to:
  /// **'Type d’enseignement'**
  String get educationType;

  /// No description provided for @generalEducation.
  ///
  /// In fr, this message translates to:
  /// **'Général'**
  String get generalEducation;

  /// No description provided for @technicalEducation.
  ///
  /// In fr, this message translates to:
  /// **'Technique'**
  String get technicalEducation;

  /// No description provided for @schoolLevel.
  ///
  /// In fr, this message translates to:
  /// **'Niveau'**
  String get schoolLevel;

  /// No description provided for @streamOrSpeciality.
  ///
  /// In fr, this message translates to:
  /// **'Série, filière ou spécialité'**
  String get streamOrSpeciality;

  /// No description provided for @establishment.
  ///
  /// In fr, this message translates to:
  /// **'Établissement'**
  String get establishment;

  /// No description provided for @establishmentHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher ou saisir un établissement'**
  String get establishmentHint;

  /// No description provided for @establishmentUnverified.
  ///
  /// In fr, this message translates to:
  /// **'Établissement sélectionné — vérification en attente'**
  String get establishmentUnverified;

  /// No description provided for @establishmentSecurityNote.
  ///
  /// In fr, this message translates to:
  /// **'La sélection d’un établissement ne donne accès à aucune donnée privée. L’autorisation du serveur reste obligatoire.'**
  String get establishmentSecurityNote;

  /// No description provided for @individualAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte élève individuel'**
  String get individualAccount;

  /// No description provided for @parentLinkedAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte rattaché au foyer familial'**
  String get parentLinkedAccount;

  /// No description provided for @parentLinkedHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le parent crée et protège les profils du foyer depuis son espace.'**
  String get parentLinkedHelp;

  /// No description provided for @learningCompanion.
  ///
  /// In fr, this message translates to:
  /// **'Compagnon pédagogique'**
  String get learningCompanion;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get createAccount;

  /// No description provided for @previousStep.
  ///
  /// In fr, this message translates to:
  /// **'Étape précédente'**
  String get previousStep;

  /// No description provided for @phoneOtp.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone et code de vérification'**
  String get phoneOtp;

  /// No description provided for @emailAuthentication.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get emailAuthentication;

  /// No description provided for @availableNow.
  ///
  /// In fr, this message translates to:
  /// **'Disponible maintenant'**
  String get availableNow;

  /// No description provided for @plannedLater.
  ///
  /// In fr, this message translates to:
  /// **'Prévu ultérieurement'**
  String get plannedLater;

  /// No description provided for @loginEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'Votre espace personnel'**
  String get loginEyebrow;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Heureux de vous retrouver.'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Reprenez votre progression et retrouvez votre compagnon pédagogique.'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In fr, this message translates to:
  /// **'prenom.nom@exemple.com'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre mot de passe'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get noAccount;

  /// No description provided for @createAccountLink.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccountLink;

  /// No description provided for @forgotEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'Accès au compte'**
  String get forgotEyebrow;

  /// No description provided for @forgotTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retrouvez votre mot de passe.'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Nous enverrons un lien sécurisé à l’adresse de votre compte.'**
  String get forgotSubtitle;

  /// No description provided for @emailSent.
  ///
  /// In fr, this message translates to:
  /// **'E-mail envoyé'**
  String get emailSent;

  /// No description provided for @checkEmail.
  ///
  /// In fr, this message translates to:
  /// **'Consultez {email} et ouvrez le lien reçu.'**
  String checkEmail(String email);

  /// No description provided for @backToLogin.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get backToLogin;

  /// No description provided for @sendLink.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get sendLink;

  /// No description provided for @phonePrimary.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone camerounais'**
  String get phonePrimary;

  /// No description provided for @phonePrimaryHint.
  ///
  /// In fr, this message translates to:
  /// **'+237 6XX XX XX XX'**
  String get phonePrimaryHint;

  /// No description provided for @emailOptional.
  ///
  /// In fr, this message translates to:
  /// **'E-mail (optionnel)'**
  String get emailOptional;

  /// No description provided for @phoneIdentityTarget.
  ///
  /// In fr, this message translates to:
  /// **'Identité cible : téléphone + code OTP'**
  String get phoneIdentityTarget;

  /// No description provided for @temporaryEmailNotice.
  ///
  /// In fr, this message translates to:
  /// **'Dans cette version, un e-mail technique reste temporairement nécessaire pour créer le compte Firebase. Il ne constitue pas l’identité principale cible.'**
  String get temporaryEmailNotice;

  /// No description provided for @temporaryEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'E-mail technique (temporaire)'**
  String get temporaryEmailLabel;

  /// No description provided for @otpChannelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment souhaitez-vous recevoir le code ?'**
  String get otpChannelTitle;

  /// No description provided for @otpWhatsapp.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir le code par WhatsApp'**
  String get otpWhatsapp;

  /// No description provided for @otpSms.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir le code par SMS'**
  String get otpSms;

  /// No description provided for @otpSmsFallback.
  ///
  /// In fr, this message translates to:
  /// **'Le SMS reste disponible si vous n’utilisez pas WhatsApp.'**
  String get otpSmsFallback;

  /// No description provided for @studyModeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mode Étude'**
  String get studyModeTitle;

  /// No description provided for @studyModeDuration.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la durée d’étude'**
  String get studyModeDuration;

  /// No description provided for @studyModeComplete.
  ///
  /// In fr, this message translates to:
  /// **'Session terminée'**
  String get studyModeComplete;

  /// No description provided for @studyModeCompleteBody.
  ///
  /// In fr, this message translates to:
  /// **'L’appareil reste dans INTELLIA237 jusqu’à ce que le parent le récupère.'**
  String get studyModeCompleteBody;

  /// No description provided for @studyModeFamilyCopy.
  ///
  /// In fr, this message translates to:
  /// **'Prêtez votre téléphone pour étudier, pas pour se distraire.'**
  String get studyModeFamilyCopy;

  /// No description provided for @reclaimDevice.
  ///
  /// In fr, this message translates to:
  /// **'Récupérer l’appareil'**
  String get reclaimDevice;

  /// No description provided for @preparingYourSpace.
  ///
  /// In fr, this message translates to:
  /// **'Préparation de ton espace…'**
  String get preparingYourSpace;

  /// No description provided for @companionQuotaReached.
  ///
  /// In fr, this message translates to:
  /// **'Tu as utilisé toutes tes questions du jour. Tu pourras de nouveau interroger {name} demain.'**
  String companionQuotaReached(String name);

  /// No description provided for @companionProfileSync.
  ///
  /// In fr, this message translates to:
  /// **'{name} a besoin de resynchroniser ton profil avant de répondre. Tes cours et exercices restent disponibles.'**
  String companionProfileSync(String name);

  /// No description provided for @companionInvalidRequest.
  ///
  /// In fr, this message translates to:
  /// **'{name} ne peut pas traiter cette question. Reformule-la en quelques mots.'**
  String companionInvalidRequest(String name);

  /// No description provided for @companionNetworkUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'{name} n’arrive pas à se connecter pour le moment. Vérifie ta connexion; tes cours et exercices restent disponibles.'**
  String companionNetworkUnavailable(String name);

  /// No description provided for @companionServiceUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'{name} n’arrive pas à répondre pour le moment. Tu peux continuer à consulter tes cours et exercices.'**
  String companionServiceUnavailable(String name);

  /// No description provided for @companionInvalidResponse.
  ///
  /// In fr, this message translates to:
  /// **'{name} a reçu une réponse incomplète. Tu peux réessayer dans un instant.'**
  String companionInvalidResponse(String name);

  /// No description provided for @companionStatusReady.
  ///
  /// In fr, this message translates to:
  /// **'Prêt à t’aider'**
  String get companionStatusReady;

  /// No description provided for @companionStatusThinking.
  ///
  /// In fr, this message translates to:
  /// **'réfléchit…'**
  String get companionStatusThinking;

  /// No description provided for @companionStatusQuota.
  ///
  /// In fr, this message translates to:
  /// **'limite du jour atteinte'**
  String get companionStatusQuota;

  /// No description provided for @companionStatusProfile.
  ///
  /// In fr, this message translates to:
  /// **'profil à synchroniser'**
  String get companionStatusProfile;

  /// No description provided for @companionStatusNetwork.
  ///
  /// In fr, this message translates to:
  /// **'connexion à retrouver'**
  String get companionStatusNetwork;

  /// No description provided for @companionStatusUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'réponse indisponible'**
  String get companionStatusUnavailable;

  /// No description provided for @phoneAuthEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'ACCÈS SÉCURISÉ · 237'**
  String get phoneAuthEyebrow;

  /// No description provided for @phoneAuthTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre numéro ouvre votre espace.'**
  String get phoneAuthTitle;

  /// No description provided for @phoneAuthSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Nous envoyons un code unique par SMS. Aucun e-mail n’est nécessaire.'**
  String get phoneAuthSubtitle;

  /// No description provided for @phoneLinkTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter votre téléphone.'**
  String get phoneLinkTitle;

  /// No description provided for @phoneLinkSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte et votre profil actuels restent inchangés.'**
  String get phoneLinkSubtitle;

  /// No description provided for @cameroonCountry.
  ///
  /// In fr, this message translates to:
  /// **'Cameroun'**
  String get cameroonCountry;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberLocalHint.
  ///
  /// In fr, this message translates to:
  /// **'6XX XX XX XX'**
  String get phoneNumberLocalHint;

  /// No description provided for @sendVerificationCode.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir mon code'**
  String get sendVerificationCode;

  /// No description provided for @useEmailCompatibility.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser mon e-mail à la place'**
  String get useEmailCompatibility;

  /// No description provided for @phoneCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez les 6 chiffres.'**
  String get phoneCodeTitle;

  /// No description provided for @phoneCodeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Le code a été envoyé au {phone}.'**
  String phoneCodeSubtitle(String phone);

  /// No description provided for @verificationCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code de vérification'**
  String get verificationCodeLabel;

  /// No description provided for @verificationCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'000000'**
  String get verificationCodeHint;

  /// No description provided for @verifyCode.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier le code'**
  String get verifyCode;

  /// No description provided for @changePhoneNumber.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le numéro'**
  String get changePhoneNumber;

  /// No description provided for @resendCode.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get resendCode;

  /// No description provided for @resendCodeIn.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer dans {seconds} s'**
  String resendCodeIn(int seconds);

  /// No description provided for @smsAutoRetrievalTimeout.
  ///
  /// In fr, this message translates to:
  /// **'La détection automatique est terminée. Saisissez le code reçu ou renvoyez-en un.'**
  String get smsAutoRetrievalTimeout;

  /// No description provided for @phoneVerificationSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Numéro vérifié'**
  String get phoneVerificationSuccess;

  /// No description provided for @phoneVerificationSuccessBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre accès sécurisé est prêt.'**
  String get phoneVerificationSuccessBody;

  /// No description provided for @phoneLinkSuccessBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre numéro est maintenant lié à ce même compte.'**
  String get phoneLinkSuccessBody;

  /// No description provided for @phoneErrorInvalidNumber.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un numéro mobile camerounais valide à 9 chiffres.'**
  String get phoneErrorInvalidNumber;

  /// No description provided for @phoneErrorInvalidCode.
  ///
  /// In fr, this message translates to:
  /// **'Le code saisi est incorrect ou a expiré.'**
  String get phoneErrorInvalidCode;

  /// No description provided for @phoneErrorTooManyRequests.
  ///
  /// In fr, this message translates to:
  /// **'Les demandes de code sont temporairement bloquées par Firebase. Le délai de déblocage n’est pas communiqué et peut dépasser une heure. Évite les demandes répétées. Si tu as déjà associé un e-mail à ton compte, utilise-le pour te connecter.'**
  String get phoneErrorTooManyRequests;

  /// No description provided for @phoneErrorAppVerification.
  ///
  /// In fr, this message translates to:
  /// **'Cette version de l’application n’a pas pu être vérifiée. Contacte l’assistance avec la référence ci-dessous.'**
  String get phoneErrorAppVerification;

  /// No description provided for @phoneErrorCaptcha.
  ///
  /// In fr, this message translates to:
  /// **'La vérification de sécurité n’a pas abouti. Réessaie depuis l’application.'**
  String get phoneErrorCaptcha;

  /// No description provided for @phoneRequestPause.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle demande dans {seconds} s'**
  String phoneRequestPause(int seconds);

  /// No description provided for @phoneErrorQuota.
  ///
  /// In fr, this message translates to:
  /// **'L’envoi de SMS est momentanément indisponible. Réessayez plus tard.'**
  String get phoneErrorQuota;

  /// No description provided for @phoneErrorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'La connexion est interrompue. Vérifiez Internet puis réessayez.'**
  String get phoneErrorNetwork;

  /// No description provided for @phoneErrorDisabled.
  ///
  /// In fr, this message translates to:
  /// **'La connexion par téléphone doit être activée dans Firebase Authentication.'**
  String get phoneErrorDisabled;

  /// No description provided for @phoneErrorCollision.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro est déjà lié à un autre compte. Reconnectez-vous avec ce numéro ou contactez l’assistance.'**
  String get phoneErrorCollision;

  /// No description provided for @phoneErrorRecentLogin.
  ///
  /// In fr, this message translates to:
  /// **'Reconnectez-vous avant d’ajouter ce numéro.'**
  String get phoneErrorRecentLogin;

  /// No description provided for @phoneErrorProfileMissing.
  ///
  /// In fr, this message translates to:
  /// **'Aucun profil INTELLIA237 n’est encore associé à ce numéro. Créez d’abord votre compte.'**
  String get phoneErrorProfileMissing;

  /// No description provided for @phoneErrorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'La vérification n’a pas abouti. Réessayez dans un instant.'**
  String get phoneErrorGeneric;

  /// No description provided for @schoolSearchLabel.
  ///
  /// In fr, this message translates to:
  /// **'Votre établissement'**
  String get schoolSearchLabel;

  /// No description provided for @schoolSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Commencez à écrire son nom ou sa ville'**
  String get schoolSearchHint;

  /// No description provided for @schoolSearchHelp.
  ///
  /// In fr, this message translates to:
  /// **'Les meilleurs résultats apparaissent au fil de votre saisie.'**
  String get schoolSearchHelp;

  /// No description provided for @schoolSelectedPending.
  ///
  /// In fr, this message translates to:
  /// **'Sélection enregistrée · affiliation en attente de vérification'**
  String get schoolSelectedPending;

  /// No description provided for @schoolNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Mon établissement n’apparaît pas'**
  String get schoolNotFound;

  /// No description provided for @schoolSuggestionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Proposer un établissement'**
  String get schoolSuggestionTitle;

  /// No description provided for @schoolSuggestionBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette proposition sera examinée. Elle ne crée jamais une affiliation vérifiée.'**
  String get schoolSuggestionBody;

  /// No description provided for @schoolNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’établissement'**
  String get schoolNameLabel;

  /// No description provided for @schoolCityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get schoolCityLabel;

  /// No description provided for @schoolRegionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Région'**
  String get schoolRegionLabel;

  /// No description provided for @schoolSuggestionSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la proposition'**
  String get schoolSuggestionSubmit;

  /// No description provided for @schoolSuggestionSaved.
  ///
  /// In fr, this message translates to:
  /// **'Proposition enregistrée · vérification en attente'**
  String get schoolSuggestionSaved;

  /// No description provided for @schoolSuggestionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez le nom, la ville et la région.'**
  String get schoolSuggestionRequired;

  /// No description provided for @schoolTypeLycee.
  ///
  /// In fr, this message translates to:
  /// **'Lycée'**
  String get schoolTypeLycee;

  /// No description provided for @schoolTypeCollege.
  ///
  /// In fr, this message translates to:
  /// **'Collège'**
  String get schoolTypeCollege;

  /// No description provided for @schoolTypeTechnical.
  ///
  /// In fr, this message translates to:
  /// **'Technique'**
  String get schoolTypeTechnical;

  /// No description provided for @schoolTypeGovernment.
  ///
  /// In fr, this message translates to:
  /// **'Public'**
  String get schoolTypeGovernment;

  /// No description provided for @schoolTypePrivate.
  ///
  /// In fr, this message translates to:
  /// **'Privé'**
  String get schoolTypePrivate;

  /// No description provided for @schoolSubsystemFrancophone.
  ///
  /// In fr, this message translates to:
  /// **'Francophone'**
  String get schoolSubsystemFrancophone;

  /// No description provided for @schoolSubsystemAnglophone.
  ///
  /// In fr, this message translates to:
  /// **'Anglophone'**
  String get schoolSubsystemAnglophone;

  /// No description provided for @schoolSubsystemBilingual.
  ///
  /// In fr, this message translates to:
  /// **'Bilingue'**
  String get schoolSubsystemBilingual;

  /// No description provided for @selectedCompanionEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'TON COMPAGNON'**
  String get selectedCompanionEyebrow;

  /// No description provided for @changeCompanion.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mon compagnon'**
  String get changeCompanion;

  /// No description provided for @leoProfileTagline.
  ///
  /// In fr, this message translates to:
  /// **'Sciences · méthode · raisonnement'**
  String get leoProfileTagline;

  /// No description provided for @kiraProfileTagline.
  ///
  /// In fr, this message translates to:
  /// **'Clarté · confiance · progression'**
  String get kiraProfileTagline;

  /// No description provided for @stepIdentity.
  ///
  /// In fr, this message translates to:
  /// **'Identité'**
  String get stepIdentity;

  /// No description provided for @stepClass.
  ///
  /// In fr, this message translates to:
  /// **'Classe'**
  String get stepClass;

  /// No description provided for @stepCompanion.
  ///
  /// In fr, this message translates to:
  /// **'Compagnon'**
  String get stepCompanion;

  /// No description provided for @stepSecurity.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get stepSecurity;

  /// No description provided for @studentSpaceEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'Espace élève'**
  String get studentSpaceEyebrow;

  /// No description provided for @studentRegistrationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Crée ton parcours\nIntellia 237.'**
  String get studentRegistrationTitle;

  /// No description provided for @studentRegistrationSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Quatre étapes rapides pour préparer ton espace personnel.'**
  String get studentRegistrationSubtitle;

  /// No description provided for @firstNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get firstNameLabel;

  /// No description provided for @firstNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Marie'**
  String get firstNameHint;

  /// No description provided for @lastNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get lastNameLabel;

  /// No description provided for @lastNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Ndi'**
  String get lastNameHint;

  /// No description provided for @seriesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Série'**
  String get seriesLabel;

  /// No description provided for @meetCompanionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rencontre ton compagnon'**
  String get meetCompanionTitle;

  /// No description provided for @meetCompanionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Découvre Kira, puis Léo. Tu choisiras une fois que tu les auras vus.'**
  String get meetCompanionSubtitle;

  /// No description provided for @secureAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurise ton compte'**
  String get secureAccountTitle;

  /// No description provided for @secureAccountPhoneVerified.
  ///
  /// In fr, this message translates to:
  /// **'Ton numéro a été vérifié. Relis tes choix avant de créer ton espace.'**
  String get secureAccountPhoneVerified;

  /// No description provided for @phoneVerifiedNoExtraCredential.
  ///
  /// In fr, this message translates to:
  /// **'Votre numéro a été vérifié. Aucun e-mail ni mot de passe supplémentaire n’est nécessaire.'**
  String get phoneVerifiedNoExtraCredential;

  /// No description provided for @classToConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Classe à confirmer'**
  String get classToConfirm;

  /// No description provided for @acceptTerms.
  ///
  /// In fr, this message translates to:
  /// **'J’accepte les conditions d’utilisation.'**
  String get acceptTerms;

  /// No description provided for @acceptPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'J’accepte la politique de confidentialité.'**
  String get acceptPrivacy;

  /// No description provided for @acceptLearningData.
  ///
  /// In fr, this message translates to:
  /// **'J’accepte le traitement pédagogique des données.'**
  String get acceptLearningData;

  /// No description provided for @parentRegistrationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte Parent'**
  String get parentRegistrationTitle;

  /// No description provided for @parentStepIdentity.
  ///
  /// In fr, this message translates to:
  /// **'Identité parent'**
  String get parentStepIdentity;

  /// No description provided for @parentStepChildren.
  ///
  /// In fr, this message translates to:
  /// **'Liaison enfants'**
  String get parentStepChildren;

  /// No description provided for @parentStepFinal.
  ///
  /// In fr, this message translates to:
  /// **'Validation finale'**
  String get parentStepFinal;

  /// No description provided for @parentDetailsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées du parent'**
  String get parentDetailsTitle;

  /// No description provided for @parentDetailsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelques informations suffisent pour préparer le parcours de votre enfant.'**
  String get parentDetailsSubtitle;

  /// No description provided for @linkChildrenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lier vos enfants'**
  String get linkChildrenTitle;

  /// No description provided for @linkChildrenSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez un identifiant élève maintenant, ou plus tard.'**
  String get linkChildrenSubtitle;

  /// No description provided for @childIdentifierLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code / Identifiant enfant'**
  String get childIdentifierLabel;

  /// No description provided for @childIdentifierHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. STU-94K2'**
  String get childIdentifierHint;

  /// No description provided for @addLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get addLabel;

  /// No description provided for @noLinkedChild.
  ///
  /// In fr, this message translates to:
  /// **'Aucun enfant lié pour le moment.'**
  String get noLinkedChild;

  /// No description provided for @finalReviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Validation finale'**
  String get finalReviewTitle;

  /// No description provided for @finalReviewSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Relisez vos informations et acceptez les consentements requis.'**
  String get finalReviewSubtitle;

  /// No description provided for @parentChildrenLater.
  ///
  /// In fr, this message translates to:
  /// **'Vous pourrez également lier ou modifier vos enfants après la création de votre compte.'**
  String get parentChildrenLater;

  /// No description provided for @previousLabel.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get previousLabel;

  /// No description provided for @nextLabel.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get nextLabel;

  /// No description provided for @createParentAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte parent'**
  String get createParentAccount;

  /// No description provided for @retryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retryLabel;

  /// No description provided for @cancelLabel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancelLabel;

  /// No description provided for @confirmLabel.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get confirmLabel;

  /// No description provided for @refreshLabel.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refreshLabel;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @readingComfortSection.
  ///
  /// In fr, this message translates to:
  /// **'Confort de lecture'**
  String get readingComfortSection;

  /// No description provided for @textSizeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Taille du texte'**
  String get textSizeLabel;

  /// No description provided for @reduceMotionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Réduire les animations'**
  String get reduceMotionLabel;

  /// No description provided for @reduceMotionDescription.
  ///
  /// In fr, this message translates to:
  /// **'Remplace les mouvements décoratifs par des transitions sobres.'**
  String get reduceMotionDescription;

  /// No description provided for @dataRemindersSection.
  ///
  /// In fr, this message translates to:
  /// **'Données et rappels'**
  String get dataRemindersSection;

  /// No description provided for @weeklyGoalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon objectif de la semaine'**
  String get weeklyGoalTitle;

  /// No description provided for @weeklyGoalUnset.
  ///
  /// In fr, this message translates to:
  /// **'Non défini — choisis ton rythme.'**
  String get weeklyGoalUnset;

  /// No description provided for @weeklyGoalSummary.
  ///
  /// In fr, this message translates to:
  /// **'{sessions} séances par semaine · ~{minutes} min'**
  String weeklyGoalSummary(int sessions, int minutes);

  /// No description provided for @dataSaverLabel.
  ///
  /// In fr, this message translates to:
  /// **'Économie de données'**
  String get dataSaverLabel;

  /// No description provided for @dataSaverDescription.
  ///
  /// In fr, this message translates to:
  /// **'Privilégie les contenus légers et limite les effets coûteux.'**
  String get dataSaverDescription;

  /// No description provided for @learningRemindersLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rappels d’apprentissage'**
  String get learningRemindersLabel;

  /// No description provided for @learningRemindersDescription.
  ///
  /// In fr, this message translates to:
  /// **'Un rappel au maximum par jour, activé seulement après ton autorisation système.'**
  String get learningRemindersDescription;

  /// No description provided for @reminderTimeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Heure du rappel'**
  String get reminderTimeLabel;

  /// No description provided for @anonymousDiagnosticsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostics anonymes'**
  String get anonymousDiagnosticsLabel;

  /// No description provided for @anonymousDiagnosticsDescription.
  ///
  /// In fr, this message translates to:
  /// **'Aide à repérer les pannes et parcours bloqués. Aucun message au compagnon, réponse libre, nom ou e-mail n’est collecté.'**
  String get anonymousDiagnosticsDescription;

  /// No description provided for @privacySection.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get privacySection;

  /// No description provided for @personalDataTitle.
  ///
  /// In fr, this message translates to:
  /// **'Données personnelles'**
  String get personalDataTitle;

  /// No description provided for @personalDataDescription.
  ///
  /// In fr, this message translates to:
  /// **'Intellia237 ne doit jamais envoyer les conversations pédagogiques dans les outils de mesure.'**
  String get personalDataDescription;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Suppression du compte'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountDescription.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer une demande de suppression sécurisée.'**
  String get deleteAccountDescription;

  /// No description provided for @accountSection.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get accountSection;

  /// No description provided for @addPhoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter ou sécuriser mon numéro'**
  String get addPhoneTitle;

  /// No description provided for @addPhoneDescription.
  ///
  /// In fr, this message translates to:
  /// **'Lie un numéro +237 sans changer ce compte ni son profil.'**
  String get addPhoneDescription;

  /// No description provided for @editProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mon profil'**
  String get editProfileTitle;

  /// No description provided for @editProfileDescription.
  ///
  /// In fr, this message translates to:
  /// **'Nom, téléphone et photo de profil.'**
  String get editProfileDescription;

  /// No description provided for @signOutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get signOutTitle;

  /// No description provided for @signOutDescription.
  ///
  /// In fr, this message translates to:
  /// **'Tes données synchronisées seront disponibles à ta prochaine connexion.'**
  String get signOutDescription;

  /// No description provided for @deleteRequestQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Demander la suppression ?'**
  String get deleteRequestQuestion;

  /// No description provided for @deleteRequestBody.
  ///
  /// In fr, this message translates to:
  /// **'Le compte et ses données seront supprimés dans 7 jours. D’ici là, le compte reste utilisable et la demande peut être annulée depuis cet écran.'**
  String get deleteRequestBody;

  /// No description provided for @sendRequestLabel.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la demande'**
  String get sendRequestLabel;

  /// No description provided for @deleteRequestError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’envoyer la demande maintenant. Réessaie plus tard.'**
  String get deleteRequestError;

  /// No description provided for @deleteScheduledSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Suppression prévue le {date}. Touchez pour annuler.'**
  String deleteScheduledSubtitle(String date);

  /// No description provided for @deleteScheduledConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Suppression programmée le {date}. Elle peut être annulée d’ici là.'**
  String deleteScheduledConfirmation(String date);

  /// No description provided for @deleteInProgressSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Suppression en cours de traitement.'**
  String get deleteInProgressSubtitle;

  /// No description provided for @cancelDeletionQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la suppression ?'**
  String get cancelDeletionQuestion;

  /// No description provided for @cancelDeletionBody.
  ///
  /// In fr, this message translates to:
  /// **'Le compte sera conservé et la demande abandonnée.'**
  String get cancelDeletionBody;

  /// No description provided for @cancelDeletionAction.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la suppression'**
  String get cancelDeletionAction;

  /// No description provided for @cancelDeletionDone.
  ///
  /// In fr, this message translates to:
  /// **'La suppression est annulée.'**
  String get cancelDeletionDone;

  /// No description provided for @cancelDeletionError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’annuler la demande maintenant. Réessayez plus tard.'**
  String get cancelDeletionError;

  /// No description provided for @chooseReminderTime.
  ///
  /// In fr, this message translates to:
  /// **'Choisir l’heure du rappel'**
  String get chooseReminderTime;

  /// No description provided for @signOutQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter ?'**
  String get signOutQuestion;

  /// No description provided for @emailVerificationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification de l’adresse e-mail'**
  String get emailVerificationTitle;

  /// No description provided for @statusUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Statut momentanément indisponible.'**
  String get statusUnavailable;

  /// No description provided for @emailVerifiedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail vérifiée'**
  String get emailVerifiedTitle;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie ton e-mail'**
  String get verifyEmailTitle;

  /// No description provided for @emailRecoveryDescription.
  ///
  /// In fr, this message translates to:
  /// **'Protège ton compte et facilite sa récupération.'**
  String get emailRecoveryDescription;

  /// No description provided for @resendLabel.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer'**
  String get resendLabel;

  /// No description provided for @emailVerificationSent.
  ///
  /// In fr, this message translates to:
  /// **'E-mail envoyé. Ouvre le lien reçu puis actualise ce statut.'**
  String get emailVerificationSent;

  /// No description provided for @accountReadyWithCompanion.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte est prêt. {name} t’accompagne dès maintenant.'**
  String accountReadyWithCompanion(String name);

  /// No description provided for @discoverIntellia.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir Intellia 237'**
  String get discoverIntellia;

  /// No description provided for @learnTitle.
  ///
  /// In fr, this message translates to:
  /// **'Apprendre'**
  String get learnTitle;

  /// No description provided for @learnEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'Explorer · comprendre · progresser'**
  String get learnEyebrow;

  /// No description provided for @learnUnavailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tes matières ne sont pas disponibles pour le moment'**
  String get learnUnavailableTitle;

  /// No description provided for @learnUnavailableBody.
  ///
  /// In fr, this message translates to:
  /// **'Réessaie dans quelques instants.'**
  String get learnUnavailableBody;

  /// No description provided for @learnUnavailableOfflineBody.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie ta connexion, puis réessaie. Ton parcours reste disponible.'**
  String get learnUnavailableOfflineBody;

  /// No description provided for @learnSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Tes matières, adaptées à ton niveau.'**
  String get learnSubtitle;

  /// No description provided for @subjectsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les matières'**
  String get subjectsLoadError;

  /// No description provided for @subjectsComingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tes matières arrivent'**
  String get subjectsComingTitle;

  /// No description provided for @subjectsComingBody.
  ///
  /// In fr, this message translates to:
  /// **'Les cours de ta classe sont en cours de préparation. Tu seras parmi les premiers à en profiter.'**
  String get subjectsComingBody;

  /// No description provided for @noSubjectFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune matière trouvée'**
  String get noSubjectFound;

  /// No description provided for @tryAnotherKeyword.
  ///
  /// In fr, this message translates to:
  /// **'Essaie un autre mot-clé.'**
  String get tryAnotherKeyword;

  /// No description provided for @clearSearch.
  ///
  /// In fr, this message translates to:
  /// **'Effacer la recherche'**
  String get clearSearch;

  /// No description provided for @personalizedPath.
  ///
  /// In fr, this message translates to:
  /// **'Parcours personnalisé'**
  String get personalizedPath;

  /// No description provided for @levelAdaptedContent.
  ///
  /// In fr, this message translates to:
  /// **'Contenus adaptés à ton niveau actuel.'**
  String get levelAdaptedContent;

  /// No description provided for @searchSubjectHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une matière…'**
  String get searchSubjectHint;

  /// No description provided for @subjectGenericTitle.
  ///
  /// In fr, this message translates to:
  /// **'Matière'**
  String get subjectGenericTitle;

  /// No description provided for @subjectUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Matière indisponible'**
  String get subjectUnavailable;

  /// No description provided for @chaptersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Chapitres'**
  String get chaptersTitle;

  /// No description provided for @chaptersComingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Chapitres en préparation'**
  String get chaptersComingTitle;

  /// No description provided for @chaptersComingBody.
  ///
  /// In fr, this message translates to:
  /// **'Le contenu de cette matière est en cours de rédaction pour ta classe. Reviens bientôt !'**
  String get chaptersComingBody;

  /// No description provided for @lessonCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune leçon} =1{1 leçon} other{{count} leçons}}'**
  String lessonCount(int count);

  /// No description provided for @lessonsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Leçons'**
  String get lessonsTitle;

  /// No description provided for @lessonsComingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Leçons en préparation'**
  String get lessonsComingTitle;

  /// No description provided for @lessonsComingBody.
  ///
  /// In fr, this message translates to:
  /// **'Les leçons de ce chapitre sont en cours de rédaction. Reviens bientôt.'**
  String get lessonsComingBody;

  /// No description provided for @chapterSavedOffline.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre enregistré pour la lecture hors connexion'**
  String get chapterSavedOffline;

  /// No description provided for @availableOffline.
  ///
  /// In fr, this message translates to:
  /// **'Disponible hors connexion'**
  String get availableOffline;

  /// No description provided for @studyOffline.
  ///
  /// In fr, this message translates to:
  /// **'Étudier sans réseau'**
  String get studyOffline;

  /// No description provided for @offlineLessonPrepared.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune leçon préparée sur cet appareil.} =1{1 leçon préparée sur cet appareil.} other{{count} leçons préparées sur cet appareil.}}'**
  String offlineLessonPrepared(int count);

  /// No description provided for @prepareOfflineLessons.
  ///
  /// In fr, this message translates to:
  /// **'Prépare toutes les leçons pour une lecture hors connexion.'**
  String get prepareOfflineLessons;

  /// No description provided for @chapterReadyOffline.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre prêt pour une lecture hors connexion.'**
  String get chapterReadyOffline;

  /// No description provided for @downloadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le téléchargement n’a pas abouti. Vérifie la connexion et réessaie.'**
  String get downloadFailed;

  /// No description provided for @nextLabelShort.
  ///
  /// In fr, this message translates to:
  /// **'À suivre'**
  String get nextLabelShort;

  /// No description provided for @lessonUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Leçon indisponible'**
  String get lessonUnavailable;

  /// No description provided for @localProgressSaved.
  ///
  /// In fr, this message translates to:
  /// **'Progression conservée sur cet appareil. Elle sera synchronisée automatiquement.'**
  String get localProgressSaved;

  /// No description provided for @markLessonComplete.
  ///
  /// In fr, this message translates to:
  /// **'Marquer la leçon comme terminée'**
  String get markLessonComplete;

  /// No description provided for @markComplete.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme terminée'**
  String get markComplete;

  /// No description provided for @completedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Terminée'**
  String get completedLabel;

  /// No description provided for @askTutorAboutLesson.
  ///
  /// In fr, this message translates to:
  /// **'Demander de l’aide à {name} sur cette leçon'**
  String askTutorAboutLesson(String name);

  /// No description provided for @askTutorPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Une question ? Demande à {name}'**
  String askTutorPrompt(String name);

  /// No description provided for @checkUnderstanding.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie ta compréhension'**
  String get checkUnderstanding;

  /// No description provided for @lessonCompletedCongrats.
  ///
  /// In fr, this message translates to:
  /// **'Leçon terminée, bravo !'**
  String get lessonCompletedCongrats;

  /// No description provided for @startNextLesson.
  ///
  /// In fr, this message translates to:
  /// **'Commencer la leçon suivante'**
  String get startNextLesson;

  /// No description provided for @nextLesson.
  ///
  /// In fr, this message translates to:
  /// **'Leçon suivante'**
  String get nextLesson;

  /// No description provided for @writeQuestionHint.
  ///
  /// In fr, this message translates to:
  /// **'Écris ta question…'**
  String get writeQuestionHint;

  /// No description provided for @stepProgressA11y.
  ///
  /// In fr, this message translates to:
  /// **'Étape {current} sur {total}: {label}'**
  String stepProgressA11y(int current, int total, String label);

  /// No description provided for @networkOfflineBanner.
  ///
  /// In fr, this message translates to:
  /// **'Aucun réseau détecté — les contenus déjà chargés restent accessibles.'**
  String get networkOfflineBanner;

  /// No description provided for @welcomeName.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue, {name} !'**
  String welcomeName(String name);

  /// No description provided for @closeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get closeLabel;

  /// No description provided for @companionPromptExplain.
  ///
  /// In fr, this message translates to:
  /// **'Explique ce concept'**
  String get companionPromptExplain;

  /// No description provided for @companionPromptSummarize.
  ///
  /// In fr, this message translates to:
  /// **'Résume en points clés'**
  String get companionPromptSummarize;

  /// No description provided for @companionPromptExample.
  ///
  /// In fr, this message translates to:
  /// **'Donne un exemple concret'**
  String get companionPromptExample;

  /// No description provided for @companionPromptQuestions.
  ///
  /// In fr, this message translates to:
  /// **'Pose-moi 3 questions'**
  String get companionPromptQuestions;

  /// No description provided for @companionContext.
  ///
  /// In fr, this message translates to:
  /// **'Contexte : {topic}'**
  String companionContext(String topic);

  /// No description provided for @chapterLabel.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre'**
  String get chapterLabel;

  /// No description provided for @chapterUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre indisponible'**
  String get chapterUnavailable;

  /// No description provided for @chapterEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'CHAPITRE'**
  String get chapterEyebrow;

  /// No description provided for @completedProgress.
  ///
  /// In fr, this message translates to:
  /// **'{done}/{total} terminées'**
  String completedProgress(int done, int total);

  /// No description provided for @saveChapterOffline.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer ce chapitre pour la lecture hors connexion'**
  String get saveChapterOffline;

  /// No description provided for @reconnectToPrepareLessons.
  ///
  /// In fr, this message translates to:
  /// **'Reconnecte-toi pour préparer toutes les leçons.'**
  String get reconnectToPrepareLessons;

  /// No description provided for @prepareChapterLessons.
  ///
  /// In fr, this message translates to:
  /// **'Prépare les {count} leçons de ce chapitre.'**
  String prepareChapterLessons(int count);

  /// No description provided for @prepareLabel.
  ///
  /// In fr, this message translates to:
  /// **'Préparer'**
  String get prepareLabel;

  /// No description provided for @backLabel.
  ///
  /// In fr, this message translates to:
  /// **'Revenir en arrière'**
  String get backLabel;

  /// No description provided for @backToChapter.
  ///
  /// In fr, this message translates to:
  /// **'Retour au chapitre'**
  String get backToChapter;

  /// No description provided for @lastLessonCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Tu as terminé la dernière leçon de ce chapitre.'**
  String get lastLessonCompleted;

  /// No description provided for @nextStepLesson.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine étape : « {title} ».'**
  String nextStepLesson(String title);

  /// No description provided for @phoneProfileChoicePrompt.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro n’a pas encore de profil. Choisis le compte à créer :'**
  String get phoneProfileChoicePrompt;

  /// No description provided for @phoneCreateStudentProfile.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon profil élève'**
  String get phoneCreateStudentProfile;

  /// No description provided for @phoneCreateParentProfile.
  ///
  /// In fr, this message translates to:
  /// **'Créer un profil parent'**
  String get phoneCreateParentProfile;

  /// No description provided for @authProfileSetupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Configuration du compte'**
  String get authProfileSetupTitle;

  /// No description provided for @authCompleteProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Complète ton profil'**
  String get authCompleteProfileTitle;

  /// No description provided for @authSessionActiveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ta session est toujours active'**
  String get authSessionActiveTitle;

  /// No description provided for @authChooseProfileBody.
  ///
  /// In fr, this message translates to:
  /// **'Choisis le profil à créer. Ta session Firebase vérifiée sera réutilisée.'**
  String get authChooseProfileBody;

  /// No description provided for @authProfileSyncFailureBody.
  ///
  /// In fr, this message translates to:
  /// **'Le profil n’a pas pu être synchronisé. Aucune déconnexion automatique n’a été effectuée.'**
  String get authProfileSyncFailureBody;

  /// No description provided for @chooseRolePrompt.
  ///
  /// In fr, this message translates to:
  /// **'Je suis…'**
  String get chooseRolePrompt;

  /// No description provided for @adminRole.
  ///
  /// In fr, this message translates to:
  /// **'Administration'**
  String get adminRole;

  /// No description provided for @notificationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationMarkAllRead.
  ///
  /// In fr, this message translates to:
  /// **'Tout lire'**
  String get notificationMarkAllRead;

  /// No description provided for @notificationsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Notifications indisponibles'**
  String get notificationsUnavailable;

  /// No description provided for @notificationsSyncError.
  ///
  /// In fr, this message translates to:
  /// **'La boîte de réception n’a pas pu être synchronisée. Vérifie la connexion puis réessaie.'**
  String get notificationsSyncError;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tout est calme'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Les rappels de cours, nouveautés et messages importants apparaîtront ici.'**
  String get notificationsEmptyBody;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Permission refusée. La boîte de réception reste disponible ici.'**
  String get notificationPermissionDenied;

  /// No description provided for @notificationEnableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ne manque aucune nouveauté'**
  String get notificationEnableTitle;

  /// No description provided for @notificationEnableBody.
  ///
  /// In fr, this message translates to:
  /// **'Active les alertes système. Tous les messages restent aussi conservés dans cette boîte de réception.'**
  String get notificationEnableBody;

  /// No description provided for @notificationEnableAction.
  ///
  /// In fr, this message translates to:
  /// **'Activer les alertes'**
  String get notificationEnableAction;

  /// No description provided for @profileUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Profil indisponible'**
  String get profileUnavailable;

  /// No description provided for @profileUnavailableBody.
  ///
  /// In fr, this message translates to:
  /// **'Le profil n’a pas pu être chargé. Vérifie la connexion puis réessaie.'**
  String get profileUnavailableBody;

  /// No description provided for @loginEmailImmutable.
  ///
  /// In fr, this message translates to:
  /// **'L’adresse de connexion ne se modifie pas ici.'**
  String get loginEmailImmutable;

  /// No description provided for @phoneOptionalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone (facultatif)'**
  String get phoneOptionalLabel;

  /// No description provided for @invalidCameroonPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro camerounais invalide.'**
  String get invalidCameroonPhone;

  /// No description provided for @savingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement…'**
  String get savingLabel;

  /// No description provided for @saveLabel.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get saveLabel;

  /// No description provided for @profileRestrictedFields.
  ///
  /// In fr, this message translates to:
  /// **'La classe, le rôle et l’établissement ne peuvent être modifiés que par un responsable autorisé.'**
  String get profileRestrictedFields;

  /// No description provided for @profileNameLengthError.
  ///
  /// In fr, this message translates to:
  /// **'Le champ {label} doit contenir entre 2 et 60 caractères.'**
  String profileNameLengthError(String label);

  /// No description provided for @profileUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour.'**
  String get profileUpdated;

  /// No description provided for @kiraDiscoveryPhraseOne.
  ///
  /// In fr, this message translates to:
  /// **'Elle prend le temps de t’expliquer.'**
  String get kiraDiscoveryPhraseOne;

  /// No description provided for @kiraDiscoveryPhraseTwo.
  ///
  /// In fr, this message translates to:
  /// **'Elle avance avec méthode et douceur.'**
  String get kiraDiscoveryPhraseTwo;

  /// No description provided for @kiraDiscoveryPhraseThree.
  ///
  /// In fr, this message translates to:
  /// **'Elle t’aide à comprendre sans pression.'**
  String get kiraDiscoveryPhraseThree;

  /// No description provided for @leoDiscoveryPhraseOne.
  ///
  /// In fr, this message translates to:
  /// **'Il transforme chaque notion en défi.'**
  String get leoDiscoveryPhraseOne;

  /// No description provided for @leoDiscoveryPhraseTwo.
  ///
  /// In fr, this message translates to:
  /// **'Il te pousse à aller un peu plus loin.'**
  String get leoDiscoveryPhraseTwo;

  /// No description provided for @leoDiscoveryPhraseThree.
  ///
  /// In fr, this message translates to:
  /// **'Il célèbre chaque progrès avec toi.'**
  String get leoDiscoveryPhraseThree;

  /// No description provided for @discoverLeo.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir Léo'**
  String get discoverLeo;

  /// No description provided for @returnToKira.
  ///
  /// In fr, this message translates to:
  /// **'Revenir vers Kira'**
  String get returnToKira;

  /// No description provided for @discoverCompanionBeforeChoice.
  ///
  /// In fr, this message translates to:
  /// **'Découvre {name} pour pouvoir le choisir'**
  String discoverCompanionBeforeChoice(String name);

  /// No description provided for @companionChosenA11y.
  ///
  /// In fr, this message translates to:
  /// **'{name} choisi'**
  String companionChosenA11y(String name);

  /// No description provided for @chooseCompanionA11y.
  ///
  /// In fr, this message translates to:
  /// **'Choisir {name}'**
  String chooseCompanionA11y(String name);

  /// No description provided for @currentCompanionLabel.
  ///
  /// In fr, this message translates to:
  /// **'{name}, ton compagnon'**
  String currentCompanionLabel(String name);

  /// No description provided for @subjectMathematics.
  ///
  /// In fr, this message translates to:
  /// **'Mathématiques'**
  String get subjectMathematics;

  /// No description provided for @subjectFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get subjectFrench;

  /// No description provided for @subjectGeography.
  ///
  /// In fr, this message translates to:
  /// **'Géographie'**
  String get subjectGeography;

  /// No description provided for @classPremiereDisplay.
  ///
  /// In fr, this message translates to:
  /// **'Première'**
  String get classPremiereDisplay;

  /// No description provided for @stateLoadingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get stateLoadingTitle;

  /// No description provided for @stateEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rien ici pour le moment'**
  String get stateEmptyTitle;

  /// No description provided for @stateNoResultsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get stateNoResultsTitle;

  /// No description provided for @stateComingSoonTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contenu bientôt disponible'**
  String get stateComingSoonTitle;

  /// No description provided for @stateRetryableErrorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Un problème est survenu'**
  String get stateRetryableErrorTitle;

  /// No description provided for @stateFatalErrorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur inattendue est survenue'**
  String get stateFatalErrorTitle;

  /// No description provided for @stateOfflineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tu es hors ligne'**
  String get stateOfflineTitle;

  /// No description provided for @stateAccessDeniedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Accès non autorisé'**
  String get stateAccessDeniedTitle;

  /// No description provided for @stateLockedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contenu verrouillé'**
  String get stateLockedTitle;

  /// No description provided for @stateSuccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'C’est fait !'**
  String get stateSuccessTitle;

  /// No description provided for @stateOfflineBody.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie ta connexion puis réessaie. Tes contenus déjà consultés restent disponibles.'**
  String get stateOfflineBody;

  /// No description provided for @stateAccessDeniedBody.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte n’a pas accès à ce contenu. Reconnecte-toi ou contacte ton établissement.'**
  String get stateAccessDeniedBody;

  /// No description provided for @stateRetryableErrorBody.
  ///
  /// In fr, this message translates to:
  /// **'Ce n’est pas de ton côté. Réessaie dans un instant.'**
  String get stateRetryableErrorBody;

  /// No description provided for @completionPercent.
  ///
  /// In fr, this message translates to:
  /// **'{percent} % terminé'**
  String completionPercent(int percent);

  /// No description provided for @nextUpA11y.
  ///
  /// In fr, this message translates to:
  /// **', à suivre'**
  String get nextUpA11y;

  /// No description provided for @lessonTileA11y.
  ///
  /// In fr, this message translates to:
  /// **'Leçon {index} : {title}, {status}{next}'**
  String lessonTileA11y(int index, String title, String status, String next);

  /// No description provided for @subjectTileA11y.
  ///
  /// In fr, this message translates to:
  /// **'{title}, {percent} % terminé, {lessons}'**
  String subjectTileA11y(String title, int percent, String lessons);

  /// No description provided for @lessonProgressQueuedOffline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne : ta progression sera validée après la reconnexion.'**
  String get lessonProgressQueuedOffline;

  /// No description provided for @lessonProgressSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’enregistrer pour le moment. Réessaie dans un instant.'**
  String get lessonProgressSaveFailed;

  /// No description provided for @removeFromFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des favoris'**
  String get removeFromFavorites;

  /// No description provided for @addToFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter aux favoris'**
  String get addToFavorites;

  /// No description provided for @lessonReadingMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Moins d’une minute de lecture} =1{1 min de lecture} other{{count} min de lecture}}'**
  String lessonReadingMinutes(int count);

  /// No description provided for @miniQuizScoreSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Score : {score}/{total} — bien joué !'**
  String miniQuizScoreSuccess(int score, int total);

  /// No description provided for @miniQuizScoreReview.
  ///
  /// In fr, this message translates to:
  /// **'Score : {score}/{total} — relis la leçon et réessaie.'**
  String miniQuizScoreReview(int score, int total);

  /// No description provided for @submitMiniQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Valider le mini quiz'**
  String get submitMiniQuiz;

  /// No description provided for @answerAllBeforeSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Réponds à toutes les questions pour valider'**
  String get answerAllBeforeSubmit;

  /// No description provided for @answerAllQuestions.
  ///
  /// In fr, this message translates to:
  /// **'Réponds à toutes les questions'**
  String get answerAllQuestions;

  /// No description provided for @correctAnswerA11y.
  ///
  /// In fr, this message translates to:
  /// **'Bonne réponse : {answer}'**
  String correctAnswerA11y(String answer);

  /// No description provided for @incorrectAnswerA11y.
  ///
  /// In fr, this message translates to:
  /// **'Ta réponse est incorrecte : {answer}'**
  String incorrectAnswerA11y(String answer);

  /// No description provided for @quizProfileIncompleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Ton profil scolaire doit être complété ou resynchronisé avant de choisir les quiz de ton niveau.'**
  String get quizProfileIncompleteBody;

  /// No description provided for @quizCatalogDeniedBody.
  ///
  /// In fr, this message translates to:
  /// **'Tes quiz ne sont pas encore ouverts pour ton profil. Tu peux continuer avec tes cours en attendant.'**
  String get quizCatalogDeniedBody;

  /// No description provided for @quizCatalogUnavailableBody.
  ///
  /// In fr, this message translates to:
  /// **'Tes quiz sont momentanément inaccessibles. Continue ton parcours ou tes cours en attendant.'**
  String get quizCatalogUnavailableBody;

  /// No description provided for @quizCatalogInvalidBody.
  ///
  /// In fr, this message translates to:
  /// **'Certains quiz ne sont pas encore prêts. Tu peux continuer ton parcours et revenir t’entraîner dans quelques instants.'**
  String get quizCatalogInvalidBody;

  /// No description provided for @quizCatalogNetworkBody.
  ///
  /// In fr, this message translates to:
  /// **'La connexion est interrompue. Tes cours et ton parcours restent disponibles.'**
  String get quizCatalogNetworkBody;

  /// No description provided for @quizLoadErrorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les quiz pour le moment.'**
  String get quizLoadErrorTitle;

  /// No description provided for @quizOfflineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les quiz attendent le réseau'**
  String get quizOfflineTitle;

  /// No description provided for @quizOfflineBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucun quiz n’est lancé sans connexion : le serveur protège la correction et valide l’envoi, sans conserver tes réponses hors ligne. Tu peux continuer avec ton parcours ou une leçon téléchargée.'**
  String get quizOfflineBody;

  /// No description provided for @openOfflineFlow.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir mon parcours hors ligne'**
  String get openOfflineFlow;

  /// No description provided for @viewDownloadedLessons.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes leçons téléchargées'**
  String get viewDownloadedLessons;

  /// No description provided for @allLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get allLabel;

  /// No description provided for @quizModeTraining.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement'**
  String get quizModeTraining;

  /// No description provided for @quizModeExam.
  ///
  /// In fr, this message translates to:
  /// **'Évaluation / examen blanc'**
  String get quizModeExam;

  /// No description provided for @quizModeUnspecified.
  ///
  /// In fr, this message translates to:
  /// **'Mode non précisé'**
  String get quizModeUnspecified;

  /// No description provided for @quizHubIntro.
  ///
  /// In fr, this message translates to:
  /// **'Entraîne-toi avec des corrections guidées ou évalue-toi dans les conditions d’un examen blanc.'**
  String get quizHubIntro;

  /// No description provided for @chooseRevisionMode.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton mode de révision'**
  String get chooseRevisionMode;

  /// No description provided for @quizPausedOfflineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quiz en pause hors connexion'**
  String get quizPausedOfflineTitle;

  /// No description provided for @quizPausedOfflineBody.
  ///
  /// In fr, this message translates to:
  /// **'Les corrections et l’envoi sont vérifiés par le serveur. Pour protéger l’évaluation, aucune réponse ni aucun corrigé n’est conservé hors ligne.'**
  String get quizPausedOfflineBody;

  /// No description provided for @displayLabel.
  ///
  /// In fr, this message translates to:
  /// **'Afficher'**
  String get displayLabel;

  /// No description provided for @filterQuizByModeA11y.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer les quiz par mode'**
  String get filterQuizByModeA11y;

  /// No description provided for @quizComingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les quiz de ta classe arrivent'**
  String get quizComingTitle;

  /// No description provided for @quizComingBody.
  ///
  /// In fr, this message translates to:
  /// **'De nouveaux quiz sont en préparation pour ton niveau. En attendant, révise une leçon ou lance ton parcours depuis l’accueil.'**
  String get quizComingBody;

  /// No description provided for @quizTrainingAction.
  ///
  /// In fr, this message translates to:
  /// **'S’entraîner'**
  String get quizTrainingAction;

  /// No description provided for @quizTrainingDescription.
  ///
  /// In fr, this message translates to:
  /// **'Une correction guidée t’aide à comprendre avant de continuer.'**
  String get quizTrainingDescription;

  /// No description provided for @quizExamAction.
  ///
  /// In fr, this message translates to:
  /// **'S’évaluer'**
  String get quizExamAction;

  /// No description provided for @quizExamDescription.
  ///
  /// In fr, this message translates to:
  /// **'Les réponses sont corrigées à la fin. Ces quiz préparent aux épreuves, sans remplacer un examen officiel.'**
  String get quizExamDescription;

  /// No description provided for @studentSpace.
  ///
  /// In fr, this message translates to:
  /// **'Espace élève'**
  String get studentSpace;

  /// No description provided for @quizTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quiz'**
  String get quizTitle;

  /// No description provided for @quizEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'S’entraîner · se tester'**
  String get quizEyebrow;

  /// No description provided for @quizUnavailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tes quiz ne sont pas disponibles pour le moment'**
  String get quizUnavailableTitle;

  /// No description provided for @quizUnavailableBody.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux continuer ton parcours et revenir t’entraîner dans quelques instants.'**
  String get quizUnavailableBody;

  /// No description provided for @quizUnavailableOfflineBody.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie ta connexion. Tu peux continuer ton parcours et revenir t’entraîner ensuite.'**
  String get quizUnavailableOfflineBody;

  /// No description provided for @quizUnavailableModesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Modes disponibles dès le retour de tes quiz'**
  String get quizUnavailableModesLabel;

  /// No description provided for @quizHistoryLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des tentatives validées…'**
  String get quizHistoryLoading;

  /// No description provided for @quizHistoryUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Historique indisponible pour le moment.'**
  String get quizHistoryUnavailable;

  /// No description provided for @quizNoValidatedAttempt.
  ///
  /// In fr, this message translates to:
  /// **'Aucune tentative validée pour le moment.'**
  String get quizNoValidatedAttempt;

  /// No description provided for @lastScore.
  ///
  /// In fr, this message translates to:
  /// **'Dernier score : {score}'**
  String lastScore(String score);

  /// No description provided for @myResults.
  ///
  /// In fr, this message translates to:
  /// **'Mes résultats'**
  String get myResults;

  /// No description provided for @quizResultsLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de récupérer les résultats validés. Tes quiz restent accessibles.'**
  String get quizResultsLoadFailed;

  /// No description provided for @quizFirstResultBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat inventé ici : ta première tentative apparaîtra après sa validation par le serveur.'**
  String get quizFirstResultBody;

  /// No description provided for @quizMasteryUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La maîtrise par thème n’est pas affichée : les tentatives actuelles n’enregistrent pas encore de compétences pédagogiques validées.'**
  String get quizMasteryUnavailable;

  /// No description provided for @dateUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Date non disponible'**
  String get dateUnavailable;

  /// No description provided for @pointsEarned.
  ///
  /// In fr, this message translates to:
  /// **'+{count} points'**
  String pointsEarned(int count);

  /// No description provided for @scoreUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Score non disponible'**
  String get scoreUnavailable;

  /// No description provided for @quizTrainingGuide.
  ///
  /// In fr, this message translates to:
  /// **'Correction guidée pendant le quiz.'**
  String get quizTrainingGuide;

  /// No description provided for @quizExamGuide.
  ///
  /// In fr, this message translates to:
  /// **'Correction complète après l’envoi.'**
  String get quizExamGuide;

  /// No description provided for @questionCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune question} =1{1 question} other{{count} questions}}'**
  String questionCount(int count);

  /// No description provided for @unavailableOfflineA11y.
  ///
  /// In fr, this message translates to:
  /// **' Indisponible hors connexion.'**
  String get unavailableOfflineA11y;

  /// No description provided for @quizNeedsNetworkTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ce quiz a besoin du réseau'**
  String get quizNeedsNetworkTitle;

  /// No description provided for @quizNeedsNetworkBody.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur protège la correction et valide l’envoi. Intellia237 ne met ni tes réponses ni les corrigés en cache. Reconnecte-toi pour commencer, ou poursuis une activité disponible hors ligne.'**
  String get quizNeedsNetworkBody;

  /// No description provided for @quizPlayOfflineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quiz indisponible hors connexion'**
  String get quizPlayOfflineTitle;

  /// No description provided for @quizPlayOfflineBody.
  ///
  /// In fr, this message translates to:
  /// **'Le contenu, la correction et l’envoi sont vérifiés par le serveur. Intellia237 ne conserve ni tes réponses ni les corrigés hors ligne. Reconnecte-toi, ou poursuis une activité déjà disponible sur cet appareil.'**
  String get quizPlayOfflineBody;

  /// No description provided for @quizQuestionsComingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Questions en préparation'**
  String get quizQuestionsComingTitle;

  /// No description provided for @quizQuestionsComingBody.
  ///
  /// In fr, this message translates to:
  /// **'Ce quiz est publié, mais ses questions ne sont pas encore disponibles.'**
  String get quizQuestionsComingBody;

  /// No description provided for @leaveQuizTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quitter ce quiz ?'**
  String get leaveQuizTitle;

  /// No description provided for @leaveQuizBody.
  ///
  /// In fr, this message translates to:
  /// **'Tes réponses de cette tentative seront perdues.'**
  String get leaveQuizBody;

  /// No description provided for @continueQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Continuer le quiz'**
  String get continueQuiz;

  /// No description provided for @leaveAndDiscardAnswers.
  ///
  /// In fr, this message translates to:
  /// **'Quitter et perdre mes réponses'**
  String get leaveAndDiscardAnswers;

  /// No description provided for @checkAnswerAction.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get checkAnswerAction;

  /// No description provided for @finishLabel.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get finishLabel;

  /// No description provided for @guidedCorrectionUnavailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Correction indisponible'**
  String get guidedCorrectionUnavailableTitle;

  /// No description provided for @guidedCorrectionFailureBody.
  ///
  /// In fr, this message translates to:
  /// **'{reason}\nTa réponse reste saisie sur cet écran et n’est pas mise en cache.'**
  String guidedCorrectionFailureBody(String reason);

  /// No description provided for @continueWithoutCorrection.
  ///
  /// In fr, this message translates to:
  /// **'Continuer sans correction'**
  String get continueWithoutCorrection;

  /// No description provided for @correctAnswerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bonne réponse !'**
  String get correctAnswerTitle;

  /// No description provided for @keyTakeawayTitle.
  ///
  /// In fr, this message translates to:
  /// **'À retenir'**
  String get keyTakeawayTitle;

  /// No description provided for @expectedAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Réponse attendue : {answer}'**
  String expectedAnswer(String answer);

  /// No description provided for @unansweredQuestionCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune question sans réponse} =1{1 question sans réponse} other{{count} questions sans réponse}}'**
  String unansweredQuestionCount(int count);

  /// No description provided for @incompleteQuizBody.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux revenir à la première question incomplète ou envoyer maintenant.'**
  String get incompleteQuizBody;

  /// No description provided for @completeMyAnswers.
  ///
  /// In fr, this message translates to:
  /// **'Compléter mes réponses'**
  String get completeMyAnswers;

  /// No description provided for @submitAnyway.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer quand même'**
  String get submitAnyway;

  /// No description provided for @quizSubmissionFailureBody.
  ///
  /// In fr, this message translates to:
  /// **'{reason} Tes réponses restent saisies sur cet écran : réessaie sans les ressaisir. Aucune copie hors ligne n’est créée.'**
  String quizSubmissionFailureBody(String reason);

  /// No description provided for @quizAnswerCheckNetworkError.
  ///
  /// In fr, this message translates to:
  /// **'La connexion est trop faible pour vérifier cette réponse. Réessaie quand le réseau revient.'**
  String get quizAnswerCheckNetworkError;

  /// No description provided for @quizAnswerCheckUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La correction guidée est indisponible pour le moment.'**
  String get quizAnswerCheckUnavailable;

  /// No description provided for @quizAnswerCheckFailed.
  ///
  /// In fr, this message translates to:
  /// **'Cette réponse ne peut pas être vérifiée pour le moment.'**
  String get quizAnswerCheckFailed;

  /// No description provided for @quizAnswerCheckGenericError.
  ///
  /// In fr, this message translates to:
  /// **'La correction guidée ne répond pas pour le moment. Vérifie ta connexion, puis réessaie.'**
  String get quizAnswerCheckGenericError;

  /// No description provided for @quizSubmissionNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Quiz introuvable ou indisponible.'**
  String get quizSubmissionNotFound;

  /// No description provided for @quizSubmissionPrecondition.
  ///
  /// In fr, this message translates to:
  /// **'Ce quiz ne peut pas encore être soumis.'**
  String get quizSubmissionPrecondition;

  /// No description provided for @quizSubmissionAlreadyExists.
  ///
  /// In fr, this message translates to:
  /// **'Cette tentative a déjà été utilisée.'**
  String get quizSubmissionAlreadyExists;

  /// No description provided for @quizSubmissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Tu ne peux pas soumettre ce quiz.'**
  String get quizSubmissionDenied;

  /// No description provided for @quizSubmissionInvalid.
  ///
  /// In fr, this message translates to:
  /// **'La tentative contient des réponses invalides.'**
  String get quizSubmissionInvalid;

  /// No description provided for @quizSubmissionUnauthenticated.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi pour valider le quiz.'**
  String get quizSubmissionUnauthenticated;

  /// No description provided for @quizSubmissionUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur n’a pas pu valider cette tentative pour le moment.'**
  String get quizSubmissionUnavailable;

  /// No description provided for @singleAnswerQcm.
  ///
  /// In fr, this message translates to:
  /// **'QCM — Une seule bonne réponse'**
  String get singleAnswerQcm;

  /// No description provided for @selectedA11y.
  ///
  /// In fr, this message translates to:
  /// **', sélectionnée'**
  String get selectedA11y;

  /// No description provided for @quizOptionA11y.
  ///
  /// In fr, this message translates to:
  /// **'Réponse {letter} : {answer}{selected}'**
  String quizOptionA11y(String letter, String answer, String selected);

  /// No description provided for @shortAnswerInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Réponds en quelques mots'**
  String get shortAnswerInstruction;

  /// No description provided for @yourAnswerHint.
  ///
  /// In fr, this message translates to:
  /// **'Ta réponse…'**
  String get yourAnswerHint;

  /// No description provided for @trueOrFalse.
  ///
  /// In fr, this message translates to:
  /// **'Vrai ou faux'**
  String get trueOrFalse;

  /// No description provided for @trueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Vrai'**
  String get trueLabel;

  /// No description provided for @falseLabel.
  ///
  /// In fr, this message translates to:
  /// **'Faux'**
  String get falseLabel;

  /// No description provided for @backToQuizzes.
  ///
  /// In fr, this message translates to:
  /// **'Retour aux quiz'**
  String get backToQuizzes;

  /// No description provided for @replayMyMistakes.
  ///
  /// In fr, this message translates to:
  /// **'Rejouer mes erreurs'**
  String get replayMyMistakes;

  /// No description provided for @restartQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer'**
  String get restartQuiz;

  /// No description provided for @detailedCorrection.
  ///
  /// In fr, this message translates to:
  /// **'Correction détaillée'**
  String get detailedCorrection;

  /// No description provided for @mistakeProgress.
  ///
  /// In fr, this message translates to:
  /// **'Erreur {current}/{total}'**
  String mistakeProgress(int current, int total);

  /// No description provided for @mentalAnswerInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Réponds mentalement, puis révèle la correction.'**
  String get mentalAnswerInstruction;

  /// No description provided for @revealAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Révéler la réponse'**
  String get revealAnswer;

  /// No description provided for @finishReview.
  ///
  /// In fr, this message translates to:
  /// **'Terminer la révision'**
  String get finishReview;

  /// No description provided for @nextMistake.
  ///
  /// In fr, this message translates to:
  /// **'Erreur suivante'**
  String get nextMistake;

  /// No description provided for @excellentResult.
  ///
  /// In fr, this message translates to:
  /// **'Excellent !'**
  String get excellentResult;

  /// No description provided for @wellDoneResult.
  ///
  /// In fr, this message translates to:
  /// **'Bien joué !'**
  String get wellDoneResult;

  /// No description provided for @keepGoingResult.
  ///
  /// In fr, this message translates to:
  /// **'Continue !'**
  String get keepGoingResult;

  /// No description provided for @zeroPoints.
  ///
  /// In fr, this message translates to:
  /// **'0 point'**
  String get zeroPoints;

  /// No description provided for @yourAnswerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ta réponse'**
  String get yourAnswerLabel;

  /// No description provided for @correctAnswerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Bonne réponse'**
  String get correctAnswerLabel;

  /// No description provided for @quizImprovement.
  ///
  /// In fr, this message translates to:
  /// **'+{delta} % par rapport à ta dernière tentative'**
  String quizImprovement(int delta);

  /// No description provided for @quizImprovementA11y.
  ///
  /// In fr, this message translates to:
  /// **'Score en progrès : {label}'**
  String quizImprovementA11y(String label);

  /// No description provided for @continueWithFlow.
  ///
  /// In fr, this message translates to:
  /// **'Continuer mon parcours'**
  String get continueWithFlow;

  /// No description provided for @homeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get homeLabel;

  /// No description provided for @companionNavLabel.
  ///
  /// In fr, this message translates to:
  /// **'Compagnon'**
  String get companionNavLabel;

  /// No description provided for @profileNavLabel.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profileNavLabel;

  /// No description provided for @homeLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l’accueil'**
  String get homeLoadError;

  /// No description provided for @flowSyncSignedOut.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi pour faire valider tes points du parcours.'**
  String get flowSyncSignedOut;

  /// No description provided for @flowSyncUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Tes points n’ont pas pu être validés pour le moment. Ta réponse est conservée.'**
  String get flowSyncUnavailable;

  /// No description provided for @flowSyncQueued.
  ///
  /// In fr, this message translates to:
  /// **'Réponse enregistrée hors ligne. Les points seront validés à la prochaine synchronisation.'**
  String get flowSyncQueued;

  /// No description provided for @flowSyncNotEligible.
  ///
  /// In fr, this message translates to:
  /// **'La validation des points du parcours est réservée aux profils élèves.'**
  String get flowSyncNotEligible;

  /// No description provided for @flowSyncContentNotValidated.
  ///
  /// In fr, this message translates to:
  /// **'Cette activité du parcours n’est pas encore validée par le serveur.'**
  String get flowSyncContentNotValidated;

  /// No description provided for @flowSyncDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Cette validation a déjà été utilisée pour une autre activité.'**
  String get flowSyncDuplicate;

  /// No description provided for @flowSyncInvalidAnswer.
  ///
  /// In fr, this message translates to:
  /// **'La réponse envoyée pour cette activité est invalide.'**
  String get flowSyncInvalidAnswer;

  /// No description provided for @flowSyncUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de valider les points du parcours pour le moment.'**
  String get flowSyncUnknown;

  /// No description provided for @flowDailyCapReached.
  ///
  /// In fr, this message translates to:
  /// **'Plafond quotidien atteint : reviens demain pour gagner de nouveaux points.'**
  String get flowDailyCapReached;

  /// No description provided for @companionSpeak.
  ///
  /// In fr, this message translates to:
  /// **'Parler'**
  String get companionSpeak;

  /// No description provided for @companionSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get companionSend;

  /// No description provided for @companionMicRationale.
  ///
  /// In fr, this message translates to:
  /// **'{name} a besoin du micro pour t’écouter. Rien n’est enregistré sans que tu envoies.'**
  String companionMicRationale(String name);

  /// No description provided for @companionMicDenied.
  ///
  /// In fr, this message translates to:
  /// **'Le micro est refusé. Tu peux l’autoriser dans les réglages, ou écrire ta question.'**
  String get companionMicDenied;

  /// No description provided for @companionMicUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La dictée n’est pas disponible sur cet appareil. Tu peux écrire ta question.'**
  String get companionMicUnavailable;

  /// No description provided for @companionListening.
  ///
  /// In fr, this message translates to:
  /// **'Je t’écoute'**
  String get companionListening;

  /// No description provided for @companionDictationCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get companionDictationCancel;

  /// No description provided for @companionDictationStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get companionDictationStop;

  /// No description provided for @companionDictationNearEnd.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt la fin'**
  String get companionDictationNearEnd;

  /// No description provided for @companionDictationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Je n’ai pas bien entendu. Tu peux réessayer ou écrire.'**
  String get companionDictationFailed;

  /// No description provided for @companionListen.
  ///
  /// In fr, this message translates to:
  /// **'Écouter'**
  String get companionListen;

  /// No description provided for @companionPauseListening.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get companionPauseListening;

  /// No description provided for @companionHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tes conversations'**
  String get companionHistoryTitle;

  /// No description provided for @companionHistoryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Tes conversations apparaîtront ici.'**
  String get companionHistoryEmpty;

  /// No description provided for @companionNewConversation.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle conversation'**
  String get companionNewConversation;

  /// No description provided for @companionSaveDeferred.
  ///
  /// In fr, this message translates to:
  /// **'{name} est ton compagnon. La synchronisation avec ton profil se fera d’elle-même.'**
  String companionSaveDeferred(String name);

  /// No description provided for @authGatewayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur INTELLIA237'**
  String get authGatewayTitle;

  /// No description provided for @authGatewaySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Quel espace veux-tu ouvrir ?'**
  String get authGatewaySubtitle;

  /// No description provided for @todayEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui'**
  String get todayEyebrow;

  /// No description provided for @firstSessionEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'Pour commencer'**
  String get firstSessionEyebrow;

  /// No description provided for @firstSessionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ta première activité'**
  String get firstSessionTitle;

  /// No description provided for @resumeWhereLeftOff.
  ///
  /// In fr, this message translates to:
  /// **'Reprends là où tu t’es arrêté'**
  String get resumeWhereLeftOff;

  /// No description provided for @keepMomentum.
  ///
  /// In fr, this message translates to:
  /// **'Continue sur ta lancée.'**
  String get keepMomentum;

  /// No description provided for @exploreEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'Explorer'**
  String get exploreEyebrow;

  /// No description provided for @chooseNextActivity.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ta prochaine activité'**
  String get chooseNextActivity;

  /// No description provided for @homeLessonsComingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tes cours arrivent'**
  String get homeLessonsComingTitle;

  /// No description provided for @homeLessonsComingBody.
  ///
  /// In fr, this message translates to:
  /// **'Les leçons de ta classe sont en cours de préparation. En attendant, découvre ton parcours ou révise avec ton compagnon.'**
  String get homeLessonsComingBody;

  /// No description provided for @discoverFlow.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir mon parcours'**
  String get discoverFlow;

  /// No description provided for @talkToCompanion.
  ///
  /// In fr, this message translates to:
  /// **'Parler à mon compagnon'**
  String get talkToCompanion;

  /// No description provided for @forYouEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'Pour toi'**
  String get forYouEyebrow;

  /// No description provided for @adaptiveJourneyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Un parcours qui avance avec toi'**
  String get adaptiveJourneyTitle;

  /// No description provided for @demoDataLabel.
  ///
  /// In fr, this message translates to:
  /// **'Données de démonstration'**
  String get demoDataLabel;

  /// No description provided for @settingsDescription.
  ///
  /// In fr, this message translates to:
  /// **'Lecture, animations, données et confidentialité'**
  String get settingsDescription;

  /// No description provided for @myProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get myProfileTitle;

  /// No description provided for @testAppVersionA11y.
  ///
  /// In fr, this message translates to:
  /// **'Version de l’application de test'**
  String get testAppVersionA11y;

  /// No description provided for @versionLoading.
  ///
  /// In fr, this message translates to:
  /// **'Version en cours de lecture'**
  String get versionLoading;

  /// No description provided for @versionUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Version indisponible'**
  String get versionUnavailable;

  /// No description provided for @intelliaUser.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur Intellia 237'**
  String get intelliaUser;

  /// No description provided for @studentAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte Élève'**
  String get studentAccount;

  /// No description provided for @academicJourney.
  ///
  /// In fr, this message translates to:
  /// **'Parcours scolaire'**
  String get academicJourney;

  /// No description provided for @loadErrorLabel.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get loadErrorLabel;

  /// No description provided for @classLabel.
  ///
  /// In fr, this message translates to:
  /// **'Classe'**
  String get classLabel;

  /// No description provided for @statisticsAndProgress.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques et progression'**
  String get statisticsAndProgress;

  /// No description provided for @statisticsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques indisponibles'**
  String get statisticsUnavailable;

  /// No description provided for @pointsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Points'**
  String get pointsLabel;

  /// No description provided for @levelLabel.
  ///
  /// In fr, this message translates to:
  /// **'Niveau'**
  String get levelLabel;

  /// No description provided for @currentStreak.
  ///
  /// In fr, this message translates to:
  /// **'Série actuelle'**
  String get currentStreak;

  /// No description provided for @dayCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 jour} =1{1 jour} other{{count} jours}}'**
  String dayCount(int count);

  /// No description provided for @progressLabel.
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get progressLabel;

  /// No description provided for @statisticsComingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tes statistiques arrivent'**
  String get statisticsComingTitle;

  /// No description provided for @statisticsComingBody.
  ///
  /// In fr, this message translates to:
  /// **'Termine ta première leçon ou ton premier quiz pour voir tes points et ta progression ici.'**
  String get statisticsComingBody;

  /// No description provided for @companionSaveDenied.
  ///
  /// In fr, this message translates to:
  /// **'Ce compagnon ne peut pas être enregistré sur ton profil.'**
  String get companionSaveDenied;

  /// No description provided for @companionSaveNetworkError.
  ///
  /// In fr, this message translates to:
  /// **'Le réseau est indisponible. Réessaie dans un instant.'**
  String get companionSaveNetworkError;

  /// No description provided for @companionSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le compagnon n’a pas pu être enregistré pour le moment.'**
  String get companionSaveFailed;

  /// No description provided for @noCompanionSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compagnon sélectionné'**
  String get noCompanionSelected;

  /// No description provided for @chooseCompanionToPersonalize.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un compagnon pour personnaliser ton expérience'**
  String get chooseCompanionToPersonalize;

  /// No description provided for @dailyChallenges.
  ///
  /// In fr, this message translates to:
  /// **'Défis du jour'**
  String get dailyChallenges;

  /// No description provided for @challengesRenewIn.
  ///
  /// In fr, this message translates to:
  /// **'Les défis se renouvellent dans {duration}'**
  String challengesRenewIn(String duration);

  /// No description provided for @challengeCompletedA11y.
  ///
  /// In fr, this message translates to:
  /// **'Défi terminé : {title}'**
  String challengeCompletedA11y(String title);

  /// No description provided for @challengeRewardA11y.
  ///
  /// In fr, this message translates to:
  /// **'Défi : {title}, récompense {points} points'**
  String challengeRewardA11y(String title, int points);

  /// No description provided for @progressOverviewA11y.
  ///
  /// In fr, this message translates to:
  /// **'Ma progression : {percent} % global, niveau {level}, {points} points. Ouvrir le profil.'**
  String progressOverviewA11y(int percent, int level, int points);

  /// No description provided for @myProgress.
  ///
  /// In fr, this message translates to:
  /// **'Ma progression'**
  String get myProgress;

  /// No description provided for @levelShort.
  ///
  /// In fr, this message translates to:
  /// **'Niv. {level}'**
  String levelShort(int level);

  /// No description provided for @currentLevel.
  ///
  /// In fr, this message translates to:
  /// **'Niveau actuel'**
  String get currentLevel;

  /// No description provided for @levelValue.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {level}'**
  String levelValue(int level);

  /// No description provided for @globalLabel.
  ///
  /// In fr, this message translates to:
  /// **'global'**
  String get globalLabel;

  /// No description provided for @quickQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Quiz rapide'**
  String get quickQuiz;

  /// No description provided for @personalizedRecommendations.
  ///
  /// In fr, this message translates to:
  /// **'Recommandations personnalisées'**
  String get personalizedRecommendations;

  /// No description provided for @resumeLessonA11y.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre la leçon {title}, avancée à {percent} pour cent.'**
  String resumeLessonA11y(String title, int percent);

  /// No description provided for @resumeLastLesson.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre le dernier cours'**
  String get resumeLastLesson;

  /// No description provided for @streakA11y.
  ///
  /// In fr, this message translates to:
  /// **'Série de {count} jours. {message}'**
  String streakA11y(int count, String message);

  /// No description provided for @streakDayCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 jour de série} =1{1 jour de série} other{{count} jours de série}}'**
  String streakDayCount(int count);

  /// No description provided for @mySpace.
  ///
  /// In fr, this message translates to:
  /// **'Mon espace'**
  String get mySpace;

  /// No description provided for @myLearningSpace.
  ///
  /// In fr, this message translates to:
  /// **'Mon espace d’apprentissage'**
  String get myLearningSpace;

  /// No description provided for @openNotificationsA11y.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Ouvrir les notifications} =1{Ouvrir les notifications, 1 non lue} other{Ouvrir les notifications, {count} non lues}}'**
  String openNotificationsA11y(int count);

  /// No description provided for @openMyProfile.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir mon profil'**
  String get openMyProfile;

  /// No description provided for @subjectsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Matières'**
  String get subjectsTitle;

  /// No description provided for @subjectProgressA11y.
  ///
  /// In fr, this message translates to:
  /// **'{title}, {percent} % terminé'**
  String subjectProgressA11y(String title, int percent);

  /// No description provided for @weeklyGoalProgressA11y.
  ///
  /// In fr, this message translates to:
  /// **'Mon objectif de la semaine : {done} sur {total} séances. {status}'**
  String weeklyGoalProgressA11y(int done, int total, String status);

  /// No description provided for @goalAchievedA11y.
  ///
  /// In fr, this message translates to:
  /// **'Objectif atteint.'**
  String get goalAchievedA11y;

  /// No description provided for @myWeeklyGoal.
  ///
  /// In fr, this message translates to:
  /// **'Mon objectif de la semaine'**
  String get myWeeklyGoal;

  /// No description provided for @editMyGoal.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mon objectif'**
  String get editMyGoal;

  /// No description provided for @goalAchievedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Objectif atteint — belle semaine !'**
  String get goalAchievedMessage;

  /// No description provided for @weeklyGoalProgressSummary.
  ///
  /// In fr, this message translates to:
  /// **'{done}/{total} séances · environ {minutes} min chacune'**
  String weeklyGoalProgressSummary(int done, int total, int minutes);

  /// No description provided for @openPrioritySubjectA11y.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir ma matière prioritaire : {subject}'**
  String openPrioritySubjectA11y(String subject);

  /// No description provided for @prioritySubject.
  ///
  /// In fr, this message translates to:
  /// **'Priorité : {subject}'**
  String prioritySubject(String subject);

  /// No description provided for @setWeeklyPace.
  ///
  /// In fr, this message translates to:
  /// **'Fixer mon rythme de la semaine'**
  String get setWeeklyPace;

  /// No description provided for @setYourWeeklyPace.
  ///
  /// In fr, this message translates to:
  /// **'Fixe ton rythme de la semaine'**
  String get setYourWeeklyPace;

  /// No description provided for @weeklyPaceChoices.
  ///
  /// In fr, this message translates to:
  /// **'2, 3 ou 5 séances : c’est toi qui choisis.'**
  String get weeklyPaceChoices;

  /// No description provided for @weeklyGoalExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Un rythme réaliste que tu choisis. Le compteur repart chaque lundi, sans pression.'**
  String get weeklyGoalExplanation;

  /// No description provided for @sessionsPerWeek.
  ///
  /// In fr, this message translates to:
  /// **'Séances par semaine'**
  String get sessionsPerWeek;

  /// No description provided for @sessionDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée d’une séance'**
  String get sessionDuration;

  /// No description provided for @prioritySubjectOptional.
  ///
  /// In fr, this message translates to:
  /// **'Matière prioritaire (optionnel)'**
  String get prioritySubjectOptional;

  /// No description provided for @noneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get noneLabel;

  /// No description provided for @saveMyGoal.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer mon objectif'**
  String get saveMyGoal;

  /// No description provided for @removeGoal.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l’objectif'**
  String get removeGoal;

  /// No description provided for @childOverviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vue enfant'**
  String get childOverviewTitle;

  /// No description provided for @childNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Enfant introuvable.'**
  String get childNotFound;

  /// No description provided for @weeklyProgress.
  ///
  /// In fr, this message translates to:
  /// **'Progression hebdomadaire'**
  String get weeklyProgress;

  /// No description provided for @progressChartComing.
  ///
  /// In fr, this message translates to:
  /// **'La courbe apparaîtra après les premières activités.'**
  String get progressChartComing;

  /// No description provided for @strongSubjects.
  ///
  /// In fr, this message translates to:
  /// **'Forts'**
  String get strongSubjects;

  /// No description provided for @needsImprovement.
  ///
  /// In fr, this message translates to:
  /// **'À renforcer'**
  String get needsImprovement;

  /// No description provided for @viewDetailedProgress.
  ///
  /// In fr, this message translates to:
  /// **'Voir la progression détaillée'**
  String get viewDetailedProgress;

  /// No description provided for @notMeasuredYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore mesuré'**
  String get notMeasuredYet;

  /// No description provided for @childProgressTitle.
  ///
  /// In fr, this message translates to:
  /// **'Progression enfant'**
  String get childProgressTitle;

  /// No description provided for @childSevenDayProgress.
  ///
  /// In fr, this message translates to:
  /// **'{name} — progression sur 7 jours'**
  String childSevenDayProgress(String name);

  /// No description provided for @todayStudy.
  ///
  /// In fr, this message translates to:
  /// **'Étude du jour'**
  String get todayStudy;

  /// No description provided for @dailyTrend.
  ///
  /// In fr, this message translates to:
  /// **'Tendance quotidienne'**
  String get dailyTrend;

  /// No description provided for @childrenLabel.
  ///
  /// In fr, this message translates to:
  /// **'Enfants'**
  String get childrenLabel;

  /// No description provided for @announcementsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Annonces'**
  String get announcementsLabel;

  /// No description provided for @subscriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement'**
  String get subscriptionLabel;

  /// No description provided for @parentSpace.
  ///
  /// In fr, this message translates to:
  /// **'Espace parent'**
  String get parentSpace;

  /// No description provided for @myChildren.
  ///
  /// In fr, this message translates to:
  /// **'Mes enfants'**
  String get myChildren;

  /// No description provided for @paymentsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get paymentsLabel;

  /// No description provided for @parentSpaceUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Espace parent indisponible'**
  String get parentSpaceUnavailable;

  /// No description provided for @parentSpaceDescription.
  ///
  /// In fr, this message translates to:
  /// **'Suivi clair et rassurant de la progression scolaire.'**
  String get parentSpaceDescription;

  /// No description provided for @globalProgressPercent.
  ///
  /// In fr, this message translates to:
  /// **'Progression globale {percent}%'**
  String globalProgressPercent(int percent);

  /// No description provided for @progressComingAfterActivities.
  ///
  /// In fr, this message translates to:
  /// **'La progression apparaîtra après les premières activités.'**
  String get progressComingAfterActivities;

  /// No description provided for @activityChartComing.
  ///
  /// In fr, this message translates to:
  /// **'Courbe d’activité à venir'**
  String get activityChartComing;

  /// No description provided for @childWeeklyProgressComing.
  ///
  /// In fr, this message translates to:
  /// **'La progression hebdomadaire de {name} apparaîtra ici après ses premières leçons et quiz.'**
  String childWeeklyProgressComing(String name);

  /// No description provided for @subjectsToImprove.
  ///
  /// In fr, this message translates to:
  /// **'À renforcer'**
  String get subjectsToImprove;

  /// No description provided for @subjectStrengthsComing.
  ///
  /// In fr, this message translates to:
  /// **'Les points forts et les matières à renforcer seront identifiés après les premières évaluations.'**
  String get subjectStrengthsComing;

  /// No description provided for @schoolAnnouncements.
  ///
  /// In fr, this message translates to:
  /// **'Annonces de l’établissement'**
  String get schoolAnnouncements;

  /// No description provided for @parentAccountActiveBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte est actif. Les enfants liés apparaîtront ici après validation du lien.'**
  String get parentAccountActiveBody;

  /// No description provided for @noChildLinked.
  ///
  /// In fr, this message translates to:
  /// **'Aucun enfant lié'**
  String get noChildLinked;

  /// No description provided for @linkChildHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez un code enfant depuis le profil ou demandez le lien à l’établissement.'**
  String get linkChildHelp;

  /// No description provided for @overviewLabel.
  ///
  /// In fr, this message translates to:
  /// **'Vue d’ensemble'**
  String get overviewLabel;

  /// No description provided for @parentProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil Parent'**
  String get parentProfile;

  /// No description provided for @parentAccountActive.
  ///
  /// In fr, this message translates to:
  /// **'Compte parent actif'**
  String get parentAccountActive;

  /// No description provided for @parentSettingsDescription.
  ///
  /// In fr, this message translates to:
  /// **'Lecture, notifications, données et confidentialité'**
  String get parentSettingsDescription;

  /// No description provided for @toBeDetermined.
  ///
  /// In fr, this message translates to:
  /// **'À déterminer'**
  String get toBeDetermined;

  /// No description provided for @studyTimeComing.
  ///
  /// In fr, this message translates to:
  /// **'Le temps d’étude sera affiché dès que la mesure sera disponible.'**
  String get studyTimeComing;

  /// No description provided for @todayStudyTime.
  ///
  /// In fr, this message translates to:
  /// **'Temps d’étude du jour'**
  String get todayStudyTime;

  /// No description provided for @studyMinutesGoal.
  ///
  /// In fr, this message translates to:
  /// **'{done} min / objectif {goal} min'**
  String studyMinutesGoal(int done, int goal);

  /// No description provided for @badgeUnlocked.
  ///
  /// In fr, this message translates to:
  /// **'Badge débloqué'**
  String get badgeUnlocked;

  /// No description provided for @discoverAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir la réponse'**
  String get discoverAnswer;

  /// No description provided for @newLabel.
  ///
  /// In fr, this message translates to:
  /// **'NOUVEAU'**
  String get newLabel;

  /// No description provided for @flowEntryDescription.
  ///
  /// In fr, this message translates to:
  /// **'Apprends en glissant,\nune carte à la fois.'**
  String get flowEntryDescription;

  /// No description provided for @missingAnswerHint.
  ///
  /// In fr, this message translates to:
  /// **'Écris le mot ou le nombre manquant'**
  String get missingAnswerHint;

  /// No description provided for @submitMyAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Valider ma réponse'**
  String get submitMyAnswer;

  /// No description provided for @checkOrder.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier l’ordre'**
  String get checkOrder;

  /// No description provided for @sessionVerifiedPoints.
  ///
  /// In fr, this message translates to:
  /// **'{count} points vérifiés dans cette session'**
  String sessionVerifiedPoints(int count);

  /// No description provided for @totalPendingShort.
  ///
  /// In fr, this message translates to:
  /// **'Total —'**
  String get totalPendingShort;

  /// No description provided for @totalPointsShort.
  ///
  /// In fr, this message translates to:
  /// **'{count} au total'**
  String totalPointsShort(int count);

  /// No description provided for @totalPendingValidation.
  ///
  /// In fr, this message translates to:
  /// **'Total en attente de validation serveur'**
  String get totalPendingValidation;

  /// No description provided for @totalVerifiedPoints.
  ///
  /// In fr, this message translates to:
  /// **'{count} points vérifiés au total'**
  String totalVerifiedPoints(int count);

  /// No description provided for @pendingValidationShort.
  ///
  /// In fr, this message translates to:
  /// **'{count} à valider'**
  String pendingValidationShort(int count);

  /// No description provided for @offlineActivitiesToSync.
  ///
  /// In fr, this message translates to:
  /// **'{count} activités hors ligne à synchroniser'**
  String offlineActivitiesToSync(int count);

  /// No description provided for @verifiedSession.
  ///
  /// In fr, this message translates to:
  /// **'Session vérifiée'**
  String get verifiedSession;

  /// No description provided for @verifiedTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total vérifié'**
  String get verifiedTotal;

  /// No description provided for @pendingValidationLabel.
  ///
  /// In fr, this message translates to:
  /// **'À valider'**
  String get pendingValidationLabel;

  /// No description provided for @activeTab.
  ///
  /// In fr, this message translates to:
  /// **'Onglet actif : {label}'**
  String activeTab(String label);

  /// No description provided for @startupInterrupted.
  ///
  /// In fr, this message translates to:
  /// **'Démarrage interrompu'**
  String get startupInterrupted;

  /// No description provided for @roleSpace.
  ///
  /// In fr, this message translates to:
  /// **'Espace {role}'**
  String roleSpace(String role);

  /// No description provided for @welcomeRoleSpace.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans l’espace {role}'**
  String welcomeRoleSpace(String role);

  /// No description provided for @roleOptionsBody.
  ///
  /// In fr, this message translates to:
  /// **'Consultez les options disponibles pour votre profil.'**
  String get roleOptionsBody;

  /// No description provided for @skipLabel.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get skipLabel;

  /// No description provided for @probatoireLevel.
  ///
  /// In fr, this message translates to:
  /// **'Probatoire'**
  String get probatoireLevel;

  /// No description provided for @baccalaureateLevel.
  ///
  /// In fr, this message translates to:
  /// **'Baccalauréat'**
  String get baccalaureateLevel;

  /// No description provided for @chooseTutorA11y.
  ///
  /// In fr, this message translates to:
  /// **'Choisir {name} comme tuteur'**
  String chooseTutorA11y(String name);

  /// No description provided for @chooseYourTutor.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton tuteur'**
  String get chooseYourTutor;

  /// No description provided for @tutorJourneyDescription.
  ///
  /// In fr, this message translates to:
  /// **'Il t’accompagnera tout au long de ton parcours'**
  String get tutorJourneyDescription;

  /// No description provided for @activationEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'INTELLIA // L’ÉVEIL'**
  String get activationEyebrow;

  /// No description provided for @activationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le savoir attend ton signal.'**
  String get activationTitle;

  /// No description provided for @knowledgeEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'UNIVERS DES SAVOIRS'**
  String get knowledgeEyebrow;

  /// No description provided for @knowledgeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Chaque matière ouvre une trajectoire.'**
  String get knowledgeTitle;

  /// No description provided for @knowledgeBody.
  ///
  /// In fr, this message translates to:
  /// **'Mathématiques, français, anglais, sciences : entre par le sujet qui t’attire.'**
  String get knowledgeBody;

  /// No description provided for @challengeEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'PREMIER DÉFI'**
  String get challengeEyebrow;

  /// No description provided for @challengeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comprendre compte plus que deviner.'**
  String get challengeTitle;

  /// No description provided for @challengeBody.
  ///
  /// In fr, this message translates to:
  /// **'Essaie. Si tu hésites, INTELLIA décompose le raisonnement avec toi.'**
  String get challengeBody;

  /// No description provided for @companionsEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'DEUX ÉNERGIES'**
  String get companionsEyebrow;

  /// No description provided for @companionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Deux personnalités. Un même objectif.'**
  String get companionsTitle;

  /// No description provided for @companionsBody.
  ///
  /// In fr, this message translates to:
  /// **'Te faire progresser, avec une manière d’expliquer qui te ressemble.'**
  String get companionsBody;

  /// No description provided for @journeyEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'PARCOURS INTELLIA'**
  String get journeyEyebrow;

  /// No description provided for @journeyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Un défi devient une maîtrise.'**
  String get journeyTitle;

  /// No description provided for @journeyBody.
  ///
  /// In fr, this message translates to:
  /// **'INTELLIA237 relie les leçons, l’entraînement et les quiz dans un parcours cohérent.'**
  String get journeyBody;

  /// No description provided for @portalEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'TON ESPACE PREND FORME'**
  String get portalEyebrow;

  /// No description provided for @portalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le parcours commence maintenant.'**
  String get portalTitle;

  /// No description provided for @portalBody.
  ///
  /// In fr, this message translates to:
  /// **'Retrouve tes matières, tes défis et ton compagnon dans une seule expérience.'**
  String get portalBody;

  /// No description provided for @holdToEnterIntellia.
  ///
  /// In fr, this message translates to:
  /// **'Maintiens pour entrer dans INTELLIA237'**
  String get holdToEnterIntellia;

  /// No description provided for @holdCenterToActivate.
  ///
  /// In fr, this message translates to:
  /// **'Maintenir le centre jusqu’à activation'**
  String get holdCenterToActivate;

  /// No description provided for @answerChoiceA11y.
  ///
  /// In fr, this message translates to:
  /// **'Réponse {answer}'**
  String answerChoiceA11y(String answer);

  /// No description provided for @continueAfterDiscovering.
  ///
  /// In fr, this message translates to:
  /// **'Continuer après avoir découvert {name}'**
  String continueAfterDiscovering(String name);

  /// No description provided for @continueWithCompanion.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec {name}'**
  String continueWithCompanion(String name);

  /// No description provided for @discoverCompanionA11y.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir {name}'**
  String discoverCompanionA11y(String name);

  /// No description provided for @kiraOnboardingSignature.
  ///
  /// In fr, this message translates to:
  /// **'CALME • MÉTHODE • CONFIANCE'**
  String get kiraOnboardingSignature;

  /// No description provided for @kiraOnboardingExample.
  ///
  /// In fr, this message translates to:
  /// **'On reprend l’idée essentielle, puis on avance ensemble.'**
  String get kiraOnboardingExample;

  /// No description provided for @leoOnboardingSignature.
  ///
  /// In fr, this message translates to:
  /// **'DÉFI • ÉNERGIE • DÉPASSEMENT'**
  String get leoOnboardingSignature;

  /// No description provided for @leoOnboardingExample.
  ///
  /// In fr, this message translates to:
  /// **'Prêt pour un défi ? Je te donne l’indice qui débloque tout.'**
  String get leoOnboardingExample;

  /// No description provided for @lessonNodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'LEÇON'**
  String get lessonNodeLabel;

  /// No description provided for @trainingNodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'ENTRAÎNEMENT'**
  String get trainingNodeLabel;

  /// No description provided for @reachMasteryA11y.
  ///
  /// In fr, this message translates to:
  /// **'Atteindre la maîtrise et ouvrir le portail'**
  String get reachMasteryA11y;

  /// No description provided for @masteryNodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'MAÎTRISE'**
  String get masteryNodeLabel;

  /// No description provided for @tapMasteryInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Touche la maîtrise pour ouvrir ton espace'**
  String get tapMasteryInstruction;

  /// No description provided for @chooseSubject.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une matière'**
  String get chooseSubject;

  /// No description provided for @yourLearningSpace.
  ///
  /// In fr, this message translates to:
  /// **'Ton espace d’apprentissage'**
  String get yourLearningSpace;

  /// No description provided for @journeyAtYourPace.
  ///
  /// In fr, this message translates to:
  /// **'Une trajectoire, à ton rythme'**
  String get journeyAtYourPace;

  /// No description provided for @nextLessonPreview.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine leçon'**
  String get nextLessonPreview;

  /// No description provided for @equationsPreview.
  ///
  /// In fr, this message translates to:
  /// **'Équations'**
  String get equationsPreview;

  /// No description provided for @dailyChallengePreview.
  ///
  /// In fr, this message translates to:
  /// **'Défi du jour'**
  String get dailyChallengePreview;

  /// No description provided for @quizFiveMinutesPreview.
  ///
  /// In fr, this message translates to:
  /// **'Quiz • 5 min'**
  String get quizFiveMinutesPreview;

  /// No description provided for @factorizedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Factorisé'**
  String get factorizedLabel;

  /// No description provided for @whoWillBeYourCompanion.
  ///
  /// In fr, this message translates to:
  /// **'Qui sera ton compagnon pédagogique ?'**
  String get whoWillBeYourCompanion;

  /// No description provided for @learningDialogueA11y.
  ///
  /// In fr, this message translates to:
  /// **'Dialogue pédagogique'**
  String get learningDialogueA11y;

  /// No description provided for @firstNameWithArticle.
  ///
  /// In fr, this message translates to:
  /// **'Le prénom'**
  String get firstNameWithArticle;

  /// No description provided for @lastNameWithArticle.
  ///
  /// In fr, this message translates to:
  /// **'Le nom'**
  String get lastNameWithArticle;

  /// No description provided for @passwordMinEight.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères minimum'**
  String get passwordMinEight;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In fr, this message translates to:
  /// **'Retapez le mot de passe'**
  String get confirmPasswordHint;

  /// No description provided for @teacherRegistrationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte Enseignant'**
  String get teacherRegistrationTitle;

  /// No description provided for @teacherIdentityStep.
  ///
  /// In fr, this message translates to:
  /// **'Identité enseignant'**
  String get teacherIdentityStep;

  /// No description provided for @teachingStep.
  ///
  /// In fr, this message translates to:
  /// **'Enseignement'**
  String get teachingStep;

  /// No description provided for @teacherDetailsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées enseignant'**
  String get teacherDetailsTitle;

  /// No description provided for @teacherDetailsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez vos informations de connexion.'**
  String get teacherDetailsSubtitle;

  /// No description provided for @firstNameTeacherHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Serge'**
  String get firstNameTeacherHint;

  /// No description provided for @lastNameTeacherHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Mbarga'**
  String get lastNameTeacherHint;

  /// No description provided for @teacherEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'enseignant@exemple.com'**
  String get teacherEmailHint;

  /// No description provided for @teachingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre enseignement'**
  String get teachingTitle;

  /// No description provided for @teachingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez vos matières et niveaux enseignés.'**
  String get teachingSubtitle;

  /// No description provided for @taughtSubjectsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Matières enseignées'**
  String get taughtSubjectsTitle;

  /// No description provided for @taughtSubjectsCaption.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez vos disciplines principales.'**
  String get taughtSubjectsCaption;

  /// No description provided for @taughtLevelsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Niveaux enseignés'**
  String get taughtLevelsTitle;

  /// No description provided for @taughtLevelsCaption.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez les classes que vous couvrez.'**
  String get taughtLevelsCaption;

  /// No description provided for @teacherFinalSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Relisez vos informations avant de confirmer.'**
  String get teacherFinalSubtitle;

  /// No description provided for @teacherValidationNotice.
  ///
  /// In fr, this message translates to:
  /// **'L’inscription d’un compte enseignant nécessite une validation par une équipe autorisée.'**
  String get teacherValidationNotice;

  /// No description provided for @createTeacherAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte enseignant'**
  String get createTeacherAccount;

  /// No description provided for @adminRegistrationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte Direction'**
  String get adminRegistrationTitle;

  /// No description provided for @adminIdentityStep.
  ///
  /// In fr, this message translates to:
  /// **'Identité direction'**
  String get adminIdentityStep;

  /// No description provided for @jobFunctionStep.
  ///
  /// In fr, this message translates to:
  /// **'Fonction'**
  String get jobFunctionStep;

  /// No description provided for @adminDetailsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées direction'**
  String get adminDetailsTitle;

  /// No description provided for @adminDetailsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Informations du responsable ou membre de direction.'**
  String get adminDetailsSubtitle;

  /// No description provided for @firstNameAdminHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Nadine'**
  String get firstNameAdminHint;

  /// No description provided for @lastNameAdminHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Meka'**
  String get lastNameAdminHint;

  /// No description provided for @adminEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'direction@exemple.com'**
  String get adminEmailHint;

  /// No description provided for @adminFunctionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre fonction'**
  String get adminFunctionTitle;

  /// No description provided for @adminFunctionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Précisez votre rôle au sein de la direction.'**
  String get adminFunctionSubtitle;

  /// No description provided for @jobTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Fonction'**
  String get jobTitleLabel;

  /// No description provided for @jobTitleHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Proviseur, Censeur, Directeur adjoint'**
  String get jobTitleHint;

  /// No description provided for @minimumThreeCharacters.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 3 caractères'**
  String get minimumThreeCharacters;

  /// No description provided for @adminAccreditationNotice.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte direction sera soumis à un contrôle d’accréditation par nos équipes avant activation.'**
  String get adminAccreditationNotice;

  /// No description provided for @adminFinalSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande sera transmise pour validation.'**
  String get adminFinalSubtitle;

  /// No description provided for @adminValidationNotice.
  ///
  /// In fr, this message translates to:
  /// **'Une fois validé, vous recevrez une notification par e-mail vous invitant à vous connecter à votre console d’administration.'**
  String get adminValidationNotice;

  /// No description provided for @createAdminAccount.
  ///
  /// In fr, this message translates to:
  /// **'Soumettre mon compte direction'**
  String get createAdminAccount;

  /// No description provided for @legalVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version du 16 juillet 2026'**
  String get legalVersion;

  /// No description provided for @legalContactNotice.
  ///
  /// In fr, this message translates to:
  /// **'Pour toute question ou demande liée aux données, contacte ton établissement ou l’équipe Intellia237. Une validation juridique locale reste requise avant la mise en production commerciale.'**
  String get legalContactNotice;

  /// No description provided for @legalTermsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d’utilisation'**
  String get legalTermsTitle;

  /// No description provided for @legalServicePurposeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Objet du service'**
  String get legalServicePurposeTitle;

  /// No description provided for @legalServicePurposeBody.
  ///
  /// In fr, this message translates to:
  /// **'Intellia237 fournit des ressources pédagogiques, des quiz et un compagnon d’apprentissage. Le service complète l’enseignement et ne remplace ni l’établissement ni l’enseignant.'**
  String get legalServicePurposeBody;

  /// No description provided for @legalAccountSecurityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte et sécurité'**
  String get legalAccountSecurityTitle;

  /// No description provided for @legalAccountSecurityBody.
  ///
  /// In fr, this message translates to:
  /// **'Les informations fournies doivent être exactes. Les identifiants restent personnels. Les comptes enseignants et administrateurs peuvent nécessiter une validation.'**
  String get legalAccountSecurityBody;

  /// No description provided for @legalResponsibleUseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Usage responsable'**
  String get legalResponsibleUseTitle;

  /// No description provided for @legalResponsibleUseBody.
  ///
  /// In fr, this message translates to:
  /// **'Il est interdit de contourner les règles des évaluations, d’extraire des données d’autres utilisateurs ou d’utiliser le compagnon pour produire un contenu nuisible.'**
  String get legalResponsibleUseBody;

  /// No description provided for @availabilityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Disponibilité'**
  String get availabilityLabel;

  /// No description provided for @legalAvailabilityBody.
  ///
  /// In fr, this message translates to:
  /// **'Certaines fonctions exigent une connexion. Les maintenances et indisponibilités temporaires sont signalées aussi clairement que possible.'**
  String get legalAvailabilityBody;

  /// No description provided for @legalPrivacyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get legalPrivacyTitle;

  /// No description provided for @legalCollectedDataTitle.
  ///
  /// In fr, this message translates to:
  /// **'Données collectées'**
  String get legalCollectedDataTitle;

  /// No description provided for @legalCollectedDataBody.
  ///
  /// In fr, this message translates to:
  /// **'Le compte, le rôle, la classe, la progression et les tentatives nécessaires au service peuvent être enregistrés. Les données demandées doivent rester limitées à la finalité pédagogique.'**
  String get legalCollectedDataBody;

  /// No description provided for @legalMinorsPrivacyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mineurs et confidentialité'**
  String get legalMinorsPrivacyTitle;

  /// No description provided for @legalMinorsPrivacyBody.
  ///
  /// In fr, this message translates to:
  /// **'Les conversations, réponses libres, noms et e-mails ne doivent jamais être envoyés aux outils de mesure d’audience. Les diagnostics anonymes sont désactivés par défaut.'**
  String get legalMinorsPrivacyBody;

  /// No description provided for @legalRetentionAccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conservation et accès'**
  String get legalRetentionAccessTitle;

  /// No description provided for @legalRetentionAccessBody.
  ///
  /// In fr, this message translates to:
  /// **'Les données sont accessibles uniquement aux personnes autorisées selon leur rôle. Les durées de conservation et procédures d’accès doivent être validées avant mise en production.'**
  String get legalRetentionAccessBody;

  /// No description provided for @legalYourRightsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos droits'**
  String get legalYourRightsTitle;

  /// No description provided for @legalYourRightsBody.
  ///
  /// In fr, this message translates to:
  /// **'L’utilisateur ou son représentant peut demander l’accès, la correction ou la suppression de ses données auprès de l’établissement ou de l’équipe Intellia237.'**
  String get legalYourRightsBody;

  /// No description provided for @legalEducationalDataTitle.
  ///
  /// In fr, this message translates to:
  /// **'Traitement pédagogique des données'**
  String get legalEducationalDataTitle;

  /// No description provided for @legalPurposeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Finalité'**
  String get legalPurposeTitle;

  /// No description provided for @legalPurposeBody.
  ///
  /// In fr, this message translates to:
  /// **'Les réponses, résultats et progressions servent à proposer une prochaine étape, présenter une correction et aider l’enseignant ou le parent autorisé à accompagner l’élève.'**
  String get legalPurposeBody;

  /// No description provided for @legalDecisionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Décisions'**
  String get legalDecisionsTitle;

  /// No description provided for @legalDecisionsBody.
  ///
  /// In fr, this message translates to:
  /// **'Une recommandation automatisée ne constitue pas une décision scolaire officielle. L’enseignant et l’établissement restent responsables de l’évaluation scolaire.'**
  String get legalDecisionsBody;

  /// No description provided for @legalCompanionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compagnon pédagogique'**
  String get legalCompanionTitle;

  /// No description provided for @legalCompanionBody.
  ///
  /// In fr, this message translates to:
  /// **'Les messages sont transmis au service nécessaire pour générer une réponse. L’élève ne doit pas y communiquer d’information personnelle sensible.'**
  String get legalCompanionBody;

  /// No description provided for @readTerms.
  ///
  /// In fr, this message translates to:
  /// **'Lire les conditions'**
  String get readTerms;

  /// No description provided for @readPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Lire la confidentialité'**
  String get readPrivacy;

  /// No description provided for @readEducationalData.
  ///
  /// In fr, this message translates to:
  /// **'Comprendre les données pédagogiques'**
  String get readEducationalData;

  /// No description provided for @loadingOffer.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de l’offre'**
  String get loadingOffer;

  /// No description provided for @serviceUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Service indisponible'**
  String get serviceUnavailable;

  /// No description provided for @subscriptionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement'**
  String get subscriptionTitle;

  /// No description provided for @mobileMoneyParentDescription.
  ///
  /// In fr, this message translates to:
  /// **'Paiement Mobile Money déclaré, puis vérifié manuellement par l’établissement de l’enfant concerné.'**
  String get mobileMoneyParentDescription;

  /// No description provided for @myPaymentRequests.
  ///
  /// In fr, this message translates to:
  /// **'Mes demandes'**
  String get myPaymentRequests;

  /// No description provided for @accessDaysAfterApproval.
  ///
  /// In fr, this message translates to:
  /// **'Accès pendant {days} jours après validation'**
  String accessDaysAfterApproval(int days);

  /// No description provided for @mobileMoneyStepTransfer.
  ///
  /// In fr, this message translates to:
  /// **'1. Effectuez le transfert'**
  String get mobileMoneyStepTransfer;

  /// No description provided for @operatorLabel.
  ///
  /// In fr, this message translates to:
  /// **'Opérateur'**
  String get operatorLabel;

  /// No description provided for @recipientNumberConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Numéro bénéficiaire configuré'**
  String get recipientNumberConfigured;

  /// No description provided for @copyNumber.
  ///
  /// In fr, this message translates to:
  /// **'Copier le numéro'**
  String get copyNumber;

  /// No description provided for @numberCopied.
  ///
  /// In fr, this message translates to:
  /// **'Numéro copié.'**
  String get numberCopied;

  /// No description provided for @mobileMoneyNoDebitNotice.
  ///
  /// In fr, this message translates to:
  /// **'Intellia237 ne déclenche aucun débit. Réalisez vous-même le transfert dans l’application de votre opérateur et vérifiez le numéro avant de confirmer.'**
  String get mobileMoneyNoDebitNotice;

  /// No description provided for @mobileMoneyStepProof.
  ///
  /// In fr, this message translates to:
  /// **'2. Envoyez la preuve de transfert'**
  String get mobileMoneyStepProof;

  /// No description provided for @payerPhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro ayant effectué le transfert'**
  String get payerPhoneLabel;

  /// No description provided for @transactionReferenceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Référence de transaction'**
  String get transactionReferenceLabel;

  /// No description provided for @sendingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Envoi en cours…'**
  String get sendingLabel;

  /// No description provided for @submitForReview.
  ///
  /// In fr, this message translates to:
  /// **'Transmettre pour vérification'**
  String get submitForReview;

  /// No description provided for @enterTransferDetails.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le téléphone et la référence du transfert.'**
  String get enterTransferDetails;

  /// No description provided for @confirmDeclarationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la déclaration'**
  String get confirmDeclarationTitle;

  /// No description provided for @confirmTransferDeclaration.
  ///
  /// In fr, this message translates to:
  /// **'Vous déclarez avoir transféré {amount} via {operator} vers {phone}. Aucune somme ne sera débitée par Intellia237.'**
  String confirmTransferDeclaration(
    String amount,
    String operator,
    String phone,
  );

  /// No description provided for @paymentRequestSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Demande transmise. L’accès sera activé uniquement après vérification.'**
  String get paymentRequestSubmitted;

  /// No description provided for @noValidatedSchoolLinked.
  ///
  /// In fr, this message translates to:
  /// **'Aucun établissement validé n’est encore lié à ce compte parent.'**
  String get noValidatedSchoolLinked;

  /// No description provided for @multipleSchoolsLinked.
  ///
  /// In fr, this message translates to:
  /// **'Vos enfants sont inscrits dans plusieurs établissements : choisissez l’enfant pour qui vous payez.'**
  String get multipleSchoolsLinked;

  /// No description provided for @noActiveMobileMoneyOffer.
  ///
  /// In fr, this message translates to:
  /// **'L’établissement de cet enfant n’a pas encore publié d’offre Mobile Money active.'**
  String get noActiveMobileMoneyOffer;

  /// No description provided for @offerUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Offre indisponible'**
  String get offerUnavailable;

  /// No description provided for @referenceValue.
  ///
  /// In fr, this message translates to:
  /// **'Référence {reference}'**
  String referenceValue(String reference);

  /// No description provided for @schoolNote.
  ///
  /// In fr, this message translates to:
  /// **'Note de l’établissement : {note}'**
  String schoolNote(String note);

  /// No description provided for @mobileMoneyReferenceAlreadySubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Cette référence a déjà été transmise. Consultez son statut ci-dessous.'**
  String get mobileMoneyReferenceAlreadySubmitted;

  /// No description provided for @mobileMoneyOfferNoLongerAvailable.
  ///
  /// In fr, this message translates to:
  /// **'L’offre ou le rattachement à l’établissement n’est plus disponible.'**
  String get mobileMoneyOfferNoLongerAvailable;

  /// No description provided for @mobileMoneyPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte n’est pas autorisé à effectuer cette opération.'**
  String get mobileMoneyPermissionDenied;

  /// No description provided for @mobileMoneyInvalidDetails.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez le numéro de téléphone et la référence de transaction.'**
  String get mobileMoneyInvalidDetails;

  /// No description provided for @mobileMoneyTemporarilyUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le service est momentanément indisponible. Réessayez sans refaire le transfert.'**
  String get mobileMoneyTemporarilyUnavailable;

  /// No description provided for @mobileMoneyGenericError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de traiter cette demande pour le moment.'**
  String get mobileMoneyGenericError;

  /// No description provided for @paymentPendingReview.
  ///
  /// In fr, this message translates to:
  /// **'En vérification'**
  String get paymentPendingReview;

  /// No description provided for @paymentApproved.
  ///
  /// In fr, this message translates to:
  /// **'Validé'**
  String get paymentApproved;

  /// No description provided for @paymentRejected.
  ///
  /// In fr, this message translates to:
  /// **'Rejeté'**
  String get paymentRejected;

  /// No description provided for @loadingPayments.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des paiements'**
  String get loadingPayments;

  /// No description provided for @paymentQueueUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'File indisponible'**
  String get paymentQueueUnavailable;

  /// No description provided for @mobileMoneyApprovalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Validation Mobile Money'**
  String get mobileMoneyApprovalTitle;

  /// No description provided for @mobileMoneyAdminDescription.
  ///
  /// In fr, this message translates to:
  /// **'Comparez chaque référence avec le portail de l’opérateur avant toute décision. Intellia237 ne prélève aucune somme.'**
  String get mobileMoneyAdminDescription;

  /// No description provided for @noPendingPaymentRequest.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande en attente'**
  String get noPendingPaymentRequest;

  /// No description provided for @payerPhoneShort.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone payeur'**
  String get payerPhoneShort;

  /// No description provided for @referenceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Référence'**
  String get referenceLabel;

  /// No description provided for @rejectLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter'**
  String get rejectLabel;

  /// No description provided for @paymentVerifiedQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Paiement vérifié ?'**
  String get paymentVerifiedQuestion;

  /// No description provided for @paymentVerificationWarning.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez uniquement si {amount} et la référence {reference} apparaissent dans le portail {operator}. Cette action activera l’accès.'**
  String paymentVerificationWarning(
    String amount,
    String reference,
    String operator,
  );

  /// No description provided for @paymentVerifiedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Paiement vérifié'**
  String get paymentVerifiedLabel;

  /// No description provided for @rejectPaymentRequest.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter la demande'**
  String get rejectPaymentRequest;

  /// No description provided for @rejectionReasonOptional.
  ///
  /// In fr, this message translates to:
  /// **'Motif visible par le parent (facultatif)'**
  String get rejectionReasonOptional;

  /// No description provided for @rejectionReasonHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. référence introuvable'**
  String get rejectionReasonHint;

  /// No description provided for @confirmRejection.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le rejet'**
  String get confirmRejection;

  /// No description provided for @paymentApprovedAndActivated.
  ///
  /// In fr, this message translates to:
  /// **'Paiement validé et accès activé.'**
  String get paymentApprovedAndActivated;

  /// No description provided for @paymentRequestRejected.
  ///
  /// In fr, this message translates to:
  /// **'Demande rejetée.'**
  String get paymentRequestRejected;

  /// No description provided for @classesUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Classes indisponibles'**
  String get classesUnavailable;

  /// No description provided for @teacherAnalyticsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Analyses enseignant'**
  String get teacherAnalyticsTitle;

  /// No description provided for @teacherAnalyticsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vue d’ensemble des performances de vos classes.'**
  String get teacherAnalyticsSubtitle;

  /// No description provided for @averageCompletionRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux moyen de complétion'**
  String get averageCompletionRate;

  /// No description provided for @activeClassesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} classes actives'**
  String activeClassesCount(int count);

  /// No description provided for @dailyEngagement.
  ///
  /// In fr, this message translates to:
  /// **'Engagement journalier'**
  String get dailyEngagement;

  /// No description provided for @metricComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Mesure disponible prochainement'**
  String get metricComingSoon;

  /// No description provided for @trackedStudentsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} élèves suivis'**
  String trackedStudentsCount(int count);

  /// No description provided for @weeklyTrend.
  ///
  /// In fr, this message translates to:
  /// **'Tendance hebdomadaire'**
  String get weeklyTrend;

  /// No description provided for @weeklyTrendEmpty.
  ///
  /// In fr, this message translates to:
  /// **'La tendance apparaîtra après la première semaine d’activité de vos élèves.'**
  String get weeklyTrendEmpty;

  /// No description provided for @progressByClass.
  ///
  /// In fr, this message translates to:
  /// **'Progression par classe'**
  String get progressByClass;

  /// No description provided for @noDataAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée disponible.'**
  String get noDataAvailable;

  /// No description provided for @classDetailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Détail de la classe'**
  String get classDetailTitle;

  /// No description provided for @publishAnnouncementShort.
  ///
  /// In fr, this message translates to:
  /// **'Publier annonce'**
  String get publishAnnouncementShort;

  /// No description provided for @studentProgressTitle.
  ///
  /// In fr, this message translates to:
  /// **'Progression élèves'**
  String get studentProgressTitle;

  /// No description provided for @studentTrackingComing.
  ///
  /// In fr, this message translates to:
  /// **'Le suivi individuel arrive : les élèves de cette classe apparaîtront ici avec leur progression dès leurs premières activités.'**
  String get studentTrackingComing;

  /// No description provided for @studyMinutesToday.
  ///
  /// In fr, this message translates to:
  /// **'{count} min aujourd’hui'**
  String studyMinutesToday(int count);

  /// No description provided for @publishAnnouncementTitle.
  ///
  /// In fr, this message translates to:
  /// **'Publier une annonce'**
  String get publishAnnouncementTitle;

  /// No description provided for @titleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get titleLabel;

  /// No description provided for @messageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get messageLabel;

  /// No description provided for @announcementPublished.
  ///
  /// In fr, this message translates to:
  /// **'Annonce publiée.'**
  String get announcementPublished;

  /// No description provided for @publishLabel.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get publishLabel;

  /// No description provided for @myClasses.
  ///
  /// In fr, this message translates to:
  /// **'Mes classes'**
  String get myClasses;

  /// No description provided for @classesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Classes'**
  String get classesLabel;

  /// No description provided for @studentsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} élèves'**
  String studentsCount(int count);

  /// No description provided for @averageProgressPercent.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne progression {percent}%'**
  String averageProgressPercent(int percent);

  /// No description provided for @pendingSubmissionsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} remises en attente'**
  String pendingSubmissionsCount(int count);

  /// No description provided for @contentManagementTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gestion de contenus'**
  String get contentManagementTitle;

  /// No description provided for @publishContentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Publier un contenu'**
  String get publishContentTitle;

  /// No description provided for @classSecondeA.
  ///
  /// In fr, this message translates to:
  /// **'Seconde A'**
  String get classSecondeA;

  /// No description provided for @classSecondeC.
  ///
  /// In fr, this message translates to:
  /// **'Seconde C'**
  String get classSecondeC;

  /// No description provided for @classPremiereD.
  ///
  /// In fr, this message translates to:
  /// **'Première D'**
  String get classPremiereD;

  /// No description provided for @subjectLabel.
  ///
  /// In fr, this message translates to:
  /// **'Matière'**
  String get subjectLabel;

  /// No description provided for @subjectPhysics.
  ///
  /// In fr, this message translates to:
  /// **'Physique'**
  String get subjectPhysics;

  /// No description provided for @lessonTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre de la leçon'**
  String get lessonTitleLabel;

  /// No description provided for @titleRequired.
  ///
  /// In fr, this message translates to:
  /// **'Titre requis'**
  String get titleRequired;

  /// No description provided for @chapterRequired.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre requis'**
  String get chapterRequired;

  /// No description provided for @summaryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Résumé'**
  String get summaryLabel;

  /// No description provided for @summaryRequired.
  ///
  /// In fr, this message translates to:
  /// **'Résumé requis'**
  String get summaryRequired;

  /// No description provided for @publishingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Publication…'**
  String get publishingLabel;

  /// No description provided for @contentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Contenu'**
  String get contentLabel;

  /// No description provided for @contentPublishedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Contenu publié avec succès.'**
  String get contentPublishedSuccess;

  /// No description provided for @quizLabel.
  ///
  /// In fr, this message translates to:
  /// **'Quiz'**
  String get quizLabel;

  /// No description provided for @statisticsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statisticsLabel;

  /// No description provided for @dashboardUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord indisponible'**
  String get dashboardUnavailable;

  /// No description provided for @noClassesYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucune classe pour le moment'**
  String get noClassesYet;

  /// No description provided for @noClassesYetBody.
  ///
  /// In fr, this message translates to:
  /// **'Vos classes apparaîtront ici dès que votre établissement vous les aura assignées. Vous pouvez déjà préparer des quiz depuis l’onglet Quiz.'**
  String get noClassesYetBody;

  /// No description provided for @activeClassesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Classes actives'**
  String get activeClassesTitle;

  /// No description provided for @recentAnnouncements.
  ///
  /// In fr, this message translates to:
  /// **'Annonces récentes'**
  String get recentAnnouncements;

  /// No description provided for @noRecentAnnouncement.
  ///
  /// In fr, this message translates to:
  /// **'Aucune annonce récente.'**
  String get noRecentAnnouncement;

  /// No description provided for @teacherSpaceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Espace Enseignant'**
  String get teacherSpaceTitle;

  /// No description provided for @teacherSpaceDescription.
  ///
  /// In fr, this message translates to:
  /// **'Pilotez vos classes, contenus et évaluations depuis un tableau unique.'**
  String get teacherSpaceDescription;

  /// No description provided for @studentsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Élèves'**
  String get studentsLabel;

  /// No description provided for @completionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Complétion'**
  String get completionLabel;

  /// No description provided for @dailyEngagementShort.
  ///
  /// In fr, this message translates to:
  /// **'Engagement / jour'**
  String get dailyEngagementShort;

  /// No description provided for @quizCreationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Création de quiz'**
  String get quizCreationTitle;

  /// No description provided for @quizCreationSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez une évaluation et publiez-la à vos classes.'**
  String get quizCreationSubtitle;

  /// No description provided for @quizTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre du quiz'**
  String get quizTitleLabel;

  /// No description provided for @questionsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Questions'**
  String get questionsLabel;

  /// No description provided for @addQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une question'**
  String get addQuestion;

  /// No description provided for @publishQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Publier le quiz'**
  String get publishQuiz;

  /// No description provided for @selectClassRequired.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez une classe.'**
  String get selectClassRequired;

  /// No description provided for @addCompleteQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez au moins une question complète.'**
  String get addCompleteQuestion;

  /// No description provided for @quizPublishedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Quiz publié avec succès.'**
  String get quizPublishedSuccess;

  /// No description provided for @questionNumber.
  ///
  /// In fr, this message translates to:
  /// **'Question {index}'**
  String questionNumber(int index);

  /// No description provided for @deleteLabel.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get deleteLabel;

  /// No description provided for @questionPromptLabel.
  ///
  /// In fr, this message translates to:
  /// **'Énoncé'**
  String get questionPromptLabel;

  /// No description provided for @questionPromptHint.
  ///
  /// In fr, this message translates to:
  /// **'Posez la question'**
  String get questionPromptHint;

  /// No description provided for @expectedAnswerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Réponse attendue'**
  String get expectedAnswerLabel;

  /// No description provided for @expectedAnswerHint.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez la réponse'**
  String get expectedAnswerHint;

  /// No description provided for @subjectBiology.
  ///
  /// In fr, this message translates to:
  /// **'SVT'**
  String get subjectBiology;

  /// No description provided for @subjectEnglish.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get subjectEnglish;

  /// No description provided for @subjectHistory.
  ///
  /// In fr, this message translates to:
  /// **'Histoire'**
  String get subjectHistory;

  /// No description provided for @administrationRole.
  ///
  /// In fr, this message translates to:
  /// **'Administration'**
  String get administrationRole;

  /// No description provided for @pendingStatus.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get pendingStatus;

  /// No description provided for @approvedStatus.
  ///
  /// In fr, this message translates to:
  /// **'Approuvé'**
  String get approvedStatus;

  /// No description provided for @hiddenStatus.
  ///
  /// In fr, this message translates to:
  /// **'Masqué'**
  String get hiddenStatus;

  /// No description provided for @publishedStatus.
  ///
  /// In fr, this message translates to:
  /// **'Publié'**
  String get publishedStatus;

  /// No description provided for @aiStatus.
  ///
  /// In fr, this message translates to:
  /// **'IA ✨'**
  String get aiStatus;

  /// No description provided for @draftStatus.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get draftStatus;

  /// No description provided for @audienceWholeSchool.
  ///
  /// In fr, this message translates to:
  /// **'Tout l’établissement'**
  String get audienceWholeSchool;

  /// No description provided for @beginnerDifficulty.
  ///
  /// In fr, this message translates to:
  /// **'Débutant'**
  String get beginnerDifficulty;

  /// No description provided for @intermediateDifficulty.
  ///
  /// In fr, this message translates to:
  /// **'Intermédiaire'**
  String get intermediateDifficulty;

  /// No description provided for @advancedDifficulty.
  ///
  /// In fr, this message translates to:
  /// **'Avancé'**
  String get advancedDifficulty;

  /// No description provided for @expertDifficulty.
  ///
  /// In fr, this message translates to:
  /// **'Expert'**
  String get expertDifficulty;

  /// No description provided for @contentPluralLabel.
  ///
  /// In fr, this message translates to:
  /// **'Contenus'**
  String get contentPluralLabel;

  /// No description provided for @analyticsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Analyses'**
  String get analyticsLabel;

  /// No description provided for @usersLabel.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs'**
  String get usersLabel;

  /// No description provided for @toolsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Outils'**
  String get toolsLabel;

  /// No description provided for @teachersLabel.
  ///
  /// In fr, this message translates to:
  /// **'Enseignants'**
  String get teachersLabel;

  /// No description provided for @parentsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Parents'**
  String get parentsLabel;

  /// No description provided for @dailyActiveUsersShort.
  ///
  /// In fr, this message translates to:
  /// **'Actifs/jour'**
  String get dailyActiveUsersShort;

  /// No description provided for @pendingAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Comptes en attente'**
  String get pendingAccounts;

  /// No description provided for @moderationTickets.
  ///
  /// In fr, this message translates to:
  /// **'Tickets modération'**
  String get moderationTickets;

  /// No description provided for @adminSettingsDescription.
  ///
  /// In fr, this message translates to:
  /// **'Accessibilité, diagnostics et confidentialité'**
  String get adminSettingsDescription;

  /// No description provided for @recentOfficialAnnouncements.
  ///
  /// In fr, this message translates to:
  /// **'Annonces officielles récentes'**
  String get recentOfficialAnnouncements;

  /// No description provided for @moderationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Modération'**
  String get moderationLabel;

  /// No description provided for @administrationAtSchool.
  ///
  /// In fr, this message translates to:
  /// **'Direction • {school}'**
  String administrationAtSchool(String school);

  /// No description provided for @helloUser.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, {name}'**
  String helloUser(String name);

  /// No description provided for @adminHeroDescription.
  ///
  /// In fr, this message translates to:
  /// **'Supervisez l’usage de la plateforme et les opérations critiques.'**
  String get adminHeroDescription;

  /// No description provided for @broadcastCenterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Centre de diffusion'**
  String get broadcastCenterTitle;

  /// No description provided for @broadcastCenterSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Publiez des annonces officielles ciblées.'**
  String get broadcastCenterSubtitle;

  /// No description provided for @audienceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Audience'**
  String get audienceLabel;

  /// No description provided for @messageRequired.
  ///
  /// In fr, this message translates to:
  /// **'Message requis'**
  String get messageRequired;

  /// No description provided for @recentHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique récent'**
  String get recentHistory;

  /// No description provided for @audienceValue.
  ///
  /// In fr, this message translates to:
  /// **'Audience : {audience}'**
  String audienceValue(String audience);

  /// No description provided for @contentModerationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modération des contenus'**
  String get contentModerationTitle;

  /// No description provided for @contentModerationSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Validez ou masquez les contenus signalés.'**
  String get contentModerationSubtitle;

  /// No description provided for @noModerationTicket.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ticket de modération.'**
  String get noModerationTicket;

  /// No description provided for @contentReports.
  ///
  /// In fr, this message translates to:
  /// **'{type} • {count} signalement(s)'**
  String contentReports(String type, int count);

  /// No description provided for @contentHidden.
  ///
  /// In fr, this message translates to:
  /// **'Contenu masqué.'**
  String get contentHidden;

  /// No description provided for @hideLabel.
  ///
  /// In fr, this message translates to:
  /// **'Masquer'**
  String get hideLabel;

  /// No description provided for @contentApproved.
  ///
  /// In fr, this message translates to:
  /// **'Contenu validé.'**
  String get contentApproved;

  /// No description provided for @schoolAnalyticsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Analyses de l’établissement'**
  String get schoolAnalyticsTitle;

  /// No description provided for @activeUsersSevenDays.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs actifs (7 jours)'**
  String get activeUsersSevenDays;

  /// No description provided for @studyMinutesSevenDays.
  ///
  /// In fr, this message translates to:
  /// **'Minutes d’étude cumulées (7 jours)'**
  String get studyMinutesSevenDays;

  /// No description provided for @averageProgressRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de progression moyen'**
  String get averageProgressRate;

  /// No description provided for @metricAvailableAfterActivities.
  ///
  /// In fr, this message translates to:
  /// **'Mesure en construction : disponible après les premières activités des élèves.'**
  String get metricAvailableAfterActivities;

  /// No description provided for @accountApprovalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Validation des comptes'**
  String get accountApprovalTitle;

  /// No description provided for @pendingRequestsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} demande(s) en attente'**
  String pendingRequestsCount(int count);

  /// No description provided for @noPendingRequest.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande en attente.'**
  String get noPendingRequest;

  /// No description provided for @userManagementTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des utilisateurs'**
  String get userManagementTitle;

  /// No description provided for @accountRejected.
  ///
  /// In fr, this message translates to:
  /// **'Compte refusé.'**
  String get accountRejected;

  /// No description provided for @refuseLabel.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get refuseLabel;

  /// No description provided for @accountApproved.
  ///
  /// In fr, this message translates to:
  /// **'Compte validé.'**
  String get accountApproved;

  /// No description provided for @unpublishLabel.
  ///
  /// In fr, this message translates to:
  /// **'Dépublier'**
  String get unpublishLabel;

  /// No description provided for @addChapter.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter chapitre'**
  String get addChapter;

  /// No description provided for @chaptersUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Chapitres indisponibles'**
  String get chaptersUnavailable;

  /// No description provided for @noChapterAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Aucun chapitre.\nAppuyez sur + pour commencer.'**
  String get noChapterAdmin;

  /// No description provided for @newChapter.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau chapitre'**
  String get newChapter;

  /// No description provided for @chapterTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre du chapitre'**
  String get chapterTitleLabel;

  /// No description provided for @shortDescriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description courte'**
  String get shortDescriptionLabel;

  /// No description provided for @createLabel.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get createLabel;

  /// No description provided for @lessonsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} leçon(s)'**
  String lessonsCount(int count);

  /// No description provided for @addLesson.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter leçon'**
  String get addLesson;

  /// No description provided for @lessonsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Leçons indisponibles'**
  String get lessonsUnavailable;

  /// No description provided for @noLessonAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Aucune leçon.\nAppuyez sur + pour créer.'**
  String get noLessonAdmin;

  /// No description provided for @newLesson.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle leçon'**
  String get newLesson;

  /// No description provided for @objectiveSummaryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Objectif / résumé'**
  String get objectiveSummaryLabel;

  /// No description provided for @estimatedDurationMinutes.
  ///
  /// In fr, this message translates to:
  /// **'Durée estimée (min)'**
  String get estimatedDurationMinutes;

  /// No description provided for @lessonSaved.
  ///
  /// In fr, this message translates to:
  /// **'✅ Leçon sauvegardée'**
  String get lessonSaved;

  /// No description provided for @lessonSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'La leçon n’a pas pu être enregistrée. Vérifie la connexion et réessaie.'**
  String get lessonSaveFailed;

  /// No description provided for @lessonPublished.
  ///
  /// In fr, this message translates to:
  /// **'🚀 Leçon publiée !'**
  String get lessonPublished;

  /// No description provided for @publicationFailed.
  ///
  /// In fr, this message translates to:
  /// **'La publication n’a pas abouti. Vérifie la connexion et réessaie.'**
  String get publicationFailed;

  /// No description provided for @newSection.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle section'**
  String get newSection;

  /// No description provided for @courseContentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Contenu du cours'**
  String get courseContentLabel;

  /// No description provided for @lessonEditorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Éditeur de leçon'**
  String get lessonEditorTitle;

  /// No description provided for @aiGeneratedReviewNotice.
  ///
  /// In fr, this message translates to:
  /// **'Contenu généré par l’IA — Relisez avant publication'**
  String get aiGeneratedReviewNotice;

  /// No description provided for @informationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get informationLabel;

  /// No description provided for @learningObjectiveLabel.
  ///
  /// In fr, this message translates to:
  /// **'Objectif pédagogique'**
  String get learningObjectiveLabel;

  /// No description provided for @estimatedDurationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Durée estimée'**
  String get estimatedDurationLabel;

  /// No description provided for @aiGenerationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Génération IA'**
  String get aiGenerationTitle;

  /// No description provided for @aiGenerationBackendOnly.
  ///
  /// In fr, this message translates to:
  /// **'La génération automatique se fait côté serveur, jamais depuis cet écran.'**
  String get aiGenerationBackendOnly;

  /// No description provided for @aiGenerationBackendInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Rédigez la leçon ici. Pour partir de pages de cours photographiées, utilisez « Importer des pages » depuis le chapitre : des brouillons sont préparés, que vous relisez avant publication.'**
  String get aiGenerationBackendInstructions;

  /// No description provided for @courseSectionsCount.
  ///
  /// In fr, this message translates to:
  /// **'Sections du cours ({count})'**
  String courseSectionsCount(int count);

  /// No description provided for @noCourseSection.
  ///
  /// In fr, this message translates to:
  /// **'Aucune section.\nAjoutez-en manuellement.'**
  String get noCourseSection;

  /// No description provided for @miniQuizQuestionsCount.
  ///
  /// In fr, this message translates to:
  /// **'Mini-quiz ({count} questions)'**
  String miniQuizQuestionsCount(int count);

  /// No description provided for @noGeneratedQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Aucune question générée pour cette leçon.'**
  String get noGeneratedQuestion;

  /// No description provided for @quizOptionsCorrectAnswer.
  ///
  /// In fr, this message translates to:
  /// **'{options} options • Réponse : {answer}'**
  String quizOptionsCorrectAnswer(int options, int answer);

  /// No description provided for @quizPublished.
  ///
  /// In fr, this message translates to:
  /// **'🚀 Quiz publié !'**
  String get quizPublished;

  /// No description provided for @quizSaved.
  ///
  /// In fr, this message translates to:
  /// **'✅ Quiz sauvegardé'**
  String get quizSaved;

  /// No description provided for @quizSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le quiz n’a pas pu être enregistré. Vérifie la connexion et réessaie.'**
  String get quizSaveFailed;

  /// No description provided for @newQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau Quiz'**
  String get newQuiz;

  /// No description provided for @editQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Modifier Quiz'**
  String get editQuiz;

  /// No description provided for @quizInformation.
  ///
  /// In fr, this message translates to:
  /// **'Informations du quiz'**
  String get quizInformation;

  /// No description provided for @descriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @difficultyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Difficulté'**
  String get difficultyLabel;

  /// No description provided for @durationSecondsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Durée (sec)'**
  String get durationSecondsLabel;

  /// No description provided for @trainingModeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement'**
  String get trainingModeLabel;

  /// No description provided for @examModeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Examen'**
  String get examModeLabel;

  /// No description provided for @trainingCorrectionDescription.
  ///
  /// In fr, this message translates to:
  /// **'La correction est affichée après chaque réponse validée.'**
  String get trainingCorrectionDescription;

  /// No description provided for @examCorrectionDescription.
  ///
  /// In fr, this message translates to:
  /// **'La correction complète est révélée uniquement après la soumission.'**
  String get examCorrectionDescription;

  /// No description provided for @targetLevels.
  ///
  /// In fr, this message translates to:
  /// **'Niveaux cibles'**
  String get targetLevels;

  /// No description provided for @questionsCount.
  ///
  /// In fr, this message translates to:
  /// **'Questions ({count})'**
  String questionsCount(int count);

  /// No description provided for @noQuestionAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Aucune question.\nAjoutez-en manuellement.'**
  String get noQuestionAdmin;

  /// No description provided for @newQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle question'**
  String get newQuestion;

  /// No description provided for @trueFalseShort.
  ///
  /// In fr, this message translates to:
  /// **'V/F'**
  String get trueFalseShort;

  /// No description provided for @answerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Réponse'**
  String get answerLabel;

  /// No description provided for @optionNumber.
  ///
  /// In fr, this message translates to:
  /// **'Option {number}'**
  String optionNumber(int number);

  /// No description provided for @selectCorrectAnswerInstruction.
  ///
  /// In fr, this message translates to:
  /// **'• Sélectionnez la bonne réponse avec le bouton radio'**
  String get selectCorrectAnswerInstruction;

  /// No description provided for @correctAnswerColon.
  ///
  /// In fr, this message translates to:
  /// **'Réponse correcte :'**
  String get correctAnswerColon;

  /// No description provided for @acceptedAnswersLabel.
  ///
  /// In fr, this message translates to:
  /// **'Réponse(s) acceptée(s) (séparées par ,)'**
  String get acceptedAnswersLabel;

  /// No description provided for @explanationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Explication'**
  String get explanationLabel;

  /// No description provided for @trueFalseLabel.
  ///
  /// In fr, this message translates to:
  /// **'Vrai/Faux'**
  String get trueFalseLabel;

  /// No description provided for @shortAnswerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Réponse courte'**
  String get shortAnswerLabel;

  /// No description provided for @contentStudioTitle.
  ///
  /// In fr, this message translates to:
  /// **'Studio de Contenu'**
  String get contentStudioTitle;

  /// No description provided for @subjectsAndCourses.
  ///
  /// In fr, this message translates to:
  /// **'Matières & Cours'**
  String get subjectsAndCourses;

  /// No description provided for @noSubjectForClass.
  ///
  /// In fr, this message translates to:
  /// **'Aucune matière pour {classLevel}.\nAjoutez-en une pour commencer.'**
  String noSubjectForClass(String classLevel);

  /// No description provided for @chaptersCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} chapitre(s)'**
  String chaptersCount(int count);

  /// No description provided for @noQuizForLevel.
  ///
  /// In fr, this message translates to:
  /// **'Aucun quiz pour ce niveau.'**
  String get noQuizForLevel;

  /// No description provided for @quizQuestionsDifficulty.
  ///
  /// In fr, this message translates to:
  /// **'{count} questions • {difficulty}'**
  String quizQuestionsDifficulty(int count, String difficulty);

  /// No description provided for @generatedByAi.
  ///
  /// In fr, this message translates to:
  /// **'Généré par l’IA'**
  String get generatedByAi;

  /// No description provided for @masteryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton apprentissage'**
  String get masteryTitle;

  /// No description provided for @masteryBySubject.
  ///
  /// In fr, this message translates to:
  /// **'Matière par matière'**
  String get masteryBySubject;

  /// No description provided for @masteryDimension.
  ///
  /// In fr, this message translates to:
  /// **'Maîtrise'**
  String get masteryDimension;

  /// No description provided for @masteryCoverage.
  ///
  /// In fr, this message translates to:
  /// **'Parcours'**
  String get masteryCoverage;

  /// No description provided for @masteryContinuity.
  ///
  /// In fr, this message translates to:
  /// **'Régularité'**
  String get masteryContinuity;

  /// No description provided for @masteryNoEvidence.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore assez d’éléments'**
  String get masteryNoEvidence;

  /// No description provided for @masteryExploring.
  ///
  /// In fr, this message translates to:
  /// **'À explorer'**
  String get masteryExploring;

  /// No description provided for @masteryBuilding.
  ///
  /// In fr, this message translates to:
  /// **'En construction'**
  String get masteryBuilding;

  /// No description provided for @masteryUnderstood.
  ///
  /// In fr, this message translates to:
  /// **'Bien compris'**
  String get masteryUnderstood;

  /// No description provided for @masterySolid.
  ///
  /// In fr, this message translates to:
  /// **'Solide'**
  String get masterySolid;

  /// No description provided for @masteryConfidenceInsufficient.
  ///
  /// In fr, this message translates to:
  /// **'Données insuffisantes'**
  String get masteryConfidenceInsufficient;

  /// No description provided for @masteryConfidenceLimited.
  ///
  /// In fr, this message translates to:
  /// **'Estimation prudente'**
  String get masteryConfidenceLimited;

  /// No description provided for @masteryConfidenceSupported.
  ///
  /// In fr, this message translates to:
  /// **'Confiance étayée'**
  String get masteryConfidenceSupported;

  /// No description provided for @masteryTrendProgressing.
  ///
  /// In fr, this message translates to:
  /// **'Estimation en progression'**
  String get masteryTrendProgressing;

  /// No description provided for @masteryTrendSteady.
  ///
  /// In fr, this message translates to:
  /// **'Estimation stable'**
  String get masteryTrendSteady;

  /// No description provided for @masteryTrendDeclining.
  ///
  /// In fr, this message translates to:
  /// **'Estimation à réexaminer'**
  String get masteryTrendDeclining;

  /// No description provided for @masteryConsolidate.
  ///
  /// In fr, this message translates to:
  /// **'À consolider'**
  String get masteryConsolidate;

  /// No description provided for @masteryRevisit.
  ///
  /// In fr, this message translates to:
  /// **'À revoir'**
  String get masteryRevisit;

  /// No description provided for @masteryNoEvidenceHint.
  ///
  /// In fr, this message translates to:
  /// **'Les réponses aux quiz aideront à construire cette lecture.'**
  String get masteryNoEvidenceHint;

  /// No description provided for @masteryScopeNote.
  ///
  /// In fr, this message translates to:
  /// **'Une estimation issue des quiz, distincte du parcours et des notes scolaires.'**
  String get masteryScopeNote;

  /// No description provided for @masterySourceLimits.
  ///
  /// In fr, this message translates to:
  /// **'Les résultats disponibles ne précisent pas les conditions de passation. Cette lecture reste prudente : « Bien compris » et « Solide » nécessitent des preuves plus complètes.'**
  String get masterySourceLimits;

  /// No description provided for @masteryLoading.
  ///
  /// In fr, this message translates to:
  /// **'Les repères d’apprentissage se chargent.'**
  String get masteryLoading;

  /// No description provided for @masteryUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La lecture de maîtrise est momentanément indisponible.'**
  String get masteryUnavailable;

  /// No description provided for @masterySubjectsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Les matières ne sont pas disponibles pour le moment.'**
  String get masterySubjectsUnavailable;

  /// No description provided for @masterySubjectsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Les matières apparaîtront ici quand le programme sera disponible.'**
  String get masterySubjectsEmpty;

  /// No description provided for @masteryStudentCollecting.
  ///
  /// In fr, this message translates to:
  /// **'INTELLIA237 commence à construire ton profil d’apprentissage. Continue à travailler et à répondre aux exercices.'**
  String get masteryStudentCollecting;

  /// No description provided for @masteryStudentFirst.
  ///
  /// In fr, this message translates to:
  /// **'Tes réponses aux quiz donnent de premiers repères. Cette lecture reste prudente et se précisera avec de nouvelles preuves.'**
  String get masteryStudentFirst;

  /// No description provided for @masteryStudentProgress.
  ///
  /// In fr, this message translates to:
  /// **'Une estimation a évolué avec de nouveaux résultats de quiz. Retrouve ce changement dans les matières ci-dessous.'**
  String get masteryStudentProgress;

  /// No description provided for @masteryParentCollecting.
  ///
  /// In fr, this message translates to:
  /// **'Il n’y a pas encore assez d’éléments pour lire ses acquis. Vous pouvez déjà l’encourager à expliquer ce qu’il apprend.'**
  String get masteryParentCollecting;

  /// No description provided for @masteryParentFirst.
  ///
  /// In fr, this message translates to:
  /// **'Les quiz donnent de premiers repères sur son apprentissage. Les estimations restent prudentes.'**
  String get masteryParentFirst;

  /// No description provided for @masteryParentProgress.
  ///
  /// In fr, this message translates to:
  /// **'De nouveaux résultats de quiz font évoluer une estimation. Cette comparaison porte seulement sur les observations disponibles.'**
  String get masteryParentProgress;

  /// No description provided for @masteryParentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment avance son apprentissage ?'**
  String get masteryParentTitle;

  /// No description provided for @masteryParentEvolving.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui évolue'**
  String get masteryParentEvolving;

  /// No description provided for @masteryParentNoComparison.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de comparaison suffisamment étayée.'**
  String get masteryParentNoComparison;

  /// No description provided for @masteryParentSupport.
  ///
  /// In fr, this message translates to:
  /// **'À accompagner'**
  String get masteryParentSupport;

  /// No description provided for @masteryParentSupportBody.
  ///
  /// In fr, this message translates to:
  /// **'Poursuivre les exercices aidera à préciser cette lecture.'**
  String get masteryParentSupportBody;

  /// No description provided for @masteryParentContinuity.
  ///
  /// In fr, this message translates to:
  /// **'Continuité du parcours'**
  String get masteryParentContinuity;

  /// No description provided for @masteryParentNoPattern.
  ///
  /// In fr, this message translates to:
  /// **'Les données disponibles ne permettent pas encore de décrire une régularité.'**
  String get masteryParentNoPattern;

  /// No description provided for @masteryParentHelp.
  ///
  /// In fr, this message translates to:
  /// **'Comment l’aider'**
  String get masteryParentHelp;

  /// No description provided for @masteryParentHelpBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez lui demander quelle notion lui a semblé difficile et l’inviter à l’expliquer avec ses mots.'**
  String get masteryParentHelpBody;

  /// No description provided for @masteryCoverageNote.
  ///
  /// In fr, this message translates to:
  /// **'Explorer un cours ne prouve pas encore qu’il est compris.'**
  String get masteryCoverageNote;

  /// No description provided for @masteryCoverageUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le parcours n’est pas disponible pour le moment.'**
  String get masteryCoverageUnavailable;

  /// No description provided for @masteryChapterDetailPending.
  ///
  /// In fr, this message translates to:
  /// **'Le détail des acquis par chapitre viendra avec des preuves rattachées aux chapitres. Aucune maîtrise de chapitre n’est déduite de la lecture.'**
  String get masteryChapterDetailPending;

  /// No description provided for @masteryRecentActivity.
  ///
  /// In fr, this message translates to:
  /// **'Résultats de quiz disponibles'**
  String get masteryRecentActivity;

  /// No description provided for @masteryRecentLimits.
  ///
  /// In fr, this message translates to:
  /// **'Seul le dernier résultat de chaque quiz est conservé dans cette lecture. Ce n’est pas l’historique de toutes les tentatives.'**
  String get masteryRecentLimits;

  /// No description provided for @masteryRecordedQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Quiz corrigé'**
  String get masteryRecordedQuiz;

  /// No description provided for @masteryOpenCourse.
  ///
  /// In fr, this message translates to:
  /// **'Retrouver le cours'**
  String get masteryOpenCourse;

  /// No description provided for @masteryScaleLegend.
  ///
  /// In fr, this message translates to:
  /// **'L’étendue de l’encre indique l’état, sa densité la confiance. Un tracé apparaît seulement lorsqu’une estimation antérieure a réellement été observée.'**
  String get masteryScaleLegend;

  /// No description provided for @masteryOfficialRecord.
  ///
  /// In fr, this message translates to:
  /// **'Carnet officiel'**
  String get masteryOfficialRecord;

  /// No description provided for @masteryOfficialRecordBody.
  ///
  /// In fr, this message translates to:
  /// **'Les notes scolaires restent des résultats officiels de l’établissement. Elles ne sont pas calculées à partir de cette estimation.'**
  String get masteryOfficialRecordBody;

  /// No description provided for @masteryOfficialRecordUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun carnet de notes scolaires n’est relié à cette vue pour le moment.'**
  String get masteryOfficialRecordUnavailable;

  /// No description provided for @masteryRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser les repères'**
  String get masteryRefresh;

  /// No description provided for @masteryEvidenceCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun résultat exploitable} =1{1 quiz distinct pris en compte} other{{count} quiz distincts pris en compte}}'**
  String masteryEvidenceCount(int count);

  /// No description provided for @masteryExploredChapters.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun chapitre exploré} =1{1 chapitre exploré} other{{count} chapitres explorés}}'**
  String masteryExploredChapters(int count);

  /// No description provided for @masteryExploredLessons.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune leçon explorée enregistrée} =1{1 leçon explorée enregistrée} other{{count} leçons explorées enregistrées}}'**
  String masteryExploredLessons(int count);

  /// No description provided for @masteryPartialCoverage.
  ///
  /// In fr, this message translates to:
  /// **'Ce parcours porte sur une partie des leçons enregistrées.'**
  String get masteryPartialCoverage;

  /// No description provided for @masteryRecordedStreak.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Série d’activité enregistrée : 1 jour} other{Série d’activité enregistrée : {count} jours}}'**
  String masteryRecordedStreak(int count);

  /// No description provided for @masteryPreviousState.
  ///
  /// In fr, this message translates to:
  /// **'Tracé précédent : {state}'**
  String masteryPreviousState(String state);

  /// No description provided for @masteryLastEvidence.
  ///
  /// In fr, this message translates to:
  /// **'Dernier résultat enregistré : {date}'**
  String masteryLastEvidence(String date);

  /// No description provided for @masteryDeclaredSchool.
  ///
  /// In fr, this message translates to:
  /// **'Établissement déclaré : {name}'**
  String masteryDeclaredSchool(String name);

  /// No description provided for @masteryWithCompanion.
  ///
  /// In fr, this message translates to:
  /// **'Avec {name}'**
  String masteryWithCompanion(String name);

  /// No description provided for @masteryEvidenceWindow.
  ///
  /// In fr, this message translates to:
  /// **'Résultats des {days} derniers jours.'**
  String masteryEvidenceWindow(int days);

  /// No description provided for @passWelcomeBack.
  ///
  /// In fr, this message translates to:
  /// **'REPRENDRE SA PLACE'**
  String get passWelcomeBack;

  /// No description provided for @passSignIn.
  ///
  /// In fr, this message translates to:
  /// **'CONNEXION'**
  String get passSignIn;

  /// No description provided for @passGoodToSeeYouAgain.
  ///
  /// In fr, this message translates to:
  /// **'Heureux de vous retrouver.'**
  String get passGoodToSeeYouAgain;

  /// No description provided for @passLinkSent.
  ///
  /// In fr, this message translates to:
  /// **'LIEN ENVOYÉ'**
  String get passLinkSent;

  /// No description provided for @passRecoverMyAccess.
  ///
  /// In fr, this message translates to:
  /// **'RÉCUPÉRER MON ACCÈS'**
  String get passRecoverMyAccess;

  /// No description provided for @passForgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'MOT DE PASSE OUBLIÉ'**
  String get passForgotPassword;

  /// No description provided for @passOneLinkThenYouReBack.
  ///
  /// In fr, this message translates to:
  /// **'Un lien.\nEt tu reprends.'**
  String get passOneLinkThenYouReBack;

  /// No description provided for @passFindYourWayBack.
  ///
  /// In fr, this message translates to:
  /// **'Retrouve\nton accès.'**
  String get passFindYourWayBack;

  /// No description provided for @passTheNextStepIsWaitingIn.
  ///
  /// In fr, this message translates to:
  /// **'La prochaine étape t’attend dans ta messagerie.'**
  String get passTheNextStepIsWaitingIn;

  /// No description provided for @passEmailAccess.
  ///
  /// In fr, this message translates to:
  /// **'ACCÈS PAR EMAIL'**
  String get passEmailAccess;

  /// No description provided for @passYourNextChapterAwaits.
  ///
  /// In fr, this message translates to:
  /// **'La suite\nt’attend.'**
  String get passYourNextChapterAwaits;

  /// No description provided for @passReturnToYourSpaceWithYour.
  ///
  /// In fr, this message translates to:
  /// **'Retrouve ton espace avec ton email et ton mot de passe.'**
  String get passReturnToYourSpaceWithYour;

  /// No description provided for @passChooseAnotherWayIn.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un autre accès'**
  String get passChooseAnotherWayIn;

  /// No description provided for @passYourNumber.
  ///
  /// In fr, this message translates to:
  /// **'TON NUMÉRO'**
  String get passYourNumber;

  /// No description provided for @passVerificationInProgress.
  ///
  /// In fr, this message translates to:
  /// **'VÉRIFICATION EN COURS'**
  String get passVerificationInProgress;

  /// No description provided for @passNumberVerified.
  ///
  /// In fr, this message translates to:
  /// **'NUMÉRO VÉRIFIÉ'**
  String get passNumberVerified;

  /// No description provided for @passPhoneAccess.
  ///
  /// In fr, this message translates to:
  /// **'ACCÈS PAR TÉLÉPHONE'**
  String get passPhoneAccess;

  /// No description provided for @passSixDigitsThenWeContinue.
  ///
  /// In fr, this message translates to:
  /// **'Six chiffres.\nEt on continue.'**
  String get passSixDigitsThenWeContinue;

  /// No description provided for @passYourNumberIsConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Ton numéro\nest confirmé.'**
  String get passYourNumberIsConfirmed;

  /// No description provided for @passYourNumberYourAccess.
  ///
  /// In fr, this message translates to:
  /// **'Ton numéro.\nTon accès.'**
  String get passYourNumberYourAccess;

  /// No description provided for @passChooseYourSpace.
  ///
  /// In fr, this message translates to:
  /// **'01 / CHOISIR SON ESPACE'**
  String get passChooseYourSpace;

  /// No description provided for @passCreateAnAccount.
  ///
  /// In fr, this message translates to:
  /// **'CRÉER UN COMPTE'**
  String get passCreateAnAccount;

  /// No description provided for @passYourPlaceStartsHere.
  ///
  /// In fr, this message translates to:
  /// **'Votre place commence ici.'**
  String get passYourPlaceStartsHere;

  /// No description provided for @passChooseYourSpaceYourPassTakes.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre espace. Votre Pass prend forme avec vous.'**
  String get passChooseYourSpaceYourPassTakes;

  /// No description provided for @passRegistrationComplete.
  ///
  /// In fr, this message translates to:
  /// **'INSCRIPTION TERMINÉE'**
  String get passRegistrationComplete;

  /// No description provided for @passYourPlaceIsReady.
  ///
  /// In fr, this message translates to:
  /// **'TA PLACE\nEST PRÊTE.'**
  String get passYourPlaceIsReady;

  /// No description provided for @passYourSpace.
  ///
  /// In fr, this message translates to:
  /// **'Votre espace'**
  String get passYourSpace;

  /// No description provided for @passPassReady.
  ///
  /// In fr, this message translates to:
  /// **'PASS PRÊT'**
  String get passPassReady;

  /// No description provided for @passTakingShape.
  ///
  /// In fr, this message translates to:
  /// **'EN CONSTRUCTION'**
  String get passTakingShape;

  /// No description provided for @passAPlaceForYou.
  ///
  /// In fr, this message translates to:
  /// **'Une place pour vous.'**
  String get passAPlaceForYou;

  /// No description provided for @passYourFamilySpace.
  ///
  /// In fr, this message translates to:
  /// **'Votre espace famille'**
  String get passYourFamilySpace;

  /// No description provided for @passYourTeachingSpace.
  ///
  /// In fr, this message translates to:
  /// **'Votre espace enseignant'**
  String get passYourTeachingSpace;

  /// No description provided for @passValidationPending.
  ///
  /// In fr, this message translates to:
  /// **'Validation en attente'**
  String get passValidationPending;

  /// No description provided for @passAccountCreated.
  ///
  /// In fr, this message translates to:
  /// **'COMPTE CRÉÉ.'**
  String get passAccountCreated;

  /// No description provided for @passChildIdentifiersAdded.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 identifiant ajouté} other{{count} identifiants ajoutés}}'**
  String passChildIdentifiersAdded(int count);

  /// No description provided for @passWithCompanion.
  ///
  /// In fr, this message translates to:
  /// **'Avec {companion}'**
  String passWithCompanion(String companion);

  /// No description provided for @authorSignature.
  ///
  /// In fr, this message translates to:
  /// **'Application conçue par Calvin EKENA · +237 699 98 90 99'**
  String get authorSignature;

  /// No description provided for @schoolHeadShieldTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Espace direction d’établissement'**
  String get schoolHeadShieldTooltip;

  /// No description provided for @schoolHeadSheetEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'ESPACE DIRECTION'**
  String get schoolHeadSheetEyebrow;

  /// No description provided for @schoolHeadSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre école,\nen entier.'**
  String get schoolHeadSheetTitle;

  /// No description provided for @schoolHeadSheetBody.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour administrer toute votre école : personnel, classes, contenus et suivi. Les comptes des élèves restent les leurs : vous ne pouvez ni en ajouter ni en supprimer.'**
  String get schoolHeadSheetBody;

  /// No description provided for @schoolHeadContinueEmail.
  ///
  /// In fr, this message translates to:
  /// **'Continuer par e-mail'**
  String get schoolHeadContinueEmail;

  /// No description provided for @schoolHeadContinuePhone.
  ///
  /// In fr, this message translates to:
  /// **'Continuer par téléphone'**
  String get schoolHeadContinuePhone;

  /// No description provided for @schoolHeadPhoneNote.
  ///
  /// In fr, this message translates to:
  /// **'Le téléphone fonctionne une fois votre numéro rattaché à votre compte, depuis vos paramètres.'**
  String get schoolHeadPhoneNote;

  /// No description provided for @schoolHeadRequestAccess.
  ///
  /// In fr, this message translates to:
  /// **'Demander un accès pour mon école'**
  String get schoolHeadRequestAccess;

  /// No description provided for @schoolDirectoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuaire de l’école'**
  String get schoolDirectoryTitle;

  /// No description provided for @schoolDirectoryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Personne dans cette catégorie pour le moment.'**
  String get schoolDirectoryEmpty;

  /// No description provided for @schoolDirectoryStudentsNote.
  ///
  /// In fr, this message translates to:
  /// **'Les élèves rejoignent l’école par leur propre inscription : la direction les consulte, sans les ajouter ni les retirer.'**
  String get schoolDirectoryStudentsNote;

  /// No description provided for @schoolDirectoryLoadMore.
  ///
  /// In fr, this message translates to:
  /// **'Voir plus'**
  String get schoolDirectoryLoadMore;

  /// No description provided for @schoolDirectoryPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente de validation'**
  String get schoolDirectoryPending;

  /// No description provided for @schoolClassesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Classes de l’école'**
  String get schoolClassesTitle;

  /// No description provided for @schoolClassesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune classe n’est encore ouverte pour votre école.'**
  String get schoolClassesEmpty;

  /// No description provided for @schoolClassCounts.
  ///
  /// In fr, this message translates to:
  /// **'Élèves : {students} · Enseignants : {teachers}'**
  String schoolClassCounts(int students, int teachers);

  /// No description provided for @renameClassLabel.
  ///
  /// In fr, this message translates to:
  /// **'Renommer la classe'**
  String get renameClassLabel;

  /// No description provided for @classNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la classe'**
  String get classNameLabel;

  /// No description provided for @reviewNoSchool.
  ///
  /// In fr, this message translates to:
  /// **'Aucune école rattachée'**
  String get reviewNoSchool;

  /// No description provided for @reviewAttachSchoolTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rattacher à une école'**
  String get reviewAttachSchoolTitle;

  /// No description provided for @reviewAttachSchoolBody.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte n’appartient encore à aucune école. Choisissez la sienne pour l’approuver.'**
  String get reviewAttachSchoolBody;

  /// No description provided for @reviewCreateSchool.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir une nouvelle école'**
  String get reviewCreateSchool;

  /// No description provided for @reviewCreateSchoolAction.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir et rattacher'**
  String get reviewCreateSchoolAction;

  /// No description provided for @accountReviewFailed.
  ///
  /// In fr, this message translates to:
  /// **'La décision n’a pas pu être enregistrée. Réessayez.'**
  String get accountReviewFailed;

  /// No description provided for @adminPhoneLinkTitle.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter aussi par téléphone'**
  String get adminPhoneLinkTitle;

  /// No description provided for @adminPhoneLinkBody.
  ///
  /// In fr, this message translates to:
  /// **'Rattachez votre numéro pour recevoir un code à chaque connexion.'**
  String get adminPhoneLinkBody;

  /// No description provided for @unattachedStaffTitle.
  ///
  /// In fr, this message translates to:
  /// **'Personnel sans école'**
  String get unattachedStaffTitle;

  /// No description provided for @unattachedStaffBody.
  ///
  /// In fr, this message translates to:
  /// **'Ces comptes ont été approuvés avant d’être rattachés. Sans école, ils ne composent ni ne gèrent rien pour elle.'**
  String get unattachedStaffBody;

  /// No description provided for @unattachedStaffEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Tout le personnel approuvé a son école.'**
  String get unattachedStaffEmpty;

  /// No description provided for @attachStaffAction.
  ///
  /// In fr, this message translates to:
  /// **'Rattacher'**
  String get attachStaffAction;

  /// No description provided for @attachStaffSheetBody.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez l’école de ce compte. Une fois rattaché, il ne changera plus d’école depuis l’application.'**
  String get attachStaffSheetBody;

  /// No description provided for @staffAttached.
  ///
  /// In fr, this message translates to:
  /// **'Compte rattaché. La personne retrouve son école à sa prochaine ouverture de l’application.'**
  String get staffAttached;

  /// No description provided for @schoolNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Donnez le nom complet de l’école.'**
  String get schoolNameRequired;

  /// No description provided for @schoolCityRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez la ville de l’école.'**
  String get schoolCityRequired;

  /// No description provided for @schoolCityHelper.
  ///
  /// In fr, this message translates to:
  /// **'Saisie libre, par exemple Douala ou Bafoussam.'**
  String get schoolCityHelper;

  /// No description provided for @schoolTransferTitle.
  ///
  /// In fr, this message translates to:
  /// **'Changer un compte d’école'**
  String get schoolTransferTitle;

  /// No description provided for @schoolTransferBody.
  ///
  /// In fr, this message translates to:
  /// **'Erreur à l’inscription, déménagement, mutation : retrouvez l’élève, le parent ou le membre du personnel par son e-mail ou son téléphone.'**
  String get schoolTransferBody;

  /// No description provided for @schoolTransferQueryLabel.
  ///
  /// In fr, this message translates to:
  /// **'E-mail ou téléphone'**
  String get schoolTransferQueryLabel;

  /// No description provided for @schoolTransferQueryHint.
  ///
  /// In fr, this message translates to:
  /// **'699 98 90 99 ou nom@exemple.cm'**
  String get schoolTransferQueryHint;

  /// No description provided for @schoolTransferSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get schoolTransferSearch;

  /// No description provided for @schoolTransferNoResult.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte ne correspond. Vérifiez l’e-mail ou le numéro.'**
  String get schoolTransferNoResult;

  /// No description provided for @schoolTransferCurrentSchool.
  ///
  /// In fr, this message translates to:
  /// **'École : {school}'**
  String schoolTransferCurrentSchool(String school);

  /// No description provided for @schoolTransferDeclared.
  ///
  /// In fr, this message translates to:
  /// **'Déclarée à l’inscription : {school}'**
  String schoolTransferDeclared(String school);

  /// No description provided for @schoolTransferMove.
  ///
  /// In fr, this message translates to:
  /// **'Changer d’école'**
  String get schoolTransferMove;

  /// No description provided for @schoolTransferAttachBody.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez l’école de ce compte.'**
  String get schoolTransferAttachBody;

  /// No description provided for @schoolTransferMoveBody.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la nouvelle école. Ce compte quittera les classes de son ancienne école.'**
  String get schoolTransferMoveBody;

  /// No description provided for @schoolTransferReasonTitle.
  ///
  /// In fr, this message translates to:
  /// **'Motif du changement'**
  String get schoolTransferReasonTitle;

  /// No description provided for @schoolTransferReasonHint.
  ///
  /// In fr, this message translates to:
  /// **'Par exemple : erreur du parent à l’inscription'**
  String get schoolTransferReasonHint;

  /// No description provided for @schoolTransferConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le changement'**
  String get schoolTransferConfirm;

  /// No description provided for @schoolTransferDone.
  ///
  /// In fr, this message translates to:
  /// **'École mise à jour. La personne la retrouve à sa prochaine ouverture de l’application.'**
  String get schoolTransferDone;

  /// No description provided for @schoolTransferSameSchool.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte appartient déjà à cette école.'**
  String get schoolTransferSameSchool;

  /// No description provided for @schoolTransferChildren.
  ///
  /// In fr, this message translates to:
  /// **'Enfants liés'**
  String get schoolTransferChildren;

  /// No description provided for @generalAdministrationAllSchools.
  ///
  /// In fr, this message translates to:
  /// **'Administration générale · toutes les écoles'**
  String get generalAdministrationAllSchools;

  /// No description provided for @broadcastTargetSchool.
  ///
  /// In fr, this message translates to:
  /// **'École destinataire'**
  String get broadcastTargetSchool;

  /// No description provided for @broadcastTargetSchoolRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez l’école destinataire.'**
  String get broadcastTargetSchoolRequired;

  /// No description provided for @announcementFailed.
  ///
  /// In fr, this message translates to:
  /// **'L’annonce n’a pas pu être publiée. Réessayez.'**
  String get announcementFailed;

  /// No description provided for @schoolsOverviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Écoles'**
  String get schoolsOverviewTitle;

  /// No description provided for @schoolsOverviewBody.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les écoles d’INTELLIA237. Touchez-en une pour voir son annuaire et ses classes.'**
  String get schoolsOverviewBody;

  /// No description provided for @schoolsOverviewCreate.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir une école'**
  String get schoolsOverviewCreate;

  /// No description provided for @schoolsOverviewEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune école n’est encore ouverte.'**
  String get schoolsOverviewEmpty;

  /// No description provided for @schoolsOverviewHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une école existante, ou ouvrez-en une nouvelle avec sa ville.'**
  String get schoolsOverviewHint;

  /// No description provided for @parentPreviewBadge.
  ///
  /// In fr, this message translates to:
  /// **'Prévisualisation Parent'**
  String get parentPreviewBadge;

  /// No description provided for @parentPreviewExit.
  ///
  /// In fr, this message translates to:
  /// **'Quitter l’aperçu'**
  String get parentPreviewExit;

  /// No description provided for @parentPreviewViewingParent.
  ///
  /// In fr, this message translates to:
  /// **'Espace de {name}'**
  String parentPreviewViewingParent(String name);

  /// No description provided for @parentPreviewOwnAccountNote.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu de votre propre espace Parent.'**
  String get parentPreviewOwnAccountNote;

  /// No description provided for @adminParentPreviewAction.
  ///
  /// In fr, this message translates to:
  /// **'Prévisualiser l’espace Parent'**
  String get adminParentPreviewAction;

  /// No description provided for @adminParentPreviewDescription.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir l’espace Parent en tant que super-administrateur, sans changer de compte.'**
  String get adminParentPreviewDescription;

  /// No description provided for @parentPreviewChooseParent.
  ///
  /// In fr, this message translates to:
  /// **'Prévisualiser en tant que'**
  String get parentPreviewChooseParent;

  /// No description provided for @parentPreviewOwnAccount.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte (super-admin)'**
  String get parentPreviewOwnAccount;

  /// No description provided for @parentPreviewNoParents.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte parent à prévisualiser pour l’instant.'**
  String get parentPreviewNoParents;

  /// No description provided for @parentPreviewPaymentsBlockedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement indisponible en prévisualisation'**
  String get parentPreviewPaymentsBlockedTitle;

  /// No description provided for @parentPreviewPaymentsBlockedBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous consultez l’espace d’un autre parent : pour protéger ses données, aucune opération de paiement n’est possible ici.'**
  String get parentPreviewPaymentsBlockedBody;

  /// No description provided for @addChildTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un enfant'**
  String get addChildTitle;

  /// No description provided for @addChildCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code de liaison de l’enfant'**
  String get addChildCodeLabel;

  /// No description provided for @addChildCodeHelp.
  ///
  /// In fr, this message translates to:
  /// **'Demande à ton enfant son code, visible dans son espace Profil › « Mon code parent ».'**
  String get addChildCodeHelp;

  /// No description provided for @addChildSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Lier l’enfant'**
  String get addChildSubmit;

  /// No description provided for @addChildSuccess.
  ///
  /// In fr, this message translates to:
  /// **'{name} est maintenant lié à ton compte.'**
  String addChildSuccess(String name);

  /// No description provided for @addChildAlready.
  ///
  /// In fr, this message translates to:
  /// **'{name} est déjà lié à ton compte.'**
  String addChildAlready(String name);

  /// No description provided for @studentLinkCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon code parent'**
  String get studentLinkCodeTitle;

  /// No description provided for @studentLinkCodeBody.
  ///
  /// In fr, this message translates to:
  /// **'Communique ce code à ton parent pour qu’il puisse suivre ta progression.'**
  String get studentLinkCodeBody;

  /// No description provided for @studentLinkCodeCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier le code'**
  String get studentLinkCodeCopy;

  /// No description provided for @studentLinkCodeCopied.
  ///
  /// In fr, this message translates to:
  /// **'Code copié.'**
  String get studentLinkCodeCopied;

  /// No description provided for @studentLinkCodeError.
  ///
  /// In fr, this message translates to:
  /// **'Le code n’a pas pu être généré. Réessaie.'**
  String get studentLinkCodeError;

  /// No description provided for @studentLinkCodeRotate.
  ///
  /// In fr, this message translates to:
  /// **'Régénérer le code'**
  String get studentLinkCodeRotate;

  /// No description provided for @studentLinkCodeRotateConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Régénérer le code ?'**
  String get studentLinkCodeRotateConfirmTitle;

  /// No description provided for @studentLinkCodeRotateConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'L’ancien code cessera immédiatement de fonctionner. Les parents déjà liés le restent.'**
  String get studentLinkCodeRotateConfirmBody;

  /// No description provided for @studentLinkCodeRotated.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code généré.'**
  String get studentLinkCodeRotated;

  /// No description provided for @createClassLabel.
  ///
  /// In fr, this message translates to:
  /// **'Créer une classe'**
  String get createClassLabel;

  /// No description provided for @classLevelLabel.
  ///
  /// In fr, this message translates to:
  /// **'Niveau'**
  String get classLevelLabel;

  /// No description provided for @classSeriesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Série (optionnel)'**
  String get classSeriesLabel;

  /// No description provided for @classTrackLabel.
  ///
  /// In fr, this message translates to:
  /// **'Filière (optionnel)'**
  String get classTrackLabel;

  /// No description provided for @classSeriesNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get classSeriesNone;

  /// No description provided for @deleteClassLabel.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la classe'**
  String get deleteClassLabel;

  /// No description provided for @deleteClassConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {name} » ? Cette classe est vide.'**
  String deleteClassConfirm(String name);

  /// No description provided for @deleteClassBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Classe non vide : retirez d’abord les élèves.'**
  String get deleteClassBlocked;

  /// No description provided for @classCreatedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Classe créée.'**
  String get classCreatedMessage;

  /// No description provided for @classDeletedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Classe supprimée.'**
  String get classDeletedMessage;

  /// No description provided for @editEstablishmentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l’école'**
  String get editEstablishmentLabel;

  /// No description provided for @archiveEstablishmentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Archiver l’école'**
  String get archiveEstablishmentLabel;

  /// No description provided for @unarchiveEstablishmentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Réactiver l’école'**
  String get unarchiveEstablishmentLabel;

  /// No description provided for @establishmentArchivedBadge.
  ///
  /// In fr, this message translates to:
  /// **'Archivée'**
  String get establishmentArchivedBadge;

  /// No description provided for @establishmentCityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get establishmentCityLabel;

  /// No description provided for @flowChoiceTrue.
  ///
  /// In fr, this message translates to:
  /// **'Vrai'**
  String get flowChoiceTrue;

  /// No description provided for @flowChoiceFalse.
  ///
  /// In fr, this message translates to:
  /// **'Faux'**
  String get flowChoiceFalse;

  /// No description provided for @flowHintPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Indice : {hint}'**
  String flowHintPrefix(String hint);

  /// No description provided for @flowFeedbackCorrect.
  ///
  /// In fr, this message translates to:
  /// **'Exact !'**
  String get flowFeedbackCorrect;

  /// No description provided for @flowFeedbackIncorrect.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore.'**
  String get flowFeedbackIncorrect;

  /// No description provided for @flowExpectedOrder.
  ///
  /// In fr, this message translates to:
  /// **'Ordre attendu : {order}'**
  String flowExpectedOrder(String order);

  /// No description provided for @flowSwipeToContinue.
  ///
  /// In fr, this message translates to:
  /// **'Balaie vers le haut pour continuer'**
  String get flowSwipeToContinue;

  /// No description provided for @childLinkErrorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ce code enfant est introuvable. Vérifie-le avec ton enfant.'**
  String get childLinkErrorNotFound;

  /// No description provided for @childLinkErrorInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Saisis le code de liaison de ton enfant.'**
  String get childLinkErrorInvalid;

  /// No description provided for @childLinkErrorPermission.
  ///
  /// In fr, this message translates to:
  /// **'Seul un compte parent peut rattacher un enfant.'**
  String get childLinkErrorPermission;

  /// No description provided for @childLinkErrorUnauthenticated.
  ///
  /// In fr, this message translates to:
  /// **'Ta session a expiré. Reconnecte-toi puis réessaie.'**
  String get childLinkErrorUnauthenticated;

  /// No description provided for @childLinkErrorTooMany.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Réessaie un peu plus tard.'**
  String get childLinkErrorTooMany;

  /// No description provided for @childLinkErrorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'La liaison n’a pas abouti. Réessaie dans un instant.'**
  String get childLinkErrorGeneric;

  /// No description provided for @studyReserveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réserve d’étude'**
  String get studyReserveTitle;

  /// No description provided for @studyReserveRemaining.
  ///
  /// In fr, this message translates to:
  /// **'{percent} % restants'**
  String studyReserveRemaining(int percent);

  /// No description provided for @studyReserveRenews.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement le {date}'**
  String studyReserveRenews(String date);

  /// No description provided for @studyReserveStatusHealthy.
  ///
  /// In fr, this message translates to:
  /// **'Bonne réserve'**
  String get studyReserveStatusHealthy;

  /// No description provided for @studyReserveStatusWarning.
  ///
  /// In fr, this message translates to:
  /// **'À surveiller'**
  String get studyReserveStatusWarning;

  /// No description provided for @studyReserveStatusLow.
  ///
  /// In fr, this message translates to:
  /// **'Réserve basse'**
  String get studyReserveStatusLow;

  /// No description provided for @studyReserveStatusCritical.
  ///
  /// In fr, this message translates to:
  /// **'Presque épuisée'**
  String get studyReserveStatusCritical;

  /// No description provided for @studyReserveStatusDepleted.
  ///
  /// In fr, this message translates to:
  /// **'Réserve épuisée'**
  String get studyReserveStatusDepleted;

  /// No description provided for @studyReserveDepletedHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le tuteur IA se repose jusqu’au renouvellement. Les cours, quiz et lectures restent accessibles.'**
  String get studyReserveDepletedHelp;

  /// No description provided for @studyReserveUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Réserve d’étude indisponible pour le moment.'**
  String get studyReserveUnavailable;

  /// No description provided for @studyReserveNotifTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réserve d’étude'**
  String get studyReserveNotifTitle;

  /// No description provided for @studyReserveNotifInfo.
  ///
  /// In fr, this message translates to:
  /// **'Il reste {percent} % de la réserve d’étude ce cycle.'**
  String studyReserveNotifInfo(int percent);

  /// No description provided for @studyReserveNotifLow.
  ///
  /// In fr, this message translates to:
  /// **'La réserve d’étude est à {percent} %. Pense à la ménager pour le tuteur.'**
  String studyReserveNotifLow(int percent);

  /// No description provided for @studyReserveNotifCritical.
  ///
  /// In fr, this message translates to:
  /// **'La réserve d’étude est presque épuisée ({percent} %).'**
  String studyReserveNotifCritical(int percent);

  /// No description provided for @studyReserveNotifDepleted.
  ///
  /// In fr, this message translates to:
  /// **'La réserve d’étude est épuisée ; elle se renouvelle au prochain cycle. Les cours et quiz restent accessibles.'**
  String get studyReserveNotifDepleted;

  /// No description provided for @studyReserveLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la réserve d’étude pour le moment.'**
  String get studyReserveLoadError;

  /// No description provided for @companionStudyReserveDepleted.
  ///
  /// In fr, this message translates to:
  /// **'Ta réserve d’étude est épuisée pour ce cycle. {name} reprendra au renouvellement ; tes cours et quiz restent accessibles.'**
  String companionStudyReserveDepleted(String name);

  /// No description provided for @parentEntryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Reliez votre enfant'**
  String get parentEntryTitle;

  /// No description provided for @parentEntrySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez son code, puis connectez-vous avec votre propre numéro.'**
  String get parentEntrySubtitle;

  /// No description provided for @parentEntryHaveCode.
  ///
  /// In fr, this message translates to:
  /// **'J’ai un code enfant'**
  String get parentEntryHaveCode;

  /// No description provided for @parentEntryCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code de l’enfant'**
  String get parentEntryCodeLabel;

  /// No description provided for @parentEntryCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. K7MP2QXA'**
  String get parentEntryCodeHint;

  /// No description provided for @parentEntryCodeHelp.
  ///
  /// In fr, this message translates to:
  /// **'Votre enfant le trouve dans son profil, rubrique « Mon code parent ».'**
  String get parentEntryCodeHelp;

  /// No description provided for @parentEntryCodeInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Un code enfant compte 8 lettres et chiffres. Vérifiez-le avec votre enfant.'**
  String get parentEntryCodeInvalid;

  /// No description provided for @parentEntryPaste.
  ///
  /// In fr, this message translates to:
  /// **'Coller'**
  String get parentEntryPaste;

  /// No description provided for @parentEntryAlreadyParent.
  ///
  /// In fr, this message translates to:
  /// **'Je suis déjà parent'**
  String get parentEntryAlreadyParent;

  /// No description provided for @parentEntryPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Le code sert uniquement à relier votre enfant, une fois votre connexion établie.'**
  String get parentEntryPrivacy;

  /// No description provided for @phonePendingChildCode.
  ///
  /// In fr, this message translates to:
  /// **'Code enfant prêt : il sera relié après votre connexion.'**
  String get phonePendingChildCode;

  /// No description provided for @phoneLinkingChild.
  ///
  /// In fr, this message translates to:
  /// **'Rattachement de votre enfant…'**
  String get phoneLinkingChild;

  /// No description provided for @passNumberAlreadyUsed.
  ///
  /// In fr, this message translates to:
  /// **'Numéro déjà associé'**
  String get passNumberAlreadyUsed;

  /// No description provided for @roleConflictStudentAccount.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro est déjà associé à un compte élève.'**
  String get roleConflictStudentAccount;

  /// No description provided for @roleConflictParentAccount.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro est déjà associé à un compte parent.'**
  String get roleConflictParentAccount;

  /// No description provided for @roleConflictStaffAccount.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro est déjà associé à un compte de l’établissement.'**
  String get roleConflictStaffAccount;

  /// No description provided for @roleConflictCredentialsStudentAccount.
  ///
  /// In fr, this message translates to:
  /// **'Ces identifiants ouvrent un compte élève.'**
  String get roleConflictCredentialsStudentAccount;

  /// No description provided for @roleConflictCredentialsParentAccount.
  ///
  /// In fr, this message translates to:
  /// **'Ces identifiants ouvrent un compte parent.'**
  String get roleConflictCredentialsParentAccount;

  /// No description provided for @roleConflictCredentialsStaffAccount.
  ///
  /// In fr, this message translates to:
  /// **'Ces identifiants ouvrent un compte de l’établissement.'**
  String get roleConflictCredentialsStaffAccount;

  /// No description provided for @roleConflictUseParentCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Pour créer ou ouvrir un espace parent, utilisez les identifiants du parent.'**
  String get roleConflictUseParentCredentials;

  /// No description provided for @roleConflictUseStudentCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Pour ouvrir l’espace élève, utilisez les identifiants de l’élève.'**
  String get roleConflictUseStudentCredentials;

  /// No description provided for @roleConflictChildCodeKept.
  ///
  /// In fr, this message translates to:
  /// **'Le code enfant reste enregistré.'**
  String get roleConflictChildCodeKept;

  /// No description provided for @roleConflictUseAnotherNumber.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser un autre numéro'**
  String get roleConflictUseAnotherNumber;

  /// No description provided for @childLinkReportFailedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le code enfant n’a pas pu être relié'**
  String get childLinkReportFailedTitle;

  /// No description provided for @childLinkBatchSuccess.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 enfant relié à votre compte.} other{{count} enfants reliés à votre compte.}}'**
  String childLinkBatchSuccess(int count);

  /// No description provided for @parentEntryCodePurpose.
  ///
  /// In fr, this message translates to:
  /// **'Ce code permet de rattacher l’enfant.\nVotre numéro de téléphone sert à vous identifier comme parent.'**
  String get parentEntryCodePurpose;

  /// No description provided for @passFamilyNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de la famille'**
  String get passFamilyNumber;

  /// No description provided for @familyPhoneMigrationPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro est actuellement utilisé pour l’accès d’un élève. Souhaitez-vous l’utiliser comme numéro du parent ? L’élève conservera son profil et utilisera désormais son code d’accès INTELLIA.'**
  String get familyPhoneMigrationPrompt;

  /// No description provided for @familyPhoneMigrationConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser ce numéro pour le parent'**
  String get familyPhoneMigrationConfirm;

  /// No description provided for @familyPhoneMigrationNothingChanged.
  ///
  /// In fr, this message translates to:
  /// **'Le transfert n’a pas abouti. Rien n’a changé : réessayez.'**
  String get familyPhoneMigrationNothingChanged;

  /// No description provided for @familyPhoneMigrationVerifyAgain.
  ///
  /// In fr, this message translates to:
  /// **'Pour votre sécurité, vérifiez à nouveau ce numéro avant de le transférer.'**
  String get familyPhoneMigrationVerifyAgain;

  /// No description provided for @familyPhoneMigrationVerifyAgainAction.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier à nouveau le numéro'**
  String get familyPhoneMigrationVerifyAgainAction;

  /// No description provided for @familyPhoneMigrationInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Un transfert est déjà en cours pour ce numéro. Patientez un instant puis réessayez.'**
  String get familyPhoneMigrationInProgress;

  /// No description provided for @familyPhoneMigrationVerifyAgainToFinish.
  ///
  /// In fr, this message translates to:
  /// **'L’élève a déjà son code d’accès. Vérifiez à nouveau ce numéro pour terminer l’ouverture de votre espace parent.'**
  String get familyPhoneMigrationVerifyAgainToFinish;

  /// No description provided for @familyPhoneMigrationRefused.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro ne peut pas être transféré depuis ce compte. Utilisez un autre numéro ou contactez l’établissement.'**
  String get familyPhoneMigrationRefused;

  /// No description provided for @familyPhoneMigrationUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le transfert du numéro n’est pas encore disponible. Réessayez plus tard ou utilisez un autre numéro.'**
  String get familyPhoneMigrationUnavailable;

  /// No description provided for @familyPhoneMigratedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro est désormais le vôtre'**
  String get familyPhoneMigratedTitle;

  /// No description provided for @familyPhoneMigratedContinue.
  ///
  /// In fr, this message translates to:
  /// **'J’ai noté le code, ouvrir mon espace parent'**
  String get familyPhoneMigratedContinue;

  /// No description provided for @studentNoPhoneUseAccessCode.
  ///
  /// In fr, this message translates to:
  /// **'Pas de téléphone ? Entre avec ton code d’accès INTELLIA'**
  String get studentNoPhoneUseAccessCode;

  /// No description provided for @studentAccessCodePhase.
  ///
  /// In fr, this message translates to:
  /// **'Ton code d’accès'**
  String get studentAccessCodePhase;

  /// No description provided for @studentAccessCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Entre avec ton code d’accès'**
  String get studentAccessCodeTitle;

  /// No description provided for @studentAccessCodeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisis les 12 caractères que ton parent ou ton établissement t’a donnés. Pas besoin de téléphone.'**
  String get studentAccessCodeSubtitle;

  /// No description provided for @studentAccessCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code d’accès INTELLIA'**
  String get studentAccessCodeLabel;

  /// No description provided for @studentAccessCodeSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Entrer dans mon espace'**
  String get studentAccessCodeSubmit;

  /// No description provided for @studentAccessCodePrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Garde ce code pour toi : il ouvre ton espace. Si tu l’as perdu, demande un nouveau code à ton parent ou à ton établissement.'**
  String get studentAccessCodePrivacy;

  /// No description provided for @studentAccessCodeUsePhone.
  ///
  /// In fr, this message translates to:
  /// **'J’ai un téléphone : recevoir un SMS'**
  String get studentAccessCodeUsePhone;

  /// No description provided for @studentAccessCodeInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Ce code ne fonctionne pas. Vérifie-le, ou demande un nouveau code à ton parent ou à ton établissement.'**
  String get studentAccessCodeInvalid;

  /// No description provided for @studentAccessCodeTooManyAttempts.
  ///
  /// In fr, this message translates to:
  /// **'Trop d’essais. Attends quelques minutes avant de réessayer.'**
  String get studentAccessCodeTooManyAttempts;

  /// No description provided for @studentAccessCodeUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le service ne répond pas pour le moment. Réessaie dans un instant.'**
  String get studentAccessCodeUnavailable;

  /// No description provided for @studentAccessCodeRevealTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code d’accès INTELLIA de {name}'**
  String studentAccessCodeRevealTitle(String name);

  /// No description provided for @studentAccessCodeRevealTitleGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Code d’accès INTELLIA de l’élève'**
  String get studentAccessCodeRevealTitleGeneric;

  /// No description provided for @studentAccessCodeRevealBody.
  ///
  /// In fr, this message translates to:
  /// **'Notez ce code et remettez-le à {name} : il ouvre son espace sans téléphone. Il ne sera plus affiché ; vous pourrez en générer un nouveau depuis sa fiche.'**
  String studentAccessCodeRevealBody(String name);

  /// No description provided for @studentAccessCodeRevealBodyGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Notez ce code et remettez-le à l’élève : il ouvre son espace sans téléphone. Il ne sera plus affiché ; vous pourrez en générer un nouveau depuis sa fiche.'**
  String get studentAccessCodeRevealBodyGeneric;

  /// No description provided for @studentAccessCodeNotShownAgain.
  ///
  /// In fr, this message translates to:
  /// **'Le code d’accès de l’élève a déjà été créé. Pour sa sécurité, il n’est jamais affiché à nouveau : générez-en un nouveau depuis sa fiche.'**
  String get studentAccessCodeNotShownAgain;

  /// No description provided for @studentAccessCodeCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier le code'**
  String get studentAccessCodeCopy;

  /// No description provided for @studentAccessCodeCopied.
  ///
  /// In fr, this message translates to:
  /// **'Code copié'**
  String get studentAccessCodeCopied;

  /// No description provided for @studentAccessCodeSheetBody.
  ///
  /// In fr, this message translates to:
  /// **'Ce code permet à votre enfant d’ouvrir son espace INTELLIA sans téléphone. Pour sa sécurité, il n’est jamais affiché à nouveau : générer un nouveau code remplace l’ancien, qui cesse aussitôt de fonctionner.'**
  String get studentAccessCodeSheetBody;

  /// No description provided for @studentAccessCodeGenerate.
  ///
  /// In fr, this message translates to:
  /// **'Afficher / générer un nouveau code d’accès'**
  String get studentAccessCodeGenerate;

  /// No description provided for @studentAccessCodeReplaceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer le code d’accès ?'**
  String get studentAccessCodeReplaceTitle;

  /// No description provided for @studentAccessCodeReplaceBody.
  ///
  /// In fr, this message translates to:
  /// **'L’ancien code de {name} cessera immédiatement de fonctionner.'**
  String studentAccessCodeReplaceBody(String name);

  /// No description provided for @studentAccessCodeReplaceConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Générer le nouveau code'**
  String get studentAccessCodeReplaceConfirm;

  /// No description provided for @studentAccessCodeDone.
  ///
  /// In fr, this message translates to:
  /// **'J’ai noté le code'**
  String get studentAccessCodeDone;

  /// No description provided for @studentAccessCodeIssueFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le code n’a pas pu être généré. Réessayez.'**
  String get studentAccessCodeIssueFailed;

  /// No description provided for @studentAccessCodeActiveSince.
  ///
  /// In fr, this message translates to:
  /// **'Code d’accès actif depuis le {date}'**
  String studentAccessCodeActiveSince(String date);

  /// No description provided for @studentAccessCodeActive.
  ///
  /// In fr, this message translates to:
  /// **'Code d’accès actif'**
  String get studentAccessCodeActive;

  /// No description provided for @studentAccessCodeNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun code d’accès pour l’instant'**
  String get studentAccessCodeNone;

  /// No description provided for @childAccessOwnPhone.
  ///
  /// In fr, this message translates to:
  /// **'Connecté avec son propre accès INTELLIA'**
  String get childAccessOwnPhone;

  /// No description provided for @childAccessCodeOnly.
  ///
  /// In fr, this message translates to:
  /// **'Se connecte avec son code d’accès INTELLIA'**
  String get childAccessCodeOnly;

  /// No description provided for @childAccessUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Accès de l’enfant non disponible pour le moment'**
  String get childAccessUnknown;

  /// No description provided for @childAccessNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun accès personnel : générez son code d’accès'**
  String get childAccessNone;

  /// No description provided for @childActionViewProfile.
  ///
  /// In fr, this message translates to:
  /// **'Voir le profil'**
  String get childActionViewProfile;

  /// No description provided for @childActionViewActivity.
  ///
  /// In fr, this message translates to:
  /// **'Voir son activité'**
  String get childActionViewActivity;

  /// No description provided for @childActionAccessCode.
  ///
  /// In fr, this message translates to:
  /// **'Code d’accès élève'**
  String get childActionAccessCode;

  /// No description provided for @childActionSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement'**
  String get childActionSubscription;

  /// No description provided for @childSubscriptionActiveUntil.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement actif jusqu’au {date}'**
  String childSubscriptionActiveUntil(String date);

  /// No description provided for @childSubscriptionPaidByAnotherGuardian.
  ///
  /// In fr, this message translates to:
  /// **'Réglé par un autre responsable de l’enfant'**
  String get childSubscriptionPaidByAnotherGuardian;

  /// No description provided for @childSubscriptionInactive.
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement actif pour cet enfant'**
  String get childSubscriptionInactive;

  /// No description provided for @childSchoolUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Établissement non renseigné'**
  String get childSchoolUnknown;

  /// No description provided for @parentChildrenCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 enfant} other{{count} enfants}}'**
  String parentChildrenCount(int count);

  /// No description provided for @parentModeProfileBanner.
  ///
  /// In fr, this message translates to:
  /// **'MODE PARENT — PROFIL DE {name}'**
  String parentModeProfileBanner(String name);

  /// No description provided for @parentModeProfileNote.
  ///
  /// In fr, this message translates to:
  /// **'Vous consultez ce profil avec votre compte parent. Vous ne pouvez rien y modifier au nom de votre enfant.'**
  String get parentModeProfileNote;

  /// No description provided for @childProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil de l’enfant'**
  String get childProfileTitle;

  /// No description provided for @childProfileClass.
  ///
  /// In fr, this message translates to:
  /// **'Classe'**
  String get childProfileClass;

  /// No description provided for @childProfileSchool.
  ///
  /// In fr, this message translates to:
  /// **'Établissement'**
  String get childProfileSchool;

  /// No description provided for @childProfileAccess.
  ///
  /// In fr, this message translates to:
  /// **'Accès INTELLIA'**
  String get childProfileAccess;

  /// No description provided for @childProfileSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement'**
  String get childProfileSubscription;

  /// No description provided for @parentSchoolsAnnouncements.
  ///
  /// In fr, this message translates to:
  /// **'Annonces des écoles de vos enfants'**
  String get parentSchoolsAnnouncements;

  /// No description provided for @mobileMoneyChooseChild.
  ///
  /// In fr, this message translates to:
  /// **'Pour quel enfant payez-vous ?'**
  String get mobileMoneyChooseChild;

  /// No description provided for @mobileMoneyOfferOfSchool.
  ///
  /// In fr, this message translates to:
  /// **'Offre de {school}'**
  String mobileMoneyOfferOfSchool(String school);

  /// No description provided for @mobileMoneyCoversChildren.
  ///
  /// In fr, this message translates to:
  /// **'Ce paiement couvre : {names}'**
  String mobileMoneyCoversChildren(String names);

  /// No description provided for @childPendingFirstSignIn.
  ///
  /// In fr, this message translates to:
  /// **'En attente de sa première connexion'**
  String get childPendingFirstSignIn;

  /// No description provided for @addChildNoAccountAction.
  ///
  /// In fr, this message translates to:
  /// **'Mon enfant n’a pas encore de compte INTELLIA'**
  String get addChildNoAccountAction;

  /// No description provided for @addChildNoAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir l’accès de votre enfant'**
  String get addChildNoAccountTitle;

  /// No description provided for @addChildNoAccountBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre enfant n’a pas besoin de téléphone. Vous recevrez son code d’accès INTELLIA ; il complétera lui-même son profil scolaire à sa première connexion.'**
  String get addChildNoAccountBody;

  /// No description provided for @addChildNoAccountNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prénom de l’enfant'**
  String get addChildNoAccountNameLabel;

  /// No description provided for @addChildNoAccountNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le prénom de votre enfant.'**
  String get addChildNoAccountNameRequired;

  /// No description provided for @addChildNoAccountSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Créer son code d’accès'**
  String get addChildNoAccountSubmit;

  /// No description provided for @addChildNoAccountFailed.
  ///
  /// In fr, this message translates to:
  /// **'L’accès n’a pas pu être ouvert. Réessayez.'**
  String get addChildNoAccountFailed;

  /// No description provided for @adminStudentAccessRecoveryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récupérer l’accès de l’élève'**
  String get adminStudentAccessRecoveryTitle;

  /// No description provided for @adminStudentAccessRecoveryBody.
  ///
  /// In fr, this message translates to:
  /// **'Un nouveau code d’accès INTELLIA remplace le précédent, qui cesse aussitôt de fonctionner. Remettez-le à l’élève ou à sa famille en main propre : il ne sera plus affiché.'**
  String get adminStudentAccessRecoveryBody;

  /// No description provided for @adminStudentPhoneOptional.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone de l’élève (facultatif)'**
  String get adminStudentPhoneOptional;

  /// No description provided for @childActionLinkCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de liaison parent'**
  String get childActionLinkCode;

  /// No description provided for @guardianLinkCodeBody.
  ///
  /// In fr, this message translates to:
  /// **'Ce code permet à un autre parent ou responsable de rattacher {name} à son propre compte. Il n’ouvre pas l’espace de l’élève : pour cela, utilisez le code d’accès élève.'**
  String guardianLinkCodeBody(String name);

  /// No description provided for @guardianLinkCodeRotate.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer ce code'**
  String get guardianLinkCodeRotate;

  /// No description provided for @guardianLinkCodeRotateBody.
  ///
  /// In fr, this message translates to:
  /// **'L’ancien code de liaison cessera immédiatement de fonctionner. Les responsables déjà rattachés le restent.'**
  String get guardianLinkCodeRotateBody;

  /// No description provided for @guardianLinkCodeUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le code de liaison n’a pas pu être obtenu. Réessayez.'**
  String get guardianLinkCodeUnavailable;

  /// No description provided for @ilbWordOrderInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Remets les mots dans le bon ordre.'**
  String get ilbWordOrderInstruction;

  /// No description provided for @ilbStepOrderInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Remets les étapes dans le bon ordre.'**
  String get ilbStepOrderInstruction;

  /// No description provided for @ilbTimelineInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Remets ces événements dans l’ordre chronologique.'**
  String get ilbTimelineInstruction;

  /// No description provided for @ilbProcessInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Remets les étapes de ce processus dans l’ordre.'**
  String get ilbProcessInstruction;

  /// No description provided for @ilbCheck.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get ilbCheck;

  /// No description provided for @ilbRestart.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer'**
  String get ilbRestart;

  /// No description provided for @ilbHint.
  ///
  /// In fr, this message translates to:
  /// **'Un indice'**
  String get ilbHint;

  /// No description provided for @ilbShowSolution.
  ///
  /// In fr, this message translates to:
  /// **'Voir la solution'**
  String get ilbShowSolution;

  /// No description provided for @ilbContinueWith.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec {name}'**
  String ilbContinueWith(String name);

  /// No description provided for @ilbContinueMessage.
  ///
  /// In fr, this message translates to:
  /// **'J’ai terminé l’exercice. On continue ?'**
  String get ilbContinueMessage;

  /// No description provided for @ilbCorrect1.
  ///
  /// In fr, this message translates to:
  /// **'Exact.'**
  String get ilbCorrect1;

  /// No description provided for @ilbCorrect2.
  ///
  /// In fr, this message translates to:
  /// **'Très bien.'**
  String get ilbCorrect2;

  /// No description provided for @ilbCorrect3.
  ///
  /// In fr, this message translates to:
  /// **'Oui, c’est ça.'**
  String get ilbCorrect3;

  /// No description provided for @ilbAlmost.
  ///
  /// In fr, this message translates to:
  /// **'Presque.'**
  String get ilbAlmost;

  /// No description provided for @ilbTryAgain.
  ///
  /// In fr, this message translates to:
  /// **'Essaie encore.'**
  String get ilbTryAgain;

  /// No description provided for @ilbPositionHint.
  ///
  /// In fr, this message translates to:
  /// **'Regarde la position {position}.'**
  String ilbPositionHint(int position);

  /// No description provided for @ilbAttempt.
  ///
  /// In fr, this message translates to:
  /// **'Essai {count}'**
  String ilbAttempt(int count);

  /// No description provided for @ilbHintsUsed.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun indice} =1{1 indice} other{{count} indices}}'**
  String ilbHintsUsed(int count);

  /// No description provided for @ilbAnswerZoneEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Touche ou glisse les mots ici'**
  String get ilbAnswerZoneEmpty;

  /// No description provided for @ilbAnswerZoneA11y.
  ///
  /// In fr, this message translates to:
  /// **'Ta réponse'**
  String get ilbAnswerZoneA11y;

  /// No description provided for @ilbWordBankA11y.
  ///
  /// In fr, this message translates to:
  /// **'Mots à placer'**
  String get ilbWordBankA11y;

  /// No description provided for @ilbPlaceWordA11y.
  ///
  /// In fr, this message translates to:
  /// **'Placer « {word} »'**
  String ilbPlaceWordA11y(String word);

  /// No description provided for @ilbRemoveWordA11y.
  ///
  /// In fr, this message translates to:
  /// **'Retirer « {word} », position {position}'**
  String ilbRemoveWordA11y(String word, int position);

  /// No description provided for @ilbMoveUp.
  ///
  /// In fr, this message translates to:
  /// **'Monter'**
  String get ilbMoveUp;

  /// No description provided for @ilbMoveDown.
  ///
  /// In fr, this message translates to:
  /// **'Descendre'**
  String get ilbMoveDown;

  /// No description provided for @ilbStepA11y.
  ///
  /// In fr, this message translates to:
  /// **'Étape {position} : {text}'**
  String ilbStepA11y(int position, String text);

  /// No description provided for @ilbSolutionShown.
  ///
  /// In fr, this message translates to:
  /// **'Voici la bonne réponse.'**
  String get ilbSolutionShown;

  /// No description provided for @ilbKiraWords.
  ///
  /// In fr, this message translates to:
  /// **'Essaie de remettre cette phrase dans le bon ordre.'**
  String get ilbKiraWords;

  /// No description provided for @ilbLeoWords.
  ///
  /// In fr, this message translates to:
  /// **'À toi. Reconstruis cette phrase.'**
  String get ilbLeoWords;

  /// No description provided for @ilbKiraSteps.
  ///
  /// In fr, this message translates to:
  /// **'Prends ton temps : remets les étapes dans l’ordre.'**
  String get ilbKiraSteps;

  /// No description provided for @ilbLeoSteps.
  ///
  /// In fr, this message translates to:
  /// **'Défi : remets les étapes dans l’ordre, sans aide si tu peux.'**
  String get ilbLeoSteps;

  /// No description provided for @parcoursEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton parcours se prépare'**
  String get parcoursEmptyTitle;

  /// No description provided for @parcoursEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucune carte n’est encore publiée pour ta classe. Reviens après une synchronisation.'**
  String get parcoursEmptyBody;

  /// No description provided for @parcoursEmptyRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get parcoursEmptyRefresh;

  /// No description provided for @parcoursEmptyHome.
  ///
  /// In fr, this message translates to:
  /// **'Revenir à l’accueil'**
  String get parcoursEmptyHome;

  /// No description provided for @parcoursVideoPending.
  ///
  /// In fr, this message translates to:
  /// **'Cette vidéo n’est pas encore disponible.'**
  String get parcoursVideoPending;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
