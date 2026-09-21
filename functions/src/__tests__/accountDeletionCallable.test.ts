import { describe, expect, it } from "vitest";

import {
  ACCOUNT_DELETION_GRACE_MS,
  ACCOUNT_DELETION_MAX_ATTEMPTS,
  createCancelAccountDeletionHandler,
  createRequestAccountDeletionHandler,
  nextDeletionRetryDelay,
} from "../services/accountDeletionCallable";

describe("account deletion policy", () => {
  it("rejects unauthenticated callers before touching any data", async () => {
    const unusedFirestore = {} as never;
    await expect(createRequestAccountDeletionHandler(unusedFirestore)({ data: {} } as never))
      .rejects.toMatchObject({ code: "unauthenticated" });
    await expect(createCancelAccountDeletionHandler(unusedFirestore)({ data: {} } as never))
      .rejects.toMatchObject({ code: "unauthenticated" });
  });

  it("keeps a seven-day grace period", () => {
    expect(ACCOUNT_DELETION_GRACE_MS).toBe(7 * 24 * 60 * 60 * 1000);
  });

  it("backs off 1 h, 6 h, 24 h, 72 h, then asks for a human", () => {
    const hour = 60 * 60 * 1000;
    expect(nextDeletionRetryDelay(1)).toBe(hour);
    expect(nextDeletionRetryDelay(2)).toBe(6 * hour);
    expect(nextDeletionRetryDelay(3)).toBe(24 * hour);
    expect(nextDeletionRetryDelay(4)).toBe(72 * hour);
    expect(nextDeletionRetryDelay(ACCOUNT_DELETION_MAX_ATTEMPTS)).toBeNull();
  });
});
