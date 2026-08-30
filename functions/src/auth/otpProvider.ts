export type OtpChannel = "sms" | "whatsapp";

export type OtpPurpose =
  | "first-parent-registration"
  | "new-device"
  | "account-recovery"
  | "sensitive-identity-recovery";

export interface OtpProviderSendRequest {
  phoneE164: string;
  channel: OtpChannel;
  senderId?: string;
  code: string;
  expiresAt: Date;
}

export interface OtpProviderSendResult {
  deliveryReference: string;
  accepted: boolean;
}

/**
 * Server-only delivery port. Provider credentials and adapter selection are
 * supplied by server configuration and are never exposed to Flutter.
 */
export interface OtpProvider {
  send(request: OtpProviderSendRequest): Promise<OtpProviderSendResult>;
  deliveryStatus?(deliveryReference: string): Promise<"pending" | "delivered" | "failed">;
}

export interface OtpProviderSelector {
  select(channel: OtpChannel): OtpProvider;
}

export const OTP_SECURITY_POLICY = Object.freeze({
  ttlSeconds: 5 * 60,
  resendCooldownSeconds: 60,
  maxVerificationAttempts: 5,
  rawCodePersistenceAllowed: false,
  logCodeAllowed: false,
  invalidatePreviousOnResend: true,
  requireAppCheck: true,
  idempotentSendRequired: true,
  perPhoneRateLimitRequired: true,
  perDeviceRateLimitRequired: true,
  riskThrottlingRequired: true,
});

export interface StoredOtpChallenge {
  challengeId: string;
  phoneLookupDigest: string;
  verifierDigest: string;
  expiresAt: Date;
  resendAvailableAt: Date;
  attemptCount: number;
  consumedAt: Date | null;
  invalidatedAt: Date | null;
  idempotencyKeyDigest: string;
}

export interface OtpChallengeStore {
  save(challenge: StoredOtpChallenge): Promise<void>;
  consumeOnce(challengeId: string, expectedVerifierDigest: string): Promise<boolean>;
  invalidateActiveForPhone(phoneLookupDigest: string): Promise<void>;
}

export interface VerifiedPhoneIdentity {
  phoneE164: string;
  purpose: OtpPurpose;
  challengeId: string;
}

export interface FirebaseIdentityIssuer {
  /** Uses Firebase Admin after OTP verification. Never runs in Flutter. */
  issueCustomToken(identity: VerifiedPhoneIdentity): Promise<string>;
}
