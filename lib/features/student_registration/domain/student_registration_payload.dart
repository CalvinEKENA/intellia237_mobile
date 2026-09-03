import 'academic_rules.dart';
import 'learning_goal.dart';
import '../../tutor/domain/tutor_persona.dart';

class StudentRegistrationPayload {
  const StudentRegistrationPayload({
    required this.firstName,
    required this.lastName,
    required this.schoolClass,
    required this.schoolSeries,
    this.interfaceLanguage = InterfaceLanguage.french,
    this.educationalSubsystem = EducationalSubsystem.francophone,
    this.educationType = EducationType.general,
    this.streamOrSpeciality = '',
    this.establishment,
    this.accountLinkage = LearnerAccountLinkage.individual,
    this.selectedTutorId,
    required this.preferredSubjects,
    required this.difficultSubjects,
    required this.learningGoal,
    required this.dailyStudyMinutes,
    required this.email,
    required this.password,
    required this.acceptedTerms,
    required this.acceptedPrivacy,
    required this.acceptedDataPolicy,
  });

  final String firstName;
  final String lastName;
  final SchoolClass schoolClass;
  final SchoolSeries? schoolSeries;
  final InterfaceLanguage interfaceLanguage;
  final EducationalSubsystem educationalSubsystem;
  final EducationType educationType;
  final String streamOrSpeciality;
  final EstablishmentAffiliation? establishment;
  final LearnerAccountLinkage accountLinkage;
  final String? selectedTutorId;
  final List<String> preferredSubjects;
  final List<String> difficultSubjects;
  final LearningGoal learningGoal;
  final int dailyStudyMinutes;
  final String email;
  final String password;
  final bool acceptedTerms;
  final bool acceptedPrivacy;
  final bool acceptedDataPolicy;

  String? get _normalizedTutorId =>
      selectedTutorId == null ? null : TutorPersona.resolveId(selectedTutorId);

  Map<String, dynamic> _preferences() => <String, dynamic>{
    'preferredSubjects': preferredSubjects,
    'difficultSubjects': difficultSubjects,
    'learningGoal': learningGoal.label,
    'dailyStudyMinutes': dailyStudyMinutes,
    'studyReminderEnabled': true,
    'notificationsEnabled': true,
    'contentLanguage': interfaceLanguage.code,
    'interfaceLanguage': interfaceLanguage.code,
    'educationalSubsystem': educationalSubsystem.storageValue,
    'educationType': educationType.name,
    'academicLevelId': schoolClass.academicLevelId(educationType),
    'streamOrSpeciality': streamOrSpeciality.isEmpty
        ? schoolSeries?.label
        : streamOrSpeciality,
    'accountLinkage': accountLinkage.name,
    // Candidate metadata is deliberately non-authoritative. A trusted
    // backend is solely responsible for writing establishmentId.
    'establishmentCandidate': establishment == null
        ? null
        : <String, dynamic>{
            'candidateId': establishment!.candidateId,
            'name': establishment!.name,
            'city': establishment!.city,
            'region': establishment!.region,
            'status': establishment!.status.name,
          },
  };

  Map<String, dynamic> _consents(DateTime now) => <String, dynamic>{
    'termsAccepted': acceptedTerms,
    'privacyAccepted': acceptedPrivacy,
    'dataPolicyAccepted': acceptedDataPolicy,
    'acceptedAt': now.toUtc(),
  };

  Map<String, dynamic> toUserDocument({
    required String uid,
    required DateTime now,
  }) {
    return <String, dynamic>{
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': 'student',
      'classLevel': schoolClass.catalogKey,
      'series': schoolSeries?.label,
      'tutorId': _normalizedTutorId,
      'profileCompleted': true,
      'tourGuideSeen': false,
      'createdAt': now.toUtc(),
      'updatedAt': now.toUtc(),
    };
  }

  /// Only fields that the owner rules explicitly allow to change.
  ///
  /// Initial authority fields such as role and establishmentId are never
  /// replayed during a retry. This is what makes a second registration submit
  /// safe without widening the Firestore rules.
  Map<String, dynamic> toUserUpdateDocument({required DateTime now}) {
    return <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'profileCompleted': true,
      'updatedAt': now.toUtc(),
    };
  }

  Map<String, dynamic> toStudentProfileDocument({
    required String uid,
    required DateTime now,
  }) {
    return <String, dynamic>{
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'classLevel': schoolClass.catalogKey,
      'series': schoolSeries?.label,
      'points': 0,
      'level': 1,
      'streak': <String, dynamic>{
        'current': 0,
        'best': 0,
        'lastStudyDate': null,
      },
      'tutorId': _normalizedTutorId,
      'preferences': _preferences(),
      'consents': _consents(now),
      'profileCompleted': true,
      'createdAt': now.toUtc(),
      'updatedAt': now.toUtc(),
    };
  }

  /// Retry payload for a profile that already exists.
  ///
  /// points, level, establishmentId, classLevel and series are intentionally
  /// absent. They remain immutable from an untrusted client.
  Map<String, dynamic> toStudentProfileUpdateDocument({required DateTime now}) {
    return <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'tutorId': _normalizedTutorId,
      'preferences': _preferences(),
      'consents': _consents(now),
      'profileCompleted': true,
      'updatedAt': now.toUtc(),
    };
  }
}
