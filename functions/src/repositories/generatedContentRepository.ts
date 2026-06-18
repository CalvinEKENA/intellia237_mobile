import { FieldValue, type Firestore } from "firebase-admin/firestore";

import { db } from "../config/firebase";
import type { QuizPayload, SummaryPayload } from "../llm/schemas";

export class GeneratedContentRepository {
  constructor(private readonly firestore: Firestore = db) {}

  async saveQuiz(params: {
    courseId: string;
    generatedByUid: string;
    traceId: string;
    count: number;
    difficulty: string;
    response: {
      quiz: QuizPayload;
      meta: {
        traceId: string;
        model: string;
        engineMode: string;
      };
    };
  }): Promise<string> {
    const ref = this.firestore
      .collection("courses")
      .doc(params.courseId)
      .collection("generated_quizzes")
      .doc();

    const now = new Date().toISOString();
    await ref.set({
      courseId: params.courseId,
      generatedByUid: params.generatedByUid,
      traceId: params.traceId,
      request: {
        count: params.count,
        difficulty: params.difficulty
      },
      quiz: params.response.quiz,
      meta: params.response.meta,
      createdAt: FieldValue.serverTimestamp(),
      createdAtIso: now,
      updatedAt: FieldValue.serverTimestamp()
    });

    return ref.id;
  }

  async saveSummary(params: {
    courseId: string;
    generatedByUid: string;
    traceId: string;
    level: string;
    response: {
      summary: SummaryPayload;
      meta: {
        traceId: string;
        model: string;
        engineMode: string;
      };
    };
  }): Promise<string> {
    const ref = this.firestore
      .collection("courses")
      .doc(params.courseId)
      .collection("generated_summaries")
      .doc();

    const now = new Date().toISOString();
    await ref.set({
      courseId: params.courseId,
      generatedByUid: params.generatedByUid,
      traceId: params.traceId,
      request: {
        level: params.level
      },
      summary: params.response.summary,
      meta: params.response.meta,
      createdAt: FieldValue.serverTimestamp(),
      createdAtIso: now,
      updatedAt: FieldValue.serverTimestamp()
    });

    return ref.id;
  }
}
