import '../../student_registration/domain/school_establishment.dart';

class AdminRegistrationState {
  const AdminRegistrationState({
    this.currentStep = 0,
    this.isSubmitting = false,
    this.errorMessage,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.jobTitle = '',
    this.establishment,
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
  final String jobTitle;
  final SchoolEstablishment? establishment;
  final bool acceptedTerms;
  final bool acceptedPrivacy;

  bool get isFirstStep => currentStep == 0;
  bool get isLastStep => currentStep == 2;

  AdminRegistrationState copyWith({
    int? currentStep,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    String? confirmPassword,
    String? jobTitle,
    SchoolEstablishment? establishment,
    bool clearEstablishment = false,
    bool? acceptedTerms,
    bool? acceptedPrivacy,
  }) {
    return AdminRegistrationState(
      currentStep: currentStep ?? this.currentStep,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      jobTitle: jobTitle ?? this.jobTitle,
      establishment: clearEstablishment
          ? null
          : (establishment ?? this.establishment),
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      acceptedPrivacy: acceptedPrivacy ?? this.acceptedPrivacy,
    );
  }
}
