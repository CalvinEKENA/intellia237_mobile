import { FieldValue, type Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

import { db } from "../config/firebase";
import {
  crossedThreshold,
  remainingPercent,
  safeUnits,
  sanitizeThreshold,
  type ReserveThreshold,
} from "./studyReserve";
import {
  ensureCurrentStudyReserveCycle,
  FirestoreStudyReserveProvisioningStore,
  type StudyReserveProvisioningStore,
} from "./studyReserveProvisioning";

/**
 * Couche de consommation **unique et autoritaire** de la Réserve d'étude.
 *
 * Toute opération facturable (tuteur/IA) passe par ici — aucune logique de
 * comptabilité dupliquée ailleurs. Sémantique réserve / commit / release :
 * on réserve un montant provisoire (sécurité de concurrence), on exécute le
 * fournisseur, puis on comptabilise l'usage **réel** (jamais une estimation
 * permanente si le réel est connu) de façon idempotente, ou on relâche la
 * réservation en cas d'échec. Deux requêtes simultanées ne peuvent pas
 * surconsommer : la réservation est transactionnelle.
 */

/** Durée de vie d'une réservation : une fonction tuée ne bloque pas le cycle. */
export const RESERVE_HOLD_TTL_MS = 5 * 60 * 1000;

/** Estimation provisoire par requête tuteur, remplacée par l'usage réel. */
export const DEFAULT_TUTOR_ESTIMATE_UNITS = 1000;

/** Raison stable renvoyée au client : distingue la réserve vide du quota
 * quotidien, qui partage le code `resource-exhausted`. */
export const STUDY_RESERVE_EXHAUSTED_REASON = "study_reserve_exhausted";

export function studyReserveExhaustedError(): HttpsError {
  return new HttpsError(
    "resource-exhausted",
    "Study reserve is empty for this cycle.",
    { reason: STUDY_RESERVE_EXHAUSTED_REASON },
  );
}

export interface ProviderUsage {
  inputUnits: number;
  outputUnits: number;
  billableUnits: number;
}

export interface ReserveHold {
  configured: boolean; // false = pas de plan → gouverné par le quota quotidien
  reserved: boolean;
}

export interface CommitResult {
  duplicate: boolean;
  thresholdEvent: ReserveThreshold | null;
  cycleId: string;
}

export interface StudyReserveConsumptionStore {
  reserve(params: {
    studentId: string;
    requestId: string;
    estimateUnits: number;
  }): Promise<ReserveHold>;
  commit(params: {
    studentId: string;
    requestId: string;
    provider: string;
    model: string;
    usage: ProviderUsage;
  }): Promise<CommitResult>;
  release(params: { studentId: string; requestId: string }): Promise<void>;
  listLinkedParents(studentId: string): Promise<string[]>;
}

export interface ThresholdNotifier {
  emit(params: {
    studentId: string;
    parentIds: string[];
    cycleId: string;
    threshold: ReserveThreshold;
  }): Promise<void>;
}

interface HoldEntry {
  units: number;
  tsMs: number;
}

function activeHolds(
  raw: unknown,
  now: number,
): Record<string, HoldEntry> {
  const holds: Record<string, HoldEntry> = {};
  if (raw && typeof raw === "object" && !Array.isArray(raw)) {
    for (const [key, value] of Object.entries(raw as Record<string, unknown>)) {
      if (value && typeof value === "object") {
        const entry = value as { units?: unknown; tsMs?: unknown };
        const tsMs = Number(entry.tsMs ?? 0);
        if (now - tsMs <= RESERVE_HOLD_TTL_MS) {
          holds[key] = { units: Number(entry.units ?? 0), tsMs };
        }
      }
    }
  }
  return holds;
}

/**
 * `holds` est toujours réécrit EN ENTIER. Un `set(..., { merge: true })`
 * fusionne les maps clé par clé : une réservation supprimée resterait en base
 * (et compterait jusqu'à l'expiration du TTL) dès qu'une autre est en cours.
 * `mergeFields` remplace exactement les champs listés, document absent compris.
 */
const HOLDS_WRITE = { mergeFields: ["holds", "updatedAt"] };

function heldUnits(holds: Record<string, HoldEntry>): number {
  return Object.values(holds).reduce((sum, h) => sum + Math.max(0, h.units), 0);
}

export class FirestoreStudyReserveConsumptionStore
  implements StudyReserveConsumptionStore {
  constructor(
    private readonly now: () => number = () => Date.now(),
    private readonly firestore: Firestore = db,
  ) {}

  private aggregateRef(studentId: string) {
    return this.firestore.collection("study_reserve").doc(studentId);
  }

  async reserve(params: {
    studentId: string;
    requestId: string;
    estimateUnits: number;
  }): Promise<ReserveHold> {
    const ref = this.aggregateRef(params.studentId);
    const now = this.now();
    return this.firestore.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const data = snap.data();
      const allowance = safeUnits(data?.allowanceInternal);
      // Pas de plan → non configuré : on ne bloque pas, on ne débite pas.
      if (!data || allowance <= 0) {
        return { configured: false, reserved: false };
      }
      const consumed = safeUnits(data.consumed);
      const holds = activeHolds(data.holds, now);
      const remaining = allowance - consumed - heldUnits(holds);
      // La réservation ne doit JAMAIS engager plus que le disponible : on exige
      // que l'estimation tienne dans le restant (holds actifs déduits). Sinon
      // deux requêtes concurrentes pourraient surconsommer.
      if (remaining < params.estimateUnits) {
        throw studyReserveExhaustedError();
      }
      holds[params.requestId] = { units: params.estimateUnits, tsMs: now };
      tx.set(ref, { holds, updatedAt: FieldValue.serverTimestamp() }, HOLDS_WRITE);
      return { configured: true, reserved: true };
    });
  }

  async commit(params: {
    studentId: string;
    requestId: string;
    provider: string;
    model: string;
    usage: ProviderUsage;
  }): Promise<CommitResult> {
    const ref = this.aggregateRef(params.studentId);
    const now = this.now();
    return this.firestore.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const data = snap.data();
      const cycleId = String(data?.cycleId ?? "");
      const ledgerRef = ref.collection("ledger").doc(`${cycleId}__${params.requestId}`);
      const ledgerSnap = await tx.get(ledgerRef);

      const holds = activeHolds(data?.holds, now);
      delete holds[params.requestId]; // la réservation est levée quoi qu'il arrive

      // Idempotence : une requête déjà comptabilisée n'est jamais rejouée.
      if (ledgerSnap.exists) {
        tx.set(ref, { holds, updatedAt: FieldValue.serverTimestamp() }, HOLDS_WRITE);
        return { duplicate: true, thresholdEvent: null, cycleId };
      }

      const allowance = safeUnits(data?.allowanceInternal);
      const consumedBefore = safeUnits(data?.consumed);
      const latestEmitted = sanitizeThreshold(data?.latestThresholdEmitted);
      const previousPercent = remainingPercent(allowance, consumedBefore);
      const consumed = consumedBefore + Math.max(0, params.usage.billableUnits);
      const newPercent = remainingPercent(allowance, consumed);
      const event = crossedThreshold(previousPercent, newPercent, latestEmitted);

      tx.set(ledgerRef, {
        studentId: params.studentId,
        cycleId,
        requestId: params.requestId,
        provider: params.provider,
        model: params.model,
        inputUnits: params.usage.inputUnits,
        outputUnits: params.usage.outputUnits,
        billableUnits: params.usage.billableUnits,
        createdAt: FieldValue.serverTimestamp(),
      });
      tx.set(
        ref,
        {
          consumed,
          holds,
          ...(event !== null ? { latestThresholdEmitted: event } : {}),
          updatedAt: FieldValue.serverTimestamp(),
        },
        {
          mergeFields: [
            "consumed",
            ...HOLDS_WRITE.mergeFields,
            ...(event !== null ? ["latestThresholdEmitted"] : []),
          ],
        },
      );
      return { duplicate: false, thresholdEvent: event, cycleId };
    });
  }

  async release(params: { studentId: string; requestId: string }): Promise<void> {
    const ref = this.aggregateRef(params.studentId);
    const now = this.now();
    await this.firestore.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) return;
      const holds = activeHolds(snap.data()?.holds, now);
      delete holds[params.requestId];
      tx.set(ref, { holds, updatedAt: FieldValue.serverTimestamp() }, HOLDS_WRITE);
    });
  }

  async listLinkedParents(studentId: string): Promise<string[]> {
    const snapshot = await this.firestore
      .collection("children_links")
      .where("studentId", "==", studentId)
      .where("status", "==", "approved")
      .get();
    const parents = new Set<string>();
    for (const doc of snapshot.docs) {
      const parentId = doc.data()?.parentId;
      if (typeof parentId === "string" && parentId.length > 0) {
        parents.add(parentId);
      }
    }
    return [...parents];
  }
}

