import { getAuth } from "firebase-admin/auth";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { z } from "zod";

import { hasUserRole } from "../auth/userRoles";
import { FirestoreStudentAccessStore, type StudentAccessStore, type CustomTokenIssuer } from "./studentAccessCode";

const input = z.object({ studentId: z.string().trim().min(1).max(128).regex(/^[^/]+$/) }).strict();

/** La preuve familiale ouvre l'UID enfant existant. Aucun rôle/claim du parent
 * n'est transféré, aucun numéro déplacé, aucun compte supplémentaire créé.
 * Une session enfant ne peut appeler ni cet échange ni les services parent.
 */
export function createOpenLinkedChildSessionHandler(
  store: Pick<StudentAccessStore, "readAccount" | "isLinkedParent"> = new FirestoreStudentAccessStore(),
  issuer: CustomTokenIssuer = { createCustomToken: (uid) => getAuth().createCustomToken(uid) },
  now: () => number = Date.now,
) {
  return async (request: CallableRequest<unknown>): Promise<{ token: string }> => {
    const auth = request.auth;
    if (!auth) throw new HttpsError("unauthenticated", "Sign-in required.");
    const parsed = input.safeParse(request.data);
    if (!parsed.success) throw new HttpsError("invalid-argument", "Invalid request.");
    const authTime = auth.token.auth_time;
    const age = now() / 1000 - Number(authTime);
    const provider = auth.token.firebase?.sign_in_provider;
    if (typeof authTime !== "number" || !Number.isFinite(age) || age < 0 || age > 300 ||
        !["phone", "password", "google.com"].includes(provider ?? "")) {
      throw new HttpsError("failed-precondition", "Sign in again to choose a child.");
    }
    const parent = await store.readAccount(auth.uid);
    if (!parent || !hasUserRole(parent, "parent") || !active(parent.accountStatus)) {
      throw new HttpsError("permission-denied", "A linked parent is required.");
    }
    const studentId = parsed.data.studentId;
    if (studentId === auth.uid || !await store.isLinkedParent(auth.uid, studentId)) {
      throw new HttpsError("permission-denied", "An approved family link is required.");
    }
    const student = await store.readAccount(studentId);
    if (!student || student.role !== "student" || !active(student.accountStatus) ||
        student.roles?.some((role) => role !== "student")) {
      throw new HttpsError("permission-denied", "Student access is unavailable.");
    }
    // Deliberately omit additional claims: this token is only the child's UID.
    return { token: await issuer.createCustomToken(studentId) };
  };
}

function active(status: string): boolean {
  return status === "active" || status === "";
}
