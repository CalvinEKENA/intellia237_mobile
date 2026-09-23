import { FieldValue, type DocumentData, type Firestore } from "firebase-admin/firestore";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { z } from "zod";

import { db } from "../config/firebase";
import { toHttpsError } from "../utils/errors";
import { isSuperAdminUser } from "../auth/userRoles";

const id = z.string().trim().min(1).max(128).regex(/^[^/]+$/);

export const manageEstablishmentInput = z.discriminatedUnion("action", [
  z.object({
    action: z.literal("create"),
    id: id,
    name: z.string().trim().min(2).max(120),
    code: z.string().trim().min(2).max(30),
    city: z.string().trim().min(2).max(60),
    region: z.string().trim().min(2).max(60),
    address: z.string().trim().max(200).optional(),
    status: z.enum(["pending", "approved"]).default("pending"),
  }).strict(),
  z.object({
    action: z.literal("updateStatus"),
    establishmentId: id,
    status: z.enum(["pending", "approved", "suspended"]),
    reason: z.string().trim().min(3).max(500),
  }).strict(),
]);

export type ManageEstablishmentInput = z.infer<typeof manageEstablishmentInput>;

export function requireSuperAdmin(data: DocumentData | undefined): void {
  if (!data || !isSuperAdminUser(data) ||
      (data.accountStatus && data.accountStatus !== "active")) {
    throw new HttpsError("permission-denied", "SuperAdmin role is required.");
  }
}

export class EstablishmentManagementStore {
  constructor(private readonly firestore: Firestore = db) {}

  async execute(actorId: string, input: ManageEstablishmentInput): Promise<{ establishmentId: string; status: string }> {
    const actorSnapshot = await this.firestore.collection("users").doc(actorId).get();
    requireSuperAdmin(actorSnapshot.data());

    if (input.action === "create") {
      const estabRef = this.firestore.collection("establishments").doc(input.id);
      await this.firestore.runTransaction(async (tx) => {
        const freshActor = await tx.get(this.firestore.collection("users").doc(actorId));
        requireSuperAdmin(freshActor.data());

        const existing = await tx.get(estabRef);
        if (existing.exists) {
          throw new HttpsError("already-exists", "An establishment with this ID already exists.");
        }

        const now = FieldValue.serverTimestamp();
        tx.set(estabRef, {
          id: input.id,
          name: input.name,
          code: input.code,
          city: input.city,
          region: input.region,
          address: input.address || "",
          status: input.status,
          createdAt: now,
          updatedAt: now,
          createdBy: actorId,
        });

        tx.create(this.firestore.collection("establishment_management_audit").doc(), {
          actorId,
          establishmentId: input.id,
          action: "create",
          newStatus: input.status,
          createdAt: now,
        });
      });

      return { establishmentId: input.id, status: input.status };
    }

    const targetRef = this.firestore.collection("establishments").doc(input.establishmentId);
    await this.firestore.runTransaction(async (tx) => {
      const [freshActor, target] = await Promise.all([
        tx.get(this.firestore.collection("users").doc(actorId)),
        tx.get(targetRef),
      ]);
      requireSuperAdmin(freshActor.data());

      if (!target.exists) {
        throw new HttpsError("not-found", "Establishment not found.");
      }

      const currentData = target.data()!;
      const prevStatus = currentData.status || "pending";
      const now = FieldValue.serverTimestamp();

      tx.update(targetRef, {
        status: input.status,
        updatedAt: now,
        updatedBy: actorId,
      });

      tx.create(this.firestore.collection("establishment_management_audit").doc(), {
        actorId,
        establishmentId: input.establishmentId,
        action: "updateStatus",
        previousStatus: prevStatus,
        newStatus: input.status,
        reason: input.reason,
        createdAt: now,
      });
    });

    return { establishmentId: input.establishmentId, status: input.status };
  }
}

export function createManageEstablishmentHandler(store = new EstablishmentManagementStore()) {
  return async (request: CallableRequest<unknown>) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    try {
      const parsed = manageEstablishmentInput.parse(request.data);
      return await store.execute(request.auth.uid, parsed);
    } catch (error) {
      throw toHttpsError(error);
    }
  };
}

export const manageEstablishmentHandler = createManageEstablishmentHandler();
