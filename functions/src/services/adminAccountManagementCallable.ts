import { getAuth, type Auth } from "firebase-admin/auth";
import { FieldValue, type DocumentData, type Firestore } from "firebase-admin/firestore";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { z } from "zod";

import { db } from "../config/firebase";
import { toHttpsError } from "../utils/errors";

const id = z.string().trim().min(1).max(128).regex(/^[^/]+$/);
export const accountManagementInput = z.discriminatedUnion("action", [
  z.object({
    action: z.literal("createStudent"),
    requestId: z.string().uuid(),
    firstName: z.string().trim().min(1).max(80),
    lastName: z.string().trim().min(1).max(80),
    // Un élève n'a pas à posséder de téléphone : il entre avec un code d'accès.
    phoneNumber: z.string().regex(/^\+2376\d{8}$/).optional(),
    email: z.string().trim().toLowerCase().email().optional(),
    establishmentId: id,
  }).strict(),
  z.object({
    action: z.enum(["suspend", "reactivate", "delete", "restore"]),
    accountId: id,
    reason: z.string().trim().min(3).max(500),
  }).strict(),
]);
type Input = z.infer<typeof accountManagementInput>;

export function requireGeneralAdministrator(data: DocumentData | undefined): void {
  if (!data || !["superAdmin", "super_admin"].includes(data.role) ||
      (data.accountStatus && data.accountStatus !== "active")) {
    throw new HttpsError("permission-denied", "General administration is required.");
  }
}

export function nextAccountStatus(input: Exclude<Input, {action: "createStudent"}>,
  actorId: string, target: DocumentData): string {
  if (actorId === input.accountId ||
      !["student", "parent", "teacher", "admin"].includes(target.role)) {
    throw new HttpsError("permission-denied", "This account cannot be changed here.");
  }
  const current = target.accountStatus || "active";
  if (input.action === "delete") return "deleted";
  if (input.action === "restore") {
    if (current !== "deleted") {
      if (target.lastAccountAction === "restore") return current;
      throw new HttpsError("failed-precondition", "Only a deleted profile can be restored.");
    }
    return target.statusBeforeDeletion || "suspended";
  }
  if (input.action === "reactivate") {
    if (current !== "suspended" && current !== "active") {
      throw new HttpsError("failed-precondition", "Approve pending staff through account review.");
    }
    return "active";
  }
  if (current !== "active" && current !== "suspended") {
    throw new HttpsError("failed-precondition", "Only an active account can be suspended.");
  }
  return "suspended";
}

export class AdminAccountManagementStore {
  constructor(private readonly firestore: Firestore = db,
    private readonly auth: Auth = getAuth()) {}

  async execute(actorId: string, input: Input): Promise<{accountId: string; status: string}> {
    const actor = await this.firestore.collection("users").doc(actorId).get();
    requireGeneralAdministrator(actor.data());
    if (input.action === "createStudent") return this.createStudent(actorId, input);

    const targetRef = this.firestore.collection("users").doc(input.accountId);
    const status = await this.firestore.runTransaction(async transaction => {
      const [freshActor, target] = await Promise.all([
        transaction.get(actor.ref), transaction.get(targetRef),
      ]);
      requireGeneralAdministrator(freshActor.data());
      if (!target.exists) throw new HttpsError("not-found", "Account not found.");
      const data = target.data()!;
      const next = nextAccountStatus(input, actorId, data);
      transaction.update(targetRef, {
        accountStatus: next,
        ...(input.action === "delete" && data.accountStatus !== "deleted"
          ? { statusBeforeDeletion: data.accountStatus || "active" } : {}),
        updatedAt: FieldValue.serverTimestamp(),
        managedBy: actorId,
        lastAccountAction: input.action,
      });
      transaction.create(this.firestore.collection("account_management_audit").doc(), {
        actorId, targetId: input.accountId, action: input.action,
        previousStatus: data.accountStatus || "active", status: next,
        reason: input.reason, createdAt: FieldValue.serverTimestamp(),
      });
      return next;
    });
    // Firestore denies suspended/deleted profiles immediately. Auth then
    // prevents future sign-ins and refreshes, including password sign-in.
    // Repeating a suspend/delete also retries this synchronization safely.
    try {
      await this.auth.updateUser(input.accountId, {
        disabled: status === "suspended" || status === "deleted",
      });
      if (status === "suspended" || status === "deleted") {
        await this.auth.revokeRefreshTokens(input.accountId);
      }
    } catch (error) {
      if ((error as {code?: string}).code !== "auth/user-not-found") throw error;
    }
    return { accountId: input.accountId, status };
  }

