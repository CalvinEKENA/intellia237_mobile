import type { CourseImageRecord, CourseRecord } from "../models/course";
import type { GenerateQuizRequest, GenerateSummaryRequest } from "../llm/schemas";

const MAX_SECTION_BODY_LENGTH = 2400;
const MAX_IMAGE_TEXT_LENGTH = 800;

function compactText(value: string, maxLength: number): string {
  const collapsed = value.replace(/\s+/g, " ").trim();
  if (collapsed.length <= maxLength) {
    return collapsed;
  }

  return `${collapsed.slice(0, maxLength - 1).trim()}...`;
}

function buildCourseContext(course: CourseRecord, images: CourseImageRecord[]) {
  return {
    id: course.id,
    title: course.title,
    subject: course.subject,
    gradeLevel: course.gradeLevel,
    language: course.language,
    learningObjectives: course.learningObjectives.slice(0, 8),
    tags: course.tags.slice(0, 10),
    contentSections: course.contentSections.slice(0, 12).map((section) => ({
      title: compactText(section.title, 120),
      body: compactText(section.body, MAX_SECTION_BODY_LENGTH)
    })),
    images: images.map((image) => ({
      id: image.id,
      fileName: image.fileName,
      storagePath: image.storagePath,
      contentType: image.contentType,
      caption: image.caption ? compactText(image.caption, MAX_IMAGE_TEXT_LENGTH) : undefined,
      ocrText: image.ocrText ? compactText(image.ocrText, MAX_IMAGE_TEXT_LENGTH) : undefined,
      sizeBytes: image.sizeBytes
    }))
  };
}

export function buildQuizLlmRequest(params: {
  traceId: string;
  requesterUid: string;
  course: CourseRecord;
  images: CourseImageRecord[];
  difficulty: GenerateQuizRequest["difficulty"];
  count: number;
}): GenerateQuizRequest {
  return {
    traceId: params.traceId,
    requesterUid: params.requesterUid,
    difficulty: params.difficulty,
    count: params.count,
    course: buildCourseContext(params.course, params.images)
  };
}

export function buildSummaryLlmRequest(params: {
  traceId: string;
  requesterUid: string;
  course: CourseRecord;
  images: CourseImageRecord[];
  level: GenerateSummaryRequest["level"];
}): GenerateSummaryRequest {
  return {
    traceId: params.traceId,
    requesterUid: params.requesterUid,
    level: params.level,
    course: buildCourseContext(params.course, params.images)
  };
}
