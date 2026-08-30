// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get backToPreviousAct => 'Return to the previous act';

  @override
  String get skipIntroduction => 'Skip experience';

  @override
  String get skipIntroductionA11y => 'Skip the introduction experience';

  @override
  String get ascensionSemanticLabel => 'The Ascent';

  @override
  String get ascensionEyebrow => 'ACT VI — THE ASCENT';

  @override
  String get ascensionTitle => 'Build your future, one step at a time.';

  @override
  String get ascensionBody =>
      'INTELLIA237 complements your lessons, books and notebooks to help you understand, practise and progress. Your teachers remain at the heart of your journey.';

  @override
  String get ascensionCta => 'Create my INTELLIA PASS';

  @override
  String get ascensionImageA11y =>
      'Two students walking towards a bright library, symbolising their academic progress';

  @override
  String get portalContinue => 'Discover what comes next';

  @override
  String get passEyebrow => 'INTELLIA PASS';

  @override
  String get passTitle => 'Who is using INTELLIA237?';

  @override
  String get passSubtitle =>
      'Clear access for every family member, even when the device is shared.';

  @override
  String get studentRole => 'Student';

  @override
  String get studentRoleDescription =>
      'Learn, practise and progress with a learning companion.';

  @override
  String get parentRole => 'Parent or guardian';

  @override
  String get parentRoleDescription =>
      'Create the household, add several children and follow their progress.';

  @override
  String get professionalAccess => 'Professional access';

  @override
  String get teacherRole => 'Teacher';

  @override
  String get teacherRoleDescription =>
      'Prepare classes and share learning resources.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get existingAccount => 'I already have an account';

  @override
  String chooseIdentityA11y(String role) {
    return 'Choose the $role profile';
  }

  @override
  String get householdQuestion => 'Who is learning today?';

  @override
  String get householdSubtitle =>
      'Choose a student profile. Switching profiles never bypasses parent authorisation.';

  @override
  String get addLearner => 'Add a child';

  @override
  String get parentArea => 'Parent area';

  @override
  String get academicPassport => 'Academic passport';

  @override
  String get academicPassportDescription =>
      'Keep the preferred identity, language and school pathway in one concise record.';

  @override
  String get interfaceLanguage => 'Interface language';

  @override
  String get frenchLanguage => 'Français';

  @override
  String get englishLanguage => 'English';

  @override
  String get educationalSubsystem => 'Educational subsystem';

  @override
  String get francophoneSubsystem => 'Francophone';

  @override
  String get anglophoneSubsystem => 'Anglophone';

  @override
  String get educationType => 'Education type';

  @override
  String get generalEducation => 'General';

  @override
  String get technicalEducation => 'Technical';

  @override
  String get schoolLevel => 'Level';

  @override
  String get streamOrSpeciality => 'Stream or speciality';

  @override
  String get establishment => 'School';

  @override
  String get establishmentHint => 'Search for or enter a school';

  @override
  String get establishmentUnverified =>
      'School selected — verification pending';

  @override
  String get establishmentSecurityNote =>
      'Selecting a school grants no access to private data. Server authorisation remains mandatory.';

  @override
  String get individualAccount => 'Individual student account';

  @override
  String get parentLinkedAccount => 'Family household account';

  @override
  String get parentLinkedHelp =>
      'The parent creates and protects household profiles from the parent area.';

  @override
  String get learningCompanion => 'Learning companion';

  @override
  String get createAccount => 'Create my account';

  @override
  String get previousStep => 'Previous step';

  @override
  String get phoneOtp => 'Phone and verification code';

  @override
  String get emailAuthentication => 'Email address';

  @override
  String get availableNow => 'Available now';

  @override
  String get plannedLater => 'Planned for later';

  @override
  String get loginEyebrow => 'Your personal space';

  @override
  String get loginTitle => 'Welcome back.';

  @override
  String get loginSubtitle =>
      'Continue your progress and return to your learning companion.';

  @override
  String get emailLabel => 'Email address';

  @override
  String get emailHint => 'first.last@example.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Your password';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get signIn => 'Sign in';

  @override
  String get noAccount => 'No account yet?';

  @override
  String get createAccountLink => 'Create an account';

  @override
  String get forgotEyebrow => 'Account access';

  @override
  String get forgotTitle => 'Recover your password.';

  @override
  String get forgotSubtitle =>
      'We will send a secure link to your account email address.';

  @override
  String get emailSent => 'Email sent';

  @override
  String checkEmail(String email) {
    return 'Check $email and open the link you received.';
  }

  @override
  String get backToLogin => 'Back to sign in';

  @override
  String get sendLink => 'Send link';

  @override
  String get phonePrimary => 'Cameroon phone number';

  @override
  String get phonePrimaryHint => '+237 6XX XX XX XX';

  @override
  String get emailOptional => 'Email (optional)';

  @override
  String get otpChannelTitle => 'How would you like to receive the code?';

  @override
  String get otpWhatsapp => 'Receive the code by WhatsApp';

  @override
  String get otpSms => 'Receive the code by SMS';

  @override
  String get otpSmsFallback =>
      'SMS remains available if you do not use WhatsApp.';

  @override
  String get studyModeTitle => 'Study Mode';

  @override
  String get studyModeDuration => 'Choose the study duration';

  @override
  String get studyModeComplete => 'Session complete';

  @override
  String get studyModeCompleteBody =>
      'The device stays inside INTELLIA237 until the parent reclaims it.';

  @override
  String get studyModeFamilyCopy =>
      'Lend your phone for studying, not distractions.';

  @override
  String get reclaimDevice => 'Reclaim device';
}
