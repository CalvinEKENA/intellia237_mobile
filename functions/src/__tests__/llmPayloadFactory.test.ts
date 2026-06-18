import { describe, expect, it } from "vitest";

import type { CourseImageRecord, CourseRecord } from "../models/course";
import { buildQuizLlmRequest, buildSummaryLlmRequest } from "../services/llmPayloadFactory";

const course: CourseRecord = {
  id: "course_demo_sciences_001",
  title: "La photosynthese",
  subject: "SVT",
  gradeLevel: "3eme",
  language: "fr",
  status: "published",
  learningObjectives: ["Comprendre la photosynthese"],
  tags: ["plante"],
  contentSections: [
    {
      title: "Definition",
      body: "La photosynthese permet aux plantes de produire du glucose."
    }
  ],
  imageRefs: ["img_1"],
  source: {
    type: "teacher-authored",
    version: 1
  }
};

const images: CourseImageRecord[] = [
  {
    id: "img_1",
    fileName: "schema.png",
    storagePath: "courses/course_demo_sciences_001/images/schema.png",
    caption: "Schema de la feuille",
    ocrText: "CO2 + H2O -> glucose + O2"
  }
];

describe("llm payload factory", () => {
  it("builds a quiz request from course context only", () => {
    const payload = buildQuizLlmRequest({
      traceId: "1fb2c3da-1111-4ccd-99f0-f7f8e13e4c31",
      requesterUid: "user-123",
      course,
      images,
      difficulty: "medium",
      count: 4
    });

    expect(payload.course.id).toBe(course.id);
    expect(payload.course.images[0]?.storagePath).toContain("courses/");
    expect(payload.count).toBe(4);
  });

  it("builds a summary request with sanitized content", () => {
    const payload = buildSummaryLlmRequest({
      traceId: "1fb2c3da-1111-4ccd-99f0-f7f8e13e4c31",
      requesterUid: "user-123",
      course,
      images,
      level: "basic"
    });

    expect(payload.level).toBe("basic");
    expect(payload.course.contentSections).toHaveLength(1);
  });
});