export type NotificationLocale = "fr" | "en";

/** Texte de notification de seuil, localisé côté serveur (FR/EN), non alarmiste.
 * Le titre/corps sont peuplés pour que le PUSH parte (jamais de doc « invalid »)
 * et dans la langue préférée du destinataire ; l'in-app re-localise par code. */
export function studyReserveNotificationText(
  lang: NotificationLocale,
  threshold: ReserveThreshold,
  audience: "student" | "parent",
): { title: string; body: string } {
  if (lang === "en") {
    const title = "Study reserve";
    const who = audience === "parent" ? "Your child's" : "Your";
    const body =
      threshold <= 0
        ? `${who} study reserve is empty; it renews next cycle. Lessons and quizzes stay available.`
        : threshold <= 5
          ? `${who} study reserve is almost empty (${threshold}%).`
          : threshold <= 25
            ? `${who} study reserve is at ${threshold}%.`
            : `${who} study reserve is at ${threshold}% this cycle.`;
    return { title, body };
  }
  const title = "Réserve d’étude";
  const who = audience === "parent" ? "La réserve d’étude de votre enfant" : "Ta réserve d’étude";
  const body =
    threshold <= 0
      ? `${who} est épuisée ; elle se renouvelle au prochain cycle. Les cours et quiz restent accessibles.`
      : threshold <= 5
        ? `${who} est presque épuisée (${threshold} %).`
        : threshold <= 25
          ? `${who} est à ${threshold} %.`
          : `${who} est à ${threshold} % ce cycle.`;
  return { title, body };
}

