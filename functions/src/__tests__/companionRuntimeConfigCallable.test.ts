import { describe, expect, it, vi } from "vitest";
import type { CallableRequest } from "firebase-functions/v2/https";
import type { Firestore } from "firebase-admin/firestore";

import { createGetCompanionRuntimeConfigHandler } from "../services/companionRuntimeConfigCallable";
import { getEnv } from "../config/env";
import { AskTutorUseCase, type TutorContextStore } from "../services/askTutorUseCase";
import {
  StudyReserveConsumption,
  type ReserveHold,
  type StudyReserveConsumptionStore,
  type ThresholdNotifier,
} from "../services/studyReserveConsumption";
import type {
  StudyReserveProvisioningStore,
} from "../services/studyReserveProvisioning";
import type { TutorQuotaSnapshot, TutorQuotaStore } from "../services/tutorDailyQuota";

function mockFirestore(userData?: { role: string; accountStatus?: string }): Firestore {
  return {
    collection: (_coll: string) => ({
      doc: (_id: string) => ({
        get: async () => ({
          exists: userData !== undefined,
          data: () => userData,
        }),
      }),
    }),
  } as unknown as Firestore;
}

class MockQuotaStore implements TutorQuotaStore {
  async reserve(): Promise<TutorQuotaSnapshot> {
    return { limit: 20, remaining: 19, resetsAt: "2026-09-16T00:00:00.000Z" };
  }
  async consume(): Promise<TutorQuotaSnapshot> {
    return { limit: 20, remaining: 19, resetsAt: "2026-09-16T00:00:00.000Z" };
  }
  async release(): Promise<void> {}
}

class MockConsumptionStore implements StudyReserveConsumptionStore {
  async reserve(): Promise<ReserveHold> {
    return { configured: false, reserved: false };
  }
  async commit() {
    return { duplicate: false, thresholdEvent: null, cycleId: "" };
  }
  async release(): Promise<void> {}
  async listLinkedParents(): Promise<string[]> {
    return [];
  }
}

class MockNotifier implements ThresholdNotifier {
  async emit(): Promise<void> {}
}

class MockProvisioningStore implements StudyReserveProvisioningStore {
  async resolveEntitlement() { return null; }
  async planConfig() { return null; }
  async updateCurrentCycle() { return null; }
  async readAggregate() { return null; }
  async provisionCycle(_id: string, fresh: any) { return fresh; }
}

