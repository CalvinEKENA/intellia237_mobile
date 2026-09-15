import { getAuth, type Auth } from "firebase-admin/auth";
import type { Firestore } from "firebase-admin/firestore";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { z } from "zod";

import { db } from "../config/firebase";
import { parseEntitlementDocument } from "./studyReserveProvisioning";

/**
 * « Mes enfants » : ce qu'un parent est autorisé à savoir de chacun de ses
 * enfants, résolu côté serveur.
 *
 * Cinq dimensions restent séparées :
 * - identité : l'UID élève, jamais celui du parent ;
 * - relation : un lien `children_links` approuvé, seule source de visibilité ;
 * - école : celle de CHAQUE enfant — un parent n'a pas « une » école ;
 * - accès : comment l'enfant se connecte (son téléphone, son code INTELLIA),
 *   sans jamais exposer le numéro ni le code ;
 * - payeur : qui couvre l'enfant, selon la sémantique V1 (un parent paie pour
 *   ses enfants d'une école : `entitlements/{parentId}_{establishmentId}`).
 *
 * Les règles Firestore interdisent à un parent de lire l'école d'un enfant,
 * l'accès Auth ou l'abonnement d'un autre parent : ce modèle de lecture les
 * projette sans élargir aucune règle.
 */

export interface ParentChildSummary {
  studentId: string;
  firstName: string;
  lastName: string;
  classLevel: string;
  series: string | null;
  establishmentId: string;
  establishmentName: string;
  access: {
    ownPhone: boolean;
    accessCode: boolean;
    accessCodeIssuedAt: string | null;
  };
  subscription: {
    status: "active" | "inactive";
    endsAt: string | null;
    offerId: string | null;
    /** `you` : ce parent paie ; `another_guardian` : un autre parent lié paie. */
    paidBy: "you" | "another_guardian" | null;
  };
  /** Une offre Mobile Money est configurée pour l'école de cet enfant. */
  offerAvailable: boolean;
}

export interface ParentChildrenStore {
  readRole(uid: string): Promise<string>;
  approvedChildIds(parentId: string): Promise<string[]>;
  approvedGuardianIds(studentId: string): Promise<string[]>;
  readStudent(studentId: string): Promise<{
    role: string;
    accountStatus: string;
    firstName: string;
    lastName: string;
    classLevel: string;
    series: string | null;
    establishmentId: string;
  } | null>;
  establishmentNames(ids: string[]): Promise<Map<string, string>>;
  activeOfferIds(establishmentIds: string[]): Promise<Set<string>>;
  entitlement(parentId: string, establishmentId: string): Promise<Record<string, unknown> | undefined>;
  accessCodeIssuedAt(studentId: string): Promise<string | null | undefined>;
  phoneAccess(studentIds: string[]): Promise<Set<string>>;
}

const listInput = z
  .object({ parentUid: z.string().trim().min(1).max(128).regex(/^[^/]+$/).optional() })
  .strict();

export async function listParentChildren(
  store: ParentChildrenStore,
  parentId: string,
  nowMs: number,
): Promise<ParentChildSummary[]> {
  const childIds = (await store.approvedChildIds(parentId)).slice(0, 20);
  const students = await Promise.all(childIds.map(async (id) => ({ id, data: await store.readStudent(id) })));
  const visible = students.filter(
    (entry): entry is { id: string; data: NonNullable<typeof entry.data> } =>
      entry.data !== null && entry.data.role === "student" && entry.data.accountStatus !== "deleted",
  );
  const schoolIds = [...new Set(visible.map((entry) => entry.data.establishmentId).filter(Boolean))];
  const [names, offers, phones] = await Promise.all([
    store.establishmentNames(schoolIds),
    store.activeOfferIds(schoolIds),
    store.phoneAccess(visible.map((entry) => entry.id)),
  ]);

  return Promise.all(
    visible.map(async ({ id, data }) => {
      const [issuedAt, subscription] = await Promise.all([
        store.accessCodeIssuedAt(id),
        resolveSubscription(store, parentId, id, data.establishmentId, nowMs),
      ]);
      return {
        studentId: id,
        firstName: data.firstName,
        lastName: data.lastName,
        classLevel: data.classLevel,
        series: data.series,
        establishmentId: data.establishmentId,
        establishmentName: names.get(data.establishmentId) ?? "",
        access: {
          ownPhone: phones.has(id),
          accessCode: issuedAt !== undefined,
          accessCodeIssuedAt: issuedAt ?? null,
        },
        subscription,
        offerAvailable: offers.has(data.establishmentId),
      } satisfies ParentChildSummary;
    }),
  );
}

