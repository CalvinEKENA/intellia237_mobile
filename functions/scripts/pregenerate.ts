import { randomUUID } from "node:crypto";

import { ensureFirebaseApp, db } from "../src/config/firebase";
import { GenerateQuizUseCase } from "../src/services/generateQuizUseCase";
import { GenerateSummaryUseCase } from "../src/services/generateSummaryUseCase";

function readArg(flag: string): string | undefined {
  const index = process.argv.indexOf(flag);
  if (index === -1) {
    return undefined;
  }

  return process.argv[index + 1];
}

async function main(): Promise<void> {
  ensureFirebaseApp();

  const singleCourseId = readArg("--courseId");
  const quizCount = Number(readArg("--count") ?? "5");
  const difficulty = (readArg("--difficulty") ?? "medium") as "easy" | "medium" | "hard";
  const level = (readArg("--level") ?? "standard") as "basic" | "standard" | "advanced";
  const actorUid = readArg("--actorUid") ?? "system-pregeneration";

  const courseSnapshots = singleCourseId
    ? [await db.collection("courses").doc(singleCourseId).get()]
    : (await db.collection("courses").where("status", "==", "published").get()).docs;

  const generateQuizUseCase = new GenerateQuizUseCase();
  const generateSummaryUseCase = new GenerateSummaryUseCase();

  for (const courseSnapshot of courseSnapshots) {
    if (!courseSnapshot.exists) {
      console.warn(`Course not found: ${singleCourseId}`);
      continue;
    }

    const traceId = randomUUID();
    console.log(`Pregenerating content for ${courseSnapshot.id} (${traceId})`);

    await generateSummaryUseCase.execute({
      userId: actorUid,
      traceId,
      courseId: courseSnapshot.id,
      level
    });

    await generateQuizUseCase.execute({
      userId: actorUid,
      traceId: randomUUID(),
      courseId: courseSnapshot.id,
      count: quizCount,
      difficulty
    });
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
