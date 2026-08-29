import { describe, expect, it } from "vitest";

import {
  createRequestAccountDeletionHandler,
  type AccountDeletionRequestStore,
} from "../services/accountDeletionCallable";

describe("requestAccountDeletion", () => {
  it("rejects unauthenticated callers", async () => {
    const handler = createRequestAccountDeletionHandler(
      new MemoryDeletionRequestStore(),
    );

    await expect(handler({ data: {} } as never)).rejects.toMatchObject({
      code: "unauthenticated",
    });
  });

  it("records the authenticated account and returns a pending status", async () => {
    const store = new MemoryDeletionRequestStore();
    const handler = createRequestAccountDeletionHandler(store);

    await expect(
      handler({ auth: { uid: "student-a" }, data: {} } as never),
    ).resolves.toEqual({ status: "pending" });
    expect(store.requestedUids).toEqual(["student-a"]);
  });
});

class MemoryDeletionRequestStore implements AccountDeletionRequestStore {
  readonly requestedUids: string[] = [];

  async request(uid: string): Promise<void> {
    this.requestedUids.push(uid);
  }
}
