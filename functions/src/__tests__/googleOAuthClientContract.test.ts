import { readFileSync } from "node:fs";
import { join } from "node:path";

import { describe, expect, it } from "vitest";

/**
 * La sonde Google n'accepte que les jetons dont l'audience figure dans
 * GOOGLE_OAUTH_CLIENT_IDS. Sur Android, cette audience est le client OAuth
 * Web lu dans google-services.json : les deux fichiers doivent désigner le
 * même client, sinon « Continuer avec Google » échoue pour tout le monde.
 */
describe("production Google OAuth client", () => {
  const root = join(__dirname, "..", "..", "..");
  const servicesJson = JSON.parse(
    readFileSync(join(root, "android", "app", "google-services.json"), "utf8"),
  ) as {
    project_info: { project_id: string };
    client: Array<{
      client_info: { android_client_info: { package_name: string } };
      oauth_client?: Array<{ client_id: string; client_type: number }>;
    }>;
  };
  const env = readFileSync(join(root, "functions", ".env.edunova-aabd1"), "utf8");
  const configured = (/^GOOGLE_OAUTH_CLIENT_IDS=(.*)$/m.exec(env)?.[1] ?? "")
    .split(",")
    .map((id) => id.trim())
    .filter(Boolean);

  const app = servicesJson.client.find(
    (client) => client.client_info.android_client_info.package_name === "com.edunova.app",
  );

  it("targets the production project and package", () => {
    expect(servicesJson.project_info.project_id).toBe("edunova-aabd1");
    expect(app).toBeDefined();
  });

  it("declares Android and Web OAuth clients for com.edunova.app", () => {
    const types = (app?.oauth_client ?? []).map((client) => client.client_type);
    expect(types).toContain(1);
    expect(types).toContain(3);
  });

  it("accepts on the server the Web client the app signs in with", () => {
    const web = (app?.oauth_client ?? []).filter((client) => client.client_type === 3);
    expect(web.length).toBeGreaterThan(0);
    for (const client of web) expect(configured).toContain(client.client_id);
  });
});
