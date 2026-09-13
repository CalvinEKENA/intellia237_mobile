import type { Bucket } from "@google-cloud/storage";
import type {
  Firestore,
  DocumentData,
  DocumentReference,
  DocumentSnapshot,
} from "firebase-admin/firestore";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { bucket, db } from "../config/firebase";
import { audienceAllows, staffCanWrite } from "./contentAudience";
import { inspectMp4 } from "./mp4Validation";

export function parseAssetPath(path: unknown) {
  if (typeof path !== "string") throw new HttpsError("invalid-argument", "Chemin mÃ©dia requis.");
  const p = path.split("/");
  if (p.length !== 7 || p[0] !== "educational_assets" || p.slice(1).some(s => !s.trim() || s === "." || s === ".." || /[\\\x00-\x1f]/.test(s))) {
    throw new HttpsError("invalid-argument", "Chemin mÃ©dia invalide.");
  }
  return { path, scopeId: p[1], classLevel: p[2], subjectId: p[3], lessonId: p[4], assetId: p[5], fileName: p[6] };
}

export async function validateLessonMedia(lesson: DocumentData, store: Bucket = bucket) {
  const validated: DocumentData[] = [];
  for (const block of lesson.contentBlocks || []) {
    if (block.type !== "media") continue;
    if (!["image", "audio", "video", "pdf"].includes(block.mediaType)) throw new HttpsError("invalid-argument", "Type de mÃ©dia inconnu.");
    const asset = parseAssetPath(block.storagePath);
    const scope = lesson.scope?.type === "establishment" ? lesson.scope.establishmentId : lesson.establishmentId || "global";
    if (asset.scopeId !== scope || asset.classLevel !== lesson.classLevel || asset.subjectId !== lesson.subjectId || asset.lessonId !== lesson.id) {
      throw new HttpsError("permission-denied", "Le mÃ©dia ne correspond pas Ã  cette leÃ§on et Ã  son pÃ©rimÃ¨tre.");
    }
    const file = store.file(asset.path);
    let metadata;
    try { [metadata] = await file.getMetadata(); }
    catch { throw new HttpsError("failed-precondition", "Fichier absent ou tÃ©lÃ©versement inachevÃ©. RÃ©importez le mÃ©dia."); }
    const limits: Record<string, number> = { image: 10, audio: 50, video: 150, pdf: 25 };
    const types: Record<string, string[]> = { image: ["image/jpeg", "image/png", "image/webp"], audio: ["audio/mpeg", "audio/mp4", "audio/m4a", "audio/aac"], video: ["video/mp4"], pdf: ["application/pdf"] };
    const size = Number(metadata.size);
    if (!Number.isFinite(size) || size <= 0 || size > limits[block.mediaType] * 1024 * 1024 || !types[block.mediaType].includes(metadata.contentType || "") || (block.mimeType && block.mimeType !== metadata.contentType)) {
      throw new HttpsError("failed-precondition", "Format ou taille du mÃ©dia non conforme.");
    }
    let durationSeconds = block.durationSeconds;
    if (block.mediaType === "video") {
      if (block.mimeType !== "video/mp4" || !asset.fileName.toLowerCase().endsWith(".mp4")) throw new HttpsError("failed-precondition", "Une vidÃ©o MP4 est requise.");
      try {
        const [bytes] = await store.file(asset.path, { generation: metadata.generation }).download();
        durationSeconds = inspectMp4(bytes).durationSeconds;
      } catch { throw new HttpsError("failed-precondition", "VidÃ©o illisible : exportez un MP4 H.264 avec audio AAC puis rÃ©importez-le."); }
    }
    // Never retain a permanent Firebase bearer URL in public content.
    delete block.downloadUrl;
    block.fileSizeBytes = size; block.mimeType = metadata.contentType;
    if (durationSeconds != null) block.durationSeconds = durationSeconds;
    validated.push({ ...asset, generation: String(metadata.generation), size, mimeType: metadata.contentType });
  }
  return validated;
}

