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

  /// No description provided for @skipIntroduction.
  ///
  /// In fr, this message translates to:
  /// **'Passer l’expérience'**
  String get skipIntroduction;

  /// No description provided for @skipIntroductionA11y.
  ///
  /// In fr, this message translates to:
  /// **'Passer l’expérience d’introduction'**
  String get skipIntroductionA11y;

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
  /// **'Passeport académique'**
  String get academicPassport;

  /// No description provided for @academicPassportDescription.
  ///
  /// In fr, this message translates to:
  /// **'Regroupez l’identité d’usage, la langue et le parcours scolaire dans une seule fiche.'**
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
