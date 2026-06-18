import { HttpsError } from "firebase-functions/v2/https";
import { ZodError } from "zod";

type ErrorCode =
  | "invalid-argument"
  | "unauthenticated"
  | "permission-denied"
  | "not-found"
  | "failed-precondition"
  | "deadline-exceeded"
  | "unavailable"
  | "internal";

export class AppError extends Error {
  constructor(
    public readonly code: ErrorCode,
    message: string,
    public readonly details?: unknown
  ) {
    super(message);
    this.name = "AppError";
  }
}

export function toHttpsError(error: unknown): HttpsError {
  if (error instanceof HttpsError) {
    return error;
  }

  if (error instanceof ZodError) {
    return new HttpsError("invalid-argument", "Invalid request payload.", {
      issues: error.flatten()
    });
  }

  if (error instanceof AppError) {
    return new HttpsError(error.code, error.message, error.details);
  }

  if (error instanceof Error) {
    return new HttpsError("internal", error.message);
  }

  return new HttpsError("internal", "Unexpected server error.");
}
