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
      const role = normalizedString(user.get("role"));
      return roles === null || roles.has(role);
    });
    await writePage(recipients);
    recipientCount += recipients.length;
    lastDocument = page.docs.at(-1);
    if (page.size < announcementFanoutPageSize) break;
  } while (lastDocument);
  return recipientCount;
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
      (user) => user.exists && normalizedString(user.get("role")) === "student",
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
