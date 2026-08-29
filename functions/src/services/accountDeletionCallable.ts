import type { CallableRequest } from "firebase-functions/v2/https";
import { HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";

import { db } from "../config/firebase";

export interface AccountDeletionRequestStore {
  request(uid: string): Promise<void>;
}

export class FirestoreAccountDeletionRequestStore
  implements AccountDeletionRequestStore
{
  async request(uid: string): Promise<void> {
    await db.collection("account_deletion_requests").doc(uid).set(
      {
        uid,
        status: "pending",
        requestedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
}

export function createRequestAccountDeletionHandler(
  store: AccountDeletionRequestStore =
    new FirestoreAccountDeletionRequestStore(),
) {
  return async (request: CallableRequest<unknown>) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    }
    await store.request(uid);
    return { status: "pending" as const };
  };
}

export const requestAccountDeletionHandler =
  createRequestAccountDeletionHandler();
