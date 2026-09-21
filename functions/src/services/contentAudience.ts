import { z } from "zod";
import type { DocumentData } from "firebase-admin/firestore";

const values = z.array(z.string().trim().min(1).max(100)).max(64).default([]);
export const audienceClauseSchema = z.object({
  educationSystems: z.array(z.enum(["francophone", "anglophone"])).default([]),
  educationTypes: z.array(z.enum(["general", "technical"])).default([]),
  classLevels: values, series: values, tracks: values, languages: values, establishments: values,
}).strict();
export const contentAudienceSchema = z.object({
  version: z.literal(1), clauses: z.array(audienceClauseSchema).min(1).max(12),
}).strict();
export type ContentAudience = z.infer<typeof contentAudienceSchema>;

const registry = [
  ["6eme", "6e", "sixieme"], ["5eme", "5e", "cinquieme"], ["4eme", "4e", "quatrieme"],
  ["3eme", "3e", "troisieme"], ["Seconde", "2nde"], ["Premiere", "1ere"], ["Terminale", "terminale", "tle"],
  ["Form1", "form1"], ["Form2", "form2"], ["Form3", "form3"], ["Form4", "form4"],
  ["Form5", "form5"], ["LowerSixth", "lower_sixth"], ["UpperSixth", "upper_sixth"],
];
const normalized = (s: unknown) => String(s || "").normalize("NFD").replace(/[\u0300-\u036f\s_-]/g, "").toLowerCase();
export function canonicalClass(value: unknown): string {
  const n = normalized(value);
  return registry.find(row => row.some(alias => normalized(alias) === n))?.[0] || String(value || "").trim();
}
export function learnerAudienceContext(user: DocumentData, profile: DocumentData = {}) {
  const preferences = profile.preferences || {};
  const stable = String(preferences.academicLevelId || "");
  const level = canonicalClass(profile.classLevel || user.classLevel || stable.replace(/^(fr|en)_(general|technical)_/, ""));
  return {
    classLevels: level,
    educationSystems: preferences.educationalSubsystem || (stable.startsWith("en_") || /^(Form|Lower|Upper)/.test(level) ? "anglophone" : "francophone"),
    educationTypes: preferences.educationType || (stable.includes("_technical_") ? "technical" : "general"),
    series: String(profile.series ?? user.series ?? ""),
    tracks: String(preferences.streamOrSpeciality ?? preferences.track ?? profile.track ?? ""),
    languages: String(preferences.interfaceLanguage || preferences.language || profile.language || "").replace("french", "fr").replace("english", "en"),
    establishments: String(user.establishmentId || ""),
  };
}

/** Empty dimensions are wildcards; clauses are OR, dimensions within a clause AND.
 * Legacy class/scope fields remain authoritative only when no v1 contract exists.
 */
export function audienceAllows(data: DocumentData, user: DocumentData, profile: DocumentData = {}, fallbackClass?: string): boolean {
  if (user.accountStatus && user.accountStatus !== "active") return false;
  if (["superAdmin", "super_admin"].includes(user.role)) return true;
  const scope = data.scope?.type === "establishment" ? data.scope.establishmentId : data.establishmentId;
  if (scope && scope !== "global" && scope !== user.establishmentId) return false;
  if (["teacher", "admin"].includes(user.role)) return true;
  if (user.role !== "student") return false;
  const context = learnerAudienceContext(user, profile);
  if (!registry.some(row => row[0] === context.classLevels)) return false;
  if (data.audience !== undefined) {
    const parsed = contentAudienceSchema.safeParse(data.audience);
    if (!parsed.success) return false;
    return parsed.data.clauses.some(clause => Object.entries(clause).every(([key, allowed]) => {
      const actual = context[key as keyof typeof context];
      return allowed.length === 0 || allowed.some(value => key === "classLevels" ? canonicalClass(value) === actual : value === actual);
    }));
  }
  const levels: string[] = data.classLevels || (data.classLevel ? [data.classLevel] : fallbackClass ? [fallbackClass] : []);
  const series: string[] = data.series || data.allowedSeries || [];
  return (!levels.length || levels.some(v => canonicalClass(v) === context.classLevels)) &&
    (!series.length || series.includes(context.series));
}

export function effectiveAudience(data: DocumentData, parent: DocumentData, classLevel: string): ContentAudience {
  if (data.audience !== undefined) return contentAudienceSchema.parse(data.audience);
  if (parent.audience !== undefined) return contentAudienceSchema.parse(parent.audience);
  return contentAudienceSchema.parse({ version: 1, clauses: [{
    classLevels: data.classLevels || [classLevel], series: data.series || parent.allowedSeries || [],
  }] });
}

export function staffCanWrite(user: DocumentData, data: DocumentData): boolean {
  if (user.accountStatus && user.accountStatus !== "active") return false;
  if (["superAdmin", "super_admin"].includes(user.role)) return true;
  const scope = data.scope?.type === "establishment" ? data.scope.establishmentId : data.establishmentId;
  return ["teacher", "admin"].includes(user.role) && !!user.establishmentId && scope === user.establishmentId;
}

/** Clé « tout niveau » : publication sans restriction de classe. */
export const FLOW_AUDIENCE_ANY_LEVEL = "lvl:*";

/**
 * Clés d'audience indexables d'une publication Parcours.
 *
 * Elles forment un SUR-ENSEMBLE des élèves autorisés : la requête indexée
 * `array-contains-any` ne sert qu'à ne plus lire tout `flow_items` ; la
 * décision finale reste `audienceAllows`. Une clause sans niveau, ou une
 * publication historique sans niveau, vaut pour tous les niveaux.
 */
export function flowAudienceKeys(data: DocumentData): string[] {
  const keys = new Set<string>();
  const addLevels = (levels: unknown) => {
    const list = Array.isArray(levels)
      ? levels.filter((level): level is string => typeof level === "string" && level.trim().length > 0)
      : [];
    if (list.length === 0) keys.add(FLOW_AUDIENCE_ANY_LEVEL);
    for (const level of list) keys.add(`lvl:${canonicalClass(level)}`);
  };
  const parsed = data.audience !== undefined ? contentAudienceSchema.safeParse(data.audience) : null;
  if (parsed?.success) {
    for (const clause of parsed.data.clauses) addLevels(clause.classLevels);
  } else {
    addLevels(data.classLevels ?? (data.classLevel ? [data.classLevel] : []));
  }
  return [...keys].sort();
}

/** Clés à interroger pour un élève d'un niveau donné. */
export function learnerFlowAudienceKeys(classLevel: string): string[] {
  return [`lvl:${canonicalClass(classLevel)}`, FLOW_AUDIENCE_ANY_LEVEL];
}

/** Niveau canonique d'un élève, tel que `audienceAllows` le compare. */
export function learnAudienceContextClass(user: DocumentData, profile: DocumentData = {}): string {
  return user.role === "student" ? learnerAudienceContext(user, profile).classLevels : "";
}
