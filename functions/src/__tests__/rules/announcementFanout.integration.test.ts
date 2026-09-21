import type { FirestoreEvent, QueryDocumentSnapshot } from "firebase-functions/v2/firestore";
import { beforeEach, describe, expect, it } from "vitest";

import { db } from "../../config/firebase";
import { fanoutAnnouncementHandler } from "../../services/announcementNotificationFanout";

/**
 * Annonces d'école → parents, contre le VRAI émulateur Firestore.
 *
 * Un parent n'appartient à aucune école : il reçoit les annonces de l'école de
 * chacun de ses enfants, via les liens `children_links` APPROUVÉS, une seule
 * fois par annonce même s'il y a plusieurs enfants.
 */

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error("This test requires the Firestore emulator (--only firestore).");
}

const SCHOOL_E = "school-e";
const SCHOOL_F = "school-f";

async function clear(): Promise<void> {
  for (const name of ["users", "children_links", "notifications", "announcements"]) {
    const snapshot = await db.collection(name).get();
    await Promise.all(snapshot.docs.map((doc) => doc.ref.delete()));
  }
}

async function seed(): Promise<void> {
  const users: Record<string, Record<string, unknown>> = {
    "student-e1": { role: "student", establishmentId: SCHOOL_E },
    "student-e2": { role: "student", establishmentId: SCHOOL_E },
    "student-f1": { role: "student", establishmentId: SCHOOL_F },
    "teacher-e": { role: "teacher", establishmentId: SCHOOL_E, accountStatus: "active" },
    // Aucun parent ne porte d'établissement : c'est le cas réel.
    "parent-one-child": { role: "parent" },
    "parent-two-children-same-school": { role: "parent" },
    "parent-two-schools": { role: "parent" },
    "parent-unlinked": { role: "parent" },
    "parent-pending": { role: "parent" },
    "parent-other-school-only": { role: "parent" },
    "parent-suspended": { role: "parent", accountStatus: "suspended" },
  };
  for (const [uid, data] of Object.entries(users)) {
    await db.collection("users").doc(uid).set(data);
  }
  const links: Array<[string, string, string]> = [
    ["parent-one-child", "student-e1", "approved"],
    ["parent-two-children-same-school", "student-e1", "approved"],
    ["parent-two-children-same-school", "student-e2", "approved"],
    ["parent-two-schools", "student-e2", "approved"],
    ["parent-two-schools", "student-f1", "approved"],
    ["parent-pending", "student-e1", "pending"],
    ["parent-other-school-only", "student-f1", "approved"],
    ["parent-suspended", "student-e1", "approved"],
  ];
  for (const [parentId, studentId, status] of links) {
    await db.collection("children_links").doc(`${parentId}_${studentId}`).set({ parentId, studentId, status });
  }
}

async function announce(id: string, establishmentId: string, audience: string): Promise<void> {
  const ref = db.collection("announcements").doc(id);
  await ref.set({
    title: "Réunion",
    message: "Réunion des familles vendredi.",
    audience,
    establishmentId,
    createdBy: "admin-e",
  });
  const snapshot = await ref.get();
  await fanoutAnnouncementHandler({ data: snapshot } as unknown as FirestoreEvent<QueryDocumentSnapshot | undefined>);
}

async function recipientsOf(announcementId: string): Promise<string[]> {
  const snapshot = await db.collection("notifications").where("sourceId", "==", announcementId).get();
  return snapshot.docs.map((doc) => String(doc.get("userId"))).sort();
}

describe("school announcements reach parents through approved child links", () => {
  beforeEach(async () => {
    await clear();
    await seed();
  });

  it("reaches each linked parent exactly once, and nobody else", async () => {
    await announce("ann-parents-e", SCHOOL_E, "Parents");
    const recipients = await recipientsOf("ann-parents-e");

    // 1 parent / 1 enfant.
    expect(recipients).toContain("parent-one-child");
    // 1 parent / 2 enfants même école : une seule notification.
    expect(recipients.filter((id) => id === "parent-two-children-same-school")).toHaveLength(1);
    // 1 parent / 2 enfants écoles différentes : reçoit l'annonce de l'école E.
    expect(recipients).toContain("parent-two-schools");
    // Parent non lié, lien non approuvé, enfant hors établissement, compte suspendu.
    expect(recipients).not.toContain("parent-unlinked");
    expect(recipients).not.toContain("parent-pending");
    expect(recipients).not.toContain("parent-other-school-only");
    expect(recipients).not.toContain("parent-suspended");
    // Une annonce « Parents » n'atteint ni élèves ni enseignants.
    expect(recipients.some((id) => id.startsWith("student-") || id.startsWith("teacher-"))).toBe(false);
    expect(new Set(recipients).size).toBe(recipients.length);
  });

  it("lets a parent with children in two schools receive both schools' announcements", async () => {
    await announce("ann-parents-e2", SCHOOL_E, "Parents");
    await announce("ann-parents-f", SCHOOL_F, "Parents");

    expect(await recipientsOf("ann-parents-e2")).toContain("parent-two-schools");
    const fRecipients = await recipientsOf("ann-parents-f");
    expect(fRecipients).toContain("parent-two-schools");
    expect(fRecipients).toContain("parent-other-school-only");
    expect(fRecipients).not.toContain("parent-one-child");
  });

  it("includes linked parents in a whole-school announcement without duplicates", async () => {
    await announce("ann-all-e", SCHOOL_E, "Tout l'établissement");
    const recipients = await recipientsOf("ann-all-e");
    expect(recipients).toEqual(expect.arrayContaining([
      "student-e1",
      "student-e2",
      "teacher-e",
      "parent-one-child",
      "parent-two-children-same-school",
      "parent-two-schools",
    ]));
    expect(recipients).not.toContain("student-f1");
    expect(recipients).not.toContain("parent-other-school-only");
    expect(new Set(recipients).size).toBe(recipients.length);
  });

  it("stays idempotent when the trigger is retried", async () => {
    await announce("ann-retry", SCHOOL_E, "Parents");
    const first = await recipientsOf("ann-retry");
    const snapshot = await db.collection("announcements").doc("ann-retry").get();
    await fanoutAnnouncementHandler({ data: snapshot } as unknown as FirestoreEvent<QueryDocumentSnapshot | undefined>);
    expect(await recipientsOf("ann-retry")).toEqual(first);
  });
});
