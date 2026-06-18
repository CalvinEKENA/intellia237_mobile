import {
  buildRequestHash,
  FirestoreAcademicStateStore,
  type AcademicStateStore
} from "./academicStateStore";
import type { RecordLessonProgressCallableInput } from "../utils/validation";

export class RecordLessonProgressUseCase {
  constructor(private readonly store: AcademicStateStore = new FirestoreAcademicStateStore()) {}

  execute(params: {
    studentId: string;
    input: RecordLessonProgressCallableInput;
  }) {
    const requestHash = buildRequestHash({
      studentId: params.studentId,
      classLevel: params.input.classLevel,
      subjectId: params.input.subjectId,
      chapterId: params.input.chapterId,
      lessonId: params.input.lessonId,
      progress: params.input.progress,
      clientEventId: params.input.clientEventId
    });

    return this.store.recordLessonProgress({
      studentId: params.studentId,
      classLevel: params.input.classLevel,
      subjectId: params.input.subjectId,
      chapterId: params.input.chapterId,
      lessonId: params.input.lessonId,
      progress: params.input.progress,
      clientEventId: params.input.clientEventId,
      requestHash
    });
  }
}
