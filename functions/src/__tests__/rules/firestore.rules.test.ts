import { readFileSync } from "node:fs";
import { join } from "node:path";
import {
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  runTransaction,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from "firebase/firestore";
import { afterAll, afterEach, beforeAll, describe, expect, it } from "vitest";

const projectId = "demo-intellia237";

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
    await setDoc(doc(db, "users/admin-b"), {
      role: "admin",
      establishmentId: "school-b",
    });
    await setDoc(doc(db, "users/pending-teacher"), {
      role: "teacher",
      establishmentId: "school-a",
      accountStatus: "pending_validation",
    });
    // The general administration belongs to no school: it serves every one.
    await setDoc(doc(db, "users/root"), { role: "superAdmin" });
    await setDoc(doc(db, "establishments/school-a"), { name: "School A" });
    await setDoc(doc(db, "classes/class-a"), {
      establishmentId: "school-a",
      mainTeacherId: "teacher-a",
      teacherIds: ["teacher-a"],
      studentIds: ["student-a"],
    });

    await setDoc(doc(db, "student_profiles/student-a"), {
      firstName: "Student A",
      points: 10,
    });
    await setDoc(doc(db, "student_profiles/student-b"), {
      firstName: "Student B",
      points: 20,
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
    await setDoc(doc(db, "notifications/notification-owned"), {
      userId: "student-a",
      title: "Nouveau cours",
      body: "Une leçon est disponible.",
      route: "/learn",
      type: "content",
      createdAt: new Date("2026-09-04T12:00:00Z"),
      readAt: null,
    });
    await setDoc(doc(db, "quizzes/quiz-a"), {
      title: "Legacy quiz",
      status: "published",
      classLevels: ["Terminale"],
      questions: [{
        id: "q1",
        prompt: "2 + 2",
        correctOptionIndex: 0,
      }],
    });
    await setDoc(doc(db, "quiz_answer_keys/quiz-a"), {
      answers: [{ id: "q1", correctOptionIndex: 0 }],
    });
    await setDoc(doc(db, "mobile_money_offers/school-a"), {
      status: "active",
      establishmentId: "school-a",
      amountXaf: 5000,
      recipientPhone: "+237600000000",
    });
    await setDoc(doc(db, "mobile_money_payment_requests/payment-a"), {
      parentId: "parent-a",
      establishmentId: "school-a",
      status: "pending",
      transactionReference: "PRIVATE-REF-A",
    });
    await setDoc(doc(db, "mobile_money_reference_keys/hash-a"), {
      requestId: "payment-a",
    });
    await setDoc(doc(db, "entitlements/parent-a_school-a"), {
      userId: "parent-a",
      establishmentId: "school-a",
      status: "active",
    });
  });
}

function dbFor(uid?: string) {
  return uid
    ? testEnv.authenticatedContext(uid).firestore()
    : testEnv.unauthenticatedContext().firestore();
}

type RegistrationPayloadOptions = {
  series?: string | null;
  tutorId?: string | null;
  establishmentCandidate?:
    | { candidateId: string | null; name: string; status: string }
    | null;
};

