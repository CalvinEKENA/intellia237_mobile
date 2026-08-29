import { describe, expect, it } from "vitest";

import { FLOW_CATALOG } from "../services/flowCatalog";
import {
  FLOW_DAILY_POINTS_CAP,
  createSubmitFlowActivityHandler,
  evaluateFlowActivity,
  flowDocumentId,
  flowRequestHash,
  idempotentFlowReplay,
  type FlowActivityCommand,
  type FlowActivityResult,
  type FlowPointsStore
} from "../services/flowPointsCallable";

describe("secure FLOW points", () => {
  it("keeps a finite server allowlist with bounded rewards", () => {
    expect(Object.keys(FLOW_CATALOG)).toHaveLength(49);
    expect(Object.values(FLOW_CATALOG).every((item) =>
      Number.isInteger(item.pointsReward) && item.pointsReward >= 0 && item.pointsReward <= 25
    )).toBe(true);
    expect(FLOW_DAILY_POINTS_CAP).toBe(400);
  });

  it("scores choice, text, boolean and ordering answers on the server", () => {
    expect(evaluateFlowActivity({
      cardId: "math-equation-1",
      kind: "choice",
      answer: 1
    })).toEqual({ correct: true, pointsReward: 25 });
    expect(evaluateFlowActivity({
      cardId: "fill-fr-author",
      kind: "text",
      answer: "  MÔNGO   BETI "
    }).correct).toBe(true);
    expect(evaluateFlowActivity({
      cardId: "tf-hg-capital",
      kind: "boolean",
      answer: false
    }).correct).toBe(true);
    expect(evaluateFlowActivity({
      cardId: "order-hg-cameroon",
      kind: "ordering",
      answer: [
        "Indépendance du Cameroun oriental — 1960",
        "Réunification — 1961",
        "État unitaire — 1972"
      ]
    }).correct).toBe(true);
  });

  it("rejects unknown cards and kind substitution", () => {
    expect(() => evaluateFlowActivity({
      cardId: "attacker-card",
      kind: "content",
      answer: null
    })).toThrowError(expect.objectContaining({ code: "not-found" }));
    expect(() => evaluateFlowActivity({
      cardId: "math-equation-1",
      kind: "content",
      answer: null
    })).toThrowError(expect.objectContaining({ code: "invalid-argument" }));
  });

  it("requires authentication and rejects client-authored reward fields", async () => {
    const handler = createSubmitFlowActivityHandler(new MemoryFlowPointsStore());
    const valid = {
      clientEventId: "flow_12345678",
      cardId: "math-equation-1",
      kind: "choice",
      answer: 1
    };
    await expect(handler({ data: valid } as never)).rejects.toMatchObject({
      code: "unauthenticated"
    });
    await expect(handler({
      auth: { uid: "student-a" },
      data: { ...valid, pointsReward: 999999 }
    } as never)).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("preserves idempotent results and rejects event-id payload reuse", () => {
    const command = {
      cardId: "math-equation-1",
      kind: "choice" as const,
      answer: 1
    };
    const hash = flowRequestHash(command);
    const stored: FlowActivityResult = {
      clientEventId: "event-1",
      cardId: command.cardId,
      correct: true,
      pointsAwarded: 25,
      totalPoints: 125,
      alreadyCompleted: false,
      dailyCapReached: false,
      idempotentReplay: false
    };
    expect(idempotentFlowReplay({ requestHash: hash, result: stored }, hash))
      .toMatchObject({
        pointsAwarded: 25,
        totalPoints: 125,
        idempotentReplay: true
      });
    expect(() => idempotentFlowReplay(
      { requestHash: hash, result: stored },
      flowRequestHash({ ...command, answer: 0 })
    )).toThrowError(expect.objectContaining({ code: "already-exists" }));
  });

  it("uses collision-safe document identifiers across students", () => {
    expect(flowDocumentId("student_a", "event_b"))
      .not.toBe(flowDocumentId("student", "a_event_b"));
    expect(flowDocumentId("student-a", "event-a")).toMatch(/^[a-f0-9]{64}$/);
  });
});

class MemoryFlowPointsStore implements FlowPointsStore {
  async submit(command: FlowActivityCommand): Promise<FlowActivityResult> {
    const evaluation = evaluateFlowActivity(command);
    return {
      clientEventId: command.clientEventId,
      cardId: command.cardId,
      correct: evaluation.correct,
      pointsAwarded: evaluation.correct ? evaluation.pointsReward : 0,
      totalPoints: evaluation.correct ? evaluation.pointsReward : 0,
      alreadyCompleted: false,
      dailyCapReached: false,
      idempotentReplay: false
    };
  }
}
