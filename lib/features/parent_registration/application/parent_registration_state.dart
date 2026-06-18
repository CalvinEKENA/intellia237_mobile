class ParentRegistrationState {
  const ParentRegistrationState({
    this.currentStep = 0,
    this.isSubmitting = false,
    this.errorMessage,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phoneNumber = '',
    this.password = '',
    this.confirmPassword = '',
    this.childIdentifiers = const <String>[],
    this.acceptedTerms = false,
    this.acceptedPrivacy = false,
  });

  final int currentStep;
  final bool isSubmitting;
  final String? errorMessage;

  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final List<String> childIdentifiers;
  final bool acceptedTerms;
  final bool acceptedPrivacy;

  bool get isFirstStep => currentStep == 0;
  bool get isLastStep => currentStep == 2;

  ParentRegistrationState copyWith({
    int? currentStep,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? password,
    String? confirmPassword,
    List<String>? childIdentifiers,
    bool? acceptedTerms,
    bool? acceptedPrivacy,
  }) {
    return ParentRegistrationState(
      currentStep: currentStep ?? this.currentStep,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      childIdentifiers: childIdentifiers ?? this.childIdentifiers,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      acceptedPrivacy: acceptedPrivacy ?? this.acceptedPrivacy,
    );
  }
}
