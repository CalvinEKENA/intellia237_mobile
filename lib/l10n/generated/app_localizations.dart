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
  /// **'Trop de tentatives. Patientez quelques minutes avant de réessayer.'**
  String get phoneErrorTooManyRequests;

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
  /// **'La demande sera enregistrée pour vérification et traitement sécurisé. Cette action te déconnectera.'**
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