function exactStudentRegistrationPayload(
  uid: string,
  now: Date,
  options: RegistrationPayloadOptions = {},
) {
  const series = options.series === undefined ? "D" : options.series;
  const tutorId = options.tutorId === undefined ? "leo" : options.tutorId;
  const establishmentCandidate =
    options.establishmentCandidate === undefined
      ? {
          candidateId: null,
          name: "Lycée de la Réunification",
          status: "selectedUnverified",
        }
      : options.establishmentCandidate;
  const preferences = {
    preferredSubjects: ["Mathématiques", "Sciences"],
    difficultSubjects: ["Anglais"],
    learningGoal: "Maitriser les examens",
    dailyStudyMinutes: 45,
    studyReminderEnabled: true,
    notificationsEnabled: true,
    contentLanguage: "fr",
    interfaceLanguage: "fr",
    educationalSubsystem: "francophone",
    educationType: "general",
    academicLevelId: "fr_general_terminale",
    streamOrSpeciality: series,
    accountLinkage: "individual",
    establishmentCandidate,
  };
  const consents = {
    termsAccepted: true,
    privacyAccepted: true,
    dataPolicyAccepted: true,
    acceptedAt: now,
  };

  return {
    user: {
      uid,
      firstName: "Amina",
      lastName: "Ndi",
      email: "amina.ndi@example.com",
      role: "student",
      classLevel: "Terminale",
      series,
      tutorId,
      profileCompleted: true,
      tourGuideSeen: false,
      createdAt: now,
      updatedAt: now,
    },
    userUpdate: {
      firstName: "Amina",
      lastName: "Ndi",
      profileCompleted: true,
      updatedAt: now,
    },
    profile: {
      uid,
      firstName: "Amina",
      lastName: "Ndi",
      email: "amina.ndi@example.com",
      classLevel: "Terminale",
      series,
      points: 0,
      level: 1,
      streak: { current: 0, best: 0, lastStudyDate: null },
      tutorId,
      preferences,
      consents,
      profileCompleted: true,
      createdAt: now,
      updatedAt: now,
    },
    profileUpdate: {
      firstName: "Amina",
      lastName: "Ndi",
      tutorId,
      preferences,
      consents,
      profileCompleted: true,
      updatedAt: now,
    },
  };
}

async function legacyMergedBatchWrite(
  uid: string,
  options: RegistrationPayloadOptions = {},
) {
  const db = dbFor(uid);
  const payload = exactStudentRegistrationPayload(uid, new Date(), options);
  const batch = writeBatch(db);
  batch.set(doc(db, `users/${uid}`), payload.user, { merge: true });
  batch.set(doc(db, `student_profiles/${uid}`), payload.profile, {
    merge: true,
  });
  await batch.commit();
}

async function idempotentRegistrationWrite(
  uid: string,
  options: RegistrationPayloadOptions = {},
) {
  const db = dbFor(uid);
  const payload = exactStudentRegistrationPayload(uid, new Date(), options);
  const userRef = doc(db, `users/${uid}`);
  await runTransaction(db, async (transaction) => {
    const snapshot = await transaction.get(userRef);
    if (snapshot.exists()) {
      transaction.update(userRef, payload.userUpdate);
    } else {
      transaction.set(userRef, payload.user);
    }
  });

  const profileRef = doc(db, `student_profiles/${uid}`);
  await runTransaction(db, async (transaction) => {
    const snapshot = await transaction.get(profileRef);
    if (snapshot.exists()) {
      transaction.update(profileRef, payload.profileUpdate);
    } else {
      transaction.set(profileRef, payload.profile);
    }
  });
}

