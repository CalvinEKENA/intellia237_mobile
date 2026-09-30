import { createHash } from "node:crypto";

import { logger } from "firebase-functions";
import type { CallableRequest } from "firebase-functions/v2/https";
import { HttpsError } from "firebase-functions/v2/https";
import {
  FieldValue,
  Timestamp,
  type DocumentData,
  type Firestore,
} from "firebase-admin/firestore";
import { z } from "zod";

import { db } from "../config/firebase";
import { AppError, toHttpsError } from "../utils/errors";
import { hasUserRole, isSuperAdminUser } from "../auth/userRoles";

const documentIdSchema = z
  .string()
  .trim()
  .min(1)
  .max(128)
  .regex(/^[A-Za-z0-9_-]+$/);

const operatorCodeSchema = z
  .string()
  .trim()
  .min(2)
  .max(32)
  .regex(/^[a-z0-9_-]+$/);

const submitPaymentSchema = z
  .object({
    offerId: documentIdSchema,
    // Contexte explicite : l'enfant pour qui l'on paie. Il désigne l'école et
    // donc l'offre ; le serveur ne devine jamais l'école d'un parent.
    beneficiaryStudentId: documentIdSchema.optional(),
    operatorCode: operatorCodeSchema,
    payerPhone: z.string().trim().min(9).max(24),
    transactionReference: z.string().trim().min(4).max(80),
    clientRequestId: z
      .string()
      .trim()
      .min(12)
      .max(80)
      .regex(/^[A-Za-z0-9_-]+$/),
  })
  .strict();

const overviewSchema = z
  .object({ beneficiaryStudentId: documentIdSchema.optional() })
  .strict();

const listPaymentRequestsSchema = z
  .object({
    status: z.enum(["pending", "approved", "rejected"]).default("pending"),
  })
  .strict();

const reviewPaymentSchema = z
  .object({
    requestId: documentIdSchema,
    decision: z.enum(["approved", "rejected"]),
    reviewNote: z.string().trim().max(280).optional(),
  })
  .strict();

const configuredOperatorSchema = z
  .object({
    code: operatorCodeSchema,
    label: z.string().trim().min(2).max(80),
    recipientPhone: z.string().trim().min(5).max(32),
    instructions: z.string().trim().min(1).max(300).optional(),
  })
  .strict();

const configuredOfferSchema = z
  .object({
    status: z.literal("active"),
    establishmentId: documentIdSchema,
    title: z.string().trim().min(2).max(100),
    description: z.string().trim().min(1).max(500),
    amountXaf: z.number().int().min(100).max(10_000_000),
    currency: z.literal("XAF"),
    durationDays: z.number().int().min(1).max(730),
    operators: z.array(configuredOperatorSchema).min(1).max(8),
  })
  .passthrough();

export type MobileMoneyPaymentStatus = "pending" | "approved" | "rejected";

export interface MobileMoneyOperator {
  code: string;
  label: string;
  recipientPhone: string;
  instructions?: string;
}

export interface MobileMoneyOffer {
  id: string;
  establishmentId: string;
  title: string;
  description: string;
  amountXaf: number;
  currency: "XAF";
  durationDays: number;
  operators: MobileMoneyOperator[];
}

export interface ParentPaymentStatus {
  requestId: string;
  establishmentId: string;
  beneficiaryStudentId: string | null;
  offerTitle: string;
  amountXaf: number;
  operatorLabel: string;
  status: MobileMoneyPaymentStatus;
  submittedAt: string | null;
  reviewedAt: string | null;
  referenceHint: string;
  reviewNote: string | null;
}

/** Un enfant lié, avec l'école qui détermine son offre. */
export interface MobileMoneyChildContext {
  studentId: string;
  firstName: string;
  establishmentId: string;
}

export interface MobileMoneyOverview {
  availability:
    | "available"
    | "not_configured"
    | "school_not_linked"
    | "multiple_schools";
  offer: MobileMoneyOffer | null;
  recentRequests: ParentPaymentStatus[];
  /** Enfants liés (champ additif : les anciennes versions l'ignorent). */
  children: MobileMoneyChildContext[];
  /** L'enfant choisi quand l'appel en nomme un, sinon null. */
  beneficiary: MobileMoneyChildContext | null;
  /**
   * Enfants de ce parent couverts par un paiement pour cette école
   * (sémantique V1 : un parent paie pour ses enfants d'une même école).
   */
  coveredStudentIds: string[];
}

