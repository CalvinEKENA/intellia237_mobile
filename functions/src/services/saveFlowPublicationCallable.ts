import { FieldValue, type Firestore, type DocumentData } from "firebase-admin/firestore";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { z } from "zod";
import { db } from "../config/firebase";
import { contentAudienceSchema, staffCanWrite } from "./contentAudience";
import { parseAssetPath } from "./educationalMedia";

const schema = z.object({ id: z.string().max(160).regex(/^[^/]*$/).default(""), content: z.object({
  type: z.enum(["notion", "question", "quiz", "image", "infographic", "audio", "shortVideo", "interactiveNative"]),
  title: z.string().trim().min(1).max(500), hook: z.string().max(6000).default(""),
  subjectId: z.string().min(1).max(160), classLevels: z.array(z.string().min(1).max(100)).min(1).max(64),
  status: z.enum(["draft", "inReview", "approved", "scheduled", "published", "archived"]),
  scope: z.object({ type: z.enum(["global", "establishment"]), establishmentId: z.string().optional() }),
  audience: contentAudienceSchema.optional(), payload: z.record(z.unknown()).default({}),
  ref: z.object({ lessonId: z.string().nullable().optional(), storagePath: z.string().nullable().optional() }).passthrough(),
}).passthrough() });
export function createSaveFlowPublicationHandler(firestore: Firestore = db) {
  return async (request: CallableRequest) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Connexion requise.");
    const parsed = schema.safeParse(request.data);
    if (!parsed.success) throw new HttpsError("invalid-argument", "Publication Parcours invalide.");
    const data: DocumentData = parsed.data.content;
    const ref = parsed.data.id ? firestore.doc(`flow_items/${parsed.data.id}`) : firestore.collection("flow_items").doc();
    return firestore.runTransaction(async tx => {
      const [user, current] = await Promise.all([tx.get(firestore.doc(`users/${request.auth!.uid}`)), tx.get(ref)]);
      const actor = user.data() || {};
      if (!staffCanWrite(actor, data) || (current.exists && !staffCanWrite(actor, current.data()!))) throw new HttpsError("permission-denied", "Ce contenu ne relève pas de votre périmètre.");
      if (current.data()?.managedBy === "lessonPublication") throw new HttpsError("failed-precondition", "Modifiez cette carte depuis sa leçon source.");
      const publishing = ["published", "scheduled"].includes(data.status);
      if (publishing && data.type === "shortVideo") {
        const asset = parseAssetPath(data.ref?.storagePath);
        const ledger = (await tx.get(firestore.doc(`educational_asset_access/${asset.assetId}`))).data();
        if (!ledger || ledger.path !== asset.path || ledger.state !== "ready") throw new HttpsError("failed-precondition", "Importez et enregistrez d’abord la vidéo dans sa leçon.");
        const lesson = (await tx.get(firestore.doc(ledger.lessonPath))).data();
        if (lesson?.status !== "published" || !lesson.contentBlocks?.some((b: DocumentData) => b.storagePath === asset.path)) throw new HttpsError("failed-precondition", "La leçon vidéo doit être publiée avant la carte Parcours.");
        data.sourceLessonPath = ledger.lessonPath;
        data.payload.fileSizeBytes = ledger.size;
      }
      if (publishing) {
        const p = data.payload;
        const valid = data.type === "quiz" ? p.question?.trim() && Array.isArray(p.options) && p.options.length >= 2 && Number.isInteger(p.correctIndex) && p.correctIndex >= 0 && p.correctIndex < p.options.length
          : data.type === "question" ? p.question?.trim() && p.answer?.trim()
          : ["notion", "infographic"].includes(data.type) ? p.insight?.trim() || p.points?.length
          : data.type === "interactiveNative" ? p.componentKey && p.summary
          : !!data.ref?.storagePath;
        if (!valid) throw new HttpsError("failed-precondition", "Complétez le contenu avant publication.");
      }
      tx.set(ref, { ...data, createdBy: current.data()?.createdBy || request.auth!.uid,
        createdAt: current.data()?.createdAt || new Date().toISOString(), updatedAt: new Date().toISOString(),
        publishedAt: publishing ? current.data()?.publishedAt || new Date().toISOString() : current.data()?.publishedAt || null,
      }, { merge: true });
      tx.set(firestore.doc("content_catalog_state/revision"), { updatedAt: FieldValue.serverTimestamp() });
      return { id: ref.id };
    });
  };
}
