import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";

import { getEnv } from "./env";

export function ensureFirebaseApp(): void {
  if (getApps().length > 0) {
    return;
  }

  const env = getEnv();
  initializeApp({
    storageBucket: env.APP_STORAGE_BUCKET
  });
}

ensureFirebaseApp();

export const db = getFirestore();
export const bucket = getStorage().bucket(getEnv().APP_STORAGE_BUCKET);
