import {
  FieldPath,
  FieldValue,
  type DocumentSnapshot,
} from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import type {
  FirestoreEvent,
  QueryDocumentSnapshot,
} from "firebase-functions/v2/firestore";

import { db } from "../config/firebase";
import { hasUserRole, resolveUserRoles } from "../auth/userRoles";

type AnnouncementDocument = {
  title?: unknown;
  message?: unknown;
  audience?: unknown;
  establishmentId?: unknown;
};

export const announcementFanoutPageSize = 400;

const audienceRoles: Readonly<Record<string, ReadonlySet<string> | null>> = {
  "Tout l'établissement": null,
  "Élèves": new Set(["student"]),
  "Parents": new Set(["parent"]),
  "Enseignants": new Set(["teacher"]),
  "Administration": new Set(["admin", "superAdmin", "super_admin"]),
  "Classe": new Set(["student"]),
};

/**
 * Turns an official school announcement into one durable inbox item per user.
 * Deterministic document ids make retries idempotent, while the downstream
 * notification trigger handles best-effort push delivery independently.
 */
export async function fanoutAnnouncementHandler(
  event: FirestoreEvent<QueryDocumentSnapshot | undefined>,
): Promise<void> {
  const snapshot = event.data;
  if (!snapshot) return;

  const data = snapshot.data() as AnnouncementDocument;
  const title = normalizedString(data.title);
  const body = normalizedString(data.message);
  const audience = normalizedString(data.audience);
  const establishmentId = normalizedString(data.establishmentId);
  const roles = audienceRoles[audience];
  const createdAt = snapshot.createTime;

  if (!title || !body || !establishmentId || roles === undefined) {
    logger.error("Announcement cannot be converted to notifications.", {
      announcementId: snapshot.id,
      audience,
      hasEstablishment: Boolean(establishmentId),
    });
    await snapshot.ref.set(
      {
        notificationFanoutState: "invalid",
        notificationFanoutUpdatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return;
  }

  const writePage = (recipients: DocumentSnapshot[]) =>
    writeNotificationPage({
      announcementId: snapshot.id,
      establishmentId,
      title,
      body,
      recipients,
      createdAt,
    });
  const recipientCount = audience === "Classe"
    ? await fanoutClassRecipients(snapshot, establishmentId, writePage)
    : await fanoutEstablishmentRecipients(establishmentId, roles, writePage);

  await snapshot.ref.set(
    {
      notificationFanoutState: "complete",
      notificationRecipientCount: recipientCount,
      notificationFanoutUpdatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  logger.info("Announcement notification fanout completed.", {
    announcementId: snapshot.id,
    recipientCount,
  });
}

async function fanoutEstablishmentRecipients(
  establishmentId: string,
  roles: ReadonlySet<string> | null,
  writePage: (recipients: DocumentSnapshot[]) => Promise<void>,
): Promise<number> {
  // Un parent n'appartient pas à UNE école : il suit l'école de chacun de ses
  // enfants. Les parents sont donc atteints par leurs liens approuvés avec les
  // élèves de cette école, en plus d'un éventuel rattachement direct hérité.
  const reachParents = roles === null || roles.has("parent");
  const reached = new Set<string>();
  let lastDocument: DocumentSnapshot | undefined;
  let recipientCount = 0;
  do {
    let query = db
      .collection("users")
      .where("establishmentId", "==", establishmentId)
      .orderBy(FieldPath.documentId())
      .limit(announcementFanoutPageSize);
    if (lastDocument) query = query.startAfter(lastDocument);
    const page = await query.get();
    const recipients = page.docs.filter((user) => {
      // Un compte à plusieurs espaces reçoit l'annonce si l'un d'eux est visé.
      const accountRoles = resolveUserRoles(user.data());
      return (roles === null || [...accountRoles].some((role) => roles.has(role))) &&
        !reached.has(user.id);
    });
    const guardians = reachParents
      ? await linkedGuardians(
        page.docs
          .filter((user) => hasUserRole(user.data(), "student"))
          .map((user) => user.id),
      )
      : [];
    const all = [...recipients, ...guardians].filter((user) => {
      if (reached.has(user.id)) return false;
      reached.add(user.id);
      return true;
    });
    await writePage(all);
    recipientCount += all.length;
    lastDocument = page.docs.at(-1);
    if (page.size < announcementFanoutPageSize) break;
  } while (lastDocument);
  return recipientCount;
}

/** Comptes parents actifs liés (lien approuvé) à au moins un de ces élèves. */
export async function linkedGuardians(studentIds: string[]): Promise<DocumentSnapshot[]> {
  const parentIds = new Set<string>();
  // Firestore limite `in` à 30 valeurs.
  for (let offset = 0; offset < studentIds.length; offset += 30) {
    // Filtre de statut en mémoire : aucun index composite à déployer.
    const links = await db
      .collection("children_links")
      .where("studentId", "in", studentIds.slice(offset, offset + 30))
      .get();
    for (const link of links.docs) {
      if (normalizedString(link.get("status")) !== "approved") continue;
      const parentId = normalizedString(link.get("parentId"));
      if (parentId) parentIds.add(parentId);
    }
  }
  if (parentIds.size === 0) return [];
  const parents = await db.getAll(
    ...[...parentIds].map((id) => db.collection("users").doc(id)),
  );
  return parents.filter((parent) =>
    parent.exists &&
    hasUserRole(parent.data(), "parent") &&
    !["suspended", "deleted"].includes(normalizedString(parent.get("accountStatus"))),
  );
}

async function fanoutClassRecipients(
  announcement: QueryDocumentSnapshot,
  establishmentId: string,
  writePage: (recipients: DocumentSnapshot[]) => Promise<void>,
): Promise<number> {
  const classId = normalizedString(announcement.get("classId"));
  if (!classId) return 0;
  const classSnapshot = await db.collection("classes").doc(classId).get();
  if (
    !classSnapshot.exists ||
    normalizedString(classSnapshot.get("establishmentId")) !== establishmentId
  ) {
    return 0;
  }
  const rawIds = classSnapshot.get("studentIds");
  const ids = Array.isArray(rawIds)
    ? [...new Set(rawIds.filter((id): id is string => typeof id === "string" && id.length > 0))]
    : [];
  let recipientCount = 0;
  for (let offset = 0; offset < ids.length; offset += announcementFanoutPageSize) {
    const documents = await db.getAll(
      ...ids
        .slice(offset, offset + announcementFanoutPageSize)
        .map((id) => db.collection("users").doc(id)),
    );
    const recipients = documents.filter(
      (user) => user.exists && hasUserRole(user.data(), "student"),
    );
    await writePage(recipients);
    recipientCount += recipients.length;
  }
  return recipientCount;
}

async function writeNotificationPage({
  announcementId,
  establishmentId,
  title,
  body,
  recipients,
  createdAt,
}: {
  announcementId: string;
  establishmentId: string;
  title: string;
  body: string;
  recipients: DocumentSnapshot[];
  createdAt: unknown;
}): Promise<void> {
  // Une page d'élèves peut entraîner plus de parents que d'élèves : les
  // écritures sont découpées sous le plafond de 500 opérations par lot.
  for (let offset = 0; offset < recipients.length; offset += announcementFanoutPageSize) {
    await writeNotificationBatch({
      announcementId,
      establishmentId,
      title,
      body,
      recipients: recipients.slice(offset, offset + announcementFanoutPageSize),
      createdAt,
    });
  }
}

async function writeNotificationBatch({
  announcementId,
  establishmentId,
  title,
  body,
  recipients,
  createdAt,
}: {
  announcementId: string;
  establishmentId: string;
  title: string;
  body: string;
  recipients: DocumentSnapshot[];
  createdAt: unknown;
}): Promise<void> {
  if (recipients.length === 0) return;
  const batch = db.batch();
  for (const recipient of recipients) {
    const notification = db
      .collection("notifications")
      .doc(announcementNotificationDocumentId(announcementId, recipient.id));
    batch.set(
      notification,
      buildAnnouncementNotificationFields({
        announcementId,
        establishmentId,
        recipientId: recipient.id,
        title,
        body,
        createdAt,
      }),
      // Retries update source content but deliberately omit readAt, so an
      // already-read inbox item can never become unread again.
      { merge: true },
    );
  }
  await batch.commit();
}

export function announcementNotificationDocumentId(
  announcementId: string,
  recipientId: string,
): string {
  return `announcement_${announcementId}_${recipientId}`;
}

export function buildAnnouncementNotificationFields({
  announcementId,
  establishmentId,
  recipientId,
  title,
  body,
  createdAt,
}: {
  announcementId: string;
  establishmentId: string;
  recipientId: string;
  title: string;
  body: string;
  createdAt: unknown;
}): Record<string, unknown> {
  return {
    userId: recipientId,
    title,
    body,
    type: "announcement",
    route: "/notifications",
    sourceId: announcementId,
    establishmentId,
    createdAt,
  };
}

function normalizedString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}
