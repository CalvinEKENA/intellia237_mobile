enum StudyModeStatus { selectingDuration, active, sessionComplete, reclaimed }

class StudyModeSession {
  const StudyModeSession({
    required this.learnerUid,
    required this.duration,
    this.status = StudyModeStatus.selectingDuration,
  });

  final String learnerUid;
  final Duration duration;
  final StudyModeStatus status;

  StudyModeSession start() => _copyWith(StudyModeStatus.active);

  /// Completion deliberately remains inside INTELLIA237. Only a parental gate
  /// may move the state to reclaimed; personal devices cannot be forced into
  /// silent kiosk mode by ordinary application code.
  StudyModeSession complete() => _copyWith(StudyModeStatus.sessionComplete);

  StudyModeSession reclaimAfterParentalGate() =>
      _copyWith(StudyModeStatus.reclaimed);

  bool get remainsInsideIntellia => status == StudyModeStatus.sessionComplete;

  StudyModeSession _copyWith(StudyModeStatus next) => StudyModeSession(
    learnerUid: learnerUid,
    duration: duration,
    status: next,
  );
}

enum StudyModePlatformSupport {
  androidAppPinningGuidance,
  managedAndroidLockTask,
  iosGuidedAccessGuidance,
}
