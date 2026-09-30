import type { Bucket } from "@google-cloud/storage";

import type { DeletionStoragePort } from "./accountDeletionCallable";

/** Suppression des objets Storage d'un compte (avatars). */
export class BucketDeletionStoragePort implements DeletionStoragePort {
  constructor(private readonly bucket: Bucket) {}

  async deletePrefix(prefix: string): Promise<number> {
    const [files] = await this.bucket.getFiles({ prefix });
    await Promise.all(files.map((file) => file.delete({ ignoreNotFound: true })));
    return files.length;
  }
}
