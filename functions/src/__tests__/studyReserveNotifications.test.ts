import { describe, expect, it } from "vitest";

import { classifyNotificationDelivery } from "../services/notificationDelivery";
import {
  buildThresholdNotificationFields,
  normalizePreferredLocale,
  thresholdNotificationId,
} from "../services/studyReserveConsumption";

const base = {
  threshold: 25 as const,
  audience: "student" as const,
  studentId: "s1",
  cycleId: "offer_1",
  recipientId: "s1",
};

describe("study reserve threshold notifications", () => {
  it("builds a French push notification for a French recipient", () => {
    const fields = buildThresholdNotificationFields({ ...base, lang: "fr" });
    expect(fields.title).toBe("Réserve d’étude");
    expect(String(fields.body)).toContain("25 %");
    expect(fields.deliveryMode).toBe("push");
    expect(classifyNotificationDelivery(fields)).toBe("deliverable");
  });

  it("builds an English push notification for an English recipient", () => {
    const fields = buildThresholdNotificationFields({
      ...base,
      lang: "en",
      audience: "parent",
      recipientId: "p1",
    });
    expect(fields.title).toBe("Study reserve");
    expect(String(fields.body)).toContain("Your child's");
    expect(classifyNotificationDelivery(fields)).toBe("deliverable");
  });

  it("never produces a blank push: unknown locale is inbox-only, not invalid", () => {
    const fields = buildThresholdNotificationFields({ ...base, lang: null });
    expect(fields.deliveryMode).toBe("inbox_only");
    // Pas de push deviné ni vide, et le document n'est PAS marqué invalide.
    expect(classifyNotificationDelivery(fields)).toBe("inbox_only");
    // L'in-app garde de quoi se localiser côté client.
    expect(fields.type).toBe("study_reserve_threshold");
    expect(fields.data).toMatchObject({ threshold: 25, studentId: "s1" });
  });

  it("keeps the existing validation for ordinary incomplete notifications", () => {
    expect(
      classifyNotificationDelivery({ userId: "u1", title: "", body: "" }),
    ).toBe("invalid");
    expect(
      classifyNotificationDelivery({ deliveryMode: "inbox_only", userId: "" }),
    ).toBe("invalid");
  });

  it("uses a stable id so a threshold is never duplicated for a recipient", () => {
    expect(thresholdNotificationId("offer_1", 25, "s1")).toBe(
      thresholdNotificationId("offer_1", 25, "s1"),
    );
    expect(thresholdNotificationId("offer_1", 25, "s1")).not.toBe(
      thresholdNotificationId("offer_1", 5, "s1"),
    );
  });

  it("normalizes stored language preferences and refuses to guess", () => {
    expect(normalizePreferredLocale("fr")).toBe("fr");
    expect(normalizePreferredLocale("french")).toBe("fr");
    expect(normalizePreferredLocale("en")).toBe("en");
    expect(normalizePreferredLocale("english")).toBe("en");
    expect(normalizePreferredLocale("anglais")).toBe("en");
    expect(normalizePreferredLocale("")).toBeNull();
    expect(normalizePreferredLocale(undefined)).toBeNull();
    expect(normalizePreferredLocale("de")).toBeNull();
  });
});
