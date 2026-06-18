import { z } from "zod";

const envSchema = z.object({
  FUNCTIONS_REGION: z.string().min(1).default("europe-west1"),
  APP_STORAGE_BUCKET: z.string().min(1).default("edunova-aabd1.firebasestorage.app"),
  LLM_SERVICE_TIMEOUT_MS: z.coerce.number().int().min(1000).max(120000).default(45000),
  GLM_API_KEY: z.string().min(1).optional(),
  GLM_MODEL: z.string().default("glm-5.1"),
  GLM_BASE_URL: z.string().url().default("https://api.z.ai/api/paas/v4"),
  MAX_COURSE_IMAGES: z.coerce.number().int().min(0).max(20).default(8),
  LOG_LEVEL: z.enum(["debug", "info", "warn", "error"]).default("info")
});

export type AppEnv = z.infer<typeof envSchema>;

let cachedEnv: AppEnv | null = null;

export function getEnv(): AppEnv {
  if (cachedEnv) {
    return cachedEnv;
  }

  const result = envSchema.safeParse(process.env);

  if (!result.success) {
    const issues = result.error.issues
      .map((issue) => `${issue.path.join(".")}: ${issue.message}`)
      .join("; ");
    console.warn(`[WATCHDOG] Environment validation issues (Functions might fail at runtime): ${issues}`);
    // We return the partial/default data anyway to let the discovery continue
    return envSchema.parse({});
  }

  cachedEnv = result.data;
  return cachedEnv;
}
