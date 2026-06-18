import { z } from "zod";

export const courseSectionSchema = z.object({
  title: z.string().trim().min(1),
  body: z.string().trim().min(1)
});

export const courseDocumentSchema = z.object({
  title: z.string().trim().min(1),
  subject: z.string().trim().min(1),
  gradeLevel: z.string().trim().min(1),
  language: z.string().trim().min(2).default("fr"),
  status: z.string().trim().min(1).default("draft"),
  difficultyBand: z.string().trim().min(1).optional(),
  learningObjectives: z.array(z.string().trim().min(1)).default([]),
  tags: z.array(z.string().trim().min(1)).default([]),
  contentSections: z.array(courseSectionSchema).min(1),
  imageRefs: z.array(z.string().trim().min(1)).default([]),
  source: z
    .object({
      type: z.string().trim().min(1),
      version: z.number().int().positive().optional()
    })
    .optional()
});

export const courseImageDocumentSchema = z.object({
  fileName: z.string().trim().min(1),
  storagePath: z.string().trim().min(1),
  contentType: z.string().trim().min(1).optional(),
  caption: z.string().trim().min(1).optional(),
  ocrText: z.string().trim().min(1).optional(),
  sizeBytes: z.number().int().nonnegative().optional(),
  checksum: z.string().trim().min(1).optional(),
  source: z
    .object({
      provider: z.string().trim().min(1),
      driveFileId: z.string().trim().min(1).optional()
    })
    .optional()
});

export type CourseSection = z.infer<typeof courseSectionSchema>;
export type CourseRecord = z.infer<typeof courseDocumentSchema> & { id: string };
export type CourseImageRecord = z.infer<typeof courseImageDocumentSchema> & {
  id: string;
  missingInStorage?: boolean;
};