/** Identifiant idempotent : une notification par cycle, seuil et destinataire. */
export function thresholdNotificationId(
  cycleId: string,
  threshold: ReserveThreshold,
  recipientId: string,
): string {
  return `study_reserve_${cycleId}_${threshold}_${recipientId}`;
}

/**
 * Champs du document de notification de seuil (hors horodatage).
 * - langue connue → titre/corps localisés FR ou EN : le push peut partir ;
 * - langue inconnue → `deliveryMode: "inbox_only"`, titre/corps vides : aucun
 *   push (ni vide ni deviné), l'in-app re-localise via le code de type.
 * Dans les deux cas, le code de type + le seuil permettent au client d'afficher
 * le texte dans la langue courante de l'application.
 */
export function buildThresholdNotificationFields(params: {
  lang: NotificationLocale | null;
  threshold: ReserveThreshold;
  audience: "student" | "parent";
  studentId: string;
  cycleId: string;
  recipientId: string;
}): Record<string, unknown> {
  const base = {
    userId: params.recipientId,
    type: "study_reserve_threshold",
    data: {
      threshold: params.threshold,
      studentId: params.studentId,
      audience: params.audience,
    },
    route: "/notifications",
    sourceId: `study_reserve_${params.cycleId}_${params.threshold}`,
  };
  if (params.lang === null) {
    return { ...base, deliveryMode: "inbox_only", title: "", body: "" };
  }
  const { title, body } = studyReserveNotificationText(
    params.lang,
    params.threshold,
    params.audience,
  );
  return { ...base, deliveryMode: "push", title, body };
}

/** Notifie un franchissement de seuil, une seule fois par cycle et par
 * destinataire, via l'architecture de notifications existante. Le document est
 * idempotent (id stable) : un rejeu n'en crée jamais un second. */
export class FirestoreThresholdNotifier implements ThresholdNotifier {
  constructor(
    private readonly firestore: Firestore = db,
    private readonly localeReader: (
      uid: string,
    ) => Promise<NotificationLocale | null> = (uid) =>
      readPreferredLocale(firestore, uid),
  ) {}

