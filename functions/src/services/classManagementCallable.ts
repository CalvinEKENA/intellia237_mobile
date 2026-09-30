import { FieldValue, type DocumentData, type Firestore } from "firebase-admin/firestore";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { z } from "zod";

import { db } from "../config/firebase";
import { toHttpsError } from "../utils/errors";
import { hasUserRole, isSuperAdminUser } from "../auth/userRoles";

const id = z.string().trim().min(1).max(128).regex(/^[^/]+$/);

export const manageSchoolClassInput = z.discriminatedUnion("action", [
  z.object({
    action: z.literal("create"),
    name: z.string().trim().min(1).max(60),
    classLevel: z.string().trim().min(1).max(30),
    series: z.string().trim().max(30).optional(),
    establishmentId: id,
  }).strict(),
  z.object({
    action: z.literal("delete"),
    classId: id,
    reason: z.string().trim().max(500).optional(),
  }).strict(),
]);

export type ManageSchoolClassInput = z.infer<typeof manageSchoolClassInput>;

export function authorizeClassAdmin(actorData: DocumentData | undefined, targetEstablishmentId: string): void {
  if (!actorData || (actorData.accountStatus && actorData.accountStatus !== "active")) {
    throw new HttpsError("permission-denied", "Active administrator account required.");
  }

  if (isSuperAdminUser(actorData)) {
    return;
  }

  if (hasUserRole(actorData, "admin")) {
    if (actorData.establishmentId !== targetEstablishmentId) {
      throw new HttpsError("permission-denied", "You can only manage classes for your own establishment.");
    }
    return;
  }

  throw new HttpsError("permission-denied", "Administrator privilege required.");
}

export class ClassManagementStore {
  constructor(private readonly firestore: Firestore = db) {}

  async execute(actorId: string, input: ManageSchoolClassInput): Promise<{ classId: string; action: string }> {
    const actorSnapshot = await this.firestore.collection("users").doc(actorId).get();
    const actorData = actorSnapshot.data();

    if (input.action === "create") {
      authorizeClassAdmin(actorData, input.establishmentId);

      // Verify establishment exists
      const estabSnapshot = await this.firestore.collection("establishments").doc(input.establishmentId).get();
      if (!estabSnapshot.exists) {
        throw new HttpsError("not-found", "Target establishment does not exist.");
      }

      const now = FieldValue.serverTimestamp();
      const newClassRef = this.firestore.collection("classes").doc();

      await this.firestore.runTransaction(async (tx) => {
        const freshActor = await tx.get(this.firestore.collection("users").doc(actorId));
        authorizeClassAdmin(freshActor.data(), input.establishmentId);

        tx.set(newClassRef, {
          id: newClassRef.id,
          name: input.name,
          classLevel: input.classLevel,
          series: input.series || "",
          establishmentId: input.establishmentId,
          studentCount: 0,
          createdAt: now,
          updatedAt: now,
          createdBy: actorId,
        });

        tx.create(this.firestore.collection("class_management_audit").doc(), {
          actorId,
          classId: newClassRef.id,
          establishmentId: input.establishmentId,
          action: "create",
          className: input.name,
          createdAt: now,
        });
      });

      return { classId: newClassRef.id, action: "create" };
    }

    // Action: delete
    const classRef = this.firestore.collection("classes").doc(input.classId);
    const classSnapshot = await classRef.get();
    if (!classSnapshot.exists) {
      throw new HttpsError("not-found", "Class not found.");
    }

    const classData = classSnapshot.data()!;
    const estabId = classData.establishmentId as string;
    authorizeClassAdmin(actorData, estabId);

    const studentCount = typeof classData.studentCount === "number" ? classData.studentCount : 0;
    if (studentCount > 0) {
      throw new HttpsError("failed-precondition", "Impossible de supprimer une classe contenant des élèves inscrits.");
    }

    const now = FieldValue.serverTimestamp();
    await this.firestore.runTransaction(async (tx) => {
      const [freshActor, freshClass] = await Promise.all([
        tx.get(this.firestore.collection("users").doc(actorId)),
        tx.get(classRef),
      ]);

      if (!freshClass.exists) {
        throw new HttpsError("not-found", "Class not found.");
      }

      const currentClassData = freshClass.data()!;
      authorizeClassAdmin(freshActor.data(), currentClassData.establishmentId);

      const currentStudents = typeof currentClassData.studentCount === "number" ? currentClassData.studentCount : 0;
      if (currentStudents > 0) {
        throw new HttpsError("failed-precondition", "Impossible de supprimer une classe contenant des élèves inscrits.");
      }

      tx.delete(classRef);

      tx.create(this.firestore.collection("class_management_audit").doc(), {
        actorId,
        classId: input.classId,
        establishmentId: estabId,
        action: "delete",
        reason: input.reason || "",
        createdAt: now,
      });
    });

    return { classId: input.classId, action: "delete" };
  }
}

export function createManageSchoolClassHandler(store = new ClassManagementStore()) {
  return async (request: CallableRequest<unknown>) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    try {
      const parsed = manageSchoolClassInput.parse(request.data);
      return await store.execute(request.auth.uid, parsed);
    } catch (error) {
      throw toHttpsError(error);
    }
  };
}

export const manageSchoolClassHandler = createManageSchoolClassHandler();
