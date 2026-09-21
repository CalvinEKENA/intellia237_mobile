import type { CallableRequest } from "firebase-functions/v2/https";
import { HttpsError } from "firebase-functions/v2/https";
import type { Firestore } from "firebase-admin/firestore";

import { getEnv } from "../config/env";
import { db } from "../config/firebase";
import {
  MAX_HISTORY_MESSAGES,
  MAX_INPUT_TOKENS_WORST_CASE,
  MAX_TOTAL_INPUT_CHARS,
  MAX_TUTOR_OUTPUT_TOKENS,
} from "../llm/tutorBudget";
import { tutorPersonaSpecification } from "../llm/tutorPersonas";

export interface CompanionRuntimeConfigView {
  provider: "vertex-ai";
  model: string;
  tutorThinkingLevel: "LOW" | "MEDIUM" | "HIGH";
  structuredThinkingLevel: "LOW" | "MEDIUM" | "HIGH";
  location: string;
  configured: boolean;
  /** Spécification réellement envoyée au modèle (persona, règles, garde-fous). */
  companions: ReturnType<typeof tutorPersonaSpecification>;
  budget: {
    maxHistoryMessages: number;
    maxTotalInputChars: number;
    maxInputTokensWorstCase: number;
    maxOutputTokens: number;
  };
}

export function createGetCompanionRuntimeConfigHandler(
  firestore: Firestore = db,
) {
  return async (
    request: CallableRequest<unknown>,
  ): Promise<CompanionRuntimeConfigView> => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Authentication is required.");
    }

    const userSnapshot = await firestore.collection("users").doc(uid).get();
    const data = userSnapshot.data();

    if (
      !data ||
      !["superAdmin", "super_admin"].includes(data.role) ||
      (data.accountStatus && data.accountStatus !== "active")
    ) {
      throw new HttpsError(
        "permission-denied",
        "SuperAdmin access is required to view runtime AI configuration.",
      );
    }

    const env = getEnv();
    const isConfigured = Boolean(
      env.VERTEX_AI_PROJECT_ID?.trim() && env.GEMINI_MODEL.trim(),
    );

    // Return strictly safe, non-secret metadata. Never expose secrets, API keys,
    // access tokens, service accounts, or raw environment variables.
    return {
      provider: "vertex-ai",
      model: env.GEMINI_MODEL,
      tutorThinkingLevel: env.GEMINI_TUTOR_THINKING_LEVEL,
      structuredThinkingLevel: env.GEMINI_STRUCTURED_THINKING_LEVEL,
      location: env.VERTEX_AI_LOCATION,
      configured: isConfigured,
      companions: tutorPersonaSpecification(),
      budget: {
        maxHistoryMessages: MAX_HISTORY_MESSAGES,
        maxTotalInputChars: MAX_TOTAL_INPUT_CHARS,
        maxInputTokensWorstCase: MAX_INPUT_TOKENS_WORST_CASE,
        maxOutputTokens: MAX_TUTOR_OUTPUT_TOKENS,
      },
    };
  };
}

export const getCompanionRuntimeConfigHandler =
  createGetCompanionRuntimeConfigHandler();
