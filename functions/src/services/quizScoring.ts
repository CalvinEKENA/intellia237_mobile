import type {
  QuizCorrection,
  QuizQuestionRecord,
  QuizRecord,
  QuizSubmissionResult
} from "./quizTypes";
import { xpForQuestion } from "./xpPolicy";

export function scoreQuizAttempt(params: {
  quiz: QuizRecord;
  attemptId: string;
  answersByQuestion: Record<string, string>;
  submittedAt: string;
}): QuizSubmissionResult {
  const corrections: QuizCorrection[] = [];
  let score = 0;
  let xpAwarded = 0;

  const seenQuestionIds = new Set(params.quiz.questions.map((question) => question.id));
  for (const questionId of Object.keys(params.answersByQuestion)) {
    if (!seenQuestionIds.has(questionId)) {
      throw new Error(`Answer references unknown question: ${questionId}`);
    }
  }

  for (const question of params.quiz.questions) {
    const rawAnswer = (params.answersByQuestion[question.id] ?? "").trim();
    const isCorrect = isAnswerCorrect(question, rawAnswer);
    const xpReward = xpForQuestion(question);

    if (isCorrect) {
      score += 1;
      xpAwarded += xpReward;
    }

    corrections.push({
      questionId: question.id,
      prompt: question.prompt,
      userAnswer: formatUserAnswer(question, rawAnswer),
      correctAnswer: correctAnswerLabel(question),
      explanation: question.explanation,
      isCorrect,
      xpReward
    });
  }

  return {
    attemptId: params.attemptId,
    quizId: params.quiz.id,
    quizTitle: params.quiz.title,
    subjectId: params.quiz.subjectId,
    subjectLabel: params.quiz.subjectLabel,
    score,
    maxScore: params.quiz.questions.length,
    xpAwarded,
    corrections,
    submittedAt: params.submittedAt,
    idempotentReplay: false
  };
}

function isAnswerCorrect(question: QuizQuestionRecord, answer: string): boolean {
  switch (question.type) {
    case "qcm": {
      const selectedIndex = Number.parseInt(answer, 10);
      return Number.isInteger(selectedIndex) && selectedIndex === question.correctOptionIndex;
    }
    case "trueFalse": {
      const normalized = answer.toLowerCase();
      const value = normalized === "true" || normalized === "vrai";
      return question.correctBooleanValue === value;
    }
    case "shortAnswer": {
      const normalized = normalizeText(answer);
      return question.acceptedAnswers.map(normalizeText).includes(normalized);
    }
  }
}

function formatUserAnswer(question: QuizQuestionRecord, answer: string): string {
  if (!answer) {
    return "Aucune reponse";
  }

  if (question.type === "qcm") {
    const selectedIndex = Number.parseInt(answer, 10);
    return Number.isInteger(selectedIndex) && question.options[selectedIndex]
      ? question.options[selectedIndex]
      : answer;
  }

  if (question.type === "trueFalse") {
    return answer.toLowerCase() === "true" || answer.toLowerCase() === "vrai"
      ? "Vrai"
      : "Faux";
  }

  return answer;
}

function correctAnswerLabel(question: QuizQuestionRecord): string {
  switch (question.type) {
    case "qcm": {
      const index = question.correctOptionIndex ?? 0;
      return question.options[index] ?? "";
    }
    case "trueFalse":
      return question.correctBooleanValue ? "Vrai" : "Faux";
    case "shortAnswer":
      return question.acceptedAnswers[0] ?? "";
  }
}

function normalizeText(value: string): string {
  return value.trim().toLowerCase();
}
