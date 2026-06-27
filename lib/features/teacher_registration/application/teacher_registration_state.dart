class TeacherRegistrationState {
  const TeacherRegistrationState({
    this.currentStep = 0,
    this.isSubmitting = false,
    this.errorMessage,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.subjects = const <String>[],
    this.levels = const <String>[],
    this.acceptedTerms = false,
    this.acceptedPrivacy = false,
  });

  final int currentStep;
  final bool isSubmitting;
  final String? errorMessage;

  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String confirmPassword;
  final List<String> subjects;
  final List<String> levels;
  final bool acceptedTerms;
  final bool acceptedPrivacy;

  bool get isFirstStep => currentStep == 0;
  bool get isLastStep => currentStep == 2;

  TeacherRegistrationState copyWith({
    int? currentStep,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    String? confirmPassword,
    List<String>? subjects,
    List<String>? levels,
    bool? acceptedTerms,
    bool? acceptedPrivacy,
  }) {
    return TeacherRegistrationState(
      currentStep: currentStep ?? this.currentStep,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      subjects: subjects ?? this.subjects,
      levels: levels ?? this.levels,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      acceptedPrivacy: acceptedPrivacy ?? this.acceptedPrivacy,
    );
  }
}
