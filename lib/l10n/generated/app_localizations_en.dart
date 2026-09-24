// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get adminManageProfile => 'Manage profile';

  @override
  String get adminSuspendProfile => 'Suspend profile';

  @override
  String get adminReactivateProfile => 'Reactivate profile';

  @override
  String get adminRestoreProfile => 'Restore profile';

  @override
  String get adminDeleteProfile => 'Delete profile';

  @override
  String get adminAccountUpdated => 'The profile has been updated.';

  @override
  String get adminDeleteProfileBody =>
      'The profile will be removed from directories and access will be blocked. Its data will be kept so general administration can restore it.';

  @override
  String get adminAccountDecisionBody =>
      'This decision changes account access. Its reason will be kept in the administration history.';

  @override
  String get adminDecisionReason => 'Reason for this decision';

  @override
  String get adminCreateStudent => 'Add a student';

  @override
  String get adminCreateStudentBody =>
      'Create an account in the selected school. The student will sign in with their phone, then complete their class and preferences.';

  @override
  String get adminStudentCreated =>
      'The student account has been created. They can sign in with their phone.';

  @override
  String get adminStudentContactExists =>
      'This phone or email already has an account. Find it using account search.';

  @override
  String get adminStudentFirstName => 'First name';

  @override
  String get adminStudentLastName => 'Last name';

  @override
  String get adminFieldRequired => 'This field is required.';

  @override
  String get adminStudentEmailOptional => 'Email (optional)';

  @override
  String get adminInvalidEmail => 'Check the email address.';

  @override
  String get adminStatusSuspended => 'Account suspended';

  @override
  String get adminStatusDeleted => 'Profile deleted';

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
      'Choosing your school gives no access to private data. Your access is checked before it opens.';

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
  String get phoneIdentityTarget => 'Your phone number';

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
      'Too many code requests for this number. Wait a while before trying again: it can take more than an hour. If your account has an email, you can use it to sign in.';

  @override
  String get phoneErrorAppVerification =>
      'This app version could not be verified. Contact support with the reference below.';

  @override
  String get phoneErrorCaptcha =>
      'The security check did not complete. Try again from the app.';

  @override
  String phoneRequestPause(int seconds) {
    return 'Request again in ${seconds}s';
  }

  @override
  String get phoneErrorQuota =>
      'SMS delivery is temporarily unavailable. Try again later.';

  @override
  String get phoneErrorNetwork =>
      'The connection was interrupted. Check your internet connection and try again.';

  @override
  String get phoneErrorDisabled =>
      'Phone sign-in is not available right now. Try again later.';

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
  String get linkChildrenSubtitle =>
      'Your child finds this code in their profile, under “My parent code”. You can also link them later.';

  @override
  String get childIdentifierLabel => 'Your child’s parent code';

  @override
  String get childIdentifierHint => 'e.g. K7PM2QXA';

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
      'The account and its data will be deleted in 7 days. Until then, the account stays usable and the request can be cancelled from this screen.';

  @override
  String get sendRequestLabel => 'Send request';

  @override
  String get deleteRequestError =>
      'The request cannot be sent right now. Try again later.';

  @override
  String deleteScheduledSubtitle(String date) {
    return 'Deletion scheduled for $date. Tap to cancel.';
  }

  @override
  String deleteScheduledConfirmation(String date) {
    return 'Deletion scheduled for $date. It can be cancelled until then.';
  }

  @override
  String get deleteInProgressSubtitle => 'Deletion is being processed.';

  @override
  String get cancelDeletionQuestion => 'Cancel the deletion?';

  @override
  String get cancelDeletionBody =>
      'The account will be kept and the request dropped.';

  @override
  String get cancelDeletionAction => 'Cancel deletion';

  @override
  String get cancelDeletionDone => 'The deletion is cancelled.';

  @override
  String get cancelDeletionError =>
      'The request cannot be cancelled right now. Try again later.';

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
  String get learnEyebrow => 'Explore · understand · progress';

  @override
  String get learnUnavailableTitle => 'Your subjects are on their way';

  @override
  String get learnUnavailableBody =>
      'Nothing to show yet. Continue your learning path, then come back here.';

  @override
  String get learnUnavailableOfflineBody =>
      'Check your connection, then refresh. Your learning path stays available.';

  @override
  String get learnSubtitle => 'Your subjects, adapted to your level.';

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
  String prepareChapterLessons(int count) {
    return 'Prepare the $count lessons in this chapter.';
  }

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

  @override
  String get phoneProfileChoicePrompt =>
      'This number does not have a profile yet. Choose the account to create:';

  @override
  String get phoneCreateStudentProfile => 'Create my student profile';

  @override
  String get phoneCreateParentProfile => 'Create a parent profile';

  @override
  String get authProfileSetupTitle => 'Account setup';

  @override
  String get authCompleteProfileTitle => 'Complete your profile';

  @override
  String get authSessionActiveTitle => 'Your session is still active';

  @override
  String get authChooseProfileBody =>
      'Choose the profile to create. Your number is already verified.';

  @override
  String get authProfileSyncFailureBody =>
      'The profile could not be synchronized. No automatic sign-out was performed.';

  @override
  String get chooseRolePrompt => 'I am…';

  @override
  String get adminRole => 'Administration';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationMarkAllRead => 'Mark all read';

  @override
  String get notificationsUnavailable => 'Notifications unavailable';

  @override
  String get notificationsSyncError =>
      'The inbox could not be synchronized. Check your connection and try again.';

  @override
  String get notificationsEmptyTitle => 'All quiet';

  @override
  String get notificationsEmptyBody =>
      'Learning reminders, news and important messages will appear here.';

  @override
  String get notificationPermissionDenied =>
      'Permission denied. The inbox remains available here.';

  @override
  String get notificationEnableTitle => 'Never miss an update';

  @override
  String get notificationEnableBody =>
      'Enable system alerts. Every message is also kept in this inbox.';

  @override
  String get notificationEnableAction => 'Enable alerts';

  @override
  String get profileUnavailable => 'Profile unavailable';

  @override
  String get profileUnavailableBody =>
      'The profile could not be loaded. Check your connection and try again.';

  @override
  String get loginEmailImmutable =>
      'The sign-in address cannot be changed here.';

  @override
  String get phoneOptionalLabel => 'Phone number (optional)';

  @override
  String get invalidCameroonPhone => 'Enter a valid Cameroon phone number.';

  @override
  String get savingLabel => 'Saving…';

  @override
  String get saveLabel => 'Save';

  @override
  String get profileRestrictedFields =>
      'Class, role and school can only be changed by an authorised person.';

  @override
  String profileNameLengthError(String label) {
    return '$label must contain between 2 and 60 characters.';
  }

  @override
  String get profileUpdated => 'Profile updated.';

  @override
  String get kiraDiscoveryPhraseOne =>
      'She takes the time to explain things clearly.';

  @override
  String get kiraDiscoveryPhraseTwo =>
      'She moves forward with method and calm.';

  @override
  String get kiraDiscoveryPhraseThree =>
      'She helps you understand without pressure.';

  @override
  String get leoDiscoveryPhraseOne =>
      'He turns every concept into a challenge.';

  @override
  String get leoDiscoveryPhraseTwo =>
      'He encourages you to go a little further.';

  @override
  String get leoDiscoveryPhraseThree =>
      'He celebrates every step forward with you.';

  @override
  String get discoverLeo => 'Discover Léo';

  @override
  String get returnToKira => 'Return to Kira';

  @override
  String discoverCompanionBeforeChoice(String name) {
    return 'Meet $name before choosing';
  }

  @override
  String companionChosenA11y(String name) {
    return '$name selected';
  }

  @override
  String chooseCompanionA11y(String name) {
    return 'Choose $name';
  }

  @override
  String currentCompanionLabel(String name) {
    return '$name, your companion';
  }

  @override
  String get subjectMathematics => 'Mathematics';

  @override
  String get subjectFrench => 'French';

  @override
  String get subjectGeography => 'Geography';

  @override
  String get classPremiereDisplay => 'Première';

  @override
  String get stateLoadingTitle => 'Loading…';

  @override
  String get stateEmptyTitle => 'Nothing here yet';

  @override
  String get stateNoResultsTitle => 'No results';

  @override
  String get stateComingSoonTitle => 'Content coming soon';

  @override
  String get stateRetryableErrorTitle => 'Something went wrong';

  @override
  String get stateFatalErrorTitle => 'An unexpected error occurred';

  @override
  String get stateOfflineTitle => 'You are offline';

  @override
  String get stateAccessDeniedTitle => 'Access denied';

  @override
  String get stateLockedTitle => 'Content locked';

  @override
  String get stateSuccessTitle => 'Done!';

  @override
  String get stateOfflineBody =>
      'Check your connection and try again. Content you have already opened remains available.';

  @override
  String get stateAccessDeniedBody =>
      'Your account cannot access this content. Sign in again or contact your school.';

  @override
  String get stateRetryableErrorBody =>
      'The problem is not on your side. Try again in a moment.';

  @override
  String completionPercent(int percent) {
    return '$percent% completed';
  }

  @override
  String get nextUpA11y => ', next up';

  @override
  String lessonTileA11y(int index, String title, String status, String next) {
    return 'Lesson $index: $title, $status$next';
  }

  @override
  String subjectTileA11y(String title, int percent, String lessons) {
    return '$title, $percent% completed, $lessons';
  }

  @override
  String get lessonProgressQueuedOffline =>
      'Offline: your progress will be validated after reconnecting.';

  @override
  String get lessonProgressSaveFailed =>
      'Unable to save right now. Try again in a moment.';

  @override
  String get removeFromFavorites => 'Remove from favourites';

  @override
  String get addToFavorites => 'Add to favourites';

  @override
  String lessonReadingMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min read',
      one: '1 min read',
      zero: 'Less than one minute to read',
    );
    return '$_temp0';
  }

  @override
  String miniQuizScoreSuccess(int score, int total) {
    return 'Score: $score/$total — well done!';
  }

  @override
  String miniQuizScoreReview(int score, int total) {
    return 'Score: $score/$total — review the lesson and try again.';
  }

  @override
  String get submitMiniQuiz => 'Submit mini quiz';

  @override
  String get answerAllBeforeSubmit => 'Answer every question before submitting';

  @override
  String get answerAllQuestions => 'Answer every question';

  @override
  String correctAnswerA11y(String answer) {
    return 'Correct answer: $answer';
  }

  @override
  String incorrectAnswerA11y(String answer) {
    return 'Your answer is incorrect: $answer';
  }

  @override
  String get quizProfileIncompleteBody =>
      'Choose your class in your profile to see quizzes for your level.';

  @override
  String get quizCatalogDeniedBody =>
      'Your quizzes are not open for your profile yet. You can continue with your lessons meanwhile.';

  @override
  String get quizCatalogUnavailableBody =>
      'Your quizzes are temporarily out of reach. Continue your learning path or your lessons meanwhile.';

  @override
  String get quizCatalogInvalidBody =>
      'Some quizzes are not ready yet. You can continue your learning path and come back to practise in a moment.';

  @override
  String get quizCatalogNetworkBody =>
      'The connection was interrupted. Your lessons and learning path remain available.';

  @override
  String get quizOfflineTitle => 'Quizzes are waiting for a connection';

  @override
  String get quizOfflineBody =>
      'A quiz needs the internet: it is checked online and your answers are not kept on the phone. You can continue your learning path or a downloaded lesson.';

  @override
  String get openOfflineFlow => 'Open my learning path offline';

  @override
  String get viewDownloadedLessons => 'View my downloaded lessons';

  @override
  String get allLabel => 'All';

  @override
  String get quizModeTraining => 'Training';

  @override
  String get quizModeExam => 'Assessment / mock exam';

  @override
  String get quizModeUnspecified => 'Mode not specified';

  @override
  String get quizHubIntro =>
      'Practise with guided feedback or assess yourself under mock exam conditions.';

  @override
  String get chooseRevisionMode => 'Choose your revision mode';

  @override
  String get quizPausedOfflineTitle => 'Quizzes paused offline';

  @override
  String get quizPausedOfflineBody =>
      'Answers are checked online. Your answers and the corrections are not kept on the phone.';

  @override
  String get displayLabel => 'Show';

  @override
  String get filterQuizByModeA11y => 'Filter quizzes by mode';

  @override
  String get quizComingTitle => 'Quizzes for your class are coming';

  @override
  String get quizComingBody =>
      'New quizzes are being prepared for your level. In the meantime, review a lesson or start your learning path from the home screen.';

  @override
  String get quizTrainingAction => 'Practise';

  @override
  String get quizTrainingDescription =>
      'Guided feedback helps you understand before continuing.';

  @override
  String get quizExamAction => 'Assess myself';

  @override
  String get quizExamDescription =>
      'Answers are checked at the end. These quizzes prepare you for assessments without replacing an official exam.';

  @override
  String get studentSpace => 'Student space';

  @override
  String get quizTitle => 'Quiz';

  @override
  String get quizEyebrow => 'Practise · test yourself';

  @override
  String get quizUnavailableTitle => 'Your quizzes are on their way';

  @override
  String get quizUnavailableBody =>
      'Nothing to practise yet. Continue your learning path, then come back here.';

  @override
  String get quizUnavailableOfflineBody =>
      'Check your connection, then refresh. Your learning path stays available.';

  @override
  String get quizUnavailableModesLabel =>
      'Two ways to practise are waiting for you';

  @override
  String get quizHistoryLoading => 'Loading validated attempts…';

  @override
  String get quizHistoryUnavailable => 'History is unavailable right now.';

  @override
  String get quizNoValidatedAttempt => 'No validated attempts yet.';

  @override
  String lastScore(String score) {
    return 'Latest score: $score';
  }

  @override
  String get myResults => 'My results';

  @override
  String get quizResultsLoadFailed =>
      'Unable to retrieve validated results. Your quizzes remain available.';

  @override
  String get quizFirstResultBody =>
      'Your first result will appear here once your attempt is checked.';

  @override
  String get quizMasteryUnavailable =>
      'Mastery by topic is not shown because current attempts do not yet record validated learning skills.';

  @override
  String get dateUnavailable => 'Date unavailable';

  @override
  String pointsEarned(int count) {
    return '+$count points';
  }

  @override
  String get scoreUnavailable => 'Score unavailable';

  @override
  String get quizTrainingGuide => 'Guided feedback during the quiz.';

  @override
  String get quizExamGuide => 'Full correction after submission.';

  @override
  String questionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
      zero: 'No questions',
    );
    return '$_temp0';
  }

  @override
  String get unavailableOfflineA11y => ' Unavailable offline.';

  @override
  String get quizNeedsNetworkTitle => 'This quiz needs a connection';

  @override
  String get quizNeedsNetworkBody =>
      'Answers are checked online and nothing is kept on the phone. Reconnect to begin, or continue an activity available without internet.';

  @override
  String get quizPlayOfflineTitle => 'Quiz unavailable offline';

  @override
  String get quizPlayOfflineBody =>
      'This quiz needs the internet to be checked. Reconnect, or continue an activity already available on this phone.';

  @override
  String get quizQuestionsComingTitle => 'Questions are being prepared';

  @override
  String get quizQuestionsComingBody =>
      'This quiz is published, but its questions are not available yet.';

  @override
  String get leaveQuizTitle => 'Leave this quiz?';

  @override
  String get leaveQuizBody => 'The answers in this attempt will be lost.';

  @override
  String get continueQuiz => 'Continue quiz';

  @override
  String get leaveAndDiscardAnswers => 'Leave and discard my answers';

  @override
  String get checkAnswerAction => 'Check';

  @override
  String get finishLabel => 'Finish';

  @override
  String get guidedCorrectionUnavailableTitle => 'Feedback unavailable';

  @override
  String guidedCorrectionFailureBody(String reason) {
    return '$reason\nYour answer stays on this screen.';
  }

  @override
  String get continueWithoutCorrection => 'Continue without feedback';

  @override
  String get correctAnswerTitle => 'Correct answer!';

  @override
  String get keyTakeawayTitle => 'Key takeaway';

  @override
  String expectedAnswer(String answer) {
    return 'Expected answer: $answer';
  }

  @override
  String unansweredQuestionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unanswered questions',
      one: '1 unanswered question',
      zero: 'No unanswered questions',
    );
    return '$_temp0';
  }

  @override
  String get incompleteQuizBody =>
      'You can return to the first incomplete question or submit now.';

  @override
  String get completeMyAnswers => 'Complete my answers';

  @override
  String get submitAnyway => 'Submit anyway';

  @override
  String quizSubmissionFailureBody(String reason) {
    return '$reason Your answers remain on this screen: try again without re-entering them. No offline copy is created.';
  }

  @override
  String get quizAnswerCheckNetworkError =>
      'The connection is too weak to check this answer. Try again when the network returns.';

  @override
  String get quizAnswerCheckUnavailable =>
      'Guided feedback is unavailable right now.';

  @override
  String get quizAnswerCheckFailed =>
      'This answer cannot be checked right now.';

  @override
  String get quizAnswerCheckGenericError =>
      'Guided feedback is not responding right now. Check your connection and try again.';

  @override
  String get quizSubmissionNotFound => 'Quiz not found or unavailable.';

  @override
  String get quizSubmissionPrecondition => 'This quiz cannot be submitted yet.';

  @override
  String get quizSubmissionAlreadyExists =>
      'This attempt has already been used.';

  @override
  String get quizSubmissionDenied => 'You cannot submit this quiz.';

  @override
  String get quizSubmissionInvalid => 'The attempt contains invalid answers.';

  @override
  String get quizSubmissionUnauthenticated => 'Sign in to validate the quiz.';

  @override
  String get quizSubmissionUnavailable =>
      'Your attempt could not be checked right now. Try again in a moment.';

  @override
  String get singleAnswerQcm => 'Multiple choice — One correct answer';

  @override
  String get selectedA11y => ', selected';

  @override
  String quizOptionA11y(String letter, String answer, String selected) {
    return 'Answer $letter: $answer$selected';
  }

  @override
  String get shortAnswerInstruction => 'Answer in a few words';

  @override
  String get yourAnswerHint => 'Your answer…';

  @override
  String get trueOrFalse => 'True or false';

  @override
  String get trueLabel => 'True';

  @override
  String get falseLabel => 'False';

  @override
  String get backToQuizzes => 'Back to quizzes';

  @override
  String get replayMyMistakes => 'Replay my mistakes';

  @override
  String get restartQuiz => 'Start again';

  @override
  String get detailedCorrection => 'Detailed feedback';

  @override
  String mistakeProgress(int current, int total) {
    return 'Mistake $current/$total';
  }

  @override
  String get mentalAnswerInstruction =>
      'Answer mentally, then reveal the correction.';

  @override
  String get revealAnswer => 'Reveal answer';

  @override
  String get finishReview => 'Finish review';

  @override
  String get nextMistake => 'Next mistake';

  @override
  String get excellentResult => 'Excellent!';

  @override
  String get wellDoneResult => 'Well done!';

  @override
  String get keepGoingResult => 'Keep going!';

  @override
  String get zeroPoints => '0 points';

  @override
  String get yourAnswerLabel => 'Your answer';

  @override
  String get correctAnswerLabel => 'Correct answer';

  @override
  String quizImprovement(int delta) {
    return '+$delta% compared with your previous attempt';
  }

  @override
  String quizImprovementA11y(String label) {
    return 'Score improved: $label';
  }

  @override
  String get continueWithFlow => 'Continue My Learning Path';

  @override
  String get homeLabel => 'Home';

  @override
  String get companionNavLabel => 'Companion';

  @override
  String get profileNavLabel => 'Profile';

  @override
  String get homeLoadError => 'The home screen couldn’t be shown';

  @override
  String get flowSyncSignedOut =>
      'Sign in to have your learning path points validated.';

  @override
  String get flowSyncUnavailable =>
      'Your points could not be validated right now. Your answer is kept.';

  @override
  String get flowSyncQueued =>
      'Answer saved offline. Points will be validated at the next sync.';

  @override
  String get flowSyncNotEligible =>
      'Learning path point validation is reserved for student profiles.';

  @override
  String get flowSyncContentNotValidated =>
      'This learning path activity is not ready yet.';

  @override
  String get flowSyncDuplicate =>
      'This validation has already been used for another activity.';

  @override
  String get flowSyncInvalidAnswer =>
      'The answer sent for this activity is invalid.';

  @override
  String get flowSyncUnknown =>
      'Learning path points cannot be validated at the moment.';

  @override
  String get flowDailyCapReached =>
      'Daily cap reached: come back tomorrow to earn more points.';

  @override
  String get companionSend => 'Send';

  @override
  String get companionHistoryTitle => 'Your conversations';

  @override
  String get companionHistoryEmpty => 'Your conversations will appear here.';

  @override
  String get companionNewConversation => 'New conversation';

  @override
  String companionSaveDeferred(String name) {
    return '$name is your companion. Syncing with your profile will happen on its own.';
  }

  @override
  String get authGatewayTitle => 'Welcome to INTELLIA237';

  @override
  String get authGatewaySubtitle =>
      'A secure learning space, built for Cameroon.';

  @override
  String get todayEyebrow => 'Today';

  @override
  String get firstSessionEyebrow => 'To begin';

  @override
  String get firstSessionTitle => 'Choose your first activity';

  @override
  String get resumeWhereLeftOff => 'Pick up where you left off';

  @override
  String get keepMomentum => 'Keep up the momentum.';

  @override
  String get exploreEyebrow => 'Explore';

  @override
  String get chooseNextActivity => 'Choose your next activity';

  @override
  String get homeLessonsComingTitle => 'Your lessons are coming';

  @override
  String get homeLessonsComingBody =>
      'Lessons for your class are being prepared. In the meantime, discover your learning path or review with your companion.';

  @override
  String get discoverFlow => 'Explore My Learning Path';

  @override
  String get talkToCompanion => 'Write to my companion';

  @override
  String get forYouEyebrow => 'For you';

  @override
  String get adaptiveJourneyTitle => 'A journey that grows with you';

  @override
  String get demoDataLabel => 'Demo data';

  @override
  String get settingsDescription => 'Reading, animations, data and privacy';

  @override
  String get myProfileTitle => 'My profile';

  @override
  String get testAppVersionA11y => 'Test application version';

  @override
  String get versionLoading => 'Reading version';

  @override
  String get versionUnavailable => 'Version unavailable';

  @override
  String get intelliaUser => 'Intellia 237 user';

  @override
  String get studentAccount => 'Student account';

  @override
  String get academicJourney => 'Academic journey';

  @override
  String get loadErrorLabel => 'Loading error';

  @override
  String get classLabel => 'Class';

  @override
  String get statisticsAndProgress => 'Statistics and progress';

  @override
  String get statisticsUnavailable => 'Statistics unavailable';

  @override
  String get pointsLabel => 'Points';

  @override
  String get levelLabel => 'Level';

  @override
  String get currentStreak => 'Current streak';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: '0 days',
    );
    return '$_temp0';
  }

  @override
  String get progressLabel => 'Progress';

  @override
  String get statisticsComingTitle => 'Your statistics are coming';

  @override
  String get statisticsComingBody =>
      'Complete your first lesson or quiz to see your points and progress here.';

  @override
  String get companionSaveDenied =>
      'This companion cannot be saved to your profile.';

  @override
  String get companionSaveNetworkError =>
      'The network is unavailable. Try again in a moment.';

  @override
  String get companionSaveFailed =>
      'The companion could not be saved right now.';

  @override
  String get noCompanionSelected => 'No companion selected';

  @override
  String get chooseCompanionToPersonalize =>
      'Choose a companion to personalise your experience';

  @override
  String get dailyChallenges => 'Today’s challenges';

  @override
  String challengesRenewIn(String duration) {
    return 'Challenges renew in $duration';
  }

  @override
  String challengeCompletedA11y(String title) {
    return 'Challenge completed: $title';
  }

  @override
  String challengeRewardA11y(String title, int points) {
    return 'Challenge: $title, reward $points points';
  }

  @override
  String progressOverviewA11y(int percent, int level, int points) {
    return 'My progress: $percent% overall, level $level, $points points. Open profile.';
  }

  @override
  String get myProgress => 'My progress';

  @override
  String levelShort(int level) {
    return 'Lvl $level';
  }

  @override
  String get currentLevel => 'Current level';

  @override
  String levelValue(int level) {
    return 'Level $level';
  }

  @override
  String get globalLabel => 'overall';

  @override
  String get quickQuiz => 'Quick quiz';

  @override
  String get personalizedRecommendations => 'Personalised recommendations';

  @override
  String resumeLessonA11y(String title, int percent) {
    return 'Resume lesson $title, $percent percent complete.';
  }

  @override
  String get resumeLastLesson => 'Resume last lesson';

  @override
  String streakA11y(int count, String message) {
    return '$count day streak. $message';
  }

  @override
  String streakDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day streak',
      one: '1-day streak',
      zero: '0-day streak',
    );
    return '$_temp0';
  }

  @override
  String get mySpace => 'My space';

  @override
  String get myLearningSpace => 'My learning space';

  @override
  String openNotificationsA11y(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Open notifications, $count unread',
      one: 'Open notifications, 1 unread',
      zero: 'Open notifications',
    );
    return '$_temp0';
  }

  @override
  String get openMyProfile => 'Open my profile';

  @override
  String get subjectsTitle => 'Subjects';

  @override
  String subjectProgressA11y(String title, int percent) {
    return '$title, $percent% completed';
  }

  @override
  String weeklyGoalProgressA11y(int done, int total, String status) {
    return 'My weekly goal: $done of $total sessions. $status';
  }

  @override
  String get goalAchievedA11y => 'Goal achieved.';

  @override
  String get myWeeklyGoal => 'My weekly goal';

  @override
  String get editMyGoal => 'Edit my goal';

  @override
  String get goalAchievedMessage => 'Goal achieved — a great week!';

  @override
  String weeklyGoalProgressSummary(int done, int total, int minutes) {
    return '$done/$total sessions · about $minutes min each';
  }

  @override
  String openPrioritySubjectA11y(String subject) {
    return 'Open my priority subject: $subject';
  }

  @override
  String prioritySubject(String subject) {
    return 'Priority: $subject';
  }

  @override
  String get setWeeklyPace => 'Set my weekly pace';

  @override
  String get setYourWeeklyPace => 'Set your weekly pace';

  @override
  String get weeklyPaceChoices => 'Choose 2, 3 or 5 sessions.';

  @override
  String get weeklyGoalExplanation =>
      'Choose a realistic pace. The counter restarts every Monday, with no pressure.';

  @override
  String get sessionsPerWeek => 'Sessions per week';

  @override
  String get sessionDuration => 'Session duration';

  @override
  String get prioritySubjectOptional => 'Priority subject (optional)';

  @override
  String get noneLabel => 'None';

  @override
  String get saveMyGoal => 'Save my goal';

  @override
  String get removeGoal => 'Remove goal';

  @override
  String get childOverviewTitle => 'Child overview';

  @override
  String get childNotFound => 'Child not found.';

  @override
  String get weeklyProgress => 'Weekly progress';

  @override
  String get progressChartComing =>
      'The chart will appear after the first activities.';

  @override
  String get strongSubjects => 'Strong';

  @override
  String get needsImprovement => 'Needs improvement';

  @override
  String get viewDetailedProgress => 'View detailed progress';

  @override
  String get notMeasuredYet => 'Not measured yet';

  @override
  String get childProgressTitle => 'Child progress';

  @override
  String childSevenDayProgress(String name) {
    return '$name — 7-day progress';
  }

  @override
  String get todayStudy => 'Today’s study';

  @override
  String get dailyTrend => 'Daily trend';

  @override
  String get childrenLabel => 'Children';

  @override
  String get announcementsLabel => 'Announcements';

  @override
  String get subscriptionLabel => 'Subscription';

  @override
  String get parentSpace => 'Parent space';

  @override
  String get myChildren => 'My children';

  @override
  String get paymentsLabel => 'Payments';

  @override
  String get parentSpaceUnavailable => 'Parent space unavailable';

  @override
  String get parentSpaceDescription =>
      'A clear, reassuring view of school progress.';

  @override
  String globalProgressPercent(int percent) {
    return 'Overall progress $percent%';
  }

  @override
  String get progressComingAfterActivities =>
      'Progress will appear after the first activities.';

  @override
  String get activityChartComing => 'Activity chart coming';

  @override
  String childWeeklyProgressComing(String name) {
    return '$name’s weekly progress will appear here after the first lessons and quizzes.';
  }

  @override
  String get subjectsToImprove => 'Needs support';

  @override
  String get subjectStrengthsComing =>
      'Strengths and subjects to improve will be identified after the first assessments.';

  @override
  String get schoolAnnouncements => 'School announcements';

  @override
  String get parentAccountActiveBody =>
      'Your account is active. Linked children will appear here after the link is validated.';

  @override
  String get noChildLinked => 'No child linked';

  @override
  String get linkChildHelp =>
      'Add a child code from the profile or ask the school to create the link.';

  @override
  String get overviewLabel => 'Overview';

  @override
  String get parentProfile => 'Parent profile';

  @override
  String get parentAccountActive => 'Parent account active';

  @override
  String get parentSettingsDescription =>
      'Reading, notifications, data and privacy';

  @override
  String get toBeDetermined => 'To be determined';

  @override
  String get studyTimeComing =>
      'Study time will be displayed once the measurement is available.';

  @override
  String get todayStudyTime => 'Today’s study time';

  @override
  String studyMinutesGoal(int done, int goal) {
    return '$done min / $goal min goal';
  }

  @override
  String get badgeUnlocked => 'Badge unlocked';

  @override
  String get discoverAnswer => 'Reveal answer';

  @override
  String get newLabel => 'NEW';

  @override
  String get flowEntryDescription => 'Learn by swiping,\none card at a time.';

  @override
  String get missingAnswerHint => 'Enter the missing word or number';

  @override
  String get submitMyAnswer => 'Submit my answer';

  @override
  String get checkOrder => 'Check order';

  @override
  String sessionVerifiedPoints(int count) {
    return '$count points verified in this session';
  }

  @override
  String get totalPendingShort => 'Total —';

  @override
  String totalPointsShort(int count) {
    return '$count total';
  }

  @override
  String get totalPendingValidation => 'Total waiting to be checked';

  @override
  String totalVerifiedPoints(int count) {
    return '$count verified points in total';
  }

  @override
  String pendingValidationShort(int count) {
    return '$count pending';
  }

  @override
  String offlineActivitiesToSync(int count) {
    return '$count offline activities to sync';
  }

  @override
  String get verifiedSession => 'Verified session';

  @override
  String get verifiedTotal => 'Verified total';

  @override
  String get pendingValidationLabel => 'Pending';

  @override
  String activeTab(String label) {
    return 'Active tab: $label';
  }

  @override
  String get startupInterrupted => 'Startup interrupted';

  @override
  String roleSpace(String role) {
    return '$role space';
  }

  @override
  String welcomeRoleSpace(String role) {
    return 'Welcome to the $role space';
  }

  @override
  String get roleOptionsBody => 'View the options available for your profile.';

  @override
  String get skipLabel => 'Skip';

  @override
  String get probatoireLevel => 'Probatoire';

  @override
  String get baccalaureateLevel => 'Baccalaureate';

  @override
  String chooseTutorA11y(String name) {
    return 'Choose $name as your tutor';
  }

  @override
  String get chooseYourTutor => 'Choose your tutor';

  @override
  String get tutorJourneyDescription =>
      'Your tutor will support you throughout your journey';

  @override
  String get activationEyebrow => 'INTELLIA // AWAKENING';

  @override
  String get activationTitle => 'Knowledge is waiting for your signal.';

  @override
  String get knowledgeEyebrow => 'A WORLD OF KNOWLEDGE';

  @override
  String get knowledgeTitle => 'Every subject opens a new path.';

  @override
  String get knowledgeBody =>
      'Mathematics, English, French and science: begin with the subject that draws you in.';

  @override
  String get challengeEyebrow => 'FIRST CHALLENGE';

  @override
  String get challengeTitle => 'Understanding matters more than guessing.';

  @override
  String get challengeBody =>
      'Give it a try. If you hesitate, INTELLIA breaks down the reasoning with you.';

  @override
  String get companionsEyebrow => 'TWO ENERGIES';

  @override
  String get companionsTitle => 'Two personalities. One goal.';

  @override
  String get companionsBody =>
      'Helping you progress with an explanation style that fits you.';

  @override
  String get journeyEyebrow => 'INTELLIA JOURNEY';

  @override
  String get journeyTitle => 'A challenge becomes mastery.';

  @override
  String get journeyBody =>
      'INTELLIA237 connects lessons, practice and quizzes in one coherent journey.';

  @override
  String get portalEyebrow => 'YOUR SPACE TAKES SHAPE';

  @override
  String get portalTitle => 'Your journey begins now.';

  @override
  String get portalBody =>
      'Find your subjects, challenges and companion in one experience.';

  @override
  String get holdToEnterIntellia => 'Press and hold to enter INTELLIA237';

  @override
  String get holdCenterToActivate => 'Hold the centre until activation';

  @override
  String answerChoiceA11y(String answer) {
    return 'Answer $answer';
  }

  @override
  String continueAfterDiscovering(String name) {
    return 'Continue after discovering $name';
  }

  @override
  String continueWithCompanion(String name) {
    return 'Continue with $name';
  }

  @override
  String discoverCompanionA11y(String name) {
    return 'Discover $name';
  }

  @override
  String get kiraOnboardingSignature => 'CALM • METHOD • CONFIDENCE';

  @override
  String get kiraOnboardingExample =>
      'Let’s revisit the essential idea, then move forward together.';

  @override
  String get leoOnboardingSignature => 'CHALLENGE • ENERGY • GROWTH';

  @override
  String get leoOnboardingExample =>
      'Ready for a challenge? I’ll give you the clue that unlocks it.';

  @override
  String get lessonNodeLabel => 'LESSON';

  @override
  String get trainingNodeLabel => 'PRACTICE';

  @override
  String get reachMasteryA11y => 'Reach mastery and open the portal';

  @override
  String get masteryNodeLabel => 'MASTERY';

  @override
  String get tapMasteryInstruction => 'Tap mastery to open your space';

  @override
  String get chooseSubject => 'Choose a subject';

  @override
  String get yourLearningSpace => 'Your learning space';

  @override
  String get journeyAtYourPace => 'A journey at your pace';

  @override
  String get nextLessonPreview => 'Next lesson';

  @override
  String get equationsPreview => 'Equations';

  @override
  String get dailyChallengePreview => 'Today’s challenge';

  @override
  String get quizFiveMinutesPreview => 'Quiz • 5 min';

  @override
  String get factorizedLabel => 'Factorised';

  @override
  String get whoWillBeYourCompanion => 'Who will be your learning companion?';

  @override
  String get learningDialogueA11y => 'Learning dialogue';

  @override
  String get firstNameWithArticle => 'First name';

  @override
  String get lastNameWithArticle => 'Last name';

  @override
  String get passwordMinEight => 'At least 8 characters';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get confirmPasswordHint => 'Enter the password again';

  @override
  String get teacherRegistrationTitle => 'Create a Teacher account';

  @override
  String get teacherIdentityStep => 'Teacher identity';

  @override
  String get teachingStep => 'Teaching';

  @override
  String get teacherDetailsTitle => 'Teacher details';

  @override
  String get teacherDetailsSubtitle => 'Enter your sign-in details.';

  @override
  String get firstNameTeacherHint => 'E.g. Serge';

  @override
  String get lastNameTeacherHint => 'E.g. Mbarga';

  @override
  String get teacherEmailHint => 'teacher@example.com';

  @override
  String get teachingTitle => 'Your teaching';

  @override
  String get teachingSubtitle => 'Select the subjects and levels you teach.';

  @override
  String get taughtSubjectsTitle => 'Subjects taught';

  @override
  String get taughtSubjectsCaption => 'Select your main subjects.';

  @override
  String get taughtLevelsTitle => 'Levels taught';

  @override
  String get taughtLevelsCaption => 'Select the classes you cover.';

  @override
  String get teacherFinalSubtitle =>
      'Review your information before confirming.';

  @override
  String get teacherValidationNotice =>
      'Teacher account registration requires approval by an authorised team.';

  @override
  String get createTeacherAccount => 'Create my teacher account';

  @override
  String get adminRegistrationTitle => 'Create an Administration account';

  @override
  String get adminIdentityStep => 'Administrator identity';

  @override
  String get jobFunctionStep => 'Role';

  @override
  String get adminDetailsTitle => 'Administrator details';

  @override
  String get adminDetailsSubtitle =>
      'Information about the school leader or administrator.';

  @override
  String get firstNameAdminHint => 'E.g. Nadine';

  @override
  String get lastNameAdminHint => 'E.g. Meka';

  @override
  String get adminEmailHint => 'administration@example.com';

  @override
  String get adminFunctionTitle => 'Your role';

  @override
  String get adminFunctionSubtitle =>
      'Describe your role within the administration.';

  @override
  String get jobTitleLabel => 'Job title';

  @override
  String get jobTitleHint => 'E.g. Principal, Head teacher, Deputy head';

  @override
  String get minimumThreeCharacters => 'At least 3 characters';

  @override
  String get adminAccreditationNotice =>
      'Your administration account will be reviewed by our team before activation.';

  @override
  String get adminFinalSubtitle =>
      'Your request will be submitted for approval.';

  @override
  String get adminValidationNotice =>
      'Once approved, you will receive an email inviting you to sign in to your administration console.';

  @override
  String get createAdminAccount => 'Submit my administration account';

  @override
  String get legalVersion => 'Version dated 16 July 2026';

  @override
  String get legalContactNotice =>
      'For questions or data requests, contact your school or the Intellia237 team. Local legal review is still required before commercial release.';

  @override
  String get legalTermsTitle => 'Terms of use';

  @override
  String get legalServicePurposeTitle => 'Purpose of the service';

  @override
  String get legalServicePurposeBody =>
      'Intellia237 provides educational resources, quizzes and a learning companion. It supports teaching and does not replace the school or teacher.';

  @override
  String get legalAccountSecurityTitle => 'Account and security';

  @override
  String get legalAccountSecurityBody =>
      'The information provided must be accurate. Sign-in details are personal. Teacher and administrator accounts may require approval.';

  @override
  String get legalResponsibleUseTitle => 'Responsible use';

  @override
  String get legalResponsibleUseBody =>
      'Users must not bypass assessment rules, extract other users’ data or use the companion to produce harmful content.';

  @override
  String get availabilityLabel => 'Availability';

  @override
  String get legalAvailabilityBody =>
      'Some features require a connection. Maintenance and temporary outages are communicated as clearly as possible.';

  @override
  String get legalPrivacyTitle => 'Privacy policy';

  @override
  String get legalCollectedDataTitle => 'Data collected';

  @override
  String get legalCollectedDataBody =>
      'Account, role, class, progress and attempts required by the service may be recorded. Requested data must remain limited to the educational purpose.';

  @override
  String get legalMinorsPrivacyTitle => 'Children and privacy';

  @override
  String get legalMinorsPrivacyBody =>
      'Conversations, free-text answers, names and emails must never be sent to audience measurement tools. Anonymous diagnostics are disabled by default.';

  @override
  String get legalRetentionAccessTitle => 'Retention and access';

  @override
  String get legalRetentionAccessBody =>
      'Data is accessible only to authorised people according to their role. Retention periods and access procedures must be approved before release.';

  @override
  String get legalYourRightsTitle => 'Your rights';

  @override
  String get legalYourRightsBody =>
      'A user or their representative may request access to, correction of or deletion of their data from the school or Intellia237 team.';

  @override
  String get legalEducationalDataTitle => 'Educational data processing';

  @override
  String get legalPurposeTitle => 'Purpose';

  @override
  String get legalPurposeBody =>
      'Answers, results and progress are used to suggest a next step, provide corrections and help an authorised teacher or parent support the student.';

  @override
  String get legalDecisionsTitle => 'Decisions';

  @override
  String get legalDecisionsBody =>
      'An automated recommendation is not an official school decision. The teacher and school remain responsible for academic assessment.';

  @override
  String get legalCompanionTitle => 'Learning companion';

  @override
  String get legalCompanionBody =>
      'Messages are sent to the service needed to generate a response. Students must not share sensitive personal information there.';

  @override
  String get readTerms => 'Read the terms';

  @override
  String get readPrivacy => 'Read the privacy policy';

  @override
  String get readEducationalData => 'Understand educational data';

  @override
  String get loadingOffer => 'Loading offer';

  @override
  String get serviceUnavailable => 'Service unavailable';

  @override
  String get subscriptionTitle => 'Subscription';

  @override
  String get mobileMoneyParentDescription =>
      'Mobile Money payment declared, then manually verified by the school of the child concerned.';

  @override
  String get myPaymentRequests => 'My requests';

  @override
  String accessDaysAfterApproval(int days) {
    return 'Access for $days days after approval';
  }

  @override
  String get mobileMoneyStepTransfer => '1. Make the transfer';

  @override
  String get operatorLabel => 'Operator';

  @override
  String get recipientNumberConfigured => 'Configured recipient number';

  @override
  String get copyNumber => 'Copy number';

  @override
  String get numberCopied => 'Number copied.';

  @override
  String get mobileMoneyNoDebitNotice =>
      'Intellia237 never initiates a debit. Make the transfer yourself in your operator’s app and check the number before confirming.';

  @override
  String get mobileMoneyStepProof => '2. Send proof of transfer';

  @override
  String get payerPhoneLabel => 'Number used to make the transfer';

  @override
  String get transactionReferenceLabel => 'Transaction reference';

  @override
  String get sendingLabel => 'Sending…';

  @override
  String get submitForReview => 'Submit for review';

  @override
  String get enterTransferDetails =>
      'Enter the phone number and transfer reference.';

  @override
  String get confirmDeclarationTitle => 'Confirm declaration';

  @override
  String confirmTransferDeclaration(
    String amount,
    String operator,
    String phone,
  ) {
    return 'You declare that you transferred $amount via $operator to $phone. Intellia237 will not debit any amount.';
  }

  @override
  String get paymentRequestSubmitted =>
      'Request submitted. Access will be activated only after verification.';

  @override
  String get noValidatedSchoolLinked =>
      'No approved school is linked to this parent account yet.';

  @override
  String get multipleSchoolsLinked =>
      'Your children attend different schools: choose the child you are paying for.';

  @override
  String get noActiveMobileMoneyOffer =>
      'This child’s school has not published an active Mobile Money offer yet.';

  @override
  String get offerUnavailable => 'Offer unavailable';

  @override
  String referenceValue(String reference) {
    return 'Reference $reference';
  }

  @override
  String schoolNote(String note) {
    return 'School note: $note';
  }

  @override
  String get mobileMoneyReferenceAlreadySubmitted =>
      'This reference has already been submitted. Check its status below.';

  @override
  String get mobileMoneyOfferNoLongerAvailable =>
      'The offer or school link is no longer available.';

  @override
  String get mobileMoneyPermissionDenied =>
      'Your account is not authorised to perform this operation.';

  @override
  String get mobileMoneyInvalidDetails =>
      'Check the phone number and transaction reference.';

  @override
  String get mobileMoneyTemporarilyUnavailable =>
      'The service is temporarily unavailable. Try again without repeating the transfer.';

  @override
  String get mobileMoneyGenericError =>
      'This request cannot be processed at the moment.';

  @override
  String get paymentPendingReview => 'Under review';

  @override
  String get paymentApproved => 'Approved';

  @override
  String get paymentRejected => 'Rejected';

  @override
  String get loadingPayments => 'Loading payments';

  @override
  String get paymentQueueUnavailable => 'Queue unavailable';

  @override
  String get mobileMoneyApprovalTitle => 'Mobile Money approval';

  @override
  String get mobileMoneyAdminDescription =>
      'Compare each reference with the operator portal before deciding. Intellia237 does not collect any payment.';

  @override
  String get noPendingPaymentRequest => 'No pending requests';

  @override
  String get payerPhoneShort => 'Payer phone';

  @override
  String get referenceLabel => 'Reference';

  @override
  String get rejectLabel => 'Reject';

  @override
  String get paymentVerifiedQuestion => 'Payment verified?';

  @override
  String paymentVerificationWarning(
    String amount,
    String reference,
    String operator,
  ) {
    return 'Confirm only if $amount and reference $reference appear in the $operator portal. This action will activate access.';
  }

  @override
  String get paymentVerifiedLabel => 'Payment verified';

  @override
  String get rejectPaymentRequest => 'Reject request';

  @override
  String get rejectionReasonOptional =>
      'Reason visible to the parent (optional)';

  @override
  String get rejectionReasonHint => 'E.g. reference not found';

  @override
  String get confirmRejection => 'Confirm rejection';

  @override
  String get paymentApprovedAndActivated =>
      'Payment approved and access activated.';

  @override
  String get paymentRequestRejected => 'Request rejected.';

  @override
  String get classesUnavailable => 'Classes unavailable';

  @override
  String get teacherAnalyticsTitle => 'Teacher analytics';

  @override
  String get teacherAnalyticsSubtitle =>
      'An overview of your classes’ performance.';

  @override
  String get averageCompletionRate => 'Average completion rate';

  @override
  String activeClassesCount(int count) {
    return '$count active classes';
  }

  @override
  String get dailyEngagement => 'Daily engagement';

  @override
  String get metricComingSoon => 'Metric coming soon';

  @override
  String trackedStudentsCount(int count) {
    return '$count students tracked';
  }

  @override
  String get weeklyTrend => 'Weekly trend';

  @override
  String get weeklyTrendEmpty =>
      'The trend will appear after your students’ first week of activity.';

  @override
  String get progressByClass => 'Progress by class';

  @override
  String get noDataAvailable => 'No data available.';

  @override
  String get classDetailTitle => 'Class details';

  @override
  String get publishAnnouncementShort => 'Post announcement';

  @override
  String get studentProgressTitle => 'Student progress';

  @override
  String get studentTrackingComing =>
      'Individual tracking is coming: students in this class will appear here with their progress after their first activities.';

  @override
  String studyMinutesToday(int count) {
    return '$count min today';
  }

  @override
  String get publishAnnouncementTitle => 'Post an announcement';

  @override
  String get titleLabel => 'Title';

  @override
  String get messageLabel => 'Message';

  @override
  String get announcementPublished => 'Announcement posted.';

  @override
  String get publishLabel => 'Publish';

  @override
  String get myClasses => 'My classes';

  @override
  String get classesLabel => 'Classes';

  @override
  String studentsCount(int count) {
    return '$count students';
  }

  @override
  String averageProgressPercent(int percent) {
    return 'Average progress $percent%';
  }

  @override
  String pendingSubmissionsCount(int count) {
    return '$count pending submissions';
  }

  @override
  String get contentManagementTitle => 'Content management';

  @override
  String get publishContentTitle => 'Publish content';

  @override
  String get classSecondeA => 'Seconde A';

  @override
  String get classSecondeC => 'Seconde C';

  @override
  String get classPremiereD => 'Première D';

  @override
  String get subjectLabel => 'Subject';

  @override
  String get subjectPhysics => 'Physics';

  @override
  String get lessonTitleLabel => 'Lesson title';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get chapterRequired => 'Chapter is required';

  @override
  String get summaryLabel => 'Summary';

  @override
  String get summaryRequired => 'Summary is required';

  @override
  String get publishingLabel => 'Publishing…';

  @override
  String get contentLabel => 'Content';

  @override
  String get contentPublishedSuccess => 'Content published successfully.';

  @override
  String get quizLabel => 'Quiz';

  @override
  String get statisticsLabel => 'Statistics';

  @override
  String get dashboardUnavailable => 'Dashboard unavailable';

  @override
  String get noClassesYet => 'No classes yet';

  @override
  String get noClassesYetBody =>
      'Your classes will appear here once your school assigns them. You can already prepare quizzes from the Quiz tab.';

  @override
  String get activeClassesTitle => 'Active classes';

  @override
  String get recentAnnouncements => 'Recent announcements';

  @override
  String get noRecentAnnouncement => 'No recent announcements.';

  @override
  String get teacherSpaceTitle => 'Teacher space';

  @override
  String get teacherSpaceDescription =>
      'Manage your classes, content and assessments from one dashboard.';

  @override
  String get studentsLabel => 'Students';

  @override
  String get completionLabel => 'Completion';

  @override
  String get dailyEngagementShort => 'Daily engagement';

  @override
  String get quizCreationTitle => 'Create a quiz';

  @override
  String get quizCreationSubtitle =>
      'Create an assessment and publish it to your classes.';

  @override
  String get quizTitleLabel => 'Quiz title';

  @override
  String get questionsLabel => 'Questions';

  @override
  String get addQuestion => 'Add a question';

  @override
  String get publishQuiz => 'Publish quiz';

  @override
  String get selectClassRequired => 'Select a class.';

  @override
  String get addCompleteQuestion => 'Add at least one complete question.';

  @override
  String get quizPublishedSuccess => 'Quiz published successfully.';

  @override
  String questionNumber(int index) {
    return 'Question $index';
  }

  @override
  String get deleteLabel => 'Delete';

  @override
  String get questionPromptLabel => 'Question';

  @override
  String get questionPromptHint => 'Enter the question';

  @override
  String get expectedAnswerLabel => 'Expected answer';

  @override
  String get expectedAnswerHint => 'Enter the answer';

  @override
  String get subjectBiology => 'Biology';

  @override
  String get subjectEnglish => 'English';

  @override
  String get subjectHistory => 'History';

  @override
  String get administrationRole => 'Administration';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get approvedStatus => 'Approved';

  @override
  String get hiddenStatus => 'Hidden';

  @override
  String get publishedStatus => 'Published';

  @override
  String get aiStatus => 'AI ✨';

  @override
  String get draftStatus => 'Draft';

  @override
  String get audienceWholeSchool => 'Whole school';

  @override
  String get beginnerDifficulty => 'Beginner';

  @override
  String get intermediateDifficulty => 'Intermediate';

  @override
  String get advancedDifficulty => 'Advanced';

  @override
  String get expertDifficulty => 'Expert';

  @override
  String get contentPluralLabel => 'Content';

  @override
  String get analyticsLabel => 'Analytics';

  @override
  String get usersLabel => 'Users';

  @override
  String get toolsLabel => 'Tools';

  @override
  String get teachersLabel => 'Teachers';

  @override
  String get parentsLabel => 'Parents';

  @override
  String get dailyActiveUsersShort => 'Daily active';

  @override
  String get pendingAccounts => 'Pending accounts';

  @override
  String get moderationTickets => 'Moderation tickets';

  @override
  String get adminSettingsDescription =>
      'Accessibility, diagnostics and privacy';

  @override
  String get recentOfficialAnnouncements => 'Recent official announcements';

  @override
  String get moderationLabel => 'Moderation';

  @override
  String administrationAtSchool(String school) {
    return 'Administration • $school';
  }

  @override
  String helloUser(String name) {
    return 'Hello, $name';
  }

  @override
  String get adminHeroDescription =>
      'Oversee platform usage and critical operations.';

  @override
  String get broadcastCenterTitle => 'Broadcast centre';

  @override
  String get broadcastCenterSubtitle =>
      'Publish targeted official announcements.';

  @override
  String get audienceLabel => 'Audience';

  @override
  String get messageRequired => 'Message is required';

  @override
  String get recentHistory => 'Recent history';

  @override
  String audienceValue(String audience) {
    return 'Audience: $audience';
  }

  @override
  String get contentModerationTitle => 'Content moderation';

  @override
  String get contentModerationSubtitle => 'Approve or hide reported content.';

  @override
  String get noModerationTicket => 'No moderation tickets.';

  @override
  String contentReports(String type, int count) {
    return '$type • $count report(s)';
  }

  @override
  String get contentHidden => 'Content hidden.';

  @override
  String get hideLabel => 'Hide';

  @override
  String get contentApproved => 'Content approved.';

  @override
  String get schoolAnalyticsTitle => 'School analytics';

  @override
  String get activeUsersSevenDays => 'Active users (7 days)';

  @override
  String get studyMinutesSevenDays => 'Total study minutes (7 days)';

  @override
  String get averageProgressRate => 'Average progress rate';

  @override
  String get metricAvailableAfterActivities =>
      'This metric will be available after students complete their first activities.';

  @override
  String get accountApprovalTitle => 'Account approvals';

  @override
  String pendingRequestsCount(int count) {
    return '$count pending request(s)';
  }

  @override
  String get noPendingRequest => 'No pending requests.';

  @override
  String get userManagementTitle => 'User management';

  @override
  String get accountRejected => 'Account rejected.';

  @override
  String get refuseLabel => 'Reject';

  @override
  String get accountApproved => 'Account approved.';

  @override
  String get unpublishLabel => 'Unpublish';

  @override
  String get addChapter => 'Add chapter';

  @override
  String get chaptersUnavailable => 'Chapters unavailable';

  @override
  String get noChapterAdmin => 'No chapters.\nTap + to begin.';

  @override
  String get newChapter => 'New chapter';

  @override
  String get chapterTitleLabel => 'Chapter title';

  @override
  String get shortDescriptionLabel => 'Short description';

  @override
  String get createLabel => 'Create';

  @override
  String lessonsCount(int count) {
    return '$count lesson(s)';
  }

  @override
  String get addLesson => 'Add lesson';

  @override
  String get lessonsUnavailable => 'Lessons unavailable';

  @override
  String get noLessonAdmin => 'No lessons.\nTap + to create one.';

  @override
  String get newLesson => 'New lesson';

  @override
  String get objectiveSummaryLabel => 'Objective / summary';

  @override
  String get estimatedDurationMinutes => 'Estimated duration (min)';

  @override
  String get lessonSaved => '✅ Lesson saved';

  @override
  String get lessonSaveFailed =>
      'The lesson could not be saved. Check your connection and try again.';

  @override
  String get lessonPublished => '🚀 Lesson published!';

  @override
  String get publicationFailed =>
      'Publishing failed. Check your connection and try again.';

  @override
  String get newSection => 'New section';

  @override
  String get courseContentLabel => 'Course content';

  @override
  String get lessonEditorTitle => 'Lesson editor';

  @override
  String get aiGeneratedReviewNotice =>
      'AI-generated content — Review before publishing';

  @override
  String get informationLabel => 'Information';

  @override
  String get learningObjectiveLabel => 'Learning objective';

  @override
  String get estimatedDurationLabel => 'Estimated duration';

  @override
  String get aiGenerationTitle => 'AI generation';

  @override
  String get aiGenerationBackendOnly =>
      'Automatic generation does not start from this screen.';

  @override
  String get aiGenerationBackendInstructions =>
      'Write the lesson here. To start from photographed course pages, use “Import pages” from the chapter: drafts are prepared for you to review before publishing.';

  @override
  String courseSectionsCount(int count) {
    return 'Course sections ($count)';
  }

  @override
  String get noCourseSection => 'No sections.\nAdd one manually.';

  @override
  String miniQuizQuestionsCount(int count) {
    return 'Mini quiz ($count questions)';
  }

  @override
  String get noGeneratedQuestion =>
      'No questions have been generated for this lesson.';

  @override
  String quizOptionsCorrectAnswer(int options, int answer) {
    return '$options options • Answer: $answer';
  }

  @override
  String get quizPublished => '🚀 Quiz published!';

  @override
  String get quizSaved => '✅ Quiz saved';

  @override
  String get quizSaveFailed =>
      'The quiz could not be saved. Check your connection and try again.';

  @override
  String get newQuiz => 'New Quiz';

  @override
  String get editQuiz => 'Edit Quiz';

  @override
  String get quizInformation => 'Quiz information';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get difficultyLabel => 'Difficulty';

  @override
  String get durationSecondsLabel => 'Duration (sec)';

  @override
  String get trainingModeLabel => 'Practice';

  @override
  String get examModeLabel => 'Exam';

  @override
  String get trainingCorrectionDescription =>
      'The correction is shown after each submitted answer.';

  @override
  String get examCorrectionDescription =>
      'The full correction is revealed only after submission.';

  @override
  String get targetLevels => 'Target levels';

  @override
  String questionsCount(int count) {
    return 'Questions ($count)';
  }

  @override
  String get noQuestionAdmin => 'No questions.\nAdd one manually.';

  @override
  String get newQuestion => 'New question';

  @override
  String get trueFalseShort => 'T/F';

  @override
  String get answerLabel => 'Answer';

  @override
  String optionNumber(int number) {
    return 'Option $number';
  }

  @override
  String get selectCorrectAnswerInstruction =>
      '• Select the correct answer using the radio button';

  @override
  String get correctAnswerColon => 'Correct answer:';

  @override
  String get acceptedAnswersLabel => 'Accepted answer(s) (separated by commas)';

  @override
  String get explanationLabel => 'Explanation';

  @override
  String get trueFalseLabel => 'True/False';

  @override
  String get shortAnswerLabel => 'Short answer';

  @override
  String get contentStudioTitle => 'Content Studio';

  @override
  String get subjectsAndCourses => 'Subjects & Courses';

  @override
  String noSubjectForClass(String classLevel) {
    return 'No subjects for $classLevel.\nAdd one to begin.';
  }

  @override
  String chaptersCount(int count) {
    return '$count chapter(s)';
  }

  @override
  String get noQuizForLevel => 'No quizzes for this level.';

  @override
  String quizQuestionsDifficulty(int count, String difficulty) {
    return '$count questions • $difficulty';
  }

  @override
  String get generatedByAi => 'Generated by AI';

  @override
  String get masteryTitle => 'Your learning';

  @override
  String get masteryBySubject => 'Subject by subject';

  @override
  String get masteryDimension => 'Mastery';

  @override
  String get masteryCoverage => 'Coverage';

  @override
  String get masteryContinuity => 'Continuity';

  @override
  String get masteryNoEvidence => 'Not enough evidence yet';

  @override
  String get masteryExploring => 'Exploring';

  @override
  String get masteryBuilding => 'Building';

  @override
  String get masteryUnderstood => 'Well understood';

  @override
  String get masterySolid => 'Solid';

  @override
  String get masteryConfidenceInsufficient => 'Insufficient evidence';

  @override
  String get masteryConfidenceLimited => 'Tentative estimate';

  @override
  String get masteryConfidenceSupported => 'Supported confidence';

  @override
  String get masteryTrendProgressing => 'Estimate moving forward';

  @override
  String get masteryTrendSteady => 'Estimate unchanged';

  @override
  String get masteryTrendDeclining => 'Estimate needs another look';

  @override
  String get masteryConsolidate => 'Worth consolidating';

  @override
  String get masteryRevisit => 'Worth revisiting';

  @override
  String get masteryNoEvidenceHint =>
      'Quiz answers will help build this picture.';

  @override
  String get masteryScopeNote =>
      'An estimate based on quizzes, separate from course coverage and school marks.';

  @override
  String get masterySourceLimits =>
      'The available results do not tell us how the quizzes were taken. This estimate stays tentative: “Well understood” and “Solid” need fuller evidence.';

  @override
  String get masteryLoading => 'Loading learning evidence.';

  @override
  String get masteryUnavailable =>
      'Mastery estimates are temporarily unavailable.';

  @override
  String get masterySubjectsUnavailable =>
      'Subjects are unavailable right now.';

  @override
  String get masterySubjectsEmpty =>
      'Subjects will appear here when the curriculum is available.';

  @override
  String get masteryStudentCollecting =>
      'INTELLIA237 is starting to build your learning profile. Keep studying and answering exercises.';

  @override
  String get masteryStudentFirst =>
      'Your quiz answers are giving us an initial picture. These estimates are tentative and will develop with more evidence.';

  @override
  String get masteryStudentProgress =>
      'An estimate has moved forward with new quiz results. You can see the change in the subjects below.';

  @override
  String get masteryParentCollecting =>
      'There is not enough evidence yet to describe their understanding. You can still encourage them to explain what they are learning.';

  @override
  String get masteryParentFirst =>
      'Quizzes are giving an initial picture of their learning. The estimates are still tentative.';

  @override
  String get masteryParentProgress =>
      'New quiz results have moved an estimate forward. This comparison covers only the available observations.';

  @override
  String get masteryParentTitle => 'How is their learning going?';

  @override
  String get masteryParentEvolving => 'What is changing';

  @override
  String get masteryParentNoComparison =>
      'There is not enough evidence for a comparison yet.';

  @override
  String get masteryParentSupport => 'Where support can help';

  @override
  String get masteryParentSupportBody =>
      'More practice will help clarify this picture.';

  @override
  String get masteryParentContinuity => 'Learning continuity';

  @override
  String get masteryParentNoPattern =>
      'The available data does not yet show a pattern of regular study.';

  @override
  String get masteryParentHelp => 'How you can help';

  @override
  String get masteryParentHelpBody =>
      'You could ask which idea felt difficult and invite them to explain it in their own words.';

  @override
  String get masteryCoverageNote =>
      'Exploring a lesson does not yet show that it is understood.';

  @override
  String get masteryCoverageUnavailable =>
      'Course coverage is unavailable right now.';

  @override
  String get masteryChapterDetailPending =>
      'Chapter-level understanding will be shown when evidence is linked to chapters. Reading alone does not establish chapter mastery.';

  @override
  String get masteryRecentActivity => 'Available quiz results';

  @override
  String get masteryRecentLimits =>
      'This view keeps only the latest result for each quiz. It is not a complete attempt history.';

  @override
  String get masteryRecordedQuiz => 'Scored quiz';

  @override
  String get masteryOpenCourse => 'Go to the course';

  @override
  String get masteryScaleLegend =>
      'The length of the ink shows the state; its density shows confidence. A trace appears only when an earlier estimate was actually observed.';

  @override
  String get masteryOfficialRecord => 'School record';

  @override
  String get masteryOfficialRecordBody =>
      'School marks are official results from the school. They are never calculated from this estimate.';

  @override
  String get masteryOfficialRecordUnavailable =>
      'No school gradebook is connected to this view yet.';

  @override
  String get masteryRefresh => 'Refresh learning evidence';

  @override
  String masteryEvidenceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count distinct quizzes included',
      one: '1 distinct quiz included',
      zero: 'No usable results',
    );
    return '$_temp0';
  }

  @override
  String masteryExploredChapters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters explored',
      one: '1 chapter explored',
      zero: 'No chapters explored',
    );
    return '$_temp0';
  }

  @override
  String masteryExploredLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count explored lessons recorded',
      one: '1 explored lesson recorded',
      zero: 'No explored lessons recorded',
    );
    return '$_temp0';
  }

  @override
  String get masteryPartialCoverage =>
      'This covers only part of the recorded lessons.';

  @override
  String masteryRecordedStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Recorded activity streak: $count days',
      one: 'Recorded activity streak: 1 day',
    );
    return '$_temp0';
  }

  @override
  String masteryPreviousState(String state) {
    return 'Previous trace: $state';
  }

  @override
  String masteryLastEvidence(String date) {
    return 'Latest recorded result: $date';
  }

  @override
  String masteryDeclaredSchool(String name) {
    return 'School provided in your profile: $name';
  }

  @override
  String masteryWithCompanion(String name) {
    return 'With $name';
  }

  @override
  String masteryEvidenceWindow(int days) {
    return 'Results from the past $days days.';
  }

  @override
  String get passWelcomeBack => 'WELCOME BACK';

  @override
  String get passSignIn => 'SIGN IN';

  @override
  String get passGoodToSeeYouAgain => 'Good to see you again.';

  @override
  String get passLinkSent => 'LINK SENT';

  @override
  String get passRecoverMyAccess => 'RECOVER MY ACCESS';

  @override
  String get passForgotPassword => 'FORGOT PASSWORD';

  @override
  String get passOneLinkThenYouReBack => 'One link.\nThen you’re back.';

  @override
  String get passFindYourWayBack => 'Find your\nway back.';

  @override
  String get passTheNextStepIsWaitingIn =>
      'The next step is waiting in your inbox.';

  @override
  String get passEmailAccess => 'EMAIL ACCESS';

  @override
  String get passYourNextChapterAwaits => 'Your next chapter\nawaits.';

  @override
  String get passReturnToYourSpaceWithYour =>
      'Return to your space with your email and password.';

  @override
  String get passChooseAnotherWayIn => 'Choose another way in';

  @override
  String get passYourNumber => 'YOUR NUMBER';

  @override
  String get passVerificationInProgress => 'VERIFICATION IN PROGRESS';

  @override
  String get passNumberVerified => 'NUMBER VERIFIED';

  @override
  String get passPhoneAccess => 'PHONE ACCESS';

  @override
  String get passSixDigitsThenWeContinue => 'Six digits.\nThen we continue.';

  @override
  String get passYourNumberIsConfirmed => 'Your number\nis confirmed.';

  @override
  String get passYourNumberYourAccess => 'Your number.\nYour access.';

  @override
  String get passChooseYourSpace => '01 / CHOOSE YOUR SPACE';

  @override
  String get passCreateAnAccount => 'CREATE AN ACCOUNT';

  @override
  String get passYourPlaceStartsHere => 'Your place starts here.';

  @override
  String get passChooseYourSpaceYourPassTakes =>
      'Choose your space. Your Pass takes shape with you.';

  @override
  String get passRegistrationComplete => 'REGISTRATION COMPLETE';

  @override
  String get passYourPlaceIsReady => 'YOUR PLACE\nIS READY.';

  @override
  String get passYourSpace => 'Your space';

  @override
  String get passPassReady => 'PASS READY';

  @override
  String get passTakingShape => 'TAKING SHAPE';

  @override
  String get passAPlaceForYou => 'A place for you.';

  @override
  String get passYourFamilySpace => 'Your family space';

  @override
  String get passYourTeachingSpace => 'Your teaching space';

  @override
  String get passValidationPending => 'Validation pending';

  @override
  String get passAccountCreated => 'ACCOUNT CREATED.';

  @override
  String passChildIdentifiersAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count identifiers added',
      one: '1 identifier added',
    );
    return '$_temp0';
  }

  @override
  String passWithCompanion(String companion) {
    return 'With $companion';
  }

  @override
  String get authorSignature =>
      'App designed by Calvin EKENA · +237 699 98 90 99';

  @override
  String get schoolHeadShieldTooltip => 'School leadership space';

  @override
  String get schoolHeadSheetEyebrow => 'LEADERSHIP SPACE';

  @override
  String get schoolHeadSheetTitle => 'Your whole\nschool.';

  @override
  String get schoolHeadSheetBody =>
      'Sign in to run your entire school: staff, classes, content and follow-up. Student accounts remain theirs: you cannot add or remove a student.';

  @override
  String get schoolHeadContinueEmail => 'Continue with email';

  @override
  String get schoolHeadContinuePhone => 'Continue with phone';

  @override
  String get schoolHeadPhoneNote =>
      'Phone sign-in works once your number is linked to your account, from your settings.';

  @override
  String get schoolHeadRequestAccess => 'Request access for my school';

  @override
  String get schoolDirectoryTitle => 'School directory';

  @override
  String get schoolDirectoryEmpty => 'Nobody in this group yet.';

  @override
  String get schoolDirectoryStudentsNote =>
      'Students join the school through their own registration: leadership views them, without adding or removing them.';

  @override
  String get schoolDirectoryLoadMore => 'Show more';

  @override
  String get schoolDirectoryPending => 'Awaiting approval';

  @override
  String get schoolClassesTitle => 'School classes';

  @override
  String get schoolClassesEmpty =>
      'No class has been opened for your school yet.';

  @override
  String schoolClassCounts(int students, int teachers) {
    return 'Students: $students · Teachers: $teachers';
  }

  @override
  String get renameClassLabel => 'Rename the class';

  @override
  String get classNameLabel => 'Class name';

  @override
  String get reviewNoSchool => 'No school attached';

  @override
  String get reviewAttachSchoolTitle => 'Attach to a school';

  @override
  String get reviewAttachSchoolBody =>
      'This account does not belong to a school yet. Choose theirs to approve it.';

  @override
  String get reviewCreateSchool => 'Open a new school';

  @override
  String get reviewCreateSchoolAction => 'Open and attach';

  @override
  String get accountReviewFailed =>
      'The decision could not be saved. Try again.';

  @override
  String get adminPhoneLinkTitle => 'Also sign in by phone';

  @override
  String get adminPhoneLinkBody =>
      'Link your number to receive a code at every sign-in.';

  @override
  String get unattachedStaffTitle => 'Staff without a school';

  @override
  String get unattachedStaffBody =>
      'These accounts were approved before being attached. Without a school, they neither compose nor manage anything for it.';

  @override
  String get unattachedStaffEmpty => 'All approved staff belong to a school.';

  @override
  String get attachStaffAction => 'Attach';

  @override
  String get attachStaffSheetBody =>
      'Choose this account’s school. Once attached, it can no longer change school from the app.';

  @override
  String get staffAttached =>
      'Account attached. The person finds their school the next time they open the app.';

  @override
  String get schoolNameRequired => 'Give the school’s full name.';

  @override
  String get schoolCityRequired => 'Enter the school’s city.';

  @override
  String get schoolCityHelper => 'Free entry, for example Douala or Bafoussam.';

  @override
  String get schoolTransferTitle => 'Change an account’s school';

  @override
  String get schoolTransferBody =>
      'Registration mistake, move, transfer: find the student, parent or staff member by email or phone.';

  @override
  String get schoolTransferQueryLabel => 'Email or phone';

  @override
  String get schoolTransferQueryHint => '699 98 90 99 or name@example.cm';

  @override
  String get schoolTransferSearch => 'Search';

  @override
  String get schoolTransferNoResult =>
      'No account matches. Check the email or number.';

  @override
  String schoolTransferCurrentSchool(String school) {
    return 'School: $school';
  }

  @override
  String schoolTransferDeclared(String school) {
    return 'Declared at registration: $school';
  }

  @override
  String get schoolTransferMove => 'Change school';

  @override
  String get schoolTransferAttachBody => 'Choose this account’s school.';

  @override
  String get schoolTransferMoveBody =>
      'Choose the new school. This account will leave the classes of its former school.';

  @override
  String get schoolTransferReasonTitle => 'Reason for the change';

  @override
  String get schoolTransferReasonHint =>
      'For example: parent’s mistake at registration';

  @override
  String get schoolTransferConfirm => 'Confirm the change';

  @override
  String get schoolTransferDone =>
      'School updated. The person finds it the next time they open the app.';

  @override
  String get schoolTransferSameSchool =>
      'This account already belongs to this school.';

  @override
  String get schoolTransferChildren => 'Linked children';

  @override
  String get generalAdministrationAllSchools =>
      'General administration · all schools';

  @override
  String get broadcastTargetSchool => 'Recipient school';

  @override
  String get broadcastTargetSchoolRequired => 'Choose the recipient school.';

  @override
  String get announcementFailed =>
      'The announcement could not be published. Try again.';

  @override
  String get schoolsOverviewTitle => 'Schools';

  @override
  String get schoolsOverviewBody =>
      'Every INTELLIA237 school. Tap one to see its directory and classes.';

  @override
  String get schoolsOverviewCreate => 'Open a school';

  @override
  String get schoolsOverviewEmpty => 'No school has been opened yet.';

  @override
  String get schoolsOverviewHint =>
      'Choose an existing school, or open a new one with its city.';

  @override
  String get parentPreviewBadge => 'Parent preview';

  @override
  String get parentPreviewExit => 'Exit preview';

  @override
  String parentPreviewViewingParent(String name) {
    return '$name\'s space';
  }

  @override
  String get parentPreviewOwnAccountNote => 'Preview of your own Parent space.';

  @override
  String get adminParentPreviewAction => 'Preview the Parent space';

  @override
  String get adminParentPreviewDescription =>
      'Open the Parent space as super-admin, without switching accounts.';

  @override
  String get parentPreviewChooseParent => 'Preview as';

  @override
  String get parentPreviewOwnAccount => 'My account (super-admin)';

  @override
  String get parentPreviewNoParents => 'No parent account to preview yet.';

  @override
  String get parentPreviewPaymentsBlockedTitle =>
      'Payment unavailable in preview';

  @override
  String get parentPreviewPaymentsBlockedBody =>
      'You are viewing another parent\'s space: to protect their data, no payment operation is possible here.';

  @override
  String get addChildTitle => 'Add a child';

  @override
  String get addChildCodeLabel => 'Child\'s link code';

  @override
  String get addChildCodeHelp =>
      'Ask your child for their code, shown in their Profile space under \"My parent code\".';

  @override
  String get addChildSubmit => 'Link child';

  @override
  String addChildSuccess(String name) {
    return '$name is now linked to your account.';
  }

  @override
  String addChildAlready(String name) {
    return '$name is already linked to your account.';
  }

  @override
  String get studentLinkCodeTitle => 'My parent code';

  @override
  String get studentLinkCodeBody =>
      'Share this code with your parent so they can follow your progress.';

  @override
  String get studentLinkCodeCopy => 'Copy code';

  @override
  String get studentLinkCodeCopied => 'Code copied.';

  @override
  String get studentLinkCodeError =>
      'The code could not be generated. Try again.';

  @override
  String get studentLinkCodeRotate => 'Regenerate code';

  @override
  String get studentLinkCodeRotateConfirmTitle => 'Regenerate the code?';

  @override
  String get studentLinkCodeRotateConfirmBody =>
      'The old code will stop working immediately. Parents already linked stay linked.';

  @override
  String get studentLinkCodeRotated => 'New code generated.';

  @override
  String get createClassLabel => 'Create a class';

  @override
  String get classLevelLabel => 'Level';

  @override
  String get classSeriesLabel => 'Series (optional)';

  @override
  String get classTrackLabel => 'Track (optional)';

  @override
  String get classSeriesNone => 'None';

  @override
  String get deleteClassLabel => 'Delete class';

  @override
  String deleteClassConfirm(String name) {
    return 'Delete \"$name\"? This class is empty.';
  }

  @override
  String get deleteClassBlocked =>
      'Class not empty: remove the students first.';

  @override
  String get classCreatedMessage => 'Class created.';

  @override
  String get classDeletedMessage => 'Class deleted.';

  @override
  String get editEstablishmentLabel => 'Edit school';

  @override
  String get archiveEstablishmentLabel => 'Archive school';

  @override
  String get unarchiveEstablishmentLabel => 'Reactivate school';

  @override
  String get establishmentArchivedBadge => 'Archived';

  @override
  String get establishmentCityLabel => 'City';

  @override
  String get flowChoiceTrue => 'True';

  @override
  String get flowChoiceFalse => 'False';

  @override
  String flowHintPrefix(String hint) {
    return 'Hint: $hint';
  }

  @override
  String get flowFeedbackCorrect => 'Correct!';

  @override
  String get flowFeedbackIncorrect => 'Not yet.';

  @override
  String flowExpectedOrder(String order) {
    return 'Expected order: $order';
  }

  @override
  String get flowSwipeToContinue => 'Swipe up to continue';

  @override
  String get childLinkErrorNotFound =>
      'This child code was not found. Check it with your child.';

  @override
  String get childLinkErrorInvalid => 'Enter your child\'s link code.';

  @override
  String get childLinkErrorPermission =>
      'Only a parent account can link a child.';

  @override
  String get childLinkErrorUnauthenticated =>
      'Your session expired. Sign in again and retry.';

  @override
  String get childLinkErrorTooMany =>
      'Too many attempts. Try again a little later.';

  @override
  String get childLinkErrorGeneric => 'Linking failed. Try again in a moment.';

  @override
  String get studyReserveTitle => 'Study reserve';

  @override
  String studyReserveRemaining(int percent) {
    return '$percent% remaining';
  }

  @override
  String studyReserveRenews(String date) {
    return 'Renews on $date';
  }

  @override
  String get studyReserveStatusHealthy => 'Plenty left';

  @override
  String get studyReserveStatusWarning => 'Getting lower';

  @override
  String get studyReserveStatusLow => 'Running low';

  @override
  String get studyReserveStatusCritical => 'Almost empty';

  @override
  String get studyReserveStatusDepleted => 'Reserve empty';

  @override
  String get studyReserveDepletedHelp =>
      'The AI tutor rests until renewal. Lessons, quizzes and readings stay available.';

  @override
  String get studyReserveUnavailable => 'Study reserve unavailable right now.';

  @override
  String get studyReserveNotifTitle => 'Study reserve';

  @override
  String studyReserveNotifInfo(int percent) {
    return '$percent% of the study reserve is left this cycle.';
  }

  @override
  String studyReserveNotifLow(int percent) {
    return 'The study reserve is at $percent%. Pace it for the tutor.';
  }

  @override
  String studyReserveNotifCritical(int percent) {
    return 'The study reserve is almost empty ($percent%).';
  }

  @override
  String get studyReserveNotifDepleted =>
      'The study reserve is empty; it renews next cycle. Lessons and quizzes stay available.';

  @override
  String get studyReserveLoadError =>
      'Couldn’t load the study reserve right now.';

  @override
  String companionStudyReserveDepleted(String name) {
    return 'Your study reserve is depleted for this cycle. $name will be back at renewal; your lessons and quizzes stay available.';
  }

  @override
  String get parentEntryTitle => 'Link your child';

  @override
  String get parentEntrySubtitle =>
      'Enter their code, then sign in with your own phone number.';

  @override
  String get parentEntryHaveCode => 'I have a child code';

  @override
  String get parentEntryCodeLabel => 'Child code';

  @override
  String get parentEntryCodeHint => 'e.g. K7MP2QXA';

  @override
  String get parentEntryCodeHelp =>
      'Your child finds it in their profile, under “My parent code”.';

  @override
  String get parentEntryCodeInvalid =>
      'A child code has 8 letters and digits. Check it with your child.';

  @override
  String get parentEntryPaste => 'Paste';

  @override
  String get parentEntryAlreadyParent => 'I already have a parent account';

  @override
  String get parentEntryPrivacy =>
      'The code is only used to link your child once you are signed in.';

  @override
  String get phonePendingChildCode =>
      'Child code ready: it will be linked once you are signed in.';

  @override
  String get phoneLinkingChild => 'Linking your child…';

  @override
  String get passNumberAlreadyUsed => 'Number already in use';

  @override
  String get roleConflictStudentAccount =>
      'This phone number is already associated with a student account.';

  @override
  String get roleConflictParentAccount =>
      'This phone number is already associated with a parent account.';

  @override
  String get roleConflictStaffAccount =>
      'This phone number is already associated with a school staff account.';

  @override
  String get roleConflictCredentialsStudentAccount =>
      'This sign-in opens a student account.';

  @override
  String get roleConflictCredentialsParentAccount =>
      'This sign-in opens a parent account.';

  @override
  String get roleConflictCredentialsStaffAccount =>
      'This sign-in opens a school staff account.';

  @override
  String get roleConflictUseParentCredentials =>
      'To create or open a parent space, sign in with the parent’s own number or email.';

  @override
  String get roleConflictUseStudentCredentials =>
      'To open the student space, sign in with the student’s own number or code.';

  @override
  String get roleConflictChildCodeKept => 'The child code is still saved.';

  @override
  String get roleConflictUseAnotherNumber => 'Use another number';

  @override
  String get childLinkReportFailedTitle => 'The child code could not be linked';

  @override
  String childLinkBatchSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count children linked to your account.',
      one: '1 child linked to your account.',
    );
    return '$_temp0';
  }

  @override
  String get parentEntryCodePurpose =>
      'This code links the child.\nYour phone number is used to identify you as the parent.';

  @override
  String get passFamilyNumber => 'Family number';

  @override
  String get familyPhoneMigrationPrompt =>
      'This number is currently used for a student’s access. Would you like to use it as the parent’s number? The student will keep their profile and will now use their INTELLIA access code.';

  @override
  String get familyPhoneMigrationConfirm => 'Use this number for the parent';

  @override
  String get familyPhoneMigrationNothingChanged =>
      'The transfer did not go through. Nothing changed: please try again.';

  @override
  String get familyPhoneMigrationVerifyAgain =>
      'For your security, verify this number again before transferring it.';

  @override
  String get familyPhoneMigrationVerifyAgainAction => 'Verify the number again';

  @override
  String get familyPhoneMigrationInProgress =>
      'A transfer is already in progress for this number. Wait a moment, then try again.';

  @override
  String get familyPhoneMigrationVerifyAgainToFinish =>
      'The student already has their access code. Verify this number again to finish opening your parent space.';

  @override
  String get familyPhoneMigrationRefused =>
      'This number cannot be transferred from this account. Use another number or contact the school.';

  @override
  String get familyPhoneMigrationUnavailable =>
      'Transferring the number is not available yet. Try again later or use another number.';

  @override
  String get familyPhoneMigratedTitle => 'This number is now yours';

  @override
  String get familyPhoneMigratedContinue =>
      'I noted the code, open my parent space';

  @override
  String get studentNoPhoneUseAccessCode =>
      'No phone? Sign in with your INTELLIA access code';

  @override
  String get studentAccessCodePhase => 'Your access code';

  @override
  String get studentAccessCodeTitle => 'Sign in with your access code';

  @override
  String get studentAccessCodeSubtitle =>
      'Enter the 12 characters your parent or your school gave you. No phone needed.';

  @override
  String get studentAccessCodeLabel => 'INTELLIA access code';

  @override
  String get studentAccessCodeSubmit => 'Enter my space';

  @override
  String get studentAccessCodePrivacy =>
      'Keep this code to yourself: it opens your space. If you lost it, ask your parent or your school for a new one.';

  @override
  String get studentAccessCodeUsePhone => 'I have a phone: receive an SMS';

  @override
  String get studentAccessCodeInvalid =>
      'This code does not work. Check it, or ask your parent or your school for a new code.';

  @override
  String get studentAccessCodeTooManyAttempts =>
      'Too many attempts. Wait a few minutes before trying again.';

  @override
  String get studentAccessCodeUnavailable =>
      'The service is not responding right now. Try again in a moment.';

  @override
  String studentAccessCodeRevealTitle(String name) {
    return 'INTELLIA access code for $name';
  }

  @override
  String get studentAccessCodeRevealTitleGeneric =>
      'Student’s INTELLIA access code';

  @override
  String studentAccessCodeRevealBody(String name) {
    return 'Write this code down and give it to $name: it opens their space without a phone. It will not be shown again; you can generate a new one from their card.';
  }

  @override
  String get studentAccessCodeRevealBodyGeneric =>
      'Write this code down and give it to the student: it opens their space without a phone. It will not be shown again; you can generate a new one from their card.';

  @override
  String get studentAccessCodeNotShownAgain =>
      'The student’s access code was already created. For their security it is never shown again: generate a new one from their card.';

  @override
  String get studentAccessCodeCopy => 'Copy code';

  @override
  String get studentAccessCodeCopied => 'Code copied';

  @override
  String get studentAccessCodeSheetBody =>
      'This code lets your child open their INTELLIA space without a phone. For their security it is never shown again: generating a new code replaces the old one, which stops working at once.';

  @override
  String get studentAccessCodeGenerate => 'Show / generate a new access code';

  @override
  String get studentAccessCodeReplaceTitle => 'Replace the access code?';

  @override
  String studentAccessCodeReplaceBody(String name) {
    return '$name’s previous code will stop working immediately.';
  }

  @override
  String get studentAccessCodeReplaceConfirm => 'Generate the new code';

  @override
  String get studentAccessCodeDone => 'I noted the code';

  @override
  String get studentAccessCodeIssueFailed =>
      'The code could not be generated. Please try again.';

  @override
  String studentAccessCodeActiveSince(String date) {
    return 'Access code active since $date';
  }

  @override
  String get studentAccessCodeActive => 'Access code active';

  @override
  String get studentAccessCodeNone => 'No access code yet';

  @override
  String get childAccessOwnPhone => 'Signed in with their own INTELLIA access';

  @override
  String get childAccessCodeOnly => 'Signs in with their INTELLIA access code';

  @override
  String get childAccessUnknown => 'Child’s access is not available right now';

  @override
  String get childAccessNone =>
      'No personal access yet: generate their access code';

  @override
  String get childActionViewProfile => 'View profile';

  @override
  String get childActionViewActivity => 'View activity';

  @override
  String get childActionAccessCode => 'Student access code';

  @override
  String get childActionSubscription => 'Subscription';

  @override
  String childSubscriptionActiveUntil(String date) {
    return 'Subscription active until $date';
  }

  @override
  String get childSubscriptionPaidByAnotherGuardian =>
      'Paid by another guardian of the child';

  @override
  String get childSubscriptionInactive =>
      'No active subscription for this child';

  @override
  String get childSchoolUnknown => 'School not provided';

  @override
  String parentChildrenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count children',
      one: '1 child',
    );
    return '$_temp0';
  }

  @override
  String parentModeProfileBanner(String name) {
    return 'PARENT MODE — $name’S PROFILE';
  }

  @override
  String get parentModeProfileNote =>
      'You are viewing this profile with your parent account. You cannot change anything on your child’s behalf.';

  @override
  String get childProfileTitle => 'Child profile';

  @override
  String get childProfileClass => 'Class';

  @override
  String get childProfileSchool => 'School';

  @override
  String get childProfileAccess => 'INTELLIA access';

  @override
  String get childProfileSubscription => 'Subscription';

  @override
  String get parentSchoolsAnnouncements =>
      'Announcements from your children’s schools';

  @override
  String get mobileMoneyChooseChild => 'Which child are you paying for?';

  @override
  String mobileMoneyOfferOfSchool(String school) {
    return '$school offer';
  }

  @override
  String mobileMoneyCoversChildren(String names) {
    return 'This payment covers: $names';
  }

  @override
  String get childPendingFirstSignIn => 'Waiting for their first sign-in';

  @override
  String get addChildNoAccountAction => 'My child has no INTELLIA account yet';

  @override
  String get addChildNoAccountTitle => 'Open your child’s access';

  @override
  String get addChildNoAccountBody =>
      'Your child does not need a phone. You will receive their INTELLIA access code; they will complete their school profile at their first sign-in.';

  @override
  String get addChildNoAccountNameLabel => 'Child’s first name';

  @override
  String get addChildNoAccountNameRequired => 'Enter your child’s first name.';

  @override
  String get addChildNoAccountSubmit => 'Create their access code';

  @override
  String get addChildNoAccountFailed =>
      'The access could not be opened. Please try again.';

  @override
  String get adminStudentAccessRecoveryTitle => 'Recover the student’s access';

  @override
  String get adminStudentAccessRecoveryBody =>
      'A new INTELLIA access code replaces the previous one, which stops working at once. Hand it to the student or their family in person: it will not be shown again.';

  @override
  String get adminStudentPhoneOptional => 'Student phone (optional)';

  @override
  String get childActionLinkCode => 'Parent link code';

  @override
  String guardianLinkCodeBody(String name) {
    return 'This code lets another parent or guardian link $name to their own account. It does not open the student’s space: use the student access code for that.';
  }

  @override
  String get guardianLinkCodeRotate => 'Replace this code';

  @override
  String get guardianLinkCodeRotateBody =>
      'The previous link code will stop working immediately. Guardians already linked stay linked.';

  @override
  String get guardianLinkCodeUnavailable =>
      'The link code could not be retrieved. Please try again.';

  @override
  String get ilbWordOrderInstruction => 'Put the words in the correct order.';

  @override
  String get ilbStepOrderInstruction => 'Put the steps in the correct order.';

  @override
  String get ilbTimelineInstruction =>
      'Put these events in chronological order.';

  @override
  String get ilbProcessInstruction =>
      'Put the stages of this process in order.';

  @override
  String get ilbCheck => 'Check';

  @override
  String get ilbRestart => 'Start again';

  @override
  String get ilbHint => 'A hint';

  @override
  String get ilbShowSolution => 'Show the solution';

  @override
  String ilbContinueWith(String name) {
    return 'Continue with $name';
  }

  @override
  String get ilbContinueMessage =>
      'I’ve finished the exercise. Shall we go on?';

  @override
  String get ilbCorrect1 => 'Exactly.';

  @override
  String get ilbCorrect2 => 'Well done.';

  @override
  String get ilbCorrect3 => 'Yes, that’s it.';

  @override
  String get ilbAlmost => 'Almost.';

  @override
  String get ilbTryAgain => 'Try again.';

  @override
  String ilbPositionHint(int position) {
    return 'Look at position $position.';
  }

  @override
  String ilbAttempt(int count) {
    return 'Attempt $count';
  }

  @override
  String ilbHintsUsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hints',
      one: '1 hint',
      zero: 'No hint',
    );
    return '$_temp0';
  }

  @override
  String get ilbAnswerZoneEmpty => 'Tap or drag the words here';

  @override
  String get ilbAnswerZoneA11y => 'Your answer';

  @override
  String get ilbWordBankA11y => 'Words to place';

  @override
  String ilbPlaceWordA11y(String word) {
    return 'Place “$word”';
  }

  @override
  String ilbRemoveWordA11y(String word, int position) {
    return 'Remove “$word”, position $position';
  }

  @override
  String get ilbMoveUp => 'Move up';

  @override
  String get ilbMoveDown => 'Move down';

  @override
  String ilbStepA11y(int position, String text) {
    return 'Step $position: $text';
  }

  @override
  String get ilbSolutionShown => 'Here is the correct answer.';

  @override
  String get ilbKiraWords => 'Try to put this sentence back in order.';

  @override
  String get ilbLeoWords => 'Your turn. Rebuild this sentence.';

  @override
  String get ilbKiraSteps => 'Take your time: put the steps in order.';

  @override
  String get ilbLeoSteps =>
      'Challenge: put the steps in order, without help if you can.';

  @override
  String get parcoursEmptyTitle => 'Your learning path is on its way';

  @override
  String get parcoursEmptyBody =>
      'No card has been published for your class yet. Come back after a sync.';

  @override
  String get parcoursEmptyRefresh => 'Refresh';

  @override
  String get parcoursEmptyHome => 'Back to home';

  @override
  String get parcoursVideoPending => 'This video isn’t available yet.';

  @override
  String get authGatewayPhone => 'Continue with my number';

  @override
  String get authGatewayPhoneSemantics =>
      'Continue with my Cameroonian phone number';

  @override
  String get authGatewayStudentCode => 'I have a student code';

  @override
  String get authGatewayStudentCodeSemantics =>
      'I have a student code: sign in without a phone or email';

  @override
  String get authGatewayOr => 'or';

  @override
  String get authGatewayStaff => 'School staff, teacher or school leader?';

  @override
  String get authGatewayTerms => 'Terms of use';

  @override
  String get authGatewayPrivacy => 'Privacy';

  @override
  String get authAccountSuspended =>
      'This account is suspended. Contact your school or INTELLIA237 support.';

  @override
  String get authGoogleContinue => 'Continue with Google';

  @override
  String get authGoogleInProgress => 'Signing in with Google';

  @override
  String get authGoogleQuestionEyebrow => 'Google account';

  @override
  String get authGoogleQuestionTitle => 'Already using INTELLIA237?';

  @override
  String get authGoogleQuestionBody =>
      'This Google account does not open any INTELLIA237 account yet. If you already have one, by phone number or by email, find it: Google will be added to it, and your space and data stay the same.';

  @override
  String authGoogleQuestionAccount(String email) {
    return 'Google account chosen: $email';
  }

  @override
  String get authGoogleQuestionYes => 'Yes, find my account';

  @override
  String get authGoogleQuestionNo => 'No, continue';

  @override
  String get authGoogleQuestionNoHint =>
      'A new INTELLIA237 access is created with this Google account. You explore the app, then create your space whenever you like.';

  @override
  String get authGoogleQuestionOtherAccount => 'Use another Google account';

  @override
  String get authGoogleStepExpired =>
      'This step has expired. Start again with “Continue with Google”.';

  @override
  String get authBackToGateway => 'Back to the welcome screen';

  @override
  String get authRecoveryEyebrow => 'Find my account';

  @override
  String get authRecoveryTitle => 'Sign in to your existing account';

  @override
  String get authRecoveryBody =>
      'Prove this account is yours. Google will then be added as a new way to sign in.';

  @override
  String authRecoveryEmailInUse(String email) {
    return 'An INTELLIA237 account already uses $email. Sign in to that account to add Google to it.';
  }

  @override
  String get authRecoveryByPhone => 'By phone';

  @override
  String get authRecoveryByEmail => 'By email';

  @override
  String get authRecoveryPhoneLabel => 'Phone number';

  @override
  String get authRecoveryPhoneHint => '6XX XX XX XX';

  @override
  String get authRecoverySendCode => 'Get the code by SMS';

  @override
  String get authRecoveryCodeLabel => 'Code received by SMS';

  @override
  String authRecoveryCodeSentTo(String phone) {
    return 'Code sent to $phone.';
  }

  @override
  String get authRecoveryVerifyCode => 'Verify the code';

  @override
  String get authRecoveryChangeNumber => 'Change number';

  @override
  String authRecoveryResendIn(int seconds) {
    return 'New code available in ${seconds}s';
  }

  @override
  String get authRecoveryResend => 'Resend the code';

  @override
  String get authRecoveryEmailLabel => 'Email address';

  @override
  String get authRecoveryPasswordLabel => 'Password';

  @override
  String get authRecoverySignIn => 'Sign in and add Google';

  @override
  String get authRecoveryLinking => 'Adding Google to your account…';

  @override
  String get authRecoveryNoAccountForPhone =>
      'No INTELLIA237 account uses this number. Check it, or go back and choose “No, continue”.';

  @override
  String get authRecoveryNoProfile =>
      'This account has no INTELLIA237 space yet. Go back and choose “No, continue”.';

  @override
  String get authRecoveryLinkedElsewhere =>
      'This Google account is already linked to another INTELLIA237 account.';

  @override
  String get authRecoveryLinkedElsewhereHelp =>
      'Nothing was changed or merged. To use this Google account, choose “Continue with Google” from the welcome screen. If in doubt, contact your school or INTELLIA237 support.';

  @override
  String get authRecoveryProviderTaken =>
      'Your INTELLIA237 account is already linked to another Google account.';

  @override
  String get authRecoveryProviderTakenHelp =>
      'Nothing was changed. Sign in with the Google account already linked, or with your number.';

  @override
  String get authRecoveryOpenWithoutGoogle => 'Open my space without Google';

  @override
  String get authRecoveryCancel => 'Cancel and go back';

  @override
  String get authRecoveryCleanupFailed =>
      'The verification of this number could not be undone. No space was created; try again later or contact INTELLIA237 support.';

  @override
  String get authWelcomeEyebrow => 'New to INTELLIA237';

  @override
  String get authWelcomeTitle => 'How would you like to start?';

  @override
  String get authWelcomeBody =>
      'Your identity is verified. No space exists for it yet.';

  @override
  String get authWelcomeParent => 'I’m a parent';

  @override
  String get authWelcomeParentHint =>
      'Create my family space, then link my child with their code.';

  @override
  String get authWelcomeStudent => 'Join my school';

  @override
  String get authWelcomeStudentHint => 'Student: choose my school and class.';

  @override
  String get authWelcomeDiscover => 'Explore INTELLIA237';

  @override
  String get authWelcomeDiscoverHint =>
      'See how the app works, without creating a space.';

  @override
  String get authWelcomeStaffNote =>
      'Teachers and school leaders: your access is opened by your school, then validated.';

  @override
  String get authUseAnotherAccount => 'Use another account';

  @override
  String authStudentPhoneTitle(String name) {
    return 'This number opens $name’s student space.';
  }

  @override
  String get authStudentPhoneTitleUnnamed =>
      'This number opens a student space.';

  @override
  String get authStudentPhoneBody =>
      'On a family phone, tell us who is signing in.';

  @override
  String authStudentPhoneContinue(String name) {
    return 'Continue as $name';
  }

  @override
  String get authStudentPhoneContinueUnnamed => 'It’s my space, continue';

  @override
  String get authStudentPhoneParent => 'I’m their parent';

  @override
  String get authSpaceEyebrow => 'Several spaces';

  @override
  String get authSpaceTitle => 'Choose your space';

  @override
  String get authSpaceBody =>
      'Your account opens several spaces. You can switch at any time from your profile, without signing out.';

  @override
  String get authSpaceStudent => 'Student space';

  @override
  String get authSpaceStudentHint =>
      'Lessons, exercises, Parcours and the KIRA and LÉO companions.';

  @override
  String get authSpaceParent => 'Parent space';

  @override
  String get authSpaceParentHint => 'Follow your children’s work and progress.';

  @override
  String get authSpaceTeacher => 'Teacher space';

  @override
  String get authSpaceTeacherHint =>
      'Your classes, your content and your students’ progress.';

  @override
  String get authSpaceAdmin => 'School leadership space';

  @override
  String get authSpaceAdminHint => 'School administration and oversight.';

  @override
  String get authSpaceCurrent => 'Current space';

  @override
  String get authSpaceSignOut => 'Sign out';

  @override
  String get authSwitchSpace => 'Switch space';

  @override
  String get authSwitchSpaceHint =>
      'Move to another space of your account, without signing out.';

  @override
  String get authErrorNetwork =>
      'Unstable internet connection. Check your network, then try again.';

  @override
  String get authErrorInvalidCode =>
      'This code is incorrect or has expired. Check the SMS, or ask for a new code.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Wait a few minutes before trying again.';

  @override
  String get authErrorAccountExists =>
      'An INTELLIA237 account already uses this address with another sign-in method. Sign in to that account to add Google to it.';

  @override
  String get authErrorCredentialInUse =>
      'This Google account is already linked to another INTELLIA237 account.';

  @override
  String get authErrorWrongPassword => 'Incorrect email address or password.';

  @override
  String get authErrorUserDisabled =>
      'This account is suspended. Contact your school or INTELLIA237 support.';

  @override
  String get authErrorProviderAlreadyLinked =>
      'This account is already linked to another Google account.';

  @override
  String get authErrorGoogleNotConfigured =>
      'Google sign-in coming soon. Use your phone number.';

  @override
  String get authErrorGoogleUnavailable =>
      'The Google account picker did not open. Check that a Google account is on this device, then try again.';

  @override
  String get authErrorInvalidPhone =>
      'This is not a valid Cameroonian mobile number. Example: 6 99 12 34 56.';

  @override
  String get authErrorMissingFields =>
      'Enter the email address and the password.';

  @override
  String get authErrorGeneric =>
      'Sign-in did not go through. Try again in a moment.';

  @override
  String get discoveryBadge => 'Explore';

  @override
  String get discoveryExit => 'Leave';

  @override
  String get discoveryTitle => 'Explore INTELLIA237';

  @override
  String get discoveryIntro =>
      'A preview of the app, with no space and no school data. Nothing you see here is saved.';

  @override
  String get discoveryFictionalNotice =>
      'Fictional examples, for illustration only: they describe no real student.';

  @override
  String get discoveryTutorsTitle =>
      'Companions that guide, without giving away the answer';

  @override
  String get discoveryKiraRole => 'Science and maths';

  @override
  String get discoveryKiraSample =>
      'To isolate x, which operation would you do first on both sides of the equation?';

  @override
  String get discoveryLeoRole => 'Method, languages and writing';

  @override
  String get discoveryLeoSample =>
      'Let’s start with what solidarity means to you. Can you name two examples?';

  @override
  String get discoveryParcoursTitle => 'Parcours, lessons and quizzes';

  @override
  String get discoveryParcoursBody =>
      'Short lessons, exercises and quizzes aligned with the Cameroonian curriculum, with explained corrections.';

  @override
  String get discoveryParentTitle => 'Follow-up for parents';

  @override
  String get discoveryParentBody =>
      'A parent links their child with a code, then follows their work: regularity, subjects covered, points to review.';

  @override
  String get discoveryParentExample =>
      'Fictional example: “Student A” worked regularly this week; one geometry concept needs review.';

  @override
  String get discoveryCreateTitle => 'Create my space';

  @override
  String get discoveryCtaParent => 'I’m a parent';

  @override
  String get discoveryCtaStudent => 'Join my school';

  @override
  String get discoveryCtaCode => 'I have a student code';

  @override
  String registrationGuideNext(String step) {
    return 'Next: $step';
  }

  @override
  String get registrationGuideLast => 'Last step';

  @override
  String get parentGuideIdentity =>
      'Your first and last name will appear in your parent space. Your number is already verified: no password to create.';

  @override
  String get parentGuideChildren =>
      'Ask your child for their “parent code” (8 characters): it is in their profile, under “My parent code”. No code yet? Continue, you can link them later.';

  @override
  String get parentGuideFinal =>
      'Accept the terms to open your space. You will follow your child’s progress there and can add other children.';

  @override
  String get studentGuideIdentity =>
      'Write your first and last name as at school: your teacher will recognise you.';

  @override
  String get studentGuideClass =>
      'Choose your class: your lessons, quizzes and learning path will be made for it.';

  @override
  String get studentGuideCompanion =>
      'Meet Kira and Léo, then choose the one who will help you revise.';

  @override
  String get studentGuideSecurity =>
      'Your number protects your account: nobody else can sign in as you.';

  @override
  String get teacherGuideIdentity =>
      'Your name as your students and your school know it.';

  @override
  String get teacherGuideTeaching =>
      'Your subjects and classes: your space and content will be prepared for them.';

  @override
  String get teacherGuideFinal =>
      'Accept the terms: your school will then approve your account.';

  @override
  String get flowExit => 'Exit';

  @override
  String get parentGuideOpen => 'Guide to your space';

  @override
  String get parentGuideReplay => 'See the guide again';

  @override
  String parentGuideProgress(int current, int total) {
    return 'STEP $current OF $total';
  }

  @override
  String get parentGuideSkip => 'Skip';

  @override
  String get parentGuideNext => 'Next';

  @override
  String get parentGuideDone => 'Got it';

  @override
  String get parentGuideWelcomeTitle => 'Welcome to your parent space';

  @override
  String get parentGuideWelcomeBody =>
      'Here you follow your children’s progress, their school’s announcements and payments. Here are the essentials, in six steps.';

  @override
  String get parentGuideAddTitle => 'Add a child';

  @override
  String get parentGuideAddBody =>
      '“My children” tab, then “Add a child”. Two cases: your child already has an INTELLIA account, or not yet.';

  @override
  String get parentGuideLinkTitle => 'Already has an account: the parent code';

  @override
  String get parentGuideLinkBody =>
      'Ask your child for their “parent code” (8 characters). It is in their Profile, under “My parent code”. Enter it, then tap “Link child”.';

  @override
  String get parentGuideAccessTitle => 'No account yet: the access code';

  @override
  String get parentGuideAccessBody =>
      'Choose “My child has no INTELLIA account yet”. You get their access code: write it down, it is shown only once. A new code can be created from their profile, “Student access code”.';

  @override
  String get parentGuideSwitchTitle => 'Your child uses this phone';

  @override
  String get parentGuideSwitchBody =>
      'Profile, then “Sign out”. On the welcome screen, your child taps “I have a student code” and enters their access code. To come back to your space: they sign out, then you sign in with your number.';

  @override
  String get parentGuideAgainTitle => 'Find this guide again';

  @override
  String get parentGuideAgainBody =>
      'Tap the compass at the top of your space, or “See the guide again” in Profile, whenever you like.';
}
