import 'phone_identity.dart';

enum OtpChannel { sms, whatsapp }

enum OtpPurpose {
  firstParentRegistration,
  newDevice,
  accountRecovery,
  sensitiveIdentityRecovery,
}

class OtpDeliveryRequest {
  const OtpDeliveryRequest({
    required this.phone,
    required this.channel,
    required this.purpose,
    required this.idempotencyKey,
    required this.deviceRiskReference,
  });

  final CameroonPhoneNumber phone;
  final OtpChannel channel;
  final OtpPurpose purpose;
  final String idempotencyKey;
  final String deviceRiskReference;
}

class OtpChallenge {
  const OtpChallenge({
    required this.challengeId,
    required this.expiresAt,
    required this.resendAvailableAt,
    required this.availableChannels,
  });

  final String challengeId;
  final DateTime expiresAt;
  final DateTime resendAvailableAt;
  final Set<OtpChannel> availableChannels;
}

class OtpVerificationRequest {
  const OtpVerificationRequest({
    required this.challengeId,
    required this.code,
    required this.deviceRiskReference,
  });

  final String challengeId;
  final String code;
  final String deviceRiskReference;
}

class FirebaseCustomTokenEnvelope {
  const FirebaseCustomTokenEnvelope({
    required this.customToken,
    required this.expiresAt,
  });

  /// Short-lived transport value. It must never be persisted or logged.
  final String customToken;
  final DateTime expiresAt;
}

/// Flutter talks only to the INTELLIA backend. SMS/WhatsApp provider selection,
/// credentials, OTP generation and Firebase Admin token minting stay server-side.
abstract interface class IntelliaOtpGateway {
  Future<OtpChallenge> send(OtpDeliveryRequest request);

  Future<FirebaseCustomTokenEnvelope> verify(OtpVerificationRequest request);
}
