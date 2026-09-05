import { logger } from "firebase-functions";
import type { FirestoreEvent, QueryDocumentSnapshot } from "firebase-functions/v2/firestore";

import { db, messaging } from "../config/firebase";

type NotificationDocument = {
  userId?: unknown;
  title?: unknown;
  body?: unknown;
  route?: unknown;
  type?: unknown;
};

const invalidTokenCodes = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);

/**
 * Delivers a server-created inbox item to every registered device.
 * The Firestore document remains the durable source of truth when a device is
 * offline or the operating system delays the push.
 */
export async function deliverNotificationPushHandler(
  event: FirestoreEvent<QueryDocumentSnapshot | undefined>,
): Promise<void> {
  const snapshot = event.data;
  if (!snapshot) return;
  const data = snapshot.data() as NotificationDocument;
  const userId = typeof data.userId === "string" ? data.userId.trim() : "";
  const title = typeof data.title === "string" ? data.title.trim() : "";
  const body = typeof data.body === "string" ? data.body.trim() : "";
  if (!userId || !title || !body) {
    logger.error("Notification document is incomplete.", {
      notificationId: snapshot.id,
    });
    await snapshot.ref.set(
      { deliveryState: "invalid", deliveryUpdatedAt: new Date() },
      { merge: true },
    );
    return;
  }

  const shouldSend = await db.runTransaction(async (transaction) => {
    const current = await transaction.get(snapshot.ref);
    if (current.get("deliveryEventId") === event.id) return false;
    transaction.set(
      snapshot.ref,
      {
        deliveryEventId: event.id,
        deliveryState: "sending",
        deliveryUpdatedAt: new Date(),
      },
      { merge: true },
    );
    return true;
  });
  if (!shouldSend) return;

  const devices = await db
    .collection("notification_devices")
    .where("userId", "==", userId)
    .get();
  const deviceDocs = devices.docs.filter((doc) => {
    const token = doc.get("token");
    return typeof token === "string" && token.length > 0;
  });
  if (deviceDocs.length === 0) {
    await snapshot.ref.set(
      {
        deliveryState: "inbox_only",
        deliverySuccessCount: 0,
        deliveryFailureCount: 0,
        deliveryUpdatedAt: new Date(),
      },
      { merge: true },
    );
    return;
  }

  let successCount = 0;
  let failureCount = 0;
  for (let offset = 0; offset < deviceDocs.length; offset += 500) {
    const chunk = deviceDocs.slice(offset, offset + 500);
    const result = await messaging.sendEachForMulticast({
      tokens: chunk.map((doc) => doc.get("token") as string),
      notification: { title, body },
      data: {
        notificationId: snapshot.id,
        route: typeof data.route === "string" ? data.route : "/notifications",
        type: typeof data.type === "string" ? data.type : "information",
      },
      android: {
        priority: "high",
        notification: { channelId: "intellia_updates" },
      },
      apns: { payload: { aps: { sound: "default" } } },
    });
    successCount += result.successCount;
    failureCount += result.failureCount;

    const removals = result.responses.flatMap((response, index) => {
      const code = response.error?.code;
      return code != null && invalidTokenCodes.has(code)
        ? [chunk[index].ref.delete()]
        : [];
    });
    await Promise.all(removals);
  }

  await snapshot.ref.set(
    {
      deliveryState: failureCount === 0 ? "sent" : "partial",
      deliverySuccessCount: successCount,
      deliveryFailureCount: failureCount,
      deliveryUpdatedAt: new Date(),
    },
    { merge: true },
  );
}