  private async createStudent(actorId: string, input: Extract<Input, {action: "createStudent"}>) {
    const school = await this.firestore.collection("establishments").doc(input.establishmentId).get();
    if (!school.exists) throw new HttpsError("not-found", "School not found.");
    const uid = `adm_${input.requestId}`;
    const userRef = this.firestore.collection("users").doc(uid);
    const existing = await userRef.get();
    if (existing.exists) {
      if (existing.data()?.createdBy !== actorId ||
          (existing.data()?.phoneNumber ?? undefined) !== input.phoneNumber) {
        throw new HttpsError("already-exists", "Request already used.");
      }
      const status = existing.data()?.accountStatus || "active";
      await this.auth.updateUser(uid, { disabled: status === "suspended" || status === "deleted" });
      return { accountId: uid, status };
    }
    try {
      await this.auth.createUser({
        uid,
        ...(input.phoneNumber ? {phoneNumber: input.phoneNumber} : {}),
        disabled: true,
        ...(input.email ? {email: input.email} : {}),
        displayName: `${input.firstName} ${input.lastName}`,
      });
    } catch (error) {
      const code = (error as {code?: string}).code;
      if (code === "auth/uid-already-exists") {
        // A retry after Auth succeeded but before the Firestore commit.
        const created = await this.auth.getUser(uid);
        if (created.phoneNumber !== input.phoneNumber || created.email !== input.email) {
          throw new HttpsError("already-exists", "Request already used.");
        }
      } else if (code === "auth/email-already-exists" || code === "auth/phone-number-already-exists") {
        throw new HttpsError("already-exists", "This contact already has an account. Use account search.");
      } else { throw error; }
    }
    await this.firestore.runTransaction(async transaction => {
      const [freshActor, freshUser, freshSchool] = await Promise.all([
        transaction.get(this.firestore.collection("users").doc(actorId)),
        transaction.get(userRef), transaction.get(school.ref),
      ]);
      requireGeneralAdministrator(freshActor.data());
      if (!freshSchool.exists) throw new HttpsError("not-found", "School not found.");
      if (freshUser.exists) return;
      transaction.create(userRef, {
        uid, role: "student", firstName: input.firstName, lastName: input.lastName,
        ...(input.phoneNumber ? {phoneNumber: input.phoneNumber} : {}),
        email: input.email || "",
        establishmentId: input.establishmentId, accountStatus: "active",
        // The student chooses their own class and learning preferences.
        profileCompleted: false, createdBy: actorId,
        createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
      });
      transaction.create(this.firestore.collection("account_management_audit").doc(input.requestId), {
        actorId, targetId: uid, action: input.action,
        createdAt: FieldValue.serverTimestamp(),
      });
    });
    await this.auth.updateUser(uid, {disabled: false});
    return { accountId: uid, status: "active" };
  }
}

export function createManageAccountHandler(store = new AdminAccountManagementStore()) {
  return async (request: CallableRequest<unknown>) => {
    if (!request.auth?.uid) throw new HttpsError("unauthenticated", "Sign in first.");
    try {
      return await store.execute(request.auth.uid, accountManagementInput.parse(request.data));
    } catch (error) { throw toHttpsError(error); }
  };
}
export const manageAccountHandler = createManageAccountHandler();
