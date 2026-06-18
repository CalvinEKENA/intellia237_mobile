import { logger } from "firebase-functions";

import { CourseRepository } from "../repositories/courseRepository";
import { GeneratedContentRepository } from "../repositories/generatedContentRepository";
import { buildSummaryLlmRequest } from "./llmPayloadFactory";
import { AppError } from "../utils/errors";
import { generateSummaryFlow } from "../llm/flows";
import { getEnv } from "../config/env";

export class GenerateSummaryUseCase {
  constructor(
    private readonly courseRepository = new CourseRepository(),
    private readonly generatedContentRepository = new GeneratedContentRepository()
  ) {}

  async execute(params: {
    userId: string;
    traceId: string;
    courseId: string;
    level: "basic" | "standard" | "advanced";
  }) {
    const course = await this.courseRepository.getCourseById(params.courseId);
    if (course.status !== "published") {
      throw new AppError("failed-precondition", "Only published courses can be used for AI generation.");
    }

    const images = await this.courseRepository.listCourseImages(params.courseId);
    const llmRequest = buildSummaryLlmRequest({
      traceId: params.traceId,
      requesterUid: params.userId,
      course,
      images,
      level: params.level
    });

    logger.info("Generating summary using Genkit flow.", {
      traceId: params.traceId,
      courseId: params.courseId,
      level: params.level,
      imageCount: images.length
    });

    const summary = await generateSummaryFlow(llmRequest);

    const env = getEnv();
    const summaryId = await this.generatedContentRepository.saveSummary({
      courseId: params.courseId,
      generatedByUid: params.userId,
      traceId: params.traceId,
      level: params.level,
      response: {
        summary,
        meta: {
          traceId: params.traceId,
          model: env.GLM_MODEL,
          engineMode: "glm"
        }
      }
    });

    return {
      summaryId,
      summary
    };
  }
}
