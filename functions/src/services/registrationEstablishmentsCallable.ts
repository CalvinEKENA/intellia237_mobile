import type { CallableRequest } from "firebase-functions/v2/https";
import type { Firestore } from "firebase-admin/firestore";
import { db } from "../config/firebase";

// Only public labels leave the server. The school documents also contain
// management information and must never become publicly readable.
export function createListRegistrationEstablishmentsHandler(firestore: Firestore = db) {
  return async (_request: CallableRequest) => {
    const snapshot = await firestore.collection("establishments")
      .where("status", "==", "active").select("name", "city", "region", "createdBy").get();
    const creators = [...new Set(snapshot.docs.map(d => d.data().createdBy)
      .filter((uid): uid is string => typeof uid === "string" && !!uid && !uid.includes("/")))];
    const authorDocs = creators.length ? await firestore.getAll(...creators.map(uid => firestore.doc(`users/${uid}`))) : [];
    const trusted = new Set(authorDocs.filter(d => ["superAdmin", "super_admin"].includes(d.data()?.role)).map(d => d.id));
    return { establishments: snapshot.docs.filter(d => trusted.has(d.data().createdBy) && typeof d.data().name === "string")
      .map(d => ({ id: d.id, name: d.data().name.trim(), city: d.data().city || "", region: d.data().region || "" }))
      .sort((a, b) => a.name.localeCompare(b.name, "fr")) };
  };
}
export const listRegistrationEstablishmentsHandler = createListRegistrationEstablishmentsHandler();