export interface MobileMoneyOverviewOptions {
  beneficiaryStudentId?: string;
}

export interface SubmitMobileMoneyPaymentInput {
  offerId: string;
  beneficiaryStudentId?: string;
  operatorCode: string;
  payerPhone: string;
  transactionReference: string;
  clientRequestId: string;
}

export interface SubmitMobileMoneyPaymentResult {
  requestId: string;
  status: MobileMoneyPaymentStatus;
  idempotentReplay: boolean;
}

export interface ReviewMobileMoneyPaymentInput {
  requestId: string;
  decision: "approved" | "rejected";
  reviewNote?: string;
}

export interface AdminPaymentRequest {
  requestId: string;
  parentId: string;
  parentName: string;
  establishmentId: string;
  beneficiaryStudentId: string | null;
  offerTitle: string;
  amountXaf: number;
  currency: "XAF";
  operatorCode: string;
  operatorLabel: string;
  payerPhone: string;
  transactionReference: string;
  status: MobileMoneyPaymentStatus;
  submittedAt: string | null;
}

export interface ReviewMobileMoneyPaymentResult {
  requestId: string;
  status: "approved" | "rejected";
  entitlementId: string | null;
  idempotentReplay: boolean;
}

export interface MobileMoneyStore {
  getParentOverview(
    parentId: string,
    options?: MobileMoneyOverviewOptions,
  ): Promise<MobileMoneyOverview>;
  submitParentPayment(
    parentId: string,
    input: SubmitMobileMoneyPaymentInput,
  ): Promise<SubmitMobileMoneyPaymentResult>;
  listRequestsForReviewer(
    reviewerId: string,
    status: MobileMoneyPaymentStatus,
  ): Promise<AdminPaymentRequest[]>;
  reviewPayment(
    reviewerId: string,
    input: ReviewMobileMoneyPaymentInput,
  ): Promise<ReviewMobileMoneyPaymentResult>;
}

export class FirestoreMobileMoneyStore implements MobileMoneyStore {
  constructor(private readonly firestore: Firestore = db) {}

  async getParentOverview(
    parentId: string,
    options: MobileMoneyOverviewOptions = {},
  ): Promise<MobileMoneyOverview> {
    const scope = options.beneficiaryStudentId
      ? await this.resolveBeneficiaryScope(parentId, options.beneficiaryStudentId)
      : await this.resolveParentScope(parentId);
    const recentRequests = await this.fetchParentRequests(parentId);
    const context = {
      recentRequests,
      children: scope.children,
      beneficiary: scope.beneficiary,
      coveredStudentIds: scope.establishmentId
        ? coveredChildren(scope.children, scope.establishmentId)
        : [],
    };
    if (scope.availability !== "available" || !scope.establishmentId) {
      return { availability: scope.availability, offer: null, ...context };
    }

    const offer = await this.fetchActiveOffer(scope.establishmentId);
    return {
      availability: offer ? "available" : "not_configured",
      offer,
      ...context,
    };
  }