  async emit(params: {
    studentId: string;
    parentIds: string[];
    cycleId: string;
    threshold: ReserveThreshold;
  }): Promise<void> {
    const recipients = [...new Set([params.studentId, ...params.parentIds])];
    const batch = this.firestore.batch();
    for (const recipient of recipients) {
      const audience = recipient === params.studentId ? "student" : "parent";
      // Langue illisible → null → boîte de réception seule (jamais deviner).
      const lang = await this.localeReader(recipient).catch(() => null);
      batch.set(
        this.firestore
          .collection("notifications")
          .doc(thresholdNotificationId(params.cycleId, params.threshold, recipient)),
        {
          ...buildThresholdNotificationFields({
            lang,
            threshold: params.threshold,
            audience,
            studentId: params.studentId,
            cycleId: params.cycleId,
            recipientId: recipient,
          }),
          createdAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
    await batch.commit();
  }
}

/** Normalise une préférence de langue stockée ; null si absente/inconnue. */
export function normalizePreferredLocale(raw: unknown): NotificationLocale | null {
  if (typeof raw !== "string") return null;
  const value = raw.trim().toLowerCase();
  if (value.startsWith("en") || value.startsWith("angl")) return "en";
  if (value.startsWith("fr")) return "fr";
  return null;
}

/** Langue préférée d'un utilisateur (student_profiles.preferences, users). */
async function readPreferredLocale(
  firestore: Firestore,
  uid: string,
): Promise<NotificationLocale | null> {
  const [profileSnap, userSnap] = await Promise.all([
    firestore.collection("student_profiles").doc(uid).get(),
    firestore.collection("users").doc(uid).get(),
  ]);
  const candidates = [
    profileSnap.data()?.preferences?.interfaceLanguage,
    profileSnap.data()?.interfaceLanguage,
    userSnap.data()?.interfaceLanguage,
    userSnap.data()?.language,
  ];
  for (const candidate of candidates) {
    const locale = normalizePreferredLocale(candidate);
    if (locale !== null) return locale;
  }
  return null;
}

/** Orchestrateur : réserve → exécute → commit(usage réel) / release, et émet
 * la notification de seuil (une fois par cycle). */
export class StudyReserveConsumption {
  constructor(
    private readonly store: StudyReserveConsumptionStore = new FirestoreStudyReserveConsumptionStore(),
    private readonly notifier: ThresholdNotifier = new FirestoreThresholdNotifier(),
    private readonly provisioning: StudyReserveProvisioningStore = new FirestoreStudyReserveProvisioningStore(),
  ) {}

  async run<T>(
    params: {
      studentId: string;
      requestId: string;
      provider: string;
      model: string;
      estimateUnits?: number;
    },
    exec: () => Promise<{ result: T; usage: ProviderUsage }>,
  ): Promise<{ result: T; thresholdEvent: ReserveThreshold | null }> {
    // Provisionne/renouvelle le cycle depuis l'entitlement réel avant toute
    // réservation (jamais de valeur inventée).
    const cycle = await ensureCurrentStudyReserveCycle(
      params.studentId,
      this.provisioning,
    );

    // Réserve « unavailable » (pas d'entitlement actif, plan absent/invalide) :
    // rien à débiter — même comportement qu'un compte jamais configuré ; le
    // quota quotidien reste le garde-fou. Un ancien cycle n'est jamais débité.
    if (cycle === null) {
      const { result } = await exec();
      return { result, thresholdEvent: null };
    }

    const hold = await this.store.reserve({
      studentId: params.studentId,
      requestId: params.requestId,
      estimateUnits: params.estimateUnits ?? DEFAULT_TUTOR_ESTIMATE_UNITS,
    });

    // Non configuré : aucune réserve à débiter (le contenu statique et les
    // autres garde-fous — quota quotidien — restent en vigueur).
    if (!hold.configured) {
      const { result } = await exec();
      return { result, thresholdEvent: null };
    }

    let execution: { result: T; usage: ProviderUsage };
    try {
      execution = await exec();
    } catch (error) {
      await this.store
        .release({ studentId: params.studentId, requestId: params.requestId })
        .catch(() => undefined);
      throw error;
    }

    const commit = await this.store.commit({
      studentId: params.studentId,
      requestId: params.requestId,
      provider: params.provider,
      model: params.model,
      usage: execution.usage,
    });

    if (commit.thresholdEvent !== null && !commit.duplicate) {
      const parents = await this.store
        .listLinkedParents(params.studentId)
        .catch(() => [] as string[]);
      await this.notifier
        .emit({
          studentId: params.studentId,
          parentIds: parents,
          cycleId: commit.cycleId,
          threshold: commit.thresholdEvent,
        })
        .catch(() => undefined);
    }

    return { result: execution.result, thresholdEvent: commit.thresholdEvent };
  }
}

/** Unités facturables réelles à partir de l'usage fournisseur. */
export function billableFromUsage(usage: {
  promptTokenCount?: number;
  candidatesTokenCount?: number;
  totalTokenCount?: number;
}): ProviderUsage {
  const input = Math.max(0, usage.promptTokenCount ?? 0);
  const output = Math.max(0, usage.candidatesTokenCount ?? 0);
  const billable =
    usage.totalTokenCount !== undefined
      ? Math.max(0, usage.totalTokenCount)
      : input + output;
  return { inputUnits: input, outputUnits: output, billableUnits: billable };
}
