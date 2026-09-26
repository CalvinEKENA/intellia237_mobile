import { describe, expect, it } from "vitest";
import {
  manageSchoolClassInput,
  authorizeClassAdmin,
  createManageSchoolClassHandler,
  type ClassManagementStore,
} from "../services/classManagementCallable";

describe("class management callable", () => {
  it("validates create class payload schema", () => {
    const valid = {
      action: "create",
      name: "Terminale C1",
      classLevel: "tle",
      series: "C",
      establishmentId: "lycee-a",
    };
    expect(() => manageSchoolClassInput.parse(valid)).not.toThrow();
  });

  it("validates delete class payload schema", () => {
    const valid = {
      action: "delete",
      classId: "class-123",
      reason: "Classe vide fermée",
    };
    expect(() => manageSchoolClassInput.parse(valid)).not.toThrow();
  });

  it("authorizes superAdmin across all establishments", () => {
    expect(() =>
      authorizeClassAdmin({ role: "superAdmin", accountStatus: "active" }, "school-any"),
    ).not.toThrow();
    expect(() =>
      authorizeClassAdmin({ role: "super_admin", accountStatus: "active" }, "school-any"),
    ).not.toThrow();
  });

  it("authorizes school admin only within their establishment", () => {
    expect(() =>
      authorizeClassAdmin(
        { role: "admin", establishmentId: "school-a", accountStatus: "active" },
        "school-a",
      ),
    ).not.toThrow();

    expect(() =>
      authorizeClassAdmin(
        { role: "admin", establishmentId: "school-a", accountStatus: "active" },
        "school-b",
      ),
    ).toThrow();
  });

  it("denies students and teachers from class administration", () => {
    expect(() =>
      authorizeClassAdmin(
        { role: "teacher", establishmentId: "school-a", accountStatus: "active" },
        "school-a",
      ),
    ).toThrow();
    expect(() =>
      authorizeClassAdmin(
        { role: "student", establishmentId: "school-a", accountStatus: "active" },
        "school-a",
      ),
    ).toThrow();
  });

  it("rejects unauthenticated requests before store execution", async () => {
    let called = false;
    const store = {
      execute: async () => {
        called = true;
        return { classId: "c1", action: "create" };
      },
    } as unknown as ClassManagementStore;

    const handler = createManageSchoolClassHandler(store);
    await expect(handler({ data: {} } as never)).rejects.toMatchObject({
      code: "unauthenticated",
    });
    expect(called).toBe(false);
  });
});
