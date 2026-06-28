import { readFileSync } from "node:fs";
import { join } from "node:path";
import {
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import { deleteDoc, doc, getDoc, setDoc, updateDoc } from "firebase/firestore";
import { afterAll, afterEach, beforeAll, describe, it } from "vitest";

const projectId = "edunova-aabd1";

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: "127.0.0.1",
      port: 8085,
      rules: readFileSync(join(process.cwd(), "../firestore.rules"), "utf8"),
    },
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
      establishmentId: "school-a",
    });
    await setDoc(doc(db, "users/student-b"), {
      role: "student",
      establishmentId: "school-b",
    });
    await setDoc(doc(db, "users/parent-a"), {
      role: "parent",
      establishmentId: "school-a",
    });
    await setDoc(doc(db, "users/parent-b"), {
      role: "parent",
      establishmentId: "school-b",
    });
    await setDoc(doc(db, "users/teacher-a"), {
      role: "teacher",
      establishmentId: "school-a",
    });
    await setDoc(doc(db, "users/admin-a"), {
      role: "admin",
      establishmentId: "school-a",
    });
    await setDoc(doc(db, "users/pending-teacher"), {
      role: "teacher",
      establishmentId: "school-a",
      accountStatus: "pending_validation",
    });

    await setDoc(doc(db, "student_profiles/student-a"), {
      firstName: "Student A",
      xp: 10,
    });
    await setDoc(doc(db, "student_profiles/student-b"), {
      firstName: "Student B",
      xp: 20,
    });
    await setDoc(doc(db, "children_links/parent-a_student-a"), {
      parentId: "parent-a",
      studentId: "student-a",
      status: "approved",
    });
    await setDoc(doc(db, "ai_conversations/private-conv"), {
      userId: "student-a",
      messages: [],
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
    await assertFails(
      setDoc(doc(db, "quiz_attempts/attempt-a"), {
        studentId: "student-a",
        xpAwarded: 999,
      }),
    );
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
    await assertFails(
      setDoc(doc(db, "classes/class-a"), {
        establishmentId: "school-a",
        title: "Class A",
      }),
    );
  });

  it("blocks client writes to quiz attempts, progress, streaks, and XP-bearing fields", async () => {
    await seedFirestore();
    const db = dbFor("student-a");

    await assertFails(
      setDoc(doc(db, "quiz_attempts/student-a_attempt"), {
        studentId: "student-a",
        score: 100,
        xpAwarded: 999,
      }),
    );
    await assertFails(
      updateDoc(doc(db, "student_profiles/student-a"), {
        xp: 999999,
      }),
    );
    await assertFails(
      setDoc(doc(db, "progress/student-a_quiz-a"), {
        studentId: "student-a",
        score: 100,
        xpAwarded: 999,
      }),
    );
    await assertFails(
      setDoc(doc(db, "streaks/student-a"), {
        currentStreak: 365,
        longestStreak: 365,
      }),
    );
  });

  it("allows student bootstrap documents only with safe initial academic values", async () => {
    const db = dbFor("new-student");

    await assertSucceeds(
      setDoc(doc(db, "users/new-student"), {
        uid: "new-student",
        role: "student",
        email: "student@example.com",
        firstName: "New",
        lastName: "Student",
        establishmentId: "school-a",
        classLevel: "Terminale",
        series: "D",
        profileCompleted: true,
        tourGuideSeen: false,
      }),
    );
    await assertSucceeds(
      setDoc(doc(db, "student_profiles/new-student"), {
        uid: "new-student",
        firstName: "New",
        lastName: "Student",
        email: "student@example.com",
        establishmentId: "school-a",
        establishmentName: "School A",
        classLevel: "Terminale",
        series: "D",
        xp: 0,
        level: 1,
        streak: {
          current: 0,
          best: 0,
          lastStudyDate: null,
        },
        profileCompleted: true,
      }),
    );
    await assertFails(
      setDoc(doc(dbFor("bad-student"), "student_profiles/bad-student"), {
        uid: "bad-student",
        xp: 500,
        level: 10,
      }),
    );
  });

  it("blocks public teacher and administrator role creation", async () => {
    await assertFails(
      setDoc(doc(dbFor("new-teacher"), "users/new-teacher"), {
        uid: "new-teacher",
        role: "teacher",
        email: "teacher@example.com",
      }),
    );
    await assertFails(
      setDoc(doc(dbFor("new-admin"), "users/new-admin"), {
        uid: "new-admin",
        role: "admin",
        email: "admin@example.com",
      }),
    );
  });

  it("blocks an unlinked parent and allows a linked parent to read the authorized child profile", async () => {
    await seedFirestore();

    await assertFails(
      getDoc(doc(dbFor("parent-b"), "student_profiles/student-a")),
    );
    await assertSucceeds(
      getDoc(doc(dbFor("parent-a"), "student_profiles/student-a")),
    );
  });

  it("blocks a teacher from promoting their own user role to administrator", async () => {
    await seedFirestore();
    await assertFails(
      updateDoc(doc(dbFor("teacher-a"), "users/teacher-a"), {
        role: "admin",
      }),
    );
  });

  it("allows only safe owner updates on user documents", async () => {
    await seedFirestore();
    await assertSucceeds(
      updateDoc(doc(dbFor("teacher-a"), "users/teacher-a"), {
        photoUrl: "https://example.com/avatar.png",
        tourGuideSeen: true,
      }),
    );
    await assertFails(
      updateDoc(doc(dbFor("teacher-a"), "users/teacher-a"), {
        establishmentId: "school-b",
      }),
    );
  });

  it("allows lesson favorites but blocks client-authored lesson progress", async () => {
    await seedFirestore();
    const db = dbFor("student-a");

    await assertSucceeds(
      setDoc(doc(db, "student_profiles/student-a/lessonProgress/math_ch1_l1"), {
        isFavorite: true,
      }),
    );
    await assertSucceeds(
      updateDoc(
        doc(db, "student_profiles/student-a/lessonProgress/math_ch1_l1"),
        {
          isFavorite: false,
        },
      ),
    );
    await assertFails(
      updateDoc(
        doc(db, "student_profiles/student-a/lessonProgress/math_ch1_l1"),
        {
          progress: 1,
        },
      ),
    );
    await assertFails(
      setDoc(doc(db, "student_profiles/student-a/lessonProgress/math_ch1_l2"), {
        progress: 1,
      }),
    );
  });

  it("enforces teacher establishment scope for student profile reads", async () => {
    await seedFirestore();
    const db = dbFor("teacher-a");

    await assertSucceeds(getDoc(doc(db, "student_profiles/student-a")));
    await assertFails(getDoc(doc(db, "student_profiles/student-b")));
  });

  it("blocks pending staff accounts from teacher and administrator privileges", async () => {
    await seedFirestore();
    const db = dbFor("pending-teacher");

    await assertFails(getDoc(doc(db, "student_profiles/student-a")));
    await assertFails(
      setDoc(doc(db, "courses/course-a"), {
        title: "Pending staff course",
      }),
    );
  });

  it("blocks a normal admin from super-admin-only actions", async () => {
    await seedFirestore();
    const db = dbFor("admin-a");

    await assertFails(
      setDoc(doc(db, "establishments/new-school"), {
        name: "New School",
      }),
    );
    await assertFails(deleteDoc(doc(db, "users/student-a")));
  });

  it("blocks client writes to generated quizzes and summaries", async () => {
    await seedFirestore();
    const db = dbFor("student-a");

    await assertFails(
      setDoc(doc(db, "courses/course-a/generated_quizzes/quiz-a"), {
        generatedByUid: "student-a",
      }),
    );
    await assertFails(
      setDoc(doc(db, "courses/course-a/generated_summaries/summary-a"), {
        generatedByUid: "student-a",
      }),
    );
  });

  it("blocks client creation of Functions-only notifications and recommendations", async () => {
    await seedFirestore();
    const db = dbFor("student-a");

    await assertFails(
      setDoc(doc(db, "notifications/notification-a"), {
        userId: "student-a",
      }),
    );
    await assertFails(
      setDoc(doc(db, "recommendations/recommendation-a"), {
        studentId: "student-a",
      }),
    );
  });
});
