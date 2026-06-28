class AdminRegistrationPayload {
  const AdminRegistrationPayload({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.jobTitle,
    required this.acceptedTerms,
    required this.acceptedPrivacy,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String jobTitle;
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
      'role': 'admin',
      'jobTitle': jobTitle,
      'profileCompleted': true,
      'accountStatus': 'pending_validation',
      'requiresValidation': true,
      'tourGuideSeen': false,
      'createdAt': now.toUtc(),
      'updatedAt': now.toUtc(),
    };
  }

  Map<String, dynamic> toAdminProfileDocument({
    required String uid,
    required DateTime now,
  }) {
    return <String, dynamic>{
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'jobTitle': jobTitle,
      'validation': <String, dynamic>{
        'status': 'pending',
        'required': true,
        'requestedAt': now.toUtc(),
        'reviewedAt': null,
      },
      'permissions': <String, dynamic>{
        'canManageTeachers': false,
        'canManageStudents': false,
        'canViewFinance': false,
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
      'role': 'admin',
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim(),
      'jobTitle': jobTitle.trim(),
      'acceptedTerms': acceptedTerms,
      'acceptedPrivacy': acceptedPrivacy,
    };
  }
}