describe("Companion runtime configuration callable & policy", () => {
  it("rejects unauthenticated requests", async () => {
    const handler = createGetCompanionRuntimeConfigHandler(mockFirestore());
    const request = { auth: undefined } as CallableRequest<unknown>;

    await expect(handler(request)).rejects.toThrowError(/Authentication is required/);
  });

  it("rejects non-superAdmin roles (e.g. admin, student, teacher)", async () => {
    const handler = createGetCompanionRuntimeConfigHandler(
      mockFirestore({ role: "admin", accountStatus: "active" }),
    );
    const request = { auth: { uid: "admin-1" } } as CallableRequest<unknown>;

    await expect(handler(request)).rejects.toThrowError(/SuperAdmin access is required/);
  });

  it("rejects inactive superAdmin accounts", async () => {
    const handler = createGetCompanionRuntimeConfigHandler(
      mockFirestore({ role: "superAdmin", accountStatus: "suspended" }),
    );
    const request = { auth: { uid: "super-1" } } as CallableRequest<unknown>;

    await expect(handler(request)).rejects.toThrowError(/SuperAdmin access is required/);
  });

  it("returns safe, non-secret metadata for active superAdmin", async () => {
    const handler = createGetCompanionRuntimeConfigHandler(
      mockFirestore({ role: "superAdmin", accountStatus: "active" }),
    );
    const request = { auth: { uid: "super-1" } } as CallableRequest<unknown>;

    const result = await handler(request);

    const { companions, budget, ...metadata } = result;
    expect(metadata).toEqual({
      provider: "vertex-ai",
      model: "gemini-3.8-flash",
      tutorThinkingLevel: "HIGH",
      structuredThinkingLevel: "MEDIUM",
      location: "global",
      configured: expect.any(Boolean),
    });

    // Studio reçoit la spécification réellement envoyée au modèle.
    expect(companions.map((companion) => companion.id)).toEqual(["kira", "leo"]);
    expect(companions[0].safety.fr.length).toBeGreaterThan(5);
    expect(budget).toEqual({
      maxHistoryMessages: 8,
      maxTotalInputChars: 22000,
      maxInputTokensWorstCase: 22000,
      maxOutputTokens: 8192,
    });

    // Zero secrets / sensitive tokens exposed in the runtime metadata.
    const serialized = JSON.stringify(metadata);
    expect(serialized).not.toContain("key");
    expect(serialized).not.toContain("token");
    expect(serialized).not.toContain("secret");
    expect(serialized).not.toContain("password");
    expect(serialized).not.toContain("credential");
    expect(serialized).not.toContain("private");
    // The published specification is product copy, never configuration.
    const specification = JSON.stringify({ companions, budget });
    expect(specification).not.toMatch(/AIza|BEGIN PRIVATE KEY|client_email|VERTEX_AI_PROJECT_ID/);
  });

  it("supports super_admin variant alias role", async () => {
    const handler = createGetCompanionRuntimeConfigHandler(
      mockFirestore({ role: "super_admin", accountStatus: "active" }),
    );
    const request = { auth: { uid: "super-2" } } as CallableRequest<unknown>;

    const result = await handler(request);
    expect(result.model).toBe("gemini-3.8-flash");
    expect(result.tutorThinkingLevel).toBe("HIGH");
  });

  it("verifies Kira and Léo both route with the same model policy in AskTutorUseCase", async () => {
    const env = getEnv();
    expect(env.GEMINI_MODEL).toBe("gemini-3.8-flash");
    expect(env.GEMINI_TUTOR_THINKING_LEVEL).toBe("HIGH");

    const contextStore: TutorContextStore = {
      async loadAuthorizedContext() {
        return {
          scope: { classLevel: "Terminale", series: "C", establishmentId: "school-1" },
          text: "Chapitre 1: Ondes et corpuscules.",
        };
      },
    };

    const capturedCalls: Array<{ operation: string; system: string; prompt: string }> = [];
    const textGenerator = async (params: {
      operation: "askTutor";
      correlationId: string;
      system: string;
      prompt: string;
    }) => {
      capturedCalls.push({
        operation: params.operation,
        system: params.system,
        prompt: params.prompt,
      });
      return "Explication claire.";
    };

    const studyReserve = new StudyReserveConsumption(
      new MockConsumptionStore(),
      new MockNotifier(),
      new MockProvisioningStore(),
    );

    const useCase = new AskTutorUseCase(
      contextStore,
      textGenerator,
      new MockQuotaStore(),
      20,
      studyReserve,
    );

    // Call with Kira
    const kiraResult = await useCase.execute({
      userId: "student-1",
      traceId: "trace-kira",
      input: {
        userMessage: "Aide-moi avec les ondes",
        classLevel: "Terminale",
        history: [],
        tutorId: "kira",
      },
    });

    // Call with Léo
    const leoResult = await useCase.execute({
      userId: "student-1",
      traceId: "trace-leo",
      input: {
        userMessage: "Donne-moi un défi sur les ondes",
        classLevel: "Terminale",
        history: [],
        tutorId: "leo",
      },
    });

    expect(kiraResult.text).toBe("Explication claire.");
    expect(leoResult.text).toBe("Explication claire.");
    expect(capturedCalls).toHaveLength(2);

    // Both use the same operation "askTutor"
    expect(capturedCalls[0].operation).toBe("askTutor");
    expect(capturedCalls[1].operation).toBe("askTutor");

    // Each companion gets its server-owned persona, never client text.
    expect(capturedCalls[0].system).toContain("Tu es Kira");
    expect(capturedCalls[0].system).toContain("Patiente, calme et explicative.");
    expect(capturedCalls[1].system).toContain("Tu es Léo");
    expect(capturedCalls[1].system).toContain("Dynamique, exigeant et constructif.");
  });
});
