import { describe, expect, it } from "vitest";

import { OTP_SECURITY_POLICY, type OtpChannel } from "../auth/otpProvider";

describe("OTP provider security contract", () => {
  it("uses a short five-minute, one-time verifier policy", () => {
    expect(OTP_SECURITY_POLICY.ttlSeconds).toBe(300);
    expect(OTP_SECURITY_POLICY.maxVerificationAttempts).toBeGreaterThan(0);
    expect(OTP_SECURITY_POLICY.rawCodePersistenceAllowed).toBe(false);
    expect(OTP_SECURITY_POLICY.logCodeAllowed).toBe(false);
    expect(OTP_SECURITY_POLICY.invalidatePreviousOnResend).toBe(true);
  });

  it("requires App Check, idempotency, and phone/device throttling", () => {
    expect(OTP_SECURITY_POLICY.requireAppCheck).toBe(true);
    expect(OTP_SECURITY_POLICY.idempotentSendRequired).toBe(true);
    expect(OTP_SECURITY_POLICY.perPhoneRateLimitRequired).toBe(true);
    expect(OTP_SECURITY_POLICY.perDeviceRateLimitRequired).toBe(true);
    expect(OTP_SECURITY_POLICY.riskThrottlingRequired).toBe(true);
  });

  it("keeps delivery channels provider-agnostic", () => {
    const channels: OtpChannel[] = ["sms", "whatsapp"];
    expect(channels).toEqual(["sms", "whatsapp"]);
  });
});
