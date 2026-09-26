import { z } from "zod";

const thinkingLevelSchema = z.enum(["LOW", "MEDIUM", "HIGH"]);
const booleanEnvironmentSchema = z.preprocess(
  (value) => {
    if (typeof value !== "string") return value;
    const normalized = value.trim().toLowerCase();
    if (normalized === "true") return true;
    if (normalized === "false") return false;
    return value;
  },
  z.boolean(),
);
const localStorageBucket = "intellia237-local.firebasestorage.app";
const productionProjectId = "edunova-aabd1";
const stagingProjectId = "intellia237-staging";

const envSchema = z.object({
  FUNCTIONS_REGION: z.string().min(1).default("europe-west1"),
  ENFORCE_APP_CHECK: booleanEnvironmentSchema.default(false),
  APP_STORAGE_BUCKET: z.string().trim().min(1).default(localStorageBucket),
  LLM_SERVICE_TIMEOUT_MS: z.coerce.number().int().min(1000).max(120000).default(45000),
  VERTEX_AI_PROJECT_ID: z.string().trim().min(1).optional(),
  VERTEX_AI_LOCATION: z.string().trim().min(1).default("global"),
  GEMINI_MODEL: z.string().trim().min(1).default("gemini-3.8-flash"),
  GEMINI_TUTOR_THINKING_LEVEL: thinkingLevelSchema.default("HIGH"),
  GEMINI_STRUCTURED_THINKING_LEVEL: thinkingLevelSchema.default("MEDIUM"),
  MAX_COURSE_IMAGES: z.coerce.number().int().min(0).max(20).default(8),
  TUTOR_DAILY_QUESTION_LIMIT: z.coerce.number().int().min(1).max(200).default(20),
  // Lecture Parcours par clé d'audience indexée. Reste désactivée tant que
  // l'index composite n'est pas déployé et que scripts/backfillFlowAudienceKeys
  // n'a pas été appliqué aux publications existantes.
  FLOW_AUDIENCE_INDEX: booleanEnvironmentSchema.default(false),
  // Clients OAuth (Web) dont les jetons Google sont acceptés par la sonde
  // d'identité Google, séparés par des virgules. Vide : Google refusé.
  GOOGLE_OAUTH_CLIENT_IDS: z.string().trim().default(""),
  LOG_LEVEL: z.enum(["debug", "info", "warn", "error"]).default("info")
});

export type AppEnv = z.infer<typeof envSchema>;

let cachedEnv: AppEnv | null = null;

function runtimeEnvironment(): NodeJS.ProcessEnv {
  const runtimeProjectId = firstNonBlank(
    process.env.GOOGLE_CLOUD_PROJECT,
    process.env.GCLOUD_PROJECT,
  );
  const configuredStorageBucket = firstNonBlank(
    process.env.APP_STORAGE_BUCKET,
    firebaseConfigStorageBucket(process.env.FIREBASE_CONFIG),
    runtimeProjectId ? `${runtimeProjectId}.firebasestorage.app` : undefined,
  );

  return {
    ...process.env,
    APP_STORAGE_BUCKET: configuredStorageBucket,
    VERTEX_AI_PROJECT_ID: firstNonBlank(
      process.env.VERTEX_AI_PROJECT_ID,
      runtimeProjectId,
    ),
  };
}

/**
 * Mode d'exécution :
 * - `deployed` : runtime Cloud Functions/Cloud Run d'un projet applicatif, ou
 *   analyse du code par `firebase deploy` (même variables de projet) ;
 * - `local` : tests, émulateur, scripts hors Google Cloud.
 */
export type EnvironmentMode = "deployed" | "local";

export function environmentMode(source: NodeJS.ProcessEnv = process.env): EnvironmentMode {
  if (source.FUNCTIONS_EMULATOR === "true") return "local";
  if (source.VITEST !== undefined || source.NODE_ENV === "test") return "local";
  const runtimeProjectId = firstNonBlank(source.GOOGLE_CLOUD_PROJECT, source.GCLOUD_PROJECT);
  if (runtimeProjectId && isApplicationProject(runtimeProjectId)) return "deployed";
  if (source.K_SERVICE || source.FUNCTION_TARGET) return "deployed";
  return "local";
}

