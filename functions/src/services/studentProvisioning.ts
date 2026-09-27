/** Plan de provisionnement limité à un élève. Aucun consentement, nom,
 * rattachement d'établissement ou droit adulte n'est inventé. */
export interface StudentProvisionInput {
  email: string;
  role: string;
  classLevel: string;
  series: string;
}

export function normalizeStudentProvisionInput(input: StudentProvisionInput) {
  const email = input.email.trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || input.role !== "student" ||
      input.classLevel.toLowerCase() !== "terminale" || input.series.toUpperCase() !== "D") {
    throw new Error("Expected --email <address> --role student --class terminale --series D.");
  }
  return { email, role: "student", classLevel: "Terminale", series: "D" } as const;
}

export function planStudentProvision(
  raw: StudentProvisionInput,
  uid: string,
  current: { user?: Record<string, unknown>; profile?: Record<string, unknown>; claims?: Record<string, unknown>; adultProfile?: boolean; disabled?: boolean },
) {
  const target = normalizeStudentProvisionInput(raw);
  if (current.disabled || current.adultProfile) throw new Error("Incompatible existing account; no changes made.");
  const claims = current.claims ?? {};
  for (const [key, value] of Object.entries(claims)) {
    if ((["admin", "superAdmin", "super_admin", "isSuperAdmin", "teacher", "parent"].includes(key) && value) ||
        (key === "role" && value !== "student") ||
        (key === "roles" && (!Array.isArray(value) || value.some((role) => role !== "student")))) {
      throw new Error("Incompatible existing claims; no changes made.");
    }
  }
  for (const document of [current.user, current.profile]) {
    if (!document) continue;
    const preferences = document.preferences as Record<string, unknown> | undefined;
    for (const [field, expected] of Object.entries({ educationalSubsystem: "francophone", educationType: "general", academicLevelId: "fr_general_terminale", streamOrSpeciality: "D" })) {
      if (preferences?.[field] && preferences[field] !== expected) {
        throw new Error("Incompatible existing academic preferences; no changes made.");
      }
    }
    if ((document.uid && document.uid !== uid) ||
        (document.email && String(document.email).toLowerCase() !== target.email) ||
        (document.role && document.role !== "student") ||
        (document.roles && (!Array.isArray(document.roles) || document.roles.some((role) => role !== "student"))) ||
        (document.accountStatus && document.accountStatus !== "active") ||
        (document.classLevel && document.classLevel !== target.classLevel) ||
        (document.series && document.series !== target.series)) {
      throw new Error("Incompatible existing profile; no changes made.");
    }
  }
  if (current.user && current.user.role !== "student") throw new Error("Existing profile has no student authorization.");
  const user: Record<string, unknown> = current.user ? {} : {
    uid, email: target.email, role: "student", firstName: "", lastName: "",
    profileCompleted: false, tourGuideSeen: false, accountStatus: "active",
  };
  const profile: Record<string, unknown> = current.profile ? {} : {
    uid, email: target.email, firstName: String(current.user?.firstName ?? ""),
    lastName: String(current.user?.lastName ?? ""), profileCompleted: false,
    points: 0, level: 1, streak: { current: 0, best: 0, lastStudyDate: null },
    preferences: { contentLanguage: "fr", interfaceLanguage: "fr", educationalSubsystem: "francophone", educationType: "general", academicLevelId: "fr_general_terminale", streamOrSpeciality: "D", accountLinkage: "individual" },
  };
  for (const [name, document, update] of [["user", current.user, user], ["profile", current.profile, profile]] as const) {
    for (const key of ["classLevel", "series"] as const) {
      if (document?.[key] !== target[key]) update[key] = target[key];
    }
    if (name === "user" && document && !document.email) update.email = target.email;
  }
  return { target, user, profile };
}