describe("Firestore security rules", () => {
  it("blocks unauthenticated access to student profiles, quiz attempts, and private conversations", async () => {
    await seedFirestore();
    const db = dbFor();

    await assertFails(getDoc(doc(db, "student_profiles/student-a")));
    await assertFails(
      setDoc(doc(db, "quiz_attempts/attempt-a"), {
        studentId: "student-a",
        pointsAwarded: 999,
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

  it("allows a student to persist only their own companion preference", async () => {
    await seedFirestore();
    const db = dbFor("student-a");

    await assertSucceeds(
      updateDoc(doc(db, "student_profiles/student-a"), {
        tutorId: "leo",
        updatedAt: new Date(),
      }),
    );
    await assertFails(
      updateDoc(doc(db, "student_profiles/student-b"), { tutorId: "leo" }),
    );
    await assertFails(updateDoc(doc(db, "users/student-a"), { tutorId: "leo" }));
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

  it("prevents students from bypassing the sanitized quiz callables", async () => {
    await seedFirestore();
    const studentDb = dbFor("student-a");
    const teacherDb = dbFor("teacher-a");

    await assertFails(getDoc(doc(studentDb, "quizzes/quiz-a")));
    await assertFails(getDoc(doc(studentDb, "quiz_answer_keys/quiz-a")));
    await assertSucceeds(getDoc(doc(teacherDb, "quizzes/quiz-a")));
    await assertSucceeds(getDoc(doc(teacherDb, "quiz_answer_keys/quiz-a")));
    await assertFails(
      setDoc(doc(studentDb, "quiz_answer_keys/student-forged"), {
        answers: [{ id: "q1", correctOptionIndex: 0 }],
      }),
    );
    await assertSucceeds(
      setDoc(doc(teacherDb, "quiz_answer_keys/teacher-authored"), {
        answers: [{ id: "q1", correctOptionIndex: 0 }],
      }),
    );
  });

  it("blocks client writes to quiz attempts, progress, streaks, and point-bearing fields", async () => {
    await seedFirestore();
    const db = dbFor("student-a");

    await assertFails(
      setDoc(doc(db, "quiz_attempts/student-a_attempt"), {
        studentId: "student-a",
        score: 100,
        pointsAwarded: 999,
      }),
    );
    await assertFails(
      updateDoc(doc(db, "student_profiles/student-a"), {
        points: 999999,
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
        pointsAwarded: 999,
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
        points: 0,
        level: 1,
        streak: {
          current: 0,
          best: 0,
          lastStudyDate: null,
        },
        profileCompleted: true,
      }),
    );
    // Compatibilité non destructive avec les anciennes versions de l'app.
    await assertSucceeds(
      setDoc(doc(dbFor("legacy-student"), "student_profiles/legacy-student"), {
        uid: "legacy-student",
        xp: 0,
        level: 1,
      }),
    );
    await assertFails(
      setDoc(doc(dbFor("bad-student"), "student_profiles/bad-student"), {
        uid: "bad-student",
        points: 500,
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

  it("lets a school head run their school without adding or removing a pupil", async () => {
    await seedFirestore();
    const head = dbFor("admin-a");

    await assertSucceeds(getDoc(doc(head, "users/student-a")));
    await assertSucceeds(getDoc(doc(head, "establishments/school-a")));
    await assertFails(getDoc(doc(head, "users/student-b")));

    // No pupil enters or leaves the school through its head.
    await assertFails(setDoc(doc(head, "users/new-pupil"), {
      uid: "new-pupil",
      role: "student",
      establishmentId: "school-a",
    }));
    await assertFails(setDoc(doc(head, "student_profiles/new-pupil"), {
      uid: "new-pupil",
      points: 0,
      level: 1,
    }));
    await assertFails(deleteDoc(doc(head, "users/student-a")));
    await assertFails(deleteDoc(doc(head, "student_profiles/student-a")));
    await assertFails(updateDoc(doc(head, "users/student-a"), {
      establishmentId: "school-b",
    }));

    // Classes are organised, rosters are not touched.
    await assertSucceeds(updateDoc(doc(head, "classes/class-a"), {
      name: "Terminale C",
    }));
    await assertFails(updateDoc(doc(head, "classes/class-a"), { studentIds: [] }));
    await assertFails(updateDoc(doc(head, "classes/class-a"), {
      studentIds: ["student-a", "student-b"],
    }));
    await assertFails(deleteDoc(doc(head, "classes/class-a")));
  });

  it("keeps every assigned teacher's class lists readable, school or not", async () => {
    await seedFirestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      // Teachers approved before schools were attached still teach classes.
      await setDoc(doc(db, "users/teacher-unattached"), { role: "teacher" });
      await setDoc(doc(db, "classes/class-u"), {
        establishmentId: "school-a",
        mainTeacherId: "teacher-a",
        teacherIds: ["teacher-unattached"],
        studentIds: [],
      });
    });
    const classesOf = (uid: string) => collection(dbFor(uid), "classes");

    await assertSucceeds(getDocs(query(
      classesOf("teacher-a"),
      where("teacherIds", "array-contains", "teacher-a"),
    )));
    await assertSucceeds(getDocs(query(
      classesOf("teacher-a"),
      where("mainTeacherId", "==", "teacher-a"),
    )));
    await assertSucceeds(getDocs(query(
      classesOf("teacher-unattached"),
      where("teacherIds", "array-contains", "teacher-unattached"),
    )));
    await assertSucceeds(getDoc(doc(dbFor("teacher-unattached"), "classes/class-u")));
    await assertFails(getDoc(doc(dbFor("admin-b"), "classes/class-a")));
    await assertFails(getDocs(classesOf("parent-a")));
  });

  it("reserves national content to the general administration", async () => {
    await seedFirestore();
    const head = dbFor("admin-a");
    const root = dbFor("root");
    const national = { title: "National", workflow: { status: "draft" } };
    const forSchool = (establishmentId: string) => ({
      title: "School",
      scope: { type: "establishment", establishmentId },
      workflow: { status: "draft" },
    });

    await assertFails(setDoc(doc(head, "lessons/national"), national));
    await assertSucceeds(setDoc(doc(head, "lessons/own"), forSchool("school-a")));
    await assertFails(setDoc(doc(head, "lessons/other"), forSchool("school-b")));
    await assertSucceeds(setDoc(doc(root, "lessons/national"), national));
    await assertSucceeds(setDoc(doc(root, "lessons/other"), forSchool("school-b")));

    await assertFails(setDoc(doc(head, "flow_items/national"), {
      status: "draft",
    }));
    await assertSucceeds(setDoc(doc(head, "flow_items/own"), {
      status: "draft",
      scope: { type: "establishment", establishmentId: "school-a" },
    }));
    await assertFails(setDoc(doc(dbFor("teacher-a"), "flow_items/national"), {
      status: "draft",
    }));
  });

  it("lets only the general administration open a school", async () => {
    await seedFirestore();

    await assertSucceeds(setDoc(doc(dbFor("root"), "establishments/new-school"), {
      name: "New School",
      city: "Douala",
    }));
    await assertFails(setDoc(doc(dbFor("teacher-a"), "establishments/other-school"), {
      name: "Other School",
    }));
  });

  it("serves the school-scoped announcement queries of every dashboard", async () => {
    // Reads stay open to signed-in accounts until installed versions that
    // query without a school are gone; the new queries must already pass.
    await seedFirestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "announcements/news-a"), {
        createdBy: "teacher-a",
        establishmentId: "school-a",
        title: "A",
        message: "A",
        audience: "Parents",
      });
      await setDoc(doc(db, "announcements/news-b"), {
        createdBy: "admin-b",
        establishmentId: "school-b",
        title: "B",
        message: "B",
        audience: "Parents",
      });
    });
    const ofSchool = (uid: string, establishmentId: string) =>
      getDocs(query(
        collection(dbFor(uid), "announcements"),
        where("establishmentId", "==", establishmentId),
      ));

    await assertSucceeds(ofSchool("admin-a", "school-a"));
    await assertSucceeds(ofSchool("parent-a", "school-a"));
    await assertSucceeds(getDocs(query(
      collection(dbFor("teacher-a"), "announcements"),
      where("establishmentId", "==", "school-a"),
      where("createdBy", "==", "teacher-a"),
    )));
    await assertFails(getDocs(collection(dbFor(), "announcements")));
    await assertSucceeds(getDocs(collection(dbFor("root"), "announcements")));
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

  it("allows only the owner read marker on server notifications", async () => {
    await seedFirestore();
    const ownerDb = dbFor("student-a");
    const otherDb = dbFor("student-b");
    const reference = doc(ownerDb, "notifications/notification-owned");

    await assertSucceeds(getDoc(reference));
    await assertFails(
      getDoc(doc(otherDb, "notifications/notification-owned")),
    );
    await assertSucceeds(updateDoc(reference, { readAt: new Date() }));
    await assertFails(updateDoc(reference, { title: "Texte falsifié" }));
    await assertFails(updateDoc(reference, { userId: "student-b" }));
  });

  it("scopes notification device tokens to the authenticated owner", async () => {
    await seedFirestore();
    const ownerDb = dbFor("student-a");
    const device = doc(ownerDb, "notification_devices/device-a");

    await assertSucceeds(
      setDoc(device, {
        userId: "student-a",
        token: "token-a",
        platform: "android",
        authorizationStatus: "authorized",
        updatedAt: new Date(),
      }),
    );
    await assertSucceeds(updateDoc(device, { token: "token-b" }));
    await assertFails(updateDoc(device, { userId: "student-b" }));
    await assertFails(
      setDoc(doc(ownerDb, "notification_devices/device-b"), {
        userId: "student-b",
        token: "token-b",
        platform: "android",
        authorizationStatus: "authorized",
        updatedAt: new Date(),
      }),
    );
  });

  it("permits only scoped, authenticated announcement publications", async () => {
    await seedFirestore();
    const now = new Date();

    await assertSucceeds(
      setDoc(doc(dbFor("admin-a"), "announcements/admin-valid"), {
        createdBy: "admin-a",
        establishmentId: "school-a",
        title: "Réunion",
        message: "Une information importante.",
        audience: "Élèves",
        publishedAt: now,
        createdAt: now,
      }),
    );
    await assertSucceeds(
      setDoc(doc(dbFor("teacher-a"), "announcements/class-valid"), {
        createdBy: "teacher-a",
        establishmentId: "school-a",
        classId: "class-a",
        title: "Devoir",
        message: "Le devoir est disponible.",
        audience: "Classe",
        publishedAt: now,
        createdAt: now,
      }),
    );
    await assertFails(
      setDoc(doc(dbFor("admin-a"), "announcements/cross-school"), {
        createdBy: "admin-a",
        establishmentId: "school-b",
        title: "Intrusion",
        message: "Non autorisé",
        audience: "Élèves",
      }),
    );
    await assertFails(
      setDoc(doc(dbFor("teacher-a"), "announcements/class-forged"), {
        createdBy: "teacher-a",
        establishmentId: "school-a",
        classId: "missing-class",
        title: "Intrusion",
        message: "Non autorisé",
        audience: "Classe",
      }),
    );
    await assertFails(
      updateDoc(doc(dbFor("admin-a"), "announcements/admin-valid"), {
        message: "Message modifié après notification",
      }),
    );
  });

  it("keeps Mobile Money configuration and anti-replay keys server-only", async () => {
    await seedFirestore();

    for (const uid of ["parent-a", "admin-a"]) {
      const scopedDb = dbFor(uid);
      await assertFails(
        getDoc(doc(scopedDb, "mobile_money_offers/school-a")),
      );
      await assertFails(
        getDoc(doc(scopedDb, "mobile_money_reference_keys/hash-a")),
      );
    }
  });

  it("scopes payment requests and entitlements to the owner or same-school admin", async () => {
    await seedFirestore();

    await assertSucceeds(
      getDoc(doc(dbFor("parent-a"), "mobile_money_payment_requests/payment-a")),
    );
    await assertFails(
      getDoc(doc(dbFor("parent-b"), "mobile_money_payment_requests/payment-a")),
    );
    await assertSucceeds(
      getDoc(doc(dbFor("admin-a"), "mobile_money_payment_requests/payment-a")),
    );
    await assertFails(
      getDoc(doc(dbFor("admin-b"), "mobile_money_payment_requests/payment-a")),
    );
    await assertSucceeds(
      getDoc(doc(dbFor("parent-a"), "entitlements/parent-a_school-a")),
    );
    await assertFails(
      getDoc(doc(dbFor("parent-b"), "entitlements/parent-a_school-a")),
    );
  });

  it("blocks every direct client write to payment requests and entitlements", async () => {
    await seedFirestore();
    const parentDb = dbFor("parent-a");
    const adminDb = dbFor("admin-a");

    await assertFails(
      setDoc(doc(parentDb, "mobile_money_payment_requests/forged"), {
        parentId: "parent-a",
        establishmentId: "school-a",
        amountXaf: 1,
        status: "approved",
      }),
    );
    await assertFails(
      updateDoc(doc(adminDb, "mobile_money_payment_requests/payment-a"), {
        status: "approved",
      }),
    );
    await assertFails(
      setDoc(doc(adminDb, "entitlements/forged"), {
        userId: "parent-a",
        establishmentId: "school-a",
        status: "active",
      }),
    );
  });

  describe("student registration idempotence", () => {
    it("reproduces DATA-PERM-101 when the legacy exact merged batch is retried", async () => {
      await assertSucceeds(legacyMergedBatchWrite("legacy-retry"));
      await assertFails(legacyMergedBatchWrite("legacy-retry"));
    });

    it("CASE 1/2 accepts the exact full payload when Auth is new or already exists", async () => {
      await assertSucceeds(idempotentRegistrationWrite("auth-new"));
      await assertSucceeds(idempotentRegistrationWrite("auth-existing"));
    });

    it("CASE 3 resumes when users exists and student_profiles is absent", async () => {
      const uid = "user-only";
      const db = dbFor(uid);
      const payload = exactStudentRegistrationPayload(uid, new Date());
      await setDoc(doc(db, `users/${uid}`), payload.user);

      await assertSucceeds(idempotentRegistrationWrite(uid));
      expect((await getDoc(doc(db, `student_profiles/${uid}`))).exists()).toBe(
        true,
      );
    });

    it("CASE 4/5 updates both existing documents and permits a double submit", async () => {
      const uid = "double-submit";
      await assertSucceeds(idempotentRegistrationWrite(uid));
      await assertSucceeds(idempotentRegistrationWrite(uid));
      await assertSucceeds(idempotentRegistrationWrite(uid));
    });

    it("CASE 6 updates historical documents that have no establishmentId", async () => {
      const uid = "historical-no-establishment";
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await setDoc(doc(db, `users/${uid}`), {
          uid,
          role: "student",
          firstName: "Amina",
          lastName: "Ndi",
          profileCompleted: false,
        });
        await setDoc(doc(db, `student_profiles/${uid}`), {
          uid,
          firstName: "Amina",
          lastName: "Ndi",
          classLevel: "Terminale",
          series: "D",
          points: 0,
          level: 1,
          profileCompleted: false,
        });
      });

      await assertSucceeds(idempotentRegistrationWrite(uid));
    });

    it("CASE 7/8 accepts null tutorId and null series", async () => {
      await assertSucceeds(
        idempotentRegistrationWrite("nullable-fields", {
          tutorId: null,
          series: null,
        }),
      );
    });

    it("CASE 9 accepts non-authoritative establishmentCandidate metadata", async () => {
      const uid = "candidate-present";
      await assertSucceeds(idempotentRegistrationWrite(uid));
      const snapshot = await getDoc(doc(dbFor(uid), `student_profiles/${uid}`));
      expect(snapshot.data()?.preferences.establishmentCandidate.name).toBe(
        "Lycée de la Réunification",
      );
      expect(snapshot.data()).not.toHaveProperty("establishmentId");
    });

    it("CASE 10 accepts an absent establishment candidate represented by null", async () => {
      const uid = "candidate-absent";
      await assertSucceeds(
        idempotentRegistrationWrite(uid, { establishmentCandidate: null }),
      );
      const snapshot = await getDoc(doc(dbFor(uid), `student_profiles/${uid}`));
      expect(snapshot.data()?.preferences.establishmentCandidate).toBeNull();
    });

    it("still blocks privilege, points, level, and authoritative establishment escalation", async () => {
      const uid = "no-escalation";
      await idempotentRegistrationWrite(uid);
      const db = dbFor(uid);

      await assertFails(updateDoc(doc(db, `users/${uid}`), { role: "admin" }));
      await assertFails(
        updateDoc(doc(db, `users/${uid}`), {
          establishmentId: "school-forged",
        }),
      );
      await assertFails(
        updateDoc(doc(db, `student_profiles/${uid}`), { points: 9000 }),
      );
      await assertFails(
        updateDoc(doc(db, `student_profiles/${uid}`), { level: 99 }),
      );
    });
  });
});