/**
 * Raisons d'une configuration invalide : noms de variables et codes de
 * validation uniquement. Jamais de valeur — une variable peut porter un
 * secret, et un message d'erreur finit dans les journaux.
 */
function describeIssues(issues: readonly z.ZodIssue[]): string {
  return issues
    .map((issue) => `${issue.path.join(".") || "(root)"}: ${issue.code}`)
    .join("; ");
}

/**
 * Lit et valide l'environnement.
 *
 * En local, une configuration invalide retombe sur des valeurs sûres et non
 * productives, avec un avertissement. En production, elle fait échouer le
 * chargement du code : `firebase deploy` s'arrête, et une instance ne démarre
 * jamais avec le bucket local ou un projet Vertex vide.
 */
export function parseEnvironment(
  source: NodeJS.ProcessEnv,
  mode: EnvironmentMode,
): AppEnv {
  const result = envSchema.safeParse(source);
  if (!result.success) {
    const reasons = describeIssues(result.error.issues);
    if (mode === "deployed") {
      throw new Error(`Invalid Functions configuration: ${reasons}.`);
    }
    console.warn(`[WATCHDOG] Local Functions configuration is invalid (${reasons}); using safe local defaults.`);
    return envSchema.parse({});
  }
  if (mode === "deployed") {
    const missing: string[] = [];
    if (!result.data.VERTEX_AI_PROJECT_ID) missing.push("VERTEX_AI_PROJECT_ID");
    if (result.data.APP_STORAGE_BUCKET === localStorageBucket) missing.push("APP_STORAGE_BUCKET");
    if (missing.length > 0) {
      throw new Error(`Incomplete Functions configuration: ${missing.join(", ")} unresolved.`);
    }
  }
  return result.data;
}

export function getEnv(): AppEnv {
  if (cachedEnv) {
    return cachedEnv;
  }
  const source = runtimeEnvironment();
  const env = parseEnvironment(source, environmentMode(process.env));
  assertEnvironmentIsolation(env);
  cachedEnv = env;
  return cachedEnv;
}

function assertEnvironmentIsolation(env: AppEnv): void {
  const runtimeProjectId = firstNonBlank(
    process.env.GOOGLE_CLOUD_PROJECT,
    process.env.GCLOUD_PROJECT,
  );
  if (!runtimeProjectId || !isApplicationProject(runtimeProjectId)) return;

  const vertexProjectId = env.VERTEX_AI_PROJECT_ID;
  if (
    vertexProjectId &&
    isApplicationProject(vertexProjectId) &&
    vertexProjectId !== runtimeProjectId
  ) {
    throw new Error(
      `Refusing cross-environment Vertex AI configuration: runtime ${runtimeProjectId}, Vertex ${vertexProjectId}.`,
    );
  }

  const oppositeBucket = runtimeProjectId === productionProjectId
    ? `${stagingProjectId}.firebasestorage.app`
    : `${productionProjectId}.firebasestorage.app`;
  if (env.APP_STORAGE_BUCKET === oppositeBucket) {
    throw new Error(
      `Refusing cross-environment Storage configuration for runtime ${runtimeProjectId}.`,
    );
  }
}

function isApplicationProject(value: string): boolean {
  return value === productionProjectId || value === stagingProjectId;
}

function firstNonBlank(...values: Array<string | undefined>): string | undefined {
  for (const value of values) {
    const normalized = value?.trim();
    if (normalized) return normalized;
  }
  return undefined;
}

function firebaseConfigStorageBucket(value: string | undefined): string | undefined {
  if (!value?.trim().startsWith("{")) return undefined;
  try {
    const parsed = JSON.parse(value) as { storageBucket?: unknown };
    return typeof parsed.storageBucket === "string"
      ? parsed.storageBucket
      : undefined;
  } catch {
    return undefined;
  }
}
