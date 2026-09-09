import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { resolveEmulatorAddress } from "./rules/emulator-address";

/**
 * Le harnais des règles se connectait au port Firestore par défaut (8080)
 * alors que ce projet l'a déplacé en 8085. `initializeTestEnvironment()`
 * échouait sur ECONNREFUSED, et les quinze cas étaient déclarés « skipped »
 * plutôt qu'en échec : une couverture disparue en silence.
 *
 * La résolution de port se teste donc seule, sans émulateur — c'est
 * précisément la pièce qui avait cédé.
 */
function firebaseConfig(emulators: Record<string, unknown>): string {
  const directory = mkdtempSync(join(tmpdir(), "intellia-emulators-"));
  const path = join(directory, "firebase.json");
  writeFileSync(path, JSON.stringify({ emulators }), "utf8");
  return path;
}

describe("resolveEmulatorAddress", () => {
  const config = () =>
    firebaseConfig({ firestore: { port: 8085 }, storage: { port: 9200 } });

  it("prefers the address exported by the CLI", () => {
    const address = resolveEmulatorAddress(
      "firestore",
      "FIRESTORE_EMULATOR_HOST",
      {
        env: { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8085" },
        firebaseConfigPath: config()
      }
    );

    expect(address).toEqual({ host: "127.0.0.1", port: 8085 });
  });

  it("accepts an address carrying its scheme", () => {
    // `STORAGE_EMULATOR_HOST` est exporté sous la forme `http://host:port`.
    const address = resolveEmulatorAddress(
      "storage",
      "FIREBASE_STORAGE_EMULATOR_HOST",
      {
        env: { FIREBASE_STORAGE_EMULATOR_HOST: "http://127.0.0.1:9200" },
        firebaseConfigPath: config()
      }
    );

    expect(address).toEqual({ host: "127.0.0.1", port: 9200 });
  });

  it("falls back to firebase.json, never to a default port", () => {
    // C'est exactement le cas qui cassait : hors CLI, il faut lire le port
    // du projet — 8085 — et surtout pas présumer 8080.
    const address = resolveEmulatorAddress(
      "firestore",
      "FIRESTORE_EMULATOR_HOST",
      { env: {}, firebaseConfigPath: config() }
    );

    expect(address).toEqual({ host: "127.0.0.1", port: 8085 });
    expect(address.port).not.toBe(8080);
  });

  it("ignores an empty variable and falls back", () => {
    const address = resolveEmulatorAddress(
      "storage",
      "FIREBASE_STORAGE_EMULATOR_HOST",
      {
        env: { FIREBASE_STORAGE_EMULATOR_HOST: "   " },
        firebaseConfigPath: config()
      }
    );

    expect(address.port).toBe(9200);
  });

  it("ignores a malformed variable and falls back", () => {
    const address = resolveEmulatorAddress(
      "firestore",
      "FIRESTORE_EMULATOR_HOST",
      {
        env: { FIRESTORE_EMULATOR_HOST: "pas-une-adresse" },
        firebaseConfigPath: config()
      }
    );

    expect(address.port).toBe(8085);
  });

  it("reports a missing port instead of guessing one", () => {
    expect(() =>
      resolveEmulatorAddress("firestore", "FIRESTORE_EMULATOR_HOST", {
        env: {},
        firebaseConfigPath: firebaseConfig({ storage: { port: 9200 } })
      })
    ).toThrowError(/Port introuvable/);
  });

  it("resolves the real project configuration", () => {
    // Garde-fou contre une dérive entre firebase.json et le harnais.
    const address = resolveEmulatorAddress(
      "firestore",
      "FIRESTORE_EMULATOR_HOST",
      { env: {}, firebaseConfigPath: join(process.cwd(), "../firebase.json") }
    );

    expect(address.port).toBe(8085);
  });
});
