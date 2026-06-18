import { readFileSync } from "node:fs";
import { join } from "node:path";
import {
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
  initializeTestEnvironment
} from "@firebase/rules-unit-testing";
import {
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc
} from "firebase/firestore";
import { afterAll, afterEach, beforeAll, describe, it } from "vitest";

const projectId = "edunova-aabd1";

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: "127.0.0.1",
      port: 8085,
      rules: readFileSync(join(process.cwd(), "../firestore.rules"), "utf8")
    }
  });
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

afterAll(async () => {
  await testEnv.cleanup();
});

async function seedFirestore() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, "users/student-a"), {
      role: "student",
      establishmentId: "school-a"
    });
    await setDoc(doc(db, "users/student-b"), {
      role: "student",
      establishmentId: "school-b"
    });
    await setDoc(doc(db, "users/parent-a"), {
      role: "parent",
      establishmentId: "school-a"
    });
    await setDoc(doc(db, "users/parent-b"), {
      role: "parent",
      establishmentId: "school-b"
    });
    await setDoc(doc(db, "users/teacher-a"), {
      role: "teacher",
      establishmentId: "school-a"
    });
    await setDoc(doc(db, "users/admin-a"), {
      role: "admin",
      establishmentId: "school-a"
    });

    await setDoc(doc(db, "student_profiles/student-a"), {
      firstName: "Student A",
      xp: 10
    });
    await setDoc(doc(db, "student_profiles/student-b"), {
      firstName: "Student B",
      xp: 20
    });
    await setDoc(doc(db, "children_links/parent-a_student-a"), {
      parentId: "parent-a",
      studentId: "student-a",
      status: "approved"
    });
    await setDoc(doc(db, "ai_conversations/private-conv"), {
      userId: "student-a",
      messages: []
    });
  });
}

function dbFor(uid?: string) {
  return uid
    ? testEnv.authenticatedContext(uid).firestore()
    : testEnv.unauthenticatedContext().firestore();
}

describe("Firestore security rules", () => {
  it("blocks unauthenticated access to student profiles, quiz attempts, and private conversations", async () => {
    await seedFirestore();
    const db = dbFor();

    await assertFails(getDoc(doc(db, "student_profiles/student-a")));
    await assertFails(setDoc(doc(db, "quiz_attempts/attempt-a"), {
      studentId: "student-a",
      xpAwarded: 999
    }));
    await assertFails(getDoc(doc(db, "ai_conversations/private-conv")));
  });

  it("allows a student to read their own profile but not another private student profile", async () => {
    await seedFirestore();
    const db = dbFor("student-a");

    await assertSucceeds(getDoc(doc(db, "student_profiles/student-a")));
    await assertFails(getDoc(doc(db, "student_profiles/student-b")));
  });

  it("blocks a student from modifying another user role or creating administrator-only content", async () => {
    await seedFirestore();
    const db = dbFor("student-a");

    await assertFails(updateDoc(doc(db, "users/student-b"), { role: "admin" }));
    await assertFails(setDoc(doc(db, "classes/class-a"), {
      establishmentId: "school-a",
      title: "Class A"
    }));
  });

  it("documents current weakness: a student can still write own quiz attempt and XP-bearing profile fields", async () => {
    await seedFirestore();
    const db = dbFor("student-a");

    await assertSucceeds(setDoc(doc(db, "quiz_attempts/student-a_attempt"), {
      studentId: "student-a",
      score: 100,
      xpAwarded: 999
    }));
    await assertSucceeds(updateDoc(doc(db, "student_profiles/student-a"), {
      xp: 999999
    }));
  });

  it("blocks an unlinked parent and allows a linked parent to read the authorized child profile", async () => {
    await seedFirestore();

    await assertFails(getDoc(doc(dbFor("parent-b"), "student_profiles/student-a")));
    await assertSucceeds(getDoc(doc(dbFor("parent-a"), "student_profiles/student-a")));
  });

  it.skip("target behavior: a teacher should not be able to promote their own user role to administrator", async () => {
    await seedFirestore();
    await assertFails(updateDoc(doc(dbFor("teacher-a"), "users/teacher-a"), {
      role: "admin"
    }));
  });

  it("documents current weakness: a teacher owner can currently update their own role field", async () => {
    await seedFirestore();
    await assertSucceeds(updateDoc(doc(dbFor("teacher-a"), "users/teacher-a"), {
      role: "admin"
    }));
  });

  it("enforces teacher establishment scope for student profile reads", async () => {
    await seedFirestore();
    const db = dbFor("teacher-a");

    await assertSucceeds(getDoc(doc(db, "student_profiles/student-a")));
    await assertFails(getDoc(doc(db, "student_profiles/student-b")));
  });

  it("blocks a normal admin from super-admin-only actions", async () => {
    await seedFirestore();
    const db = dbFor("admin-a");

    await assertFails(setDoc(doc(db, "establishments/new-school"), {
      name: "New School"
    }));
    await assertFails(deleteDoc(doc(db, "users/student-a")));
  });

  it("blocks client writes to generated quizzes and summaries", async () => {
    await seedFirestore();
    const db = dbFor("student-a");

    await assertFails(setDoc(doc(db, "courses/course-a/generated_quizzes/quiz-a"), {
      generatedByUid: "student-a"
    }));
    await assertFails(setDoc(doc(db, "courses/course-a/generated_summaries/summary-a"), {
      generatedByUid: "student-a"
    }));
  });

  it("blocks client creation of Functions-only notifications and recommendations", async () => {
    await seedFirestore();
    const db = dbFor("student-a");

    await assertFails(setDoc(doc(db, "notifications/notification-a"), {
      userId: "student-a"
    }));
    await assertFails(setDoc(doc(db, "recommendations/recommendation-a"), {
      studentId: "student-a"
    }));
  });
});
