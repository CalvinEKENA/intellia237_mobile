import { logger } from "firebase-functions";

import { CourseRepository } from "../repositories/courseRepository";
import { GeneratedContentRepository } from "../repositories/generatedContentRepository";
import { buildQuizLlmRequest } from "./llmPayloadFactory";
import { AppError } from "../utils/errors";
import { generateQuizFlow } from "../llm/flows";
import { getEnv } from "../config/env";

export class GenerateQuizUseCase {
  constructor(
    private readonly courseRepository = new CourseRepository(),
    private readonly generatedContentRepository = new GeneratedContentRepository()
  ) {}

  async execute(params: {
    userId: string;
    traceId: string;
    courseId: string;
    count: number;
    difficulty: "easy" | "medium" | "hard";
  }) {
    const course = await this.courseRepository.getCourseById(params.courseId);
    if (course.status !== "published") {
      throw new AppError("failed-precondition", "Only published courses can be used for AI generation.");
    }

    const images = await this.courseRepository.listCourseImages(params.courseId);
    const llmRequest = buildQuizLlmRequest({
      traceId: params.traceId,
      requesterUid: params.userId,
      course,
      images,
      count: params.count,
      difficulty: params.difficulty
    });

    logger.info("Generating quiz using Genkit flow.", {
      traceId: params.traceId,
      courseId: params.courseId,
      count: params.count,
      difficulty: params.difficulty,
      imageCount: images.length
    });

    const quiz = await generateQuizFlow(llmRequest);

    const env = getEnv();
    const quizId = await this.generatedContentRepository.saveQuiz({
      courseId: params.courseId,
      generatedByUid: params.userId,
      traceId: params.traceId,
      count: params.count,
      difficulty: params.difficulty,
      response: {
        quiz,
        meta: {
          traceId: params.traceId,
          model: env.GLM_MODEL,
          engineMode: "glm"
        }
      }
    });

    return {
      quizId,
      quiz
    };
  }
}
