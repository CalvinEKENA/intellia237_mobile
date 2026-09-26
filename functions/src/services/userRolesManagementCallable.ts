import { FieldValue, type DocumentData, type Firestore } from "firebase-admin/firestore";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { z } from "zod";

import { db } from "../config/firebase";
import { toHttpsError } from "../utils/errors";
import { isSuperAdminUser, planRoleChange, primaryRole } from "../auth/userRoles";

/**
 * Espaces additifs d'un compte (`roles`), accordés ou retirés par la seule
 * super-administration.
 *
 * Registre de décisions (refonte Auth V2) : `roles` existait dans les règles
 * sans aucun écrivain ; un retrait fait sur `role` seul aurait laissé un
 * `roles` obsolète actif. Les deux champs sont désormais écrits ensemble,
 * dans une transaction, selon `planRoleChange` (auth/userRoles.ts), avec un
 * journal d'audit. Aucun client ne peut écrire `roles` (règles Firestore).
 */

const id = z.string().trim().min(1).max(128).regex(/^[^/]+$/);
export const manageUserRolesInput = z.object({
  accountId: id,
  action: z.enum(["grant", "revoke"]),
  role: z.enum(["parent", "teacher", "admin"]),
  reason: z.string().trim().min(3).max(500),
}).strict();
export type ManageUserRolesInput = z.infer<typeof manageUserRolesInput>;

export interface RoleChangeDecision {
  role: string;
  roles: string[] | null;
  unchanged: boolean;
}

/** Décision pure, testée sans Firestore. */
export function decideRoleChange(params: {
  actorId: string;
  actor: DocumentData | undefined;
  target: DocumentData | undefined;
  input: ManageUserRolesInput;
}): RoleChangeDecision {
  const { actorId, actor, target, input } = params;
  if (!actor || !isSuperAdminUser(actor) || (actor.accountStatus && actor.accountStatus !== "active")) {
    throw new HttpsError("permission-denied", "General administration is required.");
  }
  if (actorId === input.accountId) {
    throw new HttpsError("permission-denied", "An account cannot change its own spaces.");
  }
  if (!target) throw new HttpsError("not-found", "Account not found.");
  if (target.accountStatus === "deleted") {
    throw new HttpsError("failed-precondition", "A deleted account has no space to change.");
  }
  if (input.action === "grant" && input.role === "admin" &&
      !(typeof target.establishmentId === "string" && target.establishmentId.trim())) {
    // Une direction d'école appartient à une école.
    throw new HttpsError("failed-precondition", "A school administrator must belong to a school.");
  }
  const plan = planRoleChange(target, { action: input.action, role: input.role });
  if (!plan.ok) {
    if (plan.reason === "unchanged") {
      const currentRoles = Array.isArray(target.roles) ? target.roles.map(String) : null;
      return { role: primaryRole(target), roles: currentRoles, unchanged: true };
    }
    throw new HttpsError("failed-precondition", `Role change refused: ${plan.reason}.`, {
      reason: plan.reason,
    });
  }
  return { role: plan.role, roles: plan.roles, unchanged: false };
}

export class UserRolesManagementStore {
  constructor(private readonly firestore: Firestore = db) {}

  async execute(actorId: string, input: ManageUserRolesInput): Promise<{ accountId: string; role: string; roles: string[] | null }> {
    const actorRef = this.firestore.collection("users").doc(actorId);
    const targetRef = this.firestore.collection("users").doc(input.accountId);
    return this.firestore.runTransaction(async (transaction) => {
      const [actor, target] = await Promise.all([transaction.get(actorRef), transaction.get(targetRef)]);
      const decision = decideRoleChange({
        actorId,
        actor: actor.data(),
        target: target.exists ? target.data() : undefined,
        input,
      });
      if (!decision.unchanged) {
        const before = target.data() ?? {};
        transaction.update(targetRef, {
          role: decision.role,
          roles: decision.roles ?? FieldValue.delete(),
          updatedAt: FieldValue.serverTimestamp(),
          managedBy: actorId,
        });
        transaction.create(this.firestore.collection("account_role_changes").doc(), {
          actorId,
          targetId: input.accountId,
          action: input.action,
          role: input.role,
          reason: input.reason,
          before: { role: before.role ?? null, roles: Array.isArray(before.roles) ? before.roles : null },
          after: { role: decision.role, roles: decision.roles },
          createdAt: FieldValue.serverTimestamp(),
        });
      }
      return { accountId: input.accountId, role: decision.role, roles: decision.roles };
    });
  }
}

export function createManageUserRolesHandler(store: UserRolesManagementStore = new UserRolesManagementStore()) {
  return async (request: CallableRequest<unknown>) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    const parsed = manageUserRolesInput.safeParse(request.data);
    if (!parsed.success) throw new HttpsError("invalid-argument", "Invalid request payload.");
    try {
      return await store.execute(uid, parsed.data);
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      throw toHttpsError(error);
    }
  };
}
