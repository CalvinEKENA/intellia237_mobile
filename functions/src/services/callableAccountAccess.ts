import { HttpsError, onCall, type CallableRequest, type HttpsOptions } from "firebase-functions/v2/https";
import { db } from "../config/firebase";

export function assertAccountAccess(status: unknown): void {
  if (status === "suspended" || status === "deleted") {
    throw new HttpsError("permission-denied", "This account is disabled.");
  }
}

// Firebase ID tokens can outlive a suspension. Check the current profile
// before every callable, even if a caller retains an otherwise valid token.
export function onCallWithAccountAccess<T, R>(
  options: HttpsOptions,
  handler: (request: CallableRequest<T>) => R | Promise<R>,
) {
  return onCall<T>(options, async (request) => {
    if (request.auth?.uid) {
      const profile = await db.collection("users").doc(request.auth.uid).get();
      assertAccountAccess(profile.data()?.accountStatus);
    }
    return handler(request);
  });
}