export async function publishedLessonAllows(firestore: Firestore, path: string, actor: DocumentData, profile: DocumentData, read: (ref: DocumentReference) => Promise<DocumentSnapshot> = ref => ref.get()) {
  if (!/^classes\/[^/]+\/subjects\/[^/]+\/chapters\/[^/]+\/lessons\/[^/]+$/.test(path)) return false;
  const ref = firestore.doc(path);
  const [lesson, chapter, subject] = await Promise.all([read(ref), read(ref.parent.parent!), read(ref.parent.parent!.parent.parent!)]);
  const level = path.split("/")[1];
  return lesson.data()?.status === "published" && subject.data()?.status === "published" &&
    [lesson, chapter, subject].every(d => {
      if (!d.exists || d.data()!.deleting) return false;
      const data = d === chapter && d.data()!.audience === undefined && subject.data()?.audience
        ? { ...d.data(), audience: subject.data()!.audience } : d.data()!;
      return audienceAllows(data, actor, profile, level);
    });
}

/** Authorization ledger, not a second content collection. The canonical media
 * remains the lesson MediaBlock; every student URL resolves its current policy. */
export function createEducationalMediaHandler(firestore: Firestore = db, store: Bucket = bucket) {
  return async (request: CallableRequest) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Connexion requise.");
    const asset = parseAssetPath(request.data?.storagePath);
    const [actorDoc, profileDoc] = await Promise.all([firestore.doc(`users/${request.auth.uid}`).get(), firestore.doc(`student_profiles/${request.auth.uid}`).get()]);
    const actor = actorDoc.data() || {}, profile = profileDoc.data() || {};
    const staff = staffCanWrite(actor, { scope: { type: asset.scopeId === "global" ? "global" : "establishment", establishmentId: asset.scopeId } });
    const ledger = firestore.doc(`educational_asset_access/${asset.assetId}`);
    const entry = (await ledger.get()).data();
    if (entry && entry.path !== asset.path) throw new HttpsError("permission-denied", "RÃ©fÃ©rence mÃ©dia incompatible.");
    if (request.data?.action === "delete") {
      if (!staff) throw new HttpsError("permission-denied", "Suppression non autorisÃ©e.");
      await firestore.runTransaction(async tx => {
        const current = (await tx.get(ledger)).data();
        if (current?.path && current.path !== asset.path) throw new HttpsError("permission-denied", "RÃ©fÃ©rence mÃ©dia incompatible.");
        if (current?.lessonPath) {
          const lesson = (await tx.get(firestore.doc(current.lessonPath))).data();
          if (lesson?.contentBlocks?.some((b: DocumentData) => b.storagePath === asset.path)) throw new HttpsError("failed-precondition", "Enregistrez le retrait du mÃ©dia de la leÃ§on avant de supprimer le fichier.");
        }
        tx.set(ledger, { ...asset, state: "deleting" }, { merge: true });
      });
      await store.file(asset.path).delete({ ignoreNotFound: true });
      await ledger.set({ state: "deleted" }, { merge: true });
      return { deleted: true };
    }
    if (entry && entry.state !== "ready") throw new HttpsError("not-found", "MÃ©dia indisponible.");
    if (!staff && (!entry?.lessonPath || !await publishedLessonAllows(firestore, entry.lessonPath, actor, profile))) throw new HttpsError("permission-denied", "Ce mÃ©dia ne fait pas partie de votre catalogue publiÃ©.");
    if (!staff) {
      const lesson = (await firestore.doc(entry!.lessonPath).get()).data();
      if (!lesson?.contentBlocks?.some((b: DocumentData) => b.storagePath === asset.path)) throw new HttpsError("not-found", "MÃ©dia retirÃ© de cette leÃ§on.");
    }
    try {
      const file = store.file(asset.path, entry?.generation ? { generation: entry.generation } : undefined);
      const [exists] = await file.exists();
      if (!exists) throw new Error("missing");
      const expiresAt = Date.now() + 15 * 60 * 1000;
      const [url] = await file.getSignedUrl({ version: "v4", action: "read", expires: expiresAt });
      return { url, expiresAt };
    } catch { throw new HttpsError("unavailable", "Le mÃ©dia est indisponible. RÃ©essayez dans quelques instants."); }
  };
}