async function resolveSubscription(
  store: ParentChildrenStore,
  parentId: string,
  studentId: string,
  establishmentId: string,
  nowMs: number,
): Promise<ParentChildSummary["subscription"]> {
  const none = { status: "inactive" as const, endsAt: null, offerId: null, paidBy: null };
  if (!establishmentId) return none;
  // Même résolution que la Réserve d'étude : tout parent lié et payant pour
  // l'école de l'enfant le couvre ; la fenêtre la plus lointaine l'emporte.
  const guardians = await store.approvedGuardianIds(studentId);
  let best: { endMs: number; offerId: string; payer: string } | null = null;
  for (const guardian of guardians) {
    const parsed = parseEntitlementDocument(
      await store.entitlement(guardian, establishmentId),
      establishmentId,
      nowMs,
    );
    if (!parsed?.active) continue;
    if (!best || parsed.windowEndMs > best.endMs || (parsed.windowEndMs === best.endMs && guardian === parentId)) {
      best = { endMs: parsed.windowEndMs, offerId: parsed.offerId, payer: guardian };
    }
  }
  if (!best) return none;
  return {
    status: "active",
    endsAt: new Date(best.endMs).toISOString(),
    offerId: best.offerId,
    paidBy: best.payer === parentId ? "you" : "another_guardian",
  };
}

export function createListParentChildrenHandler(
  store: ParentChildrenStore = new FirestoreParentChildrenStore(),
  now: () => number = () => Date.now(),
) {
  return async (request: CallableRequest<unknown>): Promise<{ children: ParentChildSummary[] }> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    const parsed = listInput.safeParse(request.data ?? {});
    if (!parsed.success) throw new HttpsError("invalid-argument", "Invalid request payload.");
    const role = await store.readRole(uid);
    let parentId = uid;
    if (parsed.data.parentUid && parsed.data.parentUid !== uid) {
      // Prévisualisation d'un parent réservée à la super-administration.
      if (role !== "superAdmin" && role !== "super_admin") {
        throw new HttpsError("permission-denied", "Only a parent can list their children.");
      }
      parentId = parsed.data.parentUid;
    } else if (role !== "parent") {
      throw new HttpsError("permission-denied", "Only a parent can list their children.");
    }
    return { children: await listParentChildren(store, parentId, now()) };
  };
}

export class FirestoreParentChildrenStore implements ParentChildrenStore {
  constructor(
    private readonly firestore: Firestore = db,
    private readonly auth: () => Auth = () => getAuth(),
  ) {}

  async readRole(uid: string): Promise<string> {
    const snapshot = await this.firestore.collection("users").doc(uid).get();
    const data = snapshot.data();
    if (data?.accountStatus === "suspended" || data?.accountStatus === "deleted") return "";
    return text(data?.role);
  }

  async approvedChildIds(parentId: string): Promise<string[]> {
    const links = await this.firestore.collection("children_links").where("parentId", "==", parentId).limit(40).get();
    return links.docs
      .filter((link) => link.data().status === "approved")
      .map((link) => text(link.data().studentId))
      .filter(Boolean);
  }

  async approvedGuardianIds(studentId: string): Promise<string[]> {
    const links = await this.firestore
      .collection("children_links")
      .where("studentId", "==", studentId)
      .where("status", "==", "approved")
      .limit(10)
      .get();
    return links.docs.map((link) => text(link.data().parentId)).filter(Boolean);
  }

  async readStudent(studentId: string) {
    const [user, profile] = await Promise.all([
      this.firestore.collection("users").doc(studentId).get(),
      this.firestore.collection("student_profiles").doc(studentId).get(),
    ]);
    if (!user.exists) return null;
    const userData = user.data() ?? {};
    const profileData = profile.data() ?? {};
    const pick = (key: string) => text(userData[key]) || text(profileData[key]);
    return {
      role: text(userData.role),
      accountStatus: text(userData.accountStatus) || "active",
      firstName: pick("firstName"),
      lastName: pick("lastName"),
      classLevel: pick("classLevel"),
      series: pick("series") || null,
      establishmentId: pick("establishmentId"),
    };
  }

  async establishmentNames(ids: string[]): Promise<Map<string, string>> {
    if (ids.length === 0) return new Map();
    const snapshots = await this.firestore.getAll(
      ...ids.map((id) => this.firestore.collection("establishments").doc(id)),
    );
    return new Map(snapshots.map((snapshot) => [snapshot.id, text(snapshot.data()?.name)]));
  }

  async activeOfferIds(establishmentIds: string[]): Promise<Set<string>> {
    if (establishmentIds.length === 0) return new Set();
    const snapshots = await this.firestore.getAll(
      ...establishmentIds.map((id) => this.firestore.collection("mobile_money_offers").doc(id)),
    );
    return new Set(
      snapshots
        .filter((snapshot) => snapshot.data()?.status === "active" && snapshot.data()?.establishmentId === snapshot.id)
        .map((snapshot) => snapshot.id),
    );
  }

  async entitlement(parentId: string, establishmentId: string) {
    const snapshot = await this.firestore.collection("entitlements").doc(`${parentId}_${establishmentId}`).get();
    return snapshot.data();
  }

  async accessCodeIssuedAt(studentId: string): Promise<string | null | undefined> {
    const snapshot = await this.firestore.collection("student_access_credentials").doc(studentId).get();
    const data = snapshot.data();
    if (!data || data.status !== "active" || !text(data.lookupKey)) return undefined;
    return typeof data.issuedAtMs === "number" ? new Date(data.issuedAtMs).toISOString() : null;
  }

  async phoneAccess(studentIds: string[]): Promise<Set<string>> {
    if (studentIds.length === 0) return new Set();
    const result = await this.auth().getUsers(studentIds.map((uid) => ({ uid })));
    return new Set(result.users.filter((user) => Boolean(user.phoneNumber)).map((user) => user.uid));
  }
}

function text(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}
