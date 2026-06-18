import type { Bucket } from "@google-cloud/storage";
import type { Firestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions";

import { bucket, db } from "../config/firebase";
import { getEnv } from "../config/env";
import {
  courseDocumentSchema,
  courseImageDocumentSchema,
  type CourseImageRecord,
  type CourseRecord
} from "../models/course";
import { AppError } from "../utils/errors";

export class CourseRepository {
  constructor(
    private readonly firestore: Firestore = db,
    private readonly storageBucket: Bucket = bucket
  ) {}

  async getCourseById(courseId: string): Promise<CourseRecord> {
    const snapshot = await this.firestore.collection("courses").doc(courseId).get();
    if (!snapshot.exists) {
      throw new AppError("not-found", `Course ${courseId} was not found.`);
    }

    const parsed = courseDocumentSchema.parse(snapshot.data());
    return {
      id: snapshot.id,
      ...parsed
    };
  }

  async listCourseImages(courseId: string): Promise<CourseImageRecord[]> {
    const env = getEnv();
    const snapshot = await this.firestore
      .collection("courses")
      .doc(courseId)
      .collection("images")
      .limit(env.MAX_COURSE_IMAGES)
      .get();

    const images = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...courseImageDocumentSchema.parse(doc.data())
    }));

    return Promise.all(images.map((image) => this.attachStorageMetadata(image)));
  }

  private async attachStorageMetadata(image: CourseImageRecord): Promise<CourseImageRecord> {
    try {
      const file = this.storageBucket.file(image.storagePath);
      const [exists] = await file.exists();
      if (!exists) {
        logger.warn("Course image metadata exists but the Storage object is missing.", {
          imageId: image.id,
          storagePath: image.storagePath
        });
        return {
          ...image,
          missingInStorage: true
        };
      }

      const [metadata] = await file.getMetadata();
      return {
        ...image,
        contentType: metadata.contentType ?? image.contentType,
        sizeBytes: metadata.size ? Number(metadata.size) : image.sizeBytes,
        checksum: metadata.md5Hash ?? image.checksum
      };
    } catch (error) {
      logger.warn("Failed to enrich course image metadata from Storage.", {
        imageId: image.id,
        storagePath: image.storagePath,
        error: error instanceof Error ? error.message : String(error)
      });
      return image;
    }
  }
}
