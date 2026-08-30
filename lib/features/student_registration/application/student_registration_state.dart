import '../domain/academic_rules.dart';
import '../domain/learning_goal.dart';
import '../domain/student_registration_payload.dart';

class StudentRegistrationState {
  const StudentRegistrationState({
    this.currentStep = 0,
    this.isSubmitting = false,
    this.errorMessage,
    this.firstName = '',
    this.lastName = '',
    this.interfaceLanguage = InterfaceLanguage.french,
    this.educationalSubsystem = EducationalSubsystem.francophone,
    this.educationType = EducationType.general,
    this.accountLinkage = LearnerAccountLinkage.individual,
    this.schoolClass,
    this.schoolSeries,
    this.streamOrSpeciality = '',
    this.establishment,
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
    this.isCompleted = false,
  });

  final int currentStep;
  final bool isSubmitting;
  final String? errorMessage;

  final String firstName;
  final String lastName;

  final InterfaceLanguage interfaceLanguage;
  final EducationalSubsystem educationalSubsystem;
  final EducationType educationType;
  final LearnerAccountLinkage accountLinkage;

  final SchoolClass? schoolClass;
  final SchoolSeries? schoolSeries;
  final String streamOrSpeciality;
  final EstablishmentAffiliation? establishment;

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
  final bool isCompleted;

  bool get isFirstStep => currentStep == 0;
  bool get isLastStep => currentStep == 3;

  StudentRegistrationState copyWith({
    int? currentStep,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    String? firstName,
    String? lastName,
    InterfaceLanguage? interfaceLanguage,
    EducationalSubsystem? educationalSubsystem,
    EducationType? educationType,
    LearnerAccountLinkage? accountLinkage,
    SchoolClass? schoolClass,
    bool clearSchoolClass = false,
    SchoolSeries? schoolSeries,
    bool clearSchoolSeries = false,
    String? streamOrSpeciality,
    EstablishmentAffiliation? establishment,
    bool clearEstablishment = false,
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
    bool? isCompleted,
  }) {
    return StudentRegistrationState(
      currentStep: currentStep ?? this.currentStep,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      interfaceLanguage: interfaceLanguage ?? this.interfaceLanguage,
      educationalSubsystem: educationalSubsystem ?? this.educationalSubsystem,
      educationType: educationType ?? this.educationType,
      accountLinkage: accountLinkage ?? this.accountLinkage,
      schoolClass: clearSchoolClass ? null : (schoolClass ?? this.schoolClass),
      schoolSeries: clearSchoolSeries
          ? null
          : (schoolSeries ?? this.schoolSeries),
      streamOrSpeciality: streamOrSpeciality ?? this.streamOrSpeciality,
      establishment: clearEstablishment
          ? null
          : (establishment ?? this.establishment),
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
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  StudentRegistrationPayload toPayload() {
    final selectedClass = schoolClass;
    final selectedGoal = learningGoal ?? LearningGoal.examMastery;

    if (selectedClass == null) {
      throw StateError('Etat incomplet pour construire le payload.');
    }

    return StudentRegistrationPayload(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      schoolClass: selectedClass,
      schoolSeries: schoolSeries,
      interfaceLanguage: interfaceLanguage,
      educationalSubsystem: educationalSubsystem,
      educationType: educationType,
      streamOrSpeciality: streamOrSpeciality.trim(),
      establishment: establishment,
      accountLinkage: accountLinkage,
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
