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
  String get onboardingOpeningBody =>
      'A learning experience designed to help you understand, practise and progress.';

  @override
  String get onboardingTapToContinue => 'Tap to continue';

  @override
  String get companionSwitchHint => 'Tap or swipe to change personality.';

  @override
  String get companionChangeLater => 'You can change later.';

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
      'Tell us a little about yourself so we can prepare your space.';

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
  String get phoneIdentityTarget => 'Target identity: phone + OTP code';

  @override
  String get temporaryEmailNotice =>
      'In this version, a technical email is still temporarily required to create the Firebase account. It is not the target primary identity.';

  @override
  String get temporaryEmailLabel => 'Technical email (temporary)';

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

  @override
  String get preparingYourSpace => 'Preparing your space…';

  @override
  String companionQuotaReached(String name) {
    return 'You have used all your questions for today. You can ask $name again tomorrow.';
  }

  @override
  String companionProfileSync(String name) {
    return '$name needs to resync your profile before answering. Your lessons and exercises remain available.';
  }

  @override
  String companionInvalidRequest(String name) {
    return '$name cannot process that question. Try rephrasing it in a few words.';
  }

  @override
  String companionNetworkUnavailable(String name) {
    return '$name cannot connect right now. Check your connection; your lessons and exercises remain available.';
  }

  @override
  String companionServiceUnavailable(String name) {
    return '$name cannot answer right now. You can keep using your lessons and exercises.';
  }

  @override
  String companionInvalidResponse(String name) {
    return '$name received an incomplete response. You can try again in a moment.';
  }

  @override
  String get companionStatusReady => 'Ready to help';

  @override
  String get companionStatusThinking => 'thinking…';

  @override
  String get companionStatusQuota => 'daily limit reached';

  @override
  String get companionStatusProfile => 'profile needs syncing';

  @override
  String get companionStatusNetwork => 'waiting for connection';

  @override
  String get companionStatusUnavailable => 'answer unavailable';

  @override
  String get phoneAuthEyebrow => 'SECURE ACCESS · 237';

  @override
  String get phoneAuthTitle => 'Your number opens your space.';

  @override
  String get phoneAuthSubtitle =>
      'We send a one-time code by SMS. No email is required.';

  @override
  String get phoneLinkTitle => 'Add your phone number.';

  @override
  String get phoneLinkSubtitle =>
      'Your current account and profile remain unchanged.';

  @override
  String get cameroonCountry => 'Cameroon';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get phoneNumberLocalHint => '6XX XX XX XX';

  @override
  String get sendVerificationCode => 'Send my code';

  @override
  String get useEmailCompatibility => 'Use my email instead';

  @override
  String get phoneCodeTitle => 'Enter the 6 digits.';

  @override
  String phoneCodeSubtitle(String phone) {
    return 'The code was sent to $phone.';
  }

  @override
  String get verificationCodeLabel => 'Verification code';

  @override
  String get verificationCodeHint => '000000';

  @override
  String get verifyCode => 'Verify code';

  @override
  String get changePhoneNumber => 'Change phone number';

  @override
  String get resendCode => 'Send code again';

  @override
  String resendCodeIn(int seconds) {
    return 'Send again in ${seconds}s';
  }

  @override
  String get smsAutoRetrievalTimeout =>
      'Automatic detection has ended. Enter the code you received or request another one.';

  @override
  String get phoneVerificationSuccess => 'Number verified';

  @override
  String get phoneVerificationSuccessBody => 'Your secure access is ready.';

  @override
  String get phoneLinkSuccessBody =>
      'Your number is now linked to this same account.';

  @override
  String get phoneErrorInvalidNumber =>
      'Enter a valid 9-digit Cameroon mobile number.';

  @override
  String get phoneErrorInvalidCode => 'The code is incorrect or has expired.';

  @override
  String get phoneErrorTooManyRequests =>
      'Too many attempts. Wait a few minutes before trying again.';

  @override
  String get phoneErrorQuota =>
      'SMS delivery is temporarily unavailable. Try again later.';

  @override
  String get phoneErrorNetwork =>
      'The connection was interrupted. Check your internet connection and try again.';

  @override
  String get phoneErrorDisabled =>
      'Phone sign-in must be enabled in Firebase Authentication.';

  @override
  String get phoneErrorCollision =>
      'This number is already linked to another account. Sign in with that number or contact support.';

  @override
  String get phoneErrorRecentLogin =>
      'Sign in again before adding this number.';

  @override
  String get phoneErrorProfileMissing =>
      'No INTELLIA237 profile is linked to this number yet. Create your account first.';

  @override
  String get phoneErrorGeneric =>
      'Verification could not be completed. Try again in a moment.';

  @override
  String get schoolSearchLabel => 'Your school';

  @override
  String get schoolSearchHint => 'Start typing its name or city';

  @override
  String get schoolSearchHelp => 'The strongest matches appear as you type.';

  @override
  String get schoolSelectedPending =>
      'Selection saved · affiliation awaiting verification';

  @override
  String get schoolNotFound => 'My school is not listed';

  @override
  String get schoolSuggestionTitle => 'Suggest a school';

  @override
  String get schoolSuggestionBody =>
      'This suggestion will be reviewed. It never creates a verified affiliation.';

  @override
  String get schoolNameLabel => 'School name';

  @override
  String get schoolCityLabel => 'City';

  @override
  String get schoolRegionLabel => 'Region';

  @override
  String get schoolSuggestionSubmit => 'Send suggestion';

  @override
  String get schoolSuggestionSaved => 'Suggestion saved · verification pending';

  @override
  String get schoolSuggestionRequired => 'Enter the name, city and region.';

  @override
  String get schoolTypeLycee => 'High school';

  @override
  String get schoolTypeCollege => 'College';

  @override
  String get schoolTypeTechnical => 'Technical';

  @override
  String get schoolTypeGovernment => 'Public';

  @override
  String get schoolTypePrivate => 'Private';

  @override
  String get schoolSubsystemFrancophone => 'Francophone';

  @override
  String get schoolSubsystemAnglophone => 'Anglophone';

  @override
  String get schoolSubsystemBilingual => 'Bilingual';

  @override
  String get selectedCompanionEyebrow => 'YOUR COMPANION';

  @override
  String get changeCompanion => 'Change my companion';

  @override
  String get leoProfileTagline => 'Science · method · reasoning';

  @override
  String get kiraProfileTagline => 'Clarity · confidence · progress';

  @override
  String get stepIdentity => 'Identity';

  @override
  String get stepClass => 'Class';

  @override
  String get stepCompanion => 'Companion';

  @override
  String get stepSecurity => 'Security';

  @override
  String get studentSpaceEyebrow => 'Student space';

  @override
  String get studentRegistrationTitle => 'Build your\nIntellia 237 journey.';

  @override
  String get studentRegistrationSubtitle =>
      'Four quick steps to prepare your personal space.';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get firstNameHint => 'E.g. Marie';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get lastNameHint => 'E.g. Ndi';

  @override
  String get seriesLabel => 'Series';

  @override
  String get meetCompanionTitle => 'Meet your companion';

  @override
  String get meetCompanionSubtitle =>
      'Discover Kira, then Léo. You will choose after meeting both.';

  @override
  String get secureAccountTitle => 'Secure your account';

  @override
  String get secureAccountPhoneVerified =>
      'Your number is verified. Review your choices before creating your space.';

  @override
  String get phoneVerifiedNoExtraCredential =>
      'Your number is verified. No additional email or password is required.';

  @override
  String get classToConfirm => 'Class to confirm';

  @override
  String get acceptTerms => 'I accept the terms of use.';

  @override
  String get acceptPrivacy => 'I accept the privacy policy.';

  @override
  String get acceptLearningData =>
      'I accept the educational processing of data.';

  @override
  String get parentRegistrationTitle => 'Create a Parent account';

  @override
  String get parentStepIdentity => 'Parent identity';

  @override
  String get parentStepChildren => 'Link children';

  @override
  String get parentStepFinal => 'Final review';

  @override
  String get parentDetailsTitle => 'Parent details';

  @override
  String get parentDetailsSubtitle =>
      'A few details are enough to prepare your child’s learning journey.';

  @override
  String get linkChildrenTitle => 'Link your children';

  @override
  String get linkChildrenSubtitle => 'Add a student identifier now or later.';

  @override
  String get childIdentifierLabel => 'Child code / identifier';

  @override
  String get childIdentifierHint => 'E.g. STU-94K2';

  @override
  String get addLabel => 'Add';

  @override
  String get noLinkedChild => 'No child linked yet.';

  @override
  String get finalReviewTitle => 'Final review';

  @override
  String get finalReviewSubtitle =>
      'Review your information and accept the required consents.';

  @override
  String get parentChildrenLater =>
      'You can also link or update your children after creating your account.';

  @override
  String get previousLabel => 'Previous';

  @override
  String get nextLabel => 'Next';

  @override
  String get createParentAccount => 'Create my parent account';

  @override
  String get retryLabel => 'Try again';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get confirmLabel => 'Confirm';

  @override
  String get refreshLabel => 'Refresh';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get readingComfortSection => 'Reading comfort';

  @override
  String get textSizeLabel => 'Text size';

  @override
  String get reduceMotionLabel => 'Reduce animations';

  @override
  String get reduceMotionDescription =>
      'Replaces decorative motion with calmer transitions.';

  @override
  String get dataRemindersSection => 'Data and reminders';

  @override
  String get weeklyGoalTitle => 'My weekly goal';

  @override
  String get weeklyGoalUnset => 'Not set — choose your pace.';

  @override
  String weeklyGoalSummary(int sessions, int minutes) {
    return '$sessions sessions per week · about $minutes min';
  }

  @override
  String get dataSaverLabel => 'Data saver';

  @override
  String get dataSaverDescription =>
      'Prioritises lightweight content and limits costly effects.';

  @override
  String get learningRemindersLabel => 'Learning reminders';

  @override
  String get learningRemindersDescription =>
      'At most one reminder a day, enabled only after your system permission.';

  @override
  String get reminderTimeLabel => 'Reminder time';

  @override
  String get anonymousDiagnosticsLabel => 'Anonymous diagnostics';

  @override
  String get anonymousDiagnosticsDescription =>
      'Helps identify outages and blocked journeys. No companion message, free-form answer, name or email is collected.';

  @override
  String get privacySection => 'Privacy';

  @override
  String get personalDataTitle => 'Personal data';

  @override
  String get personalDataDescription =>
      'Intellia237 never sends learning conversations to analytics tools.';

  @override
  String get deleteAccountTitle => 'Account deletion';

  @override
  String get deleteAccountDescription => 'Send a secure deletion request.';

  @override
  String get accountSection => 'Account';

  @override
  String get addPhoneTitle => 'Add or secure my phone number';

  @override
  String get addPhoneDescription =>
      'Link a +237 number without changing this account or profile.';

  @override
  String get editProfileTitle => 'Edit my profile';

  @override
  String get editProfileDescription =>
      'Name, phone number and profile picture.';

  @override
  String get signOutTitle => 'Sign out';

  @override
  String get signOutDescription =>
      'Your synced data will be available the next time you sign in.';

  @override
  String get deleteRequestQuestion => 'Request deletion?';

  @override
  String get deleteRequestBody =>
      'The request will be recorded for secure review and processing. This will sign you out.';

  @override
  String get sendRequestLabel => 'Send request';

  @override
  String get deleteRequestError =>
      'The request cannot be sent right now. Try again later.';

  @override
  String get chooseReminderTime => 'Choose reminder time';

  @override
  String get signOutQuestion => 'Sign out?';

  @override
  String get emailVerificationTitle => 'Email address verification';

  @override
  String get statusUnavailable => 'Status temporarily unavailable.';

  @override
  String get emailVerifiedTitle => 'Email address verified';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String get emailRecoveryDescription =>
      'Protect your account and make recovery easier.';

  @override
  String get resendLabel => 'Send again';

  @override
  String get emailVerificationSent =>
      'Email sent. Open the link you received, then refresh this status.';

  @override
  String accountReadyWithCompanion(String name) {
    return 'Your account is ready. $name is with you from now on.';
  }

  @override
  String get discoverIntellia => 'Discover Intellia 237';

  @override
  String get learnTitle => 'Learn';

  @override
  String get learnSubtitle => 'Your subjects, adapted to your level.';

  @override
  String get subjectsLoadError => 'Unable to load subjects';

  @override
  String get subjectsComingTitle => 'Your subjects are coming';

  @override
  String get subjectsComingBody =>
      'Content for your class is being prepared. You will be among the first to use it.';

  @override
  String get noSubjectFound => 'No subject found';

  @override
  String get tryAnotherKeyword => 'Try another keyword.';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get personalizedPath => 'Personalised journey';

  @override
  String get levelAdaptedContent => 'Content adapted to your current level.';

  @override
  String get searchSubjectHint => 'Search for a subject…';

  @override
  String get subjectGenericTitle => 'Subject';

  @override
  String get subjectUnavailable => 'Subject unavailable';

  @override
  String get chaptersTitle => 'Chapters';

  @override
  String get chaptersComingTitle => 'Chapters are being prepared';

  @override
  String get chaptersComingBody =>
      'This subject is being written for your class. Check back soon!';

  @override
  String lessonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons',
      one: '1 lesson',
      zero: 'No lessons',
    );
    return '$_temp0';
  }

  @override
  String get lessonsTitle => 'Lessons';

  @override
  String get lessonsComingTitle => 'Lessons are being prepared';

  @override
  String get lessonsComingBody =>
      'The lessons in this chapter are being written. Check back soon.';

  @override
  String get chapterSavedOffline => 'Chapter saved for offline reading';

  @override
  String get availableOffline => 'Available offline';

  @override
  String get studyOffline => 'Study offline';

  @override
  String offlineLessonPrepared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons prepared on this device.',
      one: '1 lesson prepared on this device.',
      zero: 'No lessons prepared on this device.',
    );
    return '$_temp0';
  }

  @override
  String get prepareOfflineLessons =>
      'Prepare all lessons for offline reading.';

  @override
  String get chapterReadyOffline => 'Chapter ready for offline reading.';

  @override
  String get downloadFailed =>
      'The download did not complete. Check your connection and try again.';

  @override
  String get nextLabelShort => 'Next';

  @override
  String get lessonUnavailable => 'Lesson unavailable';

  @override
  String get localProgressSaved =>
      'Progress saved on this device. It will sync automatically.';

  @override
  String get markLessonComplete => 'Mark lesson as complete';

  @override
  String get markComplete => 'Mark as complete';

  @override
  String get completedLabel => 'Completed';

  @override
  String askTutorAboutLesson(String name) {
    return 'Ask $name for help with this lesson';
  }

  @override
  String askTutorPrompt(String name) {
    return 'A question? Ask $name';
  }

  @override
  String get checkUnderstanding => 'Check your understanding';

  @override
  String get lessonCompletedCongrats => 'Lesson completed — well done!';

  @override
  String get startNextLesson => 'Start the next lesson';

  @override
  String get nextLesson => 'Next lesson';

  @override
  String get writeQuestionHint => 'Write your question…';

  @override
  String stepProgressA11y(int current, int total, String label) {
    return 'Step $current of $total: $label';
  }

  @override
  String get networkOfflineBanner =>
      'No network detected — previously loaded content remains available.';

  @override
  String welcomeName(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get closeLabel => 'Close';

  @override
  String get companionPromptExplain => 'Explain this concept';

  @override
  String get companionPromptSummarize => 'Summarise the key points';

  @override
  String get companionPromptExample => 'Give me a concrete example';

  @override
  String get companionPromptQuestions => 'Ask me 3 questions';

  @override
  String companionContext(String topic) {
    return 'Context: $topic';
  }

  @override
  String get chapterLabel => 'Chapter';

  @override
  String get chapterUnavailable => 'Chapter unavailable';

  @override
  String get chapterEyebrow => 'CHAPTER';

  @override
  String completedProgress(int done, int total) {
    return '$done/$total completed';
  }

  @override
  String get saveChapterOffline => 'Save this chapter for offline reading';

  @override
  String get reconnectToPrepareLessons => 'Reconnect to prepare all lessons.';

  @override
  String prepareChapterLessons(int count) {
    return 'Prepare the $count lessons in this chapter.';
  }

  @override
  String get prepareLabel => 'Prepare';

  @override
  String get backLabel => 'Go back';

  @override
  String get backToChapter => 'Back to chapter';

  @override
  String get lastLessonCompleted =>
      'You completed the final lesson in this chapter.';

  @override
  String nextStepLesson(String title) {
    return 'Next step: “$title”.';
  }
}
