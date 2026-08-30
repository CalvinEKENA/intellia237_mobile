enum GuardianRelationship { mother, father, guardian, other }

enum GuardianLearnerLinkStatus { pending, verified, revoked }

enum GuardianPermission { viewProgress, manageProfile, startStudyMode }

enum GuardianLinkMethod { secureInvite, temporaryCode, qrLink }

class CanonicalLearnerProfile {
  const CanonicalLearnerProfile({
    required this.learnerUid,
    required this.academicProfileId,
  });

  final String learnerUid;
  final String academicProfileId;
}

class GuardianLearnerLink {
  const GuardianLearnerLink({
    required this.guardianUid,
    required this.learnerUid,
    required this.relationship,
    required this.status,
    required this.permissions,
    required this.createdAt,
    this.verifiedAt,
  });

  final String guardianUid;
  final String learnerUid;
  final GuardianRelationship relationship;
  final GuardianLearnerLinkStatus status;
  final Set<GuardianPermission> permissions;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  String get id => '$guardianUid::$learnerUid';

  bool authorizes(GuardianPermission permission) =>
      status == GuardianLearnerLinkStatus.verified &&
      verifiedAt != null &&
      permissions.contains(permission);
}

class FamilyGraph {
  FamilyGraph({
    required Iterable<CanonicalLearnerProfile> learners,
    Iterable<GuardianLearnerLink> links = const [],
  }) : _learners = {
         for (final learner in learners) learner.learnerUid: learner,
       },
       _links = {for (final link in links) link.id: link};

  final Map<String, CanonicalLearnerProfile> _learners;
  final Map<String, GuardianLearnerLink> _links;

  List<CanonicalLearnerProfile> get learners =>
      List.unmodifiable(_learners.values);
  List<GuardianLearnerLink> get links => List.unmodifiable(_links.values);

  void upsertLink(GuardianLearnerLink link) {
    if (!_learners.containsKey(link.learnerUid)) {
      throw StateError('Canonical learner profile must exist before linking.');
    }
    _links[link.id] = link;
  }

  List<GuardianLearnerLink> guardiansFor(String learnerUid) => _links.values
      .where((link) => link.learnerUid == learnerUid)
      .toList(growable: false);

  List<GuardianLearnerLink> learnersFor(String guardianUid) => _links.values
      .where((link) => link.guardianUid == guardianUid)
      .toList(growable: false);
}

class GuardianLinkInvitation {
  const GuardianLinkInvitation({
    required this.serverReference,
    required this.method,
    required this.expiresAt,
  });

  /// Opaque server reference only; it is not an authorisation proof by itself.
  final String serverReference;
  final GuardianLinkMethod method;
  final DateTime expiresAt;
}
