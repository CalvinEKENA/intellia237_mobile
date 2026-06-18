import {
  buildRequestHash,
  FirestoreAcademicStateStore,
  type AcademicStateStore
} from "./academicStateStore";
import type { SubmitQuizAttemptCallableInput } from "../utils/validation";

export class SubmitQuizAttemptUseCase {
  constructor(private readonly store: AcademicStateStore = new FirestoreAcademicStateStore()) {}

  execute(params: {
    studentId: string;
    input: SubmitQuizAttemptCallableInput;
  }) {
    const requestHash = buildRequestHash({
      studentId: params.studentId,
      quizId: params.input.quizId,
      clientAttemptId: params.input.clientAttemptId,
      answersByQuestion: params.input.answersByQuestion,
      startedAt: params.input.startedAt ?? null,
      durationSeconds: params.input.durationSeconds ?? null
    });

    return this.store.submitQuizAttempt({
      studentId: params.studentId,
      quizId: params.input.quizId,
      clientAttemptId: params.input.clientAttemptId,
      answersByQuestion: params.input.answersByQuestion,
      startedAt: params.input.startedAt,
      durationSeconds: params.input.durationSeconds,
      requestHash
    });
  }
}
