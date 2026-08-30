import 'family_graph.dart';

enum FamilyDeviceTrust { untrusted, trusted, revoked }

class FamilyDeviceAuthorization {
  const FamilyDeviceAuthorization({
    required this.deviceReference,
    required this.guardianUid,
    required this.trust,
  });

  final String deviceReference;
  final String guardianUid;
  final FamilyDeviceTrust trust;
}

class LearnerSwitchRequest {
  const LearnerSwitchRequest({
    required this.selectedLearnerUid,
    required this.deviceReference,
  });

  /// A selection hint only. The server must verify guardian link, permission,
  /// device trust and revocation state before issuing a learner session.
  final String selectedLearnerUid;
  final String deviceReference;

  bool get isAuthorizationProof => false;
}

class ServerIssuedLearnerSession {
  const ServerIssuedLearnerSession({
    required this.learnerUid,
    required this.serverGrantId,
    required this.expiresAt,
  });

  final String learnerUid;
  final String serverGrantId;
  final DateTime expiresAt;
}

abstract interface class LearnerSessionBroker {
  Future<ServerIssuedLearnerSession> requestLearnerSession(
    LearnerSwitchRequest request,
  );
}

bool canRequestLearnerSession({
  required GuardianLearnerLink link,
  required FamilyDeviceAuthorization device,
}) =>
    device.trust == FamilyDeviceTrust.trusted &&
    device.guardianUid == link.guardianUid &&
    link.authorizes(GuardianPermission.startStudyMode);