  async submitParentPayment(
    parentId: string,
    input: SubmitMobileMoneyPaymentInput,
  ): Promise<SubmitMobileMoneyPaymentResult> {
    const scope = input.beneficiaryStudentId
      ? await this.resolveBeneficiaryScope(parentId, input.beneficiaryStudentId)
      : await this.resolveParentScope(parentId);
    if (scope.availability !== "available" || !scope.establishmentId) {
      throw new AppError(
        "failed-precondition",
        input.beneficiaryStudentId
          ? "This child's school is not linked to a Mobile Money offer."
          : "No single authorized school is linked to this parent account.",
      );
    }

    if (input.offerId !== scope.establishmentId) {
      throw new AppError(
        "permission-denied",
        "The selected offer does not belong to the authorized school.",
      );
    }

    const offer = await this.fetchActiveOffer(scope.establishmentId);
    if (!offer || offer.id !== input.offerId) {
      throw new AppError(
        "failed-precondition",
        "The selected Mobile Money offer is unavailable.",
      );
    }

    const operator = offer.operators.find(
      (item) => item.code === input.operatorCode,
    );
    if (!operator) {
      throw new AppError(
        "invalid-argument",
        "The selected operator is not enabled for this offer.",
      );
    }

    const payerPhone = normalizeCameroonPhone(input.payerPhone);
    const transactionReference = normalizeTransactionReference(
      input.transactionReference,
    );
    const referenceHash = sha256(
      `${input.operatorCode}:${transactionReference}`,
    );
    const requestId = sha256(`${parentId}:${input.clientRequestId}`).slice(0, 40);
    const payloadHash = sha256(
      JSON.stringify({
        parentId,
        offerId: offer.id,
        operatorCode: operator.code,
        payerPhone,
        transactionReference,
        // Absent des anciennes demandes : leur empreinte reste identique.
        ...(input.beneficiaryStudentId
          ? { beneficiaryStudentId: input.beneficiaryStudentId }
          : {}),
      }),
    );
    const requestRef = this.firestore
      .collection("mobile_money_payment_requests")
      .doc(requestId);
    const referenceRef = this.firestore
      .collection("mobile_money_reference_keys")
      .doc(referenceHash);
    const parentSnapshot = await this.firestore
      .collection("users")
      .doc(parentId)
      .get();
    const parentName = displayName(parentSnapshot.data());

    return this.firestore.runTransaction(async (transaction) => {
      const [existingRequest, existingReference] = await Promise.all([
        transaction.get(requestRef),
        transaction.get(referenceRef),
      ]);

      if (existingRequest.exists) {
        const data = existingRequest.data() ?? {};
        if (data.payloadHash !== payloadHash) {
          throw new AppError(
            "already-exists",
            "This idempotency key was already used for another payment request.",
          );
        }
        return {
          requestId,
          status: readPaymentStatus(data.status),
          idempotentReplay: true,
        };
      }

      if (existingReference.exists) {
        throw new AppError(
          "already-exists",
          "This transaction reference has already been submitted.",
        );
      }

      transaction.create(requestRef, {
        requestId,
        parentId,
        parentName,
        // Payeur et bénéficiaire sont modélisés séparément. Le numéro Mobile
        // Money n'est qu'un moyen de paiement : jamais une preuve d'identité.
        payerType: "parent",
        payerId: parentId,
        beneficiaryStudentId: input.beneficiaryStudentId ?? null,
        beneficiaryScope: "parent_children_in_establishment",
        coveredStudentIds: coveredChildren(scope.children, offer.establishmentId),
        establishmentId: offer.establishmentId,
        offerId: offer.id,
        offerTitle: offer.title,
        amountXaf: offer.amountXaf,
        currency: offer.currency,
        durationDays: offer.durationDays,
        operatorCode: operator.code,
        operatorLabel: operator.label,
        payerPhone,
        transactionReference,
        referenceHash,
        payloadHash,
        status: "pending",
        submittedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      transaction.create(referenceRef, {
        requestId,
        createdAt: FieldValue.serverTimestamp(),
      });

      return {
        requestId,
        status: "pending",
        idempotentReplay: false,
      };
    });
  }

  async listRequestsForReviewer(
    reviewerId: string,
    status: MobileMoneyPaymentStatus,
  ): Promise<AdminPaymentRequest[]> {
    const context = await this.requireReviewer(reviewerId);
    const requests = this.firestore.collection("mobile_money_payment_requests");
    // The general administration follows the payments of every school.
    const snapshot = await (context.unrestricted
      ? requests.limit(300)
      : requests.where("establishmentId", "==", context.establishmentId).limit(100)
    ).get();

    return snapshot.docs
      .map((document) => toAdminPaymentRequest(document.id, document.data()))
      .filter((request) => request.status === status)
      .sort((left, right) =>
        (right.submittedAt ?? "").localeCompare(left.submittedAt ?? ""),
      )
      .slice(0, 50);
  }

  async reviewPayment(
    reviewerId: string,
    input: ReviewMobileMoneyPaymentInput,
  ): Promise<ReviewMobileMoneyPaymentResult> {
    const requestRef = this.firestore
      .collection("mobile_money_payment_requests")
      .doc(input.requestId);
    const reviewerRef = this.firestore.collection("users").doc(reviewerId);

    return this.firestore.runTransaction(async (transaction) => {
      const [reviewerSnapshot, requestSnapshot] = await Promise.all([
        transaction.get(reviewerRef),
        transaction.get(requestRef),
      ]);
      if (!requestSnapshot.exists) {
        throw new AppError("not-found", "Payment request was not found.");
      }
      const requestData = requestSnapshot.data() ?? {};
      const establishmentId = normalizedString(requestData.establishmentId);
      authorizePaymentReview(reviewerSnapshot.data(), establishmentId);

      const currentStatus = readPaymentStatus(requestData.status);
      if (currentStatus === input.decision) {
        return {
          requestId: input.requestId,
          status: input.decision,
          entitlementId:
            input.decision === "approved"
              ? entitlementDocumentId(
                normalizedString(requestData.parentId),
                establishmentId,
              )
              : null,
          idempotentReplay: true,
        };
      }
      if (currentStatus !== "pending") {
        throw new AppError(
          "failed-precondition",
          "A reviewed payment request cannot receive a different decision.",
        );
      }

      let entitlementId: string | null = null;
      if (input.decision === "approved") {
        const parentId = normalizedString(requestData.parentId);
        const durationDays = integerInRange(requestData.durationDays, 1, 730);
        entitlementId = entitlementDocumentId(parentId, establishmentId);
        const entitlementRef = this.firestore
          .collection("entitlements")
          .doc(entitlementId);
        const entitlementSnapshot = await transaction.get(entitlementRef);
        const now = new Date();
        const existingEnd = timestampDate(entitlementSnapshot.data()?.endsAt);
        const base = existingEnd && existingEnd > now ? existingEnd : now;
        const endsAt = new Date(
          base.getTime() + durationDays * 24 * 60 * 60 * 1000,
        );
        transaction.set(
          entitlementRef,
          {
            entitlementId,
            userId: parentId,
            payerType: "parent",
            payerId: parentId,
            beneficiaryScope: "parent_children_in_establishment",
            ...(normalizedString(requestData.beneficiaryStudentId)
              ? { lastBeneficiaryStudentId: normalizedString(requestData.beneficiaryStudentId) }
              : {}),
            establishmentId,
            status: "active",
            source: "manual_mobile_money",
            offerId: normalizedString(requestData.offerId),
            grantRequestId: input.requestId,
            startsAt:
              entitlementSnapshot.exists && existingEnd && existingEnd > now
                ? entitlementSnapshot.data()?.startsAt ?? Timestamp.fromDate(now)
                : Timestamp.fromDate(now),
            endsAt: Timestamp.fromDate(endsAt),
            grantedBy: reviewerId,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }

      transaction.update(requestRef, {
        status: input.decision,
        reviewedBy: reviewerId,
        reviewedAt: FieldValue.serverTimestamp(),
        reviewNote: input.reviewNote?.trim() || null,
        entitlementId,
        updatedAt: FieldValue.serverTimestamp(),
      });

      return {
        requestId: input.requestId,
        status: input.decision,
        entitlementId,
        idempotentReplay: false,
      };
    });
  }

  private async resolveParentScope(parentId: string): Promise<ParentScope> {
    const parentData = await this.requireParent(parentId);
    const children = await this.linkedChildren(parentId);

    const directEstablishmentId = normalizedString(parentData?.establishmentId);
    // A parent can only use a direct school assignment when a trusted backend
    // explicitly marked it as verified. Public profile creation cannot set
    // this marker; otherwise an arbitrary school id would become an offer leak.
    if (directEstablishmentId && parentData?.establishmentVerified === true) {
      return {
        availability: "available",
        establishmentId: directEstablishmentId,
        children,
        beneficiary: null,
      };
    }

    const none = { establishmentId: null, children, beneficiary: null };
    if (children.length === 0) {
      return { availability: "school_not_linked", ...none };
    }
    const establishmentIds = new Set(
      children.map((child) => child.establishmentId).filter(Boolean),
    );
    if (establishmentIds.size === 0) {
      return { availability: "school_not_linked", ...none };
    }
    if (establishmentIds.size > 1) {
      // Sans enfant nommé, l'école est ambiguë : les versions récentes
      // choisissent l'enfant (donc l'école), les anciennes gardent ce refus.
      return { availability: "multiple_schools", ...none };
    }
    return {
      availability: "available",
      establishmentId: [...establishmentIds][0],
      children,
      beneficiary: null,
    };
  }

  /** Contexte explicite : l'école est celle de l'enfant, jamais celle du parent. */
  private async resolveBeneficiaryScope(
    parentId: string,
    studentId: string,
  ): Promise<ParentScope> {
    await this.requireParent(parentId);
    const children = await this.linkedChildren(parentId);
    const beneficiary = children.find((child) => child.studentId === studentId);
    if (!beneficiary) {
      throw new AppError(
        "permission-denied",
        "This child is not linked to this parent account.",
      );
    }
    return beneficiary.establishmentId
      ? {
        availability: "available",
        establishmentId: beneficiary.establishmentId,
        children,
        beneficiary,
      }
      : {
        availability: "school_not_linked",
        establishmentId: null,
        children,
        beneficiary,
      };
  }

  private async requireParent(parentId: string): Promise<DocumentData | undefined> {
    const parentSnapshot = await this.firestore
      .collection("users")
      .doc(parentId)
      .get();
    const parentData = parentSnapshot.data();
    if (!parentSnapshot.exists || !hasUserRole(parentData, "parent")) {
      throw new AppError(
        "permission-denied",
        "Only a parent account can access Mobile Money subscriptions.",
      );
    }
    return parentData;
  }

  private async linkedChildren(parentId: string): Promise<MobileMoneyChildContext[]> {
    const links = await this.firestore
      .collection("children_links")
      .where("parentId", "==", parentId)
      .limit(20)
      .get();
    const studentIds = links.docs
      .filter((link) => normalizedString(link.data().status) === "approved")
      .map((link) => normalizedString(link.data().studentId))
      .filter(Boolean);
    if (studentIds.length === 0) return [];
    // Même source que la Réserve d'étude : `users/{id}.establishmentId`.
    const studentSnapshots = await this.firestore.getAll(
      ...studentIds.map((studentId) =>
        this.firestore.collection("users").doc(studentId),
      ),
    );
    return studentSnapshots
      .filter((snapshot) => snapshot.exists)
      .map((snapshot) => ({
        studentId: snapshot.id,
        firstName: normalizedString(snapshot.data()?.firstName),
        establishmentId: normalizedString(snapshot.data()?.establishmentId),
      }));
  }

  private async fetchActiveOffer(
    establishmentId: string,
  ): Promise<MobileMoneyOffer | null> {
    const snapshot = await this.firestore
      .collection("mobile_money_offers")
      .doc(establishmentId)
      .get();
    if (!snapshot.exists) return null;
    const parsed = configuredOfferSchema.safeParse(snapshot.data());
    if (!parsed.success || parsed.data.establishmentId !== establishmentId) {
      logger.error("Invalid Mobile Money offer configuration.", {
        establishmentId,
      });
      return null;
    }
    return {
      id: snapshot.id,
      establishmentId,
      title: parsed.data.title,
      description: parsed.data.description,
      amountXaf: parsed.data.amountXaf,
      currency: parsed.data.currency,
      durationDays: parsed.data.durationDays,
      operators: parsed.data.operators,
    };
  }

  private async fetchParentRequests(
    parentId: string,
  ): Promise<ParentPaymentStatus[]> {
    const snapshot = await this.firestore
      .collection("mobile_money_payment_requests")
      .where("parentId", "==", parentId)
      .limit(30)
      .get();
    return snapshot.docs
      .map((document) => {
        const data = document.data();
        return {
          requestId: document.id,
          establishmentId: normalizedString(data.establishmentId),
          beneficiaryStudentId: normalizedString(data.beneficiaryStudentId) || null,
          offerTitle: normalizedString(data.offerTitle),
          amountXaf: integerInRange(data.amountXaf, 0, 10_000_000),
          operatorLabel: normalizedString(data.operatorLabel),
          status: readPaymentStatus(data.status),
          submittedAt: timestampIso(data.submittedAt),
          reviewedAt: timestampIso(data.reviewedAt),
          referenceHint: referenceHint(normalizedString(data.transactionReference)),
          reviewNote: normalizedString(data.reviewNote) || null,
        } satisfies ParentPaymentStatus;
      })
      .sort((left, right) =>
        (right.submittedAt ?? "").localeCompare(left.submittedAt ?? ""),
      )
      .slice(0, 10);
  }

  private async requireReviewer(reviewerId: string): Promise<{
    unrestricted: boolean;
    establishmentId: string;
  }> {
    const snapshot = await this.firestore
      .collection("users")
      .doc(reviewerId)
      .get();
    return authorizePaymentReviewer(snapshot.data());
  }
}

export function createGetMobileMoneyOverviewHandler(
  store: MobileMoneyStore = new FirestoreMobileMoneyStore(),
) {
  return async (request: CallableRequest<unknown>): Promise<MobileMoneyOverview> => {
    const uid = requireAuthenticatedUid(request);
    try {
      const input = overviewSchema.parse(request.data ?? {});
      return await store.getParentOverview(uid, input);
    } catch (error) {
      logger.error("getMobileMoneyOverview failed.", {
        uid,
        error: safeErrorMessage(error),
      });
      throw toHttpsError(error);
    }
  };
}

export function createSubmitMobileMoneyPaymentHandler(
  store: MobileMoneyStore = new FirestoreMobileMoneyStore(),
) {
  return async (
    request: CallableRequest<unknown>,
  ): Promise<SubmitMobileMoneyPaymentResult> => {
    const uid = requireAuthenticatedUid(request);
    try {
      const input = submitPaymentSchema.parse(request.data);
      return await store.submitParentPayment(uid, input);
    } catch (error) {
      // Intentionally never logs the callable payload, payer phone or reference.
      logger.error("submitMobileMoneyPayment failed.", {
        uid,
        error: safeErrorMessage(error),
      });
      throw toHttpsError(error);
    }
  };
}

export function createListMobileMoneyPaymentsHandler(
  store: MobileMoneyStore = new FirestoreMobileMoneyStore(),
) {
  return async (
    request: CallableRequest<unknown>,
  ): Promise<{ requests: AdminPaymentRequest[] }> => {
    const uid = requireAuthenticatedUid(request);
    try {
      const input = listPaymentRequestsSchema.parse(request.data ?? {});
      return {
        requests: await store.listRequestsForReviewer(uid, input.status),
      };
    } catch (error) {
      logger.error("listMobileMoneyPayments failed.", {
        uid,
        error: safeErrorMessage(error),
      });
      throw toHttpsError(error);
    }
  };
}

export function createReviewMobileMoneyPaymentHandler(
  store: MobileMoneyStore = new FirestoreMobileMoneyStore(),
) {
  return async (
    request: CallableRequest<unknown>,
  ): Promise<ReviewMobileMoneyPaymentResult> => {
    const uid = requireAuthenticatedUid(request);
    try {
      const input = reviewPaymentSchema.parse(request.data);
      return await store.reviewPayment(uid, input);
    } catch (error) {
      // The request id is deliberately omitted as a conservative PII boundary.
      logger.error("reviewMobileMoneyPayment failed.", {
        uid,
        error: safeErrorMessage(error),
      });
      throw toHttpsError(error);
    }
  };
}

/**
 * Who may review payments: a school administrator for their school, the
 * general administration for every school.
 */
export function authorizePaymentReviewer(
  reviewerData: DocumentData | undefined,
): { unrestricted: boolean; establishmentId: string } {
  const unrestricted = isSuperAdminUser(reviewerData);
  if (!unrestricted && !hasUserRole(reviewerData, "admin")) {
    throw new AppError(
      "permission-denied",
      "Only an administrator can review a payment request.",
    );
  }
  const accountStatus = normalizedString(reviewerData?.accountStatus);
  if (accountStatus && accountStatus !== "active") {
    throw new AppError(
      "permission-denied",
      "The reviewer account is not active.",
    );
  }
  const establishmentId = normalizedString(reviewerData?.establishmentId);
  if (unrestricted) {
    return { unrestricted: true, establishmentId };
  }
  if (!establishmentId) {
    throw new AppError(
      "permission-denied",
      "A school administrator must belong to a school to review payments.",
    );
  }
  return { unrestricted: false, establishmentId };
}

export function authorizePaymentReview(
  reviewerData: DocumentData | undefined,
  requestEstablishmentId: string,
): void {
  const reviewer = authorizePaymentReviewer(reviewerData);
  // An entitlement is granted for a school: a request without one is refused
  // to everyone, the general administration included.
  if (!requestEstablishmentId) {
    throw new AppError(
      "permission-denied",
      "A payment request without a school cannot be reviewed.",
    );
  }
  if (!reviewer.unrestricted && reviewer.establishmentId !== requestEstablishmentId) {
    throw new AppError(
      "permission-denied",
      "Cross-establishment payment review is forbidden.",
    );
  }
}

export function normalizeCameroonPhone(value: string): string {
  const compact = value.replace(/[\s().-]/g, "");
  const local = compact.startsWith("+237")
    ? compact.slice(4)
    : compact.startsWith("237")
      ? compact.slice(3)
      : compact;
  if (!/^6\d{8}$/.test(local)) {
    throw new AppError(
      "invalid-argument",
      "A valid Cameroonian mobile phone number is required.",
    );
  }
  return `+237${local}`;
}

export function normalizeTransactionReference(value: string): string {
  const normalized = value.trim().toUpperCase().replace(/\s+/g, "");
  if (!/^[A-Z0-9][A-Z0-9._/-]{3,79}$/.test(normalized)) {
    throw new AppError(
      "invalid-argument",
      "The transaction reference format is invalid.",
    );
  }
  return normalized;
}

function requireAuthenticatedUid(request: CallableRequest<unknown>): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Firebase Auth is required.");
  }
  return uid;
}

function entitlementDocumentId(parentId: string, establishmentId: string): string {
  if (!parentId || !establishmentId) {
    throw new AppError("failed-precondition", "Invalid entitlement scope.");
  }
  return `${parentId}_${establishmentId}`;
}

interface ParentScope {
  availability: MobileMoneyOverview["availability"];
  establishmentId: string | null;
  children: MobileMoneyChildContext[];
  beneficiary: MobileMoneyChildContext | null;
}

/** Enfants de ce parent qu'un paiement pour [establishmentId] couvre (V1). */
function coveredChildren(
  children: MobileMoneyChildContext[],
  establishmentId: string,
): string[] {
  return children
    .filter((child) => child.establishmentId === establishmentId)
    .map((child) => child.studentId);
}

function readPaymentStatus(value: unknown): MobileMoneyPaymentStatus {
  if (value === "approved" || value === "rejected") return value;
  return "pending";
}

function toAdminPaymentRequest(
  requestId: string,
  data: DocumentData,
): AdminPaymentRequest {
  return {
    requestId,
    parentId: normalizedString(data.parentId),
    parentName: normalizedString(data.parentName) || "Parent",
    establishmentId: normalizedString(data.establishmentId),
    beneficiaryStudentId: normalizedString(data.beneficiaryStudentId) || null,
    offerTitle: normalizedString(data.offerTitle),
    amountXaf: integerInRange(data.amountXaf, 0, 10_000_000),
    currency: "XAF",
    operatorCode: normalizedString(data.operatorCode),
    operatorLabel: normalizedString(data.operatorLabel),
    payerPhone: normalizedString(data.payerPhone),
    transactionReference: normalizedString(data.transactionReference),
    status: readPaymentStatus(data.status),
    submittedAt: timestampIso(data.submittedAt),
  };
}

function displayName(data: DocumentData | undefined): string {
  const value = [
    normalizedString(data?.firstName),
    normalizedString(data?.lastName),
  ]
    .filter(Boolean)
    .join(" ");
  return value || "Parent";
}

function normalizedString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function integerInRange(value: unknown, minimum: number, maximum: number): number {
  const number = typeof value === "number" ? Math.trunc(value) : Number.NaN;
  if (!Number.isFinite(number) || number < minimum || number > maximum) {
    throw new AppError("failed-precondition", "Invalid payment data.");
  }
  return number;
}

function timestampDate(value: unknown): Date | null {
  if (value instanceof Timestamp) return value.toDate();
  if (value instanceof Date) return value;
  return null;
}

function timestampIso(value: unknown): string | null {
  return timestampDate(value)?.toISOString() ?? null;
}

function referenceHint(value: string): string {
  if (!value) return "••••";
  return `••••${value.slice(-4)}`;
}

function sha256(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}

function safeErrorMessage(error: unknown): string {
  if (error instanceof z.ZodError) return "Invalid request payload.";
  if (error instanceof AppError) return error.message;
  if (error instanceof HttpsError) return error.message;
  return "Internal server error.";
}

export const getMobileMoneyOverviewHandler =
  createGetMobileMoneyOverviewHandler();
export const submitMobileMoneyPaymentHandler =
  createSubmitMobileMoneyPaymentHandler();
export const listMobileMoneyPaymentsHandler =
  createListMobileMoneyPaymentsHandler();
export const reviewMobileMoneyPaymentHandler =
  createReviewMobileMoneyPaymentHandler();
