import { describe, expect, it } from "vitest";

import {
  announcementFanoutPageSize,
  announcementNotificationDocumentId,
  buildAnnouncementNotificationFields,
} from "../services/announcementNotificationFanout";

describe("announcement notification fanout contracts", () => {
  it("keeps every Firestore read/write page below the batch ceiling", () => {
    expect(announcementFanoutPageSize).toBeGreaterThan(0);
    expect(announcementFanoutPageSize).toBeLessThanOrEqual(400);
  });

  it("uses deterministic recipient-scoped ids so retries are idempotent", () => {
    const first = announcementNotificationDocumentId("news-1", "user-1");
    expect(first).toBe("announcement_news-1_user-1");
    expect(announcementNotificationDocumentId("news-1", "user-1")).toBe(first);
    expect(announcementNotificationDocumentId("news-1", "user-2")).not.toBe(first);
  });

  it("never writes readAt, preserving an already-read item on retry", () => {
    const payload = buildAnnouncementNotificationFields({
      announcementId: "news-1",
      establishmentId: "school-1",
      recipientId: "user-1",
      title: "Schedule",
      body: "Classes start at eight.",
      createdAt: "server-time",
    });

    expect(payload).not.toHaveProperty("readAt");
    expect(payload).toMatchObject({
      userId: "user-1",
      sourceId: "news-1",
      route: "/notifications",
    });
  });
});
