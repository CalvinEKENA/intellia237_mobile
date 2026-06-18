class ParentRegistrationPayload {
  const ParentRegistrationPayload({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.childIdentifiers,
    required this.acceptedTerms,
    required this.acceptedPrivacy,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String password;
  final List<String> childIdentifiers;
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
      'phoneNumber': phoneNumber,
      'role': 'parent',
      'avatarId': 'guardian',
      'profileCompleted': true,
      'tourGuideSeen': false,
      'createdAt': now.toUtc(),
      'updatedAt': now.toUtc(),
    };
  }

  Map<String, dynamic> toParentProfileDocument({
    required String uid,
    required DateTime now,
  }) {
    return <String, dynamic>{
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'linkedChildren': [
        for (final childId in childIdentifiers)
          <String, dynamic>{
            'identifier': childId,
            'status': 'pending_link',
            'linkedAt': now.toUtc(),
          },
      ],
      'linkedChildrenCount': childIdentifiers.length,
      'preferences': <String, dynamic>{
        'notificationsEnabled': true,
        'weeklySummaryEnabled': true,
        'language': 'fr',
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
}
