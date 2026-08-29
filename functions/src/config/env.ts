import { z } from "zod";

const thinkingLevelSchema = z.enum(["LOW", "MEDIUM", "HIGH"]);
const localStorageBucket = "intellia237-local.firebasestorage.app";
const productionProjectId = "edunova-aabd1";
const stagingProjectId = "intellia237-staging";

const envSchema = z.object({
  FUNCTIONS_REGION: z.string().min(1).default("europe-west1"),
  APP_STORAGE_BUCKET: z.string().trim().min(1).default(localStorageBucket),
  LLM_SERVICE_TIMEOUT_MS: z.coerce.number().int().min(1000).max(120000).default(45000),
  VERTEX_AI_PROJECT_ID: z.string().trim().min(1).optional(),
  VERTEX_AI_LOCATION: z.string().trim().min(1).default("global"),
  GEMINI_MODEL: z.string().trim().min(1).default("gemini-3.7-flash"),
  GEMINI_TUTOR_THINKING_LEVEL: thinkingLevelSchema.default("LOW"),
  GEMINI_STRUCTURED_THINKING_LEVEL: thinkingLevelSchema.default("MEDIUM"),
  MAX_COURSE_IMAGES: z.coerce.number().int().min(0).max(20).default(8),
  TUTOR_DAILY_QUESTION_LIMIT: z.coerce.number().int().min(1).max(200).default(20),
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

export function getEnv(): AppEnv {
  if (cachedEnv) {
    return cachedEnv;
  }

  const result = envSchema.safeParse(runtimeEnvironment());

  if (!result.success) {
    const issues = result.error.issues
      .map((issue) => `${issue.path.join(".")}: ${issue.message}`)
      .join("; ");
    console.warn(`[WATCHDOG] Environment validation issues (Functions might fail at runtime): ${issues}`);
    // Keep discovery/test commands usable while preserving safe defaults.
    return envSchema.parse({});
  }

  assertEnvironmentIsolation(result.data);
  cachedEnv = result.data;
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
