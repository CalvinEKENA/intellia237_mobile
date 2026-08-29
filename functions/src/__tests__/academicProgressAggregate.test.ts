import { describe, expect, it } from "vitest";

import {
  assertLessonProgressAuthorized,
  buildStudentProgressAggregate,
} from "../services/academicStateStore";
import { recordLessonProgressCallableInputSchema } from "../utils/validation";

describe("lesson progress authorization", () => {
  const command = {
    classLevel: "Terminale",
    subjectId: "math",
    chapterId: "algebra",
    lessonId: "equations",
  };
  const publishedLesson = {
    status: "published",
    classLevel: "Terminale",
    subjectId: "math",
    chapterId: "algebra",
    lessonId: "equations",
  };

  it("accepts a real published global lesson in the student's class", () => {
    expect(() => assertLessonProgressAuthorized({
      command,
      userData: { role: "student", classLevel: "Terminale" },
      lessonData: publishedLesson,
    })).not.toThrow();
  });

  it("rejects a foreign class, unpublished lesson and cross-school lesson", () => {
    expect(() => assertLessonProgressAuthorized({
      command,
      userData: { role: "student", classLevel: "Première" },
      lessonData: publishedLesson,
    })).toThrowError(expect.objectContaining({ code: "permission-denied" }));

    expect(() => assertLessonProgressAuthorized({
      command,
      userData: { role: "student", classLevel: "Terminale" },
      lessonData: { ...publishedLesson, status: "draft" },
    })).toThrowError(expect.objectContaining({ code: "not-found" }));

    expect(() => assertLessonProgressAuthorized({
      command,
      userData: {
        role: "student",
        classLevel: "Terminale",
        establishmentId: "school-a",
      },
      lessonData: { ...publishedLesson, establishmentId: "school-b" },
    })).toThrowError(expect.objectContaining({ code: "permission-denied" }));
  });

  it("rejects path injection in lesson identifiers", () => {
    expect(() => recordLessonProgressCallableInputSchema.parse({
      ...command,
      lessonId: "../foreign-lesson",
      progress: 0.5,
      clientEventId: "event_0001",
    })).toThrow();
  });
});

describe("student lesson progress aggregates", () => {
  it("computes global, subject and completion aggregates from canonical lesson state", () => {
    const aggregate = buildStudentProgressAggregate({
      lessons: [
        { subjectId: "math", progress: 0.5 },
        { subjectId: "math", progress: 1, isCompleted: true },
        { subjectId: "physics", progress: 0.2 },
      ],
      events: [],
      now: new Date("2026-07-16T12:00:00.000Z"),
    });

    expect(aggregate.trackedLessons).toBe(3);
    expect(aggregate.completedLessons).toBe(1);
    expect(aggregate.globalProgress).toBeCloseTo(1.7 / 3);
    expect(aggregate.subjectProgress.math).toBe(0.75);
    expect(aggregate.subjectProgress.physics).toBe(0.2);
    expect(aggregate.strongSubjects).toEqual(["math"]);
    expect(aggregate.weakSubjects).toEqual(["physics"]);
  });

  it("builds the weekly curve from positive progress deltas, not repeated snapshots", () => {
    const now = new Date("2026-07-16T12:00:00.000Z");
    const aggregate = buildStudentProgressAggregate({
      lessons: [
        { subjectId: "math", progress: 0.8 },
        { subjectId: "physics", progress: 0.6 },
      ],
      events: [
        {
          previousProgress: 0,
          progress: 0.4,
          updatedAt: new Date("2026-07-15T12:00:00.000Z"),
        },
        {
          previousProgress: 0.4,
          progress: 0.8,
          updatedAt: new Date("2026-07-16T09:00:00.000Z"),
        },
        {
          previousProgress: 0.8,
          progress: 0.2,
          updatedAt: new Date("2026-07-16T10:00:00.000Z"),
        },
      ],
      now,
    });

    expect(aggregate.weeklyProgress).toEqual([0, 0, 0, 0, 0, 0.2, 0.2]);
    expect(aggregate.weeklyProgressByDate).toEqual({
      "2026-07-15": 0.2,
      "2026-07-16": 0.2,
    });
    expect(aggregate.lastProgressActivityAt?.toISOString()).toBe(
      "2026-07-16T09:00:00.000Z",
    );
  });

  it("is deterministic when an idempotent retry repairs derived state", () => {
    const input = {
      lessons: [{ subjectId: "svt", progress: 0.75 }],
      events: [{
        previousProgress: 0.25,
        progress: 0.75,
        updatedAt: new Date("2026-07-16T08:00:00.000Z"),
      }],
      now: new Date("2026-07-16T12:00:00.000Z"),
    };

    expect(buildStudentProgressAggregate(input)).toEqual(
      buildStudentProgressAggregate(input),
    );
  });
});
