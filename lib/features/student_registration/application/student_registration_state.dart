import '../domain/academic_rules.dart';
import '../domain/learning_goal.dart';
import '../domain/school_establishment.dart';
import '../domain/student_registration_payload.dart';

class StudentRegistrationState {
  const StudentRegistrationState({
    this.currentStep = 0,
    this.isSubmitting = false,
    this.errorMessage,
    this.firstName = '',
    this.lastName = '',
    this.establishment,
    this.schoolClass,
    this.schoolSeries,
    this.selectedTutorId,
    this.preferredSubjects = const <String>[],
    this.difficultSubjects = const <String>[],
    this.learningGoal,
    this.dailyStudyMinutes = 45,
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.acceptedTerms = false,
    this.acceptedPrivacy = false,
    this.acceptedDataPolicy = false,
  });

  final int currentStep;
  final bool isSubmitting;
  final String? errorMessage;

  final String firstName;
  final String lastName;

  final SchoolEstablishment? establishment;
  final SchoolClass? schoolClass;
  final SchoolSeries? schoolSeries;

  final String? selectedTutorId;

  final List<String> preferredSubjects;
  final List<String> difficultSubjects;
  final LearningGoal? learningGoal;
  final int dailyStudyMinutes;

  final String email;
  final String password;
  final String confirmPassword;

  final bool acceptedTerms;
  final bool acceptedPrivacy;
  final bool acceptedDataPolicy;

  bool get isFirstStep => currentStep == 0;
  bool get isLastStep => currentStep == 3;

  StudentRegistrationState copyWith({
    int? currentStep,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    String? firstName,
    String? lastName,
    SchoolEstablishment? establishment,
    bool clearEstablishment = false,
    SchoolClass? schoolClass,
    bool clearSchoolClass = false,
    SchoolSeries? schoolSeries,
    bool clearSchoolSeries = false,
    String? selectedTutorId,
    bool clearSelectedTutorId = false,
    List<String>? preferredSubjects,
    List<String>? difficultSubjects,
    LearningGoal? learningGoal,
    bool clearLearningGoal = false,
    int? dailyStudyMinutes,
    String? email,
    String? password,
    String? confirmPassword,
    bool? acceptedTerms,
    bool? acceptedPrivacy,
    bool? acceptedDataPolicy,
  }) {
    return StudentRegistrationState(
      currentStep: currentStep ?? this.currentStep,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      establishment: clearEstablishment
          ? null
          : (establishment ?? this.establishment),
      schoolClass: clearSchoolClass ? null : (schoolClass ?? this.schoolClass),
      schoolSeries: clearSchoolSeries
          ? null
          : (schoolSeries ?? this.schoolSeries),
      selectedTutorId: clearSelectedTutorId
          ? null
          : (selectedTutorId ?? this.selectedTutorId),
      preferredSubjects: preferredSubjects ?? this.preferredSubjects,
      difficultSubjects: difficultSubjects ?? this.difficultSubjects,
      learningGoal: clearLearningGoal
          ? null
          : (learningGoal ?? this.learningGoal),
      dailyStudyMinutes: dailyStudyMinutes ?? this.dailyStudyMinutes,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      acceptedPrivacy: acceptedPrivacy ?? this.acceptedPrivacy,
      acceptedDataPolicy: acceptedDataPolicy ?? this.acceptedDataPolicy,
    );
  }

  StudentRegistrationPayload toPayload() {
    final selectedEstablishment = establishment;
    final selectedClass = schoolClass;
    final selectedGoal = learningGoal;

    if (selectedEstablishment == null ||
        selectedClass == null ||
        selectedGoal == null) {
      throw StateError('Etat incomplet pour construire le payload.');
    }

    return StudentRegistrationPayload(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      establishment: selectedEstablishment,
      schoolClass: selectedClass,
      schoolSeries: schoolSeries,
      selectedTutorId: selectedTutorId,
      preferredSubjects: preferredSubjects,
      difficultSubjects: difficultSubjects,
      learningGoal: selectedGoal,
      dailyStudyMinutes: dailyStudyMinutes,
      email: email.trim(),
      password: password,
      acceptedTerms: acceptedTerms,
      acceptedPrivacy: acceptedPrivacy,
      acceptedDataPolicy: acceptedDataPolicy,
    );
  }
}
