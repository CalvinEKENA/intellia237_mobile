import { describe, expect, it } from "vitest";

import {
  generateQuizCallableInputSchema,
  generateSummaryCallableInputSchema
} from "../utils/validation";

describe("callable input validation", () => {
  it("accepts valid quiz input", () => {
    const parsed = generateQuizCallableInputSchema.parse({
      courseId: "course_demo_sciences_001",
      count: 5,
      difficulty: "medium"
    });

    expect(parsed.count).toBe(5);
  });

  it("rejects invalid quiz difficulty", () => {
    expect(() =>
      generateQuizCallableInputSchema.parse({
        courseId: "course_demo_sciences_001",
        count: 5,
        difficulty: "free-form"
      })
    ).toThrow();
  });

  it("accepts valid summary input", () => {
    const parsed = generateSummaryCallableInputSchema.parse({
      courseId: "course_demo_sciences_001",
      level: "standard"
    });

    expect(parsed.level).toBe("standard");
  });
});
