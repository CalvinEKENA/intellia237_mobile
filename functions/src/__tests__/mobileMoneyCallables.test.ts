import { describe, expect, it } from "vitest";

import {
  authorizePaymentReview,
  createGetMobileMoneyOverviewHandler,
  createReviewMobileMoneyPaymentHandler,
  createSubmitMobileMoneyPaymentHandler,
  normalizeCameroonPhone,
  normalizeTransactionReference,
  type AdminPaymentRequest,
  type MobileMoneyOverview,
  type MobileMoneyPaymentStatus,
  type MobileMoneyStore,
  type ReviewMobileMoneyPaymentInput,
  type ReviewMobileMoneyPaymentResult,
  type SubmitMobileMoneyPaymentInput,
  type SubmitMobileMoneyPaymentResult,
} from "../services/mobileMoneyCallables";

describe("Mobile Money callables", () => {
  it("requires Firebase Auth before returning the server-configured offer", async () => {
    const handler = createGetMobileMoneyOverviewHandler(new MemoryStore());

    await expect(handler({ data: {} } as never)).rejects.toMatchObject({
      code: "unauthenticated",
    });
  });

  it("does not accept client-controlled amount, destination or role", async () => {
    const handler = createSubmitMobileMoneyPaymentHandler(new MemoryStore());

    await expect(
      handler({
        auth: { uid: "parent-a", token: {} },
        data: {
          offerId: "school-a",
          operatorCode: "mtn",
          payerPhone: "6 70 00 00 00",
          transactionReference: "TX-1234",
          clientRequestId: "request_123456",
          amountXaf: 1,
          recipientPhone: "+237600000000",
          role: "superAdmin",
        },
      } as never),
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("submits only the validated reference metadata to the store", async () => {
    const store = new MemoryStore();
    const handler = createSubmitMobileMoneyPaymentHandler(store);

    await expect(
      handler({
        auth: { uid: "parent-a", token: {} },
        data: {
          offerId: "school-a",
          operatorCode: "mtn",
          payerPhone: "670000000",
          transactionReference: "TX-1234",
          clientRequestId: "request_123456",
        },
      } as never),
    ).resolves.toMatchObject({ status: "pending" });
    expect(store.submissions).toEqual([
      {
        parentId: "parent-a",
        input: {
          offerId: "school-a",
          operatorCode: "mtn",
          payerPhone: "670000000",
          transactionReference: "TX-1234",
          clientRequestId: "request_123456",
        },
      },
    ]);
  });

  it("confines a school admin to its school and opens every school to the general administration", () => {
    const denied = expect.objectContaining({ code: "permission-denied" });
    expect(() => authorizePaymentReview(
      { role: "admin", accountStatus: "active", establishmentId: "school-a" },
      "school-a",
    )).not.toThrow();
    expect(() => authorizePaymentReview(
      { role: "admin", establishmentId: "school-a" },
      "school-b",
    )).toThrowError(denied);
    expect(() => authorizePaymentReview({ role: "admin" }, "school-a")).toThrowError(denied);
    expect(() => authorizePaymentReview({ role: "superAdmin" }, "school-b")).not.toThrow();
    expect(() => authorizePaymentReview(
      { role: "super_admin", establishmentId: "school-a" },
      "school-b",
    )).not.toThrow();
    expect(() => authorizePaymentReview(
      { role: "superAdmin", accountStatus: "disabled" },
      "school-b",
    )).toThrowError(denied);
    expect(() => authorizePaymentReview({ role: "superAdmin" }, "")).toThrowError(denied);
    expect(() => authorizePaymentReview(
      { role: "teacher", establishmentId: "school-a" },
      "school-a",
    )).toThrowError(denied);
  });

  it("rejects any review payload attempting to mutate entitlement scope", async () => {
    const handler = createReviewMobileMoneyPaymentHandler(new MemoryStore());

    await expect(
      handler({
        auth: { uid: "admin-a", token: {} },
        data: {
          requestId: "request-a",
          decision: "approved",
          role: "superAdmin",
          establishmentId: "school-b",
          durationDays: 9999,
        },
      } as never),
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("normalizes Cameroonian phones and references, and rejects malformed values", () => {
    expect(normalizeCameroonPhone("+237 670 00 00 00")).toBe("+237670000000");
    expect(normalizeCameroonPhone("237670000000")).toBe("+237670000000");
    expect(normalizeTransactionReference(" tx-12 34 ")).toBe("TX-1234");
    expect(() => normalizeCameroonPhone("123")).toThrowError(
      expect.objectContaining({ code: "invalid-argument" }),
    );
    expect(() => normalizeTransactionReference("réf privée")).toThrowError(
      expect.objectContaining({ code: "invalid-argument" }),
    );
  });
});

class MemoryStore implements MobileMoneyStore {
  readonly submissions: Array<{
    parentId: string;
    input: SubmitMobileMoneyPaymentInput;
  }> = [];

  async getParentOverview(_parentId: string): Promise<MobileMoneyOverview> {
    return {
      availability: "not_configured",
      offer: null,
      recentRequests: [],
      children: [],
      beneficiary: null,
      coveredStudentIds: [],
    };
  }

  async submitParentPayment(
    parentId: string,
    input: SubmitMobileMoneyPaymentInput,
  ): Promise<SubmitMobileMoneyPaymentResult> {
    this.submissions.push({ parentId, input });
    return {
      requestId: "request-a",
      status: "pending",
      idempotentReplay: false,
    };
  }

  async listRequestsForReviewer(
    _reviewerId: string,
    _status: MobileMoneyPaymentStatus,
  ): Promise<AdminPaymentRequest[]> {
    return [];
  }

  async reviewPayment(
    _reviewerId: string,
    input: ReviewMobileMoneyPaymentInput,
  ): Promise<ReviewMobileMoneyPaymentResult> {
    return {
      requestId: input.requestId,
      status: input.decision,
      entitlementId: input.decision === "approved" ? "entitlement-a" : null,
      idempotentReplay: false,
    };
  }
}
