import { readFileSync } from "node:fs";
import { join } from "node:path";

export interface EmulatorAddress {
  host: string;
  port: number;
}

export type EmulatedService = "firestore" | "storage" | "auth" | "functions";

/**
 * Adresse d'un émulateur, telle que la CLI la déclare.
 *
 * Registre de décisions : aucun port n'est écrit en dur. `firebase
 * emulators:exec` exporte l'hôte et le port réellement ouverts — c'est la
 * seule source qui ne mente jamais — et `firebase.json` sert de repli quand
 * le test est lancé hors de la CLI.
 *
 * Le port par défaut de Firestore est 8080 ; ce projet l'a déplacé en 8085.
 * Un harnais qui présumait la valeur par défaut se connectait donc dans le
 * vide, et ses quinze cas étaient déclarés « skipped » au lieu d'échouer —
 * une couverture qui n'existait plus sans que rien ne le signale.
 */
export function resolveEmulatorAddress(
  service: EmulatedService,
  envVar: string,
  options: {
    env?: NodeJS.ProcessEnv;
    firebaseConfigPath?: string;
  } = {}
): EmulatorAddress {
  const env = options.env ?? process.env;
  const declared = env[envVar];

  if (declared && declared.trim().length > 0) {
    const address = parseHostPort(declared);
    if (address) return address;
  }

  const configPath =
    options.firebaseConfigPath ?? join(process.cwd(), "../firebase.json");
  const config = JSON.parse(readFileSync(configPath, "utf8")) as {
    emulators?: Record<string, { port?: number } | undefined>;
  };
  const port = config.emulators?.[service]?.port;

  if (typeof port !== "number") {
    throw new Error(
      `Port introuvable pour l'émulateur ${service} : ni ${envVar} ni ` +
        `${configPath} ne le déclarent.`
    );
  }
  return { host: "127.0.0.1", port };
}

/** Accepte `host:port` comme `http://host:port`. */
function parseHostPort(value: string): EmulatorAddress | null {
  const cleaned = value.trim().replace(/^https?:\/\//, "").replace(/\/+$/, "");
  const separator = cleaned.lastIndexOf(":");
  if (separator <= 0) return null;

  const host = cleaned.slice(0, separator);
  const port = Number(cleaned.slice(separator + 1));
  if (!host || !Number.isInteger(port) || port <= 0) return null;

  return { host, port };
}
