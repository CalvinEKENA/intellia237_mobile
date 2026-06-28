class TeacherRegistrationPayload {
  const TeacherRegistrationPayload({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.subjects,
    required this.levels,
    required this.acceptedTerms,
    required this.acceptedPrivacy,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final List<String> subjects;
  final List<String> levels;
  final bool acceptedTerms;
  final bool acceptedPrivacy;

  Map<String, dynamic> toUserDocument({
    required String uid,
    required DateTime now,
  }) {
    return <String, dynamic>{
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': 'teacher',
      'avatarId': 'mentor',
      'profileCompleted': true,
      'tourGuideSeen': false,
      'createdAt': now.toUtc(),
      'updatedAt': now.toUtc(),
    };
  }

  Map<String, dynamic> toTeacherProfileDocument({
    required String uid,
    required DateTime now,
  }) {
    return <String, dynamic>{
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'subjects': subjects,
      'levels': levels,
      'workload': <String, dynamic>{'activeClasses': 0, 'activeStudents': 0},
      'settings': <String, dynamic>{
        'notificationsEnabled': true,
        'resourceRecommendationsEnabled': true,
      },
      'profileCompleted': true,
      'createdAt': now.toUtc(),
      'updatedAt': now.toUtc(),
      'consents': <String, dynamic>{
        'termsAccepted': acceptedTerms,
        'privacyAccepted': acceptedPrivacy,
        'acceptedAt': now.toUtc(),
      },
    };
  }

  Map<String, dynamic> toStaffRegistrationData() {
    return <String, dynamic>{
      'role': 'teacher',
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim(),
      'subjects': subjects,
      'levels': levels,
      'acceptedTerms': acceptedTerms,
      'acceptedPrivacy': acceptedPrivacy,
    };
  }
}
