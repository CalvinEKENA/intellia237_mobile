import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";

import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

/**
 * Source de vérité des projets Firebase / Google Cloud :
 *   production = edunova-aabd1
 *   staging    = intellia237-staging
 *
 * assertEnvironmentIsolation (config/env.ts) ne protège que les projets
 * qu'elle reconnaît : si l'identifiant de production y était remplacé par un
 * autre, un runtime de production ne serait plus reconnu et la garde se
 * désactiverait sans bruit. Ces tests échouent dans ce cas, et quand une
 * configuration du dépôt cite un autre projet.
 */
const PRODUCTION = "edunova-aabd1";
const STAGING = "intellia237-staging";
const KNOWN = new Set([PRODUCTION, STAGING]);
const REPO = join(__dirname, "..", "..", "..");

describe("production and staging runtimes are both recognised", () => {
  const originalEnv = { ...process.env };

  beforeEach(() => {
    vi.resetModules();
    process.env = { ...originalEnv };
    for (const key of [
      "APP_STORAGE_BUCKET",
      "FIREBASE_CONFIG",
      "VERTEX_AI_PROJECT_ID",
      "GOOGLE_CLOUD_PROJECT",
      "GCLOUD_PROJECT",
    ]) {
      delete process.env[key];
    }
  });

  afterEach(() => {
    process.env = { ...originalEnv };
  });

  it("a production runtime refuses the staging Vertex project", async () => {
    process.env.GOOGLE_CLOUD_PROJECT = PRODUCTION;
    process.env.VERTEX_AI_PROJECT_ID = STAGING;
    const { getEnv } = await import("../config/env");
    expect(() => getEnv()).toThrow(/cross-environment Vertex AI/);
  });

  it("a production runtime refuses the staging bucket", async () => {
    process.env.GOOGLE_CLOUD_PROJECT = PRODUCTION;
    process.env.APP_STORAGE_BUCKET = `${STAGING}.firebasestorage.app`;
    const { getEnv } = await import("../config/env");
    expect(() => getEnv()).toThrow(/cross-environment Storage/);
  });

  it("a staging runtime refuses the production Vertex project", async () => {
    process.env.GOOGLE_CLOUD_PROJECT = STAGING;
    process.env.VERTEX_AI_PROJECT_ID = PRODUCTION;
    const { getEnv } = await import("../config/env");
    expect(() => getEnv()).toThrow(/cross-environment Vertex AI/);
  });
});

describe("repository configuration names only the two known projects", () => {
  it(".firebaserc maps production and staging to their project", () => {
    const aliases = JSON.parse(readFileSync(join(REPO, ".firebaserc"), "utf8")) as {
      projects: Record<string, string>;
    };
    expect(aliases.projects.production).toBe(PRODUCTION);
    expect(aliases.projects.default).toBe(PRODUCTION);
    expect(aliases.projects.staging).toBe(STAGING);
  });

  it("the mobile Firebase options use only the two known projects", () => {
    const options = readFileSync(join(REPO, "lib", "firebase_options.dart"), "utf8");
    const ids = [...options.matchAll(/projectId:\s*'([^']+)'/g)].map((match) => match[1]);
    expect(new Set(ids)).toEqual(KNOWN);
  });

  it("the Studio targets the production project only", () => {
    const ids = new Set<string>();
    const walk = (directory: string) => {
      for (const entry of readdirSync(directory)) {
        const path = join(directory, entry);
        if (statSync(path).isDirectory()) walk(path);
        else if (path.endsWith(".dart")) {
          const source = readFileSync(path, "utf8");
          for (const match of source.matchAll(/projectId\s*=\s*'([^']+)'/g)) ids.add(match[1]);
        }
      }
    };
    walk(join(REPO, "apps", "intellia_studio", "lib"));
    expect(ids.size).toBeGreaterThan(0);
    expect([...ids]).toEqual([PRODUCTION]);
  });
});
